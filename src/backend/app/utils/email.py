"""
Email utility module for Mint Replica Lite backend application.

Human Tasks:
1. Set up AWS SES account and obtain credentials
2. Configure SES sandbox or request production access
3. Verify sender email addresses in AWS SES
4. Create and test email templates in development environment
5. Set up email bounce and complaint handling in AWS
"""

# Library versions:
# boto3: ^1.26.0
# jinja2: ^3.0.0
# pydantic: ^1.8.2
# typing: ^3.9.0

import json
from typing import Dict, List, Optional, Tuple, Any
import boto3
from jinja2 import Environment, Template, select_autoescape
from pydantic import BaseModel, EmailStr

from ..core.config import Settings
from ..core.logging import get_logger
from .validators import validate_email

class EmailTemplate:
    """
    Class for managing and rendering email templates using Jinja2.
    
    Requirement: System Notifications - Handle email notifications through notification service
    """
    
    def __init__(self, template_name: str, subject: str, html_content: str, text_content: str):
        if not all([template_name, subject, html_content, text_content]):
            raise ValueError("All template parameters must be provided")
        
        self.template_name = template_name
        self.subject = subject
        self.html_content = html_content
        self.text_content = text_content
        
        # Initialize Jinja2 environment with security settings
        self.jinja_env = Environment(
            autoescape=select_autoescape(['html', 'xml']),
            trim_blocks=True,
            lstrip_blocks=True
        )
        
        # Pre-compile templates for efficiency
        self._subject_template = self.jinja_env.from_string(subject)
        self._html_template = self.jinja_env.from_string(html_content)
        self._text_template = self.jinja_env.from_string(text_content)

    def render(self, context: Dict[str, Any]) -> Tuple[str, str, str]:
        """
        Render email template with provided context.
        
        Requirement: Budget Alerts - Send email notifications for budget thresholds and alerts
        """
        if not isinstance(context, dict):
            raise ValueError("Context must be a dictionary")
        
        try:
            rendered_subject = self._subject_template.render(context)
            rendered_html = self._html_template.render(context)
            rendered_text = self._text_template.render(context)
            
            return rendered_subject, rendered_html, rendered_text
        except Exception as e:
            raise ValueError(f"Template rendering failed: {str(e)}")

