/**
 * HUMAN TASKS:
 * 1. Verify API endpoint configurations in environment variables
 * 2. Set up error monitoring for goal-related API calls
 * 3. Configure request timeout settings for long-running goal operations
 */

import { apiInstance } from '../../utils/api';
import { APIResponse, APIError } from '../../types';

// Requirement: Goal Management - Define interfaces for goal management functionality
interface Goal {
  id: string;
  userId: string;
  name: string;
  targetAmount: number;
  currentAmount: number;
  deadline: Date;
  category: string;
  priority: 'LOW' | 'MEDIUM' | 'HIGH';
  status: 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';
  linkedAccounts: string[];
  createdAt: Date;
  updatedAt: Date;
}

// Requirement: Goal Management - Define interface for goal progress tracking
interface GoalProgress {
  goalId: string;
  percentageComplete: number;
  remainingAmount: number;
  projectedCompletionDate: Date;
  monthlyContributionNeeded: number;
  isOnTrack: boolean;
  lastUpdated: Date;
}

/**
 * Retrieves all financial goals for the authenticated user
 * Requirement: Goal Management - Implement financial goal setting functionality
 */
export async function getGoals(): Promise<APIResponse<Goal[]>> {
  try {
    const response = await apiInstance.get<APIResponse<Goal[]>>('/api/v1/goals');
    return response;
  } catch (error) {
    throw error as APIError;
  }
}

/**
 * Retrieves a specific financial goal by ID
 * Requirement: Goal Management - Implement goal retrieval functionality
 */
export async function getGoalById(goalId: string): Promise<APIResponse<Goal>> {
  if (!goalId?.trim()) {
    throw new Error('Goal ID is required');
  }

  try {
    const response = await apiInstance.get<APIResponse<Goal>>(`/api/v1/goals/${goalId}`);
    return response;
  } catch (error) {
    throw error as APIError;
  }
}

/**
 * Creates a new financial goal
 * Requirement: Goal Management - Implement goal creation functionality
 */
export async function createGoal(goalData: Partial<Goal>): Promise<APIResponse<Goal>> {
  if (!goalData.name || !goalData.targetAmount || !goalData.deadline) {
    throw new Error('Name, target amount, and deadline are required');
  }

  try {
    const response = await apiInstance.post<APIResponse<Goal>>('/api/v1/goals', goalData);
    return response;
  } catch (error) {
    throw error as APIError;
  }
}

/**
 * Updates an existing financial goal
 * Requirement: Goal Management - Implement goal update functionality
 */
export async function updateGoal(
  goalId: string,
  goalData: Partial<Goal>
): Promise<APIResponse<Goal>> {
  if (!goalId?.trim()) {
    throw new Error('Goal ID is required');
  }

  if (Object.keys(goalData).length === 0) {
    throw new Error('At least one field must be provided for update');
  }

  try {
    const response = await apiInstance.put<APIResponse<Goal>>(
      `/api/v1/goals/${goalId}`,
      goalData
    );
    return response;
  } catch (error) {
    throw error as APIError;
  }
}

/**
 * Deletes a financial goal
 * Requirement: Goal Management - Implement goal deletion functionality
 */
export async function deleteGoal(goalId: string): Promise<APIResponse<void>> {
  if (!goalId?.trim()) {
    throw new Error('Goal ID is required');
  }

  try {
    const response = await apiInstance.delete<APIResponse<void>>(`/api/v1/goals/${goalId}`);
    return response;
  } catch (error) {
    throw error as APIError;
  }
}

/**
 * Retrieves progress tracking data for a specific goal
 * Requirement: Goal Management - Implement goal progress tracking functionality
 */
export async function trackGoalProgress(
  goalId: string
): Promise<APIResponse<GoalProgress>> {
  if (!goalId?.trim()) {
    throw new Error('Goal ID is required');
  }

  try {
    const response = await apiInstance.get<APIResponse<GoalProgress>>(
      `/api/v1/goals/${goalId}/progress`
    );
    return response;
  } catch (error) {
    throw error as APIError;
  }
}

/**
 * Links a financial account to a goal for progress tracking
 * Requirement: Goal Management - Implement goal-linked accounts functionality
 */
export async function linkAccountToGoal(
  goalId: string,
  accountId: string
): Promise<APIResponse<Goal>> {
  if (!goalId?.trim() || !accountId?.trim()) {
    throw new Error('Goal ID and Account ID are required');
  }

  try {
    const response = await apiInstance.post<APIResponse<Goal>>(
      `/api/v1/goals/${goalId}/accounts/${accountId}`
    );
    return response;
  } catch (error) {
    throw error as APIError;
  }
}