// date-fns version: ^2.30.0
// react-native version: ^0.71.0

/**
 * HUMAN TASKS:
 * 1. Verify locale settings in production environment match target markets
 * 2. Ensure currency codes are up-to-date with supported financial institutions
 * 3. Review date format patterns for consistency with UX requirements
 */

import { format } from 'date-fns';
import { APP_NAME } from '../constants/config';

/**
 * Formats a number as currency with proper locale and symbol
 * Requirement 5.1.2: Financial Data Display - Format currency for account summaries
 */
export const formatCurrency = (amount: number, currencyCode: string): string => {
  if (!Number.isFinite(amount)) {
    throw new Error('Invalid amount provided for currency formatting');
  }

  try {
    const formatter = new Intl.NumberFormat(undefined, {
      style: 'currency',
      currency: currencyCode,
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
    return formatter.format(amount);
  } catch (error) {
    console.error(`[${APP_NAME}] Currency formatting error:`, error);
    return `${currencyCode} ${amount.toFixed(2)}`;
  }
};

/**
 * Formats a date string or timestamp into human-readable format
 * Requirement 5.1.3: Date/Time Formatting - Format transaction dates consistently
 */
export const formatDate = (
  date: Date | number | string,
  formatString: string
): string => {
  try {
    const dateObject = date instanceof Date ? date : new Date(date);
    if (isNaN(dateObject.getTime())) {
      throw new Error('Invalid date');
    }
    return format(dateObject, formatString);
  } catch (error) {
    console.error(`[${APP_NAME}] Date formatting error:`, error);
    return 'Invalid Date';
  }
};

/**
 * Formats a decimal number as a percentage with specified precision
 * Requirement 5.1.5: Investment Data Display - Format investment percentages
 */
export const formatPercentage = (value: number, decimalPlaces: number): string => {
  if (!Number.isFinite(value)) {
    throw new Error('Invalid value provided for percentage formatting');
  }

  try {
    const formatter = new Intl.NumberFormat(undefined, {
      style: 'percent',
      minimumFractionDigits: decimalPlaces,
      maximumFractionDigits: decimalPlaces
    });
    return formatter.format(value);
  } catch (error) {
    console.error(`[${APP_NAME}] Percentage formatting error:`, error);
    return `${(value * 100).toFixed(decimalPlaces)}%`;
  }
};

/**
 * Formats numbers with locale-specific thousand separators and decimal points
 * Requirement 5.1.5: Investment Data Display - Format investment amounts
 */
export const formatNumber = (
  value: number,
  options: Intl.NumberFormatOptions = {}
): string => {
  if (!Number.isFinite(value)) {
    throw new Error('Invalid value provided for number formatting');
  }

  try {
    const formatter = new Intl.NumberFormat(undefined, {
      minimumFractionDigits: 0,
      maximumFractionDigits: 2,
      ...options
    });
    return formatter.format(value);
  } catch (error) {
    console.error(`[${APP_NAME}] Number formatting error:`, error);
    return value.toString();
  }
};

/**
 * Truncates text to specified length and adds ellipsis if needed
 * Requirement 5.1.2: Financial Data Display - Format display text in account summaries
 */
export const truncateText = (text: string, maxLength: number): string => {
  if (typeof text !== 'string') {
    throw new Error('Invalid text provided for truncation');
  }
  if (!Number.isInteger(maxLength) || maxLength <= 0) {
    throw new Error('Invalid maxLength provided for truncation');
  }

  if (text.length <= maxLength) {
    return text;
  }

  return `${text.slice(0, maxLength - 3)}...`;
};

/**
 * Formats account numbers by masking all but last 4 digits for security
 * Requirement 5.1.2: Financial Data Display - Secure display of account information
 */
export const formatAccountNumber = (accountNumber: string): string => {
  if (!accountNumber || typeof accountNumber !== 'string') {
    throw new Error('Invalid account number provided for masking');
  }

  const lastFourDigits = accountNumber.replace(/[^0-9]/g, '').slice(-4);
  if (!lastFourDigits) {
    throw new Error('Account number must contain at least one digit');
  }

  const maskedPortion = accountNumber.slice(0, -4).replace(/\d/g, '*');
  return maskedPortion + lastFourDigits;
};