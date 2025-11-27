# Workflow Execution Guide

## Option 1: Manual Trigger via GitHub Web Interface (Recommended)

### Step 1: Trigger Infrastructure Deployment

1. **Go to GitHub Actions:**
   - Navigate to: https://github.com/fikrat86/microservices_docker/actions

2. **Select Infrastructure Workflow:**
   - Click on "Infrastructure Deployment" in the left sidebar

3. **Run Workflow:**
   - Click the "Run workflow" button (top right)
   - Select branch: `main`
   - Select action: `apply`
   - Click "Run workflow"

4. **Monitor Progress (~15-20 minutes):**
   - Watch the workflow execution
   - Green checkmarks = success
   - Red X = failure
   - Click on workflow run to see detailed logs

5. **Wait for Completion:**
   - ✅ All jobs must complete successfully
   - Check the outputs for ALB URL
   - Verify infrastructure in AWS Console

### Step 2: Trigger Microservices Deployment

**After infrastructure workflow completes successfully:**

1. **Return to GitHub Actions:**
   - Navigate to: https://github.com/fikrat86/microservices_docker/actions

2. **Select Microservices Workflow:**
   - Click on "Microservices CI/CD" in the left sidebar

3. **Run Workflow:**
   - Click the "Run workflow" button
   - Select branch: `main`
   - Click "Run workflow"

4. **Monitor Progress (~8-12 minutes):**
   - Watch build and deployment steps
   - All 3 services will be built and deployed
   - Check for successful ECS updates

5. **Verify Deployment:**
   - Check ALB URL from infrastructure outputs
   - Test API endpoints

---

## Option 2: Using PowerShell Script (Requires GitHub Token)

### Prerequisites

1. **Generate GitHub Personal Access Token:**
   - Go to: https://github.com/settings/tokens
   - Click "Generate new token (classic)"
   - Select scopes: `repo` and `workflow`
   - Copy the token

2. **Set Environment Variable:**
   ```powershell
   $env:GITHUB_TOKEN = "your_github_token_here"
   ```

### Execute Script

**For both workflows sequentially:**
```powershell
cd scripts
.\trigger-workflows.ps1 -Workflow both -TerraformAction apply
```

**For infrastructure only:**
```powershell
.\trigger-workflows.ps1 -Workflow infrastructure -TerraformAction apply
```

**For microservices only:**
```powershell
.\trigger-workflows.ps1 -Workflow microservices
```

---

## Option 3: Using GitHub CLI (If installed)

### Install GitHub CLI (if not installed)
```powershell
winget install --id GitHub.cli
```

### Trigger Infrastructure Workflow
```powershell
gh workflow run infrastructure.yml --ref main --field action=apply
```

### Monitor Workflow
```powershell
gh run watch
```

### Trigger Microservices Workflow
```powershell
gh workflow run microservices.yml --ref main
```

---

## Verification Steps

### After Infrastructure Deployment

1. **Check AWS Console:**
   - VPC: https://console.aws.amazon.com/vpc/
   - ECS Clusters: https://console.aws.amazon.com/ecs/
   - Load Balancers: https://console.aws.amazon.com/ec2/v2/home#LoadBalancers
   - DynamoDB: https://console.aws.amazon.com/dynamodb/

2. **Get ALB URL:**
   ```powershell
   cd terraform
   terraform output alb_dns_name
   ```

3. **Verify Resources:**
   ```powershell
   # Check ECS clusters
   aws ecs list-clusters
   
   # Check services
   aws ecs list-services --cluster forum-microservices-cluster-dev
   
   # Check DynamoDB tables
   aws dynamodb list-tables
   ```

### After Microservices Deployment

1. **Test Endpoints:**
   ```powershell
   $albUrl = "http://your-alb-dns-name"
   
   # Test users service
   Invoke-WebRequest -Uri "$albUrl/api/users" | ConvertFrom-Json
   
   # Test threads service
   Invoke-WebRequest -Uri "$albUrl/api/threads" | ConvertFrom-Json
   
   # Test posts service
   Invoke-WebRequest -Uri "$albUrl/api/posts" | ConvertFrom-Json
   ```

2. **Check ECS Service Status:**
   ```powershell
   aws ecs describe-services `
     --cluster forum-microservices-cluster-dev `
     --services forum-microservices-users-dev forum-microservices-posts-dev forum-microservices-threads-dev
   ```

3. **View Container Logs:**
   ```powershell
   # Get log streams
   aws logs describe-log-streams `
     --log-group-name /ecs/forum-microservices-dev `
     --order-by LastEventTime `
     --descending `
     --max-items 10
   ```

---

## Expected Timeline

| Stage | Duration | Description |
|-------|----------|-------------|
| **Infrastructure Deployment** | 15-20 min | VPC, ECS, ALB, DynamoDB, etc. |
| - Validate | 1-2 min | Format, validation, security scan |
| - Plan | 3-5 min | Generate execution plan |
| - Apply | 10-15 min | Create AWS resources |
| **Microservices Deployment** | 8-12 min | Build, scan, push, deploy services |
| - Change Detection | 30 sec | Identify changed services |
| - Test | 2-3 min | Lint, unit tests, security audit |
| - Build | 3-5 min | Docker build and push to ECR |
| - Deploy | 2-4 min | Update ECS services, wait stable |
| **Total** | **23-32 min** | Complete end-to-end deployment |

---

## Troubleshooting

### Infrastructure Workflow Fails

**Common Issues:**
- AWS credentials not configured
- S3 backend bucket creation fails
- Resource already exists errors
- Terraform validation errors

**Solutions:**
1. Check GitHub Secrets:
   - AWS_ACCESS_KEY_ID
   - AWS_SECRET_ACCESS_KEY
   - AWS_ACCOUNT_ID

2. Review workflow logs for specific errors

3. Check import script ran successfully

### Microservices Workflow Fails

**Common Issues:**
- Infrastructure not deployed
- ECR repositories don't exist
- ECS services don't exist
- Docker build fails

**Solutions:**
1. Ensure infrastructure deployed successfully first
2. Check ECR repositories exist
3. Review build logs
4. Verify ECS cluster is running

### Deployment Verification Fails

**Common Issues:**
- Services not healthy
- ALB health checks failing
- Wrong port configurations

**Solutions:**
1. Check ECS service events
2. Review container logs
3. Verify security group rules
4. Check ALB target group health

---

## Next Steps After Successful Deployment

1. **Data Migration:**
   ```powershell
   cd scripts
   .\dynamodb-management.ps1 -Action migrate
   .\dynamodb-management.ps1 -Action verify
   ```

2. **Test Application:**
   - Create test users, threads, posts
   - Verify CRUD operations
   - Test cross-service communication

3. **Monitor:**
   - CloudWatch dashboards
   - ECS service metrics
   - ALB metrics
   - DynamoDB metrics

4. **Documentation:**
   - Note ALB URL
   - Document any issues
   - Update runbook if needed
