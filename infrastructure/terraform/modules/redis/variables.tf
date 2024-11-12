# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate credentials and region
# 2. Verify VPC and subnet configurations are properly set up for Redis deployment
# 3. Review and adjust the default node type based on production workload requirements
# 4. Configure appropriate security group rules for Redis access
# 5. Set up monitoring and alerting for Redis metrics in CloudWatch

# AWS Provider version: ~> 4.0
# Addresses requirements from:
# - Cache Infrastructure (2.1 High-Level Architecture Overview)
# - High Availability (2.5.4 Availability Architecture)
# - Security Requirements (6.2 Data Security)

variable "environment" {
  type        = string
  description = "Environment name for resource naming and tagging (e.g., dev, staging, prod)"
}

variable "node_type" {
  type        = string
  description = "ElastiCache node instance type for Redis cluster"
  default     = "cache.t3.medium"  # Default balanced instance type for moderate workloads
}

variable "num_cache_nodes" {
  type        = number
  description = "Number of cache nodes in the Redis cluster"
  default     = 2  # Default to 2 nodes for high availability
}

variable "automatic_failover" {
  type        = bool
  description = "Enable/disable automatic failover for multi-AZ deployments"
  default     = true  # Enable by default for high availability
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Redis cluster will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for Redis subnet group in multiple availability zones"
}

variable "parameter_group_family" {
  type        = string
  description = "Redis parameter group family version"
  default     = "redis6.x"  # Default to Redis 6.x for latest stable features
}

variable "tags" {
  type        = map(string)
  description = "Resource tags for Redis cluster and related resources"
  default = {
    Terraform   = "true"
    Service     = "redis"
    Component   = "cache"
  }
}