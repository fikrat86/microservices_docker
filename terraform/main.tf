# Terraform Configuration for Forum Microservices on AWS ECS Fargate
# This file defines the required providers and backend configuration

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment to use S3 backend for remote state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "forum-microservices/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
    }
  }
}

# DR Provider - Uncomment and set enable_dr=true to enable disaster recovery
# Uses us-east-2 (Ohio) for geographic diversity from us-east-1 (Virginia)
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "${var.environment}-dr"
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
      DRRegion    = "true"
    }
  }
}
