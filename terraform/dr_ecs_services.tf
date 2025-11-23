# DR Region ECS Services and Task Definitions

# DR IAM Roles
resource "aws_iam_role" "dr_ecs_task_execution_role" {
  provider = aws.dr
  name     = "${var.project_name}-ecs-task-execution-role-${var.environment}-dr"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role-dr"
  }
}

resource "aws_iam_role_policy_attachment" "dr_ecs_task_execution_role_policy" {
  provider   = aws.dr
  role       = aws_iam_role.dr_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "dr_ecs_task_role" {
  provider = aws.dr
  name     = "${var.project_name}-ecs-task-role-${var.environment}-dr"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role-dr"
  }
}

# DR Posts Service Task Definition
resource "aws_ecs_task_definition" "dr_posts" {
  provider                 = aws.dr
  family                   = "${var.project_name}-posts-${var.environment}-dr"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.dr_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.dr_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "posts"
      image     = "${aws_ecr_repository.dr_posts.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.dr_ecs.name
          "awslogs-region"        = var.dr_region
          "awslogs-stream-prefix" = "posts"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "node -e \"require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name    = "${var.project_name}-posts-task-${var.environment}-dr"
    Service = "posts"
  }
}

# DR Threads Service Task Definition
resource "aws_ecs_task_definition" "dr_threads" {
  provider                 = aws.dr
  family                   = "${var.project_name}-threads-${var.environment}-dr"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.dr_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.dr_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "threads"
      image     = "${aws_ecr_repository.dr_threads.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.dr_ecs.name
          "awslogs-region"        = var.dr_region
          "awslogs-stream-prefix" = "threads"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "node -e \"require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name    = "${var.project_name}-threads-task-${var.environment}-dr"
    Service = "threads"
  }
}

# DR Users Service Task Definition
resource "aws_ecs_task_definition" "dr_users" {
  provider                 = aws.dr
  family                   = "${var.project_name}-users-${var.environment}-dr"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.container_cpu
  memory                   = var.container_memory
  execution_role_arn       = aws_iam_role.dr_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.dr_ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "users"
      image     = "${aws_ecr_repository.dr_users.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.dr_ecs.name
          "awslogs-region"        = var.dr_region
          "awslogs-stream-prefix" = "users"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "node -e \"require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name    = "${var.project_name}-users-task-${var.environment}-dr"
    Service = "users"
  }
}

# DR Posts ECS Service
resource "aws_ecs_service" "dr_posts" {
  provider        = aws.dr
  name            = "${var.project_name}-posts-service-${var.environment}-dr"
  cluster         = aws_ecs_cluster.dr.id
  task_definition = aws_ecs_task_definition.dr_posts.arn
  desired_count   = var.enable_dr ? var.desired_count : 0
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = aws_subnet.dr_private[*].id
    security_groups  = [aws_security_group.dr_ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dr_posts.arn
    container_name   = "posts"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.dr_http,
    aws_iam_role_policy_attachment.dr_ecs_task_execution_role_policy
  ]

  tags = {
    Name    = "${var.project_name}-posts-service-${var.environment}-dr"
    Service = "posts"
  }
}

# DR Threads ECS Service
resource "aws_ecs_service" "dr_threads" {
  provider        = aws.dr
  name            = "${var.project_name}-threads-service-${var.environment}-dr"
  cluster         = aws_ecs_cluster.dr.id
  task_definition = aws_ecs_task_definition.dr_threads.arn
  desired_count   = var.enable_dr ? var.desired_count : 0
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = aws_subnet.dr_private[*].id
    security_groups  = [aws_security_group.dr_ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dr_threads.arn
    container_name   = "threads"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.dr_http,
    aws_iam_role_policy_attachment.dr_ecs_task_execution_role_policy
  ]

  tags = {
    Name    = "${var.project_name}-threads-service-${var.environment}-dr"
    Service = "threads"
  }
}

# DR Users ECS Service
resource "aws_ecs_service" "dr_users" {
  provider        = aws.dr
  name            = "${var.project_name}-users-service-${var.environment}-dr"
  cluster         = aws_ecs_cluster.dr.id
  task_definition = aws_ecs_task_definition.dr_users.arn
  desired_count   = var.enable_dr ? var.desired_count : 0
  launch_type     = "FARGATE"

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  network_configuration {
    subnets          = aws_subnet.dr_private[*].id
    security_groups  = [aws_security_group.dr_ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.dr_users.arn
    container_name   = "users"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.dr_http,
    aws_iam_role_policy_attachment.dr_ecs_task_execution_role_policy
  ]

  tags = {
    Name    = "${var.project_name}-users-service-${var.environment}-dr"
    Service = "users"
  }
}

# DR Auto Scaling for Posts Service
resource "aws_appautoscaling_target" "dr_posts" {
  provider           = aws.dr
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.dr.name}/${aws_ecs_service.dr_posts.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "dr_posts_cpu" {
  provider           = aws.dr
  name               = "${var.project_name}-posts-cpu-autoscaling-${var.environment}-dr"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dr_posts.resource_id
  scalable_dimension = aws_appautoscaling_target.dr_posts.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dr_posts.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_target_threshold
  }
}

# DR Auto Scaling for Threads Service
resource "aws_appautoscaling_target" "dr_threads" {
  provider           = aws.dr
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.dr.name}/${aws_ecs_service.dr_threads.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "dr_threads_cpu" {
  provider           = aws.dr
  name               = "${var.project_name}-threads-cpu-autoscaling-${var.environment}-dr"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dr_threads.resource_id
  scalable_dimension = aws_appautoscaling_target.dr_threads.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dr_threads.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_target_threshold
  }
}

# DR Auto Scaling for Users Service
resource "aws_appautoscaling_target" "dr_users" {
  provider           = aws.dr
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.dr.name}/${aws_ecs_service.dr_users.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "dr_users_cpu" {
  provider           = aws.dr
  name               = "${var.project_name}-users-cpu-autoscaling-${var.environment}-dr"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dr_users.resource_id
  scalable_dimension = aws_appautoscaling_target.dr_users.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dr_users.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = var.cpu_target_threshold
  }
}
