# Human Tasks:
# 1. Verify AWS credentials and region configuration
# 2. Review node group instance types for cost optimization
# 3. Validate backup retention periods for compliance
# 4. Ensure monitoring and alerting thresholds are appropriate
# 5. Review security group configurations

# Required Provider Versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws" # ~> 4.0
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" # ~> 2.0
      version = "~> 2.0"
    }
  }

  # Requirement: Infrastructure as Code - Remote State Management
  backend "s3" {
    bucket  = "mint-replica-lite-tfstate-staging"
    key     = "staging/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# Requirement: Cloud Infrastructure - Environment Configuration
locals {
  environment = "staging"
  region     = "us-west-2"
  tags = {
    Environment = "staging"
    Project     = "mint-replica-lite"
    ManagedBy   = "terraform"
  }
}

# Configure AWS Provider
provider "aws" {
  region = local.region
}

# Requirement: Staging Environment Infrastructure - EKS Configuration
module "eks" {
  source = "../../modules/eks"

  environment      = local.environment
  cluster_version  = "1.24"
  node_groups = {
    default = {
      desired_size   = 2
      min_size      = 2
      max_size      = 2
      instance_types = ["t3.medium"]
    }
  }
  tags = local.tags
}

# Requirement: Cloud Infrastructure - RDS Configuration
module "rds" {
  source = "../../modules/rds"

  environment              = local.environment
  rds_config = {
    instance_class     = "db.t3.medium"
    allocated_storage  = 50
    multi_az          = false
  }
  backup_retention_period = 7
  monitoring_interval    = 60
  tags                  = local.tags
}

# Requirement: Cloud Infrastructure - Redis Configuration
module "redis" {
  source = "../../modules/redis"

  environment           = local.environment
  node_type            = "cache.t3.medium"
  num_cache_nodes      = 1
  automatic_failover   = false
  parameter_group_family = "redis6.x"
  tags                 = local.tags
}

# Requirement: Cloud Infrastructure - S3 Configuration
module "s3" {
  source = "../../modules/s3"

  environment = local.environment
  s3_config = {
    bucket_name = "mint-replica-lite"
    versioning  = true
    lifecycle_rules = []
  }
  encryption_config = {
    sse_algorithm     = "AES256"
    kms_master_key_id = null
  }
  tags = local.tags
}

# Outputs for use by other configurations
output "eks_cluster_id" {
  description = "EKS cluster identifier for staging environment"
  value       = module.eks.cluster_id
}

output "rds_endpoint" {
  description = "RDS primary endpoint for staging environment"
  value       = module.rds.rds_endpoint
}

output "redis_endpoint" {
  description = "Redis endpoint for staging environment"
  value       = "${module.redis.cluster_id}.${module.redis.configuration_endpoint}:${module.redis.port}"
}

output "s3_bucket_id" {
  description = "S3 bucket identifier for staging environment"
  value       = module.s3.bucket_id
}