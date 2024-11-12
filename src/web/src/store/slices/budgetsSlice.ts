// @reduxjs/toolkit version: ^1.9.0
import { createSlice, createAsyncThunk } from '@reduxjs/toolkit';
import {
  Budget,
  BudgetPeriod,
  APIResponse,
  APIError
} from '../../types';
import {
  getBudgets,
  getBudgetById,
  createBudget,
  updateBudget,
  deleteBudget,
  getBudgetProgress
} from '../../services/api/budgets';

/**
 * HUMAN TASKS:
 * 1. Configure Redux DevTools in development environment for state debugging
 * 2. Set up error tracking service integration for monitoring Redux errors
 * 3. Verify Redux persist configuration for offline budget data access
 */

// Requirement: Budget Management - Define initial state for budget tracking
interface BudgetState {
  budgets: Budget[];
  selectedBudget: Budget | null;
  loading: boolean;
  error: string | null;
  progress: Record<string, {
    spent: number;
    remaining: number;
    percentage: number;
  }>;
}

const initialState: BudgetState = {
  budgets: [],
  selectedBudget: null,
  loading: false,
  error: null,
  progress: {}
};

// Requirement: Budget Management - Implement category-based budgeting
export const fetchBudgets = createAsyncThunk<
  Budget[],
  { categoryId?: string; period?: BudgetPeriod; active?: boolean },
  { rejectValue: APIError }
>('budgets/fetchBudgets', async (filters, { rejectWithValue }) => {
  try {
    const response = await getBudgets(filters);
    return response.data;
  } catch (error) {
    return rejectWithValue(error as APIError);
  }
});

// Requirement: Budget Management - Implement budget vs. actual reporting
export const fetchBudgetById = createAsyncThunk<
  Budget,
  string,
  { rejectValue: APIError }
>('budgets/fetchBudgetById', async (budgetId, { rejectWithValue }) => {
  try {
    const response = await getBudgetById(budgetId);
    return response.data;
  } catch (error) {
    return rejectWithValue(error as APIError);
  }
});

// Requirement: Budget Management - Implement category-based budgeting
export const createNewBudget = createAsyncThunk<
  Budget,
  {
    name: string;
    categoryId: string;
    amount: number;
    period: BudgetPeriod;
    startDate: Date;
    endDate: Date;
    alertThreshold?: number;
  },
  { rejectValue: APIError }
>('budgets/createNewBudget', async (budgetData, { rejectWithValue }) => {
  try {
    const response = await createBudget(budgetData);
    return response.data;
  } catch (error) {
    return rejectWithValue(error as APIError);
  }
});

// Requirement: Budget Management - Implement budget vs. actual reporting
export const updateExistingBudget = createAsyncThunk<
  Budget,
  { budgetId: string; data: Partial<Budget> },
  { rejectValue: APIError }
>('budgets/updateExistingBudget', async ({ budgetId, data }, { rejectWithValue }) => {
  try {
    const response = await updateBudget(budgetId, data);
    return response.data;
  } catch (error) {
    return rejectWithValue(error as APIError);
  }
});

// Requirement: Budget Management - Implement category-based budgeting
export const removeBudget = createAsyncThunk<
  void,
  string,
  { rejectValue: APIError }
>('budgets/removeBudget', async (budgetId, { rejectWithValue }) => {
  try {
    await deleteBudget(budgetId);
  } catch (error) {
    return rejectWithValue(error as APIError);
  }
});

// Requirement: Budget Management - Implement progress monitoring
export const fetchBudgetProgress = createAsyncThunk<
  { spent: number; remaining: number; percentage: number },
  { budgetId: string; dateRange: { startDate: Date; endDate: Date } },
  { rejectValue: APIError }
>('budgets/fetchBudgetProgress', async ({ budgetId, dateRange }, { rejectWithValue }) => {
  try {
    const response = await getBudgetProgress(budgetId, dateRange);
    return response.data;
  } catch (error) {
    return rejectWithValue(error as APIError);
  }
});

// Requirement: Real-time Data Flow - Handle real-time budget updates and state management
const budgetsSlice = createSlice({
  name: 'budgets',
  initialState,
  reducers: {
    clearSelectedBudget: (state) => {
      state.selectedBudget = null;
    },
    clearBudgetError: (state) => {
      state.error = null;
    }
  },
  extraReducers: (builder) => {
    builder
      // fetchBudgets
      .addCase(fetchBudgets.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchBudgets.fulfilled, (state, action) => {
        state.loading = false;
        state.budgets = action.payload;
      })
      .addCase(fetchBudgets.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload?.message || 'Failed to fetch budgets';
      })

      // fetchBudgetById
      .addCase(fetchBudgetById.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchBudgetById.fulfilled, (state, action) => {
        state.loading = false;
        state.selectedBudget = action.payload;
      })
      .addCase(fetchBudgetById.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload?.message || 'Failed to fetch budget';
      })

      // createNewBudget
      .addCase(createNewBudget.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(createNewBudget.fulfilled, (state, action) => {
        state.loading = false;
        state.budgets.push(action.payload);
      })
      .addCase(createNewBudget.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload?.message || 'Failed to create budget';
      })

      // updateExistingBudget
      .addCase(updateExistingBudget.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateExistingBudget.fulfilled, (state, action) => {
        state.loading = false;
        const index = state.budgets.findIndex(b => b.id === action.payload.id);
        if (index !== -1) {
          state.budgets[index] = action.payload;
        }
        if (state.selectedBudget?.id === action.payload.id) {
          state.selectedBudget = action.payload;
        }
      })
      .addCase(updateExistingBudget.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload?.message || 'Failed to update budget';
      })

      // removeBudget
      .addCase(removeBudget.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(removeBudget.fulfilled, (state, action) => {
        state.loading = false;
        state.budgets = state.budgets.filter(b => b.id !== action.meta.arg);
        if (state.selectedBudget?.id === action.meta.arg) {
          state.selectedBudget = null;
        }
      })
      .addCase(removeBudget.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload?.message || 'Failed to delete budget';
      })

      // fetchBudgetProgress
      .addCase(fetchBudgetProgress.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchBudgetProgress.fulfilled, (state, action) => {
        state.loading = false;
        state.progress[action.meta.arg.budgetId] = action.payload;
      })
      .addCase(fetchBudgetProgress.rejected, (state, action) => {
        state.loading = false;
        state.error = action.payload?.message || 'Failed to fetch budget progress';
      });
  }
});

// Selectors
export const selectAllBudgets = (state: { budgets: BudgetState }) => state.budgets.budgets;
export const selectSelectedBudget = (state: { budgets: BudgetState }) => state.budgets.selectedBudget;
export const selectBudgetProgress = (state: { budgets: BudgetState }) => state.budgets.progress;
export const selectBudgetsLoading = (state: { budgets: BudgetState }) => state.budgets.loading;
export const selectBudgetsError = (state: { budgets: BudgetState }) => state.budgets.error;

export const { clearSelectedBudget, clearBudgetError } = budgetsSlice.actions;
export default budgetsSlice.reducer;