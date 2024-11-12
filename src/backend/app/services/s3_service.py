"""
S3 storage service module for Mint Replica Lite backend application.

Human Tasks:
1. Configure AWS IAM roles with appropriate S3 permissions
2. Set up S3 bucket with server-side encryption
3. Configure cross-region replication for high availability
4. Review and set up appropriate bucket policies
5. Configure AWS KMS keys for encryption
"""

# Library versions:
# boto3: ^1.26.0
# botocore: ^1.29.0
# typing: ^3.9.0

from functools import lru_cache
from typing import Dict, Optional

import boto3
from botocore.exceptions import ClientError

from ..core.config import Settings
from ..core.logging import get_logger
from ..core.errors import BaseAppException

class S3StorageError(BaseAppException):
    """
    Custom exception class for S3 storage related errors.
    
    Requirement: Data Security - Error handling for S3 storage operations
    """
    def __init__(self, message: str, details: Dict) -> None:
        super().__init__(message=message, status_code=500, details=details)
        self._logger = get_logger(__name__)
        self._logger.bind({
            "error_type": "S3StorageError",
            "details": details
        }).error(message)

class S3Service:
    """
    Service class for handling S3 storage operations with encryption and security.
    
    Requirement: Object Storage - S3 storage for documents and files with server-side encryption
    Requirement: Data Security - File encryption for data at rest in S3 storage using AWS KMS
    """
    def __init__(self) -> None:
        """Initialize S3 service with AWS configuration and logging."""
        self._logger = get_logger(__name__)
        
        # Get AWS settings
        aws_settings = Settings().get_aws_settings()
        
        # Initialize S3 client with AWS credentials
        self._s3_client = boto3.client(
            's3',
            aws_access_key_id=aws_settings['aws_access_key_id'],
            aws_secret_access_key=aws_settings['aws_secret_access_key'],
            region_name=aws_settings['region_name'],
            endpoint_url=aws_settings.get('endpoint_url'),
            use_ssl=aws_settings['use_ssl']
        )
        
        self._bucket_name = aws_settings['s3_bucket']
        
        if not self._bucket_name:
            raise S3StorageError(
                message="S3 bucket name not configured",
                details={"configuration": "S3_BUCKET_NAME environment variable is required"}
            )

    def upload_file(self, file_data: bytes, file_key: str, content_type: str) -> str:
        """
        Upload file to S3 bucket with server-side encryption.
        
        Requirement: Data Security - File encryption for data at rest in S3 storage using AWS KMS
        """
        self._logger.bind({
            "action": "upload",
            "file_key": file_key,
            "content_type": content_type,
            "file_size": len(file_data)
        }).info("Uploading file to S3")

        try:
            # Upload with AES-256 server-side encryption
            self._s3_client.put_object(
                Bucket=self._bucket_name,
                Key=file_key,
                Body=file_data,
                ContentType=content_type,
                ServerSideEncryption='AES256'
            )
            
            # Generate the file URL
            url = f"https://{self._bucket_name}.s3.amazonaws.com/{file_key}"
            
            self._logger.bind({
                "file_key": file_key,
                "url": url
            }).info("File uploaded successfully")
            
            return url
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            error_message = e.response['Error']['Message']
            raise S3StorageError(
                message=f"Failed to upload file: {error_message}",
                details={
                    "error_code": error_code,
                    "file_key": file_key
                }
            )

    def download_file(self, file_key: str) -> bytes:
        """
        Download file from S3 bucket with decryption.
        
        Requirement: Object Storage - Secure file downloads from S3
        """
        self._logger.bind({
            "action": "download",
            "file_key": file_key
        }).info("Downloading file from S3")

        try:
            response = self._s3_client.get_object(
                Bucket=self._bucket_name,
                Key=file_key
            )
            
            file_data = response['Body'].read()
            
            self._logger.bind({
                "file_key": file_key,
                "content_length": len(file_data)
            }).info("File downloaded successfully")
            
            return file_data
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == 'NoSuchKey':
                raise S3StorageError(
                    message="File not found",
                    details={
                        "error_code": error_code,
                        "file_key": file_key
                    }
                )
            raise S3StorageError(
                message=f"Failed to download file: {e.response['Error']['Message']}",
                details={
                    "error_code": error_code,
                    "file_key": file_key
                }
            )

    def delete_file(self, file_key: str) -> bool:
        """
        Delete file from S3 bucket securely.
        
        Requirement: Object Storage - Secure file management in S3
        """
        self._logger.bind({
            "action": "delete",
            "file_key": file_key
        }).info("Deleting file from S3")

        try:
            self._s3_client.delete_object(
                Bucket=self._bucket_name,
                Key=file_key
            )
            
            self._logger.bind({
                "file_key": file_key
            }).info("File deleted successfully")
            
            return True
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            raise S3StorageError(
                message=f"Failed to delete file: {e.response['Error']['Message']}",
                details={
                    "error_code": error_code,
                    "file_key": file_key
                }
            )

    def generate_presigned_url(self, file_key: str, expiration: int) -> str:
        """
        Generate secure presigned URL for temporary file access.
        
        Requirement: Data Security - Secure temporary file access
        """
        self._logger.bind({
            "action": "generate_presigned_url",
            "file_key": file_key,
            "expiration": expiration
        }).info("Generating presigned URL")

        try:
            url = self._s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self._bucket_name,
                    'Key': file_key
                },
                ExpiresIn=expiration
            )
            
            self._logger.bind({
                "file_key": file_key,
                "expiration": expiration,
                "url": url
            }).info("Presigned URL generated successfully")
            
            return url
            
        except ClientError as e:
            error_code = e.response['Error']['Code']
            raise S3StorageError(
                message=f"Failed to generate presigned URL: {e.response['Error']['Message']}",
                details={
                    "error_code": error_code,
                    "file_key": file_key,
                    "expiration": expiration
                }
            )

@lru_cache()
def get_s3_service() -> S3Service:
    """
    Factory function to get cached S3 service instance.
    
    Requirement: Infrastructure Integration - Efficient S3 service instance management
    """
    return S3Service()