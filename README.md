# Forum Microservices - DevOps Solutions Project updated

A complete microservices-based forum application deployed on AWS using Infrastructure as Code (Terraform), containerized with Docker, orchestrated with ECS Fargate, and automated with CI/CD pipelines.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Database](#database)
- [Solution Requirements](#solution-requirements)
- [Technology Stack](#technology-stack)
- [New Features](#new-features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [AWS Deployment](#aws-deployment)
- [Disaster Recovery](#disaster-recovery)
- [Interactive Dashboard](#interactive-dashboard)
- [Testing and Quality](#testing-and-quality)
- [CI/CD Pipeline](#cicd-pipeline)
- [Cost Optimization](#cost-optimization)
- [Monitoring and Logging](#monitoring-and-logging)
- [Troubleshooting](#troubleshooting)
- [Team Members](#team-members)

## 🎯 Project Overview

This project demonstrates a complete DevOps solution for deploying a microservices-based forum application. The application consists of three independent microservices:

- **Posts Service**: Manages forum posts and comments
- **Threads Service**: Manages discussion threads
- **Users Service**: Manages user profiles

### Business Problem

A popular web forum experienced performance degradation due to increased daily active users. The monolithic application running on a single EC2 instance couldn't scale efficiently. This solution migrates to a microservices architecture where each service can scale independently based on demand.

### Solution Highlights

✅ **Microservices Architecture**: Independent services with dedicated resources  
✅ **Container-based**: Docker containers for portability and consistency  
✅ **Serverless Compute**: AWS Fargate eliminates server management  
✅ **Serverless Database**: DynamoDB with Global Tables for multi-region replication  
✅ **Auto-scaling**: CPU and memory-based scaling for cost optimization  
✅ **Load Balanced**: Application Load Balancer with path-based routing  
✅ **Infrastructure as Code**: Complete Terraform configuration with S3 backend  
✅ **Automated CI/CD**: GitHub Actions with separated infrastructure and microservices workflows  
✅ **High Availability**: Multi-AZ deployment with health checks  
✅ **Disaster Recovery**: Multi-region DR (us-east-1 ↔ us-west-2) with < 1s RPO  
✅ **Comprehensive Testing**: Unit tests (Jest), linting (ESLint), security scanning (npm audit, Trivy)  
✅ **State Management**: S3 backend with DynamoDB locking for Terraform state  

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet                                │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
                ┌───────────────────────┐
                │ Application Load      │
                │ Balancer (ALB)        │
                │ - Path-based routing  │
                └───────────┬───────────┘
                            │
           ┌────────────────┼────────────────┐
           │                │                │
           ▼                ▼                ▼
    ┌──────────┐     ┌──────────┐    ┌──────────┐
    │ Posts    │     │ Threads  │    │ Users    │
    │ Service  │     │ Service  │    │ Service  │
    │ (ECS)    │     │ (ECS)    │    │ (ECS)    │
    │ 2-10 tasks│    │ 2-10 tasks│   │ 2-10 tasks│
    └──────────┘     └──────────┘    └──────────┘
           │                │                │
           └────────────────┼────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   CloudWatch  │
                    │   Logs        │
                    └───────────────┘
```

### Network Architecture

```
VPC (10.0.0.0/16)
├── Public Subnets (2 AZs)
│   ├── 10.0.0.0/24 (us-east-1a)
│   ├── 10.0.1.0/24 (us-east-1b)
│   ├── Internet Gateway
│   ├── Application Load Balancer
│   └── NAT Gateways
│
└── Private Subnets (2 AZs)
    ├── 10.0.100.0/24 (us-east-1a)
    ├── 10.0.101.0/24 (us-east-1b)
    ├── ECS Fargate Tasks
    └── VPC Endpoints (ECR, CloudWatch, S3)
```

## 💾 Database

### Amazon DynamoDB - Serverless NoSQL Database

This project uses **Amazon DynamoDB** as its primary database solution:

**Why DynamoDB?**
- ✅ **Cost-Optimized**: Pay-per-request pricing (~$0.19/month for small apps)
- ✅ **Serverless**: No server management or capacity planning
- ✅ **Auto-Scaling**: Built-in capacity management
- ✅ **Global Tables**: Multi-region replication for DR (< 1 sec)
- ✅ **High Performance**: Single-digit millisecond latency
- ✅ **Built-in Backup**: Point-in-time recovery + AWS Backup

**Database Tables**:
- `Users` - User profiles (Primary Key: userId, GSI: email)
- `Threads` - Discussion threads (Primary Key: threadId, GSI: createdAt)
- `Posts` - Forum posts (Primary Key: postId, Sort Key: threadId, GSI: userId, threadId)

**Disaster Recovery**:
- Primary Region: us-east-1
- DR Region: us-west-2 (automated replication)
- RPO: < 1 second
- RTO: < 1 minute

**Cost Comparison**:
- DynamoDB: ~$0.19/month (small app)
- RDS t3.micro: ~$15/month
- Aurora Serverless v2: ~$45/month
- **Savings: 95% cheaper than RDS!** 💰

📚 **Full Documentation**: See `docs/DYNAMODB_GUIDE.md` for complete setup, migration, and usage instructions.

### CI/CD Pipeline Flow

```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Developer    │───▶│ CodeCommit   │───▶│ CodeBuild    │───▶│ ECR          │
│ Pushes Code  │    │ (Git Repo)   │    │ (Build Image)│    │ (Store Image)│
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
                                                                      │
                                                                      ▼
                                        ┌─────────────────────────────────┐
                                        │ ECS Fargate                     │
                                        │ (Blue/Green Deployment)         │
                                        │ - Deploy new version            │
                                        │ - Health check                  │
                                        │ - Auto rollback on failure      │
                                        └─────────────────────────────────┘
```

## ✅ Solution Requirements

This solution fulfills all project requirements:

| Requirement | Implementation | Status |
|------------|----------------|--------|
| **R1: Design** | Architecture diagram in `docs/ARCHITECTURE.md` | ✅ Complete |
| **R2: Cost Optimized** | Cost estimate in `docs/COST_ESTIMATE.md` | ✅ Complete |
| **R3: Microservices** | Three independent services (Posts, Threads, Users) | ✅ Complete |
| **R4: Portability** | Docker containers, works anywhere | ✅ Complete |
| **R5: Scalability/Resilience** | Auto-scaling (2-10 tasks), Multi-AZ ALB | ✅ Complete |
| **R6: Automated CI/CD** | CodePipeline + CodeBuild + CodeCommit | ✅ Complete |
| **R7: Infrastructure as Code** | Complete Terraform configuration | ✅ Complete |

## 🛠️ Technology Stack

### Application Layer
- **Runtime**: Node.js 20 LTS
- **Framework**: Koa.js v2 (modern async/await)
- **Language**: JavaScript

### Infrastructure
- **Cloud Provider**: AWS
- **Compute**: ECS Fargate (serverless containers)
- **Database**: Amazon DynamoDB (serverless NoSQL with Global Tables)
- **Load Balancing**: Application Load Balancer (ALB)
- **Container Registry**: Amazon ECR
- **Networking**: VPC, Subnets, NAT Gateway, Internet Gateway
- **Infrastructure as Code**: Terraform 1.5+ with S3 backend and DynamoDB locking
- **Backup & DR**: S3 cross-region replication, DynamoDB Global Tables

### CI/CD
- **Source Control**: GitHub
- **CI/CD Pipeline**: GitHub Actions (separated workflows)
  - Infrastructure workflow: Terraform validation, planning, and deployment
  - Microservices workflow: Service testing, building, and deployment
- **Container Build**: Docker multi-stage builds
- **Security Scanning**: npm audit, Trivy image scanning
- **Deployment**: ECS rolling updates with automatic rollback

### Monitoring & Logging
- **Logs**: CloudWatch Logs
- **Metrics**: CloudWatch Container Insights
- **Alarms**: CloudWatch Alarms (for auto-scaling)

### Development Tools
- **Containerization**: Docker
- **Local Orchestration**: Docker Compose
- **Reverse Proxy**: Nginx (local development)
- **Testing**: Jest 29.7.0, Supertest 6.3.3
- **Linting**: ESLint 8.56.0
- **Security Scanning**: npm audit, Trivy

## 🆕 New Features

### 1. DynamoDB Database
**Serverless, cost-optimized NoSQL database with multi-region replication**:
- **Global Tables**: Automated replication between us-east-1 and us-west-2
- **Pay-Per-Request**: Only pay for what you use (~$0.19/month for small apps)
- **Point-in-Time Recovery**: Restore to any point in last 35 days
- **Automated Backups**: Daily backups with cross-region copy
- **Zero Downtime**: Active-active setup, read/write from both regions
- **< 1 Second RPO**: Near real-time replication

**Quick Start**:
```powershell
# Step 1: Setup Terraform S3 backend
cd scripts
.\setup-terraform-backend.ps1

# Step 2: Initialize Terraform with backend
cd ..\terraform
terraform init -reconfigure

# Step 3: Deploy DynamoDB tables
terraform apply -target=aws_dynamodb_table.users -target=aws_dynamodb_table.threads -target=aws_dynamodb_table.posts

# Step 4: Migrate data from JSON files
cd ..\scripts
.\dynamodb-management.ps1 -Action migrate

# Step 5: Verify tables and data
.\dynamodb-management.ps1 -Action verify

# Step 6: Verify DR replication
.\dynamodb-management.ps1 -Action verify -Region us-west-2
```

📚 **Documentation**: 
- `docs/DYNAMODB_IMPLEMENTATION_GUIDE.md` - Complete implementation guide
- `docs/DYNAMODB_SUMMARY.md` - Quick reference and architecture
- `docs/DYNAMODB_QUICKREF.md` - Common operations cheat sheet

### 2. Disaster Recovery (DR)
Complete multi-region disaster recovery solution with DynamoDB Global Tables:

**Database DR**:
- **DynamoDB Global Tables**: Automatic bidirectional replication
- **Primary Region**: us-east-1 (read/write)
- **DR Region**: us-west-2 (read/write)
- **Replication Lag**: < 1 second
- **RPO**: < 1 second (database)
- **RTO**: < 1 minute (database), < 15 minutes (full stack)

**Infrastructure DR**:
- **Secondary Region**: Complete infrastructure replication in us-west-2
- **Automated Backup**: S3 cross-region replication for files
- **Container Sync**: ECR image replication to DR region
- **Failover Scripts**: Automated failover and testing scripts

**Quick Start**:
```powershell
# Verify database DR replication
.\scripts\dynamodb-management.ps1 -Action verify -Region us-west-2

# Test database DR failover
.\scripts\dynamodb-management.ps1 -Action test-dr

# Create infrastructure backup
.\scripts\dr-management.ps1 -Action backup

# Test DR site availability
.\scripts\dr-management.ps1 -Action test-dr

# Execute failover to DR region
.\scripts\dr-management.ps1 -Action failover
```

📚 **Documentation**: 
- `docs/DISASTER_RECOVERY.md` - Complete DR guide
- `docs/DYNAMODB_IMPLEMENTATION_GUIDE.md` - Database DR details

### 3. Interactive Dashboard
Real-time microservice communication visualization:
- **Live Health Monitoring**: Real-time service status tracking
- **API Testing**: One-click endpoint testing
- **Communication Demos**: 4 pre-built scenarios showing service interaction
- **Metrics Dashboard**: Request tracking and performance metrics

**Access**:
- Local: Open `dashboard.html` in browser (points to localhost:8080)
- AWS: Update ALB URL in dashboard configuration

See [docs/DASHBOARD_GUIDE.md](docs/DASHBOARD_GUIDE.md) for complete guide.

### 4. Testing & Quality Assurance
Comprehensive testing and code quality integrated into CI/CD:
- **Unit Tests**: Jest tests for all services (80%+ coverage requirement)
- **Linting**: ESLint with StandardJS style guide
- **Security Scanning**: 
  - npm audit for dependency vulnerabilities
  - Trivy for container image scanning
  - Automated in GitHub Actions workflows
- **CI Integration**: All checks run automatically on push and PR

**Quick Start**:
```powershell
# Run all quality checks for a service
cd users
npm test              # Run Jest tests with coverage
npm run lint          # Run ESLint
npm run lint:fix      # Auto-fix linting issues
npm audit             # Check for vulnerabilities

# Run tests in watch mode during development
npm test -- --watch

# Generate detailed coverage report
npm test -- --coverage
```

**GitHub Actions Integration**:
- Every push and PR triggers automated testing
- Microservices workflow runs: lint → test → audit → build → scan
- Infrastructure workflow runs: validate → plan → security-scan
- Failed checks block deployment automatically

📚 **Documentation**: `docs/TESTING_GUIDE.md`

### 5. CI/CD with GitHub Actions
Separated workflows for infrastructure and microservices:

**Infrastructure Workflow** (`.github/workflows/infrastructure.yml`):
```yaml
Triggers: Manual (workflow_dispatch), PR, push to main
Jobs:
  1. terraform-validate: Check Terraform syntax
  2. terraform-plan: Generate execution plan
  3. terraform-apply: Deploy infrastructure (manual approval)
  4. terraform-destroy: Destroy infrastructure (manual only)
  5. security-scan: Terraform security scanning
```

**Microservices Workflow** (`.github/workflows/microservices.yml`):
```yaml
Triggers: Push to main, PR
Jobs:
  1. detect-changes: Identify which services changed
  2. test-and-build-[service]: For each changed service:
     - ESLint code quality check
     - Jest unit tests with coverage
     - npm audit security scan
     - Docker build and push to ECR
     - Trivy container image scan
  3. deploy-[service]: Deploy to ECS Fargate
```

**Quick Start**:
```powershell
# Trigger infrastructure deployment
# Go to: GitHub → Actions → Infrastructure Deployment → Run workflow
# Select: action = "apply"

# Trigger microservices deployment
# Option 1: Push code changes
git add .
git commit -m "Update microservices"
git push origin main

# Option 2: Manual trigger
# Go to: GitHub → Actions → Microservices CI/CD → Run workflow
```

**Workflow Features**:
- ✅ Change detection (only build/deploy modified services)
- ✅ Parallel job execution for faster builds
- ✅ Automatic rollback on deployment failure
- ✅ Comprehensive security scanning
- ✅ Manual approval for infrastructure changes
- ✅ Secrets management via GitHub Secrets

📚 **Documentation**: 
- `.github/workflows/infrastructure.yml` - Infrastructure workflow
- `.github/workflows/microservices.yml` - Microservices workflow
- `GITHUB_ACTIONS_SETUP.md` - Setup guide

## 📁 Project Structure

```
microservices_docker/
├── posts/                          # Posts microservice
│   ├── server.js                   # Service implementation
│   ├── server.test.js              # Jest unit tests
│   ├── db.json                     # Sample data
│   ├── package.json                # Dependencies
│   ├── Dockerfile                  # Multi-stage Docker build
│   ├── buildspec.yml               # CodeBuild with tests & security
│   ├── jest.config.js              # Jest configuration
│   ├── .eslintrc.js                # ESLint configuration
│   ├── .dockerignore              # Docker ignore file
│   └── .env.example               # Environment variables template
│
├── threads/                        # Threads microservice
│   ├── server.js
│   ├── server.test.js              # Jest unit tests
│   ├── db.json
│   ├── package.json
│   ├── Dockerfile
│   ├── buildspec.yml               # CodeBuild with tests & security
│   ├── jest.config.js              # Jest configuration
│   ├── .eslintrc.js                # ESLint configuration
│   ├── .dockerignore
│   └── .env.example
│
├── users/                          # Users microservice
│   ├── server.js
│   ├── server.test.js              # Jest unit tests
│   ├── db.json
│   ├── package.json
│   ├── Dockerfile
│   ├── buildspec.yml               # CodeBuild with tests & security
│   ├── jest.config.js              # Jest configuration
│   ├── .eslintrc.js                # ESLint configuration
│   ├── .dockerignore
│   └── .env.example
│
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Provider configuration
│   ├── backend.tf                 # S3 backend configuration (NEW)
│   ├── variables.tf               # Input variables (with DR vars)
│   ├── outputs.tf                 # Output values (with DR outputs)
│   ├── vpc.tf                     # VPC and networking
│   ├── security_groups.tf         # Security groups
│   ├── alb.tf                     # Application Load Balancer
│   ├── ecr.tf                     # Container registry
│   ├── ecs_cluster.tf             # ECS cluster
│   ├── ecs_services.tf            # ECS services and tasks
│   ├── iam.tf                     # IAM roles and policies
│   ├── autoscaling.tf             # Auto-scaling configuration
│   ├── dynamodb.tf                # DynamoDB tables (NEW)
│   ├── dr_region.tf               # DR region infrastructure (NEW)
│   ├── dr_ecs_services.tf         # DR ECS services (NEW)
│   ├── s3_backup.tf               # S3 backup and replication (NEW)
│   ├── terraform.tfstate          # Local state (before S3 migration)
│   ├── terraform.tfvars           # Variables configuration
│   └── terraform.tfvars.example   # Variables template
│
├── scripts/                        # Deployment and management scripts
│   ├── deploy.ps1                 # Main deployment script
│   ├── build-and-push.ps1         # Build and push Docker images
│   ├── test-services.ps1          # Test deployed services
│   ├── setup-terraform-backend.ps1 # Setup S3 backend (NEW)
│   ├── cleanup-aws-resources.ps1  # Resource cleanup (NEW)
│   ├── cleanup-all-resources.ps1  # Comprehensive cleanup (NEW)
│   ├── dynamodb-management.ps1    # DynamoDB operations (NEW)
│   └── dr-management.ps1          # DR operations (NEW)
│
├── nginx/                          # Local development proxy
│   └── nginx.conf                 # Nginx configuration
│
├── docs/                           # Documentation
│   ├── ARCHITECTURE.md            # Architecture diagram
│   ├── COST_ESTIMATE.md           # Cost analysis
│   ├── QUICKSTART.md              # Quick start guide
│   ├── DISASTER_RECOVERY.md       # DR guide
│   ├── TESTING_GUIDE.md           # Testing & QA guide
│   ├── DYNAMODB_IMPLEMENTATION_GUIDE.md  # DynamoDB setup (NEW)
│   ├── DYNAMODB_SUMMARY.md        # DynamoDB quick reference (NEW)
│   └── DYNAMODB_QUICKREF.md       # DynamoDB operations (NEW)
│
├── .github/                        # GitHub Actions workflows (NEW)
│   └── workflows/
│       ├── infrastructure.yml     # Terraform deployment workflow
│       └── microservices.yml      # Microservices CI/CD workflow
│
├── docker-compose.yml              # Local development environment
├── .gitignore                      # Git ignore rules
├── COMPLETION_REPORT.md            # Project completion summary
├── DEPLOYMENT_CHECKLIST.md         # Deployment checklist
├── DOCUMENTATION_INDEX.md          # Documentation index
├── GITHUB_ACTIONS_SETUP.md         # GitHub Actions setup guide
├── PROJECT_SUMMARY.md              # Project summary
└── README.md                       # This file
```

## 📦 Prerequisites

### Required Software

1. **AWS CLI** (v2.x or later)
   ```powershell
   # Install AWS CLI
   # Download from: https://aws.amazon.com/cli/
   
   # Verify installation
   aws --version
   ```

2. **Terraform** (v1.5.0 or later)
   ```powershell
   # Install Terraform
   # Download from: https://www.terraform.io/downloads
   
   # Verify installation
   terraform version
   ```

3. **Docker** (for local development)
   ```powershell
   # Install Docker Desktop
   # Download from: https://www.docker.com/products/docker-desktop
   
   # Verify installation
   docker --version
   docker-compose --version
   ```

4. **Git** (for version control)
   ```powershell
   git --version
   ```

### AWS Account Setup

1. **AWS Account**: Active AWS account with administrative access
2. **AWS CLI Configuration**:
   ```powershell
   aws configure
   # Enter your:
   # - AWS Access Key ID
   # - AWS Secret Access Key
   # - Default region (e.g., us-east-1)
   # - Default output format (json)
   ```

3. **Verify AWS Access**:
   ```powershell
   aws sts get-caller-identity
   ```

### Permissions Required

Your AWS user/role needs permissions for:
- VPC, Subnets, Internet Gateway, NAT Gateway
- EC2 (for networking)
- ECS (Fargate, Task Definitions, Services)
- ECR (Repository management)
- Application Load Balancer, Target Groups
- IAM (Roles and Policies)
- CloudWatch (Logs, Metrics, Alarms)
- CodePipeline, CodeBuild, CodeCommit
- S3 (for pipeline artifacts)

## 🚀 Local Development

### 1. Clone the Repository

```powershell
git clone <your-repository-url>
cd microservices_docker
```

### 2. Install Dependencies (Optional - for development)

```powershell
# Install dependencies for each service
cd posts
npm install
cd ../threads
npm install
cd ../users
npm install
cd ..
```

### 3. Run with Docker Compose

```powershell
# Build and start all services
docker-compose up --build

# Or run in detached mode
docker-compose up -d --build

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 4. Test Local Services

The services will be available at:

- **Nginx Gateway**: http://localhost:8080
- **Posts Service**: http://localhost:3001 (or via http://localhost:8080/posts)
- **Threads Service**: http://localhost:3002 (or via http://localhost:8080/threads)
- **Users Service**: http://localhost:3003 (or via http://localhost:8080/users)

### Test Endpoints

```powershell
# Test via Nginx proxy (simulates ALB routing)
Invoke-WebRequest -Uri "http://localhost:8080/posts/api/" -Method Get
Invoke-WebRequest -Uri "http://localhost:8080/threads/api/threads" -Method Get
Invoke-WebRequest -Uri "http://localhost:8080/users/api/users" -Method Get

# Test direct service access
Invoke-WebRequest -Uri "http://localhost:3001/api/posts" -Method Get
Invoke-WebRequest -Uri "http://localhost:3002/api/threads" -Method Get
Invoke-WebRequest -Uri "http://localhost:3003/api/users" -Method Get
```

## ☁️ AWS Deployment

### Overview

The deployment process is now streamlined with GitHub Actions workflows and Terraform S3 backend for state management.

### Prerequisites Checklist

Before deployment, ensure you have:
- ✅ AWS CLI configured with credentials (`aws configure`)
- ✅ Terraform installed (v1.5.0+)
- ✅ GitHub repository set up with Actions enabled
- ✅ AWS credentials added to GitHub Secrets (see `GITHUB_ACTIONS_SETUP.md`)

### Step 1: Setup Terraform S3 Backend

The S3 backend provides centralized state management and prevents orphaned resources:

```powershell
# Navigate to scripts directory
cd scripts

# Run backend setup script
.\setup-terraform-backend.ps1

# Expected output:
# ✓ Created S3 bucket: forum-microservices-terraform-state-dev
# ✓ Enabled versioning
# ✓ Enabled encryption
# ✓ Created DynamoDB table: forum-microservices-terraform-locks
```

This creates:
- S3 bucket for Terraform state storage
- DynamoDB table for state locking
- Bucket versioning and encryption

### Step 2: Initialize Terraform with Backend

```powershell
# Navigate to terraform directory
cd ..\terraform

# Initialize Terraform with S3 backend
terraform init -reconfigure

# Expected output:
# Initializing the backend...
# Successfully configured the backend "s3"!
# Terraform has been successfully initialized!
```

### Step 3: Deploy Infrastructure via GitHub Actions

**Option A: Via GitHub Web Interface** (Recommended)
```
1. Go to: https://github.com/YOUR_USERNAME/microservices_docker/actions
2. Click: "Infrastructure Deployment" workflow
3. Click: "Run workflow" button
4. Select branch: main
5. Select action: "apply"
6. Click: "Run workflow"
```

**Option B: Via Local Terraform**
```powershell
# Review planned changes
terraform plan -var="environment=dev"

# Apply infrastructure
terraform apply -var="environment=dev"

# Or auto-approve
terraform apply -var="environment=dev" -auto-approve
```

**What gets deployed:**
- VPC with public/private subnets in 2 AZs
- Application Load Balancer
- ECS Fargate cluster
- ECR repositories for each service
- DynamoDB tables with Global Tables (us-east-1 ↔ us-west-2)
- IAM roles and policies
- CloudWatch log groups
- Auto-scaling policies
- DR infrastructure in us-west-2

**Deployment time:** ~15-20 minutes

```powershell
# Copy the example variables file
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings
notepad terraform.tfvars
```

Example `terraform.tfvars`:
```hcl
aws_region = "us-east-1"
environment = "dev"
project_name = "forum-microservices"
container_cpu = 256
container_memory = 512
desired_count = 2
min_capacity = 2
max_capacity = 10
```

### Step 4: Configure Terraform Variables

```powershell
# Copy the example variables file (if not already done)
Copy-Item terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your settings
notepad terraform.tfvars
```

Example `terraform.tfvars`:
```hcl
# Project Configuration
aws_region = "us-east-1"
environment = "dev"
project_name = "forum-microservices"

# ECS Configuration
container_cpu = 256
container_memory = 512
desired_count = 2
min_capacity = 2
max_capacity = 10

# Disaster Recovery
enable_dr = true
dr_region = "us-west-2"
dr_vpc_cidr = "10.1.0.0/16"
backup_retention_days = 7
enable_cross_region_backup = true
```

### Step 5: Migrate Data to DynamoDB

After infrastructure is deployed, migrate your data from JSON files:

```powershell
# Navigate to scripts
cd scripts

# Migrate data to DynamoDB
.\dynamodb-management.ps1 -Action migrate

# Verify data migration
.\dynamodb-management.ps1 -Action verify

# Verify DR replication
.\dynamodb-management.ps1 -Action verify -Region us-west-2

# View table statistics
.\dynamodb-management.ps1 -Action stats
```

### Step 6: Deploy Microservices

**Option A: Via GitHub Actions** (Recommended)
```
1. Push code changes to trigger automatic deployment:
   git add .
   git commit -m "Deploy microservices"
   git push origin main

2. Or manually trigger:
   GitHub → Actions → "Microservices CI/CD" → Run workflow
```

**Option B: Manual Docker Build and Push**
```powershell
# Build and push all services
.\scripts\build-and-push.ps1 -Service all -Region us-east-1

# Or build individual services
.\scripts\build-and-push.ps1 -Service posts -Region us-east-1
.\scripts\build-and-push.ps1 -Service threads -Region us-east-1
.\scripts\build-and-push.ps1 -Service users -Region us-east-1

# Update ECS services to use new images (done automatically by GitHub Actions)
```

### Step 7: Get Service URLs and Test

```powershell
# Get the ALB DNS name
cd terraform
terraform output alb_dns_name

# Example output: forum-microservices-alb-dev-1234567890.us-east-1.elb.amazonaws.com
```

Test the services:
```powershell
# Set the ALB URL
$albUrl = "http://$(terraform output -raw alb_dns_name)"

# Run automated tests
cd ..\scripts
.\test-services.ps1 -AlbUrl $albUrl

# Manual testing
Invoke-WebRequest -Uri "$albUrl/api/threads" -Method Get
Invoke-WebRequest -Uri "$albUrl/api/users" -Method Get
Invoke-WebRequest -Uri "$albUrl/api/posts/in-thread/1" -Method Get
```

### Step 8: Verify Disaster Recovery

```powershell
# Test DR database replication
.\dynamodb-management.ps1 -Action verify -Region us-west-2

# Test DR infrastructure (if deployed)
.\dr-management.ps1 -Action test-dr
```

### Deployment Summary

After successful deployment, you will have:
- ✅ Multi-region infrastructure (us-east-1 + us-west-2)
- ✅ DynamoDB Global Tables with active-active replication
- ✅ ECS Fargate services running in both regions
- ✅ Application Load Balancer routing traffic
- ✅ Auto-scaling based on CPU/memory
- ✅ CloudWatch logging and monitoring
- ✅ Terraform state stored in S3 with locking
- ✅ GitHub Actions CI/CD pipelines active

```powershell
# From the project root
.\scripts\build-and-push.ps1 -Service all -Region us-east-1

# Or build individual services
.\scripts\build-and-push.ps1 -Service posts -Region us-east-1
```

**Note**: This script will create ECR repositories if they don't exist.

### Step 3: Deploy Infrastructure with Terraform

```powershell
# Run deployment script (plan mode)
.\scripts\deploy.ps1 -Action plan -Environment dev

# Review the plan, then apply
.\scripts\deploy.ps1 -Action apply -Environment dev

# Or auto-approve
.\scripts\deploy.ps1 -Action apply -Environment dev -AutoApprove
```

**Manual Terraform Commands** (alternative):
```powershell
cd terraform

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="environment=dev"

# Apply the infrastructure
terraform apply -var="environment=dev"

# Get outputs
terraform output
```

### Step 4: Get Service URLs

```powershell
# View all outputs
.\scripts\deploy.ps1 -Action output

# Or manually
cd terraform
terraform output alb_dns_name
```

The ALB DNS name will be something like:
```
forum-microservices-alb-dev-1234567890.us-east-1.elb.amazonaws.com
```

### Step 5: Test Deployed Services

```powershell
# Get the ALB URL
$albUrl = "http://$(terraform output -raw alb_dns_name)"

# Run automated tests
.\scripts\test-services.ps1 -AlbUrl $albUrl

# Manual testing
Invoke-WebRequest -Uri "$albUrl/api/threads" -Method Get
Invoke-WebRequest -Uri "$albUrl/api/users" -Method Get
Invoke-WebRequest -Uri "$albUrl/api/posts/in-thread/1" -Method Get
```

## 🔄 Disaster Recovery

### Overview

The project includes a complete multi-region disaster recovery solution with infrastructure in both **us-east-1** (primary) and **us-west-2** (DR).

### Key Features

- **Infrastructure Redundancy**: Complete VPC, ECS, ALB in DR region
- **Data Backup**: S3 cross-region replication for database backups
- **Container Sync**: ECR image replication to DR region
- **Automated Failover**: Scripts for testing and failover

### Quick Commands

```powershell
# Create a backup
.\scripts\dr-management.ps1 -Action backup

# Test DR site availability
.\scripts\dr-management.ps1 -Action test-dr

# Sync container images to DR
.\scripts\dr-management.ps1 -Action sync

# Execute failover to DR region
.\scripts\dr-management.ps1 -Action failover

# Restore from backup
.\scripts\dr-management.ps1 -Action restore -RestoreFrom "backup-20241123-120000"
```

### DR Configuration

Enable/disable DR in `terraform/terraform.tfvars`:

```hcl
# Disaster Recovery Settings
enable_dr = true
dr_region = "us-west-2"
dr_vpc_cidr = "10.1.0.0/16"
backup_retention_days = 7
enable_cross_region_backup = true
```

### Recovery Objectives

- **RTO (Recovery Time Objective)**: < 15 minutes
- **RPO (Recovery Point Objective)**: < 1 hour

📚 **Complete Guide**: See [docs/DISASTER_RECOVERY.md](docs/DISASTER_RECOVERY.md)

## 📊 Interactive Dashboard

### Overview

A real-time web dashboard for visualizing microservice communication and health.

### Features

- ✅ Live service health monitoring (auto-refresh every 30s)
- ✅ One-click API endpoint testing
- ✅ 4 pre-built communication demos
- ✅ Real-time metrics tracking (requests, response times)
- ✅ Visual flow diagrams showing service interactions

### Access the Dashboard

**Local Development:**
```powershell
# Start services
docker-compose up -d

# Open dashboard.html in browser
# Default URL: http://localhost:8080
```

**AWS Deployment:**
```powershell
# Get ALB DNS
cd terraform
terraform output alb_dns_name

# Open dashboard.html
# Update "Load Balancer URL" field with ALB DNS
# Example: http://your-alb-123456.us-east-1.elb.amazonaws.com
```

### Demo Scenarios

1. **Get User with Posts**: Demonstrates cascading service calls
2. **Get Thread with Details**: Shows complex multi-service interaction
3. **Get Posts with Authors**: Demonstrates data enrichment
4. **Full Service Chain**: Complete workflow across all services

📚 **Complete Guide**: See [docs/DASHBOARD_GUIDE.md](docs/DASHBOARD_GUIDE.md)

## ✅ Testing and Quality

### Testing Framework

All services include comprehensive testing:

- **Unit Tests**: Jest with 80%+ coverage requirement
- **Linting**: ESLint with StandardJS style guide
- **Security**: npm audit + Trivy container scanning

### Running Tests Locally

```powershell
# Navigate to any service directory
cd users

# Run tests
npm test

# Run tests with coverage
npm test -- --coverage

# Run linting
npm run lint

# Fix linting issues
npm run lint:fix

# Security audit
npm audit
```

### CI/CD Integration

The build pipeline (`buildspec.yml`) automatically runs:

1. **ESLint**: Code quality and style checks
2. **Jest Tests**: Unit tests with coverage reporting
3. **npm audit**: Dependency vulnerability scanning
4. **Trivy**: Container image security scanning

```yaml
# Example buildspec.yml pipeline
build:
  commands:
    - npm run lint          # Linting
    - npm test              # Testing
    - npm audit             # Security
    - docker build ...      # Build image
    - trivy scan ...        # Image scanning
```

### Coverage Thresholds

Minimum requirements enforced in `jest.config.js`:

- **Branches**: 70%
- **Functions**: 80%
- **Lines**: 80%
- **Statements**: 80%

📚 **Complete Guide**: See [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md)

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

The project uses two separated workflows for better control and efficiency:

#### 1. Infrastructure Deployment Workflow
**File**: `.github/workflows/infrastructure.yml`

**Triggers**:
- Manual dispatch (workflow_dispatch) with action parameter
- Pull requests to main
- Pushes to main branch

**Jobs**:
```yaml
terraform-validate:
  - Terraform format check
  - Terraform validation
  - Security scanning with Checkov

terraform-plan:
  - Generate execution plan
  - Display planned changes
  - Run on: plan, apply, PR, push to main

terraform-apply:
  - Apply infrastructure changes
  - Only runs on manual trigger with action="apply"
  - Creates/updates all AWS resources

terraform-destroy:
  - Destroy all infrastructure
  - Only runs on manual trigger with action="destroy"
  - Requires manual confirmation

security-scan:
  - Terraform security scanning
  - Runs in parallel with other jobs
```

**Usage**:
```powershell
# Via GitHub UI:
# 1. Go to Actions → Infrastructure Deployment
# 2. Click "Run workflow"
# 3. Select action: validate|plan|apply|destroy
# 4. Click "Run workflow"

# The workflow will:
# - Validate Terraform configuration
# - Run security scans
# - Generate and show execution plan
# - Apply changes (if action=apply)
```

#### 2. Microservices CI/CD Workflow
**File**: `.github/workflows/microservices.yml`

**Triggers**:
- Push to main branch
- Pull requests to main

**Jobs**:
```yaml
detect-changes:
  - Identifies which services changed
  - Uses git diff to detect modifications
  - Outputs: changed_services list

test-and-build-[posts|threads|users]:
  - Runs for each changed service
  - ESLint code quality check
  - Jest unit tests with coverage
  - npm audit security scan
  - Docker multi-stage build
  - Push image to ECR
  - Trivy container security scan

deploy-[posts|threads|users]:
  - Deploy to ECS Fargate
  - Update task definition
  - Force new deployment
  - Wait for service stability
```

**Change Detection**:
The workflow only builds and deploys services that have changed:
```yaml
# Example: If you only modify posts/server.js
# Result: Only posts service is built and deployed
# Benefit: Faster builds, lower costs
```

**Security Checks**:
Every build includes:
- ✅ ESLint linting
- ✅ Jest unit tests
- ✅ npm audit (dependency vulnerabilities)
- ✅ Trivy scan (container image vulnerabilities)
- ✅ Automated rollback on failure

### Setting Up CI/CD

#### Prerequisites

1. **GitHub Repository Secrets** (Settings → Secrets and variables → Actions):
   ```
   AWS_ACCESS_KEY_ID: Your AWS access key
   AWS_SECRET_ACCESS_KEY: Your AWS secret key
   AWS_REGION: us-east-1
   AWS_ACCOUNT_ID: Your 12-digit account ID
   ```

2. **Enable GitHub Actions**:
   - Workflows are automatically enabled when you push `.github/workflows/` directory

#### First Deployment

```powershell
# 1. Ensure all code is committed
git add .
git commit -m "Initial deployment"
git push origin main

# 2. Deploy infrastructure first
# Go to: GitHub → Actions → Infrastructure Deployment → Run workflow
# Select: action = "apply"

# 3. Push microservices (triggers automatic deployment)
# Already done in step 1, or make a small change:
git commit --allow-empty -m "Trigger microservices deployment"
git push origin main

# 4. Monitor progress
# Go to: GitHub → Actions → View running workflows
```

#### Subsequent Deployments

```powershell
# Make changes to services
code posts/server.js

# Commit and push
git add posts/server.js
git commit -m "Update posts service endpoint"
git push origin main

# GitHub Actions will:
# 1. Detect only posts/ directory changed
# 2. Run tests for posts service
# 3. Build and scan posts Docker image
# 4. Deploy only posts service to ECS
# 5. Skip threads and users (no changes)
```

### Pipeline Workflow

```
Developer Push
      ↓
[GitHub Actions Triggered]
      ↓
┌─────────────────────────────────────┐
│  INFRASTRUCTURE WORKFLOW            │
│  (if .tf files changed or manual)   │
│                                     │
│  1. Validate Terraform              │
│  2. Security Scan (Checkov)         │
│  3. Plan Infrastructure             │
│  4. Apply (manual approval)         │
└─────────────────────────────────────┘
      ↓
┌─────────────────────────────────────┐
│  MICROSERVICES WORKFLOW             │
│  (if service files changed)         │
│                                     │
│  For each changed service:          │
│  1. Lint (ESLint)                   │
│  2. Test (Jest)                     │
│  3. Audit (npm audit)               │
│  4. Build (Docker)                  │
│  5. Scan (Trivy)                    │
│  6. Push (ECR)                      │
│  7. Deploy (ECS)                    │
└─────────────────────────────────────┘
      ↓
[ECS Fargate Rolling Update]
      ↓
[Service Available]
```

### Monitoring Pipeline Execution

```powershell
# View workflow runs
# GitHub → Actions tab

# View logs for specific job
# Actions → Select workflow run → Select job

# View deployment status
aws ecs describe-services `
  --cluster forum-microservices-cluster-dev `
  --services forum-microservices-posts-service-dev

# View task status
aws ecs list-tasks `
  --cluster forum-microservices-cluster-dev `
  --service-name forum-microservices-posts-service-dev
```

### Rollback Strategy

**Automatic Rollback**:
- If health checks fail after deployment, ECS automatically rolls back
- If container fails to start, old version continues running
- No manual intervention needed

**Manual Rollback**:
```powershell
# Option 1: Via AWS Console
# ECS → Clusters → Services → Update → Select previous task definition

# Option 2: Via GitHub Actions
# 1. Revert the commit that caused the issue
git revert <commit-hash>
git push origin main

# 2. Pipeline will automatically deploy the reverted version
```

### Cost Optimization

The separated workflows reduce costs by:
- Building only changed services
- Parallel job execution
- Efficient caching strategies
- Avoiding unnecessary deployments

**Example**:
- Single service change: ~3-5 minutes, $0.01
- All services change: ~8-12 minutes, $0.03
- Infrastructure change: ~5-8 minutes, $0.02

## 🧪 Testing

### API Endpoints

#### Posts Service
```powershell
# Get posts in a specific thread
Invoke-WebRequest -Uri "$albUrl/api/posts/in-thread/1" -Method Get

# Get posts by a specific user
Invoke-WebRequest -Uri "$albUrl/api/posts/by-user/1" -Method Get
```

#### Threads Service
```powershell
# Get all threads
Invoke-WebRequest -Uri "$albUrl/api/threads" -Method Get

# Get specific thread
Invoke-WebRequest -Uri "$albUrl/api/threads/1" -Method Get
```

#### Users Service
```powershell
# Get all users
Invoke-WebRequest -Uri "$albUrl/api/users" -Method Get

# Get specific user
Invoke-WebRequest -Uri "$albUrl/api/users/1" -Method Get
```

### Health Checks

All services expose a `/health` endpoint:
```powershell
Invoke-WebRequest -Uri "$albUrl/health" -Method Get
```

### Load Testing

For load testing to verify auto-scaling:

```powershell
# Using Apache Bench (if installed)
ab -n 10000 -c 100 $albUrl/api/threads

# Or use PowerShell for simple load
1..100 | ForEach-Object -Parallel {
    Invoke-WebRequest -Uri "$using:albUrl/api/threads" -Method Get
} -ThrottleLimit 10
```

Watch ECS console to see auto-scaling in action when CPU/memory thresholds are exceeded.

## 💰 Cost Optimization

This solution is designed for cost optimization through multiple strategies:

### 1. Serverless Database
- **DynamoDB Pay-Per-Request**: Only pay for reads/writes you use
- **No Idle Costs**: Unlike RDS, no charges when not in use
- **Global Tables**: Built-in replication, no additional services needed
- **Monthly Cost**: ~$0.19/month (small app) vs $15+/month for RDS

### 2. Serverless Compute
- **ECS Fargate**: Pay only for resources used, no idle EC2 instances
- **No server management**: Eliminates operational overhead
- **Right-sized tasks**: 0.25 vCPU, 512 MB RAM per service

### 3. Auto-Scaling
- **Dynamic scaling**: 2-10 tasks based on actual load
- **Scale-in**: Reduces tasks when demand decreases
- **Target tracking**: CPU at 70%, Memory at 80%
- **Cost savings**: Only run what you need

### 4. S3 Backend for State
- **Terraform State**: Stored in S3 ($0.023/GB/month)
- **State Locking**: DynamoDB on-demand pricing
- **Versioning**: Automatic state backup included
- **Cost**: < $1/month for state management

### 5. Efficient CI/CD
- **GitHub Actions**: 2,000 free minutes/month
- **Change Detection**: Only build/deploy modified services
- **Parallel Jobs**: Faster builds, less time charged
- **Caching**: Reduced build times and costs

### 6. ECR Lifecycle Policies
- **Automatic cleanup**: Keeps only last 10 images
- **Reduces storage costs**: Prevents accumulation of old images
- **Per-service policies**: Efficient image management

### Estimated Monthly Cost

#### Development Environment

| Resource | Quantity | Unit Cost | Monthly Cost |
|----------|----------|-----------|--------------|
| **Database** |
| DynamoDB Tables | 3 tables | Pay-per-request | $0.19 |
| DynamoDB Global Tables | 3 replicas | Replication cost | $0.15 |
| DynamoDB Backups | Daily | $0.10/GB | $0.50 |
| **Compute** |
| ECS Fargate (Primary) | 6 tasks @ 0.25 vCPU, 512MB | $0.04048/hour | $17.40 |
| ECS Fargate (DR) | 6 tasks @ 0.25 vCPU, 512MB | $0.04456/hour | $19.14 |
| **Networking** |
| Application Load Balancer (Primary) | 1 ALB | $0.0225/hour | $16.20 |
| Application Load Balancer (DR) | 1 ALB | $0.0252/hour | $18.14 |
| NAT Gateway (Primary) | 2 AZs | $0.045/hour each | $64.80 |
| NAT Gateway (DR) | 2 AZs | $0.045/hour each | $64.80 |
| Data Transfer | ~10GB | $0.09/GB | $0.90 |
| **Storage** |
| ECR Storage | ~2GB | $0.10/GB | $0.20 |
| S3 (Terraform State) | < 1GB | $0.023/GB | $0.02 |
| S3 (Backups) | ~5GB | $0.023/GB | $0.12 |
| CloudWatch Logs | ~5GB | $0.50/GB | $2.50 |
| **CI/CD** |
| GitHub Actions | Free tier | 2,000 min/month | $0.00 |
| **TOTAL (Dev)** | | | **~$205/month** |

#### Production Optimizations

For production, you can reduce costs by:

| Optimization | Savings | Notes |
|--------------|---------|-------|
| Single NAT Gateway (Primary) | -$32/month | Use 1 NAT instead of 2 (less HA) |
| Single NAT Gateway (DR) | -$32/month | Use 1 NAT instead of 2 (less HA) |
| Reduce DR tasks to 2 | -$13/month | Scale up only during failover |
| Use VPC Endpoints | -$15/month | Avoid NAT for AWS service traffic |
| Reserved Capacity | -10-20% | 1-year commitment for Fargate |
| Lifecycle Policies | -$1/month | Aggressive ECR cleanup |
| **TOTAL SAVINGS** | **~$93/month** | |
| **OPTIMIZED COST** | **~$112/month** | With optimizations applied |

#### Cost Breakdown by Component

```
Database (DynamoDB):        $0.84/month  (0.4%)
Compute (ECS Fargate):     $36.54/month (18%)
Networking (ALB + NAT):   $164.04/month (80%)
Storage (ECR + S3 + Logs):  $2.82/month  (1.4%)
CI/CD (GitHub Actions):     $0.00/month  (0%)
────────────────────────────────────────
Total:                    ~$205/month
```

**Key Insight**: Networking (NAT Gateways + ALBs) represents 80% of costs. Primary optimization target for production.

### Cost Monitoring

```powershell
# Enable AWS Cost Explorer
# AWS Console → Billing → Cost Explorer

# Set up billing alerts
aws cloudwatch put-metric-alarm `
  --alarm-name forum-microservices-billing-alert `
  --alarm-description "Alert when costs exceed $250/month" `
  --metric-name EstimatedCharges `
  --namespace AWS/Billing `
  --statistic Maximum `
  --period 86400 `
  --evaluation-periods 1 `
  --threshold 250 `
  --comparison-operator GreaterThanThreshold

# View current month costs
aws ce get-cost-and-usage `
  --time-period Start=2024-11-01,End=2024-11-30 `
  --granularity MONTHLY `
  --metrics BlendedCost
```

### Free Tier Benefits

If your AWS account is within the first 12 months:
- **ECS Fargate**: No free tier (pay-as-you-go)
- **DynamoDB**: 25 GB storage + 25 WCU + 25 RCU free (ongoing)
- **S3**: 5 GB storage + 20,000 GET + 2,000 PUT free (ongoing)
- **CloudWatch**: 5 GB logs + 10 custom metrics free (ongoing)
- **ECR**: 500 MB storage free for 12 months

**Potential Free Tier Savings**: ~$3-5/month

See `docs/COST_ESTIMATE.md` for detailed breakdown and regional variations.

## 📊 Monitoring and Logging

### CloudWatch Logs

All ECS tasks automatically send logs to CloudWatch:

```powershell
# View logs in AWS Console
# Navigate to: CloudWatch → Log groups → /ecs/forum-microservices-dev

# Or use AWS CLI
aws logs tail /ecs/forum-microservices-dev --follow --format short
```

Log groups by service:
- `/ecs/forum-microservices-dev` (prefix: `posts`, `threads`, `users`)
- `/aws/codebuild/forum-microservices-dev` (build logs)

### Container Insights

ECS Container Insights is enabled for advanced monitoring:

- CPU and memory utilization
- Network metrics
- Task-level metrics
- Service-level dashboards

Access in AWS Console: **CloudWatch → Container Insights → ECS Clusters**

### CloudWatch Alarms

Auto-scaling uses CloudWatch alarms:
- CPU utilization > 70% → Scale out
- Memory utilization > 80% → Scale out
- Metric below threshold for 5 minutes → Scale in

### Application Health

Health checks configured on:
1. **ALB Target Groups**: Check `/health` every 30s
2. **ECS Task Definition**: Container health check
3. **Docker**: Built-in HEALTHCHECK instruction

## 🔧 Troubleshooting

### Troubleshooting

#### 1. Terraform State Lock Issues

**Symptom**: "Error acquiring the state lock"

**Solutions**:
```powershell
# Check for stuck locks in DynamoDB
aws dynamodb scan --table-name forum-microservices-terraform-locks

# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>

# If lock table doesn't exist, recreate it
.\scripts\setup-terraform-backend.ps1
```

#### 2. ECS Tasks Not Starting

**Symptom**: Tasks show as "PENDING" or "STOPPED"

**Solutions**:
```powershell
# Check task logs
aws ecs describe-tasks --cluster forum-microservices-cluster-dev --tasks <task-id>

# Verify ECR images exist
aws ecr list-images --repository-name forum-microservices/posts

# Check IAM roles
aws iam get-role --role-name forum-microservices-ecs-task-execution-role-dev
```

#### 2. ECS Tasks Not Starting

**Symptom**: Tasks show as "PENDING" or "STOPPED"

**Solutions**:
```powershell
# Check task logs
aws ecs describe-tasks --cluster forum-microservices-cluster-dev --tasks <task-id>

# Common issues:
# - Image not found in ECR → Build and push images
# - IAM role missing permissions → Check task execution role
# - Insufficient CPU/memory → Increase task resources

# Verify ECR images exist
aws ecr list-images --repository-name forum-microservices/posts-dev

# Check IAM roles
aws iam get-role --role-name forum-microservices-ecs-task-execution-role-dev

# View ECS service events
aws ecs describe-services `
  --cluster forum-microservices-cluster-dev `
  --services forum-microservices-posts-service-dev `
  --query 'services[0].events[0:10]'
```

#### 3. GitHub Actions Workflow Failures

**Symptom**: Workflow fails during deployment

**Solutions**:
```powershell
# Check GitHub Secrets are configured:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_REGION
# - AWS_ACCOUNT_ID

# Verify AWS credentials work
aws sts get-caller-identity

# Check ECR login
aws ecr get-login-password --region us-east-1

# Review workflow logs in GitHub Actions tab
```

#### 4. DynamoDB Replication Issues

**Symptom**: Data not replicating to DR region

**Solutions**:
```powershell
# Check Global Table status
aws dynamodb describe-table --table-name forum-microservices-users-dev `
  --query 'Table.Replicas'

# Verify replication lag
.\scripts\dynamodb-management.ps1 -Action verify -Region us-west-2

# If replication is stuck, check:
# 1. IAM permissions for DynamoDB replication
# 2. Table is configured as Global Table
# 3. Both regions are healthy
```

#### 5. Terraform Backend Initialization Fails

**Symptom**: "Error configuring the backend" or "Backend not initialized"

**Solutions**:
```powershell
# Verify S3 bucket exists
aws s3 ls s3://forum-microservices-terraform-state-dev

# Verify DynamoDB table exists
aws dynamodb describe-table --table-name forum-microservices-terraform-locks

# Recreate backend if missing
cd scripts
.\setup-terraform-backend.ps1

# Reinitialize Terraform
cd ..\terraform
terraform init -reconfigure
```

#### 6. ALB Returns 503 Errors

**Symptom**: Service Unavailable errors

**Solutions**:
- Check target group health: AWS Console → EC2 → Target Groups
- Verify security group allows traffic from ALB to ECS tasks
- Check ECS service has running tasks
- Review task logs for application errors

#### 6. ALB Returns 503 Errors

**Symptom**: Service Unavailable errors

**Solutions**:
```powershell
# Check target group health
aws elbv2 describe-target-health `
  --target-group-arn <target-group-arn>

# Common issues:
# - No healthy targets → Check ECS tasks are running
# - Security group blocking → Verify ALB can reach tasks
# - Health check failing → Check /health endpoint

# Verify security group allows traffic from ALB to ECS
# Check ECS service has running tasks
aws ecs list-tasks `
  --cluster forum-microservices-cluster-dev `
  --service-name forum-microservices-posts-service-dev

# Review task logs for application errors
aws logs tail /ecs/forum-microservices-dev --follow
```

#### 7. Docker Images Not Pushing to ECR

**Symptom**: Build script fails during push

**Solutions**:
```powershell
# Re-authenticate with ECR
$accountId = (aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | `
  docker login --username AWS --password-stdin `
  "$accountId.dkr.ecr.us-east-1.amazonaws.com"

# Verify repository exists
aws ecr describe-repositories --repository-names forum-microservices/posts-dev

# Create repository if missing
aws ecr create-repository --repository-name forum-microservices/posts-dev

# Check Docker daemon is running
docker ps
```

#### 8. Terraform Apply Fails

**Symptom**: Resource creation errors

**Solutions**:
```powershell
# Check AWS credentials
aws sts get-caller-identity

# Verify region
aws configure get region

# Check for resource limits (VPCs, Elastic IPs, etc.)
aws service-quotas list-service-quotas --service-code vpc

# Clean up and retry
terraform destroy -auto-approve
terraform apply
```

#### 8. Terraform Apply Fails

**Symptom**: Resource creation errors

**Solutions**:
```powershell
# Check AWS credentials
aws sts get-caller-identity

# Verify region is set correctly
aws configure get region

# Common errors:
# - "ResourceAlreadyExists" → Resource exists from previous run
#   Solution: Import existing resource or destroy and recreate
# - "LimitExceeded" → AWS service quota reached
#   Solution: Request limit increase or cleanup unused resources
# - "InvalidParameterValue" → Configuration error
#   Solution: Check terraform.tfvars values

# Check for resource limits (VPCs, Elastic IPs, etc.)
aws service-quotas list-service-quotas --service-code vpc

# View detailed error
terraform apply -var="environment=dev" -auto-approve 2>&1 | Tee-Object -FilePath terraform-error.log

# Clean up and retry (caution: destroys resources)
terraform destroy -auto-approve
terraform apply -auto-approve
```

#### 9. Cannot Access Services via ALB

**Symptom**: Timeout or connection refused

**Solutions**:
```powershell
# Wait 5-10 minutes for DNS propagation
Start-Sleep -Seconds 300

# Verify ALB is "active"
aws elbv2 describe-load-balancers `
  --query 'LoadBalancers[?contains(LoadBalancerName, `forum-microservices`)].State'

# Check listener rules route to correct target groups
aws elbv2 describe-listeners `
  --load-balancer-arn <alb-arn>

# Verify target health (all should be "healthy")
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Check security groups allow HTTP (port 80) from internet
aws ec2 describe-security-groups `
  --filters "Name=tag:Project,Values=forum-microservices"

# Test from different network (some corporate firewalls block AWS)
# Try: Mobile hotspot, VPN, or different WiFi
```

#### 10. High Costs After Deployment

**Symptom**: AWS bill higher than expected

**Solutions**:
```powershell
# Check current costs
aws ce get-cost-and-usage `
  --time-period Start=2024-11-01,End=2024-11-30 `
  --granularity MONTHLY `
  --metrics BlendedCost

# Identify top cost drivers
# Usually: NAT Gateways (80% of cost)

# Cost reduction strategies:
# 1. Use single NAT Gateway instead of 2
# 2. Reduce desired_count in terraform.tfvars
# 3. Scale down DR environment when not testing
# 4. Enable VPC endpoints for AWS services

# Stop non-essential resources
aws ecs update-service `
  --cluster forum-microservices-cluster-dev `
  --service forum-microservices-posts-service-dev `
  --desired-count 0

# Set up billing alerts
aws cloudwatch put-metric-alarm `
  --alarm-name billing-alert `
  --metric-name EstimatedCharges `
  --namespace AWS/Billing `
  --statistic Maximum `
  --period 86400 `
  --evaluation-periods 1 `
  --threshold 250 `
  --comparison-operator GreaterThanThreshold
```

### Debug Commands

```powershell
# Check ECS service status
aws ecs describe-services --cluster forum-microservices-cluster-dev --services forum-microservices-posts-service-dev

# List running tasks
aws ecs list-tasks --cluster forum-microservices-cluster-dev --service-name forum-microservices-posts-service-dev

# Describe a specific task
aws ecs describe-tasks --cluster forum-microservices-cluster-dev --tasks <task-arn>

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>

# View recent logs
aws logs tail /ecs/forum-microservices-dev --follow --filter-pattern "ERROR"
```

### Getting Help

1. **AWS Documentation**: https://docs.aws.amazon.com/
2. **Terraform Registry**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
3. **AWS Support**: Create a support case in AWS Console
4. **Project Issues**: Open an issue in the repository

## 🗑️ Cleanup

To destroy all resources and avoid charges:

> 📘 **For comprehensive destruction instructions, see [DESTROY_GUIDE.md](DESTROY_GUIDE.md)**

### Quick Destroy

Use the dedicated destruction scripts for the safest and most reliable cleanup:

**Linux/macOS:**
```bash
# Dry run first (see what will be destroyed)
./scripts/terraform-destroy-all.sh --dry-run

# Destroy with confirmation
./scripts/terraform-destroy-all.sh --environment dev

# Destroy without confirmation (use with caution!)
./scripts/terraform-destroy-all.sh --environment dev --auto-approve
```

**Windows (PowerShell):**
```powershell
# Dry run first (see what will be destroyed)
.\scripts\terraform-destroy-all.ps1 -DryRun

# Destroy with confirmation
.\scripts\terraform-destroy-all.ps1 -Environment dev

# Destroy without confirmation (use with caution!)
.\scripts\terraform-destroy-all.ps1 -Environment dev -AutoApprove
```

### Option 1: Using GitHub Actions (Recommended)

```
1. Go to: GitHub → Actions → Infrastructure Deployment
2. Click: "Run workflow"
3. Select action: "destroy"
4. Click: "Run workflow"
5. Monitor the workflow execution
6. Verify all resources are deleted
```

### Option 2: Using Terraform Directly

```powershell
# Navigate to terraform directory
cd terraform

# Destroy all infrastructure
terraform destroy -var="environment=dev"

# Confirm by typing 'yes' when prompted
```

### Option 3: Using Cleanup Scripts

For comprehensive cleanup including orphaned resources:

```powershell
# Navigate to scripts directory
cd scripts

# Cleanup all resources in both regions
.\cleanup-all-resources.ps1

# This will delete:
# - ECR repositories (all regions)
# - ECS clusters and services (all regions)
# - VPCs and networking (all regions)
# - Load balancers and target groups
# - DynamoDB tables
# - S3 buckets (with confirmation)
```

### What Gets Deleted

**⚠️ Warning**: This will permanently delete:

**Compute & Containers**:
- ✓ All ECS tasks, services, and clusters
- ✓ ECR repositories and Docker images
- ✓ Application Load Balancers and target groups

**Database**:
- ✓ DynamoDB tables (including Global Tables)
- ✓ DynamoDB backups (if not protected)

**Networking**:
- ✓ VPC, subnets, route tables
- ✓ NAT gateways, Internet gateways
- ✓ Security groups, network ACLs
- ✓ Elastic IPs

**Storage & Logs**:
- ✓ S3 buckets (Terraform state, backups)
- ✓ CloudWatch log groups and alarms
- ✓ CloudWatch metrics

**IAM**:
- ✓ IAM roles and policies
- ✓ Instance profiles

### Manual Cleanup (If Needed)

If Terraform fails to delete some resources:

```powershell
# 1. Empty and delete S3 buckets manually
aws s3 rm s3://forum-microservices-terraform-state-dev --recursive
aws s3 rb s3://forum-microservices-terraform-state-dev

aws s3 rm s3://forum-microservices-backups-dev-us-east-1 --recursive
aws s3 rb s3://forum-microservices-backups-dev-us-east-1

# 2. Delete DynamoDB tables (if not deleted)
aws dynamodb delete-table --table-name forum-microservices-users-dev
aws dynamodb delete-table --table-name forum-microservices-threads-dev
aws dynamodb delete-table --table-name forum-microservices-posts-dev
aws dynamodb delete-table --table-name forum-microservices-terraform-locks

# 3. Delete ECR repositories
aws ecr delete-repository --repository-name forum-microservices/posts-dev --force
aws ecr delete-repository --repository-name forum-microservices/threads-dev --force
aws ecr delete-repository --repository-name forum-microservices/users-dev --force

# 4. Delete CloudWatch log groups
aws logs delete-log-group --log-group-name /ecs/forum-microservices-dev
aws logs delete-log-group --log-group-name /aws/ecs/forum-microservices-dev

# 5. Check for orphaned resources
.\cleanup-orphaned-resources.ps1
```

### Verify Cleanup

```powershell
# Check for remaining resources
aws ecs list-clusters
aws ecr describe-repositories
aws dynamodb list-tables
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=forum-microservices"
aws elbv2 describe-load-balancers

# Check estimated costs (should be $0 after cleanup)
aws ce get-cost-and-usage `
  --time-period Start=2024-11-01,End=2024-11-30 `
  --granularity MONTHLY `
  --metrics BlendedCost `
  --filter file://cost-filter.json
```

### Cleanup Checklist

After running cleanup, verify:
- [ ] No ECS clusters running
- [ ] No ECR repositories exist
- [ ] No DynamoDB tables exist
- [ ] No custom VPCs exist (only default VPC remains)
- [ ] No Load Balancers exist
- [ ] No NAT Gateways exist
- [ ] S3 buckets are empty or deleted
- [ ] CloudWatch log groups are deleted
- [ ] AWS Cost Explorer shows $0 estimated charges

### Keep State Management (Optional)

If you want to keep the S3 backend for future deployments:

```powershell
# Destroy only application resources, keep state backend
terraform destroy -target=module.ecs -target=module.vpc -target=module.alb

# Keep these:
# - S3 bucket: forum-microservices-terraform-state-dev
# - DynamoDB table: forum-microservices-terraform-locks
```

### Cost After Cleanup

After complete cleanup:
- **Expected cost**: $0.00/month
- **Possible small charges**: 
  - S3 requests for state bucket (~$0.01/month if kept)
  - CloudWatch metrics retention (~$0.01/month)
  - Data transfer for final cleanup (~$0.05 one-time)

**Total**: < $0.10/month if state backend is retained, $0.00/month if fully deleted.

## 👥 Team Members

[Add your team members here]

- **Member 1**: [Name] - [Role] - [Email]
- **Member 2**: [Name] - [Role] - [Email]
- **Member 3**: [Name] - [Role] - [Email]

## 📄 License

[Add your license information]

## 🙏 Acknowledgments

- AWS Documentation and Best Practices
- Terraform AWS Provider Documentation
- Node.js and Koa.js Communities

---

**Project Repository**: https://github.com/fikrat86/microservices_docker  
**Last Updated**: November 2024  
**Version**: 2.0.0

**Key Updates in v2.0.0**:
- ✅ DynamoDB implementation with Global Tables
- ✅ Multi-region Disaster Recovery (us-east-1 ↔ us-west-2)
- ✅ GitHub Actions CI/CD (separated workflows)
- ✅ Terraform S3 backend with state locking
- ✅ Comprehensive testing (Jest, ESLint, Trivy)
- ✅ Automated cleanup scripts
- ✅ Complete documentation overhaul
