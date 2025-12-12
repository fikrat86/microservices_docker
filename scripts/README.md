# Scripts Directory - Quick Reference

This directory contains automation scripts for deploying, managing, and destroying AWS infrastructure.

## 🗑️ Destroy AWS Resources

### Quick Destroy (Recommended)

**Linux/macOS:**
```bash
# Dry run (see what will be destroyed)
./terraform-destroy-all.sh --dry-run

# Destroy with confirmation
./terraform-destroy-all.sh --environment dev

# Destroy without confirmation
./terraform-destroy-all.sh --environment dev --auto-approve
```

**Windows (PowerShell):**
```powershell
# Dry run (see what will be destroyed)
.\terraform-destroy-all.ps1 -DryRun

# Destroy with confirmation
.\terraform-destroy-all.ps1 -Environment dev

# Destroy without confirmation
.\terraform-destroy-all.ps1 -Environment dev -AutoApprove
```

> 📘 **For comprehensive instructions, see [../DESTROY_GUIDE.md](../DESTROY_GUIDE.md)**

## 🚀 Deploy Infrastructure

```powershell
# Plan deployment
.\deploy.ps1 -Action plan -Environment dev

# Apply infrastructure
.\deploy.ps1 -Action apply -Environment dev

# Apply with auto-approve
.\deploy.ps1 -Action apply -Environment dev -AutoApprove

# Destroy infrastructure
.\deploy.ps1 -Action destroy -Environment dev

# Show outputs
.\deploy.ps1 -Action output
```

## 🧹 Cleanup Scripts

### Comprehensive Cleanup (All Regions)
```powershell
# Preview what will be deleted
.\cleanup-all-resources.ps1 -DryRun

# Execute cleanup
.\cleanup-all-resources.ps1
```

### Region-Specific Cleanup
```powershell
# Cleanup specific region
.\cleanup-aws-resources.ps1 -Region us-east-1

# Dry run
.\cleanup-aws-resources.ps1 -Region us-east-1 -DryRun
```

### VPC Cleanup
```powershell
# Simple VPC cleanup
.\simple-vpc-cleanup.ps1
```

### Orphaned Resources
```powershell
# Clean up orphaned resources
.\cleanup-orphaned-resources.ps1
```

## 🏗️ Setup Scripts

### First Deployment Setup
```powershell
# Setup everything for first deployment
.\setup-first-deployment.ps1
```

### Terraform Backend Setup
```powershell
# Setup S3 backend for Terraform state
.\setup-terraform-backend.ps1
```

## 🐳 Container Management

### Build and Push Images
```powershell
# Build and push all service images to ECR
.\build-and-push.ps1
```

## 🧪 Testing

### Test Services
```powershell
# Test all deployed services
.\test-services.ps1
```

## 🔄 CI/CD

### Trigger GitHub Workflows
```powershell
# Trigger GitHub Actions workflows
.\trigger-workflows.ps1
```

## 💾 Data Management

### DynamoDB Management
```powershell
# Manage DynamoDB tables
.\dynamodb-management.ps1
```

### Migrate to DynamoDB
```bash
# Migrate data to DynamoDB
node migrate-to-dynamodb.js
```

## 🌍 Disaster Recovery

### DR Management
```powershell
# Manage disaster recovery setup
.\dr-management.ps1
```

## 📋 Script Comparison

| Script | Purpose | Platform | Use Case |
|--------|---------|----------|----------|
| `terraform-destroy-all.sh` | Destroy all Terraform resources | Linux/macOS | Complete infrastructure teardown |
| `terraform-destroy-all.ps1` | Destroy all Terraform resources | Windows | Complete infrastructure teardown |
| `deploy.ps1` | Deploy/destroy infrastructure | Windows | General Terraform operations |
| `cleanup-all-resources.ps1` | AWS resource cleanup | Windows | When Terraform state unavailable |
| `cleanup-aws-resources.ps1` | Region-specific cleanup | Windows | Targeted cleanup |
| `cleanup-orphaned-resources.ps1` | Orphaned resource cleanup | Windows | Resource leak cleanup |

## 🆘 Which Script Should I Use?

### To Destroy Everything Managed by Terraform
✅ Use `terraform-destroy-all.sh` (Linux/macOS) or `terraform-destroy-all.ps1` (Windows)
- Safest option
- Uses Terraform state
- Handles dependencies correctly
- Supports dry-run

### To Clean Up When Terraform State is Lost/Corrupted
✅ Use `cleanup-all-resources.ps1`
- Manually finds and deletes resources
- Works without Terraform state
- Covers multiple regions

### To Remove Specific Resources in a Region
✅ Use `cleanup-aws-resources.ps1`
- Targeted cleanup
- Single region
- Good for partial cleanup

### To Deploy Infrastructure
✅ Use `deploy.ps1`
- Standard deployment workflow
- Includes destroy action
- Windows PowerShell

## 📖 Documentation

For detailed information:
- **Destruction Guide**: [../DESTROY_GUIDE.md](../DESTROY_GUIDE.md)
- **Deployment Guide**: [../DEPLOYMENT_CHECKLIST.md](../DEPLOYMENT_CHECKLIST.md)
- **Main Documentation**: [../README.md](../README.md)
- **Documentation Index**: [../DOCUMENTATION_INDEX.md](../DOCUMENTATION_INDEX.md)

## ⚠️ Important Notes

1. **Always use dry-run first** when destroying resources
2. **Back up data** before destroying infrastructure
3. **Verify environment** (dev vs prod) before destruction
4. **Check AWS credentials** are correct before running scripts
5. **Review costs** after cleanup to ensure everything is deleted

## 🔒 Safety Checklist

Before destroying infrastructure:
- [ ] Backed up all important data
- [ ] Verified correct environment (dev/prod)
- [ ] Ran dry-run to preview changes
- [ ] Notified team members (if shared environment)
- [ ] Confirmed AWS credentials
- [ ] Reviewed Terraform plan
