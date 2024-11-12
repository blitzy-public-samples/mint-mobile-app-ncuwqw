"""
Test suite for datetime utility functions.

Human Tasks:
1. Verify test environment has correct timezone configurations
2. Ensure pytz timezone database is up-to-date for holiday testing
3. Review and update test cases when business requirements change
"""

# Library versions:
# pytest: ^7.0.0
# datetime: ^3.9.0
# freezegun: ^1.2.0
# pytz: ^2021.3

import pytest
from datetime import datetime, timezone
from freezegun import freeze_time
from pytz import UTC

from app.utils.datetime import (
    parse_datetime,
    format_datetime,
    get_current_datetime,
    get_date_range,
    calculate_goal_progress,
    is_business_day
)
from app.constants import DATETIME_FORMAT, DATE_FORMAT

# Test cases for datetime string parsing
TEST_DATETIME_CASES = [
    (datetime_str='2024-01-01T12:00:00.000Z', expected=datetime(2024, 1, 1, 12, 0, tzinfo=UTC)),
    (datetime_str='2023-12-31T23:59:59.999Z', expected=datetime(2023, 12, 31, 23, 59, 59, 999000, tzinfo=UTC))
]

# Test cases for invalid datetime formats
INVALID_DATETIME_CASES = [
    'invalid',
    '2024-13-01T12:00:00.000Z',
    '2024-01-32T12:00:00.000Z',
    '2024-01-01 12:00:00'
]

# Test cases for datetime formatting
FORMAT_TEST_CASES = [
    (dt=datetime(2024, 1, 1, 12, 0, tzinfo=UTC), expected_str='2024-01-01T12:00:00.000Z'),
    (dt=datetime(2023, 12, 31, 23, 59, 59, 999000, tzinfo=UTC), expected_str='2023-12-31T23:59:59.999Z')
]

# Test cases for date range calculations
DATE_RANGE_CASES = [
    (period_type='daily', reference_date=datetime(2024, 1, 1, tzinfo=UTC),
     expected_range=(datetime(2024, 1, 1, tzinfo=UTC), datetime(2024, 1, 1, 23, 59, 59, 999999, tzinfo=UTC))),
    (period_type='monthly', reference_date=datetime(2024, 1, 15, tzinfo=UTC),
     expected_range=(datetime(2024, 1, 1, tzinfo=UTC), datetime(2024, 1, 31, 23, 59, 59, 999999, tzinfo=UTC)))
]

# Test cases for goal progress calculation
GOAL_PROGRESS_CASES = [
    (start_date=datetime(2024, 1, 1, tzinfo=UTC), target_date=datetime(2024, 12, 31, tzinfo=UTC), expected_progress=0.0),
    (start_date=datetime(2024, 1, 1, tzinfo=UTC), target_date=datetime(2024, 6, 30, tzinfo=UTC), expected_progress=50.0)
]

# Test cases for business day validation
BUSINESS_DAY_CASES = [
    (test_date=datetime(2024, 1, 1, tzinfo=UTC), expected_result=False),  # New Year's Day
    (test_date=datetime(2024, 1, 2, tzinfo=UTC), expected_result=True)    # Regular business day
]

@pytest.mark.parametrize('datetime_str,expected', TEST_DATETIME_CASES)
def test_parse_datetime_valid(datetime_str: str, expected: datetime) -> None:
    """
    Test parsing valid ISO format datetime strings to UTC datetime objects.
    
    Requirement 1.2 Scope/Financial Tracking:
    Validate transaction date handling using UTC timestamps
    """
    result = parse_datetime(datetime_str)
    assert result == expected
    assert result.tzinfo == timezone.utc

@pytest.mark.parametrize('invalid_str', INVALID_DATETIME_CASES)
def test_parse_datetime_invalid(invalid_str: str) -> None:
    """
    Test parsing invalid datetime strings raises ValueError.
    
    Requirement 1.2 Scope/Financial Tracking:
    Validate transaction date handling with proper error handling
    """
    with pytest.raises(ValueError) as exc_info:
        parse_datetime(invalid_str)
    assert "Invalid datetime format" in str(exc_info.value)

@pytest.mark.parametrize('dt,expected_str', FORMAT_TEST_CASES)
def test_format_datetime(dt: datetime, expected_str: str) -> None:
    """
    Test formatting datetime objects to ISO format strings.
    
    Requirement 1.2 Scope/Financial Tracking:
    Validate transaction date formatting with consistent ISO format
    """
    result = format_datetime(dt)
    assert result == expected_str
    assert len(result) == len(DATETIME_FORMAT.replace('%', '').replace('f', '000'))

@freeze_time('2024-01-01T12:00:00.000Z')
def test_get_current_datetime() -> None:
    """
    Test current UTC datetime retrieval with frozen time.
    
    Requirement 1.2 Scope/Financial Tracking:
    Validate consistent UTC timestamp generation
    """
    result = get_current_datetime()
    expected = datetime(2024, 1, 1, 12, 0, tzinfo=timezone.utc)
    assert result == expected
    assert result.tzinfo == timezone.utc

@pytest.mark.parametrize('period_type,reference_date,expected_range', DATE_RANGE_CASES)
def test_get_date_range(period_type: str, reference_date: datetime, expected_range: tuple) -> None:
    """
    Test period date range calculations with UTC boundaries.
    
    Requirement 1.2 Scope/Budget Management:
    Validate budget period calculations with consistent boundaries
    """
    start_date, end_date = get_date_range(period_type, reference_date)
    expected_start, expected_end = expected_range
    
    assert start_date == expected_start
    assert end_date == expected_end
    assert start_date.tzinfo == timezone.utc
    assert end_date.tzinfo == timezone.utc

@pytest.mark.parametrize('start_date,target_date,expected_progress', GOAL_PROGRESS_CASES)
@freeze_time('2024-01-01T12:00:00.000Z')
def test_calculate_goal_progress(start_date: datetime, target_date: datetime, expected_progress: float) -> None:
    """
    Test goal progress percentage calculation with UTC dates.
    
    Requirement 1.2 Scope/Goal Management:
    Verify goal timeline progress calculations
    """
    progress = calculate_goal_progress(start_date, target_date)
    assert progress == expected_progress
    assert 0 <= progress <= 100

@pytest.mark.parametrize('test_date,expected_result', BUSINESS_DAY_CASES)
def test_is_business_day(test_date: datetime, expected_result: bool) -> None:
    """
    Test business day validation with UTC dates.
    
    Requirement 1.2 Scope/Financial Tracking:
    Validate business day awareness for financial operations
    """
    result = is_business_day(test_date)
    assert result == expected_result