#!/bin/bash

# Human Tasks:
# 1. Verify AWS gp2 storage class is available in the cluster
# 2. Ensure monitoring-service ServiceAccount exists in mint-replica-monitoring namespace
# 3. Validate TLS certificates are properly configured for secure metrics
# 4. Review backup storage permissions and retention policies
# 5. Check network policy enforcement is enabled on the cluster

# Tool versions:
# - kubectl v1.24+
# - helm v3.10+

# Global variables
MONITORING_NAMESPACE="monitoring"
PROMETHEUS_VERSION="15.10.0"
GRAFANA_VERSION="9.3.2"
LOKI_VERSION="2.9.1"
PROMETHEUS_VALUES_FILE="../kubernetes/monitoring/prometheus/values.yaml"
GRAFANA_VALUES_FILE="../kubernetes/monitoring/grafana/values.yaml"
LOKI_VALUES_FILE="../kubernetes/monitoring/loki/values.yaml"

# Function to check prerequisites
# Addresses requirement: Infrastructure Monitoring (2.5.1 Production Environment)
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check kubectl installation
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl is not installed"
        return 1
    fi

    # Check helm installation
    if ! command -v helm &> /dev/null; then
        echo "Error: helm is not installed"
        return 1
    }

    # Verify cluster access
    if ! kubectl cluster-info &> /dev/null; then
        echo "Error: Unable to access Kubernetes cluster"
        return 1
    }

    # Check monitoring namespace
    if ! kubectl get namespace "$MONITORING_NAMESPACE" &> /dev/null; then
        kubectl create namespace "$MONITORING_NAMESPACE"
    fi

    # Verify RBAC permissions
    if ! kubectl auth can-i create clusterrole --all-namespaces &> /dev/null; then
        echo "Error: Insufficient RBAC permissions"
        return 1
    }

    # Check storage class
    if ! kubectl get storageclass gp2 &> /dev/null; then
        echo "Error: gp2 storage class not found"
        return 1
    }

    return 0
}

# Function to setup Prometheus
# Addresses requirements: 
# - Infrastructure Monitoring (2.5.1 Production Environment)
# - Metrics Collection (2.5.3 Scalability Architecture)
setup_prometheus() {
    echo "Setting up Prometheus..."

    # Add and update Prometheus helm repo
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo update

    # Create monitoring namespace if not exists
    kubectl create namespace "$MONITORING_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

    # Apply RBAC configurations
    kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: monitoring-service
  namespace: $MONITORING_NAMESPACE
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: monitoring-role
rules:
  - apiGroups: [""]
    resources: ["nodes", "nodes/proxy", "services", "endpoints", "pods"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["extensions"]
    resources: ["ingresses"]
    verbs: ["get", "list", "watch"]
EOF

    # Install Prometheus with custom values
    helm upgrade --install prometheus prometheus-community/prometheus \
        --namespace "$MONITORING_NAMESPACE" \
        --version "$PROMETHEUS_VERSION" \
        --values "$PROMETHEUS_VALUES_FILE" \
        --wait

    # Verify Prometheus deployment
    kubectl rollout status deployment/prometheus-server -n "$MONITORING_NAMESPACE"
    
    return $?
}

# Function to setup Grafana
# Addresses requirements:
# - Infrastructure Monitoring (2.5.1 Production Environment)
# - Health Monitoring (2.5.4 Availability Architecture)
setup_grafana() {
    echo "Setting up Grafana..."

    # Add and update Grafana helm repo
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    # Create Grafana admin secret
    kubectl create secret generic grafana-admin-credentials \
        --from-literal=admin-user=admin \
        --from-literal=admin-password="$(openssl rand -base64 20)" \
        --namespace "$MONITORING_NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -

    # Install Grafana with custom values
    helm upgrade --install grafana grafana/grafana \
        --namespace "$MONITORING_NAMESPACE" \
        --version "$GRAFANA_VERSION" \
        --values "$GRAFANA_VALUES_FILE" \
        --wait

    # Verify Grafana deployment
    kubectl rollout status deployment/grafana -n "$MONITORING_NAMESPACE"
    
    return $?
}

# Function to setup Loki
# Addresses requirement: Infrastructure Monitoring (2.5.1 Production Environment)
setup_loki() {
    echo "Setting up Loki..."

    # Add and update Loki helm repo
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update

    # Configure storage settings
    kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: loki-storage
  namespace: $MONITORING_NAMESPACE
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp2
  resources:
    requests:
      storage: 50Gi
EOF

    # Install Loki with custom values
    helm upgrade --install loki grafana/loki \
        --namespace "$MONITORING_NAMESPACE" \
        --version "$LOKI_VERSION" \
        --values "$LOKI_VALUES_FILE" \
        --wait

    # Verify Loki deployment
    kubectl rollout status statefulset/loki -n "$MONITORING_NAMESPACE"
    
    return $?
}

# Function to verify monitoring stack
# Addresses requirements:
# - Health Monitoring (2.5.4 Availability Architecture)
# - Metrics Collection (2.5.3 Scalability Architecture)
verify_monitoring() {
    echo "Verifying monitoring stack..."

    # Check all monitoring pods are running
    if ! kubectl get pods -n "$MONITORING_NAMESPACE" | grep -q "Running"; then
        echo "Error: Not all monitoring pods are running"
        return 1
    fi

    # Verify Prometheus targets
    if ! kubectl port-forward svc/prometheus-server 9090:9090 -n "$MONITORING_NAMESPACE" >/dev/null 2>&1 & then
        echo "Error: Unable to port-forward Prometheus"
        return 1
    fi
    sleep 5
    kill %1

    # Verify Grafana accessibility
    if ! kubectl port-forward svc/grafana 3000:3000 -n "$MONITORING_NAMESPACE" >/dev/null 2>&1 & then
        echo "Error: Unable to port-forward Grafana"
        return 1
    fi
    sleep 5
    kill %1

    # Verify Loki log ingestion
    if ! kubectl port-forward svc/loki 3100:3100 -n "$MONITORING_NAMESPACE" >/dev/null 2>&1 & then
        echo "Error: Unable to port-forward Loki"
        return 1
    fi
    sleep 5
    kill %1

    return 0
}

# Main execution
main() {
    echo "Starting monitoring stack setup..."

    # Check prerequisites
    if ! check_prerequisites; then
        echo "Prerequisites check failed"
        exit 1
    fi

    # Setup components
    if ! setup_prometheus; then
        echo "Prometheus setup failed"
        exit 1
    fi

    if ! setup_grafana; then
        echo "Grafana setup failed"
        exit 1
    fi

    if ! setup_loki; then
        echo "Loki setup failed"
        exit 1
    fi

    # Verify setup
    if ! verify_monitoring; then
        echo "Monitoring verification failed"
        exit 1
    fi

    echo "Monitoring stack setup completed successfully"
    return 0
}

# Execute main function
main