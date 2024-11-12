# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate permissions for RDS management
# 2. Configure VPC security groups with appropriate inbound/outbound rules for PostgreSQL (port 5432)
# 3. Set up subnet groups in multiple AZs for high availability
# 4. Configure AWS KMS key for RDS encryption if using custom key management
# 5. Review and adjust default parameter group settings based on workload requirements

# AWS Provider version requirement
# hashicorp/aws ~> 4.0

# RDS instance identifier
variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
}

# PostgreSQL engine version
variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "14.7"  # Requirement: Database Infrastructure - PostgreSQL version specified in technical spec
}

# Instance class
variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
}

# Storage allocation
variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 100  # Initial storage allocation for production workload
}

variable "max_allocated_storage" {
  description = "The upper limit for storage autoscaling in gigabytes"
  type        = number
  default     = 500  # Maximum storage limit for growth
}

# High availability configuration
variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = true  # Requirement: High Availability - Multi-AZ deployment for automated failover
}

# Backup configuration
variable "backup_retention_period" {
  description = "The days to retain backups for"
  type        = number
  default     = 7  # Standard backup retention for production
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created (UTC)"
  type        = string
  default     = "03:00-04:00"  # Early morning UTC backup window
}

variable "maintenance_window" {
  description = "The window to perform maintenance in (UTC)"
  type        = string
  default     = "Sun:04:00-Sun:05:00"  # Maintenance window following backup window
}

# Network configuration
variable "subnet_ids" {
  description = "A list of VPC subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs for RDS access control"
  type        = list(string)
}

# Parameter group configuration
variable "parameter_group_family" {
  description = "The family of the DB parameter group"
  type        = string
  default     = "postgres14"  # Matches PostgreSQL 14.x version
}

# Monitoring configuration
variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected"
  type        = number
  default     = 60  # Standard monitoring interval for production
}

# Security configuration
variable "deletion_protection" {
  description = "If the DB instance should have deletion protection enabled"
  type        = bool
  default     = true  # Requirement: Data Security - Protection against accidental deletion
}

# Resource tagging
variable "tags" {
  description = "A mapping of tags to assign to the resource"
  type        = map(string)
  default     = {
    Environment = "production"
    Project     = "mint-replica-lite"
    Terraform   = "true"
  }
}