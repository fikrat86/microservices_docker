# CodeBuild Projects for each microservice

# CloudWatch Log Group for CodeBuild
resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/aws/codebuild/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-codebuild-logs-${var.environment}"
  }
}

# CodeBuild Project for Posts Service
resource "aws_codebuild_project" "posts" {
  name          = "${var.project_name}-posts-build-${var.environment}"
  description   = "Build Docker image for Posts service"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.posts.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "posts"
    }

    environment_variable {
      name  = "ECS_TASK_DEFINITION"
      value = aws_ecs_task_definition.posts.family
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
      stream_name = "posts"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "posts/buildspec.yml"
  }

  tags = {
    Name    = "${var.project_name}-posts-build-${var.environment}"
    Service = "posts"
  }
}

# CodeBuild Project for Threads Service
resource "aws_codebuild_project" "threads" {
  name          = "${var.project_name}-threads-build-${var.environment}"
  description   = "Build Docker image for Threads service"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.threads.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "threads"
    }

    environment_variable {
      name  = "ECS_TASK_DEFINITION"
      value = aws_ecs_task_definition.threads.family
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
      stream_name = "threads"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "threads/buildspec.yml"
  }

  tags = {
    Name    = "${var.project_name}-threads-build-${var.environment}"
    Service = "threads"
  }
}

# CodeBuild Project for Users Service
resource "aws_codebuild_project" "users" {
  name          = "${var.project_name}-users-build-${var.environment}"
  description   = "Build Docker image for Users service"
  service_role  = aws_iam_role.codebuild_role.arn
  build_timeout = 20

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true

    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }

    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }

    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.users.name
    }

    environment_variable {
      name  = "IMAGE_TAG"
      value = "latest"
    }

    environment_variable {
      name  = "CONTAINER_NAME"
      value = "users"
    }

    environment_variable {
      name  = "ECS_TASK_DEFINITION"
      value = aws_ecs_task_definition.users.family
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
      stream_name = "users"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "users/buildspec.yml"
  }

  tags = {
    Name    = "${var.project_name}-users-build-${var.environment}"
    Service = "users"
  }
}
