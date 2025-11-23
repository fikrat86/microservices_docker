# Cleanup Script for Duplicate AWS Resources
# This script deletes all resources created by the forum-microservices project

param(
    [string]$Region = "us-east-1",
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Continue"

Write-Host "=== AWS Resource Cleanup for forum-microservices ===" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "DRY RUN MODE - No resources will be deleted" -ForegroundColor Green
}
Write-Host ""

# VPC IDs to clean up
$vpcs = @("vpc-064530cfd2848734c", "vpc-0a9ada02ecc1aa91d", "vpc-021cb0a8a5c20d9af", "vpc-0a7be6dde2c5772c9")

foreach ($vpcId in $vpcs) {
    Write-Host "Processing VPC: $vpcId" -ForegroundColor Cyan
    
    # 1. Delete ECS Services (must be done first)
    Write-Host "  Deleting ECS Services..." -ForegroundColor Yellow
    $ecsServices = aws ecs list-services --cluster forum-microservices-cluster --region $Region --query 'serviceArns' --output json | ConvertFrom-Json
    if ($ecsServices) {
        foreach ($serviceArn in $ecsServices) {
            $serviceName = $serviceArn.Split('/')[-1]
            Write-Host "    Deleting ECS service: $serviceName" -ForegroundColor Gray
            if (-not $DryRun) {
                aws ecs update-service --cluster forum-microservices-cluster --service $serviceName --desired-count 0 --region $Region 2>$null
                aws ecs delete-service --cluster forum-microservices-cluster --service $serviceName --force --region $Region 2>$null
            }
        }
    }
    
    # 2. Delete Load Balancers
    Write-Host "  Deleting Load Balancers..." -ForegroundColor Yellow
    $lbs = aws elbv2 describe-load-balancers --region $Region --query "LoadBalancers[?VpcId=='$vpcId'].LoadBalancerArn" --output json | ConvertFrom-Json
    foreach ($lbArn in $lbs) {
        Write-Host "    Deleting ALB: $lbArn" -ForegroundColor Gray
        if (-not $DryRun) {
            aws elbv2 delete-load-balancer --load-balancer-arn $lbArn --region $Region 2>$null
        }
    }
    
    # Wait for ALBs to be deleted
    if (-not $DryRun -and $lbs.Count -gt 0) {
        Write-Host "    Waiting for ALBs to be deleted..." -ForegroundColor Gray
        Start-Sleep -Seconds 30
    }
    
    # 3. Delete Target Groups
    Write-Host "  Deleting Target Groups..." -ForegroundColor Yellow
    $tgs = aws elbv2 describe-target-groups --region $Region --query "TargetGroups[?VpcId=='$vpcId'].TargetGroupArn" --output json | ConvertFrom-Json
    foreach ($tgArn in $tgs) {
        Write-Host "    Deleting Target Group: $tgArn" -ForegroundColor Gray
        if (-not $DryRun) {
            aws elbv2 delete-target-group --target-group-arn $tgArn --region $Region 2>$null
        }
    }
    
    # 4. Delete NAT Gateways
    Write-Host "  Deleting NAT Gateways..." -ForegroundColor Yellow
    $natGateways = aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$vpcId" "Name=state,Values=available" --region $Region --query 'NatGateways[*].NatGatewayId' --output json | ConvertFrom-Json
    foreach ($natId in $natGateways) {
        Write-Host "    Deleting NAT Gateway: $natId" -ForegroundColor Gray
        if (-not $DryRun) {
            aws ec2 delete-nat-gateway --nat-gateway-id $natId --region $Region 2>$null
        }
    }
    
    # Wait for NAT Gateways to be deleted
    if (-not $DryRun -and $natGateways.Count -gt 0) {
        Write-Host "    Waiting for NAT Gateways to be deleted..." -ForegroundColor Gray
        Start-Sleep -Seconds 60
    }
    
    # 5. Release Elastic IPs
    Write-Host "  Releasing Elastic IPs..." -ForegroundColor Yellow
    $eips = aws ec2 describe-addresses --region $Region --filters "Name=domain,Values=vpc" --query "Addresses[?contains(Tags[?Key=='Name'].Value, 'forum-microservices')].AllocationId" --output json | ConvertFrom-Json
    foreach ($eipId in $eips) {
        Write-Host "    Releasing EIP: $eipId" -ForegroundColor Gray
        if (-not $DryRun) {
            aws ec2 release-address --allocation-id $eipId --region $Region 2>$null
        }
    }
    
    # 6. Delete Network Interfaces
    Write-Host "  Deleting Network Interfaces..." -ForegroundColor Yellow
    $enis = aws ec2 describe-network-interfaces --filters "Name=vpc-id,Values=$vpcId" --region $Region --query 'NetworkInterfaces[*].NetworkInterfaceId' --output json | ConvertFrom-Json
    foreach ($eniId in $enis) {
        Write-Host "    Deleting ENI: $eniId" -ForegroundColor Gray
        if (-not $DryRun) {
            aws ec2 delete-network-interface --network-interface-id $eniId --region $Region 2>$null
        }
    }
    
    # 7. Delete Security Groups (except default)
    Write-Host "  Deleting Security Groups..." -ForegroundColor Yellow
    $sgs = aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpcId" --region $Region --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output json | ConvertFrom-Json
    foreach ($sgId in $sgs) {
        Write-Host "    Deleting Security Group: $sgId" -ForegroundColor Gray
        if (-not $DryRun) {
            aws ec2 delete-security-group --group-id $sgId --region $Region 2>$null
        }
    }
    
    # 8. Delete Subnets
    Write-Host "  Deleting Subnets..." -ForegroundColor Yellow
    $subnets = aws ec2 describe-subnets --filters "Name=vpc-id,Values=$vpcId" --region $Region --query 'Subnets[*].SubnetId' --output json | ConvertFrom-Json
    foreach ($subnetId in $subnets) {
        Write-Host "    Deleting Subnet: $subnetId" -ForegroundColor Gray
        if (-not $DryRun) {
            aws ec2 delete-subnet --subnet-id $subnetId --region $Region 2>$null
        }
    }
    
    # 9. Delete Route Tables (except main)
    Write-Host "  Deleting Route Tables..." -ForegroundColor Yellow
    $routeTables = aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$vpcId" --region $Region --query 'RouteTables[?Associations[0].Main==`false`].RouteTableId' --output json | ConvertFrom-Json
    foreach ($rtId in $routeTables) {
        Write-Host "    Deleting Route Table: $rtId" -ForegroundColor Gray
        if (-not $DryRun) {
            aws ec2 delete-route-table --route-table-id $rtId --region $Region 2>$null
        }
    }
    
    # 10. Detach and Delete Internet Gateways
    Write-Host "  Deleting Internet Gateways..." -ForegroundColor Yellow
    $igws = aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$vpcId" --region $Region --query 'InternetGateways[*].InternetGatewayId' --output json | ConvertFrom-Json
    foreach ($igwId in $igws) {
        Write-Host "    Detaching and deleting IGW: $igwId" -ForegroundColor Gray
        if (-not $DryRun) {
            aws ec2 detach-internet-gateway --internet-gateway-id $igwId --vpc-id $vpcId --region $Region 2>$null
            aws ec2 delete-internet-gateway --internet-gateway-id $igwId --region $Region 2>$null
        }
    }
    
    # 11. Delete VPC
    Write-Host "  Deleting VPC: $vpcId" -ForegroundColor Yellow
    if (-not $DryRun) {
        aws ec2 delete-vpc --vpc-id $vpcId --region $Region 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "    VPC deleted successfully!" -ForegroundColor Green
        } else {
            Write-Host "    Failed to delete VPC (may have dependencies)" -ForegroundColor Red
        }
    }
    
    Write-Host ""
}

# Delete ECS Cluster
Write-Host "Deleting ECS Cluster..." -ForegroundColor Yellow
if (-not $DryRun) {
    aws ecs delete-cluster --cluster forum-microservices-cluster --region $Region 2>$null
}

# Delete CloudWatch Log Groups
Write-Host "Deleting CloudWatch Log Groups..." -ForegroundColor Yellow
$logGroups = aws logs describe-log-groups --log-group-name-prefix "/ecs/forum-microservices" --region $Region --query 'logGroups[*].logGroupName' --output json | ConvertFrom-Json
foreach ($logGroup in $logGroups) {
    Write-Host "  Deleting log group: $logGroup" -ForegroundColor Gray
    if (-not $DryRun) {
        aws logs delete-log-group --log-group-name $logGroup --region $Region 2>$null
    }
}

Write-Host ""
Write-Host "=== Cleanup Complete ===" -ForegroundColor Green
if ($DryRun) {
    Write-Host "This was a DRY RUN. Run without -DryRun to actually delete resources." -ForegroundColor Yellow
}
