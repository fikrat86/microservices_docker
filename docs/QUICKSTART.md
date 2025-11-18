# Quick Start Guide

## Prerequisites Checklist

- [ ] AWS Account with admin access
- [ ] AWS CLI installed and configured
- [ ] Terraform installed (v1.5+)
- [ ] Docker installed
- [ ] Git installed
- [ ] PowerShell 5.1+ (Windows)

## Quick Deployment Steps

### 1. Local Development (5 minutes)

```powershell
# Clone repository
cd microservices_docker

# Start all services locally
docker-compose up -d

# Test services
Invoke-WebRequest -Uri "http://localhost:8080/threads/api/threads" -Method Get
```

**Access**:
- Gateway: http://localhost:8080
- Posts: http://localhost:3001
- Threads: http://localhost:3002
- Users: http://localhost:3003

### 2. AWS Deployment (30-45 minutes)

#### Step 1: Configure AWS
```powershell
aws configure
# Enter your AWS credentials
```

#### Step 2: Build & Push Images
```powershell
.\scripts\build-and-push.ps1 -Service all -Region us-east-1
```

#### Step 3: Configure Terraform
```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars if needed
```

#### Step 4: Deploy Infrastructure
```powershell
.\scripts\deploy.ps1 -Action apply -AutoApprove
```

#### Step 5: Get Service URLs
```powershell
.\scripts\deploy.ps1 -Action output
```

#### Step 6: Test Deployment
```powershell
$albUrl = "http://$(cd terraform; terraform output -raw alb_dns_name)"
.\scripts\test-services.ps1 -AlbUrl $albUrl
```

### 3. Setup CI/CD (Optional)

```powershell
# Get CodeCommit repo URLs
cd terraform
terraform output

# Clone repositories and push code
# (Follow instructions in README.md)
```

## Common Commands

### Local Development

```powershell
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down

# Rebuild after changes
docker-compose up -d --build
```

### AWS Management

```powershell
# Deploy/Update infrastructure
.\scripts\deploy.ps1 -Action apply

# View outputs
.\scripts\deploy.ps1 -Action output

# Destroy everything
.\scripts\deploy.ps1 -Action destroy

# Build and push new images
.\scripts\build-and-push.ps1 -Service posts
```

### Monitoring

```powershell
# View ECS service status
aws ecs describe-services --cluster forum-microservices-cluster-dev --services forum-microservices-posts-service-dev

# View CloudWatch logs
aws logs tail /ecs/forum-microservices-dev --follow

# Check ALB health
aws elbv2 describe-target-health --target-group-arn <arn>
```

## API Endpoints

### Base URL
```
http://<ALB_DNS_NAME>
```

### Posts Service
```
GET /api/posts/in-thread/:threadId   - Get posts in thread
GET /api/posts/by-user/:userId       - Get posts by user
```

### Threads Service
```
GET /api/threads                     - Get all threads
GET /api/threads/:threadId           - Get specific thread
```

### Users Service
```
GET /api/users                       - Get all users
GET /api/users/:userId               - Get specific user
```

### Health Checks
```
GET /health                          - ALB health check
```

## Troubleshooting

### Issue: ECS tasks not starting

```powershell
# Check task status
aws ecs describe-tasks --cluster forum-microservices-cluster-dev --tasks <task-arn>

# Check logs
aws logs tail /ecs/forum-microservices-dev --follow
```

### Issue: 503 errors from ALB

```powershell
# Check target health
aws elbv2 describe-target-health --target-group-arn <arn>

# Verify security groups
# ALB SG should allow 80/443 from internet
# ECS SG should allow 3000 from ALB SG
```

### Issue: Cannot access ALB

- Wait 5-10 minutes for DNS propagation
- Verify ALB is in "active" state
- Check security group rules

## Cost Control

### Monitor Costs
```powershell
# View current charges
aws ce get-cost-and-usage --time-period Start=2025-11-01,End=2025-11-30 --granularity MONTHLY --metrics UnblendedCost
```

### Reduce Costs
```powershell
# Stop all services (keeps infrastructure)
aws ecs update-service --cluster forum-microservices-cluster-dev --service forum-microservices-posts-service-dev --desired-count 0
aws ecs update-service --cluster forum-microservices-cluster-dev --service forum-microservices-threads-service-dev --desired-count 0
aws ecs update-service --cluster forum-microservices-cluster-dev --service forum-microservices-users-service-dev --desired-count 0

# Destroy everything
.\scripts\deploy.ps1 -Action destroy
```

## Project Structure Reference

```
microservices_docker/
├── posts/           - Posts microservice
├── threads/         - Threads microservice
├── users/           - Users microservice
├── terraform/       - Infrastructure as Code
├── scripts/         - Deployment scripts
├── nginx/           - Local proxy config
├── docs/            - Documentation
└── docker-compose.yml
```

## Key Files

| File | Purpose |
|------|---------|
| `README.md` | Complete documentation |
| `terraform/main.tf` | Main Terraform config |
| `terraform/variables.tf` | Terraform variables |
| `docker-compose.yml` | Local development |
| `posts/buildspec.yml` | CI/CD build config |
| `scripts/deploy.ps1` | Deployment script |

## Next Steps

1. ✅ Deploy infrastructure to AWS
2. ✅ Test all endpoints
3. ⚠️ Set up CodeCommit and push code
4. ⚠️ Configure custom domain (optional)
5. ⚠️ Enable HTTPS with ACM certificate
6. ⚠️ Set up monitoring alerts
7. ⚠️ Configure backup strategy
8. ⚠️ Document team procedures

## Support

- AWS Documentation: https://docs.aws.amazon.com/
- Terraform Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- GitHub Issues: [Your repo URL]

---

**Quick Reference Version**: 1.0  
**Last Updated**: November 2025
