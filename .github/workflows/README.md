# GitHub Actions Workflows

This project uses **two separate workflows** for better separation of concerns and faster CI/CD pipelines.

## 📋 Workflows

### 1. Infrastructure Deployment (`infrastructure.yml`)

**Purpose**: Manages AWS infrastructure using Terraform

**Triggers**:
- Push to `main` branch (only when `terraform/**` changes)
- Pull requests (only when `terraform/**` changes)  
- Manual trigger via `workflow_dispatch`

**Jobs**:
1. **terraform-validate** - Format check and validation
2. **terraform-plan** - Generate execution plan
3. **terraform-apply** - Deploy infrastructure (main branch only)
4. **terraform-destroy** - Destroy infrastructure (manual only)
5. **security-scan** - Run Checkov and tfsec security scans

---

### 2. Microservices CI/CD (`microservices.yml`)

**Purpose**: Build, test, and deploy microservices

**Triggers**:
- Push to `main` branch (when service code changes)
- Pull requests (when service code changes)
- Manual trigger via `workflow_dispatch`

**Jobs**:
1. **detect-changes** - Identify which services changed
2. **test-{service}** - Run tests only for changed services
3. **build-{service}** - Build and push Docker images
4. **deploy** - Update ECS services with new images

**Smart Features**:
- 🎯 Only tests/builds/deploys changed services
- ⚡ Faster pipelines by skipping unchanged services
- 📊 Code coverage reporting

---

## 🚀 Deployment Order

### First-Time Setup

```bash
# 1. Deploy infrastructure FIRST
# Trigger: infrastructure.yml (terraform files changed)
# Creates: VPC, ECS, DynamoDB, ALB, etc.

# 2. Deploy microservices SECOND  
# Trigger: microservices.yml (service code changed)
# Builds: Docker images, deploys to ECS
```

### Day-to-Day Development

**Infrastructure Changes** (rare):
```bash
vim terraform/variables.tf
git commit -m "infra: update DynamoDB capacity"
git push
# → Only infrastructure.yml runs
```

**Service Changes** (frequent):
```bash
vim users/server.js
git commit -m "feat(users): add new endpoint"
git push
# → Only microservices.yml runs
# → Only users service is built/deployed
```

---

## 📊 Workflow Comparison

| Feature | Infrastructure | Microservices |
|---------|---------------|---------------|
| **Frequency** | Weekly/Monthly | Daily/Hourly |
| **Duration** | 10-15 min | 5-8 min |
| **Triggers** | terraform/** | users/**, posts/**, threads/** |
| **Approval** | Required | Automatic |
| **Testing** | tfsec, Checkov | Jest, ESLint, Trivy |

---

## 🔐 Required Secrets

**Settings → Secrets and variables → Actions**

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ACCOUNT_ID`
- `CODECOV_TOKEN` (optional)

---

## 🐛 Troubleshooting

**"ECR repository not found"**
→ Run infrastructure workflow first

**"ECS cluster not found"**
→ Run infrastructure workflow first

**"Tests failing"**
→ Check 80% coverage requirement

---

**Version**: 2.0 (Separated Workflows)  
**Last Updated**: November 23, 2024
