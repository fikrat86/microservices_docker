# 🚀 Quick Start Guide - New Features

## Overview
This guide helps you quickly get started with the three new features added to your microservices project.

---

## 1️⃣ Testing & Quality Assurance

### Install Dependencies
```powershell
# Install test dependencies for each service
cd users
npm install
cd ../posts
npm install
cd ../threads
npm install
cd ..
```

### Run Tests Locally
```powershell
# Run tests for a service
cd users
npm test

# Run with coverage
npm test -- --coverage

# Run in watch mode (for development)
npm run test:watch
```

### Linting
```powershell
# Check code quality
npm run lint

# Auto-fix issues
npm run lint:fix
```

### Security Scanning
```powershell
# Check for vulnerabilities
npm audit

# Fix vulnerabilities
npm audit fix
```

### What Gets Tested?
- ✅ All API endpoints
- ✅ Health checks
- ✅ Error handling
- ✅ CORS configuration
- ✅ Response formats

### Coverage Requirements
- Branches: 70%
- Functions: 80%
- Lines: 80%
- Statements: 80%

---

## 2️⃣ Interactive Dashboard

### Local Development

**Step 1: Start Services**
```powershell
docker-compose up -d
```

**Step 2: Open Dashboard**
- Open `dashboard.html` in your browser
- Default URL is pre-configured: `http://localhost:8080`

**Step 3: Try Demo Scenarios**
- Click "Get User with Posts" to see cascading service calls
- Click "Get Thread with Details" for complex interactions
- Click "Full Service Chain" for complete workflow

### AWS Deployment

**Step 1: Get ALB URL**
```powershell
cd terraform
terraform output alb_dns_name
```

**Step 2: Configure Dashboard**
- Open `dashboard.html` in browser
- Update "Load Balancer URL" field
- Enter: `http://your-alb-dns-name.elb.amazonaws.com`

**Step 3: Test Services**
- Status badges should show "Healthy" (green)
- Click "Test" on any endpoint to see responses
- Run demo scenarios to see service interactions

### Dashboard Features
- 🟢 Real-time health monitoring
- 🔄 Auto-refresh every 30 seconds
- 📊 Request metrics tracking
- 🔍 Live API testing
- 📈 Visual flow diagrams

---

## 3️⃣ Disaster Recovery

### Initial Setup

**Step 1: Enable DR in Terraform**
```powershell
cd terraform
# Edit terraform.tfvars
notepad terraform.tfvars
```

Add these lines:
```hcl
enable_dr = true
dr_region = "us-west-2"
backup_retention_days = 7
enable_cross_region_backup = true
```

**Step 2: Deploy DR Infrastructure**
```powershell
terraform plan
terraform apply
```

This creates:
- DR VPC in us-west-2
- DR ECS cluster and services
- DR Application Load Balancer
- S3 buckets for backups
- Cross-region replication

### DR Operations

**Create a Backup**
```powershell
.\scripts\dr-management.ps1 -Action backup
```

**Test DR Site**
```powershell
.\scripts\dr-management.ps1 -Action test-dr
```

**Sync Container Images**
```powershell
.\scripts\dr-management.ps1 -Action sync
```

**Execute Failover**
```powershell
.\scripts\dr-management.ps1 -Action failover
```

**Restore from Backup**
```powershell
.\scripts\dr-management.ps1 -Action restore -RestoreFrom "backup-20241123-120000"
```

### DR Best Practices
1. Test DR site monthly
2. Create backups before deployments
3. Sync images after each build
4. Document failover procedures
5. Maintain runbooks

---

## 🔄 CI/CD Integration

### Build Pipeline Now Includes

1. **Linting** - ESLint checks code quality
2. **Testing** - Jest runs all unit tests
3. **Security** - npm audit scans dependencies
4. **Image Scan** - Trivy scans Docker images

### View Pipeline Results

**AWS Console:**
1. Go to CodePipeline
2. Select your pipeline
3. View stage details
4. Check test reports

**CloudWatch:**
- Test results appear in CloudWatch reports
- Coverage reports available
- Build logs show all checks

---

## 📋 Verification Checklist

### After Setup, Verify:

**Testing:**
- [ ] All tests pass locally
- [ ] Coverage meets thresholds
- [ ] Linting shows no errors
- [ ] No security vulnerabilities

**Dashboard:**
- [ ] Opens in browser
- [ ] All services show as healthy
- [ ] Demo scenarios work
- [ ] Metrics update correctly

**Disaster Recovery:**
- [ ] DR infrastructure deployed
- [ ] Backups created successfully
- [ ] DR services healthy
- [ ] Images synced to DR region

---

## 🆘 Common Issues

### Tests Fail

**Solution:**
```powershell
# Clear cache
npm test -- --clearCache

# Reinstall dependencies
Remove-Item -Recurse node_modules
npm install

# Check Node version
node --version  # Should be >= 20.0.0
```

### Dashboard Shows Services Offline

**Solutions:**
1. Verify services are running:
   ```powershell
   docker-compose ps
   ```

2. Check ALB URL is correct

3. Verify CORS is enabled in services

4. Check browser console for errors

### DR Test Fails

**Solutions:**
1. Verify DR infrastructure is deployed:
   ```powershell
   terraform output dr_alb_dns_name
   ```

2. Check DR services are running:
   ```powershell
   aws ecs list-services --cluster forum-microservices-cluster-dev-dr --region us-west-2
   ```

3. Sync images if missing:
   ```powershell
   .\scripts\dr-management.ps1 -Action sync
   ```

---

## 📚 Documentation

**Detailed Guides:**
- [Disaster Recovery Guide](docs/DISASTER_RECOVERY.md)
- [Dashboard Guide](docs/DASHBOARD_GUIDE.md)
- [Testing Guide](docs/TESTING_GUIDE.md)

**Quick Reference:**
- [Feature Summary](NEW_FEATURES_SUMMARY.md)
- [Main README](README.md)

---

## 🎯 Next Steps

1. **Run Local Tests:**
   ```powershell
   cd users && npm install && npm test
   ```

2. **Try the Dashboard:**
   ```powershell
   docker-compose up -d
   # Open dashboard.html
   ```

3. **Deploy DR:**
   ```powershell
   cd terraform
   terraform apply
   .\scripts\dr-management.ps1 -Action test-dr
   ```

4. **Push to Git:**
   ```powershell
   git add .
   git commit -m "Added DR, Dashboard, and Testing features"
   git push
   ```

---

## 💡 Pro Tips

1. **Testing in Watch Mode**: Use `npm run test:watch` during development for instant feedback

2. **Dashboard URL**: Bookmark the dashboard URL for quick access

3. **DR Testing**: Schedule monthly DR tests on your calendar

4. **CI/CD**: Watch the first pipeline run to ensure all checks pass

5. **Metrics**: Export dashboard metrics for reporting

---

**Need Help?** Check the detailed documentation in the `docs/` folder or review the `NEW_FEATURES_SUMMARY.md` file.

**Happy Coding! 🚀**
