// @ts-check

/**
 * HUMAN TASKS:
 * 1. Ensure all image files referenced below are placed in the correct assets directory
 * 2. Verify image dimensions and formats meet platform requirements
 * 3. Optimize images for web performance using appropriate compression tools
 * 4. Update image paths if asset directory structure changes
 */

// react-native ^0.71.0
import { ImageSourcePropType } from 'react-native';

// Requirement: Cross-platform UI Development
// Location: Technical Specification/2.1 High-Level Architecture Overview/Client Layer
// Description: Provides image assets for React Native Web application UI components

// Application logo
export const logoImage: ImageSourcePropType = require('./logo/app-logo.png');

// Empty state illustrations
export const emptyStateImages: Record<string, ImageSourcePropType> = {
  noTransactions: require('./empty-states/no-transactions.svg'),
  noAccounts: require('./empty-states/no-accounts.svg'),
  noBudgets: require('./empty-states/no-budgets.svg'),
  noGoals: require('./empty-states/no-goals.svg'),
  noInvestments: require('./empty-states/no-investments.svg'),
};

// Dashboard background images
export const dashboardImages: Record<string, ImageSourcePropType> = {
  accountSummaryBg: require('./dashboard/account-summary-bg.png'),
  budgetOverviewBg: require('./dashboard/budget-overview-bg.png'),
  goalProgressBg: require('./dashboard/goal-progress-bg.png'),
};

// Transaction and budget category icons
export const categoryImages: Record<string, ImageSourcePropType> = {
  shopping: require('./categories/shopping-icon.svg'),
  dining: require('./categories/dining-icon.svg'),
  transportation: require('./categories/transportation-icon.svg'),
  utilities: require('./categories/utilities-icon.svg'),
  entertainment: require('./categories/entertainment-icon.svg'),
};

// Onboarding flow illustrations
export const onboardingImages: Record<string, ImageSourcePropType> = {
  welcome: require('./onboarding/welcome-illustration.svg'),
  linkAccounts: require('./onboarding/link-accounts-illustration.svg'),
  setBudgets: require('./onboarding/set-budgets-illustration.svg'),
  setGoals: require('./onboarding/set-goals-illustration.svg'),
};

// Requirement: User Interface Design
// Location: Technical Specification/5.1 User Interface Design
// Description: Supports UI elements with necessary image assets for dashboard, accounts, transactions, and other screens