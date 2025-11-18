# Forum Microservices - DevOps Solutions Project

A complete microservices-based forum application deployed on AWS using Infrastructure as Code (Terraform), containerized with Docker, orchestrated with ECS Fargate, and automated with CI/CD pipelines.

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Solution Requirements](#solution-requirements)
- [Technology Stack](#technology-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [AWS Deployment](#aws-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Testing](#testing)
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
✅ **Auto-scaling**: CPU and memory-based scaling for cost optimization  
✅ **Load Balanced**: Application Load Balancer with path-based routing  
✅ **Infrastructure as Code**: Complete Terraform configuration  
✅ **Automated CI/CD**: CodePipeline with blue/green deployments  
✅ **High Availability**: Multi-AZ deployment with health checks  

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
- **Load Balancing**: Application Load Balancer (ALB)
- **Container Registry**: Amazon ECR
- **Networking**: VPC, Subnets, NAT Gateway, Internet Gateway
- **Infrastructure as Code**: Terraform 1.5+

### CI/CD
- **Source Control**: AWS CodeCommit
- **Build**: AWS CodeBuild
- **Pipeline**: AWS CodePipeline
- **Deployment**: ECS Rolling Deployment

### Monitoring & Logging
- **Logs**: CloudWatch Logs
- **Metrics**: CloudWatch Container Insights
- **Alarms**: CloudWatch Alarms (for auto-scaling)

### Development Tools
- **Containerization**: Docker
- **Local Orchestration**: Docker Compose
- **Reverse Proxy**: Nginx (local development)

## 📁 Project Structure

```
microservices_docker/
├── posts/                          # Posts microservice
│   ├── server.js                   # Service implementation
│   ├── db.json                     # Sample data
│   ├── package.json                # Dependencies
│   ├── Dockerfile                  # Multi-stage Docker build
│   ├── buildspec.yml               # CodeBuild configuration
│   ├── .dockerignore              # Docker ignore file
│   └── .env.example               # Environment variables template
│
├── threads/                        # Threads microservice
│   ├── server.js
│   ├── db.json
│   ├── package.json
│   ├── Dockerfile
│   ├── buildspec.yml
│   ├── .dockerignore
│   └── .env.example
│
├── users/                          # Users microservice
│   ├── server.js
│   ├── db.json
│   ├── package.json
│   ├── Dockerfile
│   ├── buildspec.yml
│   ├── .dockerignore
│   └── .env.example
│
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Provider configuration
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── vpc.tf                     # VPC and networking
│   ├── security_groups.tf         # Security groups
│   ├── alb.tf                     # Application Load Balancer
│   ├── ecr.tf                     # Container registry
│   ├── ecs_cluster.tf             # ECS cluster
│   ├── ecs_services.tf            # ECS services and tasks
│   ├── iam.tf                     # IAM roles and policies
│   ├── autoscaling.tf             # Auto-scaling configuration
│   ├── cicd_iam.tf                # CI/CD IAM roles
│   ├── codebuild.tf               # CodeBuild projects
│   ├── codepipeline.tf            # CodePipeline configuration
│   └── terraform.tfvars.example   # Variables template
│
├── scripts/                        # Deployment scripts
│   ├── deploy.ps1                 # Main deployment script
│   ├── build-and-push.ps1         # Build and push Docker images
│   └── test-services.ps1          # Test deployed services
│
├── nginx/                          # Local development proxy
│   └── nginx.conf                 # Nginx configuration
│
├── docs/                           # Documentation
│   ├── ARCHITECTURE.md            # Architecture diagram
│   └── COST_ESTIMATE.md           # Cost analysis
│
├── docker-compose.yml              # Local development environment
├── .gitignore                      # Git ignore rules
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

### Step 1: Prepare Terraform Variables

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

### Step 2: Build and Push Docker Images

Before deploying infrastructure, push initial Docker images to ECR:

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

## 🔄 CI/CD Pipeline

### Architecture

The CI/CD pipeline uses AWS native services for automated deployments:

1. **CodeCommit**: Git repositories for source code
2. **CodeBuild**: Builds Docker images and pushes to ECR
3. **CodePipeline**: Orchestrates the entire pipeline
4. **ECS**: Rolling deployment to Fargate tasks

### Pipeline Stages

```
Source → Build → Deploy
  ↓        ↓        ↓
CodeCommit → CodeBuild → ECS Fargate
             (Docker)    (Rolling Update)
```

### Setting Up CI/CD

#### 1. Push Code to CodeCommit

```powershell
# Get CodeCommit repository URLs
cd terraform
$postsRepo = terraform output -raw codecommit_posts_clone_url
$threadsRepo = terraform output -raw codecommit_threads_clone_url
$usersRepo = terraform output -raw codecommit_users_clone_url

# Set up Git credentials for AWS CodeCommit
# Follow: https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-gc.html

# Clone and push each service
# Posts Service
git clone $postsRepo posts-repo
cd posts-repo
Copy-Item -Recurse ..\posts\* .
git add .
git commit -m "Initial commit"
git push origin main
cd ..

# Repeat for threads and users services
```

#### 2. Pipeline Triggers

The pipeline automatically triggers when code is pushed to the `main` branch. CloudWatch Events monitor CodeCommit for changes.

#### 3. Monitor Pipeline Execution

```powershell
# View pipeline status in AWS Console
# Navigate to: CodePipeline → Pipelines → Select your pipeline

# Or use AWS CLI
aws codepipeline get-pipeline-state --name forum-microservices-posts-pipeline-dev
```

### Pipeline Workflow

1. **Developer pushes code** to CodeCommit `main` branch
2. **CloudWatch Event** triggers CodePipeline
3. **CodeBuild** pulls source code
4. **CodeBuild** builds Docker image using `buildspec.yml`
5. **CodeBuild** pushes image to ECR
6. **CodePipeline** updates ECS service with new image
7. **ECS** performs rolling deployment:
   - Starts new tasks with new image
   - Waits for health checks to pass
   - Drains connections from old tasks
   - Terminates old tasks
8. **Auto-rollback** if health checks fail

### Blue/Green Deployment Strategy

The current implementation uses **ECS Rolling Deployment** which provides:
- Zero-downtime deployments
- Automatic health checks
- Automatic rollback on failure

Configuration in ECS service:
```hcl
deployment_configuration {
  maximum_percent = 200          # Can run 2x desired count during deployment
  minimum_healthy_percent = 100  # Always maintain full capacity
}
```

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

This solution is designed for cost optimization:

### 1. Serverless Compute
- **ECS Fargate**: Pay only for resources used, no idle EC2 instances
- **No server management**: Eliminates operational overhead

### 2. Auto-Scaling
- **Dynamic scaling**: 2-10 tasks based on actual load
- **Scale-in**: Reduces tasks when demand decreases
- **Target tracking**: CPU at 70%, Memory at 80%

### 3. VPC Endpoints
- **Private connectivity**: Avoid NAT Gateway charges for AWS services
- **Included endpoints**: S3, ECR, CloudWatch Logs

### 4. Resource Right-Sizing
- **Small tasks**: 0.25 vCPU, 512 MB RAM (adequate for these services)
- **Adjustable**: Can be tuned based on actual usage

### 5. ECR Lifecycle Policies
- **Automatic cleanup**: Keeps only last 10 images
- **Reduces storage costs**: Prevents accumulation of old images

### Estimated Monthly Cost (Dev Environment)

See `docs/COST_ESTIMATE.md` for detailed breakdown. Approximate costs:

| Resource | Cost Range |
|----------|-----------|
| ECS Fargate (6 tasks @ 0.25 vCPU, 512MB) | $15-25/month |
| Application Load Balancer | $16-20/month |
| NAT Gateway (2 AZs) | $65-90/month |
| ECR Storage | $1-3/month |
| CloudWatch Logs | $3-5/month |
| Data Transfer | $5-10/month |
| **Total** | **$105-153/month** |

**Production optimizations** can include:
- Single NAT Gateway (save ~$35/month)
- Reserved capacity pricing
- Savings Plans for consistent workloads

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

### Common Issues

#### 1. ECS Tasks Not Starting

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

#### 2. ALB Returns 503 Errors

**Symptom**: Service Unavailable errors

**Solutions**:
- Check target group health: AWS Console → EC2 → Target Groups
- Verify security group allows traffic from ALB to ECS tasks
- Check ECS service has running tasks
- Review task logs for application errors

#### 3. Docker Images Not Pushing to ECR

**Symptom**: Build script fails during push

**Solutions**:
```powershell
# Re-authenticate with ECR
$accountId = (aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$accountId.dkr.ecr.us-east-1.amazonaws.com"

# Verify repository exists
aws ecr describe-repositories --repository-names forum-microservices/posts
```

#### 4. Terraform Apply Fails

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

#### 5. Cannot Access Services via ALB

**Symptom**: Timeout or connection refused

**Solutions**:
- Wait 5-10 minutes for DNS propagation
- Verify ALB is "active": AWS Console → EC2 → Load Balancers
- Check listener rules: Should route to correct target groups
- Verify target health: All should be "healthy"
- Check security groups allow HTTP (port 80) from internet

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

```powershell
# Using deployment script
.\scripts\deploy.ps1 -Action destroy -Environment dev

# Or manually with Terraform
cd terraform
terraform destroy -var="environment=dev"

# Confirm by typing 'yes' when prompted
```

**Warning**: This will permanently delete:
- All ECS tasks, services, and cluster
- Application Load Balancer and target groups
- ECR repositories and Docker images
- VPC, subnets, NAT gateways, etc.
- CodePipeline, CodeBuild, CodeCommit repositories
- CloudWatch logs and alarms
- S3 bucket with pipeline artifacts

**Manual cleanup** (if needed):
- Empty and delete S3 artifact bucket manually if Terraform fails
- Delete CloudWatch log groups if retained

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

**Project Repository**: [Add your repository URL]  
**Last Updated**: November 2025  
**Version**: 1.0.0
