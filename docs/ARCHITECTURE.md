# Architecture Documentation

## System Architecture Diagram

### High-Level Architecture

```
                                    ┌─────────────────┐
                                    │   Internet      │
                                    │   Users         │
                                    └────────┬────────┘
                                             │
                                             │ HTTPS/HTTP
                                             ▼
                            ┌────────────────────────────┐
                            │  Application Load Balancer │
                            │  (Public Subnets, Multi-AZ)│
                            │  - SSL Termination         │
                            │  - Path-based Routing      │
                            │  - Health Checks           │
                            └────────┬───────────────────┘
                                     │
                    ┌────────────────┼────────────────┐
                    │                │                │
            /api/posts       /api/threads      /api/users
                    │                │                │
                    ▼                ▼                ▼
         ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
         │ Posts        │  │ Threads      │  │ Users        │
         │ Target Group │  │ Target Group │  │ Target Group │
         └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
                │                  │                  │
         ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐
         │ ECS Service  │  │ ECS Service  │  │ ECS Service  │
         │ Posts        │  │ Threads      │  │ Users        │
         │ (2-10 tasks) │  │ (2-10 tasks) │  │ (2-10 tasks) │
         │ Auto-scaling │  │ Auto-scaling │  │ Auto-scaling │
         └──────┬───────┘  └──────┬───────┘  └──────┬───────┘
                │                  │                  │
                │    ┌─────────────┼─────────────┐   │
                │    │             │             │   │
                ▼    ▼             ▼             ▼   ▼
         ┌────────────────────────────────────────────────┐
         │           ECS Fargate Cluster                  │
         │        (Private Subnets, Multi-AZ)            │
         │                                                │
         │  ┌──────┐ ┌──────┐ ┌──────┐  ┌──────┐       │
         │  │Task 1│ │Task 2│ │Task 3│  │Task N│       │
         │  │0.25vCPU │0.25vCPU│0.25vCPU│0.25vCPU│      │
         │  │512 MB│ │512 MB│ │512 MB│  │512 MB│       │
         │  └──────┘ └──────┘ └──────┘  └──────┘       │
         └───────────────┬────────────────────────────────┘
                         │
                         │ Pull Images
                         ▼
              ┌─────────────────────┐
              │ Amazon ECR          │
              │ (Container Registry)│
              │ - posts:latest      │
              │ - threads:latest    │
              │ - users:latest      │
              └─────────────────────┘
```

### Network Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│ VPC: 10.0.0.0/16                                                    │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Availability Zone: us-east-1a                                 │ │
│  │                                                                │ │
│  │  ┌────────────────────────┐  ┌────────────────────────┐      │ │
│  │  │ Public Subnet          │  │ Private Subnet          │      │ │
│  │  │ 10.0.0.0/24            │  │ 10.0.100.0/24          │      │ │
│  │  │                        │  │                         │      │ │
│  │  │ - Internet Gateway     │  │ - ECS Tasks (Posts)     │      │ │
│  │  │ - ALB (AZ1)            │  │ - ECS Tasks (Threads)   │      │ │
│  │  │ - NAT Gateway          │  │ - ECS Tasks (Users)     │      │ │
│  │  │                        │  │ - VPC Endpoints         │      │ │
│  │  └────────────────────────┘  └────────────────────────┘      │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ Availability Zone: us-east-1b                                 │ │
│  │                                                                │ │
│  │  ┌────────────────────────┐  ┌────────────────────────┐      │ │
│  │  │ Public Subnet          │  │ Private Subnet          │      │ │
│  │  │ 10.0.1.0/24            │  │ 10.0.101.0/24          │      │ │
│  │  │                        │  │                         │      │ │
│  │  │ - Internet Gateway     │  │ - ECS Tasks (Posts)     │      │ │
│  │  │ - ALB (AZ2)            │  │ - ECS Tasks (Threads)   │      │ │
│  │  │ - NAT Gateway          │  │ - ECS Tasks (Users)     │      │ │
│  │  │                        │  │ - VPC Endpoints         │      │ │
│  │  └────────────────────────┘  └────────────────────────┘      │ │
│  └──────────────────────────────────────────────────────────────┘ │
│                                                                     │
│  VPC Endpoints (Interface):                                        │
│  - com.amazonaws.us-east-1.ecr.api                                │
│  - com.amazonaws.us-east-1.ecr.dkr                                │
│  - com.amazonaws.us-east-1.logs                                   │
│                                                                     │
│  VPC Endpoints (Gateway):                                          │
│  - com.amazonaws.us-east-1.s3                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### CI/CD Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                         CI/CD Pipeline Flow                           │
└──────────────────────────────────────────────────────────────────────┘

    Developer                  Source                   Build
       │                         │                        │
       │  1. git push            │                        │
       │────────────────────────▶│                        │
       │                         │                        │
       │                    ┌────▼─────┐                 │
       │                    │CodeCommit│                 │
       │                    │ Git Repo │                 │
       │                    └────┬─────┘                 │
       │                         │                        │
       │                         │ 2. Trigger Event       │
       │                         │    (CloudWatch)        │
       │                         ▼                        │
       │                    ┌────────────┐               │
       │                    │CodePipeline│               │
       │                    │  Workflow  │               │
       │                    └────┬───────┘               │
       │                         │                        │
       │                         │ 3. Start Build         │
       │                         ▼                        │
       │                                           ┌──────▼──────┐
       │                                           │ CodeBuild   │
       │                                           │             │
       │                                           │ - Build     │
       │                                           │ - Test      │
       │                                           │ - Package   │
       │                                           └──────┬──────┘
       │                                                  │
       │                                                  │ 4. Push Image
       │                                                  ▼
       │                                           ┌─────────────┐
       │                                           │   ECR       │
       │                                           │ Docker Repo │
       │                                           └──────┬──────┘
       │                                                  │
       │                                                  │ 5. Deploy
       │                                                  ▼
       │                                           ┌─────────────┐
       │                                           │ ECS Fargate │
       │                                           │             │
       │                                           │ Rolling     │
       │                                           │ Deployment  │
       │                                           │             │
       │                                           │ ┌─────────┐ │
       │                                           │ │New Tasks│ │
       │                                           │ └─────────┘ │
       │                                           │ ┌─────────┐ │
       │                                           │ │Old Tasks│ │
       │                                           │ └─────────┘ │
       │                                           └─────────────┘
       │                                                  │
       │                         6. Health Checks         │
       │◀─────────────────────────────────────────────────┘
       │
       │  7. Deployment Complete
       │
