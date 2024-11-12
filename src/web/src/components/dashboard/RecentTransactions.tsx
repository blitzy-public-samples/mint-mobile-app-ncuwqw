/**
 * HUMAN TASKS:
 * 1. Verify that the transaction API endpoint is properly configured in the environment
 * 2. Test empty state appearance across different screen sizes
 * 3. Validate loading state animations for performance
 * 4. Ensure proper error boundary configuration for error states
 */

// react version: ^18.0.0
// react-native version: ^0.71.0

import React, { useEffect, useState } from 'react';
import {
  StyleSheet,
  View,
  Text,
  FlatList,
  ActivityIndicator,
} from 'react-native';
import { Transaction } from '../../types';
import TransactionItem from '../transactions/TransactionItem';
import EmptyState from '../common/EmptyState';
import { getTransactions } from '../../services/api/transactions';

// Requirement: Dashboard View - Show recent transactions as part of the dashboard overview
interface RecentTransactionsProps {
  limit: number;
  onTransactionPress: (transaction: Transaction) => void;
}

const RecentTransactions: React.FC<RecentTransactionsProps> = ({
  limit,
  onTransactionPress,
}) => {
  const [transactions, setTransactions] = useState<Transaction[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Requirement: Financial Tracking - Display automated transaction imports with category management
  const fetchRecentTransactions = async (limit: number): Promise<void> => {
    try {
      setLoading(true);
      setError(null);
      const response = await getTransactions({ limit, page: 1 });
      setTransactions(response.data);
    } catch (err) {
      setError('Unable to fetch recent transactions. Please try again later.');
      console.error('Error fetching recent transactions:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchRecentTransactions(limit);
  }, [limit]);

  const renderSeparator = (): React.ReactElement => (
    <View style={styles.separator} />
  );

  const renderTransactionItem = ({ item }: { item: Transaction }): React.ReactElement => (
    <TransactionItem
      transaction={item}
      onClick={() => onTransactionPress(item)}
    />
  );

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="theme.colors.primary" />
      </View>
    );
  }

  if (error) {
    return (
      <EmptyState
        title="Oops!"
        message={error}
      />
    );
  }

  if (transactions.length === 0) {
    return (
      <EmptyState
        title="No Recent Transactions"
        message="Your recent transactions will appear here once they're available."
      />
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Recent Transactions</Text>
      </View>
      <FlatList
        style={styles.list}
        data={transactions}
        renderItem={renderTransactionItem}
        ItemSeparatorComponent={renderSeparator}
        keyExtractor={(item) => item.id}
        showsVerticalScrollIndicator={false}
        testID="recent-transactions-list"
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'theme.colors.background',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
    color: 'theme.colors.text.primary',
  },
  list: {
    flex: 1,
  },
  separator: {
    height: 1,
    backgroundColor: 'theme.colors.border',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default RecentTransactions;