// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Test progress animations on different devices
// 2. Verify goal progress calculations with finance team
// 3. Validate currency formatting across different locales
// 4. Test responsive layout on various screen sizes

import React, { useEffect, useRef } from 'react';
import { View, StyleSheet, Animated } from 'react-native';
import { Chart } from '../common/Chart';
import { theme } from '../../styles/theme';

interface Account {
  currentAmount: number;
  targetAmount: number;
  currency: string;
}

interface GoalProgressProps {
  goal: Account;
  showChart: boolean;
  height?: number;
  width?: number;
}

/**
 * Calculates the progress percentage for a goal
 * @requirements Goal Management - 1.2 Scope/Goal Management
 */
const calculateProgress = (goal: Account): number => {
  const progress = (goal.currentAmount / goal.targetAmount) * 100;
  return Math.min(Math.max(progress, 0), 100);
};

/**
 * Formats monetary amounts with proper currency symbol
 * @requirements Goal Management - 1.2 Scope/Goal Management
 */
const formatAmount = (amount: number, currency: string): string => {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
};

/**
 * A React Native Web component that visualizes financial goal progress
 * @requirements Goal Management - 1.2 Scope/Goal Management
 * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
 */
export const GoalProgress: React.FunctionComponent<GoalProgressProps> = ({
  goal,
  showChart,
  height,
  width,
}) => {
  const progressAnimation = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    Animated.timing(progressAnimation, {
      toValue: calculateProgress(goal),
      duration: 1000,
      useNativeDriver: false,
    }).start();
  }, [goal]);

  /**
   * Renders the animated progress bar
   * @requirements Goal Management - 1.2 Scope/Goal Management
   */
  const renderProgressBar = () => {
    const progressStyle = {
      width: progressAnimation.interpolate({
        inputRange: [0, 100],
        outputRange: ['0%', '100%'],
      }),
    };

    return (
      <View style={styles.progressBar}>
        <Animated.View style={[styles.progressFill, progressStyle]} />
      </View>
    );
  };

  /**
   * Renders the progress chart when showChart is true
   * @requirements Goal Management - 1.2 Scope/Goal Management
   * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
   */
  const renderChart = () => {
    if (!showChart) return null;

    const chartData = [
      { x: 'Progress', y: goal.currentAmount },
      { x: 'Remaining', y: Math.max(goal.targetAmount - goal.currentAmount, 0) },
    ];

    return (
      <Chart
        data={chartData}
        type="pie"
        height={height || 200}
        width={width || 300}
      />
    );
  };

  return (
    <View style={styles.container}>
      {renderChart()}
      {renderProgressBar()}
      <View style={styles.labels}>
        <View>
          <View style={styles.labelContainer}>
            <View style={[styles.dot, { backgroundColor: theme.colors.primary }]} />
            <View style={styles.labelText}>
              {formatAmount(goal.currentAmount, goal.currency)}
            </View>
          </View>
        </View>
        <View>
          <View style={styles.labelContainer}>
            <View style={[styles.dot, { backgroundColor: theme.colors.secondary }]} />
            <View style={styles.labelText}>
              {formatAmount(goal.targetAmount, goal.currency)}
            </View>
          </View>
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: theme.spacing.md,
  },
  progressBar: {
    height: 8,
    borderRadius: 4,
    backgroundColor: theme.colors.background,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: theme.colors.primary,
  },
  labels: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: theme.spacing.sm,
  },
  labelContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: theme.spacing.xs,
  },
  labelText: {
    color: theme.colors.text,
    fontSize: theme.typography.scale.body2.fontSize,
  },
});