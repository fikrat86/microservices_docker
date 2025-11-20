# GitHub Actions Workflows

This directory contains automated CI/CD workflows for the Forum Microservices project.

## Workflows Overview

### 🚀 complete-pipeline.yml
**Complete Deployment Pipeline**

The main workflow that handles end-to-end deployment with intelligent change detection.

**Features:**
- Detects which services changed in the commit
- Builds and pushes only modified Docker images (or all if manually triggered)
- Deploys Terraform infrastructure when terraform files change
- Updates ECS services with new container images
- Verifies deployment health after completion
- Parallel execution for faster builds

**Triggers:**
- Automatic: Push to `main` branch
- Manual: Workflow dispatch with options
  - Deploy infrastructure: Yes/No
  - Build all images: Yes/No (overrides change detection)

**Jobs:**
1. `detect-changes` - Determines which services changed
2. `build-and-push-{service}` - Builds Docker images (parallel)
3. `deploy-infrastructure` - Deploys Terraform resources
4. `deploy-{service}` - Updates ECS services (parallel)
5. `verify-deployment` - Tests service health

**Usage:**
```bash
# Automatic - just push changes
git push origin main

# Manual - via GitHub UI
Actions → Complete Deployment Pipeline → Run workflow
```

---

### 🏗️ terraform-deploy.yml
**Infrastructure Deployment**

Dedicated workflow for Terraform infrastructure management with plan/apply separation.

**Features:**
- Terraform format check
- Validates configuration
- Creates execution plan
- Comments plan on Pull Requests
- Auto-applies on merge to main
- Outputs infrastructure details

