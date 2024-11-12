/**
 * HUMAN TASKS:
 * 1. Configure Redux DevTools in development environment
 * 2. Set up Redux persist configuration for auth state
 * 3. Configure token refresh interval in environment variables
 * 4. Set up error tracking/monitoring for authentication failures
 */

// @reduxjs/toolkit version: ^1.9.5
import { createSlice, createAsyncThunk, PayloadAction } from '@reduxjs/toolkit';
import { User, APIResponse } from '../../types';
import { login, register, logout, refreshToken } from '../../services/api/auth';

// Requirement: Authentication Flow - Define authentication state interface
interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
  lastTokenRefresh: number | null;
}

// Initial state with secure defaults
const initialState: AuthState = {
  user: null,
  token: null,
  isAuthenticated: false,
  isLoading: false,
  error: null,
  lastTokenRefresh: null,
};

// Requirement: Authentication Flow - Implement secure user login
export const loginThunk = createAsyncThunk(
  'auth/login',
  async (credentials: { email: string; password: string }) => {
    const response = await login(credentials.email, credentials.password);
    return response.data;
  }
);

// Requirement: Multi-platform Authentication - Implement user registration
export const registerThunk = createAsyncThunk(
  'auth/register',
  async (userData: { email: string; password: string; name: string }) => {
    const response = await register(
      userData.email,
      userData.password,
      userData.name
    );
    return response.data;
  }
);

// Requirement: Authentication Flow - Implement secure logout
export const logoutThunk = createAsyncThunk('auth/logout', async () => {
  await logout();
});

// Requirement: Authentication Flow - Implement secure token refresh
export const refreshTokenThunk = createAsyncThunk('auth/refreshToken', async () => {
  const response = await refreshToken();
  return response.data;
});

// Requirement: Security Standards - Create secure auth slice with proper state management
const authSlice = createSlice({
  name: 'auth',
  initialState,
  reducers: {
    // Synchronous actions for direct state updates
    setUser: (state, action: PayloadAction<User>) => {
      state.user = action.payload;
      state.isAuthenticated = true;
    },
    clearUser: (state) => {
      state.user = null;
      state.token = null;
      state.isAuthenticated = false;
      state.lastTokenRefresh = null;
    },
    setToken: (state, action: PayloadAction<string>) => {
      state.token = action.payload;
      state.lastTokenRefresh = Date.now();
    },
  },
  extraReducers: (builder) => {
    // Login action handlers
    builder
      .addCase(loginThunk.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(loginThunk.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload;
        state.isAuthenticated = true;
        state.error = null;
      })
      .addCase(loginThunk.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Login failed';
      })

    // Registration action handlers
      .addCase(registerThunk.pending, (state) => {
        state.isLoading = true;
        state.error = null;
      })
      .addCase(registerThunk.fulfilled, (state, action) => {
        state.isLoading = false;
        state.user = action.payload;
        state.isAuthenticated = true;
        state.error = null;
      })
      .addCase(registerThunk.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Registration failed';
      })

    // Logout action handlers
      .addCase(logoutThunk.pending, (state) => {
        state.isLoading = true;
      })
      .addCase(logoutThunk.fulfilled, (state) => {
        state.isLoading = false;
        state.user = null;
        state.token = null;
        state.isAuthenticated = false;
        state.lastTokenRefresh = null;
        state.error = null;
      })
      .addCase(logoutThunk.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Logout failed';
      })

    // Token refresh action handlers
      .addCase(refreshTokenThunk.pending, (state) => {
        state.isLoading = true;
      })
      .addCase(refreshTokenThunk.fulfilled, (state, action) => {
        state.isLoading = false;
        state.token = action.payload.token;
        state.lastTokenRefresh = Date.now();
        state.error = null;
      })
      .addCase(refreshTokenThunk.rejected, (state, action) => {
        state.isLoading = false;
        state.error = action.error.message || 'Token refresh failed';
        // Clear auth state on token refresh failure
        state.user = null;
        state.token = null;
        state.isAuthenticated = false;
        state.lastTokenRefresh = null;
      });
  },
});

// Export actions and reducer
export const { setUser, clearUser, setToken } = authSlice.actions;
export const authReducer = authSlice.reducer;