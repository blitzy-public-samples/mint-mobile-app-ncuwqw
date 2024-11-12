#!/bin/bash

# Human Tasks:
# 1. Ensure PostgreSQL client tools (version 14.x) are installed
# 2. Configure AWS CLI v2 with appropriate IAM role and permissions
# 3. Install OpenSSL 3.x
# 4. Set BACKUP_DECRYPT_KEY environment variable with the decryption key
# 5. Create log directory with appropriate permissions: /var/log/mint-replica-lite
# 6. Configure monitoring for the restore log file
# 7. Verify S3 bucket access and permissions

# External dependencies versions:
# postgresql-client: 14.x
# aws-cli: 2.x
# openssl: 3.x

# Import shared configuration
source "$(dirname "$0")/backup-db.sh"

# Global variables
RESTORE_DIR="/tmp/db-restores"
S3_BUCKET="s3://mint-replica-lite-backups"
DECRYPT_KEY_ENV="BACKUP_DECRYPT_KEY"
LOG_FILE="/var/log/mint-replica-lite/db-restore.log"

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
}

# Function to check all required dependencies
# Addresses requirement: Dependency verification for reliable operation
check_dependencies() {
    log_message "INFO" "Checking dependencies..."
    
    # Check PostgreSQL client
    if ! command -v pg_restore >/dev/null || ! pg_restore --version | grep -q "14."; then
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
    fi
    
    # Verify AWS credentials and S3 bucket access
    if ! aws s3 ls "$S3_BUCKET" >/dev/null 2>&1; then
        log_message "ERROR" "Cannot access S3 bucket $S3_BUCKET"
        return 1
    fi
    
    # Check decryption key environment variable
    if [[ -z "${!DECRYPT_KEY_ENV}" ]]; then
        log_message "ERROR" "Decryption key environment variable $DECRYPT_KEY_ENV is not set"
        return 1
    fi
    
    log_message "INFO" "All dependencies verified successfully"
    return 0
}

# Function to list available backups
# Addresses requirement: Database Restoration
list_available_backups() {
    log_message "INFO" "Listing available backups from S3..."
    
    # List backups with metadata
    aws s3 ls "$S3_BUCKET" --recursive | \
    grep -E '\.sql\.gz\.enc$' | \
    sort -r | \
    while read -r line; do
        local file_info=($line)
        local date="${file_info[0]} ${file_info[1]}"
        local size="${file_info[2]}"
        local file="${file_info[3]}"
        
        # Get file checksum
        local checksum=$(aws s3api head-object \
            --bucket "${S3_BUCKET#s3://}" \
            --key "$file" \
            --query 'ETag' \
            --output text 2>/dev/null)
        
        echo "$date | $size bytes | $file | checksum: $checksum"
    done
}

# Function to download backup from S3
# Addresses requirement: Data Security
download_backup() {
    local backup_name=$1
    local target_dir=$2
    
    log_message "INFO" "Downloading backup: $backup_name"
    
    # Create target directory with secure permissions
    mkdir -p "$target_dir"
    chmod 0700 "$target_dir"
    
    local target_file="$target_dir/$(basename "$backup_name")"
    
    # Download with retry logic
    local retries=3
    local retry_delay=5
    
    for ((i=1; i<=retries; i++)); do
        if aws s3 cp "${S3_BUCKET}/${backup_name}" "$target_file" --only-show-errors; then
            # Verify download integrity using ETag
            local remote_etag=$(aws s3api head-object \
                --bucket "${S3_BUCKET#s3://}" \
                --key "$backup_name" \
                --query 'ETag' \
                --output text)
            
            local local_md5=$(md5sum "$target_file" | cut -d' ' -f1)
            
            if [[ "\"$local_md5\"" == "$remote_etag" ]]; then
                log_message "INFO" "Backup downloaded successfully"
                echo "$target_file"
                return 0
            else
                log_message "ERROR" "Download integrity check failed"
                rm -f "$target_file"
            fi
        fi
        
        log_message "WARNING" "Download attempt $i failed, retrying in $retry_delay seconds..."
        sleep $retry_delay
    done
    
    log_message "ERROR" "Failed to download backup after $retries attempts"
    return 1
}

# Function to decrypt backup file
# Addresses requirement: Data Security/Encryption Implementation
decrypt_backup() {
    local encrypted_file=$1
    local decryption_key="${!DECRYPT_KEY_ENV}"
    
    log_message "INFO" "Decrypting backup file..."
    
    local decrypted_file="${encrypted_file%.enc}"
    local decompressed_file="${decrypted_file%.gz}"
    
    # Decrypt file using AES-256-CBC
    if ! openssl enc -aes-256-cbc -d -salt \
        -in "$encrypted_file" \
        -out "$decrypted_file" \
        -pass "pass:$decryption_key" 2>/dev/null; then
        log_message "ERROR" "Failed to decrypt backup file"
        return 1
    fi
    
    # Decompress the decrypted file
    if ! gzip -d "$decrypted_file" 2>/dev/null; then
        log_message "ERROR" "Failed to decompress backup file"
        rm -f "$decrypted_file"
        return 1
    fi
    
    # Set secure permissions
    chmod 0600 "$decompressed_file"
    
    log_message "INFO" "Backup decrypted successfully"
    echo "$decompressed_file"
    return 0
}

