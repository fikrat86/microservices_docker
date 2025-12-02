# S3 Bucket for Database Backups (Primary Region)
resource "aws_s3_bucket" "backup" {
  bucket = "${var.project_name}-db-backups-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-db-backups-${var.environment}"
    Environment = var.environment
    Purpose     = "Database Backups"
  }
}

# Backup bucket versioning
resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Backup bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Backup bucket lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DR S3 Bucket for Database Backups (DR Region) - DISABLED
# Uncomment and add DR provider to main.tf to enable
/*
resource "aws_s3_bucket" "dr_backup" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  bucket   = "${var.project_name}-db-backups-${var.environment}-dr-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "${var.project_name}-db-backups-${var.environment}-dr"
    Environment = "${var.environment}-dr"
    Purpose     = "Database Backups DR"
  }
}

# DR Backup bucket versioning
resource "aws_s3_bucket_versioning" "dr_backup" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backup[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# DR Backup bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "dr_backup" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backup[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# DR Backup bucket lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "dr_backup" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backup[0].id

  rule {
    id     = "delete-old-backups"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.backup_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Block public access on DR bucket
resource "aws_s3_bucket_public_access_block" "dr_backup" {
  count    = var.enable_dr ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.dr_backup[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
*/


# S3 Replication Role
resource "aws_iam_role" "replication" {
  count = var.enable_cross_region_backup ? 1 : 0
  name  = "${var.project_name}-s3-replication-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })
}

# S3 Replication Policy
resource "aws_iam_role_policy" "replication" {
  count = var.enable_cross_region_backup ? 1 : 0
  name  = "${var.project_name}-s3-replication-policy-${var.environment}"
  role  = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.backup.arn
        ]
      },
      {
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.backup.arn}/*"
        ]
      },
      /* DR replication disabled
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.dr_backup.arn}/*"
        ]
      }
      */
    ]
  })
}

# S3 Replication Configuration - DISABLED (requires DR provider)
/*
resource "aws_s3_bucket_replication_configuration" "backup" {
  count = var.enable_cross_region_backup ? 1 : 0

  depends_on = [aws_s3_bucket_versioning.backup]

  role   = aws_iam_role.replication[0].arn
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "replicate-to-dr"
    status = "Enabled"

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.dr_backup.arn
      storage_class = "STANDARD"
    }
  }
}
*/


# Data source for current AWS account
data "aws_caller_identity" "current" {}
