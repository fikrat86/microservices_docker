# DynamoDB Migration and Management Script
# Handles data migration from JSON files to DynamoDB and table operations

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('migrate', 'backup', 'restore', 'verify', 'seed')]
    [string]$Action,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupFile = "dynamodb-backup.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }

# Get Terraform outputs
function Get-TerraformOutput {
    param([string]$OutputName)
    
    Push-Location "$PSScriptRoot\..\terraform"
    try {
        $output = terraform output -raw $OutputName 2>$null
        return $output
    } catch {
        Write-Warning "Could not get Terraform output: $OutputName"
        return $null
    } finally {
        Pop-Location
    }
}

# Get table names from Terraform
$UsersTable = Get-TerraformOutput "dynamodb_users_table_name"
$ThreadsTable = Get-TerraformOutput "dynamodb_threads_table_name"
$PostsTable = Get-TerraformOutput "dynamodb_posts_table_name"

if (-not $UsersTable) {
    Write-Error "Could not retrieve DynamoDB table names from Terraform outputs"
    Write-Info "Please ensure Terraform has been applied successfully"
    exit 1
}

Write-Info "Using DynamoDB tables:"
Write-Host "  - Users: $UsersTable"
Write-Host "  - Threads: $ThreadsTable"
Write-Host "  - Posts: $PostsTable"
Write-Host ""

# Migrate data from db.json to DynamoDB
function Invoke-Migration {
    Write-Info "Starting migration from db.json to DynamoDB..."
    
    # Check if Node.js migration script exists
    $migrationScript = Join-Path $PSScriptRoot "migrate-to-dynamodb.js"
    if (-not (Test-Path $migrationScript)) {
        Write-Error "Migration script not found: $migrationScript"
        exit 1
    }
    
    # Set environment variables
    $env:AWS_REGION = $Region
    $env:DYNAMODB_USERS_TABLE = $UsersTable
    $env:DYNAMODB_THREADS_TABLE = $ThreadsTable
    $env:DYNAMODB_POSTS_TABLE = $PostsTable
    
    if ($DryRun) {
        Write-Warning "DRY RUN: Would execute migration script"
        return
    }
    
    # Install dependencies if needed
    $packageJson = Join-Path $PSScriptRoot "package.json"
    if (-not (Test-Path (Join-Path $PSScriptRoot "node_modules"))) {
        Write-Info "Installing Node.js dependencies..."
        Push-Location $PSScriptRoot
        npm install --silent
        Pop-Location
    }
    
    # Run migration
    Write-Info "Executing migration..."
    node $migrationScript
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Migration completed successfully!"
    } else {
        Write-Error "Migration failed with exit code $LASTEXITCODE"
        exit 1
    }
}

