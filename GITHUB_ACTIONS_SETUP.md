# GitHub Actions CI/CD Setup Guide

This comprehensive guide will help you set up automated CI/CD pipelines using GitHub Actions for the Forum Microservices project. The workflows include automated Docker image builds, Terraform infrastructure deployment, and ECS service updates.

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Workflow Files](#workflow-files)
4. [AWS IAM Setup](#step-1-aws-iam-setup)
5. [GitHub Secrets Configuration](#step-2-configure-github-secrets)
6. [Terraform Backend Setup](#step-3-terraform-backend-setup-optional)
7. [Initial Infrastructure Deployment](#step-4-initial-infrastructure-deployment)
8. [Docker Image Build & Push](#step-5-build-and-push-docker-images)
9. [Testing Workflows](#step-6-test-workflows)
10. [Monitoring & Troubleshooting](#monitoring-and-troubleshooting)

## Prerequisites
- ✅ AWS account configured with appropriate permissions
- ✅ Local testing completed with Docker Compose
- ✅ GitHub repository created (https://github.com/fikrat86/microservices_docker)
- ✅ AWS CLI installed and configured
- ✅ Terraform installed (v1.5.0+)
- ✅ Code pushed to GitHub

## Architecture Overview

The CI/CD pipeline consists of three main workflows:

### 1. **Complete Deployment Pipeline** (`complete-pipeline.yml`)
- **Purpose**: End-to-end deployment automation
- **Features**:
  - Automatic change detection for each microservice
  - Parallel Docker image builds
  - Terraform infrastructure deployment
  - ECS service updates
  - Post-deployment verification
- **Triggers**: Push to main, manual dispatch

### 2. **Terraform Infrastructure** (`terraform-deploy.yml`)
- **Purpose**: Infrastructure-only deployment
- **Features**:
  - Terraform validation and planning
  - PR comments with plan output
  - Automatic apply on merge to main
- **Triggers**: Push to main (terraform changes), PRs, manual

### 3. **Individual Service Deployments** (`deploy-{service}.yml`)
- **Purpose**: Single service deployment
- **Features**:
  - Quick service updates
  - Independent deployment
- **Triggers**: Push to main (service-specific changes), manual

---

## Workflow Files

After setup, you'll have these workflow files:

```
.github/
└── workflows/
    ├── complete-pipeline.yml       # Main CI/CD pipeline
    ├── terraform-deploy.yml        # Infrastructure deployment
    ├── deploy-posts.yml           # Posts service deployment
    ├── deploy-threads.yml         # Threads service deployment
    └── deploy-users.yml           # Users service deployment
```

---

## Step 1: AWS IAM Setup

### Create IAM User for GitHub Actions

You need an IAM user with permissions for ECR, ECS, VPC, IAM, and other resources.

### Option A: Using AWS Console (Recommended for Production)

1. Go to **IAM Console** → **Users** → **Create user**
   - User name: `github-actions-deployer`
   - Access type: Select "Programmatic access"

2. **Attach Policies** - Choose one of:
   
   **Quick Setup** (use existing policies):
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonECS_FullAccess`
   - `AmazonVPCFullAccess`
   - `IAMFullAccess`
   - `ElasticLoadBalancingFullAccess`
   - `CloudWatchLogsFullAccess`
   - `AutoScalingFullAccess`

   **Production Setup** (custom policy - more restrictive):
   - Create custom policy with this JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*",
        "ecs:*",
        "ec2:Describe*",
        "ec2:CreateTags",
        "ec2:CreateSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DeleteSecurityGroup",
        "elasticloadbalancing:*",
        "logs:*",
        "autoscaling:*",
        "cloudwatch:*",
        "iam:CreateRole",
        "iam:PutRolePolicy",
        "iam:GetRole",
        "iam:PassRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy"
      ],
      "Resource": "*"
    }
  ]
}
```

3. **Download credentials** - Save the Access Key ID and Secret Access Key

### Option B: Using AWS CLI (Quick Setup for Development)

Run these commands in PowerShell:

```powershell
# Create IAM user
aws iam create-user --user-name github-actions-deployer

# Create inline policy for the user
$policyDocument = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeRepositories"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:UpdateService",
        "ecs:ListTasks"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::*:role/*ecsTaskExecutionRole*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "*"
    }
  ]
}
"@

# Save policy to file
$policyDocument | Out-File -FilePath policy.json -Encoding utf8

# Attach policy
aws iam put-user-policy `
  --user-name github-actions-deployer `
  --policy-name GitHubActionsPolicy `
  --policy-document file://policy.json

# Create access key
aws iam create-access-key --user-name github-actions-deployer
```

**Important**: Save the output! You'll need:
- `AccessKeyId`
- `SecretAccessKey`

---

## Step 2: Configure GitHub Secrets

1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**

Add these two secrets:

| Secret Name | Value |
|------------|-------|
| `AWS_ACCESS_KEY_ID` | (AccessKeyId from Step 1) |
| `AWS_SECRET_ACCESS_KEY` | (SecretAccessKey from Step 1) |

---

## Step 3: Verify Workflow Files Exist

Check that these files exist in your repository:

```
.github/
└── workflows/
    ├── deploy-infrastructure.yml
    ├── deploy-posts.yml
    ├── deploy-threads.yml
    ├── deploy-users.yml
    ├── test-services.yml
    └── README.md
```

If they don't exist, they were just created. Commit and push:

```powershell
git add .github/
git commit -m "Add GitHub Actions workflows"
git push origin main
```

---

## Step 4: Deploy Infrastructure First

Before deploying services, deploy the infrastructure:

### Option A: Using Terraform Locally (Recommended for first time)

```powershell
cd terraform
terraform init
terraform plan
terraform apply
```

Wait for completion (~20-30 minutes).

### Option B: Using GitHub Actions

1. Go to **Actions** tab in GitHub
2. Select **Deploy Infrastructure**
3. Click **Run workflow**
4. Select branch: `main`
5. Choose action: `plan`
6. Click **Run workflow**
7. Review the plan in the workflow logs
8. Run again with action: `apply`

---

## Step 5: Build and Push Initial Docker Images

After infrastructure is deployed, build and push Docker images:

```powershell
# Make sure you're in project root
.\scripts\build-and-push.ps1 -Service all -Region us-east-1
```

This script now:
- ✅ Automatically creates ECR repositories if they don't exist
- ✅ Better error handling
- ✅ Builds all three services
- ✅ Pushes to ECR with `latest` and timestamped tags

---

## Step 6: Test GitHub Actions Deployment

### Manual Workflow Trigger

1. Go to **Actions** tab
2. Select **Deploy Posts Service**
3. Click **Run workflow**
4. Select branch: `main`
5. Click **Run workflow**
6. Watch the workflow execute

**Expected Steps**:
1. ✓ Checkout code
2. ✓ Configure AWS credentials
3. ✓ Login to Amazon ECR
4. ✓ Build, tag, and push image
5. ✓ Download task definition
6. ✓ Update task definition with new image
7. ✓ Deploy to ECS
8. ✓ Wait for service stability

Repeat for Threads and Users services.

---

## Step 7: Test Automatic Deployments

Now test that code changes trigger automatic deployment:

### Test Posts Service

```powershell
# Edit a file
code posts/server.js
# Make a small change (add a comment)

# Commit and push
git add posts/server.js
git commit -m "Test automatic deployment for posts service"
git push origin main
```

### Verify Workflow Triggered

1. Go to **Actions** tab
2. You should see "Deploy Posts Service" running
3. Click on the workflow run
4. Monitor progress
5. Verify successful deployment

### Test Deployment

```powershell
# Get ALB URL
cd terraform
$albUrl = terraform output -raw alb_dns_name

# Test the service
Invoke-WebRequest -Uri "http://$albUrl/api/posts" -Method Get
```

---

## Step 8: Test All Services

Run the test workflow:

1. Make a small change in any service
2. Create a pull request
3. **Test Services** workflow automatically runs
4. Merge PR after tests pass
5. Deployment workflows automatically trigger

---

## Workflow Details

### Automatic Triggers

| Workflow | Trigger | When |
|----------|---------|------|
| Test Services | Pull Request | Runs tests on all services |
| Deploy Posts | Push to `main` + changes in `posts/` | Deploys Posts service |
| Deploy Threads | Push to `main` + changes in `threads/` | Deploys Threads service |
| Deploy Users | Push to `main` + changes in `users/` | Deploys Users service |
| Deploy Infrastructure | Manual only | Deploys Terraform infrastructure |

### Environment Variables

Each workflow uses these variables (already configured):

```yaml
env:
  AWS_REGION: us-east-1
  ECR_REPOSITORY: forum-microservices/{service}
  ECS_SERVICE: {service}-service
  ECS_CLUSTER: forum-microservices-cluster
  CONTAINER_NAME: {service}
```

---

## Monitoring Deployments

### View Workflow Runs

1. Go to **Actions** tab
2. Click on any workflow run
3. Click on the job name
4. Expand steps to see logs
5. Green checkmark = success
6. Red X = failure

### Check ECS Deployment

```powershell
# Check service status
aws ecs describe-services `
  --cluster forum-microservices-cluster `
  --services posts-service `
  --region us-east-1 `
  --query 'services[0].deployments'

# Check running tasks
aws ecs list-tasks `
  --cluster forum-microservices-cluster `
  --service-name posts-service `
  --region us-east-1
```

### View Application Logs

```powershell
# Get latest log stream
aws logs describe-log-streams `
  --log-group-name /ecs/forum-microservices-dev `
  --order-by LastEventTime `
  --descending `
  --max-items 1 `
  --region us-east-1

# View logs
aws logs tail /ecs/forum-microservices-dev --follow
```

---

## Troubleshooting

### Workflow Fails: "Repository not found"

**Problem**: ECR repository doesn't exist

**Solution**: Deploy infrastructure first or run build-and-push script

```powershell
.\scripts\build-and-push.ps1 -Service all -Region us-east-1
```

### Workflow Fails: "Task definition not found"

**Problem**: ECS infrastructure not deployed

**Solution**: Deploy infrastructure with Terraform

```powershell
cd terraform
terraform apply
```

### Workflow Fails: "Invalid credentials"

**Problem**: GitHub secrets not configured correctly

**Solution**: 
1. Verify secrets in GitHub Settings → Secrets
2. Re-create IAM access key if needed
3. Update secrets with new values

### Deployment Succeeds but Service Unhealthy

**Problem**: Container failing health checks

**Solution**:
```powershell
# Check ECS task logs
aws logs tail /ecs/forum-microservices-dev --follow

# Check task status
aws ecs describe-tasks `
  --cluster forum-microservices-cluster `
  --tasks $(aws ecs list-tasks --cluster forum-microservices-cluster --service-name posts-service --query 'taskArns[0]' --output text) `
  --region us-east-1
```

### Workflow Takes Too Long

**Normal**: 5-10 minutes for build and deploy
**Problem**: If > 15 minutes, check:
- Docker build step for errors
- Network connectivity
- ECS service stability timeout

---

## Advanced Features

### Deploy to Multiple Environments

Add this to workflow file:

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options:
          - development
          - staging
          - production
```

### Add Slack Notifications

1. Create Slack incoming webhook
2. Add `SLACK_WEBHOOK` secret to GitHub
3. Add step to workflow:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Enable Manual Approval for Production

1. Create environment in GitHub Settings
2. Add protection rules
3. Update workflow:

```yaml
jobs:
  deploy:
    environment: production
    # ... rest of job
```

---

## Best Practices

✅ **Do**:
- Review workflow logs regularly
- Monitor ECS service health
- Set up CloudWatch alarms
- Use semantic versioning for image tags
- Test locally before pushing

❌ **Don't**:
- Commit AWS credentials to code
- Skip testing workflows
- Deploy to production without review
- Ignore failed builds
- Override health checks

---

## Quick Reference Commands

```powershell
# Get ALB URL
cd terraform; terraform output -raw alb_dns_name

# Test service
$albUrl = "http://$(cd terraform; terraform output -raw alb_dns_name)"
Invoke-WebRequest -Uri "$albUrl/api/posts"

# Watch ECS deployments
aws ecs describe-services --cluster forum-microservices-cluster --services posts-service --region us-east-1

# View logs
aws logs tail /ecs/forum-microservices-dev --follow

# Force new deployment
aws ecs update-service --cluster forum-microservices-cluster --service posts-service --force-new-deployment

# Check workflow status (via GitHub CLI)
gh run list --workflow=deploy-posts.yml
```

---

## Next Steps

1. ✅ Verify all workflows are working
2. ✅ Set up branch protection rules
3. ✅ Configure CloudWatch alarms
4. ✅ Set up AWS Budget alerts
5. ✅ Document your deployment process
6. ✅ Test disaster recovery procedures

---

## Support Resources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- Project Documentation: `../docs/`
- Workflow Details: `.github/workflows/README.md`

---

**Setup Complete!** 🎉

Your CI/CD pipeline is now configured. Every code change pushed to main will automatically build, test, and deploy to AWS ECS.
