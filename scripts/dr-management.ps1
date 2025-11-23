# Backup and DR Management Script
# This script manages database backups and disaster recovery operations

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('backup', 'restore', 'test-dr', 'failover', 'sync')]
    [string]$Action = 'backup',
    
    [Parameter(Mandatory=$false)]
    [string]$BackupName = "backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')",
    
    [Parameter(Mandatory=$false)]
    [string]$RestoreFrom = "",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

# Configuration
$PROJECT_NAME = "forum-microservices"
$ENVIRONMENT = "dev"
$BACKUP_BUCKET = "$PROJECT_NAME-db-backups-$ENVIRONMENT"
$DR_REGION = "us-west-2"

# Colors for output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Backup database files
function Backup-DatabaseFiles {
    Write-ColorOutput "`n=== Starting Database Backup ===" "Cyan"
    
    # Create backup directory
    $backupDir = "backups\$BackupName"
    New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
    
    # Backup all db.json files
    Write-ColorOutput "Backing up database files..." "Yellow"
    Copy-Item "posts\db.json" "$backupDir\posts-db.json"
    Copy-Item "threads\db.json" "$backupDir\threads-db.json"
    Copy-Item "users\db.json" "$backupDir\users-db.json"
    
    # Create manifest file
    $manifest = @{
        timestamp = Get-Date -Format 'o'
        version = "1.0"
        services = @{
            posts = @{ file = "posts-db.json"; size = (Get-Item "$backupDir\posts-db.json").Length }
            threads = @{ file = "threads-db.json"; size = (Get-Item "$backupDir\threads-db.json").Length }
            users = @{ file = "users-db.json"; size = (Get-Item "$backupDir\users-db.json").Length }
        }
    } | ConvertTo-Json -Depth 10
    
    $manifest | Out-File "$backupDir\manifest.json"
    
    # Upload to S3
    Write-ColorOutput "Uploading backup to S3..." "Yellow"
    try {
        aws s3 sync $backupDir "s3://$BACKUP_BUCKET/$BackupName/" --region $Region
        Write-ColorOutput "✓ Backup completed successfully: $BackupName" "Green"
        
        # Replicate to DR region (if enabled)
        Write-ColorOutput "Replicating to DR region..." "Yellow"
        aws s3 sync $backupDir "s3://$BACKUP_BUCKET-dr/$BackupName/" --region $DR_REGION
        Write-ColorOutput "✓ DR replication completed" "Green"
    }
    catch {
        Write-ColorOutput "✗ Backup failed: $_" "Red"
        exit 1
    }
}

# Restore database files
function Restore-DatabaseFiles {
    Write-ColorOutput "`n=== Starting Database Restore ===" "Cyan"
    
    if ([string]::IsNullOrEmpty($RestoreFrom)) {
        Write-ColorOutput "✗ Please specify backup name with -RestoreFrom parameter" "Red"
        exit 1
    }
    
    # Download from S3
    $restoreDir = "backups\restore-$RestoreFrom"
    Write-ColorOutput "Downloading backup from S3..." "Yellow"
    
    try {
        aws s3 sync "s3://$BACKUP_BUCKET/$RestoreFrom/" $restoreDir --region $Region
        
        # Verify manifest
        if (Test-Path "$restoreDir\manifest.json") {
            $manifest = Get-Content "$restoreDir\manifest.json" | ConvertFrom-Json
            Write-ColorOutput "Backup timestamp: $($manifest.timestamp)" "Gray"
            
            # Restore files
            Write-ColorOutput "Restoring database files..." "Yellow"
            Copy-Item "$restoreDir\posts-db.json" "posts\db.json" -Force
            Copy-Item "$restoreDir\threads-db.json" "threads\db.json" -Force
            Copy-Item "$restoreDir\users-db.json" "users\db.json" -Force
            
            Write-ColorOutput "✓ Restore completed successfully" "Green"
        }
        else {
            Write-ColorOutput "✗ Invalid backup: manifest.json not found" "Red"
            exit 1
        }
    }
    catch {
        Write-ColorOutput "✗ Restore failed: $_" "Red"
        exit 1
    }
}

