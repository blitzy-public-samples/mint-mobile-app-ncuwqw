// @ts-check

// react-router-dom v6.0.0
import { type RouteDefinition } from 'react-router-dom';

/**
 * Human Tasks:
 * 1. Ensure react-router-dom v6.0.0 or higher is installed in package.json
 * 2. Verify route paths align with backend API endpoints
 * 3. Update any environment-specific route prefixes in deployment config
 */

/**
 * Authentication related routes
 * Requirement 1.2 Scope/Account Management:
 * Define routes for multi-platform user authentication
 */
export const AUTH = {
  LOGIN: '/auth/login',
  REGISTER: '/auth/register',
  FORGOT_PASSWORD: '/auth/forgot-password',
  RESET_PASSWORD: '/auth/reset-password',
  VERIFY_EMAIL: '/auth/verify-email',
  TWO_FACTOR: '/auth/2fa'
} as const;

/**
 * Dashboard and overview routes
 * Requirement 1.2 Scope/Financial Tracking:
 * Define routes for automated transaction import and spending analysis features
 */
export const DASHBOARD = {
  HOME: '/',
  OVERVIEW: '/overview',
  INSIGHTS: '/insights',
  ACTIVITY: '/activity'
} as const;

/**
 * Account management routes
 * Requirement 1.2 Scope/Account Management:
 * Define routes for financial account aggregation and cross-platform data synchronization
 */
export const ACCOUNTS = {
  LIST: '/accounts',
  DETAIL: '/accounts/:id',
  ADD: '/accounts/add',
  EDIT: '/accounts/:id/edit',
  LINK: '/accounts/link',
  SYNC: '/accounts/sync'
} as const;

/**
 * Transaction management routes
 * Requirement 1.2 Scope/Financial Tracking:
 * Define routes for transaction management and category features
 */
export const TRANSACTIONS = {
  LIST: '/transactions',
  DETAIL: '/transactions/:id',
  ADD: '/transactions/add',
  EDIT: '/transactions/:id/edit',
  IMPORT: '/transactions/import',
  EXPORT: '/transactions/export',
  CATEGORIES: '/transactions/categories'
} as const;

/**
 * Budget management routes
 * Requirement 1.2 Scope/Budget Management:
 * Define routes for category-based budgeting and progress monitoring
 */
export const BUDGETS = {
  LIST: '/budgets',
  DETAIL: '/budgets/:id',
  CREATE: '/budgets/create',
  EDIT: '/budgets/:id/edit',
  ANALYSIS: '/budgets/analysis',
  TEMPLATES: '/budgets/templates'
} as const;

/**
 * Financial goals routes
 * Requirement 1.2 Scope/Goal Management:
 * Define routes for financial goal setting and progress tracking
 */
export const GOALS = {
  LIST: '/goals',
  DETAIL: '/goals/:id',
  CREATE: '/goals/create',
  EDIT: '/goals/:id/edit',
  PROGRESS: '/goals/:id/progress',
  MILESTONES: '/goals/:id/milestones'
} as const;

/**
 * Investment tracking routes
 * Requirement 1.2 Scope/Investment Tracking:
 * Define routes for portfolio monitoring and performance metrics
 */
export const INVESTMENTS = {
  LIST: '/investments',
  DETAIL: '/investments/:id',
  PORTFOLIO: '/investments/portfolio',
  PERFORMANCE: '/investments/performance',
  HOLDINGS: '/investments/holdings',
  TRANSACTIONS: '/investments/transactions'
} as const;

/**
 * Application settings routes
 * Requirement 1.2 Scope/Account Management:
 * Define routes for user preferences and account settings
 */
export const SETTINGS = {
  MAIN: '/settings',
  PROFILE: '/settings/profile',
  SECURITY: '/settings/security',
  NOTIFICATIONS: '/settings/notifications',
  PREFERENCES: '/settings/preferences',
  CONNECTED_ACCOUNTS: '/settings/connected-accounts',
  DATA_EXPORT: '/settings/data-export'
} as const;

/**
 * Combined routes object for application-wide routing
 */
export const ROUTES = {
  AUTH,
  DASHBOARD,
  ACCOUNTS,
  TRANSACTIONS,
  BUDGETS,
  GOALS,
  INVESTMENTS,
  SETTINGS
} as const;

/**
 * Type definition for route paths with optional parameters
 */
export interface RouteDefinition {
  path: string;
  params?: string[];
}

// Type assertion to ensure all routes are strings
type RouteType = typeof ROUTES;
type ValidateRoutes<T> = {
  [K in keyof T]: T[K] extends { [key: string]: string } ? T[K] : never;
};
export type Routes = ValidateRoutes<RouteType>;