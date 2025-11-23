# Complete AWS Resource Cleanup Script
# Deletes all forum-microservices resources in us-east-1 and us-west-2

param(
    [switch]$DryRun = $false
)

$ErrorActionPreference = "Continue"

Write-Host "`n" -NoNewline
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  AWS Resource Cleanup - Forum Microservices" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "  DRY RUN MODE - No resources will be deleted" -ForegroundColor Yellow
    Write-Host ""
}

$regions = @("us-east-1", "us-west-2")

foreach ($region in $regions) {
    Write-Host "Processing Region: $region" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Gray
    
    # 1. Delete ECR Repositories
    Write-Host " [1] Deleting ECR Repositories..." -ForegroundColor Yellow
    $repos = aws ecr describe-repositories --region $region --output json 2>$null | ConvertFrom-Json
    if ($repos.repositories) {
        foreach ($repo in $repos.repositories) {
            if ($repo.repositoryName -like "forum-microservices/*" -or $repo.repositoryName -like "forum-microservices/*-dev") {
                Write-Host "   - Deleting: $($repo.repositoryName)" -ForegroundColor White
                if (-not $DryRun) {
                    aws ecr delete-repository --region $region --repository-name $repo.repositoryName --force 2>$null
                }
            }
        }
    }
    
    # 2. Delete ECS Services
    Write-Host " [2] Deleting ECS Services..." -ForegroundColor Yellow
    $clusters = aws ecs list-clusters --region $region --output json 2>$null | ConvertFrom-Json
    if ($clusters.clusterArns) {
        foreach ($clusterArn in $clusters.clusterArns) {
            $clusterName = ($clusterArn -split '/')[-1]
            if ($clusterName -like "forum-microservices*") {
                Write-Host "   - Processing Cluster: $clusterName" -ForegroundColor White
                
                $services = aws ecs list-services --region $region --cluster $clusterName --output json 2>$null | ConvertFrom-Json
                if ($services.serviceArns) {
                    foreach ($serviceArn in $services.serviceArns) {
                        $serviceName = ($serviceArn -split '/')[-1]
                        Write-Host "     * Deleting Service: $serviceName" -ForegroundColor Gray
                        if (-not $DryRun) {
                            aws ecs update-service --region $region --cluster $clusterName --service $serviceName --desired-count 0 2>$null | Out-Null
                            aws ecs delete-service --region $region --cluster $clusterName --service $serviceName --force 2>$null | Out-Null
                        }
                    }
                }
            }
        }
    }
    
    Start-Sleep -Seconds 3
    
    # 3. Delete ECS Clusters
    Write-Host " [3] Deleting ECS Clusters..." -ForegroundColor Yellow
    if ($clusters.clusterArns) {
        foreach ($clusterArn in $clusters.clusterArns) {
            $clusterName = ($clusterArn -split '/')[-1]
            if ($clusterName -like "forum-microservices*") {
                Write-Host "   - Deleting: $clusterName" -ForegroundColor White
                if (-not $DryRun) {
                    aws ecs delete-cluster --region $region --cluster $clusterName 2>$null | Out-Null
                }
            }
        }
    }
    
    # 4. Delete Load Balancers
    Write-Host " [4] Deleting Load Balancers..." -ForegroundColor Yellow
    $albs = aws elbv2 describe-load-balancers --region $region --output json 2>$null | ConvertFrom-Json
    if ($albs.LoadBalancers) {
        foreach ($alb in $albs.LoadBalancers) {
            if ($alb.LoadBalancerName -like "forum-microservices*" -or $alb.LoadBalancerName -like "forum-ms*") {
                Write-Host "   - Deleting: $($alb.LoadBalancerName)" -ForegroundColor White
                if (-not $DryRun) {
                    aws elbv2 delete-load-balancer --region $region --load-balancer-arn $alb.LoadBalancerArn 2>$null | Out-Null
                }
            }
        }
    }
    
    Start-Sleep -Seconds 5
    
    # 5. Delete Target Groups
    Write-Host " [5] Deleting Target Groups..." -ForegroundColor Yellow
    $tgs = aws elbv2 describe-target-groups --region $region --output json 2>$null | ConvertFrom-Json
    if ($tgs.TargetGroups) {
        foreach ($tg in $tgs.TargetGroups) {
            if ($tg.TargetGroupName -like "forum-*") {
                Write-Host "   - Deleting: $($tg.TargetGroupName)" -ForegroundColor White
                if (-not $DryRun) {
                    aws elbv2 delete-target-group --region $region --target-group-arn $tg.TargetGroupArn 2>$null | Out-Null
                }
            }
        }
    }
    
    # 6. Delete VPCs and related resources
    Write-Host " [6] Deleting VPCs..." -ForegroundColor Yellow
    $vpcs = aws ec2 describe-vpcs --region $region --filters "Name=tag:Project,Values=forum-microservices" --output json 2>$null | ConvertFrom-Json
    if ($vpcs.Vpcs) {
        foreach ($vpc in $vpcs.Vpcs) {
            Write-Host "   - Processing VPC: $($vpc.VpcId)" -ForegroundColor White
            
            if (-not $DryRun) {
                # Delete NAT Gateways
                $nats = aws ec2 describe-nat-gateways --region $region --filter "Name=vpc-id,Values=$($vpc.VpcId)" --output json 2>$null | ConvertFrom-Json
                foreach ($nat in $nats.NatGateways) {
                    if ($nat.State -ne "deleted") {
                        Write-Host "     * Deleting NAT Gateway: $($nat.NatGatewayId)" -ForegroundColor Gray
                        aws ec2 delete-nat-gateway --region $region --nat-gateway-id $nat.NatGatewayId 2>$null | Out-Null
                    }
                }
                
                # Wait for NAT Gateways
                Write-Host "     * Waiting for NAT Gateways to delete..." -ForegroundColor Gray
                Start-Sleep -Seconds 30
                
                # Delete Network Interfaces
                $enis = aws ec2 describe-network-interfaces --region $region --filters "Name=vpc-id,Values=$($vpc.VpcId)" --output json 2>$null | ConvertFrom-Json
                foreach ($eni in $enis.NetworkInterfaces) {
                    if ($eni.Attachment) {
                        aws ec2 detach-network-interface --region $region --attachment-id $eni.Attachment.AttachmentId --force 2>$null | Out-Null
                        Start-Sleep -Seconds 2
                    }
                    aws ec2 delete-network-interface --region $region --network-interface-id $eni.NetworkInterfaceId 2>$null | Out-Null
                }
                
                # Release Elastic IPs
                $eips = aws ec2 describe-addresses --region $region --output json 2>$null | ConvertFrom-Json
                foreach ($eip in $eips.Addresses) {
                    if ($eip.PublicIp -and -not $eip.InstanceId -and -not $eip.NetworkInterfaceId) {
                        aws ec2 release-address --region $region --allocation-id $eip.AllocationId 2>$null | Out-Null
                    }
                }
                
                # Delete Subnets
                $subnets = aws ec2 describe-subnets --region $region --filters "Name=vpc-id,Values=$($vpc.VpcId)" --output json 2>$null | ConvertFrom-Json
                foreach ($subnet in $subnets.Subnets) {
                    aws ec2 delete-subnet --region $region --subnet-id $subnet.SubnetId 2>$null | Out-Null
                }
                
                # Delete Route Tables
                $rts = aws ec2 describe-route-tables --region $region --filters "Name=vpc-id,Values=$($vpc.VpcId)" --output json 2>$null | ConvertFrom-Json
                foreach ($rt in $rts.RouteTables) {
                    $isMain = $false
                    foreach ($assoc in $rt.Associations) {
                        if ($assoc.Main) { $isMain = $true }
                    }
                    if (-not $isMain) {
                        foreach ($assoc in $rt.Associations) {
                            if (-not $assoc.Main) {
                                aws ec2 disassociate-route-table --region $region --association-id $assoc.RouteTableAssociationId 2>$null | Out-Null
                            }
                        }
                        aws ec2 delete-route-table --region $region --route-table-id $rt.RouteTableId 2>$null | Out-Null
                    }
                }
                
                # Delete Internet Gateways
                $igws = aws ec2 describe-internet-gateways --region $region --filters "Name=attachment.vpc-id,Values=$($vpc.VpcId)" --output json 2>$null | ConvertFrom-Json
                foreach ($igw in $igws.InternetGateways) {
                    aws ec2 detach-internet-gateway --region $region --internet-gateway-id $igw.InternetGatewayId --vpc-id $vpc.VpcId 2>$null | Out-Null
                    aws ec2 delete-internet-gateway --region $region --internet-gateway-id $igw.InternetGatewayId 2>$null | Out-Null
                }
                
                # Delete Security Groups
                $sgs = aws ec2 describe-security-groups --region $region --filters "Name=vpc-id,Values=$($vpc.VpcId)" --output json 2>$null | ConvertFrom-Json
                foreach ($sg in $sgs.SecurityGroups) {
                    if ($sg.GroupName -ne "default") {
                        aws ec2 delete-security-group --region $region --group-id $sg.GroupId 2>$null | Out-Null
                    }
                }
                
                # Delete VPC
                Write-Host "     * Deleting VPC: $($vpc.VpcId)" -ForegroundColor Gray
                aws ec2 delete-vpc --region $region --vpc-id $vpc.VpcId 2>$null | Out-Null
            }
        }
    }
    
    Write-Host ""
}

Write-Host "================================================================" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  DRY RUN COMPLETE - No resources were deleted" -ForegroundColor Yellow
} else {
    Write-Host "  CLEANUP COMPLETE!" -ForegroundColor Green
}
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
