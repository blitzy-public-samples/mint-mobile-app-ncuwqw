# Human Tasks:
# 1. Verify that the Flask development server is accessible on the specified host and port
# 2. Ensure firewall rules allow access to port 5000 for development
# 3. Review debug settings before deploying to staging/production environments

# Requirement: Backend Development Configuration (2.1 High-Level Architecture Overview)
# Specifies the Flask application entry point using the wsgi.py module
FLASK_APP=app.wsgi:app

# Requirement: Development Environment (2.5.1 Production Environment)
# Sets Flask environment to development mode for enhanced debugging capabilities
FLASK_ENV=development

# Enables Flask debug mode with hot reloading and detailed error pages
FLASK_DEBUG=1

# Development server network binding configuration
# Binds to all network interfaces (0.0.0.0) for local development access
FLASK_RUN_HOST=0.0.0.0

# Default development server port
FLASK_RUN_PORT=5000