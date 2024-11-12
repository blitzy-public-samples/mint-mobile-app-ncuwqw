// react version: ^18.0.0
// react-native version: ^0.71.0
// react-redux version: ^8.0.0
// @react-navigation/native version: ^6.0.0

// Human Tasks:
// 1. Verify pull-to-refresh functionality on mobile devices
// 2. Test list performance with large datasets
// 3. Validate real-time update behavior
// 4. Test navigation flow to budget details
// 5. Verify empty state rendering conditions

import React, { useEffect, useState, useCallback } from 'react';
import {
  View,
  FlatList,
  StyleSheet,
  RefreshControl,
  ActivityIndicator,
  Text,
} from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';
import { NavigationProp } from '@react-navigation/native';

import { BudgetCard } from '../../components/budgets/BudgetCard';
import { EmptyState } from '../../components/common/EmptyState';
import {
  selectAllBudgets,
  selectBudgetsLoading,
  selectBudgetsError,
  fetchBudgets,
} from '../../store/slices/budgetsSlice';
import { theme } from '../../styles/theme';
import { Budget } from '../../types';

interface BudgetListScreenProps {
  navigation: NavigationProp<any>;
}

/**
 * Screen component that displays a list of user budgets with their progress
 * 
 * @requirement Category-based Budgeting - 1.2 Scope/Budget Management/Category-based budgeting
 * Displays budgets organized by spending categories
 * 
 * @requirement Progress Monitoring - 1.2 Scope/Budget Management/Progress monitoring
 * Shows real-time budget progress and spending patterns
 * 
 * @requirement Budget vs Actual Reporting - 1.2 Scope/Budget Management/Budget vs. actual reporting
 * Presents comparison between budgeted amounts and actual spending
 */
const BudgetsListScreen: React.FC<BudgetListScreenProps> = ({ navigation }) => {
  const dispatch = useDispatch();
  const budgets = useSelector(selectAllBudgets);
  const isLoading = useSelector(selectBudgetsLoading);
  const error = useSelector(selectBudgetsError);
  const [refreshing, setRefreshing] = useState(false);

  // Initial data fetch
  useEffect(() => {
    dispatch(fetchBudgets({}));
  }, [dispatch]);

  // Handle pull-to-refresh
  const handleRefresh = useCallback(async () => {
    setRefreshing(true);
    await dispatch(fetchBudgets({}));
    setRefreshing(false);
  }, [dispatch]);

  // Handle budget item press
  const handleBudgetPress = useCallback((budgetId: string) => {
    navigation.navigate('BudgetDetailScreen', { budgetId });
  }, [navigation]);

  // Render individual budget item
  const renderBudgetItem = useCallback(({ item }: { item: Budget }) => (
    <BudgetCard
      category={item.category}
      budgetAmount={item.amount}
      spentAmount={item.spent}
      period={item.period}
      onPress={() => handleBudgetPress(item.id)}
    />
  ), [handleBudgetPress]);

  // Loading state
  if (isLoading && !refreshing) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={theme.colors.primary} />
      </View>
    );
  }

  // Error state
  if (error) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>
          {error}
        </Text>
      </View>
    );
  }

  // Empty state
  if (!budgets.length) {
    return (
      <EmptyState
        title="No Budgets Found"
        message="Create your first budget to start tracking your expenses"
        actionButtonText="Create Budget"
        onActionButtonPress={() => navigation.navigate('CreateBudgetScreen')}
      />
    );
  }

  // Budget list
  return (
    <View style={styles.container}>
      <FlatList
        data={budgets}
        renderItem={renderBudgetItem}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.listContainer}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            colors={[theme.colors.primary]}
          />
        }
        initialNumToRender={10}
        maxToRenderPerBatch={10}
        windowSize={5}
        removeClippedSubviews={true}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  listContainer: {
    flex: 1,
    padding: 16,
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 16,
  },
  errorText: {
    color: theme.colors.error,
    textAlign: 'center',
    fontSize: 16,
  },
});

export default BudgetsListScreen;