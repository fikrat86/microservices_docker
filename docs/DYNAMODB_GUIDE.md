# DynamoDB Database Implementation Guide

## Overview

This microservices project uses **Amazon DynamoDB** as its primary database, providing:

- **Serverless Architecture**: No server management required
- **Cost Optimization**: Pay-per-request pricing model
- **Auto-Scaling**: Built-in capacity management
- **Global Tables**: Multi-region replication for disaster recovery
- **High Performance**: Single-digit millisecond latency
- **Built-in Backup**: Point-in-time recovery and automated backups

## Architecture

### Database Tables

#### 1. Users Table
- **Primary Key**: `userId` (String)
- **GSI**: `EmailIndex` on `email`
- **Attributes**:
  - `userId`: Unique user identifier
  - `email`: User email (indexed)
  - `name`: User display name
  - `createdAt`: ISO 8601 timestamp

#### 2. Threads Table
- **Primary Key**: `threadId` (String)
- **GSI**: `CreatedAtIndex` on `createdAt`
- **Attributes**:
  - `threadId`: Unique thread identifier
  - `title`: Thread title
  - `description`: Thread description
  - `createdAt`: ISO 8601 timestamp (indexed)

#### 3. Posts Table
- **Primary Key**: `postId` (String)
- **Sort Key**: `threadId` (String)
- **GSI 1**: `ThreadIndex` on `threadId` + `createdAt`
- **GSI 2**: `UserIndex` on `userId` + `createdAt`
- **Attributes**:
  - `postId`: Unique post identifier
  - `threadId`: Parent thread ID
  - `userId`: Author user ID
  - `title`: Post title
  - `content`: Post content
  - `createdAt`: ISO 8601 timestamp

### Multi-Region Setup

```
┌─────────────────────────────────────────────────────────────┐
│                     Primary Region (us-east-1)              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Users Table  │  │Threads Table │  │ Posts Table  │      │
│  │  (Primary)   │  │  (Primary)   │  │  (Primary)   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         │   Bi-directional Global Tables     │              │
│         └──────────────────┼──────────────────┘              │
└─────────────────────────────┼──────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │  Auto Replication │
                    └─────────┬─────────┘
                              │
┌─────────────────────────────┼──────────────────────────────┐
│                     DR Region (us-west-2)                   │
│         ┌─────────────────────┴─────────────────┐           │
│         │                                       │           │
│  ┌──────▼───────┐  ┌──────────────┐  ┌──────▼─────────┐   │
│  │ Users Table  │  │Threads Table │  │ Posts Table    │   │
│  │  (Replica)   │  │  (Replica)   │  │  (Replica)     │   │
│  └──────────────┘  └──────────────┘  └────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Cost Optimization

### Billing Mode: Pay-Per-Request

- **No Minimum Charges**: Pay only for what you use
- **No Capacity Planning**: Auto-scales to demand
- **Cost-Effective for**: Variable, unpredictable workloads

**Pricing (as of 2024)**:
- Write: $1.25 per million requests
- Read: $0.25 per million requests
- Storage: $0.25 per GB-month

### Cost Estimate for Small Application

**Assumptions**:
- 10,000 reads/day
- 1,000 writes/day
- 100 MB storage

**Monthly Cost**:
```
Reads:  (10,000 × 30) / 1,000,000 × $0.25  = $0.075
Writes: (1,000 × 30) / 1,000,000 × $1.25   = $0.0375
Storage: 0.1 GB × $0.25                    = $0.025
Global Tables Replication: 2× writes       = $0.0375
Backups: Negligible                        = $0.01
────────────────────────────────────────────────────
Total:                                     ≈ $0.19/month
```

### Alternative: Provisioned Capacity

For **predictable** workloads, consider provisioned capacity:
- 5 RCU + 5 WCU ≈ $3.29/month (reserved capacity)
- Auto-scaling between min/max thresholds
- Up to 67% savings for consistent traffic

## Deployment

### 1. Enable DynamoDB in Terraform

Edit `terraform/terraform.tfvars`:

```hcl
# Enable DynamoDB
enable_global_tables = true
dynamodb_billing_mode = "PAY_PER_REQUEST"
dynamodb_point_in_time_recovery = true
```

### 2. Deploy Infrastructure

```powershell
cd terraform
terraform init
terraform plan
terraform apply
```

This creates:
- ✅ 3 DynamoDB tables in primary region (us-east-1)
- ✅ 3 DynamoDB table replicas in DR region (us-west-2)
- ✅ Global Tables with bi-directional replication
- ✅ Point-in-time recovery (PITR)
- ✅ AWS Backup vault and plans
- ✅ CloudWatch alarms for throttling
- ✅ IAM permissions for ECS tasks

### 3. Migrate Data from JSON Files

```powershell
# Install Node.js dependencies
cd scripts
npm install

