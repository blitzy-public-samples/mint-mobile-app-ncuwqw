# Human Tasks:
# 1. Review and adjust node group configurations based on workload requirements
# 2. Verify CIDR blocks for API endpoint access align with security policies
# 3. Confirm Kubernetes version meets application compatibility requirements
# 4. Ensure subnet configuration spans desired availability zones
# 5. Review IAM roles and service account configurations

# Required Provider Version
# hashicorp/aws ~> 4.0

# Requirement: Container Orchestration - Cluster Configuration
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  validation {
    condition     = length(var.cluster_name) <= 40 && can(regex("^[a-zA-Z][a-zA-Z0-9-]*$", var.cluster_name))
    error_message = "Cluster name must be 40 characters or less, start with a letter, and contain only alphanumeric characters and hyphens"
  }
}

# Requirement: Container Orchestration - Environment Specification
variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Environment must be production, staging, or development"
  }
}

# Requirement: Container Orchestration - Kubernetes Version
variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.24"
  validation {
    condition     = can(regex("^1\\.(2[4-9]|3[0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.24 or higher"
  }
}

# Requirement: High Availability - Network Configuration
variable "vpc_id" {
  description = "ID of the VPC where EKS cluster will be deployed"
  type        = string
  validation {
    condition     = can(regex("^vpc-[a-f0-9]{8,17}$", var.vpc_id))
    error_message = "VPC ID must be a valid AWS VPC identifier"
  }
}

# Requirement: High Availability - Multi-AZ Configuration
variable "subnet_ids" {
  description = "List of subnet IDs for EKS cluster nodes, spanning multiple availability zones"
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2 && alltrue([for s in var.subnet_ids : can(regex("^subnet-[a-f0-9]{8,17}$", s))])
    error_message = "At least 2 valid subnet IDs are required for high availability"
  }
}

# Requirement: Container Orchestration - Node Group Configuration
variable "node_groups_config" {
  description = "Map of EKS node group configurations with instance types and scaling parameters"
  type = map(object({
    instance_types = list(string)
    desired_size   = number
    min_size      = number
    max_size      = number
    disk_size     = optional(number)
    labels        = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
  }))
  default = {
    default_node_group = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size      = 1
      max_size      = 4
      disk_size     = 50
    }
  }
  validation {
    condition     = alltrue([for ng in var.node_groups_config : ng.min_size <= ng.desired_size && ng.desired_size <= ng.max_size && (ng.disk_size == null || ng.disk_size >= 20)])
    error_message = "Node group sizes must satisfy: min_size <= desired_size <= max_size, and disk size must be at least 20GB if specified"
  }
}

# Requirement: Security Infrastructure - Network Access Configuration
variable "cluster_endpoint_private_access" {
  description = "Enable private API server endpoint access"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public API server endpoint access"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
  validation {
    condition     = alltrue([for cidr in var.cluster_endpoint_public_access_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All values must be valid CIDR blocks"
  }
}

# Requirement: Security Infrastructure - IAM Configuration
variable "enable_irsa" {
  description = "Enable IAM roles for service accounts"
  type        = bool
  default     = true
}

# Requirement: Container Orchestration - Resource Tagging
variable "tags" {
  description = "Additional tags for EKS cluster resources"
  type        = map(string)
  default     = {}
}