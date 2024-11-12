// react version: ^18.0.0
// react-native version: ^0.71.0

/**
 * HUMAN TASKS:
 * 1. Verify real-time balance update performance with large account lists
 * 2. Test accessibility features with screen readers
 * 3. Validate responsive layout on different screen sizes
 * 4. Configure account sync interval in environment variables
 */

import React, { useEffect, useState, useCallback } from 'react';
import { StyleSheet, View, RefreshControl, ScrollView } from 'react-native';
import AccountCard from '../../components/accounts/AccountCard';
import EmptyState from '../../components/common/EmptyState';
import Loading from '../../components/common/Loading';
import { Account } from '../../types';
import { getAccounts, syncAccount } from '../../services/api/accounts';

/**
 * AccountsListScreen displays a list of user's financial accounts with real-time balances
 * Requirements addressed:
 * - Account Management (1.2 Scope/Account Management)
 * - Real-time Updates (1.2 Scope/Account Management)
 * - Cross-Platform UI (2.2.1 Client Applications/React Native)
 */
const AccountsListScreen: React.FC = () => {
  // State management for accounts, loading, and refresh states
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);

  /**
   * Fetches user's financial accounts from the API
   * Requirement: Account Management - Multi-platform user authentication and financial account aggregation
   */
  const fetchAccounts = async (): Promise<void> => {
    try {
      const accountsData = await getAccounts();
      setAccounts(accountsData);
    } catch (error) {
      // Error handling would be implemented based on the application's error handling strategy
      console.error('Failed to fetch accounts:', error);
    } finally {
      setLoading(false);
    }
  };

  /**
   * Handles pull-to-refresh functionality
   * Requirement: Real-time Updates - Real-time balance updates and cross-platform data synchronization
   */
  const handleRefresh = useCallback(async (): Promise<void> => {
    setRefreshing(true);
    await fetchAccounts();
    setRefreshing(false);
  }, []);

  /**
   * Handles account sync when user clicks on an account
   * Requirement: Real-time Updates - Real-time balance updates and cross-platform data synchronization
   */
  const handleAccountSync = useCallback(async (accountId: string): Promise<void> => {
    try {
      const updatedAccount = await syncAccount(accountId);
      setAccounts(prevAccounts => 
        prevAccounts.map(account => 
          account.id === accountId ? updatedAccount : account
        )
      );
    } catch (error) {
      console.error('Failed to sync account:', error);
    }
  }, []);

  // Fetch accounts on component mount
  useEffect(() => {
    fetchAccounts();
  }, []);

  // Show loading state while fetching initial data
  if (loading) {
    return (
      <Loading 
        size="large"
        message="Loading your accounts..."
      />
    );
  }

  // Show empty state when no accounts exist
  if (!accounts.length) {
    return (
      <EmptyState
        title="No Accounts Found"
        message="Add your first financial account to start tracking your finances"
        actionButtonText="Add Account"
        onActionButtonPress={() => {
          // Navigation to add account screen would be implemented here
        }}
      />
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={styles.contentContainer}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            testID="accounts-refresh-control"
          />
        }
      >
        <View style={styles.accountsList}>
          {accounts.map(account => (
            <AccountCard
              key={account.id}
              account={account}
              onClick={() => handleAccountSync(account.id)}
            />
          ))}
        </View>
      </ScrollView>
    </View>
  );
};

/**
 * Styles for the AccountsListScreen component
 * Requirement: Cross-Platform UI - Maintain consistent UI components across platforms
 */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF', // Should match theme.colors.background
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    padding: 16, // Should match theme.spacing.md
  },
  accountsList: {
    gap: 12, // Should match theme.spacing.sm
  },
});

export default AccountsListScreen;