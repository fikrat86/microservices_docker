# Disaster Recovery (DR) Setup Guide

## Overview
This infrastructure supports optional Disaster Recovery in a secondary AWS region. DR is **disabled by default** to avoid unnecessary costs and deployment complexity.

## Current DR Configuration
- **Primary Region**: us-east-1 (Virginia)
- **DR Region**: us-east-2 (Ohio)
- **Status**: DISABLED (enable_dr = false)

## Why us-east-2 for DR?
- **Geographic diversity**: Different AWS Availability Zone group from us-east-1
- **Low latency**: Close proximity for fast replication
- **Cost-effective**: Same pricing tier as us-east-1
- **ECR support**: Full support for all AWS services

## Alternative DR Regions
You can use any of these regions for DR:

| Region | Location | Notes |
|--------|----------|-------|
| us-east-2 | Ohio | ✅ **Recommended** - Low latency, cost-effective |
| us-west-1 | California | Higher latency, slightly higher costs |
| us-west-2 | Oregon | Higher latency, similar costs |
| ca-central-1 | Canada | Data sovereignty option |

⚠️ **Avoid us-west-2 temporarily** - Previous deployments created orphaned state

## How to Enable DR

### Step 1: Choose Your DR Region
Edit `terraform/variables.tf`:
```hcl
variable "dr_region" {
  description = "AWS region for disaster recovery"
  type        = string
  default     = "us-east-2"  # Change this to your desired region
}
```

### Step 2: Enable DR in Terraform Variables
Edit `terraform/terraform.tfvars`:
```hcl
enable_dr = true
enable_global_tables = true  # Optional: For DynamoDB multi-region replication
```

### Step 3: DR Resources That Will Be Created
When enabled, the following will be deployed in the DR region:

#### S3 Resources
- DR backup S3 bucket with versioning
- Encryption and lifecycle policies
- Cross-region replication from primary

#### DynamoDB Resources (if enable_global_tables = true)
- Replica tables for users, threads, posts
- Global Table replication (bi-directional)
- CloudWatch alarms for DR tables
- Backup vault for DR region
- Automatic failover capability

#### Backup Resources
- AWS Backup vault in DR region
- Backup copy actions from primary to DR
- 30-day retention policy

### Step 4: Deploy DR Infrastructure

#### Option A: Via GitHub Actions Workflow
```bash
gh workflow run infrastructure.yml \
  -f action=apply
```

Make sure your `terraform/terraform.tfvars` has:
```hcl
enable_dr = true
enable_global_tables = true
```

#### Option B: Locally
```bash
cd terraform
terraform init
terraform plan -var="enable_dr=true" -var="enable_global_tables=true"
terraform apply -var="enable_dr=true" -var="enable_global_tables=true"
```

### Step 5: Create ECR Repositories in DR Region
**Important**: You must manually create ECR repositories in the DR region:

```bash
# Set DR region
DR_REGION="us-east-2"

# Create ECR repositories
aws ecr create-repository --repository-name forum-microservices/users --region $DR_REGION
aws ecr create-repository --repository-name forum-microservices/posts --region $DR_REGION
aws ecr create-repository --repository-name forum-microservices/threads --region $DR_REGION
aws ecr create-repository --repository-name forum-microservices/gateway --region $DR_REGION
```

Or use the automated script:
```powershell
.\scripts\create-dr-ecr.ps1 -DrRegion us-east-2
```

### Step 6: Push Docker Images to DR ECR
You'll need to tag and push images to both regions:

```bash
# Login to DR ECR
aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin 949848044200.dkr.ecr.us-east-2.amazonaws.com

# Tag and push each service
docker tag forum-microservices/users:latest 949848044200.dkr.ecr.us-east-2.amazonaws.com/forum-microservices/users:latest
docker push 949848044200.dkr.ecr.us-east-2.amazonaws.com/forum-microservices/users:latest

# Repeat for posts, threads, gateway
```

## Cost Estimate with DR Enabled

### Additional Monthly Costs:
- **DynamoDB Global Tables**: ~$25-50 (replication costs)
- **S3 Cross-Region Replication**: ~$10-20 (data transfer)
- **DR Region Infrastructure**: ~$50-100 (VPC, ALB, ECS in standby)
- **Backup Storage**: ~$5-10 (DR vault storage)

**Total Additional Cost**: ~$90-180/month

## Disabling DR

To disable DR and save costs:

### Step 1: Update Variables
Edit `terraform/terraform.tfvars`:
```hcl
enable_dr = false
enable_global_tables = false
```

### Step 2: Destroy DR Resources
```bash
terraform apply -var="enable_dr=false" -var="enable_global_tables=false"
```

This will:
- Remove all DR region resources
- Stop S3 replication
- Delete DynamoDB replicas
- Preserve primary region data

### Step 3: Manually Delete DR ECR (Optional)
```bash
aws ecr delete-repository --repository-name forum-microservices/users --region us-east-2 --force
aws ecr delete-repository --repository-name forum-microservices/posts --region us-east-2 --force
aws ecr delete-repository --repository-name forum-microservices/threads --region us-east-2 --force
aws ecr delete-repository --repository-name forum-microservices/gateway --region us-east-2 --force
```

## Testing DR Failover

### Manual Failover Test:
1. Stop primary region ECS services:
   ```bash
   aws ecs update-service --cluster forum-microservices-cluster-dev \
     --service forum-microservices-users-service-dev \
     --desired-count 0 --region us-east-1
   ```

2. Start DR region services:
   ```bash
   aws ecs update-service --cluster forum-microservices-cluster-dev-dr \
     --service forum-microservices-users-service-dev \
     --desired-count 2 --region us-east-2
   ```

3. Update Route53/DNS to point to DR ALB

### Automatic Failover:
- Use Route53 health checks and failover routing
- Configure CloudWatch alarms to trigger failover
- Set up Lambda functions for automated failover

## Monitoring DR Health

CloudWatch alarms created for DR:
- `forum-microservices-users-throttles-dev-dr` - DynamoDB throttling
- S3 replication metrics
- DynamoDB replication lag

Check replication status:
```bash
# DynamoDB replication status
aws dynamodb describe-table --table-name forum-microservices-users-dev --region us-east-1 \
  | jq '.Table.Replicas'

# S3 replication status  
aws s3api get-bucket-replication --bucket forum-microservices-db-backups-dev-ACCOUNT_ID
```

## Troubleshooting

### Issue: DynamoDB Global Tables Timeout
**Symptom**: "timeout while waiting for state to become 'ACTIVE'"
**Solution**: 
- Wait 45-60 minutes for initial replication
- Check AWS Service Health Dashboard
- Verify IAM permissions for replication

### Issue: S3 Replication Not Working
**Symptom**: Objects not appearing in DR bucket
**Solution**:
- Verify IAM replication role exists
- Check bucket versioning is enabled
- Verify replication rule is active

### Issue: ECR Image Pull Errors in DR
**Symptom**: "pull image manifest... not found"
**Solution**:
- Create ECR repositories in DR region
- Push Docker images to DR ECR
- Update ECS task definitions to use DR ECR URLs

## Best Practices

1. **Test failover regularly** (monthly recommended)
2. **Monitor replication lag** - Set CloudWatch alarms
3. **Keep images synced** - Automate image replication
4. **Document runbook** - DR activation procedures
5. **Cost optimization** - Use DR with minimal standby capacity

## Support

For questions or issues:
1. Check Terraform logs: `terraform plan -var="enable_dr=true"`
2. Review AWS CloudWatch logs
3. Consult `TROUBLESHOOTING.md`
4. Check GitHub Actions workflow logs
