# HUMAN TASKS:
# 1. Ensure Docker BuildKit is enabled for optimal multi-stage builds
# 2. Configure AWS CloudWatch credentials for log shipping
# 3. Set up Prometheus monitoring endpoint in Kubernetes
# 4. Verify PostgreSQL and Redis connection strings are configured in environment
# 5. Review and adjust resource limits in Kubernetes deployment

# Stage 1: Builder
# REQ: Backend Development Framework - Python 3.9+ for backend development
FROM python:3.9-slim AS builder

# Set build environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install build dependencies
# REQ: Backend Development Framework - Extensive libraries support
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Create and set working directory
WORKDIR /build

# Copy requirements file
COPY requirements.txt .

# Create directory for wheels
RUN mkdir /wheels

# Build wheels for all dependencies
# REQ: Backend Development Framework - Package management
RUN pip wheel --no-cache-dir --no-deps --wheel-dir /wheels -r requirements.txt

# Stage 2: Final runtime image
# REQ: Containerization - Docker for containerization of services
FROM python:3.9-slim

# Set runtime environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    FLASK_ENV=production \
    PATH="/home/app/.local/bin:$PATH"

# Install runtime system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# REQ: Security Architecture - Security hardening
# Create non-root user
RUN groupadd -r app && \
    useradd -r -g app -d /home/app -s /sbin/nologin -u 1000 app && \
    mkdir -p /home/app && \
    chown -R app:app /home/app

# Set working directory
WORKDIR /app

# Copy wheels from builder stage
COPY --from=builder /wheels /wheels

# Install Python packages from wheels
RUN pip install --no-cache-dir /wheels/* && \
    rm -rf /wheels

# Copy application code and configuration
COPY --chown=app:app . .

# Set secure permissions
# REQ: Security Architecture - Security hardening
RUN chmod 755 /app && \
    chmod 644 /app/gunicorn.conf.py && \
    find /app -type d -exec chmod 755 {} \; && \
    find /app -type f -exec chmod 644 {} \;

# Create and set permissions for data and log directories
# REQ: Production Environment - Application configuration
RUN mkdir -p /app/data /app/logs && \
    chown -R app:app /app/data /app/logs && \
    chmod 755 /app/data /app/logs

# Switch to non-root user
USER app

# Expose Gunicorn port
# REQ: Production Environment - Application Servers configuration
EXPOSE 8000

# Set up volumes for persistence
VOLUME ["/app/data", "/app/logs"]

# Configure health check
# REQ: Production Environment - Health monitoring
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl --fail http://localhost:8000/health || exit 1

# Set the entrypoint to Gunicorn
# REQ: Production Environment - WSGI server configuration
ENTRYPOINT ["gunicorn"]

# Configure Gunicorn with production settings
CMD ["--config", "gunicorn.conf.py", "--bind", "0.0.0.0:8000", "app.wsgi:app"]