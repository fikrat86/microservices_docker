# Terraform Backend Configuration
# This file configures S3 backend for storing Terraform state remotely
# This makes it easy to track and destroy resources

# The S3 bucket and DynamoDB table are automatically created by GitHub Actions workflow
# If running locally, first run: .\scripts\setup-terraform-backend.ps1

terraform {
  backend "s3" {
    bucket         = "forum-microservices-terraform-state-dev"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "forum-microservices-terraform-locks"
  }
}
