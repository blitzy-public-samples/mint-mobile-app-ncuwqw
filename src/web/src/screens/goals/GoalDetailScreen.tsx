// react version: ^18.0.0
// react-native version: ^0.71.0
// react-redux version: ^8.0.5
// @react-navigation/native version: ^6.0.0

// Human Tasks:
// 1. Test goal deletion flow with backend team
// 2. Verify account linking functionality with financial services
// 3. Review accessibility features for goal management actions
// 4. Test real-time progress updates across different network conditions

import React, { useEffect, useState } from 'react';
import { View, ScrollView, StyleSheet, Alert } from 'react-native';
import { useDispatch, useSelector } from 'react-redux';
import { useRoute, useNavigation } from '@react-navigation/native';
import GoalCard from '../../components/goals/GoalCard';
import { GoalProgress } from '../../components/goals/GoalProgress';
import {
  selectSelectedGoal,
  selectGoalsLoading,
  selectGoalsError,
  goalsThunks,
} from '../../store/slices/goalsSlice';

/**
 * Interface for route parameters
 * @requirements Goal Management - 1.2 Scope/Goal Management
 */
interface RouteParams {
  goalId: string;
}

/**
 * GoalDetailScreen component displays detailed information about a specific financial goal
 * @requirements Goal Management - 1.2 Scope/Goal Management
 * @requirements Goal Progress Monitoring - 1.2 Scope/Goal Management/Progress tracking
 * @requirements Goal-Linked Accounts - 1.2 Scope/Goal Management/Goal-linked accounts
 */
const GoalDetailScreen: React.FC = () => {
  const dispatch = useDispatch();
  const navigation = useNavigation();
  const route = useRoute();
  const { goalId } = route.params as RouteParams;

  const selectedGoal = useSelector(selectSelectedGoal);
  const isLoading = useSelector(selectGoalsLoading);
  const error = useSelector(selectGoalsError);

  useEffect(() => {
    const loadGoalDetails = async () => {
      try {
        await dispatch(goalsThunks.fetchGoalById(goalId)).unwrap();
      } catch (err) {
        Alert.alert('Error', 'Failed to load goal details');
      }
    };

    loadGoalDetails();
  }, [dispatch, goalId]);

  /**
   * Handles updating goal information
   * @requirements Goal Management - 1.2 Scope/Goal Management
   */
  const handleUpdateGoal = async (updatedGoalData: {
    name: string;
    targetAmount: number;
    currentAmount: number;
    targetDate: string;
  }) => {
    try {
      await dispatch(
        goalsThunks.updateExistingGoal({
          goalId,
          goalData: updatedGoalData,
        })
      ).unwrap();
      Alert.alert('Success', 'Goal updated successfully');
      dispatch(goalsThunks.fetchGoalById(goalId));
    } catch (err) {
      Alert.alert('Error', 'Failed to update goal');
    }
  };

  /**
   * Handles goal deletion with confirmation
   * @requirements Goal Management - 1.2 Scope/Goal Management
   */
  const handleDeleteGoal = async () => {
    Alert.alert(
      'Delete Goal',
      'Are you sure you want to delete this goal? This action cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              await dispatch(goalsThunks.removeGoal(goalId)).unwrap();
              navigation.goBack();
            } catch (err) {
              Alert.alert('Error', 'Failed to delete goal');
            }
          },
        },
      ]
    );
  };

  /**
   * Handles linking accounts to the goal
   * @requirements Goal-Linked Accounts - 1.2 Scope/Goal Management/Goal-linked accounts
   */
  const handleLinkAccount = async (accountId: string) => {
    try {
      await dispatch(
        goalsThunks.linkAccount({
          goalId,
          accountId,
        })
      ).unwrap();
      Alert.alert('Success', 'Account linked successfully');
      dispatch(goalsThunks.fetchGoalById(goalId));
    } catch (err) {
      Alert.alert('Error', 'Failed to link account');
    }
  };

  if (isLoading) {
    return <View style={styles.container} />;
  }

  if (error || !selectedGoal) {
    return (
      <View style={styles.container}>
        <ScrollView
          style={styles.content}
          contentContainerStyle={styles.contentContainer}
        >
          <Text style={styles.errorText}>
            {error || 'Goal not found'}
          </Text>
        </ScrollView>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <ScrollView
        style={styles.content}
        contentContainerStyle={styles.contentContainer}
      >
        {/* Goal Card Section */}
        <View style={styles.section}>
          <GoalCard
            goal={selectedGoal}
            onPress={() => {}}
            style={styles.goalCard}
          />
        </View>

        {/* Detailed Progress Section */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Progress Details</Text>
          <GoalProgress
            goal={selectedGoal}
            showChart={true}
            height={200}
            width={undefined}
          />
        </View>

        {/* Goal Management Actions */}
        <View style={styles.actionButtons}>
          <TouchableOpacity
            style={[styles.button, styles.editButton]}
            onPress={() => handleUpdateGoal(selectedGoal)}
          >
            <Text style={styles.buttonText}>Edit Goal</Text>
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.button, styles.deleteButton]}
            onPress={handleDeleteGoal}
          >
            <Text style={styles.buttonText}>Delete Goal</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  content: {
    padding: 16,
  },
  contentContainer: {
    paddingBottom: 32,
  },
  section: {
    marginVertical: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8,
    color: theme.colors.text.primary,
  },
  goalCard: {
    marginBottom: 16,
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 16,
  },
  button: {
    flex: 1,
    padding: 12,
    borderRadius: 8,
    marginHorizontal: 8,
    alignItems: 'center',
  },
  editButton: {
    backgroundColor: theme.colors.primary,
  },
  deleteButton: {
    backgroundColor: theme.colors.error,
  },
  buttonText: {
    color: theme.colors.white,
    fontWeight: '600',
  },
  errorText: {
    color: theme.colors.error,
    textAlign: 'center',
    marginTop: 16,
  },
});

export default GoalDetailScreen;