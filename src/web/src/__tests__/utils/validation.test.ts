/**
 * HUMAN TASKS:
 * 1. Ensure Jest ^29.0.0 is installed in package.json
 * 2. Configure Jest to handle TypeScript files
 * 3. Set up test coverage reporting
 */

import { describe, test, expect } from '@jest/globals'; // ^29.0.0
import {
  validateEmail,
  validatePassword,
  validateAmount,
  validateAccountData,
  validateTransactionData,
  validateBudgetData
} from '../../utils/validation';
import { Account, AccountType, Transaction, TransactionType, Budget, BudgetPeriod } from '../../types';

// Requirement: Data Security - Test secure input validation implementation
describe('validateEmail', () => {
  test('should validate correct email formats', () => {
    expect(validateEmail('user@example.com')).toBe(true);
    expect(validateEmail('user.name@subdomain.example.co.uk')).toBe(true);
    expect(validateEmail('user+tag@example.com')).toBe(true);
  });

  test('should reject invalid email formats', () => {
    expect(validateEmail('invalid-email')).toBe(false);
    expect(validateEmail('user@')).toBe(false);
    expect(validateEmail('@domain.com')).toBe(false);
    expect(validateEmail('user@.com')).toBe(false);
  });

  test('should handle empty or null inputs', () => {
    expect(validateEmail('')).toBe(false);
    expect(validateEmail(null as any)).toBe(false);
    expect(validateEmail(undefined as any)).toBe(false);
  });

  test('should handle special characters correctly', () => {
    expect(validateEmail('user!@example.com')).toBe(false);
    expect(validateEmail('user#@example.com')).toBe(false);
    expect(validateEmail('user$@example.com')).toBe(false);
  });
});

// Requirement: Data Security - Test password validation implementation
describe('validatePassword', () => {
  test('should validate correct password formats', () => {
    expect(validatePassword('Password123!')).toEqual({ isValid: true });
    expect(validatePassword('Complex@Pass999')).toEqual({ isValid: true });
  });

  test('should enforce minimum length requirement', () => {
    expect(validatePassword('Pass1!')).toEqual({
      isValid: false,
      error: 'Password must be at least 8 characters long'
    });
  });

  test('should require uppercase letter', () => {
    expect(validatePassword('password123!')).toEqual({
      isValid: false,
      error: 'Password must contain an uppercase letter'
    });
  });

  test('should require lowercase letter', () => {
    expect(validatePassword('PASSWORD123!')).toEqual({
      isValid: false,
      error: 'Password must contain a lowercase letter'
    });
  });

  test('should require number', () => {
    expect(validatePassword('Password!')).toEqual({
      isValid: false,
      error: 'Password must contain a number'
    });
  });

  test('should require special character', () => {
    expect(validatePassword('Password123')).toEqual({
      isValid: false,
      error: 'Password must contain a special character (!@#$%^&*)'
    });
  });

  test('should handle empty or null inputs', () => {
    expect(validatePassword('')).toEqual({
      isValid: false,
      error: 'Password is required'
    });
    expect(validatePassword(null as any)).toEqual({
      isValid: false,
      error: 'Password is required'
    });
  });
});

// Requirement: Financial Tracking - Test financial amount validation
describe('validateAmount', () => {
  test('should validate correct amount formats', () => {
    expect(validateAmount(100)).toBe(true);
    expect(validateAmount(99.99)).toBe(true);
    expect(validateAmount(0)).toBe(true);
  });

  test('should handle decimal places correctly', () => {
    expect(validateAmount(100.999)).toBe(false);
    expect(validateAmount(99.9)).toBe(true);
  });

  test('should reject negative amounts', () => {
    expect(validateAmount(-100)).toBe(false);
    expect(validateAmount(-0.01)).toBe(false);
  });

  test('should handle invalid inputs', () => {
    expect(validateAmount(NaN)).toBe(false);
    expect(validateAmount(Infinity)).toBe(false);
    expect(validateAmount(null as any)).toBe(false);
  });
});

