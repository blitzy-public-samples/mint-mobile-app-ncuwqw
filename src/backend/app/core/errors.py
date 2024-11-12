"""
Core error handling module for Mint Replica Lite backend application.

Human Tasks:
1. Review error logging configuration in production environment
2. Verify ELK Stack integration for error tracking
3. Confirm error response format meets API documentation requirements
4. Set up monitoring alerts for critical error patterns
"""

# Library versions:
# fastapi: ^0.68.0
# pydantic: ^1.8.2
# typing: ^3.9.0

from datetime import datetime
from typing import Dict, Optional

from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import ValidationError as PydanticValidationError

from ..constants import API_VERSION
from ..core.logging import get_logger

# Initialize logger for error handling
logger = get_logger(__name__)

class BaseAppException(Exception):
    """
    Base exception class for all application-specific exceptions.
    
    Requirement: Error Handling - Standardized error handling and reporting across all system components
    """
    def __init__(self, message: str, status_code: int, details: Optional[Dict] = None) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        self._logger = get_logger(__name__)
        
        # Log error with structured context
        self._logger.bind({
            "status_code": status_code,
            "error_type": self.__class__.__name__,
            "details": self.details
        }).error(message)

class AuthenticationError(BaseAppException):
    """
    Exception for authentication-related errors.
    
    Requirement: Security Error Management - Security-related error handling and logging requirements
    """
    def __init__(self, message: str, details: Optional[Dict] = None) -> None:
        super().__init__(message=message, status_code=401, details=details)

class AuthorizationError(BaseAppException):
    """
    Exception for authorization-related errors.
    
    Requirement: Security Error Management - Security-related error handling and logging requirements
    """
    def __init__(self, message: str, details: Optional[Dict] = None) -> None:
        super().__init__(message=message, status_code=403, details=details)

class ValidationError(BaseAppException):
    """
    Exception for data validation errors.
    
    Requirement: API Error Responses - Standardized API error response format and handling
    """
    def __init__(self, message: str, details: Optional[Dict] = None) -> None:
        super().__init__(message=message, status_code=422, details=details)

class NotFoundError(BaseAppException):
    """
    Exception for resource not found errors.
    
    Requirement: API Error Responses - Standardized API error response format and handling
    """
    def __init__(self, message: str, details: Optional[Dict] = None) -> None:
        super().__init__(message=message, status_code=404, details=details)

def format_error_response(message: str, status_code: int, details: Optional[Dict] = None) -> Dict:
    """
    Format error responses in a standardized structure.
    
    Requirement: API Error Responses - Standardized API error response format and handling
    """
    response = {
        "error": {
            "message": message,
            "status_code": status_code,
            "timestamp": datetime.utcnow().isoformat(),
            "api_version": API_VERSION
        }
    }
    
    if details:
        response["error"]["details"] = details
    
    return response

async def handle_application_error(request: Request, error: BaseAppException) -> JSONResponse:
    """
    Global error handler for converting application exceptions to FastAPI responses.
    
    Requirement: Error Handling - Standardized error handling and reporting across all system components
    """
    logger.bind({
        "endpoint": str(request.url),
        "method": request.method,
        "client_host": request.client.host if request.client else None,
        "error_type": error.__class__.__name__
    }).error(error.message)
    
    return JSONResponse(
        status_code=error.status_code,
        content=format_error_response(
            message=error.message,
            status_code=error.status_code,
            details=error.details
        )
    )

async def handle_validation_error(request: Request, error: RequestValidationError) -> JSONResponse:
    """
    Handler for Pydantic validation errors.
    
    Requirement: API Error Responses - Standardized API error response format and handling
    """
    error_details = []
    for err in error.errors():
        error_details.append({
            "loc": " -> ".join(str(x) for x in err["loc"]),
            "msg": err["msg"],
            "type": err["type"]
        })
    
    logger.bind({
        "endpoint": str(request.url),
        "method": request.method,
        "validation_errors": error_details
    }).error("Request validation failed")
    
    return JSONResponse(
        status_code=422,
        content=format_error_response(
            message="Request validation failed",
            status_code=422,
            details={"validation_errors": error_details}
        )
    )