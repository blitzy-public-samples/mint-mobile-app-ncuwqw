# Human Tasks:
# 1. Review and adjust node instance types based on workload profiling
# 2. Configure alert_endpoints with actual email addresses for production monitoring
# 3. Verify backup retention periods meet compliance requirements
# 4. Review and adjust allocated storage values based on data growth projections
# 5. Ensure AWS KMS keys are properly configured for encryption

# Requirement: Production Environment Infrastructure - Environment Identifier
variable "environment" {
  description = "Production environment identifier"
  type        = string
  default     = "production"
  validation {
    condition     = var.environment == "production"
    error_message = "This environment must be set to 'production'"
  }
}

# Requirement: Infrastructure Architecture - High Availability Configuration
variable "environment_config" {
  description = "Production environment configuration"
  type = object({
    high_availability = bool
    multi_az         = bool
  })
  default = {
    high_availability = true
    multi_az         = true
  }
  validation {
    condition     = var.environment_config.high_availability == true
    error_message = "High availability must be enabled in production environment"
  }
  validation {
    condition     = var.environment_config.multi_az == true
    error_message = "Multi-AZ deployment must be enabled in production environment"
  }
}

# Requirement: Infrastructure Architecture - EKS Cluster Configuration
variable "eks_cluster_config" {
  description = "Production EKS cluster settings"
  type = object({
    min_nodes                      = number
    max_nodes                      = number
    node_instance_types           = list(string)
    kubernetes_version            = string
    cluster_endpoint_private_access = bool
    cluster_endpoint_public_access  = bool
    enable_irsa                    = bool
  })
  default = {
    min_nodes                      = 2
    max_nodes                      = 20
    node_instance_types           = ["t3.large", "t3.xlarge"]
    kubernetes_version            = "1.24"
    cluster_endpoint_private_access = true
    cluster_endpoint_public_access  = true
    enable_irsa                    = true
  }
  validation {
    condition     = var.eks_cluster_config.min_nodes >= 2
    error_message = "Production environment requires minimum 2 nodes for high availability"
  }
  validation {
    condition     = var.eks_cluster_config.max_nodes >= var.eks_cluster_config.min_nodes && var.eks_cluster_config.max_nodes <= 20
    error_message = "Maximum nodes must be between min_nodes and 20"
  }
  validation {
    condition     = length(var.eks_cluster_config.node_instance_types) > 0
    error_message = "At least one node instance type must be specified"
  }
  validation {
    condition     = can(regex("^1\\.(2[4-9]|[3-9][0-9])$", var.eks_cluster_config.kubernetes_version))
    error_message = "Kubernetes version must be 1.24 or higher"
  }
}

# Requirement: Production Environment Infrastructure - RDS Configuration
variable "rds_production_config" {
  description = "Production RDS database settings"
  type = object({
    instance_class          = string
    multi_az               = bool
    backup_retention_days  = number
    allocated_storage     = number
    max_allocated_storage = number
    deletion_protection   = bool
    monitoring_interval   = number
  })
  default = {
    instance_class          = "db.t3.large"
    multi_az               = true
    backup_retention_days  = 30
    allocated_storage     = 100
    max_allocated_storage = 500
    deletion_protection   = true
    monitoring_interval   = 60
  }
  validation {
    condition     = contains(["db.t3.large", "db.t3.xlarge", "db.r5.large", "db.r5.xlarge"], var.rds_production_config.instance_class)
    error_message = "Instance class must be production-grade (db.t3.large or higher)"
  }
  validation {
    condition     = var.rds_production_config.multi_az == true
    error_message = "Multi-AZ must be enabled for production RDS instances"
  }
  validation {
    condition     = var.rds_production_config.backup_retention_days >= 30
    error_message = "Backup retention period must be at least 30 days for production"
  }
  validation {
    condition     = var.rds_production_config.allocated_storage >= 100
    error_message = "Allocated storage must be at least 100 GB for production"
  }
  validation {
    condition     = var.rds_production_config.max_allocated_storage >= var.rds_production_config.allocated_storage
    error_message = "Maximum allocated storage must be greater than or equal to allocated storage"
  }
}

# Requirement: Production Environment Infrastructure - ElastiCache Configuration
variable "elasticache_production_config" {
  description = "Production ElastiCache settings"
  type = object({
    node_type                  = string
    num_cache_clusters         = number
    engine_version            = string
    automatic_failover_enabled = bool
  })
  default = {
    node_type                  = "cache.t3.medium"
    num_cache_clusters         = 2
    engine_version            = "6.x"
    automatic_failover_enabled = true
  }
  validation {
    condition     = contains(["cache.t3.medium", "cache.t3.large", "cache.r5.large", "cache.r5.xlarge"], var.elasticache_production_config.node_type)
    error_message = "Node type must be production-grade (cache.t3.medium or higher)"
  }
  validation {
    condition     = var.elasticache_production_config.num_cache_clusters >= 2
    error_message = "Production environment requires at least 2 cache clusters for high availability"
  }
  validation {
    condition     = var.elasticache_production_config.automatic_failover_enabled == true
    error_message = "Automatic failover must be enabled for production ElastiCache clusters"
  }
}

# Requirement: Security Architecture - Monitoring Configuration
variable "monitoring_config" {
  description = "Production monitoring settings"
  type = object({
    retention_days            = number
    alert_endpoints          = list(string)
    detailed_monitoring_enabled = bool
  })
  default = {
    retention_days            = 90
    alert_endpoints          = ["ops@mintreplica.com"]
    detailed_monitoring_enabled = true
  }
  validation {
    condition     = var.monitoring_config.retention_days >= 90
    error_message = "Log retention must be at least 90 days for production environment"
  }
  validation {
    condition     = length(var.monitoring_config.alert_endpoints) > 0
    error_message = "At least one alert endpoint must be configured"
  }
  validation {
    condition     = var.monitoring_config.detailed_monitoring_enabled == true
    error_message = "Detailed monitoring must be enabled for production environment"
  }
}