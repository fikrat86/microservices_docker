# Disaster Recovery - Secondary Region Configuration
# This file sets up a complete secondary region for disaster recovery

# Secondary region provider
provider "aws" {
  alias  = "dr"
  region = var.dr_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "${var.environment}-dr"
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
      Region      = "DR"
    }
  }
}

# DR VPC
resource "aws_vpc" "dr" {
  provider             = aws.dr
  cidr_block           = var.dr_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc-${var.environment}-dr"
  }
}

# DR Internet Gateway
resource "aws_internet_gateway" "dr" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr.id

  tags = {
    Name = "${var.project_name}-igw-${var.environment}-dr"
  }
}

# DR Public Subnets
resource "aws_subnet" "dr_public" {
  provider                = aws.dr
  count                   = length(var.dr_availability_zones)
  vpc_id                  = aws_vpc.dr.id
  cidr_block              = cidrsubnet(var.dr_vpc_cidr, 8, count.index)
  availability_zone       = var.dr_availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}-${var.environment}-dr"
    Type = "Public"
  }
}

# DR Private Subnets
resource "aws_subnet" "dr_private" {
  provider          = aws.dr
  count             = length(var.dr_availability_zones)
  vpc_id            = aws_vpc.dr.id
  cidr_block        = cidrsubnet(var.dr_vpc_cidr, 8, count.index + 10)
  availability_zone = var.dr_availability_zones[count.index]

  tags = {
    Name = "${var.project_name}-private-subnet-${count.index + 1}-${var.environment}-dr"
    Type = "Private"
  }
}

# DR NAT Gateways
resource "aws_eip" "dr_nat" {
  provider = aws.dr
  count    = length(var.dr_availability_zones)
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip-${count.index + 1}-${var.environment}-dr"
  }
}

resource "aws_nat_gateway" "dr" {
  provider      = aws.dr
  count         = length(var.dr_availability_zones)
  allocation_id = aws_eip.dr_nat[count.index].id
  subnet_id     = aws_subnet.dr_public[count.index].id

  tags = {
    Name = "${var.project_name}-nat-${count.index + 1}-${var.environment}-dr"
  }

  depends_on = [aws_internet_gateway.dr]
}

# DR Public Route Table
resource "aws_route_table" "dr_public" {
  provider = aws.dr
  vpc_id   = aws_vpc.dr.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${var.environment}-dr"
  }
}

resource "aws_route_table_association" "dr_public" {
  provider       = aws.dr
  count          = length(var.dr_availability_zones)
  subnet_id      = aws_subnet.dr_public[count.index].id
  route_table_id = aws_route_table.dr_public.id
}

# DR Private Route Tables
resource "aws_route_table" "dr_private" {
  provider = aws.dr
  count    = length(var.dr_availability_zones)
  vpc_id   = aws_vpc.dr.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.dr[count.index].id
  }

  tags = {
    Name = "${var.project_name}-private-rt-${count.index + 1}-${var.environment}-dr"
  }
}

resource "aws_route_table_association" "dr_private" {
  provider       = aws.dr
  count          = length(var.dr_availability_zones)
  subnet_id      = aws_subnet.dr_private[count.index].id
  route_table_id = aws_route_table.dr_private[count.index].id
}

# DR ECR Repositories (replicate from primary)
resource "aws_ecr_repository" "dr_posts" {
  provider             = aws.dr
  name                 = "${var.project_name}/posts-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${var.project_name}-posts-ecr-dr"
    Service = "posts"
  }
}

resource "aws_ecr_repository" "dr_threads" {
  provider             = aws.dr
  name                 = "${var.project_name}/threads-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${var.project_name}-threads-ecr-dr"
    Service = "threads"
  }
}

resource "aws_ecr_repository" "dr_users" {
  provider             = aws.dr
  name                 = "${var.project_name}/users-${var.environment}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${var.project_name}-users-ecr-dr"
    Service = "users"
  }
}

# DR ECR Lifecycle Policies
resource "aws_ecr_lifecycle_policy" "dr_posts" {
  provider   = aws.dr
  repository = aws_ecr_repository.dr_posts.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "dr_threads" {
  provider   = aws.dr
  repository = aws_ecr_repository.dr_threads.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "dr_users" {
  provider   = aws.dr
  repository = aws_ecr_repository.dr_users.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}

# DR ECS Cluster
resource "aws_ecs_cluster" "dr" {
  provider = aws.dr
  name     = "${var.project_name}-cluster-${var.environment}-dr"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-ecs-cluster-${var.environment}-dr"
  }
}

# DR CloudWatch Log Group
resource "aws_cloudwatch_log_group" "dr_ecs" {
  provider          = aws.dr
  name              = "/ecs/${var.project_name}-${var.environment}-dr"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ecs-logs-dr"
  }
}

# DR Security Groups
resource "aws_security_group" "dr_alb" {
  provider    = aws.dr
  name        = "${var.project_name}-alb-sg-${var.environment}-dr"
  description = "Security group for Application Load Balancer in DR region"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg-${var.environment}-dr"
  }
}

resource "aws_security_group" "dr_ecs_tasks" {
  provider    = aws.dr
  name        = "${var.project_name}-ecs-tasks-sg-${var.environment}-dr"
  description = "Security group for ECS tasks in DR region"
  vpc_id      = aws_vpc.dr.id

  ingress {
    description     = "Allow traffic from ALB"
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.dr_alb.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg-${var.environment}-dr"
  }
}

# DR Application Load Balancer
resource "aws_lb" "dr" {
  provider           = aws.dr
  name               = "${var.project_name}-alb-${var.environment}-dr"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dr_alb.id]
  subnets            = aws_subnet.dr_public[*].id

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb-${var.environment}-dr"
  }
}

# DR Target Groups
resource "aws_lb_target_group" "dr_posts" {
  provider    = aws.dr
  name        = "forum-ms-posts-tg-${var.environment}-dr"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.dr.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name    = "forum-microservices-posts-tg-${var.environment}-dr"
    Service = "posts"
  }
}

resource "aws_lb_target_group" "dr_threads" {
  provider    = aws.dr
  name        = "forum-ms-threads-tg-${var.environment}-dr"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.dr.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name    = "forum-microservices-threads-tg-${var.environment}-dr"
    Service = "threads"
  }
}

resource "aws_lb_target_group" "dr_users" {
  provider    = aws.dr
  name        = "forum-ms-users-tg-${var.environment}-dr"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.dr.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name    = "forum-microservices-users-tg-${var.environment}-dr"
    Service = "users"
  }
}

# DR ALB Listener
resource "aws_lb_listener" "dr_http" {
  provider          = aws.dr
  load_balancer_arn = aws_lb.dr.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Service not found"
      status_code  = "404"
    }
  }
}

# DR Listener Rules
resource "aws_lb_listener_rule" "dr_posts" {
  provider     = aws.dr
  listener_arn = aws_lb_listener.dr_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dr_posts.arn
  }

  condition {
    path_pattern {
      values = ["/api/posts*"]
    }
  }
}

resource "aws_lb_listener_rule" "dr_threads" {
  provider     = aws.dr
  listener_arn = aws_lb_listener.dr_http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dr_threads.arn
  }

  condition {
    path_pattern {
      values = ["/api/threads*"]
    }
  }
}

resource "aws_lb_listener_rule" "dr_users" {
  provider     = aws.dr
  listener_arn = aws_lb_listener.dr_http.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dr_users.arn
  }

  condition {
    path_pattern {
      values = ["/api/users*"]
    }
  }
}
