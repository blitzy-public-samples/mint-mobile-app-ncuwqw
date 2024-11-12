/**
 * HUMAN TASKS:
 * 1. Configure Redux DevTools for development environment
 * 2. Set up error tracking integration for failed async operations
 * 3. Configure performance monitoring for Redux state updates
 * 4. Verify Redux persist configuration for account state caching
 */

// @reduxjs/toolkit version: ^1.9.0
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { Account, AccountType, APIError } from '../../types';
import {
  getAccounts,
  getAccountById,
  linkAccount,
  unlinkAccount,
  syncAccount,
  updateAccountSettings,
} from '../../services/api/accounts';

// State interface definition
interface AccountsState {
  items: Account[];
  loading: {
    fetchAll: boolean;
    link: boolean;
    unlink: boolean;
    sync: boolean;
  };
  error: string | null;
  lastSync: string | null;
}

// Initial state
const initialState: AccountsState = {
  items: [],
  loading: {
    fetchAll: false,
    link: false,
    unlink: false,
    sync: false,
  },
  error: null,
  lastSync: null,
};

// Requirement: Account Management - Multi-platform user authentication and financial account aggregation
export const fetchAccounts = createAsyncThunk<
  Account[],
  void,
  { rejectValue: string }
>('accounts/fetchAccounts', async (_, { rejectWithValue }) => {
  try {
    const accounts = await getAccounts();
    return accounts;
  } catch (error) {
    const apiError = error as APIError;
    return rejectWithValue(apiError.message);
  }
});

// Requirement: Account Management - Multi-platform user authentication and financial account aggregation
export const linkNewAccount = createAsyncThunk<
  Account,
  {
    institutionId: string;
    credentials: Record<string, string>;
    accountType: AccountType;
  },
  { rejectValue: string }
>('accounts/linkNewAccount', async (linkData, { rejectWithValue }) => {
  try {
    const account = await linkAccount(linkData);
    return account;
  } catch (error) {
    const apiError = error as APIError;
    return rejectWithValue(apiError.message);
  }
});

// Requirement: Account Management - Multi-platform user authentication and financial account aggregation
export const unlinkExistingAccount = createAsyncThunk<
  string,
  string,
  { rejectValue: string }
>('accounts/unlinkExistingAccount', async (accountId, { rejectWithValue }) => {
  try {
    await unlinkAccount(accountId);
    return accountId;
  } catch (error) {
    const apiError = error as APIError;
    return rejectWithValue(apiError.message);
  }
});

// Requirement: Real-time Updates - Real-time balance updates and cross-platform data synchronization
export const syncAccountData = createAsyncThunk<
  Account,
  string,
  { rejectValue: string }
>('accounts/syncAccountData', async (accountId, { rejectWithValue }) => {
  try {
    const updatedAccount = await syncAccount(accountId);
    return updatedAccount;
  } catch (error) {
    const apiError = error as APIError;
    return rejectWithValue(apiError.message);
  }
});

// Create the accounts slice
export const accountsSlice = createSlice({
  name: 'accounts',
  initialState,
  reducers: {
    clearError: (state) => {
      state.error = null;
    },
    resetState: () => initialState,
  },
  extraReducers: (builder) => {
    // Fetch accounts reducers
    builder
      .addCase(fetchAccounts.pending, (state) => {
        state.loading.fetchAll = true;
        state.error = null;
      })
      .addCase(fetchAccounts.fulfilled, (state, action) => {
        state.loading.fetchAll = false;
        state.items = action.payload;
        state.lastSync = new Date().toISOString();
      })
      .addCase(fetchAccounts.rejected, (state, action) => {
        state.loading.fetchAll = false;
        state.error = action.payload ?? 'Failed to fetch accounts';
      })

      // Link account reducers
      .addCase(linkNewAccount.pending, (state) => {
        state.loading.link = true;
        state.error = null;
      })
      .addCase(linkNewAccount.fulfilled, (state, action) => {
        state.loading.link = false;
        state.items.push(action.payload);
      })
      .addCase(linkNewAccount.rejected, (state, action) => {
        state.loading.link = false;
        state.error = action.payload ?? 'Failed to link account';
      })

      // Unlink account reducers
      .addCase(unlinkExistingAccount.pending, (state) => {
        state.loading.unlink = true;
        state.error = null;
      })
      .addCase(unlinkExistingAccount.fulfilled, (state, action) => {
        state.loading.unlink = false;
        state.items = state.items.filter((account) => account.id !== action.payload);
      })
      .addCase(unlinkExistingAccount.rejected, (state, action) => {
        state.loading.unlink = false;
        state.error = action.payload ?? 'Failed to unlink account';
      })

      // Sync account reducers
      .addCase(syncAccountData.pending, (state) => {
        state.loading.sync = true;
        state.error = null;
      })
      .addCase(syncAccountData.fulfilled, (state, action) => {
        state.loading.sync = false;
        const index = state.items.findIndex((account) => account.id === action.payload.id);
        if (index !== -1) {
          state.items[index] = action.payload;
        }
        state.lastSync = new Date().toISOString();
      })
      .addCase(syncAccountData.rejected, (state, action) => {
        state.loading.sync = false;
        state.error = action.payload ?? 'Failed to sync account';
      });
  },
});

// Export actions
export const { clearError, resetState } = accountsSlice.actions;

// Selectors
export const selectAccounts = (state: { accounts: AccountsState }) => state.accounts.items;
export const selectAccountById = (state: { accounts: AccountsState }, accountId: string) =>
  state.accounts.items.find((account) => account.id === accountId);
export const selectAccountsLoading = (state: { accounts: AccountsState }) => state.accounts.loading;
export const selectAccountsError = (state: { accounts: AccountsState }) => state.accounts.error;
export const selectLastSync = (state: { accounts: AccountsState }) => state.accounts.lastSync;

// Export reducer
export default accountsSlice.reducer;