# Cleanup Orphaned AWS Resources
# This script deletes AWS resources that were created but are not in Terraform state

param(
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1",
    
    [Parameter(Mandatory=$false)]
    [string]$VpcId = "vpc-0bd03b448a499ab09",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false
)

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  AWS Orphaned Resources Cleanup" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host " DRY RUN MODE - No resources will be deleted`n" -ForegroundColor Yellow
}

Write-Host " Target Region: $Region" -ForegroundColor White
Write-Host " Target VPC: $VpcId`n" -ForegroundColor White

# Function to execute AWS CLI command
function Invoke-AwsCommand {
    param(
        [string]$Command,
        [string]$Description
    )
    
    Write-Host " → $Description..." -ForegroundColor Cyan -NoNewline
    
    if ($DryRun) {
        Write-Host " [SKIPPED - DRY RUN]" -ForegroundColor Yellow
        return $null
    }
    
    try {
        $result = Invoke-Expression $Command 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host " ✓" -ForegroundColor Green
            return $result
        } else {
            Write-Host " ✗ (Exit code: $LASTEXITCODE)" -ForegroundColor Red
            Write-Host "   Error: $result" -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host " ✗ Failed" -ForegroundColor Red
        Write-Host "   Error: $_" -ForegroundColor Red
        return $null
    }
}

Write-Host " Step 1: Gathering VPC Resources..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# Get VPC details
$vpcDetails = aws ec2 describe-vpcs --region $Region --vpc-ids $VpcId --output json 2>&1 | ConvertFrom-Json

if (-not $vpcDetails.Vpcs) {
    Write-Host " ✓ VPC not found - already deleted or does not exist" -ForegroundColor Green
    exit 0
}

Write-Host " Found VPC: $($vpcDetails.Vpcs[0].VpcId)" -ForegroundColor White
Write-Host " CIDR: $($vpcDetails.Vpcs[0].CidrBlock)" -ForegroundColor Gray
Write-Host " Tags: $($vpcDetails.Vpcs[0].Tags | ConvertTo-Json -Compress)" -ForegroundColor Gray

Write-Host "`n Step 2: Deleting VPC Resources..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan

