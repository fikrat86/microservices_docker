# Deployment Checklist

Use this checklist to ensure successful deployment of the Forum Microservices infrastructure.

## Pre-Deployment

### AWS Account Setup
- [ ] AWS account created and accessible
- [ ] IAM user with admin permissions created
- [ ] AWS CLI installed
- [ ] AWS CLI configured with credentials (`aws configure`)
- [ ] Verify access: `aws sts get-caller-identity`
- [ ] Verify region: `aws configure get region`

### Local Environment
- [ ] Terraform installed (v1.5.0+)
- [ ] Docker installed and running
- [ ] Docker Compose installed
- [ ] Git installed
- [ ] PowerShell 5.1+ available
- [ ] Code editor installed (VS Code recommended)

### Project Setup
- [ ] Repository cloned locally
- [ ] Navigate to project directory
- [ ] Review `README.md`
- [ ] Review `docs/ARCHITECTURE.md`
- [ ] Review `docs/COST_ESTIMATE.md`

## Local Testing (Optional but Recommended)

- [ ] Run `docker-compose up -d`
- [ ] Verify all containers are running: `docker-compose ps`
- [ ] Test Posts service: `http://localhost:3001/api/`
- [ ] Test Threads service: `http://localhost:3002/api/threads`
- [ ] Test Users service: `http://localhost:3003/api/users`
- [ ] Test Nginx gateway: `http://localhost:8080`
- [ ] Check logs: `docker-compose logs`
- [ ] Stop services: `docker-compose down`

## Pre-Deployment Configuration

### Terraform Variables
- [ ] Navigate to `terraform/` directory
- [ ] Copy `terraform.tfvars.example` to `terraform.tfvars`
- [ ] Edit `terraform.tfvars`:
  - [ ] Confirm `aws_region` (default: us-east-1)
  - [ ] Set `environment` (default: dev)
  - [ ] Set `project_name` (default: forum-microservices)
  - [ ] Review resource sizing (cpu, memory, desired_count)
  - [ ] Review scaling limits (min_capacity, max_capacity)
- [ ] Save changes

### Cost Verification
- [ ] Review estimated costs in `docs/COST_ESTIMATE.md`
- [ ] Understand monthly cost range: $105-$225
- [ ] Plan to set up AWS Budget alerts
- [ ] Note: NAT Gateway is largest cost (~$66/month)

## Step 1: Build and Push Docker Images

- [ ] Navigate to project root directory
- [ ] Run: `.\scripts\build-and-push.ps1 -Service all -Region us-east-1`
- [ ] Verify ECR authentication successful
- [ ] Verify Posts image built successfully
- [ ] Verify Threads image built successfully
- [ ] Verify Users image built successfully
- [ ] Verify all images pushed to ECR
- [ ] Check ECR repositories in AWS Console

**Expected Output**: 3 ECR repositories with `:latest` and timestamped tags

## Step 2: Initialize Terraform

- [ ] Navigate to `terraform/` directory
- [ ] Run: `terraform init`
- [ ] Verify providers downloaded
- [ ] Verify no errors in initialization
- [ ] Check `.terraform/` directory created

## Step 3: Plan Infrastructure

- [ ] Run: `terraform plan -var="environment=dev"`
- [ ] Review planned resources (~100+ resources)
- [ ] Verify no errors in plan
- [ ] Check resources to be created:
  - [ ] VPC and subnets (6 total)
  - [ ] Internet Gateway
  - [ ] NAT Gateways (2)
  - [ ] Route tables
  - [ ] Security groups (3)
  - [ ] Application Load Balancer
  - [ ] Target groups (3)
  - [ ] ECR repositories (3)
  - [ ] ECS cluster
  - [ ] ECS task definitions (3)
  - [ ] ECS services (3)
  - [ ] IAM roles and policies
  - [ ] Auto-scaling policies
  - [ ] CodePipeline resources
  - [ ] CloudWatch resources
- [ ] Save plan: `terraform plan -var="environment=dev" -out=tfplan`

## Step 4: Deploy Infrastructure

- [ ] Run: `.\scripts\deploy.ps1 -Action apply`
  - OR: `terraform apply -var="environment=dev"`
- [ ] Review plan one more time
- [ ] Type `yes` to confirm deployment
- [ ] Wait for deployment (15-30 minutes)
- [ ] Monitor for errors
- [ ] Verify no errors during apply

**Expected Duration**: 20-30 minutes

## Step 5: Verify Deployment

### Check Terraform Outputs
- [ ] Run: `terraform output`
- [ ] Note ALB DNS name
- [ ] Note ECR repository URLs
- [ ] Note ECS cluster name
- [ ] Note service names

### Verify AWS Resources

#### VPC
- [ ] Open AWS Console → VPC
- [ ] Verify VPC created (10.0.0.0/16)
- [ ] Verify 4 subnets (2 public, 2 private)
- [ ] Verify Internet Gateway attached
- [ ] Verify 2 NAT Gateways
- [ ] Verify route tables configured

