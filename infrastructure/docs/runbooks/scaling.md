# Mint Replica Lite System Scaling Runbook

# Human Tasks:
# 1. Verify Kubernetes metrics server is installed and functioning
# 2. Configure CloudWatch alarms for scaling events
# 3. Set up Prometheus monitoring for scaling metrics
# 4. Review and adjust initial scaling thresholds after 2 weeks of production data
# 5. Configure cross-zone load balancing in AWS ALB
# 6. Enable enhanced monitoring for RDS instances
# 7. Set up Redis cluster alerts in CloudWatch

# Table of Contents
1. Overview
2. Application Scaling
   2.1 Backend Services
   2.2 Web Frontend
3. Database Scaling
   3.1 RDS Scaling
   3.2 Read Replicas
4. Cache Scaling
   4.1 Redis Cluster
   4.2 Cache Optimization
5. Monitoring and Alerts
6. Emergency Procedures

## 1. Overview

This runbook provides comprehensive procedures for scaling the Mint Replica Lite system across all components. The system is designed to scale horizontally and vertically based on demand while maintaining high availability.

Key scaling principles:
- Proactive scaling based on metrics
- Automated horizontal scaling where possible
- Multi-AZ deployment for high availability
- Resource optimization for cost efficiency

## 2. Application Scaling

### 2.1 Backend Services
[Requirement: Horizontal Scaling - 2.5.3 Scalability Architecture]

Backend API service scaling is managed through Kubernetes HPA with the following configuration:

```yaml
# Reference: infrastructure/kubernetes/apps/backend/hpa.yaml
Scaling Parameters:
- Min replicas: 2
- Max replicas: 20
- CPU threshold: 70%
- Memory threshold: 80%
- Scale up window: 60s
- Scale down window: 300s
```

Scaling Procedures:
1. Monitor CPU and memory utilization through Kubernetes metrics
2. HPA automatically scales pods based on defined thresholds
3. New pods are distributed across availability zones
4. Health checks ensure pod readiness before traffic routing

Manual Scaling:
```bash
# Scale backend deployment manually if needed
kubectl scale deployment backend-api -n mint-replica-backend --replicas=<count>

# Check scaling status
kubectl get hpa backend-api-hpa -n mint-replica-backend
```

### 2.2 Web Frontend
[Requirement: Horizontal Scaling - 2.5.3 Scalability Architecture]

Web frontend scaling configuration:

```yaml
# Reference: infrastructure/kubernetes/apps/web/hpa.yaml
Scaling Parameters:
- Min replicas: 2
- Max replicas: 10
- CPU threshold: 70%
- Memory threshold: 80%
- Scale up window: 60s
- Scale down window: 300s
```

Scaling Procedures:
1. Frontend pods scale based on CPU and memory metrics
2. CDN caching reduces load on frontend servers
3. Session affinity maintained during scaling
4. Rolling updates ensure zero-downtime deployments

## 3. Database Scaling
[Requirement: Database Scaling - 2.5.3 Scalability Architecture]

### 3.1 RDS Scaling

Vertical Scaling Options:
```hcl
# Reference: infrastructure/terraform/modules/rds/main.tf
Instance Classes:
- db.t3.medium (Development)
- db.t3.large (Staging)
- db.r5.large (Production)
- db.r5.xlarge (High Load)

Storage Scaling:
- Increment: 100GB
- Auto-scaling enabled
- Maximum storage: 1TB
```

Vertical Scaling Procedure:
1. Monitor storage and performance metrics
2. Schedule maintenance window
3. Modify instance class:
```bash
aws rds modify-db-instance \
    --db-instance-identifier mintreplica-postgres \
    --db-instance-class db.r5.xlarge \
    --apply-immediately
```

### 3.2 Read Replicas
[Requirement: High Availability - 2.5.4 Availability Architecture]

