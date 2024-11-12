# Human Tasks:
# 1. Review and adjust KMS key configuration if using customer-managed keys
# 2. Verify replication configuration settings for production environment
# 3. Review lifecycle rules based on data retention requirements
# 4. Ensure appropriate IAM permissions are configured for S3 bucket access

# Requirement: Infrastructure Architecture - Environment Specification
variable "environment" {
  description = "Deployment environment (production, staging, development)"
  type        = string
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development"
  }
}

# Requirement: S3-compatible Storage Configuration
variable "s3_config" {
  description = "S3 bucket configuration settings"
  type = object({
    bucket_name         = string
    versioning         = bool
    replication_enabled = bool
    lifecycle_rules    = list(object({
      id               = string
      enabled          = bool
      prefix           = string
      expiration_days  = number
    }))
  })
  default = {
    versioning         = true
    replication_enabled = false
    lifecycle_rules    = []
  }

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.s3_config.bucket_name))
    error_message = "Bucket name must be lowercase alphanumeric characters and hyphens, and cannot start or end with a hyphen"
  }
}

# Requirement: Data Security Configuration
variable "encryption_config" {
  description = "S3 encryption configuration as specified in section 6.2.1"
  type = object({
    sse_algorithm     = string
    kms_master_key_id = string
  })
  default = {
    sse_algorithm     = "AES256"
    kms_master_key_id = null
  }

  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_config.sse_algorithm)
    error_message = "SSE algorithm must be either AES256 or aws:kms"
  }
}

# Requirement: Production Storage Infrastructure
variable "replication_config" {
  description = "Cross-region replication configuration for disaster recovery"
  type = object({
    destination_bucket = string
    destination_region = string
  })
  default = null

  validation {
    condition     = var.replication_config == null ? true : (
                    can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.replication_config.destination_bucket)) &&
                    can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.replication_config.destination_region))
                   )
    error_message = "Invalid destination bucket name or region format"
  }
}

# Requirement: Infrastructure Architecture - Resource Tagging
variable "tags" {
  description = "Resource tags to apply to all S3 resources"
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.tags) <= 50
    error_message = "Maximum of 50 tags can be specified"
  }
}