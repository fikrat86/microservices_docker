# Auto Scaling Configuration for ECS Services

# Auto Scaling Target for Posts Service
resource "aws_appautoscaling_target" "posts" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.posts.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based Auto Scaling Policy for Posts
resource "aws_appautoscaling_policy" "posts_cpu" {
  name               = "${var.project_name}-posts-cpu-autoscaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.posts.resource_id
  scalable_dimension = aws_appautoscaling_target.posts.scalable_dimension
  service_namespace  = aws_appautoscaling_target.posts.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Memory-based Auto Scaling Policy for Posts
resource "aws_appautoscaling_policy" "posts_memory" {
  name               = "${var.project_name}-posts-memory-autoscaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.posts.resource_id
  scalable_dimension = aws_appautoscaling_target.posts.scalable_dimension
  service_namespace  = aws_appautoscaling_target.posts.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_target_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Target for Threads Service
resource "aws_appautoscaling_target" "threads" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.threads.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based Auto Scaling Policy for Threads
resource "aws_appautoscaling_policy" "threads_cpu" {
  name               = "${var.project_name}-threads-cpu-autoscaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.threads.resource_id
  scalable_dimension = aws_appautoscaling_target.threads.scalable_dimension
  service_namespace  = aws_appautoscaling_target.threads.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Memory-based Auto Scaling Policy for Threads
resource "aws_appautoscaling_policy" "threads_memory" {
  name               = "${var.project_name}-threads-memory-autoscaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.threads.resource_id
  scalable_dimension = aws_appautoscaling_target.threads.scalable_dimension
  service_namespace  = aws_appautoscaling_target.threads.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_target_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Auto Scaling Target for Users Service
resource "aws_appautoscaling_target" "users" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.users.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based Auto Scaling Policy for Users
resource "aws_appautoscaling_policy" "users_cpu" {
  name               = "${var.project_name}-users-cpu-autoscaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.users.resource_id
  scalable_dimension = aws_appautoscaling_target.users.scalable_dimension
  service_namespace  = aws_appautoscaling_target.users.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_target_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# Memory-based Auto Scaling Policy for Users
resource "aws_appautoscaling_policy" "users_memory" {
  name               = "${var.project_name}-users-memory-autoscaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.users.resource_id
  scalable_dimension = aws_appautoscaling_target.users.scalable_dimension
  service_namespace  = aws_appautoscaling_target.users.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_target_threshold
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
