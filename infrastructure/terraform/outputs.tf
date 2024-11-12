# Human Tasks:
# 1. Verify that no sensitive information is exposed through these outputs
# 2. Confirm that all required outputs are available for dependent services
# 3. Validate that output values match expected formats for service configurations

# Requirement: Production Environment Infrastructure - VPC Outputs
output "vpc_id" {
  description = "ID of the created VPC for network reference"
  value       = module.vpc.vpc_id
  sensitive   = false
}

output "vpc_private_subnet_ids" {
  description = "List of private subnet IDs for service deployment"
  value       = module.vpc.private_subnet_ids
  sensitive   = false
}

# Requirement: Cloud Services Integration - EKS Cluster Outputs
output "eks_cluster_endpoint" {
  description = "Endpoint URL for EKS cluster access"
  value       = module.eks.cluster_endpoint
  sensitive   = false
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster for reference"
  value       = module.eks.cluster_id
  sensitive   = false
}

# Requirement: Cloud Services Integration - RDS Database Outputs
output "rds_endpoint" {
  description = "Connection endpoint for PostgreSQL RDS instance"
  value       = module.rds.endpoint
  sensitive   = false
}

output "rds_port" {
  description = "Port number for PostgreSQL RDS instance"
  value       = module.rds.port
  sensitive   = false
}

# Requirement: Cloud Services Integration - ElastiCache Outputs
output "elasticache_endpoint" {
  description = "Connection endpoint for Redis ElastiCache cluster"
  value       = module.elasticache.endpoint
  sensitive   = false
}

output "elasticache_port" {
  description = "Port number for Redis ElastiCache cluster"
  value       = module.elasticache.port
  sensitive   = false
}

# Requirement: Cloud Services Integration - S3 Storage Outputs
output "s3_bucket_name" {
  description = "Name of the created S3 bucket for object storage"
  value       = module.s3.bucket_name
  sensitive   = false
}

# Requirement: Infrastructure Architecture - CloudFront Outputs
output "cloudfront_distribution_id" {
  description = "ID of CloudFront distribution for CDN"
  value       = module.cloudfront.distribution_id
  sensitive   = false
}

output "cloudfront_domain_name" {
  description = "Domain name of CloudFront distribution"
  value       = module.cloudfront.domain_name
  sensitive   = false
}