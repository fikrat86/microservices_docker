# Setup Terraform S3 Backend
# This script creates the S3 bucket and DynamoDB table for Terraform state management

param(
    [Parameter(Mandatory=$false)]
    [string]$BucketName = "forum-microservices-terraform-state-dev",
    
    [Parameter(Mandatory=$false)]
    [string]$TableName = "forum-microservices-terraform-locks",
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  Terraform Backend Setup" -ForegroundColor Green
Write-Host "================================================================`n" -ForegroundColor Cyan

# Create S3 Bucket for State
Write-Host " [1/4] Creating S3 Bucket..." -ForegroundColor Yellow
$bucketExists = aws s3 ls "s3://$BucketName" 2>$null
if ($bucketExists) {
    Write-Host "   ✓ Bucket already exists: $BucketName" -ForegroundColor Green
} else {
    aws s3 mb "s3://$BucketName" --region $Region 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Created bucket: $BucketName" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Failed to create bucket" -ForegroundColor Red
        exit 1
    }
}

# Enable Versioning
Write-Host "`n [2/4] Enabling Versioning..." -ForegroundColor Yellow
aws s3api put-bucket-versioning --bucket $BucketName --versioning-configuration Status=Enabled --region $Region 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Enabled versioning" -ForegroundColor Green
} else {
    Write-Host "   ✗ Failed to enable versioning" -ForegroundColor Red
}

# Enable Encryption
Write-Host "`n [3/4] Enabling Encryption..." -ForegroundColor Yellow
$encryptionConfig = @"
{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}
"@
$encryptionConfig | Out-File -FilePath "$env:TEMP\encryption.json" -Encoding UTF8
aws s3api put-bucket-encryption --bucket $BucketName --server-side-encryption-configuration file://$env:TEMP\encryption.json --region $Region 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✓ Enabled encryption" -ForegroundColor Green
} else {
    Write-Host "   ✗ Failed to enable encryption" -ForegroundColor Red
}
Remove-Item "$env:TEMP\encryption.json" -Force

# Create DynamoDB Table for State Locking
Write-Host "`n [4/4] Creating DynamoDB Table..." -ForegroundColor Yellow
$tableExists = aws dynamodb describe-table --table-name $TableName --region $Region 2>$null
if ($tableExists) {
    Write-Host "   ✓ Table already exists: $TableName" -ForegroundColor Green
} else {
    aws dynamodb create-table `
        --table-name $TableName `
        --attribute-definitions AttributeName=LockID,AttributeType=S `
        --key-schema AttributeName=LockID,KeyType=HASH `
        --billing-mode PAY_PER_REQUEST `
        --region $Region 2>$null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ Created table: $TableName" -ForegroundColor Green
    } else {
        Write-Host "   ✗ Failed to create table" -ForegroundColor Red
    }
}

Write-Host "`n================================================================" -ForegroundColor Cyan
Write-Host "  Backend Setup Complete!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "`n Next Steps:" -ForegroundColor Yellow
Write-Host "   1. cd terraform" -ForegroundColor White
Write-Host "   2. terraform init -reconfigure" -ForegroundColor White
Write-Host "   3. This will migrate state to S3" -ForegroundColor Gray
Write-Host ""