```

### Security Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Security Layers                             │
└─────────────────────────────────────────────────────────────────┘

1. Network Security
   ├── Internet Gateway (Public access only to ALB)
   ├── Security Groups
   │   ├── ALB SG: Allow 80/443 from 0.0.0.0/0
   │   ├── ECS Tasks SG: Allow 3000 from ALB SG only
   │   └── VPC Endpoints SG: Allow 443 from VPC CIDR
   └── Private Subnets (No direct internet access)

2. IAM Security
   ├── ECS Task Execution Role
   │   ├── Pull images from ECR
   │   ├── Write logs to CloudWatch
   │   └── Assume role for tasks
   ├── ECS Task Role
   │   └── Application-level permissions
   ├── CodePipeline Role
   │   ├── Access S3 artifacts
   │   ├── Trigger CodeBuild
   │   └── Deploy to ECS
   └── CodeBuild Role
       ├── Build Docker images
       ├── Push to ECR
       └── Write logs

3. Container Security
   ├── Non-root user (nodejs:1001)
   ├── Minimal base image (node:20-alpine)
   ├── Multi-stage builds
   ├── Image scanning (ECR)
   └── Read-only root filesystem (optional)

4. Data Security
   ├── Encryption at rest (ECR, S3)
   ├── Encryption in transit (ALB → ECS)
   └── VPC Endpoints (Private connectivity)

5. Monitoring & Compliance
   ├── CloudWatch Logs (All services)
   ├── Container Insights (Metrics)
   ├── CloudWatch Alarms (Anomalies)
   └── AWS CloudTrail (API audit)
```

### Auto-Scaling Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                  Auto-Scaling Strategy                        │
└──────────────────────────────────────────────────────────────┘

Metrics:
  - ECS Service CPU Utilization
  - ECS Service Memory Utilization

Thresholds:
  - CPU Target: 70%
  - Memory Target: 80%

