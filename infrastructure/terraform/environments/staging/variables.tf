# Human Tasks:
# 1. Review and adjust instance types based on staging workload requirements
# 2. Verify backup retention periods align with data retention policies
# 3. Confirm ElastiCache node count meets staging environment needs
# 4. Review S3 lifecycle rules for staging data management
# 5. Ensure staging environment CIDR blocks don't conflict with other environments

# AWS Provider version requirement
# hashicorp/aws ~> 4.0

# Requirement: Staging Environment Infrastructure - Environment Identifier
variable "environment" {
  description = "Deployment environment identifier"
  type        = string
  default     = "staging"
  validation {
    condition     = var.environment == "staging"
    error_message = "This configuration is specifically for staging environment"
  }
}

# Requirement: Infrastructure Architecture - EKS Cluster Configuration
variable "eks_cluster_config" {
  description = "EKS cluster configuration for staging environment"
  type = object({
    node_count      = number
    instance_types  = list(string)
    disk_size      = number
    max_pods       = number
  })
  default = {
    node_count     = 2            # Fixed 2-node deployment for staging
    instance_types = ["t3.medium"] # Cost-effective instance type for staging
    disk_size     = 50           # Minimum required disk size
    max_pods      = 30           # Pod limit per node for staging workloads
  }
  validation {
    condition     = var.eks_cluster_config.node_count >= 2
    error_message = "Node count must be >= 2 for staging environment"
  }
  validation {
    condition     = var.eks_cluster_config.disk_size >= 50
    error_message = "Disk size must be >= 50GB"
  }
  validation {
    condition     = contains(["t3.medium", "t3.large"], var.eks_cluster_config.instance_types[0])
    error_message = "Instance type must be either t3.medium or t3.large for staging"
  }
}

# Requirement: Infrastructure Architecture - RDS Configuration
variable "rds_config" {
  description = "RDS configuration for staging environment"
  type = object({
    instance_class        = string
    allocated_storage    = number
    multi_az            = bool
    backup_retention_days = number
  })
  default = {
    instance_class        = "db.t3.medium"  # Cost-effective instance for staging
    allocated_storage    = 50              # Minimum storage for staging
    multi_az            = false           # Single-AZ deployment for staging
    backup_retention_days = 7              # Minimum backup retention period
  }
  validation {
    condition     = contains(["db.t3.medium", "db.t3.large"], var.rds_config.instance_class)
    error_message = "Instance class must be either db.t3.medium or db.t3.large for staging"
  }
  validation {
    condition     = var.rds_config.allocated_storage >= 50
    error_message = "Allocated storage must be >= 50GB"
  }
  validation {
    condition     = var.rds_config.backup_retention_days >= 7
    error_message = "Backup retention must be >= 7 days"
  }
}

# Requirement: Infrastructure Architecture - ElastiCache Configuration
variable "elasticache_config" {
  description = "ElastiCache configuration for staging environment"
  type = object({
    instance_type       = string
    num_nodes          = number
    automatic_failover = bool
  })
  default = {
    instance_type       = "cache.t3.medium"  # Cost-effective cache instance
    num_nodes          = 1                  # Single node for staging
    automatic_failover = false             # Disabled for staging environment
  }
  validation {
    condition     = contains(["cache.t3.micro", "cache.t3.small", "cache.t3.medium"], var.elasticache_config.instance_type)
    error_message = "Instance type must be a valid ElastiCache node type for staging"
  }
  validation {
    condition     = var.elasticache_config.num_nodes >= 1
    error_message = "Number of nodes must be >= 1"
  }
}

# Requirement: Infrastructure Architecture - S3 Storage Configuration
variable "s3_config" {
  description = "S3 storage configuration for staging environment"
  type = object({
    versioning        = bool
    lifecycle_rules  = map(number)
  })
  default = {
    versioning       = true
    lifecycle_rules = {
      transition_glacier_days = 90  # Archive old staging data
      expiration_days        = 365  # Remove expired staging data
    }
  }
  validation {
    condition     = var.s3_config.lifecycle_rules.transition_glacier_days >= 30
    error_message = "Glacier transition must be >= 30 days"
  }
  validation {
    condition     = var.s3_config.lifecycle_rules.expiration_days >= 90
    error_message = "Expiration must be >= 90 days"
  }
}

# Requirement: Security Architecture - Network Configuration
variable "vpc_cidr" {
  description = "VPC CIDR block for staging environment"
  type        = string
  default     = "10.1.0.0/16"  # Dedicated CIDR range for staging
}

# Requirement: Infrastructure Architecture - Region Configuration
variable "aws_region" {
  description = "AWS region for staging environment deployment"
  type        = string
  default     = "us-west-2"  # Same region as production for consistency
}