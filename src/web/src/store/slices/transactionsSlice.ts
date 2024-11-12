/**
 * HUMAN TASKS:
 * 1. Configure Redux DevTools in development environment for state debugging
 * 2. Set up error tracking service integration for monitoring Redux state errors
 * 3. Verify Redux persist configuration for transaction state caching
 * 4. Configure performance monitoring for Redux actions and state updates
 */

// @reduxjs/toolkit version: ^1.9.0
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import {
  Transaction,
  TransactionType,
  APIResponse,
  APIError
} from '../../types';
import {
  getTransactions,
  getTransactionById,
  createTransaction,
  updateTransaction,
  deleteTransaction,
  categorizeTransaction,
  searchTransactions
} from '../../services/api/transactions';

// Define the shape of the transactions state
interface TransactionsState {
  items: Transaction[];
  loading: boolean;
  error: string | null;
  currentPage: number;
  totalPages: number;
  filters: {
    accountId: string | null;
    categoryId: string | null;
    startDate: Date | null;
    endDate: Date | null;
    searchQuery: string | null;
  };
}

// Initial state
const initialState: TransactionsState = {
  items: [],
  loading: false,
  error: null,
  currentPage: 1,
  totalPages: 1,
  filters: {
    accountId: null,
    categoryId: null,
    startDate: null,
    endDate: null,
    searchQuery: null
  }
};

// Requirement: Financial Tracking - Implements automated transaction import
export const fetchTransactions = createAsyncThunk(
  'transactions/fetchTransactions',
  async (params: {
    accountId?: string;
    categoryId?: string;
    startDate?: Date;
    endDate?: Date;
    page?: number;
    limit?: number;
  }) => {
    const response = await getTransactions(params);
    return response.data;
  }
);

// Requirement: Financial Tracking - Implements transaction search/filtering
export const searchTransactionsThunk = createAsyncThunk(
  'transactions/searchTransactions',
  async (searchParams: {
    query: string;
    accountId?: string;
    startDate?: Date;
    endDate?: Date;
    page?: number;
    limit?: number;
  }) => {
    const response = await searchTransactions(searchParams);
    return response.data;
  }
);

// Requirement: Transaction Management - Implements transaction creation
export const createTransactionThunk = createAsyncThunk(
  'transactions/createTransaction',
  async (transactionData: {
    accountId: string;
    amount: number;
    description: string;
    categoryId: string;
    date: Date;
    type: TransactionType;
  }) => {
    const response = await createTransaction(transactionData);
    return response.data;
  }
);

// Requirement: Transaction Management - Implements transaction updates
export const updateTransactionThunk = createAsyncThunk(
  'transactions/updateTransaction',
  async ({ transactionId, updateData }: {
    transactionId: string;
    updateData: {
      categoryId?: string;
      description?: string;
    };
  }) => {
    const response = await updateTransaction(transactionId, updateData);
    return response.data;
  }
);

// Requirement: Transaction Management - Implements transaction deletion
export const deleteTransactionThunk = createAsyncThunk(
  'transactions/deleteTransaction',
  async (transactionId: string) => {
    const response = await deleteTransaction(transactionId);
    return transactionId;
  }
);

// Requirement: Financial Tracking - Implements category management
export const categorizeTransactionThunk = createAsyncThunk(
  'transactions/categorizeTransaction',
  async ({ transactionId, categoryId }: {
    transactionId: string;
    categoryId: string;
  }) => {
    const response = await categorizeTransaction(transactionId, categoryId);
    return response.data;
  }
);

// Create the transactions slice
const transactionsSlice = createSlice({
  name: 'transactions',
  initialState,
  reducers: {
    setFilters: (state, action: PayloadAction<Partial<TransactionsState['filters']>>) => {
      state.filters = {
        ...state.filters,
        ...action.payload
      };
      state.currentPage = 1; // Reset page when filters change
    },
    clearFilters: (state) => {
      state.filters = initialState.filters;
      state.currentPage = 1;
    },
    setCurrentPage: (state, action: PayloadAction<number>) => {
      state.currentPage = action.payload;
    }
  },
  extraReducers: (builder) => {
    // Handle fetchTransactions
    builder
      .addCase(fetchTransactions.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(fetchTransactions.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload;
      })
      .addCase(fetchTransactions.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to fetch transactions';
      })

    // Handle searchTransactions
    builder
      .addCase(searchTransactionsThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(searchTransactionsThunk.fulfilled, (state, action) => {
        state.loading = false;
        state.items = action.payload;
      })
      .addCase(searchTransactionsThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to search transactions';
      })

    // Handle createTransaction
    builder
      .addCase(createTransactionThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(createTransactionThunk.fulfilled, (state, action) => {
        state.loading = false;
        state.items = [action.payload, ...state.items];
      })
      .addCase(createTransactionThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to create transaction';
      })

    // Handle updateTransaction
    builder
      .addCase(updateTransactionThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(updateTransactionThunk.fulfilled, (state, action) => {
        state.loading = false;
        state.items = state.items.map(item =>
          item.id === action.payload.id ? action.payload : item
        );
      })
      .addCase(updateTransactionThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to update transaction';
      })

    // Handle deleteTransaction
    builder
      .addCase(deleteTransactionThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(deleteTransactionThunk.fulfilled, (state, action) => {
        state.loading = false;
        state.items = state.items.filter(item => item.id !== action.payload);
      })
      .addCase(deleteTransactionThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to delete transaction';
      })

    // Handle categorizeTransaction
    builder
      .addCase(categorizeTransactionThunk.pending, (state) => {
        state.loading = true;
        state.error = null;
      })
      .addCase(categorizeTransactionThunk.fulfilled, (state, action) => {
        state.loading = false;
        state.items = state.items.map(item =>
          item.id === action.payload.id ? action.payload : item
        );
      })
      .addCase(categorizeTransactionThunk.rejected, (state, action) => {
        state.loading = false;
        state.error = action.error.message || 'Failed to categorize transaction';
      });
  }
});

// Export actions and reducer
export const { setFilters, clearFilters, setCurrentPage } = transactionsSlice.actions;
export default transactionsSlice.reducer;