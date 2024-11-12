// react version: ^18.0.0
// react-native version: ^0.71.0
// react-redux version: ^8.0.5
// @react-navigation/native version: ^6.0.0

// Human Tasks:
// 1. Verify pull-to-refresh behavior on different devices and network conditions
// 2. Test empty state interactions and navigation flows
// 3. Validate loading states with screen readers for accessibility
// 4. Review responsive layout on various screen sizes

import React, { useEffect, useCallback, useState } from 'react';
import { View, FlatList, StyleSheet, RefreshControl } from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { useNavigation } from '@react-navigation/native';

import GoalCard from '../../components/goals/GoalCard';
import Loading from '../../components/common/Loading';
import EmptyState from '../../components/common/EmptyState';
import {
  selectGoals,
  selectGoalsLoading,
  selectGoalsError,
  goalsThunks,
} from '../../store/slices/goalsSlice';
import { theme } from '../../styles/theme';

/**
 * Main screen component for displaying and managing financial goals
 * @requirements Goal Management - 1.2 Scope/Goal Management
 * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
 */
const GoalsListScreen: React.FC = () => {
  const dispatch = useDispatch();
  const navigation = useNavigation();
  const [isRefreshing, setIsRefreshing] = useState(false);

  // Select goals data from Redux store
  const goals = useSelector(selectGoals);
  const isLoading = useSelector(selectGoalsLoading);
  const error = useSelector(selectGoalsError);

  /**
   * Fetch goals data on component mount
   * @requirements Goal Management - 1.2 Scope/Goal Management
   */
  useEffect(() => {
    dispatch(goalsThunks.fetchGoals());
  }, [dispatch]);

  /**
   * Handle pull-to-refresh functionality
   * @requirements Progressive Enhancement - 5.1.7 Platform-Specific Implementation Notes/Web
   */
  const handleRefresh = useCallback(async () => {
    setIsRefreshing(true);
    try {
      await dispatch(goalsThunks.fetchGoals());
    } finally {
      setIsRefreshing(false);
    }
  }, [dispatch]);

  /**
   * Handle navigation to goal details screen
   * @requirements Goal Management - 1.2 Scope/Goal Management
   */
  const handleGoalPress = useCallback((goalId: string) => {
    navigation.navigate('GoalDetails', { goalId });
  }, [navigation]);

  /**
   * Handle navigation to goal creation screen
   * @requirements Goal Management - 1.2 Scope/Goal Management
   */
  const handleCreateGoal = useCallback(() => {
    navigation.navigate('CreateGoal');
  }, [navigation]);

  /**
   * Render separator between goal cards
   * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
   */
  const renderSeparator = useCallback(() => (
    <View style={styles.separator} />
  ), []);

  /**
   * Render individual goal card
   * @requirements Goal Management - 1.2 Scope/Goal Management
   */
  const renderGoalCard = useCallback(({ item }) => (
    <GoalCard
      goal={item}
      onPress={() => handleGoalPress(item.id)}
      style={styles.goalCard}
    />
  ), [handleGoalPress]);

  // Show loading state while fetching initial data
  if (isLoading && !isRefreshing && !goals.length) {
    return (
      <Loading
        size="large"
        message="Loading your financial goals..."
      />
    );
  }

  // Show error state if fetch failed
  if (error && !goals.length) {
    return (
      <EmptyState
        title="Oops! Something went wrong"
        message={error}
        actionButtonText="Try Again"
        onActionButtonPress={() => dispatch(goalsThunks.fetchGoals())}
      />
    );
  }

  // Show empty state if no goals exist
  if (!isLoading && !goals.length) {
    return (
      <EmptyState
        title="No Goals Yet"
        message="Start tracking your financial goals by creating your first goal."
        actionButtonText="Create Goal"
        onActionButtonPress={handleCreateGoal}
      />
    );
  }

  /**
   * Render main goals list
   * @requirements Goal Management - 1.2 Scope/Goal Management
   * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
   */
  return (
    <View style={styles.container}>
      <FlatList
        data={goals}
        renderItem={renderGoalCard}
        ItemSeparatorComponent={renderSeparator}
        contentContainerStyle={styles.list}
        keyExtractor={(item) => item.id}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={handleRefresh}
            colors={[theme.colors.primary]}
            tintColor={theme.colors.primary}
          />
        }
        testID="goals-list"
        accessibilityLabel="List of financial goals"
      />
    </View>
  );
};

/**
 * Styles for the GoalsListScreen component
 * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
 */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  list: {
    flex: 1,
    padding: theme.spacing.md,
  },
  separator: {
    height: theme.spacing.sm,
  },
  goalCard: {
    width: '100%',
  },
});

export default GoalsListScreen;