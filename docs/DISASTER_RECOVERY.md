# Disaster Recovery Guide

## Overview
This guide explains the disaster recovery (DR) setup for the Forum Microservices application. The DR infrastructure provides business continuity by maintaining a complete secondary deployment in a separate AWS region.

## Architecture

### Primary Region: us-east-1
- Full VPC with public and private subnets across 2 AZs
- ECS Fargate cluster running all three microservices
- Application Load Balancer for traffic distribution
- ECR repositories for container images
- S3 bucket for database backups

### DR Region: us-west-2
- Mirror VPC infrastructure in different region
- Standby ECS Fargate cluster with all services
- Separate Application Load Balancer
- Replicated ECR repositories
- S3 bucket with cross-region replication

## Key Features

### 1. Infrastructure Redundancy
- Complete infrastructure duplication in DR region
- Independent networking and compute resources
- Separate ECR repositories for container images
- Isolated security groups and IAM roles

### 2. Data Replication
- **S3 Cross-Region Replication**: Automatic replication of database backups
- **Container Image Sync**: Manual or automated image synchronization to DR ECR
- **Backup Retention**: 7-day retention policy with lifecycle management

### 3. Auto-Scaling
- Both regions configured with identical auto-scaling policies
- CPU-based scaling (70% target)
- Memory-based scaling (80% target)
- Min: 2 tasks, Max: 10 tasks per service

## DR Operations

### Backup Operations

#### Create Backup
```powershell
.\scripts\dr-management.ps1 -Action backup
```

This will:
1. Copy all database files (db.json) from each service
2. Create a timestamped backup directory
3. Upload to primary S3 bucket
4. Automatically replicate to DR region

#### Restore from Backup
```powershell
.\scripts\dr-management.ps1 -Action restore -RestoreFrom "backup-20241123-120000"
```

### Container Image Synchronization

Sync latest images to DR region:
```powershell
.\scripts\dr-management.ps1 -Action sync
```

This will:
1. Pull latest images from primary ECR
2. Tag for DR region
3. Push to DR ECR repositories

### DR Testing

Test DR site availability:
```powershell
.\scripts\dr-management.ps1 -Action test-dr
```

This validates:
- All DR services are running
- Health checks are passing
- Load balancer is accessible

### Failover to DR Region

Execute failover:
```powershell
.\scripts\dr-management.ps1 -Action failover
```

⚠️ **Warning**: This is a critical operation. It will:
1. Scale up DR services to production capacity
2. Provide DR ALB DNS for traffic redirection
3. Require manual DNS update to complete failover

## Configuration

### Enable/Disable DR

In `terraform/terraform.tfvars`:
```hcl
enable_dr = true  # Set to false to disable DR infrastructure
```

### DR Region Configuration
```hcl
dr_region = "us-west-2"
dr_vpc_cidr = "10.1.0.0/16"
dr_availability_zones = ["us-west-2a", "us-west-2b"]
```

### Backup Settings
```hcl
backup_retention_days = 7
enable_cross_region_backup = true
```

## Deployment

### Initial DR Setup

1. **Deploy DR Infrastructure**:
```powershell
cd terraform
terraform init
terraform plan
terraform apply
```

2. **Sync Container Images**:
```powershell
.\scripts\dr-management.ps1 -Action sync
```

3. **Verify DR Services**:
```powershell
.\scripts\dr-management.ps1 -Action test-dr
```

### Update DR Infrastructure

When updating DR configuration:
```powershell
cd terraform
terraform plan
terraform apply
```

## Recovery Objectives

- **RTO (Recovery Time Objective)**: < 15 minutes
- **RPO (Recovery Point Objective)**: < 1 hour (based on backup frequency)

## Cost Optimization

### Active-Passive Strategy
- DR services run with `desired_count = 0` by default when `enable_dr = false`
- Scale up only during DR events or testing
- Reduces compute costs while maintaining infrastructure readiness

### Storage Costs
- S3 lifecycle policies transition old backups to cheaper storage tiers:
  - Day 0-30: Standard
  - Day 30-90: Standard-IA
  - Day 90+: Glacier

## Monitoring

### Key Metrics to Monitor

1. **Replication Lag**: S3 replication metrics
2. **DR Service Health**: ECS service health checks
3. **Backup Success Rate**: CloudWatch logs for backup operations
4. **Image Sync Status**: Manual verification recommended

### CloudWatch Alarms

Set up alarms for:
- S3 replication failures
- DR ECS service failures
- Backup job failures

## Failback Procedure

After resolving primary region issues:

1. **Verify Primary Region**:
```powershell
.\scripts\test-services.ps1
```

2. **Sync Latest Data**:
- Create backup from DR region
- Restore to primary region

3. **Update DNS**:
- Redirect traffic back to primary ALB

4. **Scale Down DR**:
```powershell
# In Terraform
enable_dr = false
terraform apply
```

## Testing Schedule

### Recommended DR Tests

- **Monthly**: Execute `test-dr` to verify DR site availability
- **Quarterly**: Full failover test during maintenance window
- **Annually**: Complete DR drill with stakeholders

## Troubleshooting

### DR Services Not Starting

1. Check ECR images are synced:
```powershell
aws ecr describe-images --repository-name forum-microservices/users-dev --region us-west-2
```

2. Verify ECS task execution role has ECR permissions

3. Check CloudWatch logs for error messages

### S3 Replication Not Working

1. Verify replication configuration:
```powershell
aws s3api get-bucket-replication --bucket <backup-bucket-name>
```

2. Check IAM replication role permissions

3. Ensure versioning is enabled on both buckets

### High Costs

1. Verify DR services are scaled to 0 when not needed
2. Check S3 lifecycle policies are active
3. Review CloudWatch logs retention

## Security Considerations

- DR region uses separate IAM roles
- Encryption at rest for all S3 backups (AES-256)
- Encryption in transit for all replication
- Security groups restrict access appropriately
- No public access to S3 buckets

## Compliance

The DR setup supports:
- Business continuity requirements
- Data sovereignty (separate regions)
- Audit trail through CloudWatch logs
- Version control of backups

## Additional Resources

- [AWS Disaster Recovery Whitepaper](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-workloads-on-aws.html)
- [ECS Disaster Recovery](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/backup-recovery.html)
- [S3 Replication](https://docs.aws.amazon.com/AmazonS3/latest/userguide/replication.html)