# Run migration
.\dynamodb-management.ps1 -Action migrate

# Verify migration
.\dynamodb-management.ps1 -Action verify
```

### 4. Update Service Code

The services automatically detect DynamoDB via environment variable `USE_DYNAMODB=true`.

No code changes needed! The `DatabaseAdapter` handles both:
- **DynamoDB mode**: When deployed to ECS
- **JSON mode**: For local development

## Data Migration

### Migrate from db.json to DynamoDB

```powershell
# Method 1: PowerShell script
.\scripts\dynamodb-management.ps1 -Action migrate -Region us-east-1

# Method 2: Node.js script directly
cd scripts
npm install
node migrate-to-dynamodb.js
```

**What it does**:
1. Reads `users/db.json`, `threads/db.json`, `posts/db.json`
2. Transforms JSON format to DynamoDB schema
3. Batch writes to DynamoDB tables
4. Verifies item counts

### Seed Sample Data

```powershell
.\scripts\dynamodb-management.ps1 -Action seed -Region us-east-1
```

Creates:
- 3 sample users
- 2 sample threads
- 2 sample posts

## Backup & Recovery

### Automatic Backups

**Point-in-Time Recovery (PITR)**:
- Enabled on all tables
- Restore to any point in last 35 days
- Continuous backups, no performance impact

**AWS Backup**:
- Daily snapshots at 2 AM UTC
- 30-day retention
- Cross-region copy to DR region (us-west-2)

### Manual Backup

```powershell
# Backup all tables to JSON
.\scripts\dynamodb-management.ps1 -Action backup -BackupFile "backup-2024-11-23.json"
```

### Restore from Backup

```powershell
# Restore from JSON backup
.\scripts\dynamodb-management.ps1 -Action restore -BackupFile "backup-2024-11-23.json"

# Restore from PITR (AWS Console or CLI)
aws dynamodb restore-table-to-point-in-time \
  --source-table-name forum-microservices-users-dev \
  --target-table-name forum-microservices-users-restored \
  --restore-date-time 2024-11-23T10:00:00Z \
  --region us-east-1
```

## Disaster Recovery

### Global Tables (Active-Active)

**Automatic Features**:
- ✅ Bi-directional replication (< 1 second latency)
- ✅ Conflict resolution (last-writer-wins)
- ✅ Read/write from either region
- ✅ Automatic failover

### RTO/RPO

- **Recovery Time Objective (RTO)**: < 1 minute
  - DR region is already active and synchronized
  - Just redirect traffic via Route 53/ALB

- **Recovery Point Objective (RPO)**: < 1 second
  - Global Tables provide near real-time replication
  - Minimal data loss

### Failover Procedure

1. **Check DR region sync status**:
   ```powershell
   .\scripts\dynamodb-management.ps1 -Action verify -Region us-west-2
   ```

2. **Redirect traffic**: Update Route 53 or ALB to DR region

3. **ECS services in DR region**: Already have DynamoDB access via IAM roles

4. **Monitor**: Check CloudWatch metrics in DR region

### Failback to Primary

1. Ensure primary region is healthy
2. Verify data consistency
3. Redirect traffic back to primary
4. Global Tables automatically sync any changes

## Monitoring & Alerts

### CloudWatch Metrics

**Key Metrics** (available in AWS Console):
- `ConsumedReadCapacityUnits`: Read throughput
- `ConsumedWriteCapacityUnits`: Write throughput
- `UserErrors`: Client-side errors (throttling)
- `SystemErrors`: Service-side errors
- `SuccessfulRequestLatency`: Performance

### CloudWatch Alarms

**Automatically Created**:
- Throttling alarms on all tables (primary + DR)
- Alert when `UserErrors > 10` in 10 minutes
- Can integrate with SNS for notifications

### View Table Status

```powershell
# Verify all tables
.\scripts\dynamodb-management.ps1 -Action verify

