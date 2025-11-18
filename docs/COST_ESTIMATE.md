# Cost Estimate - Forum Microservices Infrastructure

## Executive Summary

This document provides a detailed cost breakdown for the Forum Microservices infrastructure deployed on AWS. The solution is designed with cost optimization in mind while maintaining high availability and scalability.

### Estimated Monthly Cost Range

| Environment | Monthly Cost (USD) |
|-------------|-------------------|
| Development | $105 - $153 |
| Production (Small) | $250 - $350 |
| Production (Medium) | $500 - $750 |

**Note**: All estimates are for US East (N. Virginia) region as of November 2025. Actual costs may vary based on usage patterns, data transfer, and AWS pricing changes.

## Development Environment Cost Breakdown

### Assumptions
- Region: US East (N. Virginia) - us-east-1
- Availability Zones: 2
- Service Count: 3 (Posts, Threads, Users)
- Minimum Tasks: 2 per service (6 total)
- Average Tasks: 3 per service (9 total)
- Maximum Tasks: 10 per service (30 total)
- Uptime: 24/7 (730 hours/month)
- Data Transfer: Light (10 GB/month)

### 1. Compute - ECS Fargate

**Configuration per Task**:
- CPU: 0.25 vCPU
- Memory: 0.5 GB (512 MB)

**Pricing** (as of Nov 2025):
- vCPU: $0.04048 per vCPU per hour
- Memory: $0.004445 per GB per hour

**Calculation - Minimum Load (6 tasks)**:
```
vCPU cost = 6 tasks × 0.25 vCPU × $0.04048 × 730 hours
          = 6 × 0.25 × 0.04048 × 730
          = $44.33/month

Memory cost = 6 tasks × 0.5 GB × $0.004445 × 730 hours
            = 6 × 0.5 × 0.004445 × 730
            = $9.73/month

Total (minimum) = $44.33 + $9.73 = $54.06/month
```

**Calculation - Average Load (9 tasks)**:
```
vCPU cost = 9 × 0.25 × 0.04048 × 730 = $66.49/month
Memory cost = 9 × 0.5 × 0.004445 × 730 = $14.60/month

Total (average) = $66.49 + $14.60 = $81.09/month
```

**Estimated Range**: **$54 - $81/month** (depending on auto-scaling)

### 2. Load Balancer - Application Load Balancer

**Pricing**:
- ALB Hour: $0.0225 per hour
- LCU Hour: $0.008 per LCU per hour
- Estimated LCUs: 1 (light traffic)

**Calculation**:
```
ALB cost = $0.0225 × 730 hours = $16.43/month
LCU cost = $0.008 × 1 LCU × 730 hours = $5.84/month

Total ALB = $16.43 + $5.84 = $22.27/month
```

**Estimated**: **$22/month**

### 3. NAT Gateway

**Configuration**: 2 NAT Gateways (one per AZ for high availability)

**Pricing**:
- NAT Gateway Hour: $0.045 per hour
- Data Processing: $0.045 per GB processed

**Calculation**:
```
NAT Gateway hours = 2 gateways × 730 hours × $0.045
                  = 2 × 730 × 0.045
                  = $65.70/month

Data processing = 10 GB × $0.045
                = $0.45/month

Total NAT = $65.70 + $0.45 = $66.15/month
```

**Estimated**: **$66/month**

**Cost Optimization Option**: 
- Use single NAT Gateway: **~$33/month** (reduces HA)
- Production recommended: Keep 2 for resilience

### 4. Container Registry - Amazon ECR

**Storage**:
- Images: 3 services × 10 versions each
- Average image size: 100 MB per image
- Total storage: 3 GB

**Pricing**:
- Storage: $0.10 per GB per month

**Calculation**:
```
ECR storage = 3 GB × $0.10 = $0.30/month
```

**Estimated**: **$0.30/month**

### 5. CloudWatch Logs

**Log Volume**:
- Logs per task: ~100 MB/month
- Total tasks (average): 9
- Total logs: 900 MB = 0.9 GB

**Pricing**:
- Ingestion: $0.50 per GB
- Storage (first 5 GB): Free

