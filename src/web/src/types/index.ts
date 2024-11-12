// TypeScript v4.9.0 or higher required

/**
 * HUMAN TASKS:
 * 1. Ensure TypeScript version ^4.9.0 is installed in package.json
 * 2. Configure tsconfig.json to enable strict type checking
 * 3. Set up ESLint with @typescript-eslint for type checking in development
 */

// Requirement: Account Management - Define types for financial account aggregation and management
export interface Account {
    id: string;
    userId: string;
    institutionId: string;
    type: AccountType;
    name: string;
    balance: number;
    currency: string;
    isActive: boolean;
    lastSynced: Date;
}

// Requirement: Account Management - Define account types for cross-platform data synchronization
export enum AccountType {
    CHECKING = 'CHECKING',
    SAVINGS = 'SAVINGS',
    CREDIT = 'CREDIT',
    INVESTMENT = 'INVESTMENT'
}

// Requirement: Financial Tracking - Define types for automated transaction import and category management
export interface Transaction {
    id: string;
    accountId: string;
    categoryId: string;
    amount: number;
    description: string;
    date: Date;
    type: TransactionType;
    status: TransactionStatus;
    metadata: Record<string, unknown>;
}

// Requirement: Financial Tracking - Define transaction types for spending analysis
export enum TransactionType {
    DEBIT = 'DEBIT',
    CREDIT = 'CREDIT'
}

// Requirement: Financial Tracking - Define transaction status for real-time tracking
export enum TransactionStatus {
    PENDING = 'PENDING',
    POSTED = 'POSTED',
    CANCELLED = 'CANCELLED'
}

// Requirement: Budget Management - Define types for category-based budgeting and progress monitoring
export interface Budget {
    id: string;
    userId: string;
    categoryId: string;
    name: string;
    amount: number;
    period: BudgetPeriod;
    startDate: Date;
    endDate: Date;
    alertThreshold: number;
    notificationPreferences: NotificationPreferences;
}

// Requirement: Budget Management - Define budget periods for customizable tracking
export enum BudgetPeriod {
    MONTHLY = 'MONTHLY',
    QUARTERLY = 'QUARTERLY',
    YEARLY = 'YEARLY'
}

// Requirement: Budget Management - Define types for customizable alerts
export interface NotificationPreferences {
    email: boolean;
    push: boolean;
    sms: boolean;
}

// Requirement: Financial Tracking - Define types for category management and spending analysis
export interface Category {
    id: string;
    name: string;
    type: CategoryType;
    parentId: string | null;
    icon: string;
    color: string;
}

// Requirement: Financial Tracking - Define category types for comprehensive tracking
export enum CategoryType {
    INCOME = 'INCOME',
    EXPENSE = 'EXPENSE',
    TRANSFER = 'TRANSFER',
    INVESTMENT = 'INVESTMENT'
}

// Requirement: Investment Tracking - Define types for basic portfolio monitoring
export interface Investment {
    id: string;
    accountId: string;
    symbol: string;
    shares: number;
    costBasis: number;
    currentValue: number;
    lastUpdated: Date;
}

// Requirement: Account Management - Define generic API response wrapper for cross-platform data synchronization
export interface APIResponse<T> {
    data: T;
    status: number;
    message: string;
    timestamp: Date;
}

// Requirement: Account Management - Define standardized error response for cross-platform compatibility
export interface APIError {
    status: number;
    message: string;
    errors: string[];
    code: string;
    timestamp: Date;
}