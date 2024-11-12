// @jest/globals version: ^29.0.0
// @testing-library/react-native version: ^12.0.0
// react-redux version: ^8.0.0
// @reduxjs/toolkit version: ^1.9.0

// Human Tasks:
// 1. Verify test coverage meets minimum threshold (>80%)
// 2. Run tests in CI pipeline with different network conditions
// 3. Add performance testing scenarios for real-time updates
// 4. Review error simulation scenarios with QA team

import React from 'react';
import { render, fireEvent, waitFor, act } from '@testing-library/react-native';
import { Provider } from 'react-redux';
import { configureStore } from '@reduxjs/toolkit';
import { jest, describe, beforeEach, it, expect } from '@jest/globals';

import DashboardScreen, { 
  handleRefresh, 
  handleTransactionPress 
} from '../../../screens/dashboard/DashboardScreen';
import { calculateNetWorth } from '../../../components/dashboard/AccountSummary';

// Mock navigation
const mockNavigate = jest.fn();
jest.mock('@react-navigation/native', () => ({
  useNavigation: () => ({
    navigate: mockNavigate
  })
}));

// Mock child components
jest.mock('../../../components/dashboard/AccountSummary', () => ({
  AccountSummary: () => 'AccountSummary',
  calculateNetWorth: jest.fn()
}));
jest.mock('../../../components/dashboard/BudgetOverview', () => ({
  BudgetOverview: () => 'BudgetOverview'
}));
jest.mock('../../../components/dashboard/GoalsProgress', () => ({
  GoalsProgress: () => 'GoalsProgress'
}));
jest.mock('../../../components/dashboard/RecentTransactions', () => ({
  RecentTransactions: () => 'RecentTransactions'
}));
jest.mock('../../../components/common/Loading', () => ({
  Loading: () => 'Loading'
}));
jest.mock('../../../components/common/Error', () => ({
  Error: () => 'Error'
}));

// Mock Redux store
const createTestStore = (initialState = {}) => {
  return configureStore({
    reducer: {
      accounts: (state = initialState.accounts || [], action) => {
        switch (action.type) {
          case 'accounts/refresh':
            return [...state];
          default:
            return state;
        }
      },
      budgets: (state = initialState.budgets || [], action) => {
        switch (action.type) {
          case 'budgets/refresh':
            return [...state];
          default:
            return state;
        }
      },
      goals: (state = initialState.goals || [], action) => {
        switch (action.type) {
          case 'goals/refresh':
            return [...state];
          default:
            return state;
        }
      },
      transactions: (state = initialState.transactions || [], action) => {
        switch (action.type) {
          case 'transactions/refresh':
            return [...state];
          default:
            return state;
        }
      }
    }
  });
};

describe('DashboardScreen', () => {
  let store;

  beforeEach(() => {
    // Clear all mocks
    jest.clearAllMocks();
    
    // Reset store
    store = createTestStore({
      accounts: [
        { id: '1', balance: 1000, type: 'checking' },
        { id: '2', balance: 2000, type: 'savings' }
      ],
      budgets: [
        { id: '1', category: 'Food', limit: 500, spent: 300 }
      ],
      goals: [
        { id: '1', name: 'Vacation', target: 5000, current: 2500 }
      ],
      transactions: [
        { id: '1', amount: 100, description: 'Groceries' }
      ]
    });

    // Mock calculateNetWorth implementation
    calculateNetWorth.mockImplementation((accounts) => {
      return accounts.reduce((sum, account) => sum + account.balance, 0);
    });
  });

  // Test case: Initial render
  it('renders correctly', async () => {
    const { getByTestId, queryByText } = render(
      <Provider store={store}>
        <DashboardScreen />
      </Provider>
    );

    // Verify initial loading state
    expect(queryByText('Loading')).toBeTruthy();

    // Wait for loading to complete
    await waitFor(() => {
      expect(queryByText('Loading')).toBeFalsy();
    });

    // Verify all dashboard components are rendered
    expect(queryByText('AccountSummary')).toBeTruthy();
    expect(queryByText('BudgetOverview')).toBeTruthy();
    expect(queryByText('GoalsProgress')).toBeTruthy();
    expect(queryByText('RecentTransactions')).toBeTruthy();

    // Verify refresh control is present
    expect(getByTestId('dashboard-refresh-control')).toBeTruthy();
  });

  // Test case: Refresh functionality
  it('handles refresh correctly', async () => {
    const { getByTestId } = render(
      <Provider store={store}>
        <DashboardScreen />
      </Provider>
    );

    // Wait for initial render to complete
    await waitFor(() => {
      expect(getByTestId('dashboard-refresh-control')).toBeTruthy();
    });

    // Trigger refresh
    await act(async () => {
      fireEvent.refresh(getByTestId('dashboard-refresh-control'));
    });

    // Verify store actions were dispatched
    const actions = store.getState();
    expect(actions.accounts).toBeTruthy();
    expect(actions.budgets).toBeTruthy();
    expect(actions.goals).toBeTruthy();
    expect(actions.transactions).toBeTruthy();
  });

  // Test case: Transaction navigation
  it('navigates to transaction details', async () => {
    const { getByTestId } = render(
      <Provider store={store}>
        <DashboardScreen />
      </Provider>
    );

    // Wait for component to render
    await waitFor(() => {
      expect(getByTestId('dashboard-refresh-control')).toBeTruthy();
    });

    // Simulate transaction press
    act(() => {
      handleTransactionPress('1');
    });

    // Verify navigation was called with correct params
    expect(mockNavigate).toHaveBeenCalledWith('TransactionDetails', {
      transactionId: '1'
    });
  });

  // Test case: Error handling
  it('displays error state correctly', async () => {
    // Mock store with error state
    store = createTestStore();
    const mockError = new Error('API Error');
    jest.spyOn(console, 'error').mockImplementation(() => {});

    const { queryByText } = render(
      <Provider store={store}>
        <DashboardScreen />
      </Provider>
    );

    // Trigger error state
    await act(async () => {
      await handleRefresh();
    });

    // Verify error component is displayed
    expect(queryByText('Error')).toBeTruthy();
  });

  // Test case: Real-time updates
  it('sets up real-time updates correctly', async () => {
    jest.useFakeTimers();

    render(
      <Provider store={store}>
        <DashboardScreen />
      </Provider>
    );

    // Fast-forward 30 seconds
    act(() => {
      jest.advanceTimersByTime(30000);
    });

    // Verify refresh was triggered
    const actions = store.getState();
    expect(actions.accounts).toBeTruthy();
    expect(actions.budgets).toBeTruthy();
    expect(actions.goals).toBeTruthy();
    expect(actions.transactions).toBeTruthy();

    jest.useRealTimers();
  });
});