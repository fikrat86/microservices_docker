#!/usr/bin/env pwsh
# Script to build and push Docker images to ECR
# This script is used for initial deployment before CI/CD pipeline is active

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('posts', 'threads', 'users', 'all')]
    [string]$Service = 'all',
    
    [Parameter(Mandatory=$false)]
    [string]$Region = 'us-east-1',
    
    [Parameter(Mandatory=$false)]
    [string]$Tag = 'latest'
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Docker Build and Push Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get AWS Account ID
Write-Host "Getting AWS Account ID..." -ForegroundColor Yellow
try {
    $accountId = (aws sts get-caller-identity --query Account --output text)
    Write-Host "✓ AWS Account ID: $accountId" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to get AWS Account ID. Make sure AWS CLI is configured." -ForegroundColor Red
    exit 1
}

# Login to ECR
Write-Host ""
Write-Host "Logging in to Amazon ECR..." -ForegroundColor Yellow
try {
    aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "$accountId.dkr.ecr.$Region.amazonaws.com"
    Write-Host "✓ Successfully logged in to ECR" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to login to ECR" -ForegroundColor Red
    exit 1
}

# Function to build and push a service
function Build-And-Push-Service {
    param(
        [string]$ServiceName
    )
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Building $ServiceName service..." -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $repoName = "forum-microservices/$ServiceName"
    $repoUri = "$accountId.dkr.ecr.$Region.amazonaws.com/$repoName"
    
    # Check if repository exists, create if it doesn't
    Write-Host "Checking if ECR repository exists..." -ForegroundColor Yellow
    try {
        $checkRepo = aws ecr describe-repositories --repository-names $repoName --region $Region 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Repository exists" -ForegroundColor Green
        } else {
            throw "Repository not found"
        }
    } catch {
        Write-Host "Repository does not exist. Creating..." -ForegroundColor Yellow
        try {
            aws ecr create-repository `
                --repository-name $repoName `
                --region $Region `
                --image-scanning-configuration scanOnPush=true `
                --encryption-configuration encryptionType=AES256 | Out-Null
            Write-Host "✓ Repository created" -ForegroundColor Green
        } catch {
            Write-Host "✗ Failed to create repository. It may already exist or you need permissions." -ForegroundColor Red
            Write-Host "Note: If using Terraform, deploy infrastructure first with: .\scripts\deploy.ps1 -Action apply" -ForegroundColor Yellow
            exit 1
        }
    }
    
    # Build Docker image
    Write-Host ""
    Write-Host "Building Docker image for $ServiceName..." -ForegroundColor Yellow
    Set-Location (Join-Path $PSScriptRoot ".." $ServiceName)
    docker build -t "${repoName}:$Tag" .
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Docker image built successfully" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker build failed" -ForegroundColor Red
        exit 1
    }
    
    # Tag image
    Write-Host "Tagging image..." -ForegroundColor Yellow
    docker tag "${repoName}:$Tag" "${repoUri}:$Tag"
    docker tag "${repoName}:$Tag" "${repoUri}:$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    # Push to ECR
    Write-Host "Pushing image to ECR..." -ForegroundColor Yellow
    docker push "${repoUri}:$Tag"
    docker push "${repoUri}:$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Image pushed successfully to $repoUri" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker push failed" -ForegroundColor Red
        exit 1
    }
}

# Build and push services
Set-Location (Join-Path $PSScriptRoot "..")

if ($Service -eq 'all') {
    Build-And-Push-Service -ServiceName 'posts'
    Build-And-Push-Service -ServiceName 'threads'
    Build-And-Push-Service -ServiceName 'users'
} else {
    Build-And-Push-Service -ServiceName $Service
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "All images built and pushed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Deploy infrastructure with: .\scripts\deploy.ps1 -Action apply" -ForegroundColor Cyan
Write-Host "2. Update ECS services to use the new images" -ForegroundColor Cyan
Write-Host "3. Set up CodeCommit repositories and push code for CI/CD" -ForegroundColor Cyan
