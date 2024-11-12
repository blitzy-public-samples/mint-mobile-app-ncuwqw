/**
 * HUMAN TASKS:
 * 1. Verify API endpoint configurations in deployment environment
 * 2. Set up monitoring for transaction API performance metrics
 * 3. Configure rate limiting for transaction endpoints
 * 4. Set up data validation rules for transaction amounts and dates
 */

// axios version: ^0.24.0
import { AxiosResponse } from 'axios';
import { apiInstance, handleApiError } from '../utils/api';
import { 
  Transaction, 
  TransactionType, 
  APIResponse, 
  APIError 
} from '../../types';

/**
 * Requirement: Financial Tracking - Implement automated transaction import
 * Retrieves a paginated list of transactions with optional filtering
 */
export async function getTransactions(params: {
  accountId?: string;
  categoryId?: string;
  startDate?: Date;
  endDate?: Date;
  page?: number;
  limit?: number;
}): Promise<APIResponse<Transaction[]>> {
  try {
    // Validate date range if provided
    if (params.startDate && params.endDate && params.startDate > params.endDate) {
      throw new Error('Start date must be before end date');
    }

    // Construct query parameters
    const queryParams = new URLSearchParams();
    if (params.accountId) queryParams.append('accountId', params.accountId);
    if (params.categoryId) queryParams.append('categoryId', params.categoryId);
    if (params.startDate) queryParams.append('startDate', params.startDate.toISOString());
    if (params.endDate) queryParams.append('endDate', params.endDate.toISOString());
    if (params.page) queryParams.append('page', params.page.toString());
    if (params.limit) queryParams.append('limit', params.limit.toString());

    const response = await apiInstance.get<APIResponse<Transaction[]>>(`/transactions?${queryParams}`);
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Requirement: Transaction Management - Interface with Transaction Service
 * Retrieves a single transaction by its ID
 */
export async function getTransactionById(transactionId: string): Promise<APIResponse<Transaction>> {
  try {
    if (!transactionId.match(/^[0-9a-fA-F]{24}$/)) {
      throw new Error('Invalid transaction ID format');
    }

    const response = await apiInstance.get<APIResponse<Transaction>>(`/transactions/${transactionId}`);
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Requirement: Financial Tracking - Implement transaction management
 * Creates a new manual transaction record
 */
export async function createTransaction(transactionData: {
  accountId: string;
  amount: number;
  description: string;
  categoryId: string;
  date: Date;
  type: TransactionType;
}): Promise<APIResponse<Transaction>> {
  try {
    // Validate required fields
    if (!transactionData.accountId || !transactionData.categoryId) {
      throw new Error('Account ID and Category ID are required');
    }

    if (!transactionData.amount || transactionData.amount === 0) {
      throw new Error('Transaction amount must be non-zero');
    }

    const payload = {
      ...transactionData,
      date: transactionData.date.toISOString()
    };

    const response = await apiInstance.post<APIResponse<Transaction>>('/transactions', payload);
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Requirement: Transaction Management - Interface with Transaction Service
 * Updates an existing transaction's details
 */
export async function updateTransaction(
  transactionId: string,
  updateData: {
    categoryId?: string;
    description?: string;
  }
): Promise<APIResponse<Transaction>> {
  try {
    if (!transactionId.match(/^[0-9a-fA-F]{24}$/)) {
      throw new Error('Invalid transaction ID format');
    }

    if (!updateData.categoryId && !updateData.description) {
      throw new Error('At least one field must be provided for update');
    }

    const response = await apiInstance.patch<APIResponse<Transaction>>(
      `/transactions/${transactionId}`,
      updateData
    );
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Requirement: Transaction Management - Interface with Transaction Service
 * Deletes a manually created transaction
 */
export async function deleteTransaction(transactionId: string): Promise<APIResponse<void>> {
  try {
    if (!transactionId.match(/^[0-9a-fA-F]{24}$/)) {
      throw new Error('Invalid transaction ID format');
    }

    const response = await apiInstance.delete<APIResponse<void>>(`/transactions/${transactionId}`);
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Requirement: Financial Tracking - Implement category management
 * Updates the category of a transaction
 */
export async function categorizeTransaction(
  transactionId: string,
  categoryId: string
): Promise<APIResponse<Transaction>> {
  try {
    if (!transactionId.match(/^[0-9a-fA-F]{24}$/)) {
      throw new Error('Invalid transaction ID format');
    }

    if (!categoryId.match(/^[0-9a-fA-F]{24}$/)) {
      throw new Error('Invalid category ID format');
    }

    const response = await apiInstance.patch<APIResponse<Transaction>>(
      `/transactions/${transactionId}/category`,
      { categoryId }
    );
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Requirement: Financial Tracking - Implement transaction search/filtering
 * Searches transactions by description or category
 */
export async function searchTransactions(searchParams: {
  query: string;
  accountId?: string;
  startDate?: Date;
  endDate?: Date;
  page?: number;
  limit?: number;
}): Promise<APIResponse<Transaction[]>> {
  try {
    if (!searchParams.query || searchParams.query.trim().length === 0) {
      throw new Error('Search query is required');
    }

    // Validate date range if provided
    if (searchParams.startDate && searchParams.endDate && searchParams.startDate > searchParams.endDate) {
      throw new Error('Start date must be before end date');
    }

    // Construct search parameters
    const queryParams = new URLSearchParams();
    queryParams.append('query', searchParams.query.trim());
    if (searchParams.accountId) queryParams.append('accountId', searchParams.accountId);
    if (searchParams.startDate) queryParams.append('startDate', searchParams.startDate.toISOString());
    if (searchParams.endDate) queryParams.append('endDate', searchParams.endDate.toISOString());
    if (searchParams.page) queryParams.append('page', searchParams.page.toString());
    if (searchParams.limit) queryParams.append('limit', searchParams.limit.toString());

    const response = await apiInstance.get<APIResponse<Transaction[]>>(
      `/transactions/search?${queryParams}`
    );
    return response;
  } catch (error) {
    throw handleApiError(error);
  }
}