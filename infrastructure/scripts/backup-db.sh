#!/bin/bash

# Human Tasks:
# 1. Ensure PostgreSQL client tools (version 14.x) are installed
# 2. Install AWS CLI v2 and configure with appropriate IAM role
# 3. Install OpenSSL 3.x
# 4. Create and configure the encryption key at /etc/mint-replica-lite/backup-key.pem
# 5. Set up S3 bucket with versioning and cross-region replication
# 6. Configure proper file permissions for log directory
# 7. Set up monitoring for the backup log file

# External dependencies versions:
# postgresql-client: 14.x
# aws-cli: 2.x
# openssl: 3.x

# Global variables
BACKUP_DIR="/tmp/db-backups"
S3_BUCKET="s3://mint-replica-lite-backups"
RETENTION_DAYS=30
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ENCRYPTION_KEY_PATH="/etc/mint-replica-lite/backup-key.pem"
LOG_FILE="/var/log/mint-replica-lite/db-backups.log"

# Function to log messages with timestamp and severity
# Addresses requirement: Error handling with comprehensive logging
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [[ "$level" == "ERROR" ]]; then
        echo "[$timestamp] [$level] $message" >&2
    else
        echo "[$timestamp] [$level] $message"
    fi
    
    # Rotate log if it exceeds 100MB
    if [[ -f "$LOG_FILE" && $(stat -f%z "$LOG_FILE") -gt 104857600 ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.1"
        touch "$LOG_FILE"
        chmod 0640 "$LOG_FILE"
    fi
}

# Function to check all required dependencies
# Addresses requirement: Dependency verification for reliable operation
check_dependencies() {
    log_message "INFO" "Checking dependencies..."
    
    # Check PostgreSQL client
    if ! command -v pg_dump >/dev/null || ! pg_dump --version | grep -q "14."; then
        log_message "ERROR" "PostgreSQL client 14.x is required but not found"
        return 1
    fi
    
    # Check AWS CLI
    if ! command -v aws >/dev/null || ! aws --version | grep -q "aws-cli/2"; then
        log_message "ERROR" "AWS CLI version 2 is required but not found"
        return 1
    fi
    
    # Check OpenSSL
    if ! command -v openssl >/dev/null || ! openssl version | grep -q "OpenSSL 3."; then
        log_message "ERROR" "OpenSSL 3.x is required but not found"
        return 1
    }
    
    # Verify AWS credentials and S3 bucket access
    if ! aws s3 ls "$S3_BUCKET" >/dev/null 2>&1; then
        log_message "ERROR" "Cannot access S3 bucket $S3_BUCKET"
        return 1
    fi
    
    # Check encryption key
    if [[ ! -f "$ENCRYPTION_KEY_PATH" ]]; then
        log_message "ERROR" "Encryption key not found at $ENCRYPTION_KEY_PATH"
        return 1
    fi
    
    # Verify encryption key permissions
    if [[ $(stat -f%p "$ENCRYPTION_KEY_PATH") != "100600" ]]; then
        log_message "ERROR" "Incorrect permissions on encryption key file"
        return 1
    fi
    
    log_message "INFO" "All dependencies verified successfully"
    return 0
}

# Function to create encrypted database backup
# Addresses requirements: Database Backup and Disaster Recovery
create_backup() {
    local db_host=$1
    local db_name=$2
    local db_user=$3
    local db_port=$4
    
    log_message "INFO" "Starting backup for database $db_name"
    
    # Create backup directory with secure permissions
    mkdir -p "$BACKUP_DIR"
    chmod 0700 "$BACKUP_DIR"
    
    local backup_file="${BACKUP_DIR}/${db_name}_${TIMESTAMP}.sql"
    local compressed_file="${backup_file}.gz"
    local encrypted_file="${compressed_file}.enc"
    local checksum_file="${encrypted_file}.sha256"
    
    # Create consistent backup with compression
    if ! PGPASSWORD="$DB_PASSWORD" pg_dump \
        -h "$db_host" \
        -U "$db_user" \
        -p "$db_port" \
        -d "$db_name" \
        --format=custom \
        --compress=9 \
        --verbose \
        --file="$backup_file" \
        --no-owner \
        --no-acl; then
        log_message "ERROR" "Database backup failed for $db_name"
        return 1
    fi
    
    # Verify backup integrity
    if ! pg_restore --list "$backup_file" >/dev/null 2>&1; then
        log_message "ERROR" "Backup verification failed for $db_name"
        rm -f "$backup_file"
        return 1
    fi
    
    # Compress backup
    if ! gzip -9 "$backup_file"; then
        log_message "ERROR" "Backup compression failed"
        rm -f "$backup_file"
        return 1
    fi
    
    # Calculate checksum
    sha256sum "$compressed_file" > "$checksum_file"
    
    # Encrypt backup using AES-256-CBC
    if ! openssl enc -aes-256-cbc \
        -salt \
        -in "$compressed_file" \
        -out "$encrypted_file" \
        -pass file:"$ENCRYPTION_KEY_PATH"; then
        log_message "ERROR" "Backup encryption failed"
        rm -f "$compressed_file" "$checksum_file"
        return 1
    fi
    
    # Clean up unencrypted files
    rm -f "$compressed_file"
    
    log_message "INFO" "Backup created successfully: $encrypted_file"
    echo "$encrypted_file"
    return 0
}

