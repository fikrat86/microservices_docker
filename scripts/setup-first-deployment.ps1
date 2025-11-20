#!/usr/bin/env pwsh
# First-Time Deployment Script
# This script helps you complete the pre-deployment configuration

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = 'us-east-1'
)

$ErrorActionPreference = "Stop"

Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║     Forum Microservices - First-Time Deployment Setup       ║
╚══════════════════════════════════════════════════════════════╝

This script will help you complete the pre-deployment configuration:
1. Verify AWS credentials
2. Create ECR repositories via Terraform
3. Build and push Docker images
4. Prepare for GitHub Actions setup

"@ -ForegroundColor Cyan

# Step 1: Verify AWS Credentials
Write-Host "`n[Step 1/5] Verifying AWS Credentials..." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

try {
    $accountId = (aws sts get-caller-identity --query Account --output text)
    $currentRegion = (aws configure get region)
    
    Write-Host "✓ AWS Account ID: $accountId" -ForegroundColor Green
    Write-Host "✓ Current Region: $currentRegion" -ForegroundColor Green
    
    if ($currentRegion -ne $Region) {
        Write-Host "⚠️  Warning: Current region ($currentRegion) differs from target region ($Region)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ Failed to verify AWS credentials" -ForegroundColor Red
    Write-Host "  Please run: aws configure" -ForegroundColor Yellow
    exit 1
}

# Step 2: Check Terraform Configuration
Write-Host "`n[Step 2/5] Checking Terraform Configuration..." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

if (Test-Path "terraform/terraform.tfvars") {
    Write-Host "✓ Found terraform.tfvars" -ForegroundColor Green
    
    # Display current configuration
    Write-Host "`nCurrent Configuration:" -ForegroundColor Cyan
    Get-Content "terraform/terraform.tfvars" | Select-String -Pattern "^[^#]" | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
} else {
    Write-Host "⚠️  terraform.tfvars not found. Creating from example..." -ForegroundColor Yellow
    Copy-Item "terraform/terraform.tfvars.example" "terraform/terraform.tfvars"
    Write-Host "✓ Created terraform.tfvars" -ForegroundColor Green
    Write-Host "  Please review and update: terraform/terraform.tfvars" -ForegroundColor Yellow
}

# Step 3: Deploy ECR Repositories First
Write-Host "`n[Step 3/5] Deploying ECR Repositories..." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$response = Read-Host "`nDeploy ECR repositories now? This creates only the Docker registries. [Y/n]"
if ($response -eq '' -or $response -eq 'Y' -or $response -eq 'y') {
    try {
        Set-Location terraform
        
        Write-Host "Initializing Terraform..." -ForegroundColor Cyan
        terraform init
        
        Write-Host "`nCreating ECR repositories..." -ForegroundColor Cyan
        terraform apply `
            -target=aws_ecr_repository.posts `
            -target=aws_ecr_repository.threads `
            -target=aws_ecr_repository.users `
            -auto-approve
        
        Write-Host "`n✓ ECR repositories created successfully!" -ForegroundColor Green
        
        # Get repository URLs
        Write-Host "`nRepository URLs:" -ForegroundColor Cyan
        $postsRepo = terraform output -raw ecr_posts_repository_url
        $threadsRepo = terraform output -raw ecr_threads_repository_url
        $usersRepo = terraform output -raw ecr_users_repository_url
        
        Write-Host "  Posts:   $postsRepo" -ForegroundColor Gray
        Write-Host "  Threads: $threadsRepo" -ForegroundColor Gray
        Write-Host "  Users:   $usersRepo" -ForegroundColor Gray
        
        Set-Location ..
    } catch {
        Write-Host "✗ Failed to create ECR repositories" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Set-Location ..
        exit 1
    }
} else {
    Write-Host "Skipping ECR repository creation." -ForegroundColor Yellow
}

# Step 4: Build and Push Docker Images
Write-Host "`n[Step 4/5] Building and Pushing Docker Images..." -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

$response = Read-Host "`nBuild and push Docker images to ECR? [Y/n]"
if ($response -eq '' -or $response -eq 'Y' -or $response -eq 'y') {
    try {
        Write-Host "`nRunning build-and-push script..." -ForegroundColor Cyan
        & ".\scripts\build-and-push.ps1" -Service all -Region $Region
        
        Write-Host "`n✓ All Docker images built and pushed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "✗ Failed to build/push Docker images" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host "`nYou can manually run: .\scripts\build-and-push.ps1 -Service all" -ForegroundColor Yellow
    }
} else {
    Write-Host "Skipping Docker image build." -ForegroundColor Yellow
}

# Step 5: GitHub Actions Setup
Write-Host "`n[Step 5/5] GitHub Actions Configuration" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Yellow

Write-Host @"

To complete GitHub Actions setup, you need to:

1. Create IAM User for GitHub Actions
   ────────────────────────────────────
   Run these commands:
   
   aws iam create-user --user-name github-actions-deployer
   
   aws iam attach-user-policy \
     --user-name github-actions-deployer \
     --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess
   
   aws iam attach-user-policy \
     --user-name github-actions-deployer \
     --policy-arn arn:aws:iam::aws:policy/AmazonECS_FullAccess
   
   aws iam create-access-key --user-name github-actions-deployer


2. Add GitHub Secrets
   ────────────────────
   Go to: https://github.com/fikrat86/microservices_docker/settings/secrets/actions
   
   Add these secrets:
   • AWS_ACCESS_KEY_ID         (from step 1)
   • AWS_SECRET_ACCESS_KEY     (from step 1)


3. Verify Workflow Files
   ────────────────────────
   Check that .github/workflows/ contains:
   ✓ complete-pipeline.yml
   ✓ terraform-deploy.yml
   ✓ deploy-posts.yml
   ✓ deploy-threads.yml
   ✓ deploy-users.yml


4. Deploy Full Infrastructure
   ──────────────────────────
   Option A - Via Terraform locally:
     cd terraform
     terraform plan
     terraform apply
   
   Option B - Via GitHub Actions:
     • Push code to GitHub
     • Go to Actions tab
     • Run "Complete Deployment Pipeline"
     • Enable "Deploy Terraform infrastructure"


5. Test Deployment
   ───────────────
   After infrastructure is deployed:
     cd terraform
     `$albUrl = terraform output -raw alb_url
     .\scripts\test-services.ps1 -AlbUrl `$albUrl

"@ -ForegroundColor Cyan

# Summary
Write-Host @"

╔══════════════════════════════════════════════════════════════╗
║                    Setup Summary                             ║
╚══════════════════════════════════════════════════════════════╝

Completed Steps:
"@ -ForegroundColor Green

Write-Host "✓ AWS credentials verified (Account: $accountId)" -ForegroundColor Green
Write-Host "✓ Terraform configuration checked" -ForegroundColor Green

if ($response -eq '' -or $response -eq 'Y' -or $response -eq 'y') {
    Write-Host "✓ ECR repositories created" -ForegroundColor Green
    Write-Host "✓ Docker images built and pushed" -ForegroundColor Green
}

Write-Host @"

Next Steps:
"@ -ForegroundColor Yellow

Write-Host "1. Follow GitHub Actions setup instructions above" -ForegroundColor Yellow
Write-Host "2. Deploy full infrastructure (Terraform or GitHub Actions)" -ForegroundColor Yellow
Write-Host "3. Test the deployment" -ForegroundColor Yellow

Write-Host @"

Documentation:
"@ -ForegroundColor Cyan

Write-Host "• Pre-deployment checklist:  DEPLOYMENT_CHECKLIST.md" -ForegroundColor Cyan
Write-Host "• GitHub Actions setup:      GITHUB_ACTIONS_SETUP.md" -ForegroundColor Cyan
Write-Host "• Workflow documentation:    .github/workflows/README.md" -ForegroundColor Cyan
Write-Host "• Quick start guide:         docs/QUICKSTART.md" -ForegroundColor Cyan

Write-Host "`n✨ Pre-deployment configuration complete! ✨`n" -ForegroundColor Green
