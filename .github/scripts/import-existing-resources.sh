#!/bin/bash
# Import existing AWS resources into Terraform state
# This script imports resources that already exist from previous deployments

set -e

ENVIRONMENT="dev"
PROJECT_NAME="forum-microservices"
PRIMARY_REGION="us-east-1"
DR_REGION="us-west-2"

echo "=== Importing Existing Resources into Terraform State ==="

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Account ID: ${ACCOUNT_ID}"
echo "Working directory: $(pwd)"

# Change to terraform directory if not already there
if [ ! -f "main.tf" ]; then
  if [ -d "terraform" ]; then
    cd terraform
    echo "Changed to terraform directory"
  else
    echo "Error: Cannot find terraform directory or main.tf"
    exit 1
  fi
fi

# Function to safely import a resource
import_resource() {
  local resource_address=$1
  local resource_id=$2
  
  echo "Importing: $resource_address"
  if terraform state show "$resource_address" &>/dev/null; then
    echo "  ✓ Already in state, skipping"
  else
    if terraform import "$resource_address" "$resource_id" 2>/dev/null; then
      echo "  ✓ Imported successfully"
    else
      echo "  ⚠ Import failed or resource doesn't exist (this is OK)"
    fi
  fi
}

echo ""
echo "=== Importing IAM Roles ==="
import_resource "aws_iam_role.ecs_task_execution_role" "${PROJECT_NAME}-ecs-task-execution-role-${ENVIRONMENT}"
import_resource "aws_iam_role.ecs_task_role" "${PROJECT_NAME}-ecs-task-role-${ENVIRONMENT}"
import_resource "aws_iam_role.dr_ecs_task_execution_role" "${PROJECT_NAME}-ecs-task-execution-role-${ENVIRONMENT}-dr"
import_resource "aws_iam_role.dr_ecs_task_role" "${PROJECT_NAME}-ecs-task-role-${ENVIRONMENT}-dr"
import_resource "aws_iam_role.backup_role" "${PROJECT_NAME}-backup-role-${ENVIRONMENT}"
import_resource "aws_iam_role.replication[0]" "${PROJECT_NAME}-s3-replication-role-${ENVIRONMENT}"

echo ""
echo "=== Importing CloudWatch Log Groups ==="
import_resource "aws_cloudwatch_log_group.ecs" "/ecs/${PROJECT_NAME}-${ENVIRONMENT}"
import_resource "aws_cloudwatch_log_group.dr_ecs" "/ecs/${PROJECT_NAME}-${ENVIRONMENT}-dr"

echo ""
echo "=== Importing DynamoDB Tables ==="
import_resource "aws_dynamodb_table.users" "${PROJECT_NAME}-users-${ENVIRONMENT}"
import_resource "aws_dynamodb_table.threads" "${PROJECT_NAME}-threads-${ENVIRONMENT}"
import_resource "aws_dynamodb_table.posts" "${PROJECT_NAME}-posts-${ENVIRONMENT}"

# Note: Global table replicas use the same table names
import_resource "aws_dynamodb_table.users_replica" "${PROJECT_NAME}-users-${ENVIRONMENT}"
import_resource "aws_dynamodb_table.threads_replica" "${PROJECT_NAME}-threads-${ENVIRONMENT}"
import_resource "aws_dynamodb_table.posts_replica" "${PROJECT_NAME}-posts-${ENVIRONMENT}"

echo ""
echo "=== Importing Backup Vaults ==="
import_resource "aws_backup_vault.dynamodb_backup" "${PROJECT_NAME}-dynamodb-backup-${ENVIRONMENT}"
import_resource "aws_backup_vault.dr_dynamodb_backup" "${PROJECT_NAME}-dynamodb-backup-${ENVIRONMENT}-dr"

echo ""
echo "=== Importing S3 Buckets ==="
import_resource "aws_s3_bucket.backup" "${PROJECT_NAME}-db-backups-${ENVIRONMENT}-${ACCOUNT_ID}"
import_resource "aws_s3_bucket.dr_backup" "${PROJECT_NAME}-db-backups-${ENVIRONMENT}-dr-${ACCOUNT_ID}"

echo ""
echo "=== Import Complete ==="
echo "Run 'terraform plan' to verify the state matches your resources"
