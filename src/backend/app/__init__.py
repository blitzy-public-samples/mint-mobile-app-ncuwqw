"""
Main application initialization module for Mint Replica Lite backend service.

Human Tasks:
1. Generate and configure production SECRET_KEY in environment variables
2. Set up PostgreSQL credentials and database for production
3. Configure Redis credentials and cluster for production
4. Set up SSL certificates for production deployment
5. Configure CORS allowed origins for production
"""

# Library versions:
# flask==2.0.0
# flask-sqlalchemy==2.5.0
# flask-migrate==3.1.0
# flask-cors==3.0.0
# flask-jwt-extended==4.3.0

from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from flask_jwt_extended import JWTManager

from .config import settings
from .core.cache import RedisCache
from .api.v1.routes import api_router

# Initialize global instances
# Requirement: Data Storage - Configure PostgreSQL database connection
db = SQLAlchemy()

# Requirement: Data Storage - Configure database migrations
migrate = Migrate()

# Requirement: Security Infrastructure - Setup JWT-based authentication
jwt = JWTManager()

def create_app(config_name: str) -> Flask:
    """
    Factory function to create and configure Flask application instance.
    
    Args:
        config_name (str): Environment configuration name (development/staging/production)
        
    Returns:
        Flask: Configured Flask application instance
        
    Requirement: Backend Services - Initialize and configure RESTful API services
    """
    # Create Flask app instance
    app = Flask(__name__)
    
    # Load environment-specific configuration
    app.config['ENV'] = config_name
    app.config['SQLALCHEMY_DATABASE_URI'] = settings.get_database_url()
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
    app.config['JWT_SECRET_KEY'] = settings.SECRET_KEY.get_secret_value()
    app.config['JWT_ALGORITHM'] = settings.JWT_ALGORITHM
    app.config['JWT_ACCESS_TOKEN_EXPIRES'] = settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
    
    # Initialize SQLAlchemy with application
    # Requirement: Data Storage - Configure PostgreSQL connection
    db.init_app(app)
    
    # Initialize database migrations
    migrate.init_app(app, db)
    
    # Initialize Redis cache
    # Requirement: Data Storage - Configure Redis storage connection
    app.config['REDIS_URL'] = settings.get_redis_url()
    cache = RedisCache()
    app.extensions['redis_cache'] = cache
    
    # Configure JWT authentication
    # Requirement: Security Infrastructure - Setup JWT-based authentication
    jwt.init_app(app)
    
    # Configure CORS
    # Requirement: Backend Services - Configure secure API access
    CORS(app, resources={
        r"/api/*": {
            "origins": ["http://localhost:3000", "https://app.mintreplica.com"],
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
            "expose_headers": ["Content-Range", "X-Total-Count"],
            "supports_credentials": True,
            "max_age": 600
        }
    })
    
    # Register API routes
    # Requirement: Backend Services - Initialize RESTful API services
    app.register_blueprint(api_router)
    
    # Configure error handlers
    @app.errorhandler(400)
    def bad_request_error(error):
        return {"error": "Bad Request", "message": str(error)}, 400
    
    @app.errorhandler(401)
    def unauthorized_error(error):
        return {"error": "Unauthorized", "message": str(error)}, 401
    
    @app.errorhandler(403)
    def forbidden_error(error):
        return {"error": "Forbidden", "message": str(error)}, 403
    
    @app.errorhandler(404)
    def not_found_error(error):
        return {"error": "Not Found", "message": str(error)}, 404
    
    @app.errorhandler(500)
    def internal_server_error(error):
        return {"error": "Internal Server Error", "message": str(error)}, 500
    
    # Add health check endpoint
    @app.route('/health')
    def health_check():
        return {"status": "healthy", "version": settings.API_VERSION}, 200
    
    return app