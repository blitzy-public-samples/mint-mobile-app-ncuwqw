# Human Tasks:
# 1. Verify AWS credentials and access permissions for production environment
# 2. Review and validate VPC configuration and subnet allocations
# 3. Confirm KMS key permissions for encryption configurations
# 4. Verify DNS and domain configurations for service endpoints
# 5. Review backup retention policies compliance with business requirements

# Required Provider Versions
# hashicorp/aws ~> 4.0
# hashicorp/kubernetes ~> 2.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }

  # Requirement: Infrastructure as Code - Remote State Management
  backend "s3" {
    bucket  = "mint-replica-lite-tfstate"
    key     = "production/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# Configure AWS Provider
provider "aws" {
  region = local.region
}

# Local variables
locals {
  environment = "production"
  region     = "us-west-2"
  tags = {
    Environment = "production"
    Project     = "mint-replica-lite"
    ManagedBy   = "terraform"
  }
}

# Requirement: Production Environment Infrastructure - EKS Cluster
module "eks" {
  source = "../../modules/eks"

  environment = local.environment
  cluster_version = "1.24"
  node_groups = {
    general = {
      instance_types = ["t3.large"]
      scaling_config = {
        desired_size = 3
        min_size     = 2
        max_size     = 20
      }
    }
  }
  tags = local.tags
}

# Requirement: Production Environment Infrastructure - RDS Database
module "rds" {
  source = "../../modules/rds"

  environment              = local.environment
  instance_class          = "db.r6g.xlarge"
  allocated_storage       = 100
  multi_az               = true
  backup_retention_period = 30
  monitoring_interval    = 60
  tags                   = local.tags
}

# Requirement: Production Environment Infrastructure - Redis Cache
module "redis" {
  source = "../../modules/redis"

  environment            = local.environment
  node_type             = "cache.r6g.large"
  num_cache_nodes       = 3
  automatic_failover    = true
  parameter_group_family = "redis6.x"
  tags                  = local.tags
}

# Requirement: Production Environment Infrastructure - S3 Storage
module "s3" {
  source = "../../modules/s3"

  environment = local.environment
  s3_config = {
    versioning = true
    replication_enabled = true
    lifecycle_rules = [
      {
        id = "archive_old_objects"
        status = "Enabled"
        transition = {
          days = 90
          storage_class = "GLACIER"
        }
      }
    ]
  }
  encryption_config = {
    sse_algorithm = "aws:kms"
    kms_master_key_id = "alias/mint-replica-s3-key"
  }
  tags = local.tags
}

# Outputs
output "vpc_id" {
  description = "VPC identifier for network configuration"
  value       = module.eks.vpc_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint URL"
  value       = module.eks.cluster_endpoint
}

output "rds_primary_endpoint" {
  description = "Primary RDS instance endpoint"
  value       = module.rds.rds_endpoint
}

output "redis_endpoint" {
  description = "Redis cluster endpoint"
  value       = module.redis.configuration_endpoint
}