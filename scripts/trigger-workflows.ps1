# Trigger GitHub Actions Workflows
# Usage: .\trigger-workflows.ps1 -Workflow <infrastructure|microservices|both>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("infrastructure", "microservices", "both")]
    [string]$Workflow,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("plan", "apply", "destroy")]
    [string]$TerraformAction = "apply",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$ErrorActionPreference = "Stop"

# Configuration
$RepoOwner = "fikrat86"
$RepoName = "microservices_docker"
$Branch = "main"

# Check if GitHub token is available
if (-not $GitHubToken) {
    Write-Host "❌ GitHub token not found!" -ForegroundColor Red
    Write-Host "Please set GITHUB_TOKEN environment variable or pass it as parameter" -ForegroundColor Yellow
    Write-Host "Example: `$env:GITHUB_TOKEN = 'your_token_here'" -ForegroundColor Cyan
    exit 1
}

# Function to trigger workflow
function Trigger-GitHubWorkflow {
    param(
        [string]$WorkflowFile,
        [hashtable]$Inputs = @{}
    )
    
    $apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/actions/workflows/$WorkflowFile/dispatches"
    
    $body = @{
        ref = $Branch
        inputs = $Inputs
    } | ConvertTo-Json
    
    $headers = @{
        "Authorization" = "Bearer $GitHubToken"
        "Accept" = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    
    try {
        Write-Host "🚀 Triggering workflow: $WorkflowFile" -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $body -ContentType "application/json"
        Write-Host "✅ Workflow triggered successfully!" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "❌ Failed to trigger workflow: $_" -ForegroundColor Red
        Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Yellow
        return $false
    }
}

# Function to check workflow status
function Get-WorkflowRuns {
    param([string]$WorkflowFile)
    
    $apiUrl = "https://api.github.com/repos/$RepoOwner/$RepoName/actions/workflows/$WorkflowFile/runs?per_page=1"
    
    $headers = @{
        "Authorization" = "Bearer $GitHubToken"
        "Accept" = "application/vnd.github+json"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $apiUrl -Method Get -Headers $headers
        return $response.workflow_runs[0]
    } catch {
        Write-Host "⚠️  Could not fetch workflow status" -ForegroundColor Yellow
        return $null
    }
}

# Function to wait for workflow completion
function Wait-ForWorkflow {
    param(
        [string]$WorkflowName,
        [string]$WorkflowFile,
        [int]$TimeoutMinutes = 30
    )
    
    Write-Host "`n⏳ Waiting for '$WorkflowName' to complete..." -ForegroundColor Yellow
    Write-Host "Check status at: https://github.com/$RepoOwner/$RepoName/actions" -ForegroundColor Cyan
    
    $startTime = Get-Date
    $timeout = $startTime.AddMinutes($TimeoutMinutes)
    
    while ((Get-Date) -lt $timeout) {
        Start-Sleep -Seconds 30
        
        $run = Get-WorkflowRuns -WorkflowFile $WorkflowFile
        
        if ($run) {
            $status = $run.status
            $conclusion = $run.conclusion
            
            Write-Host "Status: $status" -ForegroundColor Cyan
            
            if ($status -eq "completed") {
                if ($conclusion -eq "success") {
                    Write-Host "✅ Workflow completed successfully!" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "❌ Workflow failed with conclusion: $conclusion" -ForegroundColor Red
                    Write-Host "View logs: $($run.html_url)" -ForegroundColor Yellow
                    return $false
                }
            }
        }
    }
    
    Write-Host "⏱️  Timeout reached after $TimeoutMinutes minutes" -ForegroundColor Yellow
    return $false
}

# Main execution
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "GitHub Actions Workflow Trigger Script" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

switch ($Workflow) {
    "infrastructure" {
        Write-Host "📋 Triggering Infrastructure Deployment..." -ForegroundColor Green
        Write-Host "Terraform Action: $TerraformAction" -ForegroundColor Yellow
        Write-Host ""
        
        $inputs = @{
            action = $TerraformAction
        }
        
        $success = Trigger-GitHubWorkflow -WorkflowFile "infrastructure.yml" -Inputs $inputs
        
        if ($success) {
            Write-Host ""
            Write-Host "🔗 Monitor progress at:" -ForegroundColor Cyan
            Write-Host "https://github.com/$RepoOwner/$RepoName/actions/workflows/infrastructure.yml" -ForegroundColor Blue
        }
    }
    
    "microservices" {
        Write-Host "📋 Triggering Microservices CI/CD..." -ForegroundColor Green
        Write-Host ""
        
        $success = Trigger-GitHubWorkflow -WorkflowFile "microservices.yml"
        
        if ($success) {
            Write-Host ""
            Write-Host "🔗 Monitor progress at:" -ForegroundColor Cyan
            Write-Host "https://github.com/$RepoOwner/$RepoName/actions/workflows/microservices.yml" -ForegroundColor Blue
        }
    }
    
    "both" {
        Write-Host "📋 Triggering Infrastructure Deployment first..." -ForegroundColor Green
        Write-Host "Terraform Action: $TerraformAction" -ForegroundColor Yellow
        Write-Host ""
        
        # Trigger infrastructure
        $inputs = @{
            action = $TerraformAction
        }
        
        $infraSuccess = Trigger-GitHubWorkflow -WorkflowFile "infrastructure.yml" -Inputs $inputs
        
        if (-not $infraSuccess) {
            Write-Host "❌ Failed to trigger infrastructure workflow. Aborting." -ForegroundColor Red
            exit 1
        }
        
        # Wait for infrastructure to complete
        Write-Host ""
        $infraCompleted = Wait-ForWorkflow -WorkflowName "Infrastructure Deployment" -WorkflowFile "infrastructure.yml" -TimeoutMinutes 25
        
        if (-not $infraCompleted) {
            Write-Host "❌ Infrastructure deployment did not complete successfully. Aborting microservices deployment." -ForegroundColor Red
            exit 1
        }
        
        # Trigger microservices
        Write-Host ""
        Write-Host "=" * 60 -ForegroundColor Cyan
        Write-Host "📋 Now triggering Microservices CI/CD..." -ForegroundColor Green
        Write-Host ""
        
        Start-Sleep -Seconds 5  # Brief pause
        
        $microSuccess = Trigger-GitHubWorkflow -WorkflowFile "microservices.yml"
        
        if ($microSuccess) {
            Write-Host ""
            Write-Host "🔗 Monitor microservices progress at:" -ForegroundColor Cyan
            Write-Host "https://github.com/$RepoOwner/$RepoName/actions/workflows/microservices.yml" -ForegroundColor Blue
            
            Write-Host ""
            Write-Host "⏳ Waiting for microservices deployment..." -ForegroundColor Yellow
            $microCompleted = Wait-ForWorkflow -WorkflowName "Microservices CI/CD" -WorkflowFile "microservices.yml" -TimeoutMinutes 15
            
            if ($microCompleted) {
                Write-Host ""
                Write-Host "🎉 Complete deployment successful!" -ForegroundColor Green
                Write-Host "✅ Infrastructure deployed" -ForegroundColor Green
                Write-Host "✅ Microservices deployed" -ForegroundColor Green
            }
        }
    }
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Done!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
