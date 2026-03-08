######################################################################
# S3 MODULE - Main Configuration
######################################################################

# S3 Bucket for Application Data
resource "aws_s3_bucket" "app" {
  count  = var.create_app_bucket ? 1 : 0
  bucket = "${var.project_name}-app-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-app-${var.environment}"
    }
  )
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  count  = var.create_terraform_state_bucket ? 1 : 0
  bucket = "${var.project_name}-terraform-state-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-terraform-state-${var.environment}"
    }
  )
}

# S3 Bucket for Artifacts
resource "aws_s3_bucket" "artifacts" {
  count  = var.create_artifacts_bucket ? 1 : 0
  bucket = "${var.project_name}-artifacts-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-artifacts-${var.environment}"
    }
  )
}

# Versioning for all buckets
resource "aws_s3_bucket_versioning" "app" {
  count  = var.create_app_bucket && var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.app[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  count  = var.create_terraform_state_bucket && var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  versioning_configuration {
    status = "Enabled"
    mfa_delete = var.enable_mfa_delete ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_versioning" "artifacts" {
  count  = var.create_artifacts_bucket && var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app" {
  count  = var.create_app_bucket && var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.app[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  count  = var.create_terraform_state_bucket && var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  count  = var.create_artifacts_bucket && var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Public access block for all buckets
resource "aws_s3_bucket_public_access_block" "app" {
  count  = var.create_app_bucket && var.enable_public_access_block ? 1 : 0
  bucket = aws_s3_bucket.app[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  count  = var.create_terraform_state_bucket && var.enable_public_access_block ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  count  = var.create_artifacts_bucket && var.enable_public_access_block ? 1 : 0
  bucket = aws_s3_bucket.artifacts[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket logging
resource "aws_s3_bucket_logging" "app" {
  count         = var.create_app_bucket ? 1 : 0
  bucket        = aws_s3_bucket.app[0].id
  target_bucket = aws_s3_bucket.app[0].id
  target_prefix = "logs/app/"
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  count  = var.create_terraform_state_bucket ? 1 : 0
  bucket = aws_s3_bucket.terraform_state[0].id

  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Data source for AWS account ID
data "aws_caller_identity" "current" {}
