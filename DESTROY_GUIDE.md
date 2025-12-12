# AWS Resource Destruction Guide

This guide provides complete instructions for destroying all AWS resources created by Terraform in this project.

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Destruction Methods](#destruction-methods)
4. [Step-by-Step Instructions](#step-by-step-instructions)
5. [Post-Destruction Cleanup](#post-destruction-cleanup)
6. [Troubleshooting](#troubleshooting)
7. [Safety Considerations](#safety-considerations)

## Overview

This project creates AWS infrastructure using Terraform. When you want to completely remove all resources, you have several options:

- **Terraform Destroy** (Recommended): Uses Terraform to properly destroy all managed resources
- **Manual AWS Cleanup**: Use AWS CLI or Console to manually delete resources
- **Cleanup Scripts**: Use the provided PowerShell scripts for comprehensive cleanup

## Prerequisites

Before destroying resources, ensure you have:

- ✅ AWS CLI installed and configured
- ✅ Terraform installed (version >= 1.5.0)
- ✅ Valid AWS credentials with appropriate permissions
- ✅ Access to the Terraform state (stored in S3)
- ⚠️ **Backup any important data** before proceeding

## Destruction Methods

### Method 1: Terraform Destroy (Recommended)

This is the safest and cleanest method as Terraform tracks all resources.

#### Using the Dedicated Destroy Script

**For Linux/macOS:**
```bash
# Dry run to see what will be destroyed
./scripts/terraform-destroy-all.sh --dry-run

# Destroy with confirmation prompt
./scripts/terraform-destroy-all.sh --environment dev

# Destroy without confirmation (use with caution!)
./scripts/terraform-destroy-all.sh --environment dev --auto-approve
```

**For Windows (PowerShell):**
```powershell
# Dry run to see what will be destroyed
.\scripts\terraform-destroy-all.ps1 -DryRun

# Destroy with confirmation prompt
.\scripts\terraform-destroy-all.ps1 -Environment dev

# Destroy without confirmation (use with caution!)
.\scripts\terraform-destroy-all.ps1 -Environment dev -AutoApprove
```

#### Using the Deploy Script

```powershell
# Navigate to scripts directory
cd scripts

# Run destroy action
.\deploy.ps1 -Action destroy -Environment dev

# Or with auto-approve
.\deploy.ps1 -Action destroy -Environment dev -AutoApprove
```

#### Manual Terraform Commands

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform (loads state from S3)
terraform init

# Preview what will be destroyed
terraform plan -destroy -var="environment=dev"

# Destroy resources with confirmation
terraform destroy -var="environment=dev"

# Or without confirmation
terraform destroy -var="environment=dev" -auto-approve
```

### Method 2: PowerShell Cleanup Scripts

If Terraform state is corrupted or unavailable, use these scripts:

```powershell
# Complete cleanup (all regions)
.\scripts\cleanup-all-resources.ps1

# Dry run first
.\scripts\cleanup-all-resources.ps1 -DryRun

# Specific region
.\scripts\cleanup-aws-resources.ps1 -Region us-east-1

# Cleanup orphaned resources
.\scripts\cleanup-orphaned-resources.ps1
```

### Method 3: GitHub Actions Workflow

If you have GitHub Actions configured:

1. Go to your repository on GitHub
2. Navigate to Actions tab
3. Find the infrastructure workflow
4. Manually trigger the destroy action (if available)

## Step-by-Step Instructions

### Complete Infrastructure Destruction

Follow these steps for a complete teardown:

#### Step 1: Verify Current Infrastructure

```bash
cd terraform
terraform init
terraform plan -var="environment=dev"
```

This shows you what currently exists.

#### Step 2: Back Up Critical Data

⚠️ **Important:** Back up any data you need to keep:

- DynamoDB table data
- S3 bucket contents
- CloudWatch logs
- ECR container images

```bash
# Example: Export DynamoDB tables
aws dynamodb scan --table-name forum-microservices-users-dev > users-backup.json
aws dynamodb scan --table-name forum-microservices-posts-dev > posts-backup.json
aws dynamodb scan --table-name forum-microservices-threads-dev > threads-backup.json

# Example: Sync S3 buckets
aws s3 sync s3://your-backup-bucket ./local-backup/
```

#### Step 3: Run Terraform Destroy

```bash
# Use the dedicated script (recommended)
./scripts/terraform-destroy-all.sh --environment dev

# Or use Terraform directly
cd terraform
terraform destroy -var="environment=dev"
```

Type `yes` when prompted to confirm destruction.

#### Step 4: Verify Destruction

```bash
# Check ECS clusters
aws ecs list-clusters --region us-east-1

# Check VPCs
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=forum-microservices" --region us-east-1

# Check load balancers
aws elbv2 describe-load-balancers --region us-east-1

# Check ECR repositories
aws ecr describe-repositories --region us-east-1
```

All commands should return empty results or no forum-microservices resources.

#### Step 5: Clean Up Terraform Backend (Optional)

If you want to remove the Terraform state backend:

```bash
# Delete S3 state bucket (WARNING: This removes all state history)
aws s3 rb s3://forum-microservices-terraform-state-dev --force

# Delete DynamoDB lock table
aws dynamodb delete-table --table-name forum-microservices-terraform-locks
```

⚠️ **Warning:** Only do this if you're completely done with the infrastructure.

#### Step 6: Clean Up Remaining Resources

Some resources may not be managed by Terraform:

```bash
# Delete CloudWatch log groups
aws logs describe-log-groups --log-group-name-prefix "/ecs/forum-microservices" --query 'logGroups[*].logGroupName' --output text | \
xargs -I {} aws logs delete-log-group --log-group-name {}

# Delete ECR repositories (if not in Terraform)
aws ecr describe-repositories --query 'repositories[?contains(repositoryName, `forum-microservices`)].repositoryName' --output text | \
xargs -I {} aws ecr delete-repository --repository-name {} --force
```

## Post-Destruction Cleanup

After destroying infrastructure:

### Verify in AWS Console

1. Log in to AWS Console
2. Check these services:
   - ECS (Clusters, Services, Task Definitions)
   - EC2 (Load Balancers, Target Groups, VPCs)
   - ECR (Repositories)
   - DynamoDB (Tables)
   - S3 (Buckets)
   - IAM (Roles, Policies)
   - CloudWatch (Log Groups)

### Remove Local State Files

```bash
# Remove local Terraform files
cd terraform
rm -rf .terraform/
rm -f terraform.tfstate
rm -f terraform.tfstate.backup
rm -f tfplan
```

### Update Documentation

If this was a permanent teardown, update your README and documentation to reflect that the infrastructure is no longer deployed.

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Error deleting VPC: DependencyViolation"

**Solution:** VPC has dependencies that weren't cleaned up. Run cleanup script:

```powershell
.\scripts\simple-vpc-cleanup.ps1
```

#### Issue: "Error: Failed to load state"

**Solution:** State file is corrupted or unavailable. Use manual cleanup:

```powershell
.\scripts\cleanup-all-resources.ps1
```

#### Issue: "Error deleting Load Balancer: ResourceInUse"

**Solution:** Wait for services to fully stop, then retry:

```bash
# Stop all ECS services first
aws ecs list-services --cluster forum-microservices-cluster --query 'serviceArns' --output text | \
xargs -I {} aws ecs update-service --cluster forum-microservices-cluster --service {} --desired-count 0

# Wait 2 minutes
sleep 120

# Retry destroy
terraform destroy -var="environment=dev"
```

#### Issue: "Error: Some resources couldn't be destroyed"

**Solution:** Use targeted destroy for problematic resources:

```bash
# Destroy specific resources first
terraform destroy -target=aws_ecs_service.users -var="environment=dev"
terraform destroy -target=aws_ecs_service.posts -var="environment=dev"
terraform destroy -target=aws_ecs_service.threads -var="environment=dev"

# Then destroy everything else
terraform destroy -var="environment=dev"
```

#### Issue: "Cannot delete non-empty S3 bucket"

**Solution:** Empty bucket before deletion:

```bash
aws s3 rm s3://forum-microservices-terraform-state-dev --recursive
aws s3 rb s3://forum-microservices-terraform-state-dev
```

#### Issue: "DynamoDB table in DELETING state"

**Solution:** Wait for the deletion to complete (can take several minutes):

```bash
# Check status
aws dynamodb describe-table --table-name forum-microservices-users-dev

# Wait and retry
```

## Safety Considerations

### Before Destroying

- [ ] **Back up all data** you need to keep
- [ ] **Verify the environment** you're destroying (dev vs. prod)
- [ ] **Check for dependencies** with other projects
- [ ] **Notify team members** if in a shared environment
- [ ] **Review the destroy plan** before confirming
- [ ] **Consider using dry-run** first

### Cost Implications

Destroying resources will:
- ✅ Stop all ongoing AWS charges
- ✅ Remove all compute resources (ECS tasks)
- ✅ Delete all data storage (DynamoDB, S3)
- ⚠️ May incur small charges for data transfer during deletion

### Recovery

If you need to redeploy after destruction:

```bash
# Redeploy infrastructure
cd terraform
terraform init
terraform plan -var="environment=dev"
terraform apply -var="environment=dev"

# Restore data from backups
# (Restore your DynamoDB and S3 data here)
```

## Resource Destruction Checklist

Use this checklist when destroying infrastructure:

- [ ] Backed up all important data
- [ ] Verified correct environment (dev/prod)
- [ ] Notified team members
- [ ] Reviewed destroy plan
- [ ] Confirmed AWS credentials
- [ ] Executed terraform destroy
- [ ] Verified all resources deleted
- [ ] Cleaned up CloudWatch logs
- [ ] Removed ECR images (if needed)
- [ ] Deleted state backend (if permanent)
- [ ] Removed local state files
- [ ] Updated documentation

## Quick Reference

### One-Command Destroy (With Confirmation)

```bash
# Linux/macOS
./scripts/terraform-destroy-all.sh --environment dev

# Windows
.\scripts\terraform-destroy-all.ps1 -Environment dev
```

### One-Command Destroy (No Confirmation - USE WITH CAUTION!)

```bash
# Linux/macOS
./scripts/terraform-destroy-all.sh --environment dev --auto-approve

# Windows
.\scripts\terraform-destroy-all.ps1 -Environment dev -AutoApprove
```

### Dry Run (See what would be destroyed)

```bash
# Linux/macOS
./scripts/terraform-destroy-all.sh --dry-run

# Windows
.\scripts\terraform-destroy-all.ps1 -DryRun
```

## Support

If you encounter issues not covered in this guide:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review Terraform error messages carefully
3. Check AWS Console for resource states
4. Review CloudWatch logs for application errors

## Related Documentation

- [README.md](README.md) - Main project documentation
- [DEPLOYMENT_CHECKLIST.md](DEPLOYMENT_CHECKLIST.md) - Deployment guide
- [terraform/](terraform/) - Terraform configuration files
