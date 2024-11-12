/**
 * HUMAN TASKS:
 * 1. Ensure zod v3.21.0 or higher is installed in package.json
 * 2. Configure ESLint rules for consistent string literals and regex patterns
 * 3. Set up unit tests for validation functions using Jest/Vitest
 */

import { z } from 'zod'; // v3.21.0
import { 
  Account, 
  AccountType, 
  Transaction, 
  TransactionType,
  Budget,
  BudgetPeriod 
} from '../types';

// Requirement: Data Security - Implement secure input validation to prevent injection attacks
const EMAIL_REGEX = /^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/;
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const CURRENCY_CODE_REGEX = /^[A-Z]{3}$/;
const AMOUNT_REGEX = /^\d+(\.\d{0,2})?$/;

// Requirement: Account Management - Validate user inputs for account management
export function validateEmail(email: string): boolean {
  if (!email || typeof email !== 'string') {
    return false;
  }
  return EMAIL_REGEX.test(email.trim());
}

// Requirement: Data Security - Implement secure password validation
export function validatePassword(password: string): { isValid: boolean; error?: string } {
  if (!password || typeof password !== 'string') {
    return { isValid: false, error: 'Password is required' };
  }

  const checks = [
    { condition: password.length >= 8, message: 'Password must be at least 8 characters long' },
    { condition: /[A-Z]/.test(password), message: 'Password must contain an uppercase letter' },
    { condition: /[a-z]/.test(password), message: 'Password must contain a lowercase letter' },
    { condition: /[0-9]/.test(password), message: 'Password must contain a number' },
    { condition: /[!@#$%^&*]/.test(password), message: 'Password must contain a special character (!@#$%^&*)' }
  ];

  for (const check of checks) {
    if (!check.condition) {
      return { isValid: false, error: check.message };
    }
  }

  return { isValid: true };
}

// Requirement: Financial Tracking - Validate financial inputs
export function validateAmount(amount: number): boolean {
  if (!Number.isFinite(amount) || amount < 0) {
    return false;
  }
  
  const amountStr = amount.toFixed(2);
  return AMOUNT_REGEX.test(amountStr);
}

// Requirement: Account Management - Validate financial account data
export function validateAccountData(accountData: Partial<Account>): { isValid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Required fields validation
  if (!accountData.name?.trim()) {
    errors.push('Account name is required');
  }
  if (!accountData.type) {
    errors.push('Account type is required');
  }
  if (!accountData.institutionId) {
    errors.push('Institution ID is required');
  }

  // Account type validation
  if (accountData.type && !Object.values(AccountType).includes(accountData.type)) {
    errors.push('Invalid account type');
  }

  // Balance validation
  if (accountData.balance !== undefined && !validateAmount(accountData.balance)) {
    errors.push('Invalid balance format');
  }

  // Institution ID validation
  if (accountData.institutionId && !UUID_REGEX.test(accountData.institutionId)) {
    errors.push('Invalid institution ID format');
  }

  // Currency code validation
  if (accountData.currency && !CURRENCY_CODE_REGEX.test(accountData.currency)) {
    errors.push('Invalid currency code format');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}

// Requirement: Financial Tracking - Validate transaction data
export function validateTransactionData(transactionData: Partial<Transaction>): { isValid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Required fields validation
  if (!transactionData.amount && transactionData.amount !== 0) {
    errors.push('Transaction amount is required');
  }
  if (!transactionData.type) {
    errors.push('Transaction type is required');
  }
  if (!transactionData.date) {
    errors.push('Transaction date is required');
  }
  if (!transactionData.categoryId) {
    errors.push('Category ID is required');
  }

  // Amount validation
  if (transactionData.amount !== undefined && !validateAmount(transactionData.amount)) {
    errors.push('Invalid amount format');
  }

  // Transaction type validation
  if (transactionData.type && !Object.values(TransactionType).includes(transactionData.type)) {
    errors.push('Invalid transaction type');
  }

  // Date validation
  if (transactionData.date) {
    const date = new Date(transactionData.date);
    if (isNaN(date.getTime()) || date > new Date()) {
      errors.push('Invalid transaction date');
    }
  }

  // Category ID validation
  if (transactionData.categoryId && !UUID_REGEX.test(transactionData.categoryId)) {
    errors.push('Invalid category ID format');
  }

  // Description validation
  if (transactionData.description && 
      (transactionData.description.length > 255 || /[<>]/.test(transactionData.description))) {
    errors.push('Invalid description format');
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}

// Requirement: Financial Tracking - Validate budget data
export function validateBudgetData(budgetData: Partial<Budget>): { isValid: boolean; errors: string[] } {
  const errors: string[] = [];

  // Required fields validation
  if (!budgetData.amount && budgetData.amount !== 0) {
    errors.push('Budget amount is required');
  }
  if (!budgetData.period) {
    errors.push('Budget period is required');
  }
  if (!budgetData.startDate) {
    errors.push('Start date is required');
  }
  if (!budgetData.endDate) {
    errors.push('End date is required');
  }

  // Amount validation
  if (budgetData.amount !== undefined && !validateAmount(budgetData.amount)) {
    errors.push('Invalid budget amount format');
  }

  // Period validation
  if (budgetData.period && !Object.values(BudgetPeriod).includes(budgetData.period)) {
    errors.push('Invalid budget period');
  }

  // Date range validation
  if (budgetData.startDate && budgetData.endDate) {
    const startDate = new Date(budgetData.startDate);
    const endDate = new Date(budgetData.endDate);
    
    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      errors.push('Invalid date format');
    } else if (endDate <= startDate) {
      errors.push('End date must be after start date');
    }
  }

  // Alert threshold validation
  if (budgetData.alertThreshold !== undefined) {
    if (!Number.isFinite(budgetData.alertThreshold) || 
        budgetData.alertThreshold < 0 || 
        budgetData.alertThreshold > 100) {
      errors.push('Alert threshold must be between 0 and 100');
    }
  }

  return {
    isValid: errors.length === 0,
    errors
  };
}