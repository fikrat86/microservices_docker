# DynamoDB Quick Reference Card

## 🚀 Quick Commands

### Setup & Deployment
```powershell
# 1. Deploy infrastructure
cd terraform
terraform apply -var="enable_global_tables=true"

# 2. Install migration dependencies
cd ..\scripts
npm install

# 3. Migrate data
.\dynamodb-management.ps1 -Action migrate

# 4. Verify deployment
.\dynamodb-management.ps1 -Action verify
```

### Common Operations
```powershell
# Seed sample data
.\scripts\dynamodb-management.ps1 -Action seed

# Backup tables to JSON
.\scripts\dynamodb-management.ps1 -Action backup -BackupFile "backup.json"

# Restore from backup
.\scripts\dynamodb-management.ps1 -Action restore -BackupFile "backup.json"

# Verify DR region
.\scripts\dynamodb-management.ps1 -Action verify -Region us-west-2
```

### AWS CLI Commands
```powershell
# List all tables
aws dynamodb list-tables --region us-east-1

# Describe table
aws dynamodb describe-table --table-name forum-microservices-users-dev

# Scan table (get all items)
aws dynamodb scan --table-name forum-microservices-users-dev

# Get specific item
aws dynamodb get-item \
  --table-name forum-microservices-users-dev \
  --key '{"userId": {"S": "1"}}'

# Put item
aws dynamodb put-item \
  --table-name forum-microservices-users-dev \
  --item '{"userId": {"S": "999"}, "email": {"S": "test@example.com"}, "name": {"S": "Test User"}}'
```

## 📊 Table Schema Reference

### Users Table
| Field | Type | Key | Index |
|-------|------|-----|-------|
| userId | String | Primary | - |
| email | String | - | GSI: EmailIndex |
| name | String | - | - |
| createdAt | String | - | - |

### Threads Table
| Field | Type | Key | Index |
|-------|------|-----|-------|
| threadId | String | Primary | - |
| title | String | - | - |
| description | String | - | - |
| createdAt | String | - | GSI: CreatedAtIndex |

### Posts Table
| Field | Type | Key | Index |
|-------|------|-----|-------|
| postId | String | Primary | - |
| threadId | String | Sort Key | GSI: ThreadIndex |
| userId | String | - | GSI: UserIndex |
| title | String | - | - |
| content | String | - | - |
| createdAt | String | - | Range in both GSIs |

## 🔧 Environment Variables

### ECS Task Configuration
```bash
USE_DYNAMODB=true
AWS_REGION=us-east-1
DYNAMODB_USERS_TABLE=forum-microservices-users-dev
DYNAMODB_THREADS_TABLE=forum-microservices-threads-dev
DYNAMODB_POSTS_TABLE=forum-microservices-posts-dev
```

### Local Development (JSON Mode)
```bash
USE_DYNAMODB=false  # or unset
# Service will use db.json files automatically
```

### Local Development (DynamoDB Mode)
```powershell
$env:USE_DYNAMODB = "true"
$env:AWS_REGION = "us-east-1"
$env:DYNAMODB_USERS_TABLE = "forum-microservices-users-dev"
cd users
npm start
```

## 💰 Cost Calculator

### Pay-Per-Request Pricing
```
Read Request:  $0.25 per million
Write Request: $1.25 per million
Storage:       $0.25 per GB-month
```

### Example Calculations
```
Small App (10K reads/day, 1K writes/day):
- Reads:  10,000 × 30 / 1M × $0.25 = $0.075
- Writes:  1,000 × 30 / 1M × $1.25 = $0.0375
- Storage: 0.1 GB × $0.25 = $0.025
- Global Tables: 2× writes = $0.0375
Total: ~$0.19/month

Medium App (100K reads/day, 10K writes/day):
- Reads:  100,000 × 30 / 1M × $0.25 = $0.75
- Writes:  10,000 × 30 / 1M × $1.25 = $0.375
- Storage: 1 GB × $0.25 = $0.25
- Global Tables: 2× writes = $0.375
Total: ~$1.75/month
```

## 🔍 Monitoring

### CloudWatch Metrics
```
Namespace: AWS/DynamoDB

Key Metrics:
- ConsumedReadCapacityUnits
- ConsumedWriteCapacityUnits
- UserErrors (throttling)
- SystemErrors
- SuccessfulRequestLatency
```

