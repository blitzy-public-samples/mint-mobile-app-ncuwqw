/**
 * HUMAN TASKS:
 * 1. Ensure Redux DevTools is configured in store setup for development
 * 2. Set up error tracking service integration for async thunk error handling
 * 3. Configure Redux persist for goals state if offline support is needed
 */

// @reduxjs/toolkit version ^1.9.5
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { Goal, APIResponse } from '../../types';
import {
  getGoals,
  getGoalById,
  createGoal,
  updateGoal,
  deleteGoal,
  trackGoalProgress,
  linkAccountToGoal,
} from '../../services/api/goals';

// Requirement: Goal Management - Define state interface for goal management
interface GoalsState {
  goals: Goal[];
  selectedGoal: Goal | null;
  loading: boolean;
  error: string | null;
  progressLoading: boolean;
  progressError: string | null;
}

// Initial state
const initialState: GoalsState = {
  goals: [],
  selectedGoal: null,
  loading: false,
  error: null,
  progressLoading: false,
  progressError: null,
};

// Requirement: Goal Management - Implement async thunk for fetching all goals
export const fetchGoals = createAsyncThunk(
  'goals/fetchGoals',
  async (_, { rejectWithValue }) => {
    try {
      const response = await getGoals();
      return response.data;
    } catch (error: any) {
      return rejectWithValue(error.message || 'Failed to fetch goals');
    }
  }
);

// Requirement: Goal Management - Implement async thunk for fetching single goal
export const fetchGoalById = createAsyncThunk(
  'goals/fetchGoalById',
  async (goalId: string, { rejectWithValue }) => {
    try {
      const response = await getGoalById(goalId);
      return response.data;
    } catch (error: any) {
      return rejectWithValue(error.message || 'Failed to fetch goal');
    }
  }
);

// Requirement: Goal Management - Implement async thunk for goal creation
export const createNewGoal = createAsyncThunk(
  'goals/createGoal',
  async (goalData: Partial<Goal>, { rejectWithValue }) => {
    try {
      const response = await createGoal(goalData);
      return response.data;
    } catch (error: any) {
      return rejectWithValue(error.message || 'Failed to create goal');
    }
  }
);

// Requirement: Goal Management - Implement async thunk for goal updates
export const updateExistingGoal = createAsyncThunk(
  'goals/updateGoal',
  async (payload: { goalId: string; goalData: Partial<Goal> }, { rejectWithValue }) => {
    try {
      const { goalId, goalData } = payload;
      const response = await updateGoal(goalId, goalData);
      return response.data;
    } catch (error: any) {
      return rejectWithValue(error.message || 'Failed to update goal');
    }
  }
);

// Requirement: Goal Management - Implement async thunk for goal deletion
export const removeGoal = createAsyncThunk(
  'goals/deleteGoal',
  async (goalId: string, { rejectWithValue }) => {
    try {
      await deleteGoal(goalId);
      return goalId;
    } catch (error: any) {
      return rejectWithValue(error.message || 'Failed to delete goal');
    }
  }
);

// Requirement: Goal Management - Implement async thunk for progress tracking
export const fetchGoalProgress = createAsyncThunk(
  'goals/fetchProgress',
  async (goalId: string, { rejectWithValue }) => {
    try {
      const response = await trackGoalProgress(goalId);
      return response.data;
    } catch (error: any) {
      return rejectWithValue(error.message || 'Failed to fetch goal progress');
    }
  }
);

// Requirement: Goal Management - Implement async thunk for account linking
export const linkAccount = createAsyncThunk(
  'goals/linkAccount',
  async (payload: { goalId: string; accountId: string }, { rejectWithValue }) => {
    try {
      const { goalId, accountId } = payload;
      const response = await linkAccountToGoal(goalId, accountId);
      return response.data;
    } catch (error: any) {
      return rejectWithValue(error.message || 'Failed to link account to goal');
    }
  }
);

// Requirement: State Management - Create Redux slice for goals management
const goalsSlice = createSlice({
  name: 'goals',
  initialState,
  reducers: {
    setSelectedGoal: (state, action: PayloadAction<Goal>) => {
      state.selectedGoal = action.payload;
    },
    clearSelectedGoal: (state) => {
      state.selectedGoal = null;
    },
    resetGoalsState: (state) => {
      Object.assign(state, initialState);
    },
  },
  extraReducers: (builder) => {
    // Fetch goals
    builder
      .addCase(fetchGoals.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchGoals.fulfilled, (state, action) => {
        state.loading = false;
        state.goals = action.payload;
      })
      .addCase(fetchGoals.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Fetch single goal
      .addCase(fetchGoalById.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchGoalById.fulfilled, (state, action) => {
        state.loading = false;
        state.selectedGoal = action.payload;
      })
      .addCase(fetchGoalById.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Create goal
      .addCase(createNewGoal.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(createNewGoal.fulfilled, (state, action) => {
        state.loading = false;
        state.goals.push(action.payload);
      })
      .addCase(createNewGoal.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Update goal
      .addCase(updateExistingGoal.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateExistingGoal.fulfilled, (state, action) => {
        state.loading = false;
        const index = state.goals.findIndex((goal) => goal.id === action.payload.id);
        if (index !== -1) {
          state.goals[index] = action.payload;
        }
        if (state.selectedGoal?.id === action.payload.id) {
          state.selectedGoal = action.payload;
        }
      })
      .addCase(updateExistingGoal.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Delete goal
      .addCase(removeGoal.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(removeGoal.fulfilled, (state, action) => {
        state.loading = false;
        state.goals = state.goals.filter((goal) => goal.id !== action.payload);
        if (state.selectedGoal?.id === action.payload) {
          state.selectedGoal = null;
        }
      })
      .addCase(removeGoal.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      })
      // Progress tracking
      .addCase(fetchGoalProgress.pending, (state) => {
        state.progressLoading = true;
        state.progressError = null;
      })
      .addCase(fetchGoalProgress.fulfilled, (state) => {
        state.progressLoading = false;
      })
      .addCase(fetchGoalProgress.rejected, (state, action) => {
        state.progressLoading = false;
        state.progressError = action.payload as string;
      })
      // Link account
      .addCase(linkAccount.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(linkAccount.fulfilled, (state, action) => {
        state.loading = false;
        const index = state.goals.findIndex((goal) => goal.id === action.payload.id);
        if (index !== -1) {
          state.goals[index] = action.payload;
        }
        if (state.selectedGoal?.id === action.payload.id) {
          state.selectedGoal = action.payload;
        }
      })
      .addCase(linkAccount.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload as string;
      });
  },
});

// Export actions
export const goalsActions = goalsSlice.actions;
export const goalsThunks = {
  fetchGoals,
  fetchGoalById,
  createNewGoal,
  updateExistingGoal,
  removeGoal,
  fetchGoalProgress,
  linkAccount,
};

// Requirement: State Management - Export selectors for accessing goals state
export const selectGoals = (state: { goals: GoalsState }) => state.goals.goals;
export const selectSelectedGoal = (state: { goals: GoalsState }) => state.goals.selectedGoal;
export const selectGoalsLoading = (state: { goals: GoalsState }) => state.goals.loading;
export const selectGoalsError = (state: { goals: GoalsState }) => state.goals.error;

// Export reducer
export default goalsSlice.reducer;