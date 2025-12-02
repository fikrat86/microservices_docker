# DynamoDB Tables for Forum Microservices
# Serverless NoSQL database with auto-scaling and global replication

# Users Table (Primary Region with Global Table Replica)
resource "aws_dynamodb_table" "users" {
  name           = "${var.project_name}-users-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST" # On-demand pricing for cost optimization
  hash_key       = "userId"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  # Global Secondary Index for querying by email
  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  # DR Region Replica
  dynamic "replica" {
    for_each = var.enable_global_tables ? [1] : []
    content {
      region_name = var.dr_region
      point_in_time_recovery = true
    }
  }

  # Point-in-time recovery for backup
  point_in_time_recovery {
    enabled = true
  }

  # Enable encryption at rest
  server_side_encryption {
    enabled = true
  }

  # Tags for cost tracking
  tags = {
    Name        = "${var.project_name}-users-${var.environment}"
    Service     = "users"
    Environment = var.environment
  }

  # Prevent accidental deletion in production
  lifecycle {
    prevent_destroy = false
  }
}

# Threads Table (Primary Region with Global Table Replica)
resource "aws_dynamodb_table" "threads" {
  name           = "${var.project_name}-threads-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "threadId"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "threadId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  # GSI for querying threads by creation date
  global_secondary_index {
    name            = "CreatedAtIndex"
    hash_key        = "createdAt"
    projection_type = "ALL"
  }

  # DR Region Replica
  dynamic "replica" {
    for_each = var.enable_global_tables ? [1] : []
    content {
      region_name = var.dr_region
      point_in_time_recovery = true
    }
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-threads-${var.environment}"
    Service     = "threads"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Posts Table (Primary Region with Global Table Replica)
resource "aws_dynamodb_table" "posts" {
  name           = "${var.project_name}-posts-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "postId"
  range_key      = "threadId"
  stream_enabled = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "postId"
    type = "S"
  }

  attribute {
    name = "threadId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  # GSI for querying posts by thread
  global_secondary_index {
    name            = "ThreadIndex"
    hash_key        = "threadId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  # GSI for querying posts by user
  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "userId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  # DR Region Replica
  dynamic "replica" {
    for_each = var.enable_global_tables ? [1] : []
    content {
      region_name = var.dr_region
      point_in_time_recovery = true
    }
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-posts-${var.environment}"
    Service     = "posts"
    Environment = var.environment
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Auto Scaling for Users Table (optional, for provisioned mode)
# Commented out since we're using PAY_PER_REQUEST mode
# Uncomment if switching to provisioned capacity

# resource "aws_appautoscaling_target" "users_read" {
#   max_capacity       = 100
#   min_capacity       = 5
#   resource_id        = "table/${aws_dynamodb_table.users.name}"
#   scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#   service_namespace  = "dynamodb"
# }

# resource "aws_appautoscaling_policy" "users_read_policy" {
#   name               = "${var.project_name}-users-read-scaling-${var.environment}"
#   policy_type        = "TargetTrackingScaling"
#   resource_id        = aws_appautoscaling_target.users_read.resource_id
#   scalable_dimension = aws_appautoscaling_target.users_read.scalable_dimension
#   service_namespace  = aws_appautoscaling_target.users_read.service_namespace

#   target_tracking_scaling_policy_configuration {
#     predefined_metric_specification {
#       predefined_metric_type = "DynamoDBReadCapacityUtilization"
#     }
#     target_value = 70.0
#   }
# }

# CloudWatch Alarms for monitoring
resource "aws_cloudwatch_metric_alarm" "users_table_throttles" {
  alarm_name          = "${var.project_name}-users-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors DynamoDB throttling"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.users.name
  }
}

resource "aws_cloudwatch_metric_alarm" "posts_table_throttles" {
  alarm_name          = "${var.project_name}-posts-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors DynamoDB throttling"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.posts.name
  }
}

resource "aws_cloudwatch_metric_alarm" "threads_table_throttles" {
  alarm_name          = "${var.project_name}-threads-throttles-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors DynamoDB throttling"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.threads.name
  }
}

# Backup vault for on-demand backups
resource "aws_backup_vault" "dynamodb_backup" {
  name = "${var.project_name}-dynamodb-backup-${var.environment}"

  tags = {
    Name        = "${var.project_name}-dynamodb-backup-${var.environment}"
    Environment = var.environment
  }
}

# Backup plan for DynamoDB tables
resource "aws_backup_plan" "dynamodb_backup_plan" {
  name = "${var.project_name}-dynamodb-backup-plan-${var.environment}"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.dynamodb_backup.name
    schedule          = "cron(0 2 * * ? *)" # Daily at 2 AM UTC

    lifecycle {
      delete_after = 30 # Keep backups for 30 days
    }

    /* DR copy disabled - requires DR provider
    copy_action {
      destination_vault_arn = aws_backup_vault.dr_dynamodb_backup.arn

      lifecycle {
        delete_after = 30
      }
    }
    */
  }

  tags = {
    Name        = "${var.project_name}-dynamodb-backup-plan-${var.environment}"
    Environment = var.environment
  }
}

# Backup vault in DR region - DISABLED (requires DR provider)
/*
resource "aws_backup_vault" "dr_dynamodb_backup" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  name     = "${var.project_name}-dynamodb-backup-${var.environment}-dr"

  tags = {
    Name        = "${var.project_name}-dynamodb-backup-${var.environment}-dr"
    Environment = "${var.environment}-dr"
  }
}
*/


# Backup selection for DynamoDB tables
resource "aws_backup_selection" "dynamodb_backup_selection" {
  name         = "${var.project_name}-dynamodb-selection-${var.environment}"
  iam_role_arn = aws_iam_role.backup_role.arn
  plan_id      = aws_backup_plan.dynamodb_backup_plan.id

  resources = [
    aws_dynamodb_table.users.arn,
    aws_dynamodb_table.threads.arn,
    aws_dynamodb_table.posts.arn,
  ]
}

# IAM role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.project_name}-backup-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-backup-role-${var.environment}"
  }
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "restore_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# Output table names and ARNs
output "dynamodb_users_table_name" {
  description = "Name of the Users DynamoDB table"
  value       = aws_dynamodb_table.users.name
}

output "dynamodb_threads_table_name" {
  description = "Name of the Threads DynamoDB table"
  value       = aws_dynamodb_table.threads.name
}

output "dynamodb_posts_table_name" {
  description = "Name of the Posts DynamoDB table"
  value       = aws_dynamodb_table.posts.name
}

output "dynamodb_users_table_arn" {
  description = "ARN of the Users DynamoDB table"
  value       = aws_dynamodb_table.users.arn
}

output "dynamodb_threads_table_arn" {
  description = "ARN of the Threads DynamoDB table"
  value       = aws_dynamodb_table.threads.arn
}

output "dynamodb_posts_table_arn" {
  description = "ARN of the Posts DynamoDB table"
  value       = aws_dynamodb_table.posts.arn
}
