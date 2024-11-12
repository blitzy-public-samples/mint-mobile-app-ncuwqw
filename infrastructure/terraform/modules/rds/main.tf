# Provider version requirements
# hashicorp/aws ~> 4.0
# hashicorp/random ~> 3.0

# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate permissions for RDS management
# 2. Configure subnet groups in multiple AZs for high availability
# 3. Review and adjust parameter group settings based on workload requirements
# 4. Set up AWS KMS key for RDS encryption if using custom key management
# 5. Configure CloudWatch alarms for RDS monitoring metrics

# Generate random password for RDS instance
# Requirement: Database Security - Secure password management
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Create RDS primary instance
# Requirement: Primary Database Infrastructure - PostgreSQL deployment
resource "aws_db_instance" "primary" {
  identifier = "${var.environment}-mintreplica-postgres"
  engine     = "postgres"
  # Using PostgreSQL 13.7 as specified in requirements
  engine_version = "13.7"

  # Instance configuration
  instance_class        = var.rds_config.instance_class
  allocated_storage     = var.rds_config.allocated_storage
  max_allocated_storage = var.rds_config.allocated_storage * 2

  # High availability configuration
  # Requirement: Database High Availability - Multi-AZ deployment
  multi_az = var.rds_config.multi_az

  # Database configuration
  db_name  = "mintreplica"
  username = "mintadmin"
  password = random_password.db_password.result

  # Backup configuration
  backup_retention_period = var.backup_retention_period
  
  # Monitoring configuration
  # Requirement: Database Monitoring - Enhanced monitoring and CloudWatch integration
  monitoring_interval = var.monitoring_interval
  enabled_cloudwatch_logs_exports = [
    "postgresql",
    "upgrade"
  ]
  performance_insights_enabled = true

  # Security configuration
  # Requirement: Database Security - Encryption at rest
  storage_encrypted = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  # Tags
  tags = var.tags
}

# Create security group for RDS
# Requirement: Database Security - Network security and access controls
resource "aws_security_group" "rds" {
  name   = "${var.environment}-mintreplica-rds-sg"
  vpc_id = var.vpc_id

  # Inbound rule for PostgreSQL access
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Outbound rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

# Create RDS read replica
# Requirement: Primary Database Infrastructure - Read replicas for scalability
resource "aws_db_instance" "replica" {
  identifier = "${var.environment}-mintreplica-postgres-replica"
  
  # Instance configuration
  instance_class = var.rds_config.instance_class
  
  # Replication configuration
  replicate_source_db = aws_db_instance.primary.id
  
  # High availability configuration
  multi_az = false  # Read replicas are single-AZ by design
  
  # Monitoring configuration
  monitoring_interval = var.monitoring_interval
  
  # Security configuration
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Tags
  tags = var.tags
  
  # Only create replica in production environment
  count = var.environment == "production" ? 1 : 0
}

# Output values
output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.primary.endpoint
}

output "rds_replica_endpoint" {
  description = "The connection endpoint for the RDS read replica"
  value       = var.environment == "production" ? aws_db_instance.replica[0].endpoint : ""
}

output "db_name" {
  description = "The name of the default database"
  value       = aws_db_instance.primary.db_name
}