# Test DR site
function Test-DRSite {
    Write-ColorOutput "`n=== Testing DR Site ===" "Cyan"
    
    try {
        # Get DR ALB DNS name
        $drAlb = terraform output -raw dr_alb_dns_name
        
        Write-ColorOutput "DR ALB: $drAlb" "Gray"
        Write-ColorOutput "`nTesting DR endpoints..." "Yellow"
        
        # Test each service
        $services = @("posts", "threads", "users")
        $allHealthy = $true
        
        foreach ($service in $services) {
            $endpoint = "http://$drAlb/api/$service/health"
            try {
                $response = Invoke-WebRequest -Uri $endpoint -TimeoutSec 10
                if ($response.StatusCode -eq 200) {
                    Write-ColorOutput "✓ $service service is healthy" "Green"
                }
                else {
                    Write-ColorOutput "✗ $service service returned status $($response.StatusCode)" "Red"
                    $allHealthy = $false
                }
            }
            catch {
                Write-ColorOutput "✗ $service service is not responding" "Red"
                $allHealthy = $false
            }
        }
        
        if ($allHealthy) {
            Write-ColorOutput "`n✓ All DR services are healthy" "Green"
        }
        else {
            Write-ColorOutput "`n✗ Some DR services are not healthy" "Red"
        }
    }
    catch {
        Write-ColorOutput "✗ DR test failed: $_" "Red"
        exit 1
    }
}

# Perform failover to DR
function Start-Failover {
    Write-ColorOutput "`n=== Starting Failover to DR Region ===" "Cyan"
    
    Write-ColorOutput "WARNING: This will redirect traffic to the DR region" "Yellow"
    $confirm = Read-Host "Are you sure you want to continue? (yes/no)"
    
    if ($confirm -ne "yes") {
        Write-ColorOutput "Failover cancelled" "Gray"
        return
    }
    
    try {
        # Scale up DR services
        Write-ColorOutput "Scaling up DR services..." "Yellow"
        
        $services = @("posts", "threads", "users")
        foreach ($service in $services) {
            aws ecs update-service `
                --cluster "$PROJECT_NAME-cluster-$ENVIRONMENT-dr" `
                --service "$PROJECT_NAME-$service-service-$ENVIRONMENT-dr" `
                --desired-count 2 `
                --region $DR_REGION
        }
        
        Write-ColorOutput "Waiting for DR services to stabilize..." "Yellow"
        Start-Sleep -Seconds 30
        
        # Test DR site
        Test-DRSite
        
        Write-ColorOutput "`n✓ Failover initiated. Update DNS to point to DR ALB:" "Green"
        Write-ColorOutput "  DR ALB DNS: $(terraform output -raw dr_alb_dns_name)" "Cyan"
    }
    catch {
        Write-ColorOutput "✗ Failover failed: $_" "Red"
        exit 1
    }
}

# Sync images to DR region
function Sync-ImagesToDR {
    Write-ColorOutput "`n=== Syncing Container Images to DR Region ===" "Cyan"
    
    $services = @("posts", "threads", "users")
    $accountId = (aws sts get-caller-identity --query Account --output text)
    
    foreach ($service in $services) {
        Write-ColorOutput "`nSyncing $service images..." "Yellow"
        
        # Primary repository
        $primaryRepo = "$accountId.dkr.ecr.$Region.amazonaws.com/$PROJECT_NAME/$service-$ENVIRONMENT"
        
        # DR repository
        $drRepo = "$accountId.dkr.ecr.$DR_REGION.amazonaws.com/$PROJECT_NAME/$service-$ENVIRONMENT"
        
        # Login to both ECR registries
        aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "$accountId.dkr.ecr.$Region.amazonaws.com"
        aws ecr get-login-password --region $DR_REGION | docker login --username AWS --password-stdin "$accountId.dkr.ecr.$DR_REGION.amazonaws.com"
        
        # Pull from primary
        docker pull "$primaryRepo:latest"
        
        # Tag for DR
        docker tag "$primaryRepo:latest" "$drRepo:latest"
        
        # Push to DR
        docker push "$drRepo:latest"
        
        Write-ColorOutput "✓ $service image synced to DR" "Green"
    }
    
    Write-ColorOutput "`n✓ All images synced to DR region" "Green"
}

# Main execution
Write-ColorOutput "`n╔════════════════════════════════════════════════╗" "Cyan"
Write-ColorOutput "║  Disaster Recovery Management Script          ║" "Cyan"
Write-ColorOutput "╚════════════════════════════════════════════════╝" "Cyan"

switch ($Action) {
    'backup' {
        Backup-DatabaseFiles
    }
    'restore' {
        Restore-DatabaseFiles
    }
    'test-dr' {
        Test-DRSite
    }
    'failover' {
        Start-Failover
    }
    'sync' {
        Sync-ImagesToDR
    }
    default {
        Write-ColorOutput "Unknown action: $Action" "Red"
        exit 1
    }
}

Write-ColorOutput "`n=== Operation Completed ===" "Cyan"