# Check specific table
aws dynamodb describe-table \
  --table-name forum-microservices-users-dev \
  --region us-east-1
```

## Local Development

### Use JSON Files (Default)

Services default to JSON mode when `USE_DYNAMODB != true`:

```bash
# In each service directory
cd users
npm install
npm start  # Uses db.json
```

### Test with DynamoDB Locally

**Option 1**: Use DynamoDB Local (Docker)

```powershell
# Run DynamoDB Local
docker run -p 8000:8000 amazon/dynamodb-local

# Point services to local DynamoDB
$env:USE_DYNAMODB = "true"
$env:AWS_REGION = "us-east-1"
$env:DYNAMODB_ENDPOINT = "http://localhost:8000"
```

**Option 2**: Use AWS DynamoDB (Dev Tables)

```powershell
# Set environment variables
$env:USE_DYNAMODB = "true"
$env:AWS_REGION = "us-east-1"
$env:DYNAMODB_USERS_TABLE = "forum-microservices-users-dev"

# Ensure AWS credentials configured
aws configure

# Start service
cd users
npm start
```

## Service Code Integration

### DatabaseAdapter Usage

Services use the shared `DatabaseAdapter` class:

```javascript
const DatabaseAdapter = require('../shared/database-adapter')
const db = require('./db.json')

// Initialize (auto-detects DynamoDB vs JSON mode)
const adapter = new DatabaseAdapter(
  process.env.DYNAMODB_USERS_TABLE || 'forum-microservices-users-dev',
  db.users,
  'userId'
)

// Get all users
const users = await adapter.getAll()

// Get by ID
const user = await adapter.getById('123')

// Query by index
const user = await adapter.queryByIndex('EmailIndex', 'email', 'alice@example.com')

// Create
await adapter.create({ userId: '4', name: 'Dave', email: 'dave@example.com' })

// Update
await adapter.update('4', { name: 'David' })

// Delete
await adapter.delete('4')

// Health check
const health = await adapter.healthCheck()
```

### Environment Variables

**ECS Task Definition** (automatically set by Terraform):
- `USE_DYNAMODB=true`
- `AWS_REGION=us-east-1`
- `DYNAMODB_USERS_TABLE=forum-microservices-users-dev`
- `DYNAMODB_THREADS_TABLE=forum-microservices-threads-dev`
- `DYNAMODB_POSTS_TABLE=forum-microservices-posts-dev`

**IAM Permissions** (automatically granted):
- `dynamodb:GetItem`
- `dynamodb:PutItem`
- `dynamodb:UpdateItem`
- `dynamodb:DeleteItem`
- `dynamodb:Query`
- `dynamodb:Scan`
- `dynamodb:BatchGetItem`
- `dynamodb:BatchWriteItem`

## Troubleshooting

### Issue: "Table does not exist"

**Solution**:
```powershell
# Verify table names
cd terraform
terraform output dynamodb_users_table_name
terraform output dynamodb_threads_table_name
terraform output dynamodb_posts_table_name

