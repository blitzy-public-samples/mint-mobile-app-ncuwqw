// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify real-time update interval (60s) meets performance requirements
// 2. Test responsiveness on various mobile screen sizes
// 3. Validate accessibility features with screen readers
// 4. Review loading states and error messages with design team

import React, { useEffect, useCallback, useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import Card from '../common/Card';
import { useApi } from '../../hooks/useApi';
import { getAccounts } from '../../services/api/accounts';
import { formatCurrency } from '../../utils/formatting';

interface Account {
  id: string;
  name: string;
  type: string;
  balance: number;
  currency: string;
  isActive: boolean;
  lastUpdated: string;
}

/**
 * Calculates the total net worth from active accounts
 * @requirements Account Management - 1.2 Scope/Account Management
 */
const calculateNetWorth = (accounts: Account[]): number => {
  return accounts
    .filter(account => account.isActive)
    .reduce((total, account) => total + account.balance, 0);
};

/**
 * AccountSummary component displays financial account information
 * @requirements Dashboard Layout - 5.1.2 Dashboard Layout
 * @requirements Mobile Adaptations - 5.1.6 Mobile-Specific Adaptations
 */
const AccountSummary: React.FC = () => {
  const [refreshKey, setRefreshKey] = useState<number>(0);

  // Initialize API hook for fetching accounts
  const { 
    data: accounts, 
    error, 
    loading,
    execute: fetchAccounts 
  } = useApi<Account[]>({
    method: 'GET',
    url: '/accounts',
    config: getAccounts
  });

  // Fetch accounts on mount and refresh
  useEffect(() => {
    fetchAccounts();
  }, [fetchAccounts, refreshKey]);

  // Set up real-time updates every 60 seconds
  useEffect(() => {
    const intervalId = setInterval(() => {
      setRefreshKey(prev => prev + 1);
    }, 60000);

    return () => clearInterval(intervalId);
  }, []);

  // Calculate net worth when accounts data changes
  const netWorth = accounts ? calculateNetWorth(accounts) : 0;

  // Render loading state
  if (loading && !accounts) {
    return (
      <Card elevation={1} padding={16} borderRadius={8}>
        <View style={styles.container}>
          <Text style={styles.headerText}>Loading account information...</Text>
        </View>
      </Card>
    );
  }

  // Render error state
  if (error) {
    return (
      <Card elevation={1} padding={16} borderRadius={8}>
        <View style={styles.container}>
          <Text style={[styles.headerText, { color: '#FF0000' }]}>
            Error loading accounts: {error.message}
          </Text>
        </View>
      </Card>
    );
  }

  return (
    <Card elevation={1} padding={16} borderRadius={8}>
      <View style={styles.container}>
        {/* Net Worth Section */}
        <Text style={styles.headerText}>
          Total Net Worth
        </Text>
        <Text style={styles.balanceText}>
          {formatCurrency(netWorth, 'USD')}
        </Text>

        {/* Account List Section */}
        {accounts?.map(account => (
          <View key={account.id} style={styles.accountRow}>
            <Text style={styles.balanceText}>
              {account.name}
            </Text>
            <Text 
              style={[
                styles.balanceText,
                { color: account.balance < 0 ? '#FF0000' : '#000000' }
              ]}
            >
              {formatCurrency(account.balance, account.currency)}
            </Text>
          </View>
        ))}
      </View>
    </Card>
  );
};

/**
 * Component styles
 * @requirements Mobile Adaptations - 5.1.6 Mobile-Specific Adaptations
 */
const styles = StyleSheet.create({
  container: {
    padding: 16,
    marginBottom: 16,
  },
  headerText: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  balanceText: {
    fontSize: 18,
    marginVertical: 8,
  },
  accountRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 8,
    borderBottomWidth: 1,
    borderBottomColor: '#EEEEEE',
  },
});

export default AccountSummary;