// Requirement: Account Management - Test account data validation
describe('validateAccountData', () => {
  const validAccount: Partial<Account> = {
    name: 'Checking Account',
    type: AccountType.CHECKING,
    institutionId: '123e4567-e89b-42d3-a456-556642440000',
    balance: 1000,
    currency: 'USD'
  };

  test('should validate correct account data', () => {
    expect(validateAccountData(validAccount)).toEqual({
      isValid: true,
      errors: []
    });
  });

  test('should require mandatory fields', () => {
    const result = validateAccountData({});
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Account name is required');
    expect(result.errors).toContain('Account type is required');
    expect(result.errors).toContain('Institution ID is required');
  });

  test('should validate account type', () => {
    const invalidType = {
      ...validAccount,
      type: 'INVALID_TYPE' as AccountType
    };
    const result = validateAccountData(invalidType);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Invalid account type');
  });

  test('should validate balance format', () => {
    const invalidBalance = {
      ...validAccount,
      balance: -100
    };
    const result = validateAccountData(invalidBalance);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Invalid balance format');
  });

  test('should validate currency code', () => {
    const invalidCurrency = {
      ...validAccount,
      currency: 'INVALID'
    };
    const result = validateAccountData(invalidCurrency);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Invalid currency code format');
  });
});

// Requirement: Financial Tracking - Test transaction data validation
describe('validateTransactionData', () => {
  const validTransaction: Partial<Transaction> = {
    amount: 100,
    type: TransactionType.DEBIT,
    date: new Date(),
    categoryId: '123e4567-e89b-42d3-a456-556642440000',
    description: 'Test transaction'
  };

  test('should validate correct transaction data', () => {
    expect(validateTransactionData(validTransaction)).toEqual({
      isValid: true,
      errors: []
    });
  });

  test('should require mandatory fields', () => {
    const result = validateTransactionData({});
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Transaction amount is required');
    expect(result.errors).toContain('Transaction type is required');
    expect(result.errors).toContain('Transaction date is required');
    expect(result.errors).toContain('Category ID is required');
  });

  test('should validate amount format', () => {
    const invalidAmount = {
      ...validTransaction,
      amount: -100
    };
    const result = validateTransactionData(invalidAmount);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Invalid amount format');
  });

  test('should validate transaction type', () => {
    const invalidType = {
      ...validTransaction,
      type: 'INVALID_TYPE' as TransactionType
    };
    const result = validateTransactionData(invalidType);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Invalid transaction type');
  });

  test('should validate description format', () => {
    const invalidDescription = {
      ...validTransaction,
      description: '<script>alert("test")</script>'
    };
    const result = validateTransactionData(invalidDescription);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Invalid description format');
  });
});

// Requirement: Financial Tracking - Test budget data validation
describe('validateBudgetData', () => {
  const validBudget: Partial<Budget> = {
    amount: 1000,
    period: BudgetPeriod.MONTHLY,
    startDate: new Date(),
    endDate: new Date(Date.now() + 86400000), // Tomorrow
    alertThreshold: 80
  };

  test('should validate correct budget data', () => {
    expect(validateBudgetData(validBudget)).toEqual({
      isValid: true,
      errors: []
    });
  });

  test('should require mandatory fields', () => {
    const result = validateBudgetData({});
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Budget amount is required');
    expect(result.errors).toContain('Budget period is required');
    expect(result.errors).toContain('Start date is required');
    expect(result.errors).toContain('End date is required');
  });

  test('should validate amount format', () => {
    const invalidAmount = {
      ...validBudget,
      amount: -100
    };
    const result = validateBudgetData(invalidAmount);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Invalid budget amount format');
  });

  test('should validate budget period', () => {
    const invalidPeriod = {
      ...validBudget,
      period: 'INVALID_PERIOD' as BudgetPeriod
    };
    const result = validateBudgetData(invalidPeriod);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Invalid budget period');
  });

  test('should validate date range', () => {
    const invalidDates = {
      ...validBudget,
      startDate: new Date(),
      endDate: new Date(Date.now() - 86400000) // Yesterday
    };
    const result = validateBudgetData(invalidDates);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('End date must be after start date');
  });

  test('should validate alert threshold', () => {
    const invalidThreshold = {
      ...validBudget,
      alertThreshold: 150
    };
    const result = validateBudgetData(invalidThreshold);
    expect(result.isValid).toBe(false);
    expect(result.errors).toContain('Alert threshold must be between 0 and 100');
  });
});