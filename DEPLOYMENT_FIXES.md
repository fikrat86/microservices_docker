# Deployment Fixes and Best Practices

## Overview
This document captures all critical fixes applied to ensure successful deployments.

## ✅ Critical Fixes Applied

### 1. Gateway Container Configuration (Dockerfile.nginx)
**Issue**: 504 Gateway Timeout errors
**Root Causes**:
- Missing `curl` for ECS health checks
- Conflicting nginx configurations in `/etc/nginx/conf.d/`
- Security group blocking port 80

**Fixes Applied**:
```dockerfile
# Install curl for health checks
RUN apk add --no-cache curl

# Remove ALL conf.d files to prevent conflicts
RUN rm -rf /etc/nginx/conf.d/*

# Validate nginx config during build
RUN nginx -t
```

**Status**: ✅ FIXED - All gateway targets healthy

---

### 2. Security Groups (terraform/security_groups.tf)
**Issue**: ALB could not reach gateway containers on port 80
**Root Cause**: ECS security group only allowed port 3000

**Fix Applied**:
```hcl
# Added port 80 ingress for gateway
ingress {
  description     = "HTTP traffic from ALB for gateway"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.alb.id]
}

# Added inter-service communication on port 80
ingress {
  description = "Allow inter-service communication on port 80"
  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  self        = true
}
```

**Status**: ✅ FIXED - Gateway accessible on port 80

---

### 3. Microservice Routing (users/posts/threads server.js)
**Issue**: Frontend showing services as "Offline" (404 errors)
**Root Cause**: ALB forwards full path `/api/users/health` but services only had `/health` endpoint

**Fix Applied**: Dual routing support
```javascript
// Health check endpoint (for direct ALB target group health checks)
router.get('/health', async (ctx) => {
  ctx.body = { status: 'healthy', service: SERVICE_NAME, timestamp: new Date().toISOString() };
});

// Health check endpoint (for API calls through ALB path-based routing)
router.get('/api/users/health', async (ctx) => {
  ctx.body = { status: 'healthy', service: SERVICE_NAME, timestamp: new Date().toISOString() };
});

// Data endpoints (both root and prefixed)
router.get('/', async (ctx) => {
  ctx.body = db.users;
});

router.get('/api/users', async (ctx) => {
  ctx.body = db.users;
});
```

**Rationale**:
- ALB target group health checks use `/health` directly on port 3000
- Frontend API calls go through ALB routing: `/api/users/health` → users service receives full path
- Both endpoints needed to support both access patterns

**Status**: ✅ FIXED - All endpoints returning 200 OK

---

### 4. DR Provider Configuration (terraform/main.tf)
**Issue**: "Provider configuration not present" errors
**Root Cause**: DR resources referenced `provider = aws.dr` but provider wasn't defined

**Fix Applied**:
```hcl
provider "aws" {
  alias  = "dr"
  region = var.dr_region
}
```

**Status**: ✅ FIXED - DR resources conditional and properly configured

---

## 🔍 Verification Checklist

### Before Deployment
- [ ] `terraform fmt -check -recursive` passes
- [ ] `terraform validate` succeeds
- [ ] All workflows pass validation
- [ ] AWS credentials configured correctly

### Infrastructure Deployment
- [ ] S3 backend bucket exists: `forum-microservices-terraform-state-dev-v2`
- [ ] DynamoDB lock table exists: `forum-microservices-terraform-locks-v2`
- [ ] Terraform init succeeds with backend configuration
- [ ] `enable_dr=false` for standard deployments
- [ ] `enable_global_tables=false` for cost optimization

### Microservices Deployment
- [ ] All ECR repositories exist
- [ ] Gateway Dockerfile.nginx includes curl
- [ ] Gateway Dockerfile.nginx removes conf.d files
- [ ] All microservices have dual routing (/health and /api/{service}/health)
- [ ] Security groups allow port 80 AND 3000

### Post-Deployment Verification
```bash
# 1. Check all target groups are healthy
aws elbv2 describe-target-health --target-group-arn <TG_ARN>

# 2. Test health endpoints
curl http://<ALB_DNS>/api/users/health
curl http://<ALB_DNS>/api/posts/health
curl http://<ALB_DNS>/api/threads/health

# 3. Test data endpoints
curl http://<ALB_DNS>/api/users
curl http://<ALB_DNS>/api/posts
curl http://<ALB_DNS>/api/threads

# 4. Verify frontend loads
curl http://<ALB_DNS>/
```

