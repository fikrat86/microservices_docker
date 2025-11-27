# DynamoDB Global Tables for Disaster Recovery
# Enables automatic multi-region replication for all tables

# Global Tables provide:
# - Multi-region replication (Primary: us-east-1, DR: us-west-2)
# - Automatic conflict resolution
# - Low latency reads in both regions
# - Active-active capability

# Users Global Table Replica (DR Region)
resource "aws_dynamodb_table" "users_replica" {
  provider       = aws.dr
  name           = "${var.project_name}-users-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
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

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-users-${var.environment}-dr"
    Service     = "users"
    Environment = "${var.environment}-dr"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Threads Global Table Replica (DR Region)
resource "aws_dynamodb_table" "threads_replica" {
  provider       = aws.dr
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

  global_secondary_index {
    name            = "CreatedAtIndex"
    hash_key        = "createdAt"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-threads-${var.environment}-dr"
    Service     = "threads"
    Environment = "${var.environment}-dr"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Posts Global Table Replica (DR Region)
resource "aws_dynamodb_table" "posts_replica" {
  provider       = aws.dr
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

  global_secondary_index {
    name            = "ThreadIndex"
    hash_key        = "threadId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "userId"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = {
    Name        = "${var.project_name}-posts-${var.environment}-dr"
    Service     = "posts"
    Environment = "${var.environment}-dr"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Enable Global Tables (Version 2019.11.21)
# This creates bi-directional replication between regions

resource "aws_dynamodb_table_replica" "users_global" {
  count            = var.enable_global_tables ? 1 : 0
  provider         = aws.dr
  global_table_arn = aws_dynamodb_table.users.arn
  
  tags = {
    Name        = "${var.project_name}-users-global-${var.environment}"
    Environment = var.environment
  }

  depends_on = [
    aws_dynamodb_table.users,
    aws_dynamodb_table.users_replica
  ]
}

resource "aws_dynamodb_table_replica" "threads_global" {
  count            = var.enable_global_tables ? 1 : 0
  provider         = aws.dr
  global_table_arn = aws_dynamodb_table.threads.arn
  
  tags = {
    Name        = "${var.project_name}-threads-global-${var.environment}"
    Environment = var.environment
  }

  depends_on = [
    aws_dynamodb_table.threads,
    aws_dynamodb_table.threads_replica
  ]
}

resource "aws_dynamodb_table_replica" "posts_global" {
  count            = var.enable_global_tables ? 1 : 0
  provider         = aws.dr
  global_table_arn = aws_dynamodb_table.posts.arn
  
  tags = {
    Name        = "${var.project_name}-posts-global-${var.environment}"
    Environment = var.environment
  }

  depends_on = [
    aws_dynamodb_table.posts,
    aws_dynamodb_table.posts_replica
  ]
}

# CloudWatch Alarms for DR tables
resource "aws_cloudwatch_metric_alarm" "dr_users_table_throttles" {
  provider            = aws.dr
  alarm_name          = "${var.project_name}-users-throttles-${var.environment}-dr"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UserErrors"
  namespace           = "AWS/DynamoDB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors DynamoDB throttling in DR region"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = aws_dynamodb_table.users_replica.name
  }
}

# Output DR table information
output "dynamodb_dr_users_table_name" {
  description = "Name of the DR Users DynamoDB table"
  value       = aws_dynamodb_table.users_replica.name
}

output "dynamodb_dr_threads_table_name" {
  description = "Name of the DR Threads DynamoDB table"
  value       = aws_dynamodb_table.threads_replica.name
}

output "dynamodb_dr_posts_table_name" {
  description = "Name of the DR Posts DynamoDB table"
  value       = aws_dynamodb_table.posts_replica.name
}

output "global_tables_enabled" {
  description = "Whether Global Tables are enabled"
  value       = var.enable_global_tables
}
