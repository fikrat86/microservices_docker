# Elastic Container Registry (ECR) Repositories

# ECR Repository for Posts Service
resource "aws_ecr_repository" "posts" {
  name                 = "${var.project_name}/posts"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${var.project_name}-posts-ecr-${var.environment}"
    Service = "posts"
  }
}

# ECR Repository for Threads Service
resource "aws_ecr_repository" "threads" {
  name                 = "${var.project_name}/threads"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${var.project_name}-threads-ecr-${var.environment}"
    Service = "threads"
  }
}

# ECR Repository for Users Service
resource "aws_ecr_repository" "users" {
  name                 = "${var.project_name}/users"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name    = "${var.project_name}-users-ecr-${var.environment}"
    Service = "users"
  }
}

# Lifecycle Policy for ECR Repositories (keep last 10 images)
resource "aws_ecr_lifecycle_policy" "posts" {
  repository = aws_ecr_repository.posts.name

  policy = jsonencode({
    rules = [
      {
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
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "threads" {
  repository = aws_ecr_repository.threads.name

  policy = jsonencode({
    rules = [
      {
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
      }
    ]
  })
}

resource "aws_ecr_lifecycle_policy" "users" {
  repository = aws_ecr_repository.users.name

  policy = jsonencode({
    rules = [
      {
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
      }
    ]
  })
}