# Function to upload backup to S3 with versioning
# Addresses requirement: Cross-region backup for disaster recovery
upload_to_s3() {
    local backup_file=$1
    local s3_path=$2
    
    log_message "INFO" "Uploading backup to S3: $s3_path"
    
    # Verify backup file exists
    if [[ ! -f "$backup_file" ]]; then
        log_message "ERROR" "Backup file not found: $backup_file"
        return 1
    fi
    
    # Upload file with server-side encryption and metadata
    if ! aws s3 cp "$backup_file" "$s3_path" \
        --storage-class STANDARD_IA \
        --server-side-encryption aws:kms \
        --metadata "timestamp=${TIMESTAMP}" \
        --only-show-errors; then
        log_message "ERROR" "S3 upload failed for $backup_file"
        return 1
    fi
    
    # Upload checksum file
    if ! aws s3 cp "${backup_file}.sha256" "${s3_path}.sha256" \
        --storage-class STANDARD_IA \
        --server-side-encryption aws:kms \
        --only-show-errors; then
        log_message "WARNING" "Failed to upload checksum file"
    fi
    
    # Verify upload with ETag
    if ! aws s3api head-object \
        --bucket "${S3_BUCKET#s3://}" \
        --key "${s3_path#${S3_BUCKET}/}" >/dev/null 2>&1; then
        log_message "ERROR" "Upload verification failed"
        return 1
    fi
    
    log_message "INFO" "Backup uploaded successfully to S3"
    return 0
}

# Function to clean up old backups
# Addresses requirement: Backup retention management
cleanup_old_backups() {
    local days=$1
    
    log_message "INFO" "Starting cleanup of backups older than $days days"
    
    # Clean local backups
    find "$BACKUP_DIR" -type f -mtime "+$days" -exec rm -f {} \;
    
    # Clean S3 backups
    local cutoff_date=$(date -v-${days}d +%Y-%m-%d)
    
    aws s3api list-objects-v2 \
        --bucket "${S3_BUCKET#s3://}" \
        --query "Contents[?LastModified<='${cutoff_date}'].Key" \
        --output text | \
    while read -r key; do
        if [[ -n "$key" ]]; then
            aws s3 rm "${S3_BUCKET}/${key}" --only-show-errors
            log_message "INFO" "Removed old S3 backup: $key"
        fi
    done
    
    log_message "INFO" "Cleanup completed"
    return 0
}

# Main execution function
# Addresses requirements: Comprehensive backup workflow
main() {
    log_message "INFO" "Starting database backup process"
    
    # Check dependencies first
    if ! check_dependencies; then
        log_message "ERROR" "Dependency check failed"
        return 1
    fi
    
    # Parse command line arguments
    local db_host="$1"
    local db_name="$2"
    local db_user="$3"
    local db_port="${4:-5432}"
    
    if [[ -z "$db_host" || -z "$db_name" || -z "$db_user" ]]; then
        log_message "ERROR" "Missing required parameters"
        echo "Usage: $0 <db_host> <db_name> <db_user> [db_port]"
        return 1
    fi
    
    # Create backup
    local backup_file
    backup_file=$(create_backup "$db_host" "$db_name" "$db_user" "$db_port")
    if [[ $? -ne 0 || -z "$backup_file" ]]; then
        log_message "ERROR" "Backup creation failed"
        return 1
    fi
    
    # Upload to S3
    local s3_path="${S3_BUCKET}/${db_name}/${TIMESTAMP}/"
    if ! upload_to_s3 "$backup_file" "$s3_path"; then
        log_message "ERROR" "S3 upload failed"
        return 1
    fi
    
    # Cleanup old backups
    if ! cleanup_old_backups "$RETENTION_DAYS"; then
        log_message "WARNING" "Cleanup process failed"
    fi
    
    log_message "INFO" "Backup process completed successfully"
    return 0
}

# Execute main function with all arguments
main "$@"