**Expected Results**:
- All health checks: `200 OK` with `{"status":"healthy",...}`
- All data endpoints: `200 OK` with JSON arrays
- Frontend: `200 OK` with HTML content
- Services show as "Online" in dashboard

---

## 🚀 Deployment Commands

### Infrastructure
```bash
# Plan
terraform plan -var="enable_global_tables=false" -var="enable_dr=false"

# Apply
terraform apply -var="enable_global_tables=false" -var="enable_dr=false" -auto-approve
```

### Microservices
```bash
# Trigger via GitHub Actions
git add .
git commit -m "Update microservices"
git push origin main

# Or manual force deployment
aws ecs update-service --cluster forum-microservices-cluster-dev \
  --service forum-microservices-<SERVICE>-service-dev \
  --force-new-deployment
```

---

## 📊 Current Status

### Infrastructure
- ✅ VPC with public/private subnets in 2 AZs
- ✅ Application Load Balancer (ALB)
- ✅ ECS Fargate cluster
- ✅ ECR repositories for all services
- ✅ Security groups with port 80 + 3000
- ✅ CloudWatch log groups

### Services Running
- ✅ **Gateway** (nginx:alpine + curl): 2 tasks, port 80, HEALTHY
- ✅ **Users Service** (Node.js): 2 tasks, port 3000, HEALTHY
- ✅ **Posts Service** (Node.js): 2 tasks, port 3000, HEALTHY
- ✅ **Threads Service** (Node.js): 2 tasks, port 3000, HEALTHY

### Endpoints Working
- ✅ `http://<ALB_DNS>/` - Frontend dashboard
- ✅ `http://<ALB_DNS>/api/users` - 4 users
- ✅ `http://<ALB_DNS>/api/posts` - 6 posts
- ✅ `http://<ALB_DNS>/api/threads` - 3 threads
- ✅ All health checks passing

---

## 🔧 Troubleshooting Guide

### 504 Gateway Timeout
**Symptoms**: ALB returns 504 errors
**Check**:
1. Target health: `aws elbv2 describe-target-health --target-group-arn <ARN>`
2. ECS task logs: `aws logs tail /ecs/<service>-service-dev --follow`
3. Security group rules allow correct ports

**Common Causes**:
- Security group blocking traffic (check port 80 for gateway, 3000 for services)
- Container health check failing (verify curl is installed in gateway)
- Nginx config conflicts (ensure conf.d is cleaned)

### Services Showing "Offline" in Frontend
**Symptoms**: Dashboard shows services as offline
**Check**:
1. Test health endpoints: `curl http://<ALB_DNS>/api/users/health`
2. Check if old tasks are draining: Look for "draining" status in target health
3. Verify dual routing exists in server.js files

**Common Causes**:
- Missing `/api/{service}/health` routes in microservices
- Old tasks still running with old code (wait for draining to complete)
- ALB caching (wait 60 seconds or clear browser cache)

### Terraform State Issues
**Symptoms**: "Resource already exists" errors
**Fix**:
1. Import existing resources: `.github/scripts/import-existing-resources.sh`
2. Or use `terraform import` for individual resources
3. Verify state backend is accessible

---

## 📝 Future Improvements

### Recommended Enhancements
1. **SSL/TLS**: Add ACM certificate and HTTPS listener
2. **Custom Domain**: Route 53 with custom domain name
3. **Auto-scaling**: Configure target tracking policies
4. **Monitoring**: CloudWatch dashboards and alarms
5. **DR Activation**: Enable `enable_dr=true` when needed
6. **Database**: Migrate from JSON files to RDS/DynamoDB
7. **CI/CD**: Add integration tests in workflows
8. **Secrets**: Use AWS Secrets Manager for sensitive data

### Code Quality
1. Add more comprehensive tests
2. Implement API versioning
3. Add request rate limiting
4. Implement proper authentication/authorization
5. Add API documentation (Swagger/OpenAPI)

---

## 👥 Team Information
- **Course**: Implementing DevOps Solutions - Durham College 2025
- **Team**: Group 1
- **Members**:
  - Anju Doot (100959389)
  - Muskaan Fatima (101005853)
  - Hushang Fikrat Muhibullah (101012042)
  - Mohammad Kaif (101001476)
  - Bharath (100956079)

---

## 📅 Last Updated
December 2, 2025

**Deployment Status**: ✅ FULLY OPERATIONAL
**All Issues**: RESOLVED
**Services**: HEALTHY
**Frontend**: ONLINE
