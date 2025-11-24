#!/bin/bash
# Setup Terraform S3 Backend
# This script creates the S3 bucket and DynamoDB table needed for Terraform state management

set -e

BUCKET_NAME="forum-microservices-terraform-state-dev"
TABLE_NAME="forum-microservices-terraform-locks"
REGION="us-east-1"

echo "=== Setting up Terraform Backend ==="

# Check if S3 bucket exists
if ! aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
  echo "Creating S3 bucket for Terraform state..."
  aws s3api create-bucket \
    --bucket "${BUCKET_NAME}" \
    --region "${REGION}"
  
  # Enable versioning
  echo "Enabling versioning on S3 bucket..."
  aws s3api put-bucket-versioning \
    --bucket "${BUCKET_NAME}" \
    --versioning-configuration Status=Enabled
  
  # Enable encryption
  echo "Enabling encryption on S3 bucket..."
  aws s3api put-bucket-encryption \
    --bucket "${BUCKET_NAME}" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }]
    }'
  
  # Block public access
  echo "Blocking public access to S3 bucket..."
  aws s3api put-public-access-block \
    --bucket "${BUCKET_NAME}" \
    --public-access-block-configuration \
      "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
  
  echo "✓ S3 bucket created successfully: ${BUCKET_NAME}"
else
  echo "✓ S3 bucket already exists: ${BUCKET_NAME}"
fi

# Check if DynamoDB table exists
if ! aws dynamodb describe-table --table-name "${TABLE_NAME}" --region "${REGION}" 2>/dev/null; then
  echo "Creating DynamoDB table for state locking..."
  aws dynamodb create-table \
    --table-name "${TABLE_NAME}" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "${REGION}"
  
  echo "Waiting for DynamoDB table to be active..."
  aws dynamodb wait table-exists --table-name "${TABLE_NAME}" --region "${REGION}"
  echo "✓ DynamoDB table created successfully: ${TABLE_NAME}"
else
  echo "✓ DynamoDB table already exists: ${TABLE_NAME}"
fi

echo ""
echo "=== Terraform Backend Setup Complete ==="
echo "S3 Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${TABLE_NAME}"
echo "Region: ${REGION}"