# Backup DynamoDB tables to JSON
function Invoke-Backup {
    Write-Info "Backing up DynamoDB tables to $BackupFile..."
    
    $backup = @{
        timestamp = (Get-Date).ToString("o")
        region = $Region
        tables = @{}
    }
    
    $tables = @(
        @{ Name = $UsersTable; Key = "users" },
        @{ Name = $ThreadsTable; Key = "threads" },
        @{ Name = $PostsTable; Key = "posts" }
    )
    
    foreach ($table in $tables) {
        Write-Info "Backing up $($table.Name)..."
        
        if ($DryRun) {
            Write-Warning "DRY RUN: Would scan table $($table.Name)"
            continue
        }
        
        $items = aws dynamodb scan `
            --table-name $table.Name `
            --region $Region `
            --output json | ConvertFrom-Json
        
        $backup.tables[$table.Key] = $items.Items
        Write-Success "Backed up $($items.Count) items from $($table.Key)"
    }
    
    if (-not $DryRun) {
        $backup | ConvertTo-Json -Depth 10 | Out-File $BackupFile
        Write-Success "Backup saved to $BackupFile"
    }
}

# Restore DynamoDB tables from JSON backup
function Invoke-Restore {
    Write-Info "Restoring DynamoDB tables from $BackupFile..."
    
    if (-not (Test-Path $BackupFile)) {
        Write-Error "Backup file not found: $BackupFile"
        exit 1
    }
    
    $backup = Get-Content $BackupFile | ConvertFrom-Json
    
    Write-Warning "This will overwrite existing data in DynamoDB tables!"
    if (-not $DryRun) {
        $confirm = Read-Host "Type 'yes' to confirm"
        if ($confirm -ne 'yes') {
            Write-Info "Restore cancelled"
            return
        }
    }
    
    $tables = @(
        @{ Name = $UsersTable; Key = "users" },
        @{ Name = $ThreadsTable; Key = "threads" },
        @{ Name = $PostsTable; Key = "posts" }
    )
    
    foreach ($table in $tables) {
        $items = $backup.tables.$($table.Key)
        Write-Info "Restoring $($items.Count) items to $($table.Name)..."
        
        if ($DryRun) {
            Write-Warning "DRY RUN: Would restore $($items.Count) items"
            continue
        }
        
        # Batch write items (max 25 per request)
        $batchSize = 25
        for ($i = 0; $i -lt $items.Count; $i += $batchSize) {
            $batch = $items[$i..[Math]::Min($i + $batchSize - 1, $items.Count - 1)]
            
            $putRequests = $batch | ForEach-Object {
                @{ PutRequest = @{ Item = $_ } }
            }
            
            $requestItems = @{
                $table.Name = $putRequests
            }
            
            $json = @{ RequestItems = $requestItems } | ConvertTo-Json -Depth 10
            $json | aws dynamodb batch-write-item --cli-input-json - --region $Region
        }
        
        Write-Success "Restored $($items.Count) items to $($table.Key)"
    }
}

# Verify DynamoDB tables
function Invoke-Verification {
    Write-Info "Verifying DynamoDB tables..."
    
    $tables = @(
        @{ Name = $UsersTable; Label = "Users" },
        @{ Name = $ThreadsTable; Label = "Threads" },
        @{ Name = $PostsTable; Label = "Posts" }
    )
    
    foreach ($table in $tables) {
        Write-Info "Checking $($table.Label) table..."
        
        # Check table exists
        $tableInfo = aws dynamodb describe-table `
            --table-name $table.Name `
            --region $Region `
            --output json 2>$null | ConvertFrom-Json
        
        if ($tableInfo) {
            $status = $tableInfo.Table.TableStatus
            $itemCount = $tableInfo.Table.ItemCount
            
            Write-Host "  Status: $status" -ForegroundColor $(if ($status -eq 'ACTIVE') { 'Green' } else { 'Yellow' })
            Write-Host "  Items: $itemCount"
            Write-Host "  Size: $([math]::Round($tableInfo.Table.TableSizeBytes / 1KB, 2)) KB"
            
            # Check point-in-time recovery
            $pitr = aws dynamodb describe-continuous-backups `
                --table-name $table.Name `
                --region $Region `
                --output json | ConvertFrom-Json
            
            $pitrStatus = $pitr.ContinuousBackupsDescription.PointInTimeRecoveryDescription.PointInTimeRecoveryStatus
            Write-Host "  PITR: $pitrStatus" -ForegroundColor $(if ($pitrStatus -eq 'ENABLED') { 'Green' } else { 'Red' })
            
            Write-Success "$($table.Label) table verified"
        } else {
            Write-Error "$($table.Label) table not found!"
        }
        Write-Host ""
    }
}

# Seed DynamoDB with sample data
function Invoke-Seed {
    Write-Info "Seeding DynamoDB with sample data..."
    
    if ($DryRun) {
        Write-Warning "DRY RUN: Would seed tables with sample data"
        return
    }
    
    # Sample users
    $users = @(
        @{ userId = "1"; email = "alice@example.com"; name = "Alice Smith"; createdAt = (Get-Date).ToString("o") },
        @{ userId = "2"; email = "bob@example.com"; name = "Bob Johnson"; createdAt = (Get-Date).ToString("o") },
        @{ userId = "3"; email = "carol@example.com"; name = "Carol Williams"; createdAt = (Get-Date).ToString("o") }
    )
    
    foreach ($user in $users) {
        $json = $user | ConvertTo-Json
        Write-Host "Adding user: $($user.name)"
        echo $json | aws dynamodb put-item `
            --table-name $UsersTable `
            --item (ConvertTo-Json @{ Item = $user } -Depth 5) `
            --region $Region
    }
    Write-Success "Seeded $($users.Count) users"
    
    # Sample threads
    $threads = @(
        @{ threadId = "1"; title = "Welcome to the Forum"; description = "Introduce yourself here"; createdAt = (Get-Date).ToString("o") },
        @{ threadId = "2"; title = "General Discussion"; description = "Talk about anything"; createdAt = (Get-Date).ToString("o") }
    )
    
    foreach ($thread in $threads) {
        Write-Host "Adding thread: $($thread.title)"
        $json = @{ Item = $thread } | ConvertTo-Json -Depth 5
        echo $json | aws dynamodb put-item `
            --table-name $ThreadsTable `
            --cli-input-json - `
            --region $Region
    }
    Write-Success "Seeded $($threads.Count) threads"
    
    # Sample posts
    $posts = @(
        @{ postId = "1"; threadId = "1"; userId = "1"; title = "Hello!"; content = "First post!"; createdAt = (Get-Date).ToString("o") },
        @{ postId = "2"; threadId = "1"; userId = "2"; title = "Hi there"; content = "Welcome everyone"; createdAt = (Get-Date).ToString("o") }
    )
    
    foreach ($post in $posts) {
        Write-Host "Adding post: $($post.title)"
        $json = @{ Item = $post } | ConvertTo-Json -Depth 5
        echo $json | aws dynamodb put-item `
            --table-name $PostsTable `
            --cli-input-json - `
            --region $Region
    }
    Write-Success "Seeded $($posts.Count) posts"
}

# Main execution
Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   DynamoDB Migration & Management      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

switch ($Action) {
    'migrate' { Invoke-Migration }
    'backup' { Invoke-Backup }
    'restore' { Invoke-Restore }
    'verify' { Invoke-Verification }
    'seed' { Invoke-Seed }
}

Write-Success "Operation completed!"