**Triggers:**
- Automatic: Push to `main` (when terraform/** changes)
- Pull Requests: Runs plan only, comments on PR
- Manual: Workflow dispatch

**Jobs:**
1. `terraform` - Runs init, validate, plan, apply

**Usage:**
```bash
# For PRs - automatic plan
git checkout -b infra-updates
# make terraform changes
git push origin infra-updates
# Creates PR → workflow comments with plan

# For main branch - automatic apply
git merge infra-updates
git push origin main
```

---

### 📦 deploy-posts.yml
**Posts Service Deployment**

Individual deployment workflow for the Posts microservice.

**Features:**
- Builds Posts Docker image
- Pushes to ECR
- Updates ECS task definition
- Deploys to ECS cluster
- Waits for service stability

**Triggers:**
- Automatic: Push to `main` (when posts/** changes)
- Manual: Workflow dispatch

**Jobs:**
1. `deploy` - Complete deployment cycle

**Usage:**
```bash
# Automatic
vim posts/server.js
git commit -am "Update posts service"
git push origin main

# Manual
Actions → Deploy Posts Service → Run workflow
```

---

### 📦 deploy-threads.yml
**Threads Service Deployment**

Individual deployment workflow for the Threads microservice.

**Features:**
- Same as deploy-posts.yml but for Threads service

**Triggers:**
- Automatic: Push to `main` (when threads/** changes)
- Manual: Workflow dispatch

---

### 📦 deploy-users.yml
**Users Service Deployment**

Individual deployment workflow for the Users microservice.

**Features:**
- Same as deploy-posts.yml but for Users service

**Triggers:**
- Automatic: Push to `main` (when users/** changes)
- Manual: Workflow dispatch

---

## Workflow Execution Flow

### Scenario 1: Push Code Changes to Posts Service

```
Developer pushes changes to posts/
    ↓
GitHub detects push to main
    ↓
complete-pipeline.yml triggers
    ↓
detect-changes identifies: posts = true
    ↓
build-and-push-posts runs:
    • Builds Docker image
    • Tags with commit SHA and 'latest'
    • Pushes to ECR
    ↓
deploy-posts runs:
    • Downloads current task definition
    • Updates image reference
    • Deploys to ECS
    • Waits for stability
    ↓
verify-deployment runs:
    • Tests service health
    • Reports status
```

### Scenario 2: Infrastructure Changes

```
Developer updates terraform files
    ↓
Creates Pull Request
    ↓
terraform-deploy.yml triggers (plan mode)
    ↓
Comments on PR with plan output
    ↓
PR gets reviewed and merged
    ↓
terraform-deploy.yml triggers (apply mode)
    ↓
Infrastructure updated
```

### Scenario 3: Manual Full Deployment

```
Go to Actions → Complete Deployment Pipeline
    ↓
Run workflow with:
    • Deploy infrastructure: true
    • Build all images: true
    ↓
All jobs execute regardless of changes
```

---

## Environment Variables

### Global Environment Variables

Used across all workflows:

```yaml
AWS_REGION: us-east-1
ECR_REGISTRY_PREFIX: forum-microservices
ECS_CLUSTER: forum-microservices-cluster
```

### Service-Specific Variables

**Posts Service:**
```yaml
ECR_REPOSITORY: forum-microservices/posts
ECS_SERVICE: posts-service
CONTAINER_NAME: posts
```

**Threads Service:**
```yaml
ECR_REPOSITORY: forum-microservices/threads
ECS_SERVICE: threads-service
CONTAINER_NAME: threads
```

**Users Service:**
```yaml
ECR_REPOSITORY: forum-microservices/users
ECS_SERVICE: users-service
CONTAINER_NAME: users
```

---

## Required GitHub Secrets

Configure these in: **Repository Settings → Secrets and variables → Actions**

| Secret Name | Description | Example |
|------------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS IAM user access key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | AWS IAM secret key | `wJalrXUtn...` |

**Note:** These are automatically passed to workflows and should NEVER be committed to code.

---

## Monitoring Workflows

### View Workflow Runs

1. Go to repository **Actions** tab
2. Select workflow from left sidebar
3. Click on specific run
4. View logs for each job/step

### Workflow Status Badges

Add to README.md:

```markdown
![Complete Pipeline](https://github.com/fikrat86/microservices_docker/actions/workflows/complete-pipeline.yml/badge.svg)
![Terraform](https://github.com/fikrat86/microservices_docker/actions/workflows/terraform-deploy.yml/badge.svg)
```

### Email Notifications

GitHub automatically emails:
- Workflow failures
- First workflow failure after success
- Workflow success after failure

Configure in: **GitHub Profile → Settings → Notifications**

---

## Troubleshooting

### Common Issues

#### 1. "Repository does not exist in ECR"

**Cause:** ECR repositories not created yet

**Solution:**
```bash
# Deploy infrastructure first
cd terraform
terraform apply -target=aws_ecr_repository.posts \
                -target=aws_ecr_repository.threads \
                -target=aws_ecr_repository.users
```

#### 2. "Task definition not found"

**Cause:** ECS infrastructure not deployed

**Solution:**
```bash
# Deploy full infrastructure
cd terraform
terraform apply
```

#### 3. "AccessDenied" errors

**Cause:** IAM permissions insufficient

**Solution:**
- Review IAM user permissions
- Verify secrets in GitHub are correct
- Check AWS account ID matches

#### 4. Service fails to stabilize

**Cause:** Health checks failing or image issues

**Debug:**
```bash
# Check task logs
aws logs tail /ecs/forum-microservices-dev --follow

# Describe tasks
aws ecs describe-tasks \
  --cluster forum-microservices-cluster \
  --tasks $(aws ecs list-tasks \
    --cluster forum-microservices-cluster \
    --service-name posts-service \
    --query 'taskArns[0]' \
    --output text)
```

#### 5. Workflow timeout

**Cause:** ECS deployment taking too long

**Solution:**
- Check ECS task can pull image from ECR
- Verify security groups allow ALB → ECS traffic
- Check task definition resource limits

---

## Best Practices

### ✅ Do's

- **Test locally first** before pushing
- **Use pull requests** for infrastructure changes
- **Review workflow logs** after each run
- **Monitor CloudWatch** for application logs
- **Tag images** with commit SHA for traceability
- **Set up branch protection** to require PR reviews
- **Use environments** in GitHub for approval workflows

### ❌ Don'ts

- **Don't commit secrets** to repository
- **Don't skip failed builds** - investigate and fix
- **Don't deploy to production** without testing
- **Don't override health checks** without reason
- **Don't manually edit infrastructure** (use Terraform)

---

## Advanced Configurations

### Multi-Environment Deployments

Create separate workflows for environments:

```yaml
# .github/workflows/deploy-staging.yml
on:
  push:
    branches:
      - staging

env:
  AWS_REGION: us-east-1
  ENVIRONMENT: staging
```

### Approval Gates for Production

```yaml
jobs:
  deploy-production:
    environment:
      name: production
      url: ${{ steps.deployment.outputs.url }}
    # ... rest of job
```

Configure environment protection rules in GitHub Settings.

### Slack Notifications

Add notification step:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: 'Deployment ${{ job.status }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Rollback on Failure

```yaml
- name: Rollback on failure
  if: failure()
  run: |
    aws ecs update-service \
      --cluster ${{ env.ECS_CLUSTER }} \
      --service ${{ env.ECS_SERVICE }} \
      --task-definition ${{ env.PREVIOUS_TASK_DEF }} \
      --force-new-deployment
```

---

## Workflow Optimization Tips

### Reduce Build Time

1. **Use Docker layer caching**
```yaml
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
```

2. **Parallelize jobs**
Already implemented in complete-pipeline.yml

3. **Use GitHub-hosted runner caching**
Automatically enabled for npm, pip, etc.

### Cost Optimization

1. **Limit workflow runs**
```yaml
on:
  push:
    branches: [main]
    paths:
      - 'posts/**'  # Only run when relevant files change
```

2. **Cancel in-progress runs**
```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

3. **Use self-hosted runners** for high-volume projects

---

## Security Considerations

### Secrets Management

- ✅ Use GitHub Secrets for sensitive data
- ✅ Use AWS Secrets Manager for application secrets
- ✅ Rotate IAM access keys regularly
- ✅ Use least-privilege IAM policies

### Container Security

- ✅ Enable ECR image scanning (already configured)
- ✅ Use specific image tags (commit SHA)
- ✅ Scan for vulnerabilities before deployment
- ✅ Keep base images updated

### Network Security

- ✅ ECS tasks in private subnets
- ✅ ALB in public subnets
- ✅ Security groups restrict traffic
- ✅ No public IPs on ECS tasks

---

## Monitoring and Logging

### GitHub Actions Logs

- Retained for 90 days
- Downloadable as zip
- Real-time viewing during execution

### AWS CloudWatch Logs

```bash
# View logs for specific service
aws logs tail /ecs/forum-microservices-dev \
  --follow \
  --filter-pattern "ERROR"

# Export logs to S3
aws logs create-export-task \
  --log-group-name /ecs/forum-microservices-dev \
  --from $(date -d '1 day ago' +%s)000 \
  --to $(date +%s)000 \
  --destination your-logs-bucket
```

### Metrics and Alarms

Set up CloudWatch alarms for:
- ECS service CPU/memory usage
- ALB target health
- ECS task failures
- API error rates

---

## Quick Reference

### Manual Workflow Triggers

```bash
# Using GitHub CLI
gh workflow run complete-pipeline.yml
gh workflow run terraform-deploy.yml
gh workflow run deploy-posts.yml

# View status
gh run list --workflow=complete-pipeline.yml

# View logs
gh run view --log
```

### Force Redeployment

```bash
# Force new deployment without code changes
aws ecs update-service \
  --cluster forum-microservices-cluster \
  --service posts-service \
  --force-new-deployment \
  --region us-east-1
```

### Check Workflow Status via API

```bash
curl -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/fikrat86/microservices_docker/actions/runs
```

---

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS ECS Deployment with GitHub Actions](https://docs.github.com/en/actions/deployment/deploying-to-amazon-ecs)
- [Terraform GitHub Actions](https://learn.hashicorp.com/tutorials/terraform/github-actions)
- [Docker Build Push Action](https://github.com/docker/build-push-action)

---

## Support

For issues:
1. Check workflow logs in GitHub Actions tab
2. Review this README and GITHUB_ACTIONS_SETUP.md
3. Check AWS CloudWatch logs
4. Verify IAM permissions
5. Review Terraform plan output

**Last Updated:** November 2025
