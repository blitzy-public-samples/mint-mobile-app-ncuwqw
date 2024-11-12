"""
WSGI application entry point for Mint Replica Lite backend service.

Human Tasks:
1. Configure Gunicorn worker processes and threads based on server resources
2. Set up Gunicorn logging and monitoring for production
3. Configure SSL certificates and HTTPS for production deployment
4. Set up health check monitoring for Kubernetes liveness probes
5. Configure load balancer settings for production traffic
"""

# Library versions:
# os from Python ^3.9.0

import os
from app import create_app
from app.config import settings

# Requirement: Backend Services - Initialize RESTful API services for production deployment
# Create Flask application instance configured for production environment
app = create_app(settings.ENVIRONMENT)

# Requirement: Infrastructure Architecture - Configure application servers in Kubernetes cluster with Gunicorn
# Export WSGI application interface for Gunicorn server
# The 'application' variable is the conventional WSGI callable that Gunicorn expects
application = app.wsgi_app

if __name__ == '__main__':
    # This section is for development server only
    # In production, Gunicorn will use the 'application' variable directly
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)