"""
API package initialization module for Mint Replica Lite backend application.

Human Tasks:
1. Review and adjust CORS settings for production environment
2. Configure monitoring and alerting for API endpoints
3. Set up centralized logging for API requests
4. Review rate limiting settings for production load
5. Configure SSL/TLS certificates for HTTPS
"""

# fastapi: ^0.95.0
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Import API routers and settings
from app.api.v1.routes import api_router
from app.core.config import Settings

def setup_cors(app: FastAPI) -> None:
    """
    Configure CORS middleware with secure defaults for the FastAPI application.
    
    Requirements addressed:
    - API Security (2.4): Implements secure CORS configuration
    """
    app.add_middleware(
        CORSMiddleware,
        # In production, replace with specific origins
        allow_origins=["*"] if app.debug else ["https://mint-replica-lite.com"],
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
        allow_headers=[
            "Authorization",
            "Content-Type",
            "Accept",
            "Origin",
            "X-Requested-With",
        ],
        max_age=3600,  # Cache preflight requests for 1 hour
    )

def setup_routes(app: FastAPI) -> None:
    """
    Register all API routes with versioning support.
    
    Requirements addressed:
    - API Gateway Layer (2.1): Implements centralized API routing
    - RESTful Services (2.D): Configures RESTful endpoints with versioning
    """
    settings = Settings()
    
    # Include the v1 API router with version prefix
    app.include_router(
        api_router,
        prefix=settings.API_V1_PREFIX,
    )

def init_app() -> FastAPI:
    """
    Initialize and configure the FastAPI application instance.
    
    Requirements addressed:
    - API Gateway Layer (2.1): Configures central API gateway
    - API Security (2.4): Implements secure API configuration
    - RESTful Services (2.D): Sets up RESTful API structure
    """
    settings = Settings()
    
    # Initialize FastAPI with OpenAPI documentation configuration
    app = FastAPI(
        title=f"{settings.PROJECT_NAME} API",
        openapi_url=f"{settings.API_V1_PREFIX}/openapi.json",
        docs_url=f"{settings.API_V1_PREFIX}/docs",
        redoc_url=f"{settings.API_V1_PREFIX}/redoc",
        # Security headers
        swagger_ui_parameters={
            "persistAuthorization": True,
            "displayRequestDuration": True,
        },
        # Response headers for security
        default_response_class_kwargs={
            "headers": {
                "X-Content-Type-Options": "nosniff",
                "X-Frame-Options": "DENY",
                "X-XSS-Protection": "1; mode=block",
            }
        }
    )

    # Configure CORS middleware
    setup_cors(app)
    
    # Register API routes
    setup_routes(app)
    
    return app

# Initialize the FastAPI application
app = init_app()