**Calculation**:
```
Log ingestion = 0.9 GB × $0.50 = $0.45/month
Log storage = Free (under 5 GB)

Total CloudWatch = $0.45/month
```

**Estimated**: **$0.45/month**

### 6. CloudWatch Metrics & Alarms

**Resources**:
- Container Insights: Enabled
- Custom Metrics: ~20 metrics
- Alarms: ~12 alarms (auto-scaling)

**Pricing**:
- Metrics: $0.30 per metric per month
- Alarms: $0.10 per alarm per month

**Calculation**:
```
Metrics = 20 × $0.30 = $6.00/month
Alarms = 12 × $0.10 = $1.20/month

Total CloudWatch Metrics = $6.00 + $1.20 = $7.20/month
```

**Estimated**: **$7/month**

### 7. VPC Endpoints

**Interface Endpoints**: 3 (ECR API, ECR DKR, CloudWatch Logs)

**Pricing**:
- Endpoint Hour: $0.01 per AZ per hour
- Data Processing: $0.01 per GB

**Calculation**:
```
Endpoint hours = 3 endpoints × 2 AZs × 730 hours × $0.01
               = 3 × 2 × 730 × 0.01
               = $43.80/month

Data processing = 10 GB × $0.01 = $0.10/month

Total VPC Endpoints = $43.80 + $0.10 = $43.90/month
```

**Note**: VPC Endpoints save money by avoiding NAT Gateway data charges for AWS services

**Estimated**: **$44/month**

### 8. S3 - Artifact Storage

**Storage**:
- Pipeline artifacts: ~1 GB
- Lifecycle policy: Delete after 30 days

**Pricing**:
- Standard Storage: $0.023 per GB per month

**Calculation**:
```
S3 storage = 1 GB × $0.023 = $0.023/month
```

**Estimated**: **<$0.10/month**

### 9. CodePipeline

**Pipelines**: 3 (one per service)

**Pricing**:
- Active pipeline: $1.00 per pipeline per month

**Calculation**:
```
CodePipeline = 3 pipelines × $1.00 = $3.00/month
```

**Estimated**: **$3/month**

### 10. CodeBuild

**Usage**:
- Builds per month: ~30 (10 per service)
- Build time: ~5 minutes per build
- Compute type: BUILD_GENERAL1_SMALL

**Pricing**:
- BUILD_GENERAL1_SMALL: $0.005 per minute

**Calculation**:
```
Build minutes = 30 builds × 5 minutes = 150 minutes
CodeBuild cost = 150 × $0.005 = $0.75/month
```

**Note**: First 100 build minutes per month are free

**Estimated**: **<$1/month**

### 11. CodeCommit

**Storage**:
- Repository size: ~50 MB total
- Active users: 5

**Pricing**:
- First 5 users: Free
- Storage (first 50 GB): Free

**Estimated**: **Free**

### 12. Data Transfer

**Assumptions**:
- Incoming data: Free
- Outgoing data to internet: 10 GB/month
- Inter-AZ data transfer: 5 GB/month

**Pricing**:
- Data out to internet: $0.09 per GB (first 10 TB)
- Inter-AZ transfer: $0.01 per GB

**Calculation**:
```
Internet out = 10 GB × $0.09 = $0.90/month
Inter-AZ = 5 GB × $0.01 = $0.05/month

Total Data Transfer = $0.90 + $0.05 = $0.95/month
```

**Estimated**: **$1/month**

## Development Environment - Total Monthly Cost

| Service | Monthly Cost (USD) |
|---------|-------------------|
| ECS Fargate (6-9 tasks) | $54 - $81 |
| Application Load Balancer | $22 |
| NAT Gateway (2 AZs) | $66 |
| ECR Storage | $0.30 |
| CloudWatch Logs | $0.45 |
| CloudWatch Metrics & Alarms | $7 |
| VPC Endpoints | $44 |
| S3 Artifacts | <$0.10 |
| CodePipeline | $3 |
| CodeBuild | <$1 |
| CodeCommit | Free |
| Data Transfer | $1 |
| **TOTAL** | **$197.75 - $224.75** |

**Simplified Estimate**: **$200 - $225/month**

