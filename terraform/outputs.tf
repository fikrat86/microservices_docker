# Output values for infrastructure resources

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "URL of the Application Load Balancer"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_posts_repository_url" {
  description = "URL of the Posts service ECR repository"
  value       = aws_ecr_repository.posts.repository_url
}

output "ecr_threads_repository_url" {
  description = "URL of the Threads service ECR repository"
  value       = aws_ecr_repository.threads.repository_url
}

output "ecr_users_repository_url" {
  description = "URL of the Users service ECR repository"
  value       = aws_ecr_repository.users.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "posts_service_name" {
  description = "Name of the Posts ECS service"
  value       = aws_ecs_service.posts.name
}

output "threads_service_name" {
  description = "Name of the Threads ECS service"
  value       = aws_ecs_service.threads.name
}

output "users_service_name" {
  description = "Name of the Users ECS service"
  value       = aws_ecs_service.users.name
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "service_endpoints" {
  description = "Service endpoints for testing"
  value = {
    posts   = "http://${aws_lb.main.dns_name}/api/posts"
    threads = "http://${aws_lb.main.dns_name}/api/threads"
    users   = "http://${aws_lb.main.dns_name}/api/users"
  }
}

# DR Region Outputs
output "dr_alb_dns_name" {
  description = "DNS name of the DR Application Load Balancer"
  value       = aws_lb.dr.dns_name
}

output "dr_alb_url" {
  description = "URL of the DR Application Load Balancer"
  value       = "http://${aws_lb.dr.dns_name}"
}

output "dr_service_endpoints" {
  description = "DR service endpoints for testing"
  value = {
    posts   = "http://${aws_lb.dr.dns_name}/api/posts"
    threads = "http://${aws_lb.dr.dns_name}/api/threads"
    users   = "http://${aws_lb.dr.dns_name}/api/users"
  }
}

output "dr_ecs_cluster_name" {
  description = "Name of the DR ECS cluster"
  value       = aws_ecs_cluster.dr.name
}

output "backup_bucket_name" {
  description = "Name of the S3 bucket for database backups"
  value       = aws_s3_bucket.backup.id
}

output "dr_backup_bucket_name" {
  description = "Name of the DR S3 bucket for database backups"
  value       = aws_s3_bucket.dr_backup.id
}
