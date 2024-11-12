#!/bin/bash

# Human Tasks:
# 1. Configure AWS CLI with appropriate credentials and region
# 2. Set up HashiCorp Vault with appropriate policies and access
# 3. Configure Kubernetes RBAC for secret-rotator service account
# 4. Verify backup directory permissions and encryption
# 5. Set up logging directory with appropriate permissions
# 6. Configure AWS KMS key permissions for encryption/decryption
# 7. Set up monitoring alerts for failed rotation attempts

# Required versions:
# aws-cli version 2.0+ 
# vault-cli version 1.12+
# kubectl version 1.24+

set -euo pipefail

# Addresses requirement: Secret Management (6.2 Data Security/6.2.1 Encryption Implementation)
# Global variables
readonly ENVIRONMENTS=('staging' 'production')
readonly BACKUP_DIR='/var/backups/secrets'
readonly ROTATION_INTERVAL=30
readonly LOG_FILE='/var/log/secret-rotation.log'
readonly VAULT_ADDR='https://vault.mint-replica.internal:8200'
readonly VAULT_ROLE='secret-rotation'

# Logging function
log() {
    local level=$1
    local message=$2
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$level] $message" >> "$LOG_FILE"
}

# Validate environment parameter
validate_environment() {
    local env=$1
    if [[ ! " ${ENVIRONMENTS[@]} " =~ " ${env} " ]]; then
        log "ERROR" "Invalid environment: $env. Must be one of: ${ENVIRONMENTS[*]}"
        exit 1
    fi
}

# Addresses requirement: Security Controls (6.3 Security Protocols/6.3.3 Security Controls)
backup_previous_secrets() {
    local environment=$1
    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_path="${BACKUP_DIR}/${environment}_${timestamp}"
    
    log "INFO" "Starting backup of secrets for environment: $environment"
    
    # Create backup directory
    mkdir -p "$backup_path"
    
    # Export Kubernetes secrets
    kubectl get secret backend-secrets -n mint-replica-backend -o yaml > "${backup_path}/backend-secrets.yaml"
    kubectl get secret web-secrets -n mint-replica-web -o yaml > "${backup_path}/web-secrets.yaml"
    
    # Export Vault secrets
    VAULT_TOKEN=$(vault login -token-only -method=kubernetes role="$VAULT_ROLE")
    vault kv get -format=json "secret/mint-replica/${environment}" > "${backup_path}/vault-secrets.json"
    
    # Encrypt backup files using AWS KMS
    tar -czf "${backup_path}.tar.gz" -C "$backup_path" .
    aws kms encrypt \
        --key-id "alias/mint-replica-backup" \
        --plaintext "fileb://${backup_path}.tar.gz" \
        --output text \
        --query CiphertextBlob > "${backup_path}.tar.gz.encrypted"
    
    # Cleanup unencrypted files
    rm -rf "$backup_path" "${backup_path}.tar.gz"
    
    log "INFO" "Backup completed successfully at: ${backup_path}.tar.gz.encrypted"
    echo "${backup_path}.tar.gz.encrypted"
}

# Addresses requirement: Key Management (2.4 Security Architecture)
rotate_database_credentials() {
    local environment=$1
    log "INFO" "Starting database credential rotation for environment: $environment"
    
    # Generate new credentials using Vault's database secrets engine
    local new_credentials
    new_credentials=$(vault write -format=json "database/creds/mint-replica-${environment}" \
        ttl="720h" \
        username="mint_replica_${environment}")
    
    local new_username
    new_username=$(echo "$new_credentials" | jq -r '.data.username')
    local new_password
    new_password=$(echo "$new_credentials" | jq -r '.data.password')
    
    # Update RDS instance
    aws rds modify-db-instance \
        --db-instance-identifier "mint-replica-${environment}" \
        --master-user-password "$new_password"
    
    # Create new DATABASE_URL
    local db_url="postgresql://${new_username}:${new_password}@mint-replica-${environment}.rds.amazonaws.com:5432/mint_replica"
    local encoded_db_url
    encoded_db_url=$(echo -n "$db_url" | base64 -w 0)
    
    # Update Kubernetes secret
    kubectl patch secret backend-secrets -n mint-replica-backend \
        -p "{\"data\":{\"DATABASE_URL\":\"${encoded_db_url}\"}}"
    
    # Verify database connectivity
    PGPASSWORD=$new_password psql -h "mint-replica-${environment}.rds.amazonaws.com" \
        -U "$new_username" -d mint_replica -c "SELECT 1" > /dev/null
    
    log "INFO" "Database credential rotation completed successfully"
    return 0
}