#### Load Balancer
- [ ] Open AWS Console → EC2 → Load Balancers
- [ ] Verify ALB is in "active" state
- [ ] Verify 2 availability zones
- [ ] Note DNS name
- [ ] Open EC2 → Target Groups
- [ ] Verify 3 target groups created
- [ ] Check target health (may take 2-3 minutes)
- [ ] Wait for all targets to be "healthy"

#### ECS
- [ ] Open AWS Console → ECS
- [ ] Verify cluster created
- [ ] Click on cluster
- [ ] Verify 3 services running
- [ ] Click on each service
- [ ] Verify desired count = running count
- [ ] Check task status (should be "RUNNING")
- [ ] Review task logs in CloudWatch

#### ECR
- [ ] Open AWS Console → ECR
- [ ] Verify 3 repositories
- [ ] Check each repository has images
- [ ] Verify `:latest` tag exists

## Step 6: Test Deployed Services

### Get ALB URL
- [ ] Run: `.\scripts\deploy.ps1 -Action output`
- [ ] Copy ALB DNS name
- [ ] Set variable: `$albUrl = "http://<your-alb-dns>"`

### Run Automated Tests
- [ ] Run: `.\scripts\test-services.ps1 -AlbUrl $albUrl`
- [ ] Verify all tests pass
- [ ] Check HTTP 200 responses

### Manual Testing
- [ ] Test root: `Invoke-WebRequest -Uri "$albUrl/" -Method Get`
- [ ] Test Posts: `Invoke-WebRequest -Uri "$albUrl/api/posts" -Method Get`
- [ ] Test Threads: `Invoke-WebRequest -Uri "$albUrl/api/threads" -Method Get`
- [ ] Test Users: `Invoke-WebRequest -Uri "$albUrl/api/users" -Method Get`
- [ ] Test specific thread: `Invoke-WebRequest -Uri "$albUrl/api/threads/1" -Method Get`
- [ ] Test specific user: `Invoke-WebRequest -Uri "$albUrl/api/users/1" -Method Get`

### Browser Testing (Optional)
- [ ] Open browser
- [ ] Navigate to: `http://<alb-dns>/api/threads`
- [ ] Verify JSON response with threads data
- [ ] Navigate to: `http://<alb-dns>/api/users`
- [ ] Verify JSON response with users data

## Step 7: Verify Auto-Scaling (Optional)

- [ ] Open AWS Console → ECS → Clusters
- [ ] Click on cluster → Services → Posts service
- [ ] Click "Update Service"
- [ ] Change desired count to 4
- [ ] Click "Update"
- [ ] Watch tasks starting
- [ ] Verify 4 tasks running
- [ ] Check CloudWatch alarms
- [ ] Reset to 2 tasks

## Step 8: Setup CI/CD (Optional)

### Get CodeCommit URLs
- [ ] Run: `terraform output`
- [ ] Note CodeCommit repository URLs

### Configure Git Credentials
- [ ] Follow AWS CodeCommit setup guide
- [ ] Configure HTTPS Git credentials for AWS CodeCommit
- [ ] OR setup SSH keys

### Push Code to CodeCommit

