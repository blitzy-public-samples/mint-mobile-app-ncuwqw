/**
 * HUMAN TASKS:
 * 1. Ensure Redux DevTools is configured for development environment
 * 2. Set up Redux persist configuration for caching investment data
 * 3. Configure error tracking service integration for API errors
 * 4. Set up performance monitoring for Redux state updates
 */

// @reduxjs/toolkit version: ^1.9.0
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { 
  Account, 
  AccountType, 
  APIResponse, 
  APIError, 
  Transaction, 
  Investment,
  PortfolioSummary 
} from '../../types';
import {
  getInvestmentAccounts,
  getPortfolioSummary,
  getInvestmentTransactions,
  getInvestmentPerformance
} from '../../services/api/investments';

// Define interface for performance metrics state
interface PerformanceMetrics {
  returnAmount: number;
  returnPercentage: number;
  period: string;
  startDate: Date;
  endDate: Date;
}

// Define interface for the investments slice state
interface InvestmentsState {
  accounts: Account[];
  portfolioSummary: PortfolioSummary | null;
  transactions: Transaction[];
  holdings: Investment[];
  performance: PerformanceMetrics | null;
  isLoading: boolean;
  error: APIError | null;
}

// Initial state
const initialState: InvestmentsState = {
  accounts: [],
  portfolioSummary: null,
  transactions: [],
  holdings: [],
  performance: null,
  isLoading: false,
  error: null
};

// Requirement: Investment Tracking - Basic portfolio monitoring and investment account integration
export const fetchInvestmentAccounts = createAsyncThunk(
  'investments/fetchAccounts',
  async (_, { rejectWithValue }) => {
    try {
      const response = await getInvestmentAccounts();
      return response.data;
    } catch (error) {
      return rejectWithValue(error as APIError);
    }
  }
);

// Requirement: Investment Tracking - Basic portfolio monitoring
export const fetchPortfolioSummary = createAsyncThunk(
  'investments/fetchPortfolio',
  async (_, { rejectWithValue }) => {
    try {
      const response = await getPortfolioSummary();
      return response.data;
    } catch (error) {
      return rejectWithValue(error as APIError);
    }
  }
);

// Requirement: Investment Tracking - Basic portfolio monitoring
export const fetchInvestmentTransactions = createAsyncThunk(
  'investments/fetchTransactions',
  async (filters: {
    startDate?: Date;
    endDate?: Date;
    type?: string;
    symbol?: string;
  }, { rejectWithValue }) => {
    try {
      const response = await getInvestmentTransactions('all', filters);
      return response.data;
    } catch (error) {
      return rejectWithValue(error as APIError);
    }
  }
);

// Requirement: Performance Metrics - Simple performance metrics tracking
export const fetchInvestmentPerformance = createAsyncThunk(
  'investments/fetchPerformance',
  async (period: '1d' | '1w' | '1m' | '3m' | '6m' | '1y' | 'ytd' | 'all', { rejectWithValue }) => {
    try {
      const response = await getInvestmentPerformance('portfolio', period);
      return response.data;
    } catch (error) {
      return rejectWithValue(error as APIError);
    }
  }
);

// Create the investments slice
const investmentsSlice = createSlice({
  name: 'investments',
  initialState,
  reducers: {
    resetInvestmentState: (state) => {
      Object.assign(state, initialState);
    },
    clearInvestmentError: (state) => {
      state.error = null;
    }
  },
  extraReducers: (builder) => {
    // Fetch Investment Accounts
    builder
      .addCase(fetchInvestmentAccounts.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchInvestmentAccounts.fulfilled, (state, action) => {
        state.isLoading = false;
        state.accounts = action.payload.filter(
          account => account.type === AccountType.INVESTMENT
        );
      })
      .addCase(fetchInvestmentAccounts.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as APIError;
      })

    // Fetch Portfolio Summary
    builder
      .addCase(fetchPortfolioSummary.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchPortfolioSummary.fulfilled, (state, action) => {
        state.isLoading = false;
        state.portfolioSummary = action.payload;
        state.holdings = action.payload.holdings;
      })
      .addCase(fetchPortfolioSummary.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as APIError;
      })

    // Fetch Investment Transactions
    builder
      .addCase(fetchInvestmentTransactions.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchInvestmentTransactions.fulfilled, (state, action) => {
        state.isLoading = false;
        state.transactions = action.payload;
      })
      .addCase(fetchInvestmentTransactions.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as APIError;
      })

    // Fetch Investment Performance
    builder
      .addCase(fetchInvestmentPerformance.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(fetchInvestmentPerformance.fulfilled, (state, action) => {
        state.isLoading = false;
        state.performance = action.payload;
      })
      .addCase(fetchInvestmentPerformance.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.payload as APIError;
      });
  }
});

// Export actions
export const { resetInvestmentState, clearInvestmentError } = investmentsSlice.actions;

// Export selectors
export const selectInvestmentAccounts = (state: { investments: InvestmentsState }) => 
  state.investments.accounts;

export const selectPortfolioSummary = (state: { investments: InvestmentsState }) => 
  state.investments.portfolioSummary;

export const selectInvestmentTransactions = (state: { investments: InvestmentsState }) => 
  state.investments.transactions;

export const selectInvestmentPerformance = (state: { investments: InvestmentsState }) => 
  state.investments.performance;

export const selectInvestmentLoading = (state: { investments: InvestmentsState }) => 
  state.investments.isLoading;

export const selectInvestmentError = (state: { investments: InvestmentsState }) => 
  state.investments.error;

// Export reducer as default
export default investmentsSlice.reducer;