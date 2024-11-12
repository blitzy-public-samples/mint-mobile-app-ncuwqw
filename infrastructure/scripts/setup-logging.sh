#!/bin/bash

# Human Tasks:
# 1. Ensure AWS CLI is configured with appropriate credentials and permissions
# 2. Verify Helm v3.0+ is installed and configured
# 3. Confirm kubectl access to target Kubernetes cluster
# 4. Validate AWS S3 bucket permissions and encryption settings
# 5. Check network policies allow Loki pod communication
# 6. Verify monitoring namespace exists and has appropriate RBAC

# Required tool versions:
# - kubectl v1.24+
# - helm v3.0+
# - aws-cli 2.0+

set -euo pipefail

# Global variables from specification
LOKI_VERSION="2.9.1"
MONITORING_NAMESPACE="monitoring"
LOG_RETENTION_DAYS="7"
S3_BUCKET_PREFIX="mint-replica-logs"

# Script variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOKI_VALUES_FILE="../kubernetes/monitoring/loki/values.yaml"
LOKI_CONFIG_FILE="../monitoring/loki/loki.yml"
NETWORK_POLICY_FILE="../kubernetes/security/network-policies.yaml"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check required tools
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl v1.24+"
        exit 1
    fi
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        log_error "helm is not installed. Please install helm v3.0+"
        exit 1
    fi
    
    # Check aws-cli
    if ! command -v aws &> /dev/null; then
        log_error "aws-cli is not installed. Please install aws-cli 2.0+"
        exit 1
    }
    
    log_info "Prerequisites check completed"
}

# Function to setup S3 storage for logs
# Implements requirement: Distributed Logging (2.5.3 Scalability Architecture)
setup_s3_storage() {
    local aws_region="$1"
    local bucket_name="$2"
    
    log_info "Setting up S3 storage in region ${aws_region}..."
    
    # Create S3 bucket if it doesn't exist
    if ! aws s3api head-bucket --bucket "${bucket_name}" 2>/dev/null; then
        aws s3api create-bucket \
            --bucket "${bucket_name}" \
            --region "${aws_region}" \
            --create-bucket-configuration LocationConstraint="${aws_region}"
        
        # Enable bucket encryption
        aws s3api put-bucket-encryption \
            --bucket "${bucket_name}" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'
        
        # Set lifecycle policy for log retention
        aws s3api put-bucket-lifecycle-configuration \
            --bucket "${bucket_name}" \
            --lifecycle-configuration '{
                "Rules": [
                    {
                        "ID": "LogRetention",
                        "Status": "Enabled",
                        "ExpirationInDays": '"${LOG_RETENTION_DAYS}"',
                        "Filter": {
                            "Prefix": "logs/"
                        }
                    }
                ]
            }'
    fi
    
    log_info "S3 storage setup completed"
}

# Function to deploy Loki using Helm
# Implements requirement: Logging Infrastructure (2.5.1 Production Environment)
deploy_loki() {
    local namespace="$1"
    local release_name="$2"
    
    log_info "Deploying Loki to namespace ${namespace}..."
    
    # Create namespace if it doesn't exist
    kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply -f -
    
    # Add Grafana Helm repository
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # Apply network policies
    kubectl apply -f "${NETWORK_POLICY_FILE}"
    
    # Deploy Loki using Helm
    helm upgrade --install "${release_name}" grafana/loki \
        --namespace "${namespace}" \
        --version "${LOKI_VERSION}" \
        --values "${LOKI_VALUES_FILE}" \
        --wait \
        --timeout 10m
    
    # Verify deployment
    kubectl rollout status statefulset/${release_name} -n "${namespace}"
    
    log_info "Loki deployment completed"
}

# Function to configure retention policies
# Implements requirement: System Observability (2.5.4 Availability Architecture)
configure_retention() {
    local retention_period="$1"
    
    log_info "Configuring retention policies..."
    
    # Update Loki configuration with retention settings
    kubectl create configmap loki-retention-config \
        --from-file="${LOKI_CONFIG_FILE}" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply retention settings to storage configuration
    yq eval ".limits_config.retention_period = \"${retention_period}\"" -i "${LOKI_CONFIG_FILE}"
    
    log_info "Retention configuration completed"
}

# Function to setup monitoring integration
# Implements requirement: System Observability (2.5.4 Availability Architecture)
setup_monitoring_integration() {
    local namespace="$1"
    
    log_info "Setting up monitoring integration..."
    
    # Configure Prometheus scraping
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: loki-monitoring
  namespace: ${namespace}
spec:
  selector:
    matchLabels:
      app: loki
  endpoints:
  - port: http-metrics
    interval: 15s
EOF
    
    # Setup Grafana datasource
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-loki-datasource
  namespace: ${namespace}
labels:
  grafana_datasource: "1"
data:
  loki-datasource.yaml: |-
    apiVersion: 1
    datasources:
    - name: Loki
      type: loki
      access: proxy
      url: http://loki:3100
      version: 1
      isDefault: false
      jsonData:
        maxLines: 1000
EOF
    
    log_info "Monitoring integration completed"
}

# Main function to orchestrate the setup
main() {
    local aws_region="us-west-2"  # Default region
    local bucket_name="${S3_BUCKET_PREFIX}-${aws_region}"
    local release_name="loki"
    local retention_period="${LOG_RETENTION_DAYS}d"
    
    # Check prerequisites
    check_prerequisites
    
    # Setup logging infrastructure
    setup_s3_storage "${aws_region}" "${bucket_name}"
    deploy_loki "${MONITORING_NAMESPACE}" "${release_name}"
    configure_retention "${retention_period}"
    setup_monitoring_integration "${MONITORING_NAMESPACE}"
    
    log_info "Logging infrastructure setup completed successfully"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi