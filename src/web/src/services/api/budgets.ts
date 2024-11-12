/**
 * HUMAN TASKS:
 * 1. Verify API rate limits for budget-related endpoints in production environment
 * 2. Configure monitoring alerts for budget progress tracking API performance
 * 3. Set up error tracking for budget-related API failures
 */

// axios version: ^0.24.0
import { apiInstance, handleApiError } from '../../utils/api';
import { BUDGET_ENDPOINTS } from '../../constants/api';
import { 
  Budget, 
  BudgetPeriod, 
  APIResponse, 
  APIError 
} from '../../types';

/**
 * Interface for budget progress tracking data
 * Requirement: Budget Management - Implement progress monitoring
 */
interface BudgetProgress {
  budgetId: string;
  currentSpending: number;
  budgetedAmount: number;
  remainingAmount: number;
  percentageUsed: number;
  periodStart: Date;
  periodEnd: Date;
  lastUpdated: Date;
}

/**
 * Retrieves list of budgets with optional filtering
 * Requirement: Budget Management - Implement category-based budgeting
 */
export async function getBudgets(filters?: {
  categoryId?: string;
  period?: BudgetPeriod;
  active?: boolean;
}): Promise<APIResponse<Budget[]>> {
  try {
    const response = await apiInstance.get(BUDGET_ENDPOINTS.LIST, {
      params: filters
    });
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Retrieves details of a specific budget by ID
 * Requirement: Budget Management - Implement budget vs. actual reporting
 */
export async function getBudgetById(budgetId: string): Promise<APIResponse<Budget>> {
  if (!budgetId) {
    throw new Error('Budget ID is required');
  }

  try {
    const response = await apiInstance.get(
      BUDGET_ENDPOINTS.DETAILS.replace(':id', budgetId)
    );
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Creates a new budget with the provided data
 * Requirement: Budget Management - Implement category-based budgeting
 */
export async function createBudget(budgetData: {
  name: string;
  categoryId: string;
  amount: number;
  period: BudgetPeriod;
  startDate: Date;
  endDate: Date;
  alertThreshold?: number;
}): Promise<APIResponse<Budget>> {
  // Validate required fields
  if (!budgetData.name || !budgetData.categoryId || !budgetData.amount || !budgetData.period) {
    throw new Error('Missing required budget data fields');
  }

  try {
    const response = await apiInstance.post(BUDGET_ENDPOINTS.LIST, budgetData);
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Updates an existing budget with the provided data
 * Requirement: Budget Management - Implement category-based budgeting
 */
export async function updateBudget(
  budgetId: string,
  budgetData: Partial<Budget>
): Promise<APIResponse<Budget>> {
  if (!budgetId) {
    throw new Error('Budget ID is required');
  }

  try {
    const response = await apiInstance.put(
      BUDGET_ENDPOINTS.DETAILS.replace(':id', budgetId),
      budgetData
    );
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Deletes a specific budget by ID
 * Requirement: Budget Management - Implement category-based budgeting
 */
export async function deleteBudget(budgetId: string): Promise<APIResponse<void>> {
  if (!budgetId) {
    throw new Error('Budget ID is required');
  }

  try {
    const response = await apiInstance.delete(
      BUDGET_ENDPOINTS.DETAILS.replace(':id', budgetId)
    );
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Retrieves progress tracking data for a specific budget
 * Requirement: Budget Management - Implement budget vs. actual reporting
 */
export async function getBudgetProgress(
  budgetId: string,
  dateRange: {
    startDate: Date;
    endDate: Date;
  }
): Promise<APIResponse<BudgetProgress>> {
  if (!budgetId) {
    throw new Error('Budget ID is required');
  }

  if (!dateRange.startDate || !dateRange.endDate) {
    throw new Error('Start and end dates are required for progress tracking');
  }

  try {
    const response = await apiInstance.get(
      BUDGET_ENDPOINTS.PROGRESS.replace(':id', budgetId),
      {
        params: {
          startDate: dateRange.startDate.toISOString(),
          endDate: dateRange.endDate.toISOString()
        }
      }
    );
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}