# Application Load Balancer and Target Groups

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = var.enable_deletion_protection
  enable_http2               = true
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "${var.project_name}-alb-${var.environment}"
  }
}

# Target Group for Posts Service
resource "aws_lb_target_group" "posts" {
  name        = "forum-ms-posts-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
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
    Name    = "${var.project_name}-posts-tg-${var.environment}"
    Service = "posts"
  }
}

# Target Group for Threads Service
resource "aws_lb_target_group" "threads" {
  name        = "forum-ms-threads-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
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
    Name    = "${var.project_name}-threads-tg-${var.environment}"
    Service = "threads"
  }
}

# Target Group for Users Service
resource "aws_lb_target_group" "users" {
  name        = "forum-ms-users-tg-${var.environment}"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
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
    Name    = "${var.project_name}-users-tg-${var.environment}"
    Service = "users"
  }
}

# Target Group for Gateway (Nginx + Frontend)
resource "aws_lb_target_group" "gateway" {
  name        = "forum-ms-gateway-tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name    = "${var.project_name}-gateway-tg-${var.environment}"
    Service = "gateway"
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.gateway.arn
  }
}

# Listener Rule for Posts Service
resource "aws_lb_listener_rule" "posts" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.posts.arn
  }

  condition {
    path_pattern {
      values = ["/api/posts*", "/posts*"]
    }
  }

  tags = {
    Service = "posts"
  }
}

# Listener Rule for Threads Service
resource "aws_lb_listener_rule" "threads" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.threads.arn
  }

  condition {
    path_pattern {
      values = ["/api/threads*", "/threads*"]
    }
  }

  tags = {
    Service = "threads"
  }
}

# Listener Rule for Users Service
resource "aws_lb_listener_rule" "users" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.users.arn
  }

  condition {
    path_pattern {
      values = ["/api/users*", "/users*"]
    }
  }

  tags = {
    Service = "users"
  }
}

# Health Check Listener Rule (for ALB health checks)
resource "aws_lb_listener_rule" "health" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 50

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = jsonencode({
        status    = "healthy"
        timestamp = "auto"
      })
      status_code = "200"
    }
  }

  condition {
    path_pattern {
      values = ["/health"]
    }
  }
}