# Function to restore database
# Addresses requirement: Database Restoration
restore_database() {
    local db_host=$1
    local db_name=$2
    local db_user=$3
    local backup_file=$4
    
    log_message "INFO" "Starting database restoration for $db_name"
    
    # Validate database connection
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$db_host" -U "$db_user" -d postgres -c '\q' >/dev/null 2>&1; then
        log_message "ERROR" "Cannot connect to database server"
        return 1
    fi
    
    # Create database if it doesn't exist
    PGPASSWORD="$DB_PASSWORD" psql -h "$db_host" -U "$db_user" -d postgres \
        -c "CREATE DATABASE $db_name WITH ENCODING='UTF8' LC_COLLATE='en_US.UTF-8' LC_CTYPE='en_US.UTF-8' TEMPLATE=template0;" >/dev/null 2>&1
    
    # Restore database with transaction safety
    if ! PGPASSWORD="$DB_PASSWORD" pg_restore \
        -h "$db_host" \
        -U "$db_user" \
        -d "$db_name" \
        --clean \
        --if-exists \
        --no-owner \
        --no-privileges \
        --single-transaction \
        --verbose \
        "$backup_file" 2>&1 | tee -a "$LOG_FILE"; then
        log_message "ERROR" "Database restoration failed"
        return 1
    fi
    
    # Verify restoration
    if ! PGPASSWORD="$DB_PASSWORD" psql -h "$db_host" -U "$db_user" -d "$db_name" \
        -c "SELECT COUNT(*) FROM information_schema.tables;" >/dev/null 2>&1; then
        log_message "ERROR" "Database restoration verification failed"
        return 1
    fi
    
    log_message "INFO" "Database restored successfully"
    return 0
}

# Function to clean up temporary files
# Addresses requirement: Data Security
cleanup() {
    local restore_dir=$1
    
    log_message "INFO" "Cleaning up temporary files..."
    
    # Securely remove files with shred
    find "$restore_dir" -type f -exec shred -u {} \;
    
    # Remove directory
    rm -rf "$restore_dir"
    
    # Clear sensitive variables
    unset PGPASSWORD
    unset "${DECRYPT_KEY_ENV}"
    
    log_message "INFO" "Cleanup completed"
    return 0
}

# Main execution function
# Addresses requirements: Comprehensive restore workflow
main() {
    # Enable error handling
    set -e
    trap 'cleanup "$RESTORE_DIR"' EXIT
    
    log_message "INFO" "Starting database restore process"
    
    # Parse command line arguments
    local db_host=""
    local db_name=""
    local db_user=""
    local backup_name=""
    local list_only=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --host)
                db_host="$2"
                shift 2
                ;;
            --db)
                db_name="$2"
                shift 2
                ;;
            --user)
                db_user="$2"
                shift 2
                ;;
            --backup)
                backup_name="$2"
                shift 2
                ;;
            --list)
                list_only=true
                shift
                ;;
            *)
                log_message "ERROR" "Unknown option: $1"
                echo "Usage: $0 --host <db_host> --db <db_name> --user <db_user> --backup <backup_name> [--list]"
                exit 1
                ;;
        esac
    done
    
    # Check dependencies first
    if ! check_dependencies; then
        log_message "ERROR" "Dependency check failed"
        exit 1
    fi
    
    # List backups if requested
    if [[ "$list_only" == true ]]; then
        list_available_backups
        exit 0
    fi
    
    # Validate required parameters
    if [[ -z "$db_host" || -z "$db_name" || -z "$db_user" || -z "$backup_name" ]]; then
        log_message "ERROR" "Missing required parameters"
        echo "Usage: $0 --host <db_host> --db <db_name> --user <db_user> --backup <backup_name> [--list]"
        exit 1
    fi
    
    # Download backup
    local downloaded_file
    downloaded_file=$(download_backup "$backup_name" "$RESTORE_DIR")
    if [[ $? -ne 0 || -z "$downloaded_file" ]]; then
        log_message "ERROR" "Backup download failed"
        exit 1
    fi
    
    # Decrypt backup
    local decrypted_file
    decrypted_file=$(decrypt_backup "$downloaded_file")
    if [[ $? -ne 0 || -z "$decrypted_file" ]]; then
        log_message "ERROR" "Backup decryption failed"
        exit 1
    fi
    
    # Restore database
    if ! restore_database "$db_host" "$db_name" "$db_user" "$decrypted_file"; then
        log_message "ERROR" "Database restoration failed"
        exit 1
    fi
    
    log_message "INFO" "Database restore process completed successfully"
    return 0
}

# Execute main function with all arguments
main "$@"