#### Posts Service
- [ ] Clone CodeCommit repo: `git clone <posts-repo-url> posts-repo`
- [ ] Copy files: `Copy-Item -Recurse posts\* posts-repo\`
- [ ] Commit: `cd posts-repo; git add .; git commit -m "Initial commit"`
- [ ] Push: `git push origin main`
- [ ] Verify pipeline triggered in AWS Console

#### Threads Service
- [ ] Clone CodeCommit repo: `git clone <threads-repo-url> threads-repo`
- [ ] Copy files: `Copy-Item -Recurse threads\* threads-repo\`
- [ ] Commit and push
- [ ] Verify pipeline triggered

#### Users Service
- [ ] Clone CodeCommit repo: `git clone <users-repo-url> users-repo`
- [ ] Copy files: `Copy-Item -Recurse users\* users-repo\`
- [ ] Commit and push
- [ ] Verify pipeline triggered

### Verify Pipelines
- [ ] Open AWS Console → CodePipeline
- [ ] Verify 3 pipelines exist
- [ ] Check pipeline status
- [ ] Monitor pipeline execution
- [ ] Verify successful deployment

## Step 9: Setup Monitoring

### CloudWatch Logs
- [ ] Open AWS Console → CloudWatch → Log groups
- [ ] Verify log group: `/ecs/forum-microservices-dev`
- [ ] Click log group
- [ ] Verify log streams for each service
- [ ] Check recent logs

### CloudWatch Alarms
- [ ] Open CloudWatch → Alarms
- [ ] Verify auto-scaling alarms created
- [ ] Review alarm thresholds

### Container Insights
- [ ] Open CloudWatch → Container Insights
- [ ] Click "View container map"
- [ ] Explore service metrics
- [ ] Review CPU and memory usage

## Step 10: Cost Monitoring

### Setup Budget Alert
- [ ] Open AWS Console → Billing → Budgets
- [ ] Click "Create budget"
- [ ] Select "Cost budget"
- [ ] Set monthly budget: $250
- [ ] Set alert at 80% ($200)
- [ ] Enter email for notifications
- [ ] Create budget

### Enable Cost Explorer
- [ ] Open Billing → Cost Explorer
- [ ] Enable Cost Explorer (if not already enabled)
- [ ] Review current month costs
- [ ] Filter by service to see breakdown

### Check Current Costs
- [ ] Run: `aws ce get-cost-and-usage --time-period Start=2025-11-01,End=2025-11-30 --granularity MONTHLY --metrics UnblendedCost`
- [ ] Review cost breakdown

## Post-Deployment Documentation

- [ ] Document ALB URL in team notes
- [ ] Document CodeCommit URLs
- [ ] Save Terraform outputs
- [ ] Take screenshots for presentation:
  - [ ] Architecture diagram
  - [ ] AWS Console showing ECS cluster
  - [ ] ALB with healthy targets
  - [ ] CloudWatch logs
  - [ ] Cost Explorer breakdown
  - [ ] Working API response in browser
- [ ] Update team contact information in README.md

## Presentation Preparation

- [ ] Review `PROJECT_SUMMARY.md`
- [ ] Review `docs/ARCHITECTURE.md`
- [ ] Review `docs/COST_ESTIMATE.md`
- [ ] Prepare demo script
- [ ] Test demo in your AWS account
- [ ] Prepare to show:
  - [ ] Local development (docker-compose)
  - [ ] Infrastructure code (Terraform)
  - [ ] Live AWS deployment
  - [ ] API responses
  - [ ] CI/CD pipeline
  - [ ] Cost estimate

## Cleanup (After Project Review)

**WARNING**: This will delete all resources and incur no further charges.

- [ ] Decide cleanup date
- [ ] Backup any important data
- [ ] Run: `.\scripts\deploy.ps1 -Action destroy`
- [ ] Confirm with `yes`
- [ ] Wait for destruction (10-15 minutes)
- [ ] Verify all resources deleted:
  - [ ] ECS cluster deleted
  - [ ] ALB deleted
  - [ ] VPC and subnets deleted
  - [ ] ECR repositories deleted
  - [ ] CodePipeline resources deleted
- [ ] Check AWS Console manually for any remaining resources
- [ ] Delete S3 bucket manually if needed (artifact bucket)

## Troubleshooting

### Issue: Terraform apply fails
- [ ] Check AWS credentials: `aws sts get-caller-identity`
- [ ] Verify region matches
- [ ] Check for resource limits (VPCs, Elastic IPs)
- [ ] Review error message carefully
- [ ] Try: `terraform destroy` then re-apply

### Issue: ECS tasks not starting
- [ ] Check ECR images exist
- [ ] Verify IAM roles have correct permissions
- [ ] Check task definition for errors
- [ ] Review CloudWatch logs: `/ecs/forum-microservices-dev`
- [ ] Check security groups

### Issue: Target groups unhealthy
- [ ] Wait 2-3 minutes for health checks
- [ ] Verify ECS tasks are running
- [ ] Check security group allows ALB → ECS traffic
- [ ] Review health check path: `/health`
- [ ] Check task logs for errors

### Issue: Cannot access ALB
- [ ] Wait 5-10 minutes for DNS propagation
- [ ] Verify ALB is "active" state
- [ ] Check security group allows port 80 from internet
- [ ] Try different browser or curl
- [ ] Check listener rules configured

### Issue: High costs
- [ ] Review actual costs in Cost Explorer
- [ ] Check number of running tasks
- [ ] Verify NAT Gateways (expensive)
- [ ] Consider reducing to 1 NAT Gateway for dev
- [ ] Set desired count to 1 per service if testing

## Success Criteria

✅ **Deployment Successful** when:
- [ ] All Terraform resources created without errors
- [ ] All ECS services showing "RUNNING" status
- [ ] All target groups showing "healthy" status
- [ ] ALB accessible via browser
- [ ] All API endpoints returning correct responses
- [ ] CloudWatch logs receiving data
- [ ] Auto-scaling policies active
- [ ] CI/CD pipelines created (if configured)
- [ ] Estimated costs within expected range ($105-225/month)

## Final Verification

- [ ] All services accessible via ALB
- [ ] Health checks passing
- [ ] Logs appearing in CloudWatch
- [ ] Auto-scaling configured and working
- [ ] Documentation complete
- [ ] Team ready to present
- [ ] Screenshots taken
- [ ] Demo practiced

---

**Deployment Status**: [ ] Complete  
**Deployment Date**: _______________  
**Deployed By**: _______________  
**ALB URL**: _______________  
**Notes**: _______________

---

**Checklist Version**: 1.0  
**Last Updated**: November 2025