# 1. Delete NAT Gateways
Write-Host " [1/11] NAT Gateways" -ForegroundColor Cyan
$natGateways = aws ec2 describe-nat-gateways --region $Region --filter "Name=vpc-id,Values=$VpcId" --output json | ConvertFrom-Json
foreach ($nat in $natGateways.NatGateways) {
    if ($nat.State -ne "deleted") {
        Invoke-AwsCommand -Command "aws ec2 delete-nat-gateway --region $Region --nat-gateway-id $($nat.NatGatewayId)" `
                         -Description "Deleting NAT Gateway $($nat.NatGatewayId)"
    }
}

# 2. Delete ECS Services (if any)
Write-Host "`n [2/11] ECS Services" -ForegroundColor Cyan
$ecsClusters = aws ecs list-clusters --region $Region --output json | ConvertFrom-Json
foreach ($clusterArn in $ecsClusters.clusterArns) {
    $services = aws ecs list-services --region $Region --cluster $clusterArn --output json | ConvertFrom-Json
    foreach ($serviceArn in $services.serviceArns) {
        Invoke-AwsCommand -Command "aws ecs update-service --region $Region --cluster $clusterArn --service $serviceArn --desired-count 0" `
                         -Description "Scaling down service $serviceArn"
        Invoke-AwsCommand -Command "aws ecs delete-service --region $Region --cluster $clusterArn --service $serviceArn --force" `
                         -Description "Deleting service $serviceArn"
    }
}

# 3. Delete Load Balancers
Write-Host "`n [3/11] Load Balancers" -ForegroundColor Cyan
$albs = aws elbv2 describe-load-balancers --region $Region --output json | ConvertFrom-Json
foreach ($alb in $albs.LoadBalancers) {
    if ($alb.VpcId -eq $VpcId) {
        Invoke-AwsCommand -Command "aws elbv2 delete-load-balancer --region $Region --load-balancer-arn $($alb.LoadBalancerArn)" `
                         -Description "Deleting ALB $($alb.LoadBalancerName)"
    }
}

Start-Sleep -Seconds 5

# 4. Delete Target Groups
Write-Host "`n [4/11] Target Groups" -ForegroundColor Cyan
$targetGroups = aws elbv2 describe-target-groups --region $Region --output json | ConvertFrom-Json
foreach ($tg in $targetGroups.TargetGroups) {
    if ($tg.VpcId -eq $VpcId) {
        Invoke-AwsCommand -Command "aws elbv2 delete-target-group --region $Region --target-group-arn $($tg.TargetGroupArn)" `
                         -Description "Deleting Target Group $($tg.TargetGroupName)"
    }
}

# 5. Delete Network Interfaces (ENIs)
Write-Host "`n [5/11] Network Interfaces" -ForegroundColor Cyan
$enis = aws ec2 describe-network-interfaces --region $Region --filters "Name=vpc-id,Values=$VpcId" --output json | ConvertFrom-Json
foreach ($eni in $enis.NetworkInterfaces) {
    if ($eni.Attachment) {
        Invoke-AwsCommand -Command "aws ec2 detach-network-interface --region $Region --attachment-id $($eni.Attachment.AttachmentId)" `
                         -Description "Detaching ENI $($eni.NetworkInterfaceId)"
        Start-Sleep -Seconds 2
    }
    Invoke-AwsCommand -Command "aws ec2 delete-network-interface --region $Region --network-interface-id $($eni.NetworkInterfaceId)" `
                     -Description "Deleting ENI $($eni.NetworkInterfaceId)"
}

# Wait for NAT Gateways to be deleted
Write-Host "`n Waiting for NAT Gateways to be deleted (this may take 2-3 minutes)..." -ForegroundColor Yellow
if (-not $DryRun) {
    $maxWait = 180
    $waited = 0
    while ($waited -lt $maxWait) {
        $remainingNats = aws ec2 describe-nat-gateways --region $Region --filter "Name=vpc-id,Values=$VpcId" --output json | ConvertFrom-Json
        $activeNats = $remainingNats.NatGateways | Where-Object { $_.State -ne "deleted" }
        if ($activeNats.Count -eq 0) {
            Write-Host " ✓ All NAT Gateways deleted" -ForegroundColor Green
            break
        }
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep -Seconds 10
        $waited += 10
    }
    Write-Host ""
}

# 6. Release Elastic IPs
Write-Host "`n [6/11] Elastic IPs" -ForegroundColor Cyan
$eips = aws ec2 describe-addresses --region $Region --output json | ConvertFrom-Json
foreach ($eip in $eips.Addresses) {
    if ($eip.NetworkInterfaceId -or $eip.InstanceId) {
        # Skip if still attached
        continue
    }
    Invoke-AwsCommand -Command "aws ec2 release-address --region $Region --allocation-id $($eip.AllocationId)" `
                     -Description "Releasing EIP $($eip.PublicIp)"
}

# 7. Delete Subnets
Write-Host "`n [7/11] Subnets" -ForegroundColor Cyan
$subnets = aws ec2 describe-subnets --region $Region --filters "Name=vpc-id,Values=$VpcId" --output json | ConvertFrom-Json
foreach ($subnet in $subnets.Subnets) {
    Invoke-AwsCommand -Command "aws ec2 delete-subnet --region $Region --subnet-id $($subnet.SubnetId)" `
                     -Description "Deleting Subnet $($subnet.SubnetId)"
}

# 8. Delete Route Tables
Write-Host "`n [8/11] Route Tables" -ForegroundColor Cyan
$routeTables = aws ec2 describe-route-tables --region $Region --filters "Name=vpc-id,Values=$VpcId" --output json | ConvertFrom-Json
foreach ($rt in $routeTables.RouteTables) {
    # Skip main route table
    $isMain = $rt.Associations | Where-Object { $_.Main -eq $true }
    if ($isMain) {
        continue
    }
    
    # Disassociate first
    foreach ($assoc in $rt.Associations) {
        if (-not $assoc.Main) {
            Invoke-AwsCommand -Command "aws ec2 disassociate-route-table --region $Region --association-id $($assoc.RouteTableAssociationId)" `
                             -Description "Disassociating Route Table $($rt.RouteTableId)"
        }
    }
    
    Invoke-AwsCommand -Command "aws ec2 delete-route-table --region $Region --route-table-id $($rt.RouteTableId)" `
                     -Description "Deleting Route Table $($rt.RouteTableId)"
}

# 9. Delete Internet Gateways
Write-Host "`n [9/11] Internet Gateways" -ForegroundColor Cyan
$igws = aws ec2 describe-internet-gateways --region $Region --filters "Name=attachment.vpc-id,Values=$VpcId" --output json | ConvertFrom-Json
foreach ($igw in $igws.InternetGateways) {
    Invoke-AwsCommand -Command "aws ec2 detach-internet-gateway --region $Region --internet-gateway-id $($igw.InternetGatewayId) --vpc-id $VpcId" `
                     -Description "Detaching IGW $($igw.InternetGatewayId)"
    Invoke-AwsCommand -Command "aws ec2 delete-internet-gateway --region $Region --internet-gateway-id $($igw.InternetGatewayId)" `
                     -Description "Deleting IGW $($igw.InternetGatewayId)"
}

# 10. Delete Security Groups
Write-Host "`n [10/11] Security Groups" -ForegroundColor Cyan
$securityGroups = aws ec2 describe-security-groups --region $Region --filters "Name=vpc-id,Values=$VpcId" --output json | ConvertFrom-Json
foreach ($sg in $securityGroups.SecurityGroups) {
    if ($sg.GroupName -eq "default") {
        continue
    }
    Invoke-AwsCommand -Command "aws ec2 delete-security-group --region $Region --group-id $($sg.GroupId)" `
                     -Description "Deleting Security Group $($sg.GroupName)"
}

# 11. Finally, delete the VPC
Write-Host "`n [11/11] VPC" -ForegroundColor Cyan
Invoke-AwsCommand -Command "aws ec2 delete-vpc --region $Region --vpc-id $VpcId" `
                 -Description "Deleting VPC $VpcId"

Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  DRY RUN COMPLETE - No resources were deleted" -ForegroundColor Yellow
} else {
    Write-Host "  CLEANUP COMPLETE!" -ForegroundColor Green
}
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━`n" -ForegroundColor Cyan