class EmailSender:
    """
    Class for sending emails using AWS SES with logging and error handling.
    
    Requirement: System Notifications - Handle email notifications through notification service
    """
    
    def __init__(self, sender_email: str):
        # Validate sender email
        if not validate_email(sender_email):
            raise ValueError("Invalid sender email address")
        
        self.sender_email = sender_email
        self.logger = get_logger("EmailSender")
        
        # Initialize AWS SES client
        aws_settings = Settings().get_aws_settings()
        self.ses_client = boto3.client(
            'ses',
            aws_access_key_id=aws_settings['aws_access_key_id'],
            aws_secret_access_key=aws_settings['aws_secret_access_key'],
            region_name=aws_settings['region_name']
        )
        
        # Initialize template storage
        self.templates: Dict[str, EmailTemplate] = {}

    def send_email(
        self,
        template_name: str,
        recipient_email: str,
        context: Dict[str, Any],
        cc_list: Optional[List[str]] = None,
        bcc_list: Optional[List[str]] = None
    ) -> bool:
        """
        Send email using specified template with error handling.
        
        Requirement: Security Notifications - Send security-related notifications and alerts
        """
        try:
            # Validate recipient email
            if not validate_email(recipient_email):
                raise ValueError("Invalid recipient email address")
            
            # Validate CC and BCC emails if provided
            if cc_list:
                for cc_email in cc_list:
                    if not validate_email(cc_email):
                        raise ValueError(f"Invalid CC email address: {cc_email}")
            
            if bcc_list:
                for bcc_email in bcc_list:
                    if not validate_email(bcc_email):
                        raise ValueError(f"Invalid BCC email address: {bcc_email}")
            
            # Get and render template
            template = self.templates.get(template_name)
            if not template:
                raise ValueError(f"Template not found: {template_name}")
            
            subject, html_content, text_content = template.render(context)
            
            # Prepare email message
            message = {
                'Subject': {'Data': subject},
                'Body': {
                    'Html': {'Data': html_content},
                    'Text': {'Data': text_content}
                }
            }
            
            # Prepare recipient list
            destination = {
                'ToAddresses': [recipient_email],
                'CcAddresses': cc_list or [],
                'BccAddresses': bcc_list or []
            }
            
            # Send email via AWS SES
            response = self.ses_client.send_email(
                Source=self.sender_email,
                Destination=destination,
                Message=message
            )
            
            self.logger.bind({
                'event': 'email_sent',
                'template': template_name,
                'recipient': recipient_email,
                'message_id': response['MessageId']
            }).info("Email sent successfully")
            
            return True
            
        except Exception as e:
            self.logger.bind({
                'event': 'email_error',
                'template': template_name,
                'recipient': recipient_email,
                'error': str(e)
            }).error("Failed to send email")
            
            return False

    def send_bulk_email(
        self,
        template_name: str,
        recipient_emails: List[str],
        context: Dict[str, Any]
    ) -> Dict[str, bool]:
        """
        Send same email to multiple recipients efficiently.
        
        Requirement: Budget Alerts - Send email notifications for budget thresholds and alerts
        """
        results: Dict[str, bool] = {}
        
        try:
            # Validate all recipient emails first
            for email in recipient_emails:
                if not validate_email(email):
                    raise ValueError(f"Invalid recipient email address: {email}")
            
            # Get and render template once for efficiency
            template = self.templates.get(template_name)
            if not template:
                raise ValueError(f"Template not found: {template_name}")
            
            subject, html_content, text_content = template.render(context)
            
            # Prepare base message
            message = {
                'Subject': {'Data': subject},
                'Body': {
                    'Html': {'Data': html_content},
                    'Text': {'Data': text_content}
                }
            }
            
            # Send to each recipient in batches of 50 (AWS SES limit)
            batch_size = 50
            for i in range(0, len(recipient_emails), batch_size):
                batch = recipient_emails[i:i + batch_size]
                
                for email in batch:
                    try:
                        response = self.ses_client.send_email(
                            Source=self.sender_email,
                            Destination={'ToAddresses': [email]},
                            Message=message
                        )
                        results[email] = True
                        
                        self.logger.bind({
                            'event': 'bulk_email_sent',
                            'template': template_name,
                            'recipient': email,
                            'message_id': response['MessageId']
                        }).info("Bulk email sent successfully")
                        
                    except Exception as e:
                        results[email] = False
                        self.logger.bind({
                            'event': 'bulk_email_error',
                            'template': template_name,
                            'recipient': email,
                            'error': str(e)
                        }).error("Failed to send bulk email")
            
            return results
            
        except Exception as e:
            self.logger.bind({
                'event': 'bulk_email_error',
                'template': template_name,
                'error': str(e)
            }).error("Bulk email operation failed")
            
            return {email: False for email in recipient_emails}

def create_email_content(
    subject: str,
    body: str,
    template_vars: Optional[Dict[str, Any]] = None
) -> Tuple[str, str]:
    """
    Create email content with proper formatting and escaping.
    
    Requirement: System Notifications - Handle email notifications through notification service
    """
    if not subject or not body:
        raise ValueError("Subject and body are required")
    
    try:
        # Create Jinja2 environment for content creation
        env = Environment(
            autoescape=select_autoescape(['html']),
            trim_blocks=True,
            lstrip_blocks=True
        )
        
        # Apply template variables if provided
        if template_vars:
            subject_template = env.from_string(subject)
            body_template = env.from_string(body)
            
            subject = subject_template.render(template_vars)
            body = body_template.render(template_vars)
        
        # Create HTML version with basic formatting
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{subject}</title>
        </head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            {body}
        </body>
        </html>
        """
        
        # Create plain text version
        text_content = body.replace('<br>', '\n').replace('<p>', '\n').replace('</p>', '\n')
        
        return html_content.strip(), text_content.strip()
        
    except Exception as e:
        raise ValueError(f"Failed to create email content: {str(e)}")