Read Replica Management:
```hcl
# Reference: infrastructure/terraform/modules/rds/main.tf
Read Replica Configuration:
- Maximum replicas: 5
- Multi-AZ deployment
- Automated failover
```

Scaling Procedures:
1. Create read replica:
```bash
aws rds create-db-instance-read-replica \
    --db-instance-identifier mintreplica-postgres-replica-n \
    --source-db-instance-identifier mintreplica-postgres
```

2. Monitor replication lag:
```bash
aws cloudwatch get-metric-statistics \
    --namespace AWS/RDS \
    --metric-name ReplicaLag \
    --dimensions Name=DBInstanceIdentifier,Value=mintreplica-postgres-replica-1
```

3. Promote replica if needed:
```bash
aws rds promote-read-replica \
    --db-instance-identifier mintreplica-postgres-replica-1
```

## 4. Cache Scaling
[Requirement: Cache Scaling - 2.5.3 Scalability Architecture]

### 4.1 Redis Cluster

Redis Cluster Configuration:
```yaml
Cluster Parameters:
- Maximum shards: 15
- Replicas per shard: 5
- Node types: 
  - cache.t3.medium
  - cache.r5.large
  - cache.r5.xlarge
```

Scaling Procedures:
1. Add shard:
```bash
aws elasticache modify-replication-group-shard-configuration \
    --replication-group-id mintreplica-redis \
    --node-group-count <new_count> \
    --apply-immediately
```

2. Add replicas:
```bash
aws elasticache increase-replica-count \
    --replication-group-id mintreplica-redis \
    --apply-immediately
```

### 4.2 Cache Optimization

Cache Sizing Guidelines:
1. Monitor memory usage and eviction rates
2. Scale up when memory usage exceeds 75%
3. Optimize key expiration policies
4. Implement cache warming procedures

Node Type Upgrade:
```bash
aws elasticache modify-replication-group \
    --replication-group-id mintreplica-redis \
    --cache-node-type cache.r5.large \
    --apply-immediately
```

## 5. Monitoring and Alerts

Key Metrics to Monitor:
1. Application Metrics:
   - Pod CPU/Memory utilization
   - Request latency
   - Error rates
   - Active sessions

2. Database Metrics:
   - CPU utilization
   - IOPS
   - Connection count
   - Replication lag

3. Cache Metrics:
   - Memory usage
   - Cache hit rate
   - Eviction rate
   - Connection count

Alert Thresholds:
```yaml
Application:
  CPU: >80% for 5 minutes
  Memory: >85% for 5 minutes
  Error Rate: >1% for 5 minutes

Database:
  CPU: >75% for 10 minutes
  Storage: >85% used
  Replication Lag: >30 seconds

Cache:
  Memory: >80% for 5 minutes
  Eviction Rate: >100/second
```

## 6. Emergency Procedures

High Load Response:
1. Verify monitoring alerts
2. Check system health:
```bash
# Check pod status
kubectl get pods -n mint-replica-backend
kubectl get pods -n mint-replica-web

# Check HPA status
kubectl get hpa -A

# Check node capacity
kubectl describe nodes
```

3. Emergency Scaling:
```bash
# Scale backend immediately
kubectl scale deployment backend-api -n mint-replica-backend --replicas=20

# Scale frontend immediately
kubectl scale deployment web-frontend -n mint-replica-web --replicas=10

# Add database read replica
aws rds create-db-instance-read-replica \
    --db-instance-identifier mintreplica-postgres-replica-emergency \
    --source-db-instance-identifier mintreplica-postgres \
    --availability-zone us-west-2b

# Scale up Redis cluster
aws elasticache modify-replication-group \
    --replication-group-id mintreplica-redis \
    --cache-node-type cache.r5.xlarge \
    --apply-immediately
```

4. Post-Incident:
- Analyze metrics leading to incident
- Adjust scaling thresholds if needed
- Update runbook based on lessons learned
- Schedule capacity planning review