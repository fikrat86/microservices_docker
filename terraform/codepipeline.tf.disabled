# CodePipeline for CI/CD with Blue/Green Deployment

# CodePipeline for Posts Service
resource "aws_codepipeline" "posts" {
  name     = "${var.project_name}-posts-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.posts.repository_name
        BranchName           = "main"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.posts.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.posts.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Name    = "${var.project_name}-posts-pipeline-${var.environment}"
    Service = "posts"
  }
}

# CodePipeline for Threads Service
resource "aws_codepipeline" "threads" {
  name     = "${var.project_name}-threads-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.threads.repository_name
        BranchName           = "main"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.threads.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.threads.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Name    = "${var.project_name}-threads-pipeline-${var.environment}"
    Service = "threads"
  }
}

# CodePipeline for Users Service
resource "aws_codepipeline" "users" {
  name     = "${var.project_name}-users-pipeline-${var.environment}"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName       = aws_codecommit_repository.users.repository_name
        BranchName           = "main"
        PollForSourceChanges = false
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      version          = "1"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]

      configuration = {
        ProjectName = aws_codebuild_project.users.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      version         = "1"
      input_artifacts = ["build_output"]

      configuration = {
        ClusterName = aws_ecs_cluster.main.name
        ServiceName = aws_ecs_service.users.name
        FileName    = "imagedefinitions.json"
      }
    }
  }

  tags = {
    Name    = "${var.project_name}-users-pipeline-${var.environment}"
    Service = "users"
  }
}

# CodeCommit Repositories
resource "aws_codecommit_repository" "posts" {
  repository_name = "${var.project_name}-posts-${var.environment}"
  description     = "Posts microservice repository"

  tags = {
    Name    = "${var.project_name}-posts-repo-${var.environment}"
    Service = "posts"
  }
}

resource "aws_codecommit_repository" "threads" {
  repository_name = "${var.project_name}-threads-${var.environment}"
  description     = "Threads microservice repository"

  tags = {
    Name    = "${var.project_name}-threads-repo-${var.environment}"
    Service = "threads"
  }
}

resource "aws_codecommit_repository" "users" {
  repository_name = "${var.project_name}-users-${var.environment}"
  description     = "Users microservice repository"

  tags = {
    Name    = "${var.project_name}-users-repo-${var.environment}"
    Service = "users"
  }
}

# CloudWatch Event Rule to trigger pipeline on code change
resource "aws_cloudwatch_event_rule" "posts_pipeline" {
  name        = "${var.project_name}-posts-pipeline-trigger-${var.environment}"
  description = "Trigger Posts pipeline on CodeCommit changes"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = [aws_codecommit_repository.posts.arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = ["main"]
    }
  })
}

resource "aws_cloudwatch_event_target" "posts_pipeline" {
  rule     = aws_cloudwatch_event_rule.posts_pipeline.name
  arn      = aws_codepipeline.posts.arn
  role_arn = aws_iam_role.cloudwatch_events_role.arn
}

resource "aws_cloudwatch_event_rule" "threads_pipeline" {
  name        = "${var.project_name}-threads-pipeline-trigger-${var.environment}"
  description = "Trigger Threads pipeline on CodeCommit changes"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = [aws_codecommit_repository.threads.arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = ["main"]
    }
  })
}

resource "aws_cloudwatch_event_target" "threads_pipeline" {
  rule     = aws_cloudwatch_event_rule.threads_pipeline.name
  arn      = aws_codepipeline.threads.arn
  role_arn = aws_iam_role.cloudwatch_events_role.arn
}

resource "aws_cloudwatch_event_rule" "users_pipeline" {
  name        = "${var.project_name}-users-pipeline-trigger-${var.environment}"
  description = "Trigger Users pipeline on CodeCommit changes"

  event_pattern = jsonencode({
    source      = ["aws.codecommit"]
    detail-type = ["CodeCommit Repository State Change"]
    resources   = [aws_codecommit_repository.users.arn]
    detail = {
      event         = ["referenceCreated", "referenceUpdated"]
      referenceType = ["branch"]
      referenceName = ["main"]
    }
  })
}

resource "aws_cloudwatch_event_target" "users_pipeline" {
  rule     = aws_cloudwatch_event_rule.users_pipeline.name
  arn      = aws_codepipeline.users.arn
  role_arn = aws_iam_role.cloudwatch_events_role.arn
}

# IAM Role for CloudWatch Events
resource "aws_iam_role" "cloudwatch_events_role" {
  name = "${var.project_name}-cloudwatch-events-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_events_policy" {
  name = "${var.project_name}-cloudwatch-events-policy-${var.environment}"
  role = aws_iam_role.cloudwatch_events_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codepipeline:StartPipelineExecution"
        ]
        Resource = [
          aws_codepipeline.posts.arn,
          aws_codepipeline.threads.arn,
          aws_codepipeline.users.arn
        ]
      }
    ]
  })
}
