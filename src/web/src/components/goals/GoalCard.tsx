// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify goal progress calculations with finance team
// 2. Test card interactions on different screen sizes
// 3. Validate accessibility features with screen readers
// 4. Review color contrast ratios for theme compliance

import React from 'react';
import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import Card from '../common/Card';
import { GoalProgress } from './GoalProgress';
import { theme } from '../../styles/theme';

/**
 * Interface for the GoalCard component props
 * @requirements Goal Management - 1.2 Scope/Goal Management
 */
interface GoalCardProps {
  goal: Account;
  onPress: () => void;
  style?: ViewStyle;
}

/**
 * Formats monetary amounts with proper currency symbol
 * @requirements Goal Management - 1.2 Scope/Goal Management
 */
const formatAmount = (amount: number): string => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
};

/**
 * A React Native component that displays a financial goal in a card format
 * @requirements Goal Management - 1.2 Scope/Goal Management
 * @requirements Goal Progress Monitoring - 1.2 Scope/Goal Management/Progress tracking
 * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
 */
const GoalCard: React.FC<GoalCardProps> = ({ goal, onPress, style }) => {
  const progressPercentage = (goal.currentAmount / goal.targetAmount) * 100;
  const isCompleted = progressPercentage >= 100;

  return (
    <Card
      elevation={2}
      padding={theme.spacing.md}
      borderRadius={theme.shape.borderRadius.md}
      onClick={onPress}
    >
      <View style={[styles.container, style]}>
        {/* Goal Header Section */}
        <View style={styles.header}>
          <Text style={styles.title} numberOfLines={1}>
            {goal.name}
          </Text>
          <Text style={styles.amount}>
            {formatAmount(goal.currentAmount)}
            <Text style={styles.targetAmount}>
              {' '}/ {formatAmount(goal.targetAmount)}
            </Text>
          </Text>
        </View>

        {/* Goal Progress Visualization */}
        <GoalProgress
          goal={goal}
          showChart={false}
          height={8}
          width={undefined}
        />

        {/* Goal Details Section */}
        <View style={styles.details}>
          <Text style={styles.progressText}>
            {isCompleted ? 'Goal Achieved! 🎉' : `${Math.round(progressPercentage)}% Complete`}
          </Text>
          {goal.targetDate && (
            <Text style={styles.targetDate}>
              Target Date: {new Date(goal.targetDate).toLocaleDateString()}
            </Text>
          )}
        </View>

        {/* Status Indicator */}
        <View style={[
          styles.statusIndicator,
          { backgroundColor: isCompleted ? theme.colors.success : theme.colors.primary }
        ]} />
      </View>
    </Card>
  );
};

/**
 * Styles for the GoalCard component
 * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
 */
const styles = StyleSheet.create({
  container: {
    marginVertical: theme.spacing.sm,
    position: 'relative',
    overflow: 'hidden',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.sm,
  },
  title: {
    fontSize: 18,
    fontWeight: theme.typography.fontWeights.bold,
    color: theme.colors.text.primary,
    flex: 1,
    marginRight: theme.spacing.sm,
  },
  amount: {
    fontSize: 16,
    color: theme.colors.text.primary,
    fontWeight: theme.typography.fontWeights.medium,
  },
  targetAmount: {
    color: theme.colors.text.secondary,
    fontSize: 14,
  },
  details: {
    marginTop: theme.spacing.sm,
  },
  progressText: {
    fontSize: 14,
    color: theme.colors.text.secondary,
    fontWeight: theme.typography.fontWeights.medium,
  },
  targetDate: {
    fontSize: 14,
    color: theme.colors.text.secondary,
    marginTop: theme.spacing.xs,
  },
  statusIndicator: {
    position: 'absolute',
    top: 0,
    left: 0,
    width: 4,
    height: '100%',
  },
});

export default GoalCard;