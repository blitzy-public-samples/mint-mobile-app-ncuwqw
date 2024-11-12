# Backup and Restore Procedures for Mint Replica Lite

<!-- Human Tasks:
1. Verify AWS IAM roles and permissions for S3 bucket access
2. Ensure encryption keys are securely stored in HashiCorp Vault
3. Configure monitoring alerts for backup/restore operations
4. Set up cross-region replication for S3 buckets
5. Validate backup retention policies with compliance team
6. Test restore procedures in staging environment
7. Document emergency contacts for critical failures -->

## Overview

### Purpose and Scope
<!-- Addresses requirement: Database Backup (2.5.1 Production Environment/Database) -->
This runbook provides comprehensive procedures for backing up and restoring Mint Replica Lite's database, application state, and infrastructure components. The procedures ensure data integrity, security, and business continuity.

### Prerequisites
- PostgreSQL Client 14.x
- AWS CLI v2
- OpenSSL 3.x
- Configured S3 buckets with versioning
- Encryption keys and credentials
- Sufficient storage capacity
- Required IAM permissions

### Security Considerations
<!-- Addresses requirement: Data Security (6.2 Data Security/Encryption Implementation) -->
- AES-256-CBC encryption for backup files
- TLS 1.3 for data transfer
- AWS KMS for key management
- Field-level encryption
- Secure backup handling
- Access control policies

## Backup Procedures

### Automated Daily Backups
<!-- Addresses requirement: Database Backup (2.5.1 Production Environment/Database) -->
1. Schedule:
   ```bash
   # Add to crontab
   0 1 * * * /infrastructure/scripts/backup-db.sh \
     --host $DB_HOST \
     --db mint_replica \
     --user $DB_USER
   ```

2. Backup Types:
   - Full database dumps (daily)
   - Incremental backups (every 6 hours)
   - Transaction logs (continuous)
   - Configuration backups (weekly)

### Manual Backup Process
```bash
# Execute manual backup
./backup-db.sh \
  --host <database_host> \
  --db mint_replica \
  --user <database_user>
```

### Backup Verification
1. Integrity Checks:
   - Database consistency
   - Backup file checksums
   - Encryption verification
   - Upload confirmation

2. Validation Steps:
   ```bash
   # Verify backup integrity
   pg_restore --list /tmp/db-backups/backup_file.sql
   
   # Verify checksum
   sha256sum -c backup_file.sha256
   ```

### Backup Retention Policy
<!-- Addresses requirement: Database Backup (2.5.1 Production Environment/Database) -->
- Daily backups: 30 days
- Weekly backups: 90 days
- Monthly backups: 365 days
- Yearly backups: 7 years

## Restore Procedures

### Listing Available Backups
```bash
# List available backups
./restore-db.sh --list

# Example output:
# 2024-01-20 01:00:00 | 1.2GB | mint_replica_20240120_010000.sql.gz.enc
```

### Backup Selection Criteria
1. Recovery Point Objective (RPO):
   - Production: 1 hour
   - Staging: 24 hours
   - Development: 48 hours

2. Selection Factors:
   - Timestamp
   - Data consistency
   - Backup type
   - Environment requirements

### Restoration Process
<!-- Addresses requirement: Disaster Recovery (2.5.4 Availability Architecture) -->
1. Pre-restore Checks:
   ```bash
   # Verify target environment
   psql -h $DB_HOST -U $DB_USER -c "\l"
   
   # Check storage space
   df -h /tmp/db-restores
   ```

2. Execute Restore:
   ```bash
   ./restore-db.sh \
     --host <database_host> \
     --db mint_replica \
     --user <database_user> \
     --backup <backup_name>
   ```

### Post-Restore Validation
1. Data Integrity:
   - Table count verification
   - Sample data validation
   - Application connectivity
   - Performance metrics

2. Validation Queries:
   ```sql
   -- Check table counts
   SELECT COUNT(*) FROM information_schema.tables;
   
   -- Verify recent data
   SELECT MAX(created_at) FROM transactions;
   ```

## Emergency Recovery Procedures

### Emergency Response Steps
<!-- Addresses requirement: Disaster Recovery (2.5.4 Availability Architecture) -->
1. Initial Assessment:
   - Identify failure scope
   - Document incident time
   - Notify stakeholders
   - Initiate recovery plan

2. Critical Service Recovery:
   - Database restoration
   - Application services
   - Infrastructure components
   - External integrations

### Data Recovery Priority
1. High Priority:
   - User authentication data
   - Transaction records
   - Financial data
   - System configurations

2. Medium Priority:
   - Historical records
   - Analytics data
   - Audit logs
   - Cached content

### Service Restoration
1. Recovery Order:
   - Database services
   - Core application
   - API services
   - Background jobs
   - Monitoring systems

2. Verification Steps:
   - Service health checks
   - Data consistency
   - Performance metrics
   - User access

## Security Measures

### Encryption Standards
<!-- Addresses requirement: Data Security (6.2 Data Security/Encryption Implementation) -->
- Backup files: AES-256-CBC
- Data transfer: TLS 1.3
- Key management: AWS KMS
- Field-level: Application-specific

### Access Controls
1. AWS IAM Policies:
   - Backup creation
   - S3 bucket access
   - KMS key usage
   - Restore operations

2. Database Permissions:
   - Backup user roles
   - Restore privileges
   - Monitoring access
   - Audit logging

### Key Management
1. Encryption Keys:
   - Rotation schedule
   - Access policies
   - Storage location
   - Backup procedures

2. AWS KMS Configuration:
   - Key aliases
   - Usage monitoring
   - Permission boundaries
   - Cross-region setup

### Audit Logging
1. Logged Operations:
   - Backup creation
   - Restore attempts
   - Access patterns
   - Key usage

2. Log Retention:
   - Backup logs: 90 days
   - Restore logs: 90 days
   - Access logs: 365 days
   - Audit trails: 7 years

## Local Troubleshooting Guide

### Backup Issues
1. Database Connection Failures:
   ```bash
   # Check connectivity
   pg_isready -h $DB_HOST -p 5432
   
   # Verify credentials
   psql -h $DB_HOST -U $DB_USER -d postgres -c "\conninfo"
   ```

2. Storage Space Issues:
   ```bash
   # Check available space
   df -h /tmp/db-backups
   
   # Clean old backups
   find /tmp/db-backups -mtime +30 -delete
   ```

### Restore Issues
1. Backup File Corruption:
   ```bash
   # Verify file integrity
   openssl dgst -sha256 backup_file.enc
   
   # Test decryption
   openssl enc -d -aes-256-cbc -in backup_file.enc
   ```

2. Permission Problems:
   ```bash
   # Check file permissions
   ls -l /tmp/db-restores
   
   # Verify database privileges
   psql -h $DB_HOST -U $DB_USER -c "\du"
   ```

### Resolution Steps
1. Diagnostic Commands:
   ```bash
   # Check PostgreSQL logs
   tail -f /var/log/postgresql/postgresql.log
   
   # Monitor backup process
   tail -f /var/log/mint-replica-lite/db-backups.log
   ```

2. Common Fixes:
   - Clear temporary files
   - Restart backup services
   - Verify network connectivity
   - Update credentials