/**
 * HUMAN TASKS:
 * 1. Verify API endpoint configuration in environment variables
 * 2. Set up monitoring for account sync operations
 * 3. Configure rate limiting for account sync requests
 * 4. Set up error tracking for failed account operations
 */

// axios version: ^0.24.0
import { AxiosResponse } from 'axios';
import { 
  Account, 
  AccountType, 
  APIResponse, 
  APIError 
} from '../../types';
import { 
  apiInstance, 
  handleApiError 
} from '../../utils/api';

/**
 * Retrieves all financial accounts for the authenticated user
 * Requirement: Account Management - Multi-platform user authentication and financial account aggregation
 */
export async function getAccounts(): Promise<Account[]> {
  try {
    const response = await apiInstance.get<APIResponse<Account[]>>('/accounts');
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Retrieves details of a specific account by ID
 * Requirement: Account Management - Multi-platform user authentication and financial account aggregation
 */
export async function getAccountById(accountId: string): Promise<Account> {
  if (!accountId) {
    throw new Error('Account ID is required');
  }

  try {
    const response = await apiInstance.get<APIResponse<Account>>(`/accounts/${accountId}`);
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Links a new financial institution account
 * Requirement: Account Management - Multi-platform user authentication and financial account aggregation
 */
export async function linkAccount(linkData: {
  institutionId: string;
  credentials: Record<string, string>;
  accountType: AccountType;
}): Promise<Account> {
  if (!linkData.institutionId || !linkData.credentials || !linkData.accountType) {
    throw new Error('Institution ID, credentials, and account type are required');
  }

  try {
    const response = await apiInstance.post<APIResponse<Account>>('/accounts/link', linkData);
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Unlinks a financial institution account
 * Requirement: Account Management - Multi-platform user authentication and financial account aggregation
 */
export async function unlinkAccount(accountId: string): Promise<void> {
  if (!accountId) {
    throw new Error('Account ID is required');
  }

  try {
    await apiInstance.delete<APIResponse<void>>(`/accounts/${accountId}`);
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Triggers a sync of account data with financial institution
 * Requirement: Real-time Updates - Real-time balance updates and cross-platform data synchronization
 */
export async function syncAccount(accountId: string): Promise<Account> {
  if (!accountId) {
    throw new Error('Account ID is required');
  }

  try {
    const response = await apiInstance.post<APIResponse<Account>>(`/accounts/${accountId}/sync`);
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
}

/**
 * Updates account settings and preferences
 * Requirement: Account Management - Multi-platform user authentication and financial account aggregation
 */
export async function updateAccountSettings(
  accountId: string,
  settings: {
    isActive?: boolean;
    name?: string;
  }
): Promise<Account> {
  if (!accountId) {
    throw new Error('Account ID is required');
  }

  if (!settings || (settings.isActive === undefined && !settings.name)) {
    throw new Error('At least one setting must be provided');
  }

  try {
    const response = await apiInstance.patch<APIResponse<Account>>(
      `/accounts/${accountId}/settings`,
      settings
    );
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
}