# Check if tables exist
aws dynamodb list-tables --region us-east-1
```

### Issue: "Access Denied" errors

**Solution**:
```powershell
# Check ECS task role has DynamoDB permissions
aws iam get-role-policy \
  --role-name forum-microservices-ecs-task-role-dev \
  --policy-name forum-microservices-ecs-task-policy-dev
```

### Issue: Throttling errors

**Symptoms**: `ProvisionedThroughputExceededException`

**Solutions**:
1. **For Pay-Per-Request**: Rare, check if hitting soft limits
2. **For Provisioned**: Increase RCU/WCU or enable auto-scaling
3. **Implement backoff**: Use exponential backoff in code
4. **Use DAX**: Add DynamoDB Accelerator for caching

### Issue: High costs

**Solutions**:
1. **Review usage**: Check CloudWatch metrics
2. **Optimize queries**: Use indexes instead of scans
3. **Enable TTL**: Auto-delete old data
4. **Consider provisioned**: Switch if workload is predictable
5. **Reduce Global Tables**: Disable DR replica if not needed

### Issue: Replication lag

**Check replication status**:
```powershell
aws dynamodb describe-table \
  --table-name forum-microservices-users-dev \
  --region us-east-1 \
  --query 'Table.Replicas[*].{Region:RegionName,Status:ReplicaStatus}'
```

## Performance Optimization

### 1. Use Indexes Wisely

```javascript
// ❌ Bad: Full table scan
const users = await adapter.getAll()
const user = users.find(u => u.email === 'alice@example.com')

// ✅ Good: Use GSI
const users = await adapter.queryByIndex('EmailIndex', 'email', 'alice@example.com')
```

### 2. Batch Operations

```javascript
// ❌ Bad: Multiple single writes
for (const user of users) {
  await adapter.create(user)
}

// ✅ Good: Batch write (in DatabaseAdapter)
await batchWriteItems(tableName, users)
```

### 3. Projection Expressions

```javascript
// Get only specific attributes to reduce data transfer
const params = {
  TableName: 'users',
  Key: { userId: '123' },
  ProjectionExpression: 'userId, #n, email',
  ExpressionAttributeNames: { '#n': 'name' }
}
```

### 4. Caching with DAX

For read-heavy workloads, consider DynamoDB Accelerator (DAX):
- In-memory cache
- Microsecond latency
- Write-through caching
- Drop-in replacement (no code changes)

## Security Best Practices

### 1. Encryption

✅ **At Rest**: Enabled by default (AWS managed keys)
✅ **In Transit**: All connections use TLS

### 2. IAM Permissions

✅ **Principle of Least Privilege**: ECS tasks have table-specific permissions
✅ **No Hardcoded Credentials**: Use IAM roles

### 3. VPC Endpoints

Consider using VPC endpoints for DynamoDB:
- Traffic stays within AWS network
- No internet gateway required
- Reduced latency and costs

```hcl
# Add to terraform/vpc.tf
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.aws_region}.dynamodb"
  route_table_ids = [aws_route_table.private.id]
}
```

### 4. Audit Logging

Enable CloudTrail for DynamoDB API calls:
- Track all data plane operations
- Monitor for suspicious activity
- Compliance and auditing

## Next Steps

1. **Deploy infrastructure**: `terraform apply`
2. **Migrate data**: `.\scripts\dynamodb-management.ps1 -Action migrate`
3. **Update services**: Rebuild Docker images with aws-sdk dependency
4. **Deploy to ECS**: Push images and update task definitions
5. **Test endpoints**: Verify CRUD operations work
6. **Monitor**: Check CloudWatch metrics and logs
7. **Set up alerts**: Configure SNS notifications for alarms

## Additional Resources

- [DynamoDB Developer Guide](https://docs.aws.amazon.com/dynamodb/)
- [Global Tables](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GlobalTables.html)
- [Best Practices](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/best-practices.html)
- [Pricing Calculator](https://aws.amazon.com/dynamodb/pricing/)
