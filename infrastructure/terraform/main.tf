# Human Tasks:
# 1. Review and validate AWS credentials and permissions
# 2. Verify VPC CIDR ranges and subnet allocations
# 3. Confirm RDS backup retention periods meet compliance requirements
# 4. Review ElastiCache cluster sizing for production workload
# 5. Validate S3 bucket naming convention and policies
# 6. Configure monitoring alert endpoints in monitoring_config variable

# Required Provider Versions
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws" # ~> 4.0
      version = "~> 4.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes" # ~> 2.0
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm" # ~> 2.0
      version = "~> 2.0"
    }
  }
}

# Requirement: Infrastructure Architecture - Provider Configuration
provider "aws" {
  region = var.aws_region
}

# Requirement: Container Orchestration - Kubernetes Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Requirement: Container Orchestration - Helm Provider
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

# Requirement: Infrastructure Architecture - Project Globals
locals {
  project_name = "mint-replica-lite"
  common_tags = {
    Project     = "mint-replica-lite"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Requirement: Production Environment Infrastructure - Data Sources
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

# Requirement: Production Environment Infrastructure - VPC Module
module "vpc" {
  source = "./modules/vpc"

  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
}

# Requirement: Production Environment Infrastructure - EKS Module
module "eks" {
  source = "./modules/eks"

  cluster_name        = "${local.project_name}-${var.environment}"
  kubernetes_version  = var.kubernetes_config.cluster_version
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.private_subnet_ids
  node_groups_config = var.kubernetes_config.node_groups
  environment        = var.environment
}

# Requirement: Production Environment Infrastructure - RDS Module
module "rds" {
  source = "./modules/rds"

  instance_config = var.rds_config
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.database_subnet_ids
  environment    = var.environment
}

# Requirement: Production Environment Infrastructure - ElastiCache Module
module "elasticache" {
  source = "./modules/redis"

  cluster_config = var.elasticache_config
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.database_subnet_ids
  environment   = var.environment
}

# Requirement: Production Environment Infrastructure - S3 Module
module "s3" {
  source = "./modules/s3"

  bucket_config = var.s3_config
  environment  = var.environment
}

# Requirement: Infrastructure Architecture - Outputs
output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "rds_endpoint" {
  description = "Endpoint for RDS instance"
  value       = module.rds.endpoint
}

output "elasticache_endpoint" {
  description = "Endpoint for ElastiCache cluster"
  value       = module.elasticache.endpoint
}

output "s3_bucket_name" {
  description = "Name of created S3 bucket"
  value       = module.s3.bucket_name
}