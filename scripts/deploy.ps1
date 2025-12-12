#!/usr/bin/env pwsh
# Deployment Script for Forum Microservices Infrastructure
# This script deploys the complete infrastructure using Terraform

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('plan', 'apply', 'destroy', 'output')]
    [string]$Action = 'plan',
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = 'dev',
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoApprove
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Forum Microservices Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to terraform directory
$terraformDir = Join-Path $PSScriptRoot "terraform"
Set-Location $terraformDir

Write-Host "Current directory: $terraformDir" -ForegroundColor Yellow
Write-Host "Action: $Action" -ForegroundColor Yellow
Write-Host "Environment: $Environment" -ForegroundColor Yellow
Write-Host ""

# Check if Terraform is installed
try {
    $tfVersion = terraform version
    Write-Host "✓ Terraform is installed" -ForegroundColor Green
    Write-Host $tfVersion[0] -ForegroundColor Gray
} catch {
    Write-Host "✗ Terraform is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Terraform from https://www.terraform.io/downloads" -ForegroundColor Red
    exit 1
}

# Check if AWS CLI is installed
try {
    $awsVersion = aws --version
    Write-Host "✓ AWS CLI is installed" -ForegroundColor Green
    Write-Host $awsVersion -ForegroundColor Gray
} catch {
    Write-Host "✗ AWS CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install AWS CLI from https://aws.amazon.com/cli/" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Execute Terraform commands
switch ($Action) {
    'plan' {
        Write-Host "Running Terraform init..." -ForegroundColor Cyan
        terraform init
        
        Write-Host ""
        Write-Host "Running Terraform plan..." -ForegroundColor Cyan
        terraform plan -var="environment=$Environment" -out=tfplan
        
        Write-Host ""
        Write-Host "Plan saved to tfplan file" -ForegroundColor Green
        Write-Host "Review the plan above. To apply, run: .\deploy.ps1 -Action apply" -ForegroundColor Yellow
    }
    
    'apply' {
        Write-Host "Running Terraform init..." -ForegroundColor Cyan
        terraform init
        
        Write-Host ""
        if ($AutoApprove) {
            Write-Host "Running Terraform apply with auto-approve..." -ForegroundColor Cyan
            terraform apply -var="environment=$Environment" -auto-approve
        } else {
            Write-Host "Running Terraform apply..." -ForegroundColor Cyan
            terraform apply -var="environment=$Environment"
        }
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Deployment Complete!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "Run the following command to see outputs:" -ForegroundColor Yellow
        Write-Host ".\deploy.ps1 -Action output" -ForegroundColor Cyan
    }
    
    'destroy' {
        Write-Host "WARNING: This will destroy all infrastructure!" -ForegroundColor Red
        Write-Host ""
        Write-Host "For comprehensive destruction instructions, see DESTROY_GUIDE.md" -ForegroundColor Cyan
        Write-Host "Or use the dedicated script: .\terraform-destroy-all.ps1" -ForegroundColor Cyan
        Write-Host ""
        
        if ($AutoApprove) {
            terraform destroy -var="environment=$Environment" -auto-approve
        } else {
            terraform destroy -var="environment=$Environment"
        }
        
        Write-Host ""
        Write-Host "Infrastructure destroyed" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Note: Some resources may require manual cleanup:" -ForegroundColor Yellow
        Write-Host "  - S3 state bucket: forum-microservices-terraform-state-$Environment" -ForegroundColor Gray
        Write-Host "  - DynamoDB lock table: forum-microservices-terraform-locks" -ForegroundColor Gray
        Write-Host "  - CloudWatch log groups" -ForegroundColor Gray
        Write-Host "  - ECR repositories (if not force-deleted)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "See DESTROY_GUIDE.md for post-destruction cleanup steps" -ForegroundColor Cyan
    }
    
    'output' {
        Write-Host "Terraform Outputs:" -ForegroundColor Cyan
        Write-Host ""
        terraform output
        
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Quick Access URLs" -ForegroundColor Cyan
        Write-Host "========================================" -ForegroundColor Cyan
        
        $albUrl = terraform output -raw alb_url 2>$null
        if ($albUrl) {
            Write-Host ""
            Write-Host "Application Load Balancer:" -ForegroundColor Yellow
            Write-Host $albUrl -ForegroundColor Green
            Write-Host ""
            Write-Host "Service Endpoints:" -ForegroundColor Yellow
            Write-Host "  Posts:   $albUrl/api/posts" -ForegroundColor Green
            Write-Host "  Threads: $albUrl/api/threads" -ForegroundColor Green
            Write-Host "  Users:   $albUrl/api/users" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Script completed successfully" -ForegroundColor Green
