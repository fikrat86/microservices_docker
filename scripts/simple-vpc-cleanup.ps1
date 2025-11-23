# Simple VPC Cleanup Script
# Deletes a specific VPC and all its dependencies

param(
    [Parameter(Mandatory=$true)]
    [string]$VpcId,
    
    [Parameter(Mandatory=$false)]
    [string]$Region = "us-east-1"
)

Write-Host "`nCleaning up VPC: $VpcId in region $Region`n" -ForegroundColor Cyan

# Step 1: Delete NAT Gateways
Write-Host "Step 1: Deleting NAT Gateways..." -ForegroundColor Yellow
$natGws = aws ec2 describe-nat-gateways --region $Region --filter "Name=vpc-id,Values=$VpcId" --query "NatGateways[?State!='deleted'].NatGatewayId" --output text
if ($natGws) {
    foreach ($nat in $natGws -split "`t") {
        Write-Host "  Deleting NAT Gateway: $nat"
        aws ec2 delete-nat-gateway --region $Region --nat-gateway-id $nat
    }
    Write-Host "  Waiting for NAT Gateways to delete (90 seconds)..." -ForegroundColor Gray
    Start-Sleep -Seconds 90
} else {
    Write-Host "  No NAT Gateways found" -ForegroundColor Gray
}

# Step 2: Release Elastic IPs
Write-Host "`nStep 2: Releasing Elastic IPs..." -ForegroundColor Yellow
$eips = aws ec2 describe-addresses --region $Region --query "Addresses[?AssociationId==null].AllocationId" --output text
if ($eips) {
    foreach ($eip in $eips -split "`t") {
        Write-Host "  Releasing EIP: $eip"
        aws ec2 release-address --region $Region --allocation-id $eip 2>$null
    }
} else {
    Write-Host "  No unassociated Elastic IPs found" -ForegroundColor Gray
}

# Step 3: Delete Network Interfaces
Write-Host "`nStep 3: Deleting Network Interfaces..." -ForegroundColor Yellow
$enis = aws ec2 describe-network-interfaces --region $Region --filters "Name=vpc-id,Values=$VpcId" --query "NetworkInterfaces[].NetworkInterfaceId" --output text
if ($enis) {
    foreach ($eni in $enis -split "`t") {
        Write-Host "  Deleting ENI: $eni"
        aws ec2 delete-network-interface --region $Region --network-interface-id $eni 2>$null
    }
} else {
    Write-Host "  No ENIs found" -ForegroundColor Gray
}

# Step 4: Delete Subnets
Write-Host "`nStep 4: Deleting Subnets..." -ForegroundColor Yellow
$subnets = aws ec2 describe-subnets --region $Region --filters "Name=vpc-id,Values=$VpcId" --query "Subnets[].SubnetId" --output text
if ($subnets) {
    foreach ($subnet in $subnets -split "`t") {
        Write-Host "  Deleting Subnet: $subnet"
        aws ec2 delete-subnet --region $Region --subnet-id $subnet 2>$null
    }
} else {
    Write-Host "  No Subnets found" -ForegroundColor Gray
}

# Step 5: Delete Route Tables
Write-Host "`nStep 5: Deleting Route Tables..." -ForegroundColor Yellow
$rts = aws ec2 describe-route-tables --region $Region --filters "Name=vpc-id,Values=$VpcId" --query "RouteTables[?Associations[0].Main==``false``].RouteTableId" --output text
if ($rts) {
    foreach ($rt in $rts -split "`t") {
        Write-Host "  Deleting Route Table: $rt"
        aws ec2 delete-route-table --region $Region --route-table-id $rt 2>$null
    }
} else {
    Write-Host "  No custom Route Tables found" -ForegroundColor Gray
}

# Step 6: Detach and Delete Internet Gateways
Write-Host "`nStep 6: Deleting Internet Gateways..." -ForegroundColor Yellow
$igws = aws ec2 describe-internet-gateways --region $Region --filters "Name=attachment.vpc-id,Values=$VpcId" --query "InternetGateways[].InternetGatewayId" --output text
if ($igws) {
    foreach ($igw in $igws -split "`t") {
        Write-Host "  Detaching IGW: $igw"
        aws ec2 detach-internet-gateway --region $Region --internet-gateway-id $igw --vpc-id $VpcId 2>$null
        Write-Host "  Deleting IGW: $igw"
        aws ec2 delete-internet-gateway --region $Region --internet-gateway-id $igw 2>$null
    }
} else {
    Write-Host "  No Internet Gateways found" -ForegroundColor Gray
}

# Step 7: Delete Security Groups
Write-Host "`nStep 7: Deleting Security Groups..." -ForegroundColor Yellow
$sgs = aws ec2 describe-security-groups --region $Region --filters "Name=vpc-id,Values=$VpcId" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text
if ($sgs) {
    foreach ($sg in $sgs -split "`t") {
        Write-Host "  Deleting Security Group: $sg"
        aws ec2 delete-security-group --region $Region --group-id $sg 2>$null
    }
} else {
    Write-Host "  No custom Security Groups found" -ForegroundColor Gray
}

# Step 8: Delete VPC
Write-Host "`nStep 8: Deleting VPC..." -ForegroundColor Yellow
Write-Host "  Deleting VPC: $VpcId"
aws ec2 delete-vpc --region $Region --vpc-id $VpcId
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ VPC $VpcId successfully deleted!`n" -ForegroundColor Green
} else {
    Write-Host "`n✗ Failed to delete VPC. Manual cleanup may be required.`n" -ForegroundColor Red
    Write-Host "Run this command to see what's left:" -ForegroundColor Yellow
    Write-Host "  aws ec2 describe-vpcs --region $Region --vpc-ids $VpcId`n" -ForegroundColor Gray
}
