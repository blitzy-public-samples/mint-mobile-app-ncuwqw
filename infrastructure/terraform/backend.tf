# Human Tasks:
# 1. Ensure AWS credentials are properly configured with permissions for S3 and DynamoDB access
# 2. Verify S3 bucket and DynamoDB table are created before initializing Terraform
# 3. Review IAM policies to ensure proper access controls for state management
# 4. Confirm encryption keys and policies are properly configured in AWS KMS
# 5. Validate workspace naming conventions with team standards

# AWS Provider version: hashicorp/aws ~> 4.0

# Requirement: Infrastructure as Code (2.5.2 Deployment Architecture)
# Configures Terraform backend to store state in AWS S3 with DynamoDB locking
terraform {
  # Requirement: Security Architecture (6.2 Data Security/6.2.1 Encryption Implementation)
  # Implements server-side encryption for state files and secure access controls
  backend "s3" {
    # State file storage configuration
    bucket = "mint-replica-lite-${var.environment}-terraform-state"
    key    = "terraform.tfstate"
    region = "us-west-2"

    # Requirement: Security Architecture - Enable encryption for state files
    encrypt = true

    # Requirement: High Availability (2.5.4 Availability Architecture)
    # DynamoDB table for state locking to prevent concurrent modifications
    dynamodb_table = "mint-replica-lite-${var.environment}-terraform-locks"

    # Requirement: Multi-Environment Support (7.1 Deployment Environment)
    # Workspace-based state isolation for different environments
    workspace_key_prefix = "env"
  }
}

# Note: This backend configuration implements the following security features:
# - Server-side encryption (SSE) for state files in S3
# - State locking using DynamoDB to prevent concurrent modifications
# - Workspace isolation for environment separation
# - IAM-based access control (configured externally)
# - S3 versioning (configured on the bucket)

# State file path format: env/{workspace_name}/terraform.tfstate
# Example: env/production/terraform.tfstate