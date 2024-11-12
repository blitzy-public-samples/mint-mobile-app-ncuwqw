#!/bin/bash

# Human Tasks:
# 1. Ensure AWS credentials are configured with appropriate permissions
# 2. Verify Kubernetes cluster is accessible and has required storage classes
# 3. Configure network security groups to allow specified ports
# 4. Set up DNS entries for service discovery if using custom domain
# 5. Review and adjust resource quotas in monitoring namespace

# Required tool versions:
# - kubectl v1.24+
# - helm v3.0+
# - aws-cli v2.0+
# - Tempo v1.5.0

set -euo pipefail

# Global variables
TEMPO_VERSION="1.5.0"
MONITORING_NAMESPACE="monitoring"
S3_BUCKET="mint-replica-traces"
AWS_REGION="us-west-2"
HELM_REPO="https://grafana.github.io/helm-charts"
TEMPO_HTTP_PORT="3200"
TEMPO_GRPC_PORT="9095"

# REQ: Distributed Tracing Setup - Verify prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl not found"
        return 1
    fi
    
    # Check kubectl cluster access
    if ! kubectl cluster-info &> /dev/null; then
        echo "Error: Cannot connect to Kubernetes cluster"
        return 1
    }
    
    # Check helm
    if ! command -v helm &> /dev/null; then
        echo "Error: helm not found"
        return 1
    fi
    
    # Verify helm version
    HELM_VERSION=$(helm version --short | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "${HELM_VERSION}" -lt 3 ]; then
        echo "Error: Helm v3.0+ required"
        return 1
    }
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI not found"
        return 1
    }
    
    # Verify AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo "Error: Invalid AWS credentials"
        return 1
    }
    
    return 0
}

# REQ: System Observability - Configure S3 storage backend
setup_storage() {
    echo "Setting up S3 storage..."
    
    # Check if bucket exists
    if ! aws s3api head-bucket --bucket "${S3_BUCKET}" --region "${AWS_REGION}" 2>/dev/null; then
        # Create bucket if it doesn't exist
        aws s3api create-bucket \
            --bucket "${S3_BUCKET}" \
            --region "${AWS_REGION}" \
            --create-bucket-configuration LocationConstraint="${AWS_REGION}"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "${S3_BUCKET}" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "${S3_BUCKET}" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    # Set lifecycle policy for retention
    aws s3api put-bucket-lifecycle-configuration \
        --bucket "${S3_BUCKET}" \
        --lifecycle-configuration '{
            "Rules": [
                {
                    "ID": "Tempo-Retention",
                    "Status": "Enabled",
                    "Expiration": {
                        "Days": 7
                    }
                }
            ]
        }'
    
    return 0
}

# REQ: Distributed Tracing Setup - Deploy Tempo with HA configuration
deploy_tempo() {
    local namespace=$1
    echo "Deploying Tempo to namespace: ${namespace}..."
    
    # Add Grafana helm repository
    helm repo add grafana "${HELM_REPO}"
    helm repo update
    
    # Create namespace if it doesn't exist
    kubectl create namespace "${namespace}" --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Tempo using helm
    helm upgrade --install tempo grafana/tempo \
        --namespace "${namespace}" \
        --version "${TEMPO_VERSION}" \
        --values ../kubernetes/monitoring/tempo/values.yaml \
        --set tempo.storage.trace.backend=s3 \
        --set tempo.storage.trace.s3.bucket="${S3_BUCKET}" \
        --set tempo.storage.trace.s3.endpoint=s3.${AWS_REGION}.amazonaws.com \
        --set tempo.storage.trace.s3.region="${AWS_REGION}" \
        --wait
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=tempo \
        --namespace "${namespace}" \
        --timeout=300s
    
    return 0
}

# REQ: System Observability - Configure monitoring stack integration
configure_integrations() {
    echo "Configuring monitoring integrations..."
    
    # Create ServiceMonitor for Prometheus integration
    kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: tempo
  namespace: ${MONITORING_NAMESPACE}
spec:
  selector:
    matchLabels:
      app: tempo
  endpoints:
  - port: tempo-query
    interval: 30s
EOF
    
    # Configure Grafana data source
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-tempo-datasource
  namespace: ${MONITORING_NAMESPACE}
data:
  tempo-datasource.yaml: |
    apiVersion: 1
    datasources:
    - name: Tempo
      type: tempo
      access: proxy
      url: http://tempo:${TEMPO_HTTP_PORT}
      version: 1
      isDefault: false
EOF
    
    return 0
}

# REQ: Request Monitoring - Verify setup and functionality
verify_setup() {
    echo "Verifying Tempo setup..."
    
    # Check pod status
    if ! kubectl get pods -n "${MONITORING_NAMESPACE}" -l app=tempo | grep -q "Running"; then
        echo "Error: Tempo pods not running"
        return 1
    fi
    
    # Verify service endpoints
    local endpoints=(
        "${TEMPO_HTTP_PORT}"  # Query endpoint
        "${TEMPO_GRPC_PORT}"  # GRPC endpoint
        "14250"  # Jaeger gRPC
        "14268"  # Jaeger HTTP
        "4317"   # OTLP gRPC
        "4318"   # OTLP HTTP
    )
    
    for port in "${endpoints[@]}"; do
        if ! kubectl get svc -n "${MONITORING_NAMESPACE}" tempo | grep -q "${port}"; then
            echo "Error: Service port ${port} not configured"
            return 1
        fi
    done
    
    # Test S3 access
    if ! aws s3 ls "s3://${S3_BUCKET}" &> /dev/null; then
        echo "Error: Cannot access S3 bucket"
        return 1
    fi
    
    return 0
}

# Main execution
main() {
    echo "Starting Tempo tracing setup..."
    
    check_prerequisites || exit 1
    setup_storage || exit 1
    deploy_tempo "${MONITORING_NAMESPACE}" || exit 1
    configure_integrations || exit 1
    verify_setup || exit 1
    
    echo "Tempo tracing setup completed successfully"
    return 0
}

main "$@"