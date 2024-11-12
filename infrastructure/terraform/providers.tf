# Human Tasks:
# 1. Ensure AWS credentials are properly configured in the deployment environment
# 2. Verify EKS cluster name is correctly specified in the data source blocks
# 3. Review and adjust provider version constraints based on feature requirements
# 4. Confirm AWS region selection aligns with latency and compliance requirements

# Requirement: Infrastructure as Code (2.5.2 Deployment Architecture)
# Configures Terraform and required providers with strict version constraints
terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    # Requirement: Cloud Infrastructure Provider (7.2 Cloud Services)
    aws = {
      source  = "hashicorp/aws"  # hashicorp/aws ~> 4.0
      version = "~> 4.0"
    }
    
    kubernetes = {
      source  = "hashicorp/kubernetes"  # hashicorp/kubernetes ~> 2.0
      version = "~> 2.0"
    }
    
    random = {
      source  = "hashicorp/random"  # hashicorp/random ~> 3.0
      version = "~> 3.0"
    }
  }
}

# Requirement: Cloud Infrastructure Provider (7.2 Cloud Services)
# Configures AWS provider with region and default resource tagging
provider "aws" {
  region = var.aws_region

  # Requirement: Infrastructure as Code (2.5.2 Deployment Architecture)
  # Implements consistent resource tagging across all AWS resources
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "MintReplicaLite"
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources for EKS cluster configuration
# Required for Kubernetes provider authentication
data "aws_eks_cluster" "cluster" {
  name = "mint-replica-lite-${var.environment}"  # Cluster name follows environment-based naming convention
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}

# Requirement: Multi-Region Support (2.5.4 Availability Architecture)
# Configures Kubernetes provider with EKS cluster authentication
provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

# Configure random provider for generating unique identifiers
provider "random" {
  # No specific configuration needed for random provider
}