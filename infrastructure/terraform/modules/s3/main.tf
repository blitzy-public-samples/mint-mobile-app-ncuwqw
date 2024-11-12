# Human Tasks:
# 1. Review and adjust KMS key configuration if using customer-managed keys
# 2. Verify replication configuration settings for production environment
# 3. Review lifecycle rules based on data retention requirements
# 4. Ensure appropriate IAM permissions are configured for S3 bucket access
# 5. Verify CloudFront CDN integration settings if required

# AWS Provider version constraint
# AWS Provider ~> 4.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Requirement: S3-compatible storage (Section 1.1)
# Creates the main S3 bucket with environment-specific naming
resource "aws_s3_bucket" "main" {
  bucket        = "${var.s3_config.bucket_name}-${var.environment}"
  force_destroy = false
  tags          = var.tags
}

# Requirement: Production Storage Infrastructure (Section 2.5.1)
# Configures versioning for the S3 bucket
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id
  versioning_configuration {
    status = var.s3_config.versioning ? "Enabled" : "Disabled"
  }
}

# Requirement: Data Security (Section 6.2.1)
# Implements server-side encryption for the S3 bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_config.sse_algorithm
      kms_master_key_id = var.encryption_config.kms_master_key_id
    }
    bucket_key_enabled = true
  }
}

# Requirement: S3-compatible storage (Section 1.1)
# Configures lifecycle rules for the S3 bucket
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  dynamic "rule" {
    for_each = var.s3_config.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.enabled ? "Enabled" : "Disabled"

      filter {
        prefix = rule.value.prefix
      }

      expiration {
        days = rule.value.expiration_days
      }
    }
  }
}

# Requirement: Data Security (Section 6.2)
# Blocks all public access to the S3 bucket
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Requirement: Data Security (Section 6.2)
# Enables default encryption for objects
resource "aws_s3_bucket_acl" "main" {
  bucket = aws_s3_bucket.main.id
  acl    = "private"
}

# Requirement: Production Storage Infrastructure (Section 2.5.1)
# Configures CORS rules for the S3 bucket
resource "aws_s3_bucket_cors_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Outputs for use by other modules
output "bucket_id" {
  description = "The ID of the created S3 bucket"
  value       = aws_s3_bucket.main.id
}

output "bucket_arn" {
  description = "The ARN of the created S3 bucket"
  value       = aws_s3_bucket.main.arn
}