**With Cost Optimizations** (single NAT, reduced endpoints):
- **$105 - $153/month**

## Production Environment Cost Estimates

### Small Production (Similar to Dev, Optimized)

**Changes from Dev**:
- Desired count: 3 tasks per service (9 total)
- Average tasks: 5 per service (15 total)
- Higher data transfer: 50 GB/month
- Larger images in ECR

**Estimated**: **$250 - $350/month**

### Medium Production

**Specifications**:
- CPU: 0.5 vCPU per task
- Memory: 1 GB per task
- Desired count: 4 tasks per service (12 total)
- Average tasks: 7 per service (21 total)
- Data transfer: 200 GB/month

**Key Cost Changes**:
```
ECS Fargate (21 tasks @ 0.5 vCPU, 1GB):
  vCPU: 21 × 0.5 × $0.04048 × 730 = $311/month
  Memory: 21 × 1 × $0.004445 × 730 = $68/month
  Total Fargate = $379/month

ALB (higher LCUs) = $35/month
NAT Gateway = $100/month (more traffic)
Data Transfer = $20/month (200 GB)

Total = ~$600/month
```

**Estimated**: **$500 - $750/month**

## Cost Optimization Strategies

### 1. Compute Optimization

**Current**: 0.25 vCPU, 512 MB per task

**Recommendations**:
- Right-size based on metrics (may need less memory)
- Use Fargate Spot for development (up to 70% savings)
- Consider Savings Plans for predictable workloads (20% savings)

**Potential Savings**: **15-30% on compute**

### 2. Network Optimization

**High-Cost Items**:
- NAT Gateway: $66/month (largest single cost)
- VPC Endpoints: $44/month

**Recommendations**:
- **Dev**: Single NAT Gateway (save $33/month)
- **Prod**: Keep 2 NAT Gateways for HA
- VPC Endpoints already save ~$10-20/month in NAT data charges

**Potential Savings**: **$33/month in dev**

### 3. Storage Optimization

**Current**: ECR lifecycle policy (keep 10 images)

**Recommendations**:
- Reduce to 5 images in dev (save ~$0.15/month - minimal)
- Enable S3 Intelligent-Tiering for artifacts
- Use CloudWatch Logs retention (7 days in dev)

**Potential Savings**: **$1-2/month**

### 4. Monitoring Optimization

**Current**: Full Container Insights enabled

**Recommendations**:
- Disable Container Insights in dev (save $6/month)
- Use basic CloudWatch metrics (free)
- Reduce custom metrics count

**Potential Savings**: **$6-10/month in dev**

### 5. CI/CD Optimization

**Current**: 3 separate pipelines

**Recommendations**:
- Consolidate pipelines (would complicate deployments)
- Use scheduled builds instead of on-commit (reduce CodeBuild)
- Cache Docker layers (faster builds, same cost)

**Potential Savings**: **Minimal (~$1/month)**

## Cost Comparison with Alternatives

### Alternative 1: EC2 Auto Scaling Group

**Configuration**:
- Instance type: t3.small (2 vCPU, 2 GB)
- Instances: 3 (one per service, in ASG)

**Costs**:
```
EC2 On-Demand: 3 × $0.0208/hour × 730 = $45.55/month
ALB: $22/month
NAT Gateway: $66/month
Total: ~$133/month
```

**Analysis**:
- ✅ Lower compute cost
- ❌ Manual server management
- ❌ Less granular scaling
- ❌ Higher operational overhead

**Verdict**: Fargate preferred for serverless benefits

### Alternative 2: AWS Lambda

**Not suitable** for this use case:
- Persistent HTTP servers (not request-response)
- Long-running connections
- Container-based architecture better for microservices

### Alternative 3: EKS (Kubernetes)

**Costs**:
```
EKS Control Plane: $73/month
Fargate/EC2 nodes: Similar to ECS
Total: ~$200-300/month
```

**Analysis**:
- ❌ Higher cost (control plane)
- ❌ More complex
- ✅ More features (if needed)

**Verdict**: ECS sufficient for this scale

## Monthly Cost Breakdown by Category

### Development Environment

