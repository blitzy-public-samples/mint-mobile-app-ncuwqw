"""
Gunicorn WSGI server configuration for Mint Replica Lite backend application.

Human Tasks:
1. Verify AWS CloudWatch credentials and permissions are configured
2. Set up Prometheus monitoring endpoint in Kubernetes service
3. Configure Kubernetes liveness and readiness probe settings
4. Review and adjust resource limits in Kubernetes deployment
"""

# Library versions:
# multiprocessing from Python ^3.9.0
# os from Python ^3.9.0

import multiprocessing
import os
from app.config import settings
from app.core.logging import setup_logging

# WSGI application configuration
wsgi_app = 'app.wsgi:application'  # WSGI application path
bind = '0.0.0.0:8000'  # Server socket binding

# Worker processes configuration
# Requirement: Production Environment Configuration - Configure application servers with auto-scaling
workers = multiprocessing.cpu_count() * 2 + 1  # Number of worker processes
worker_class = 'uvicorn.workers.UvicornWorker'  # ASGI worker class
worker_connections = 1000  # Maximum number of simultaneous connections

# Worker lifecycle settings
timeout = 30  # Worker timeout in seconds
keepalive = 2  # Keepalive timeout
max_requests = 1000  # Maximum requests before worker restart
max_requests_jitter = 50  # Random jitter for max_requests

# Logging configuration
# Requirement: System Monitoring - Integration with CloudWatch
accesslog = '-'  # Access log to stdout for container logging
errorlog = '-'  # Error log to stderr for container logging
loglevel = 'info' if not settings.DEBUG else 'debug'  # Log level based on environment

# Prometheus metrics configuration
prometheus_multiproc_dir = os.getenv('PROMETHEUS_MULTIPROC_DIR', '/tmp/prometheus_multiproc')
prometheus_dir_mode = 0o755

def on_starting(server):
    """
    Handler called when Gunicorn starts. Initializes logging and monitoring.
    
    Requirement: System Monitoring - Integration with CloudWatch and Prometheus
    Requirement: High Availability - Configure health monitoring
    """
    # Configure structured logging
    setup_logging(
        log_level=loglevel,
    )
    
    # Initialize Prometheus metrics collectors
    if not os.path.exists(prometheus_multiproc_dir):
        os.makedirs(prometheus_multiproc_dir, mode=prometheus_dir_mode)
    
    # Set up CloudWatch logging integration
    if settings.ENVIRONMENT == 'production':
        import watchtower
        import logging
        logging.getLogger().addHandler(
            watchtower.CloudWatchLogHandler(
                log_group=f"{settings.PROJECT_NAME}-gunicorn",
                stream_name="{strftime:%Y-%m-%d}",
                use_queues=True
            )
        )
    
    # Set process title
    server.proc_name = f"{settings.PROJECT_NAME}-gunicorn"

def post_fork(server, worker):
    """
    Handler called after worker process fork. Configures worker-specific settings.
    
    Requirement: High Availability - Configure health monitoring
    Requirement: System Monitoring - Integration with Prometheus
    """
    # Set worker process title
    worker.proc_name = f"{settings.PROJECT_NAME}-worker-{worker.age}"
    
    # Configure worker-specific structured logging
    setup_logging(
        log_level=loglevel,
    )
    
    # Initialize worker-specific Prometheus metrics
    from prometheus_client import multiprocess
    multiprocess.mark_process_dead(worker.pid)
    
    # Set up worker health check handler
    worker.log.info(f"Worker {worker.pid} initialized")

def worker_exit(server, worker):
    """
    Handler called when a worker exits. Performs cleanup and logging.
    
    Requirement: System Monitoring - Integration with CloudWatch and Prometheus
    Requirement: High Availability - Configure auto-recovery capabilities
    """
    # Log worker exit status
    worker.log.info(
        f"Worker {worker.pid} exiting",
        extra={
            'worker_age': worker.age,
            'worker_status': worker.status
        }
    )
    
    # Clean up worker-specific Prometheus metrics
    from prometheus_client import multiprocess
    multiprocess.mark_process_dead(worker.pid)
    
    # Update CloudWatch metrics for worker exits
    if settings.ENVIRONMENT == 'production':
        import boto3
        cloudwatch = boto3.client('cloudwatch')
        cloudwatch.put_metric_data(
            Namespace=f"{settings.PROJECT_NAME}/gunicorn",
            MetricData=[{
                'MetricName': 'WorkerExit',
                'Value': 1,
                'Unit': 'Count',
                'Dimensions': [
                    {'Name': 'Environment', 'Value': settings.ENVIRONMENT},
                    {'Name': 'WorkerPID', 'Value': str(worker.pid)}
                ]
            }]
        )