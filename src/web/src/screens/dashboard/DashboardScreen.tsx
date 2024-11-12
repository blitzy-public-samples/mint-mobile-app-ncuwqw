// react version: ^18.0.0
// react-native version: ^0.71.0
// react-redux version: ^8.0.0
// @react-navigation/native version: ^6.0.0

// Human Tasks:
// 1. Verify real-time update interval (30s) meets performance requirements
// 2. Test pull-to-refresh functionality across different network conditions
// 3. Validate loading states and error handling with product team
// 4. Review responsive layout behavior on various screen sizes

import React, { useEffect, useState } from 'react';
import {
  View,
  ScrollView,
  RefreshControl,
  StyleSheet,
} from 'react-native';
import { useSelector, useDispatch } from 'react-redux';
import { useNavigation } from '@react-navigation/native';

// Internal component imports
import { AccountSummary } from '../../components/dashboard/AccountSummary';
import { BudgetOverview } from '../../components/dashboard/BudgetOverview';
import { GoalsProgress } from '../../components/dashboard/GoalsProgress';
import { RecentTransactions } from '../../components/dashboard/RecentTransactions';
import { Loading } from '../../components/common/Loading';
import { Error } from '../../components/common/Error';

/**
 * Main dashboard screen component that provides a comprehensive overview
 * of the user's financial status
 * @requirements Dashboard UI - 5.1.2 Dashboard Layout
 * @requirements Cross-Platform Compatibility - 2.2.1 Client Applications
 */
const DashboardScreen: React.FC = () => {
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const navigation = useNavigation();
  const dispatch = useDispatch();

  // Initialize real-time data sync
  useEffect(() => {
    const initializeDashboard = async () => {
      try {
        setLoading(true);
        setError(null);
        // Initial data fetch will be handled by child components
        setLoading(false);
      } catch (err) {
        setError('Failed to initialize dashboard. Please try again.');
        setLoading(false);
      }
    };

    initializeDashboard();

    // Set up real-time updates every 30 seconds
    // @requirements Real-time Updates - 2.3 Data Flow Architecture
    const intervalId = setInterval(() => {
      handleRefresh();
    }, 30000);

    return () => clearInterval(intervalId);
  }, []);

  /**
   * Handles pull-to-refresh functionality to update all dashboard data
   * @requirements Real-time Updates - 2.3 Data Flow Architecture
   */
  const handleRefresh = async () => {
    try {
      setRefreshing(true);
      setError(null);
      
      // Trigger parallel updates for all sections
      await Promise.all([
        dispatch({ type: 'accounts/refresh' }),
        dispatch({ type: 'budgets/refresh' }),
        dispatch({ type: 'goals/refresh' }),
        dispatch({ type: 'transactions/refresh' })
      ]);
    } catch (err) {
      setError('Failed to refresh dashboard data. Please try again.');
    } finally {
      setRefreshing(false);
    }
  };

  /**
   * Handles navigation to transaction details screen
   * @param transactionId - ID of the transaction to view
   */
  const handleTransactionPress = (transactionId: string) => {
    navigation.navigate('TransactionDetails', { transactionId });
  };

  if (loading) {
    return (
      <Loading 
        size="large"
        message="Loading your financial dashboard..."
      />
    );
  }

  if (error) {
    return (
      <Error
        message={error}
        type="network"
        onRetry={handleRefresh}
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
            testID="dashboard-refresh-control"
          />
        }
      >
        {/* Account Summary Section */}
        <View style={styles.section}>
          <AccountSummary />
        </View>

        {/* Budget Overview Section */}
        <View style={styles.section}>
          <BudgetOverview
            showChart={true}
            maxCategories={5}
          />
        </View>

        {/* Goals Progress Section */}
        <View style={styles.section}>
          <GoalsProgress />
        </View>

        {/* Recent Transactions Section */}
        <View style={styles.section}>
          <RecentTransactions
            limit={5}
            onTransactionPress={handleTransactionPress}
          />
        </View>
      </ScrollView>
    </View>
  );
};

/**
 * Component styles
 * @requirements Cross-Platform Compatibility - 2.2.1 Client Applications
 */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'theme.colors.background',
  },
  scrollView: {
    flex: 1,
  },
  contentContainer: {
    paddingHorizontal: 16,
    paddingVertical: 20,
  },
  section: {
    marginBottom: 24,
  },
});

export default DashboardScreen;