# Addresses requirement: Key Management (2.4 Security Architecture)
rotate_encryption_keys() {
    local environment=$1
    log "INFO" "Starting encryption key rotation for environment: $environment"
    
    # Generate new encryption key using AWS KMS
    local new_key
    new_key=$(aws kms generate-data-key \
        --key-id "alias/mint-replica-encryption" \
        --key-spec AES_256 \
        --output text \
        --query Plaintext)
    
    # Encode new encryption keys
    local encoded_key
    encoded_key=$(echo -n "$new_key" | base64 -w 0)
    
    # Update backend secrets
    kubectl patch secret backend-secrets -n mint-replica-backend \
        -p "{\"data\":{\"ENCRYPTION_KEY\":\"${encoded_key}\"}}"
    
    # Update web secrets
    kubectl patch secret web-secrets -n mint-replica-web \
        -p "{\"data\":{\"REACT_APP_ENCRYPTION_KEY\":\"${encoded_key}\"}}"
    
    # Verify key rotation
    local backend_key
    backend_key=$(kubectl get secret backend-secrets -n mint-replica-backend \
        -o jsonpath="{.data.ENCRYPTION_KEY}")
    local web_key
    web_key=$(kubectl get secret web-secrets -n mint-replica-web \
        -o jsonpath="{.data.REACT_APP_ENCRYPTION_KEY}")
    
    if [[ "$backend_key" != "$encoded_key" || "$web_key" != "$encoded_key" ]]; then
        log "ERROR" "Encryption key verification failed"
        return 1
    }
    
    log "INFO" "Encryption key rotation completed successfully"
    return 0
}

# Addresses requirement: Secret Management (6.2 Data Security/6.2.1 Encryption Implementation)
rotate_api_credentials() {
    local environment=$1
    log "INFO" "Starting API credential rotation for environment: $environment"
    
    # Rotate Plaid API credentials
    local new_plaid_creds
    new_plaid_creds=$(vault write -format=json "plaid/rotate/${environment}")
    local plaid_client_id
    plaid_client_id=$(echo "$new_plaid_creds" | jq -r '.data.client_id' | base64 -w 0)
    local plaid_secret
    plaid_secret=$(echo "$new_plaid_creds" | jq -r '.data.secret' | base64 -w 0)
    
    # Rotate AWS access keys
    local new_aws_creds
    new_aws_creds=$(aws iam create-access-key \
        --user-name "mint-replica-${environment}-api")
    local aws_access_key
    aws_access_key=$(echo "$new_aws_creds" | jq -r '.AccessKey.AccessKeyId' | base64 -w 0)
    local aws_secret_key
    aws_secret_key=$(echo "$new_aws_creds" | jq -r '.AccessKey.SecretAccessKey' | base64 -w 0)
    
    # Update backend secrets
    kubectl patch secret backend-secrets -n mint-replica-backend \
        -p "{\"data\":{
            \"PLAID_CLIENT_ID\":\"${plaid_client_id}\",
            \"PLAID_SECRET\":\"${plaid_secret}\",
            \"AWS_ACCESS_KEY_ID\":\"${aws_access_key}\",
            \"AWS_SECRET_ACCESS_KEY\":\"${aws_secret_key}\"
        }}"
    
    # Verify API connectivity
    curl -s "https://api.plaid.com/ping" \
        -H "PLAID-CLIENT-ID: $(echo -n "$plaid_client_id" | base64 -d)" \
        -H "PLAID-SECRET: $(echo -n "$plaid_secret" | base64 -d)" > /dev/null
    
    log "INFO" "API credential rotation completed successfully"
    return 0
}

# Main secret rotation function
rotate_all_secrets() {
    local environment=$1
    local backup_file
    
    # Validate environment
    validate_environment "$environment"
    
    log "INFO" "Starting secret rotation for environment: $environment"
    
    # Create backup before rotation
    backup_file=$(backup_previous_secrets "$environment")
    
    # Rotate all secrets
    if ! rotate_database_credentials "$environment"; then
        log "ERROR" "Database credential rotation failed"
        exit 1
    fi
    
    if ! rotate_encryption_keys "$environment"; then
        log "ERROR" "Encryption key rotation failed"
        exit 1
    fi
    
    if ! rotate_api_credentials "$environment"; then
        log "ERROR" "API credential rotation failed"
        exit 1
    fi
    
    log "INFO" "Secret rotation completed successfully for environment: $environment"
    log "INFO" "Backup file location: $backup_file"
}

# Script entry point
main() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: $0 <environment>"
        echo "Available environments: ${ENVIRONMENTS[*]}"
        exit 1
    fi
    
    # Set up error handling
    trap 'log "ERROR" "Secret rotation failed with error on line $LINENO"' ERR
    
    # Verify required tools
    for cmd in aws vault kubectl jq curl psql; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: Required command '$cmd' not found"
            exit 1
        fi
    done
    
    # Verify directories exist
    for dir in "$BACKUP_DIR" "$(dirname "$LOG_FILE")"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            chmod 700 "$dir"
        fi
    done
    
    # Start rotation process
    rotate_all_secrets "$1"
}

# Execute main function
main "$@"