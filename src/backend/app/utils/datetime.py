"""
Utility module providing standardized datetime operations and formatting functions.

Human Tasks:
1. Verify timezone configurations in deployment environment
2. Ensure pytz timezone database is up-to-date for accurate holiday calculations
3. Review and update business day holiday calendar as needed
"""

# Library versions:
# datetime: ^3.9.0
# pytz: ^2021.3
# typing: ^3.9.0

from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
import pytz

from app.constants import DATETIME_FORMAT, DATE_FORMAT

def parse_datetime(datetime_str: str) -> datetime:
    """
    Parses datetime string into UTC datetime object.
    
    Requirement 1.2 Scope/Financial Tracking:
    Support transaction date handling with standardized UTC timestamps
    """
    if not datetime_str:
        raise ValueError("Datetime string cannot be empty")
    
    try:
        dt = datetime.strptime(datetime_str, DATETIME_FORMAT)
        return dt.replace(tzinfo=timezone.utc)
    except ValueError as e:
        raise ValueError(f"Invalid datetime format. Expected {DATETIME_FORMAT}: {str(e)}")

def format_datetime(dt: datetime) -> str:
    """
    Formats datetime object to standard ISO string format.
    
    Requirement 1.2 Scope/Financial Tracking:
    Support transaction date handling with standardized UTC timestamps
    """
    if not dt:
        raise ValueError("Datetime object cannot be None")
    
    # Convert to UTC if needed
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    elif dt.tzinfo != timezone.utc:
        dt = dt.astimezone(timezone.utc)
    
    return dt.strftime(DATETIME_FORMAT)

def get_current_datetime() -> datetime:
    """
    Gets current UTC datetime.
    
    Requirement 1.2 Scope/Financial Tracking:
    Support transaction date handling with standardized UTC timestamps
    """
    return datetime.now(timezone.utc)

def get_date_range(period_type: str, reference_date: datetime) -> Tuple[datetime, datetime]:
    """
    Calculates date range for budget/transaction periods.
    
    Requirement 1.2 Scope/Budget Management:
    Enable budget period calculations with consistent period boundaries
    """
    valid_periods = {'daily', 'weekly', 'monthly', 'yearly'}
    if period_type not in valid_periods:
        raise ValueError(f"Invalid period type. Must be one of: {', '.join(valid_periods)}")
    
    if not reference_date:
        raise ValueError("Reference date cannot be None")
    
    # Ensure UTC timezone
    if reference_date.tzinfo is None:
        reference_date = reference_date.replace(tzinfo=timezone.utc)
    
    start_date = None
    end_date = None
    
    if period_type == 'daily':
        start_date = reference_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=1)
    elif period_type == 'weekly':
        start_date = reference_date - timedelta(days=reference_date.weekday())
        start_date = start_date.replace(hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date + timedelta(days=7)
    elif period_type == 'monthly':
        start_date = reference_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        if reference_date.month == 12:
            end_date = start_date.replace(year=reference_date.year + 1, month=1)
        else:
            end_date = start_date.replace(month=reference_date.month + 1)
    else:  # yearly
        start_date = reference_date.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        end_date = start_date.replace(year=reference_date.year + 1)
    
    return start_date, end_date

def calculate_goal_progress(start_date: datetime, target_date: datetime) -> float:
    """
    Calculates time-based goal progress percentage.
    
    Requirement 1.2 Scope/Goal Management:
    Support goal timeline tracking with precise progress calculations
    """
    if not start_date or not target_date:
        raise ValueError("Start date and target date cannot be None")
    
    # Ensure UTC timezone
    if start_date.tzinfo is None:
        start_date = start_date.replace(tzinfo=timezone.utc)
    if target_date.tzinfo is None:
        target_date = target_date.replace(tzinfo=timezone.utc)
    
    current_date = get_current_datetime()
    
    # Calculate total and elapsed durations
    total_duration = (target_date - start_date).total_seconds()
    elapsed_duration = (current_date - start_date).total_seconds()
    
    if total_duration <= 0:
        raise ValueError("Target date must be after start date")
    
    # Calculate progress percentage
    progress = (elapsed_duration / total_duration) * 100
    
    # Cap progress at 100%
    return min(max(progress, 0), 100)

def is_business_day(date: datetime) -> bool:
    """
    Checks if given date is a business day for investment tracking.
    
    Requirement 1.2 Scope/Financial Tracking:
    Support investment tracking with business day awareness
    """
    if not date:
        raise ValueError("Date cannot be None")
    
    # Ensure UTC timezone
    if date.tzinfo is None:
        date = date.replace(tzinfo=timezone.utc)
    
    # Convert to US/Eastern for market hours
    us_eastern = pytz.timezone('US/Eastern')
    date_eastern = date.astimezone(us_eastern)
    
    # Check if weekend
    if date_eastern.weekday() >= 5:  # Saturday = 5, Sunday = 6
        return False
    
    # Get US holidays calendar
    us_holidays = pytz.US.holidays()
    
    # Check if holiday
    if date_eastern.date() in us_holidays:
        return False
    
    return True