### View Metrics
```powershell
# Get consumed capacity
aws cloudwatch get-metric-statistics \
  --namespace AWS/DynamoDB \
  --metric-name ConsumedReadCapacityUnits \
  --dimensions Name=TableName,Value=forum-microservices-users-dev \
  --start-time 2024-11-23T00:00:00Z \
  --end-time 2024-11-23T23:59:59Z \
  --period 3600 \
  --statistics Sum
```

## 🚨 Troubleshooting

### Table Not Found
```powershell
# Check Terraform outputs
cd terraform
terraform output dynamodb_users_table_name

# List tables
aws dynamodb list-tables
```

### Access Denied
```powershell
# Check ECS task role
aws iam get-role-policy \
  --role-name forum-microservices-ecs-task-role-dev \
  --policy-name forum-microservices-ecs-task-policy-dev
```

### Replication Lag
```powershell
# Check replica status
aws dynamodb describe-table \
  --table-name forum-microservices-users-dev \
  --region us-east-1 \
  --query 'Table.Replicas[*].{Region:RegionName,Status:ReplicaStatus}'
```

### High Costs
```powershell
# Check CloudWatch metrics for usage
# Consider:
# 1. Switch to provisioned capacity if predictable
# 2. Optimize queries (use indexes, not scans)
# 3. Enable TTL for old data
# 4. Disable Global Tables if DR not needed
```

## 📚 Code Examples

### Using DatabaseAdapter (Services)
```javascript
const DatabaseAdapter = require('../shared/database-adapter')

// Initialize
const db = new DatabaseAdapter(
  process.env.DYNAMODB_USERS_TABLE,
  require('./db.json').users,
  'userId'
)

// Get all
const users = await db.getAll()

// Get by ID
const user = await db.getById('123')

// Query by index
const users = await db.queryByIndex('EmailIndex', 'email', 'alice@example.com')

// Create
await db.create({ userId: '4', email: 'new@example.com', name: 'New User' })

// Update
await db.update('4', { name: 'Updated Name' })

// Delete
await db.delete('4')
```

### Direct AWS SDK Usage
```javascript
const AWS = require('aws-sdk')
const dynamodb = new AWS.DynamoDB.DocumentClient()

// Get item
const result = await dynamodb.get({
  TableName: 'forum-microservices-users-dev',
  Key: { userId: '123' }
}).promise()

// Put item
await dynamodb.put({
  TableName: 'forum-microservices-users-dev',
  Item: {
    userId: '456',
    email: 'user@example.com',
    name: 'John Doe',
    createdAt: new Date().toISOString()
  }
}).promise()

// Query with GSI
const result = await dynamodb.query({
  TableName: 'forum-microservices-users-dev',
  IndexName: 'EmailIndex',
  KeyConditionExpression: 'email = :email',
  ExpressionAttributeValues: {
    ':email': 'user@example.com'
  }
}).promise()
```

## 🔐 IAM Permissions Required

### ECS Task Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem"
      ],
      "Resource": [
        "arn:aws:dynamodb:*:*:table/forum-microservices-*",
        "arn:aws:dynamodb:*:*:table/forum-microservices-*/index/*"
      ]
    }
  ]
}
```

## 📖 Documentation Links

- **Complete Guide**: `docs/DYNAMODB_GUIDE.md`
- **Summary**: `docs/DYNAMODB_SUMMARY.md`
- **Architecture**: `docs/ARCHITECTURE.md`
- **DR Guide**: `docs/DISASTER_RECOVERY.md`

## 🎯 Common Workflows

### New Deployment
```powershell
1. terraform apply
2. .\scripts\dynamodb-management.ps1 -Action seed
3. .\scripts\build-and-push.ps1
4. .\scripts\deploy.ps1
```

### Data Migration
```powershell
1. .\scripts\dynamodb-management.ps1 -Action backup -BackupFile "before-migration.json"
2. .\scripts\dynamodb-management.ps1 -Action migrate
3. .\scripts\dynamodb-management.ps1 -Action verify
```

### Disaster Recovery Test
```powershell
1. .\scripts\dynamodb-management.ps1 -Action verify -Region us-west-2
2. .\scripts\dr-management.ps1 -Action test-dr
3. # Verify data consistency between regions
```

### Restore from Backup
```powershell
1. # Find backup file
2. .\scripts\dynamodb-management.ps1 -Action restore -BackupFile "backup-2024-11-23.json"
3. .\scripts\dynamodb-management.ps1 -Action verify
```

---

**Last Updated**: November 23, 2024  
**Version**: 1.0  
**Region**: us-east-1 (Primary), us-west-2 (DR)
