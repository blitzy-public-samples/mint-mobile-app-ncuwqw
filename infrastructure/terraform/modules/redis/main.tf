# AWS Provider version: ~> 4.0
# Addresses requirements from:
# - Cache Infrastructure (2.1 High-Level Architecture Overview)
# - High Availability (2.5.4 Availability Architecture)
# - Security Requirements (6.2 Data Security)

# Human Tasks:
# 1. Ensure AWS provider is configured with appropriate credentials and region
# 2. Verify VPC and subnet configurations are properly set up for Redis deployment
# 3. Review and adjust the default node type based on production workload requirements
# 4. Configure appropriate security group rules for Redis access
# 5. Set up monitoring and alerting for Redis metrics in CloudWatch

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = var.tags
  }
}

# Create ElastiCache subnet group for multi-AZ deployment
# Addresses: High Availability requirement
resource "aws_elasticache_subnet_group" "redis_subnet_group" {
  name        = "redis-${var.environment}-subnet-group"
  description = "Subnet group for Redis cluster in ${var.environment} environment"
  subnet_ids  = var.subnet_ids
}

# Create Redis parameter group for custom configurations
# Addresses: Security Requirements and Cache Infrastructure requirements
resource "aws_elasticache_parameter_group" "redis_params" {
  family      = var.parameter_group_family
  name        = "redis-${var.environment}-params"
  description = "Redis parameter group for ${var.environment} environment"

  # Security parameters
  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }

  parameter {
    name  = "notify-keyspace-events"
    value = "Ex"
  }
}

# Create security group for Redis cluster
# Addresses: Security Requirements
resource "aws_security_group" "redis_sg" {
  name        = "redis-${var.environment}-sg"
  description = "Security group for Redis cluster in ${var.environment} environment"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis port"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "redis-${var.environment}-sg"
    }
  )
}

# Lookup VPC details
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Create Redis cluster
# Addresses: Cache Infrastructure and High Availability requirements
resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = "redis-${var.environment}"
  engine              = "redis"
  node_type           = var.node_type
  num_cache_nodes     = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.redis_params.name
  port                = 6379
  subnet_group_name   = aws_elasticache_subnet_group.redis_subnet_group.name
  security_group_ids  = [aws_security_group.redis_sg.id]

  # Enable encryption at rest and in transit
  # Addresses: Security Requirements
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  # Enable automatic failover for high availability
  # Addresses: High Availability requirement
  automatic_failover_enabled = var.automatic_failover

  # Maintenance window (adjust as needed)
  maintenance_window = "sun:05:00-sun:06:00"
  
  # Backup configuration
  snapshot_retention_limit = 7
  snapshot_window         = "03:00-04:00"

  # Apply tags
  tags = merge(
    var.tags,
    {
      Name = "redis-${var.environment}"
    }
  )

  # Advanced configurations
  apply_immediately = true
  engine_version    = "6.x"  # Latest stable version
  
  # Enable CloudWatch monitoring
  # Addresses: Cache Infrastructure monitoring requirements
  notification_topic_arn = null  # Optional: Add SNS topic ARN for notifications

  lifecycle {
    prevent_destroy = true  # Prevent accidental deletion in production
  }
}

# Create CloudWatch alarms for Redis monitoring
resource "aws_cloudwatch_metric_alarm" "redis_cpu" {
  alarm_name          = "redis-${var.environment}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = "75"
  alarm_description  = "Redis cluster CPU utilization"
  alarm_actions      = []  # Add SNS topic ARN for notifications

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis_cluster.id
  }
}

resource "aws_cloudwatch_metric_alarm" "redis_memory" {
  alarm_name          = "redis-${var.environment}-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "DatabaseMemoryUsagePercentage"
  namespace          = "AWS/ElastiCache"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "Redis cluster memory utilization"
  alarm_actions      = []  # Add SNS topic ARN for notifications

  dimensions = {
    CacheClusterId = aws_elasticache_cluster.redis_cluster.id
  }
}