```
┌─────────────────────────────────────────┐
│ Cost Distribution (Dev)                 │
├─────────────────────────────────────────┤
│                                         │
│ NAT Gateway     ████████████  33%       │
│ VPC Endpoints   ████████      22%       │
│ ECS Fargate     ████████      27%       │
│ ALB             ████          11%       │
│ Monitoring      ██            4%        │
│ CI/CD           █             2%        │
│ Other           █             1%        │
│                                         │
└─────────────────────────────────────────┘

Total: ~$200/month
```

### Cost Breakdown

1. **Network (55%)**: NAT + VPC Endpoints + Data Transfer
2. **Compute (27%)**: ECS Fargate tasks
3. **Load Balancing (11%)**: ALB + Target Groups
4. **Monitoring (4%)**: CloudWatch + Container Insights
5. **CI/CD (2%)**: CodePipeline + CodeBuild
6. **Storage (1%)**: ECR + S3

## Annual Cost Projections

### Development Environment

| Scenario | Monthly | Annual |
|----------|---------|--------|
| Minimum (6 tasks, optimized) | $105 | $1,260 |
| Average (9 tasks, full features) | $200 | $2,400 |
| Maximum (15 tasks) | $225 | $2,700 |

### Production Environment

| Scenario | Monthly | Annual | Notes |
|----------|---------|--------|-------|
| Small | $300 | $3,600 | Similar to dev, more traffic |
| Medium | $600 | $7,200 | 2x resources, higher traffic |
| Large | $1,200 | $14,400 | 4x resources, premium features |

## Savings Plans & Reserved Capacity

### Compute Savings Plans (Not applicable to Fargate)
- Fargate doesn't support Compute Savings Plans
- Consider EC2 if cost is primary concern

### Fargate Spot (Development)
- Up to 70% discount
- May be interrupted
- Good for non-critical dev workloads

**Example**:
```
Regular Fargate: $81/month (9 tasks)
Fargate Spot: $24/month (70% savings)
```

## Cost Monitoring & Alerts

### Recommended CloudWatch Alarms

1. **Daily Cost Exceeds $10**
   ```
   Metric: EstimatedCharges (Billing)
   Threshold: > $10/day ($300/month)
   Action: Email notification
   ```

2. **ECS Task Count Exceeds 15**
   ```
   Metric: CPUUtilization or RunningTaskCount
   Threshold: > 15 tasks total
   Action: Email + investigate
   ```

3. **NAT Gateway Data Transfer Spike**
   ```
   Metric: BytesOutToSource
   Threshold: > 50 GB/day
   Action: Check for issues
   ```

### AWS Cost Explorer

Enable Cost Explorer to:
- Track daily spending
- View cost by service
- Identify cost anomalies
- Forecast monthly costs

### Budgets

Set up AWS Budgets:
- **Development**: $250/month alert at 80%
- **Production**: Custom based on projections

## Conclusion

### Summary

The Forum Microservices infrastructure provides:
- **High availability**: Multi-AZ deployment
- **Auto-scaling**: 2-10 tasks per service
- **Serverless**: No server management
- **CI/CD**: Automated deployments
- **Cost-effective**: ~$200/month for dev

### Key Takeaways

1. **Largest Cost**: NAT Gateway (33% of total)
   - Necessary for high availability
   - Consider single NAT in dev

2. **Scalable Cost**: ECS Fargate (27% of total)
   - Grows with traffic
   - Auto-scales down to save money

3. **Fixed Costs**: ALB, VPC Endpoints, Monitoring
   - ~$73/month baseline
   - Independent of traffic

4. **Negligible**: Storage, CI/CD
   - <$5/month combined

### Recommendations

**Development**:
- Start with minimum configuration: **$105-153/month**
- Monitor and adjust based on actual usage
- Use Fargate Spot for additional savings

**Production**:
- Budget **$300-600/month** depending on scale
- Enable Container Insights for monitoring
- Set up cost alarms and budgets
- Consider Savings Plans if workload is predictable

---

**Document Version**: 1.0  
**Last Updated**: November 2025  
**Pricing Source**: AWS Pricing Calculator (as of Nov 2025)  
**Disclaimer**: Actual costs may vary based on usage, region, and AWS pricing changes
