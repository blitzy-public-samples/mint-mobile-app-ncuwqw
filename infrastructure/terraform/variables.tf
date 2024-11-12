# Human Tasks:
# 1. Review and adjust CIDR blocks based on network design requirements
# 2. Verify AWS region selection based on target user base location
# 3. Configure monitoring alert endpoints with actual email addresses/webhooks
# 4. Review and adjust Kubernetes node group sizes based on workload requirements
# 5. Ensure AWS provider is configured with appropriate permissions

# AWS Provider version requirement
# hashicorp/aws ~> 4.0

# Requirement: Infrastructure Architecture - Region Configuration
variable "aws_region" {
  description = "AWS region for infrastructure deployment"
  type        = string
  default     = "us-west-2"  # Default region for optimal latency and service availability
}

# Requirement: Infrastructure Architecture - Environment Specification
variable "environment" {
  description = "Deployment environment specification"
  type        = string
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be one of: production, staging, development"
  }
}

# Requirement: Production Environment Infrastructure - Network Configuration
variable "vpc_cidr" {
  description = "VPC CIDR block for network configuration"
  type        = string
  default     = "10.0.0.0/16"  # Standard VPC CIDR range allowing for future growth
}

# Requirement: Production Environment Infrastructure - High Availability
variable "availability_zones" {
  description = "AWS availability zones for high availability deployment"
  type        = list(string)
}

# Requirement: Production Environment Infrastructure - Kubernetes Configuration
variable "kubernetes_config" {
  description = "Kubernetes cluster configuration including version and node groups"
  type = object({
    cluster_version = string
    node_groups = map(object({
      instance_type = string
      desired_size  = number
      min_size     = number
      max_size     = number
    }))
  })
  default = {
    cluster_version = "1.27"  # Latest stable EKS version
    node_groups = {
      general = {
        instance_type = "t3.large"
        desired_size  = 2
        min_size     = 2
        max_size     = 5
      }
      compute = {
        instance_type = "c5.xlarge"
        desired_size  = 2
        min_size     = 1
        max_size     = 10
      }
    }
  }
}

# Requirement: Production Environment Infrastructure - RDS Configuration
variable "rds_config" {
  description = "RDS PostgreSQL configuration including instance class and storage"
  type = object({
    instance_class     = string
    multi_az          = bool
    engine_version    = string
    allocated_storage = number
  })
  default = {
    instance_class     = "db.t3.large"
    multi_az          = true
    engine_version    = "14.7"
    allocated_storage = 100
  }
}

# Requirement: Production Environment Infrastructure - ElastiCache Configuration
variable "elasticache_config" {
  description = "ElastiCache Redis configuration for caching and session management"
  type = object({
    node_type          = string
    num_cache_clusters = number
    engine_version     = string
  })
  default = {
    node_type          = "cache.t3.medium"
    num_cache_clusters = 2
    engine_version     = "7.0"
  }
}

# Requirement: Security Architecture - S3 Storage Configuration
variable "s3_config" {
  description = "S3 storage configuration including security and replication settings"
  type = object({
    versioning          = bool
    replication_enabled = bool
    encryption_enabled  = bool
  })
  default = {
    versioning          = true
    replication_enabled = true
    encryption_enabled  = true
  }
}

# Requirement: Production Environment Infrastructure - Monitoring Configuration
variable "monitoring_config" {
  description = "Monitoring and alerting configuration for infrastructure"
  type = object({
    retention_days   = number
    alert_endpoints = list(string)
  })
  default = {
    retention_days   = 90
    alert_endpoints = []  # To be populated with actual alert endpoints
  }
}

# Requirement: Security Architecture - Network Security Groups
variable "security_group_rules" {
  description = "Default security group rules for VPC resources"
  type = map(object({
    type        = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = {
    http = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    https = {
      type        = "ingress"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    postgresql = {
      type        = "ingress"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = []  # To be populated with actual VPC CIDR
    }
  }
}

# Requirement: Security Architecture - Backup Configuration
variable "backup_config" {
  description = "Backup configuration for databases and storage"
  type = object({
    retention_period = number
    backup_window   = string
  })
  default = {
    retention_period = 30
    backup_window   = "03:00-04:00"
  }
}

# Requirement: Infrastructure Architecture - Resource Tagging
variable "tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "mint-replica-lite"
    Environment = "production"
    Terraform   = "true"
    Owner       = "platform-team"
  }
}