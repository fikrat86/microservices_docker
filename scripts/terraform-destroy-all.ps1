#!/usr/bin/env pwsh
# Complete Terraform Destroy Script
# This script destroys all AWS resources created by Terraform

param(
    [Parameter(Mandatory=$false)]
    [string]$Environment = 'dev',
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun,
    
    [Parameter(Mandatory=$false)]
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# Configuration variables (can be overridden via environment variables)
$script:TerraformDir = if ($env:TERRAFORM_DIR) { $env:TERRAFORM_DIR } else { Join-Path $PSScriptRoot "..\terraform" }
$script:StateBucketPrefix = if ($env:STATE_BUCKET_PREFIX) { $env:STATE_BUCKET_PREFIX } else { "forum-microservices-terraform-state" }
$script:LockTableName = if ($env:LOCK_TABLE_NAME) { $env:LOCK_TABLE_NAME } else { "forum-microservices-terraform-locks" }

# Function to print colored messages
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Warning-Message {
    param([string]$Message)
    Write-Host "⚠ $Message" -ForegroundColor Yellow
}

function Write-Error-Message {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Cyan
}

# Function to display usage
function Show-Usage {
    Write-Host @"
Usage: .\terraform-destroy-all.ps1 [OPTIONS]

Destroy all AWS resources created by Terraform

OPTIONS:
    -Environment ENV    Environment to destroy (default: dev)
    -AutoApprove        Auto-approve destruction without confirmation
    -DryRun            Show what would be destroyed without actually destroying
    -Help              Display this help message

EXAMPLES:
    # Dry run to see what would be destroyed
    .\terraform-destroy-all.ps1 -DryRun

    # Destroy with confirmation prompt
    .\terraform-destroy-all.ps1 -Environment dev

    # Destroy without confirmation (use with caution!)
    .\terraform-destroy-all.ps1 -Environment dev -AutoApprove

"@
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if Terraform is installed
    try {
        $tfVersion = terraform version 2>&1 | Select-Object -First 1
        Write-Success "Terraform is installed: $tfVersion"
    } catch {
        Write-Error-Message "Terraform is not installed or not in PATH"
        Write-Info "Please install Terraform from https://www.terraform.io/downloads"
        exit 1
    }
    
    # Check if AWS CLI is installed
    try {
        $awsVersion = aws --version 2>&1
        Write-Success "AWS CLI is installed: $awsVersion"
    } catch {
        Write-Error-Message "AWS CLI is not installed or not in PATH"
        Write-Info "Please install AWS CLI from https://aws.amazon.com/cli/"
        exit 1
    }
    
    # Check AWS credentials
    try {
        $caller = aws sts get-caller-identity 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "AWS credentials are valid"
        } else {
            throw "Invalid credentials"
        }
    } catch {
        Write-Error-Message "AWS credentials are not configured or invalid"
        Write-Info "Please configure AWS credentials using 'aws configure'"
        exit 1
    }
    
    Write-Host ""
}

# Main function
function Main {
    # Show usage if Help parameter is set
    if ($Help) {
        Show-Usage
        exit 0
    }
    
    Write-Header "Terraform Destroy - AWS Resources"
    
    Write-Info "Environment: $Environment"
    Write-Info "Terraform Directory: $script:TerraformDir"
    if ($DryRun) {
        Write-Warning-Message "DRY RUN MODE - No resources will be destroyed"
    }
    Write-Host ""
    
    # Check prerequisites
    Test-Prerequisites
    
    # Change to terraform directory
    if (-not (Test-Path $script:TerraformDir)) {
        Write-Error-Message "Terraform directory not found: $script:TerraformDir"
        exit 1
    }
    
    Push-Location $script:TerraformDir
    
    try {
        # Initialize Terraform
        Write-Info "Initializing Terraform..."
        terraform init
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Terraform initialized successfully"
        } else {
            Write-Error-Message "Failed to initialize Terraform"
            exit 1
        }
        Write-Host ""
        
        # Show what will be destroyed
        Write-Info "Generating destroy plan..."
        terraform plan -destroy -var="environment=$Environment"
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Destroy plan generated successfully"
        } else {
            Write-Error-Message "Failed to generate destroy plan"
            exit 1
        }
        Write-Host ""
        
        # If dry run, exit here
        if ($DryRun) {
            Write-Header "Dry Run Complete"
            Write-Warning-Message "No resources were destroyed. Run without -DryRun to actually destroy resources."
            Pop-Location
            exit 0
        }
        
        # Confirmation prompt (unless auto-approve is set)
        if (-not $AutoApprove) {
            Write-Host ""
            Write-Warning-Message "WARNING: This will destroy ALL infrastructure resources!"
            Write-Warning-Message "This action cannot be undone."
            Write-Host ""
            $confirmation = Read-Host "Are you sure you want to destroy all resources? (type 'yes' to confirm)"
            
            if ($confirmation -ne "yes") {
                Write-Info "Destruction cancelled by user"
                Pop-Location
                exit 0
            }
        }
        
        # Execute destroy
        Write-Host ""
        Write-Header "Destroying AWS Resources"
        
        if ($AutoApprove) {
            Write-Info "Executing terraform destroy with auto-approve..."
            terraform destroy -var="environment=$Environment" -auto-approve
        } else {
            Write-Info "Executing terraform destroy..."
            terraform destroy -var="environment=$Environment"
        }
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Header "Destruction Complete"
            Write-Success "All Terraform-managed resources have been destroyed"
            Write-Host ""
            Write-Info "Note: The following may still exist and require manual cleanup:"
            Write-Host "  - S3 bucket: $script:StateBucketPrefix-$Environment"
            Write-Host "  - DynamoDB table: $script:LockTableName"
            Write-Host "  - ECR repositories (if force delete was not enabled)"
            Write-Host "  - CloudWatch log groups"
            Write-Host ""
            Write-Info "To remove the Terraform state backend, run:"
            Write-Host "  aws s3 rb s3://$script:StateBucketPrefix-$Environment --force"
            Write-Host "  aws dynamodb delete-table --table-name $script:LockTableName"
            Write-Host ""
        } else {
            Write-Error-Message "Terraform destroy failed"
            Pop-Location
            exit 1
        }
        
    } finally {
        Pop-Location
    }
}

# Run main function
Main