┌─────────────────────────────────────────────────────────────┐
│                                                              │
│  High Load                                                   │
│  ────────────────────────────────────────────────           │
│                                                              │
│  CPU > 70% OR Memory > 80%                                   │
│         │                                                    │
│         ▼                                                    │
│  ┌───────────────┐                                          │
│  │CloudWatch     │                                          │
│  │Alarm Triggered│                                          │
│  └───────┬───────┘                                          │
│          │                                                   │
│          ▼                                                   │
│  ┌──────────────────┐                                       │
│  │Auto Scaling      │                                       │
│  │Policy Executes   │                                       │
│  └───────┬──────────┘                                       │
│          │                                                   │
│          ▼                                                   │
│  ┌──────────────────────────┐                               │
│  │Increase Desired Count    │                               │
│  │Current: 2 → Target: 4    │                               │
│  └───────┬──────────────────┘                               │
│          │                                                   │
│          ▼                                                   │
│  ┌──────────────────────────┐                               │
│  │ECS Starts New Tasks      │                               │
│  │ - Task 3 (Starting)      │                               │
│  │ - Task 4 (Starting)      │                               │
│  └───────┬──────────────────┘                               │
│          │                                                   │
│          ▼                                                   │
│  ┌──────────────────────────┐                               │
│  │Tasks Register with ALB   │                               │
│  │Health checks pass         │                               │
│  └───────┬──────────────────┘                               │
│          │                                                   │
│          ▼                                                   │
│  ┌──────────────────────────┐                               │
│  │Capacity Increased        │                               │
│  │Load Distributed          │                               │
│  └──────────────────────────┘                               │
│                                                              │
│  ────────────────────────────────────────────────           │
│  Low Load (Scale In)                                         │
│                                                              │
│  CPU < 70% AND Memory < 80% for 5 minutes                    │
│         │                                                    │
│         ▼                                                    │
│  Decrease Desired Count: 4 → 2                              │
│  Gracefully drain and terminate tasks                        │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Capacity Limits:
  - Minimum: 2 tasks per service
  - Maximum: 10 tasks per service
  - Total: 6-30 tasks across all services
```

## Design Decisions

### 1. Why ECS Fargate?

**Advantages**:
- Serverless: No EC2 instance management
- Cost-effective: Pay only for resources used
- Auto-scaling: Scales compute automatically
- High availability: Multi-AZ by default
- Security: Task-level isolation

**Alternative considered**: ECS on EC2
- Rejected due to operational overhead and fixed costs

### 2. Why Application Load Balancer?

**Advantages**:
- Layer 7 routing (path-based)
- Health checks with auto-recovery
- SSL termination
- WebSocket support
- Multi-AZ for high availability

**Alternative considered**: Network Load Balancer
- Rejected: No path-based routing needed for this use case

### 3. Why CodePipeline over Jenkins?

**Advantages**:
- Fully managed (no infrastructure)
- Native AWS integration
- Pay-per-use pricing
- Built-in security (IAM)

**Alternative considered**: Self-hosted Jenkins
- Rejected due to operational overhead and infrastructure costs

### 4. Why Multi-AZ Deployment?

**Advantages**:
- High availability (99.99% SLA)
- Automatic failover
- Resilience to AZ failures
- Load distribution

**Cost consideration**: Higher cost (2x NAT Gateways)
- Justified for production resilience

## Scalability Characteristics

### Vertical Scaling
- Task CPU: 256-4096 (adjustable)
- Task Memory: 512 MB-30 GB (adjustable)
- Current: 0.25 vCPU, 512 MB (adequate for current load)

### Horizontal Scaling
- Min capacity: 2 tasks (always running)
- Max capacity: 10 tasks (scales on demand)
- Scale-out time: ~60 seconds
- Scale-in cooldown: 5 minutes

### Expected Performance
- **Single task**: ~1000 req/sec
- **2 tasks (min)**: ~2000 req/sec
- **10 tasks (max)**: ~10,000 req/sec
- **Latency**: <100ms (p99)

## Resilience Features

### High Availability
1. **Multi-AZ deployment**: 2 availability zones
2. **ALB health checks**: 30-second interval
3. **Auto-recovery**: Unhealthy tasks replaced automatically
4. **Connection draining**: Graceful shutdown (30s)

### Disaster Recovery
1. **Infrastructure as Code**: Redeploy in minutes
2. **Immutable infrastructure**: No configuration drift
3. **Version control**: All code in Git
4. **Automated backups**: ECR image retention

### Fault Tolerance
1. **Rolling deployments**: Zero-downtime updates
2. **Health-based routing**: Traffic to healthy tasks only
3. **Auto-rollback**: Failed deployments revert automatically
4. **Circuit breaking**: Target group deregistration

## Performance Optimization

### Network Optimization
- VPC Endpoints: Reduce NAT Gateway traffic
- Keep-alive connections: Reduce connection overhead
- ALB connection pooling: Reuse connections

### Container Optimization
- Multi-stage builds: Smaller image sizes
- Alpine Linux: Minimal base image (~5 MB)
- Layer caching: Faster builds
- Health checks: Fast task recovery

### Application Optimization
- Async/await: Non-blocking I/O
- CORS enabled: Browser compatibility
- Request logging: Performance monitoring
- Error handling: Graceful degradation

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Maintained By**: DevOps Team
