// react version: ^18.0.0
// react-native version: ^0.71.0
// react-redux version: ^8.0.0

/**
 * HUMAN TASKS:
 * 1. Verify Chart component performance with large datasets
 * 2. Test real-time budget updates in development environment
 * 3. Validate progress bar accessibility features
 * 4. Test responsive layout on different screen sizes
 */

import React from 'react';
import { View, StyleSheet } from 'react-native';
import { useSelector } from 'react-redux';
import { Budget, BudgetPeriod } from '../../types';
import { Chart } from '../common/Chart';
import { 
  selectBudgetProgress, 
  selectBudgetsLoading 
} from '../../store/slices/budgetsSlice';
import { formatCurrency, formatPercentage } from '../../utils/formatting';

interface BudgetProgressProps {
  budgetId: string;
  showChart?: boolean;
  height?: number;
  width?: number;
}

/**
 * A component that displays budget progress including spent amount, remaining amount,
 * and visual progress indicator.
 * 
 * @requirement Budget Management - 1.2 Scope/Budget Management
 * Implements progress monitoring and budget vs. actual reporting visualization
 * 
 * @requirement Real-time Data Flow - 3.3.3 Real-time Data Flows
 * Displays real-time budget progress updates
 */
export const BudgetProgress: React.FC<BudgetProgressProps> = ({
  budgetId,
  showChart = true,
  height = 200,
  width = 300
}) => {
  // Get progress data and loading state from Redux store
  const progress = useSelector(selectBudgetProgress)[budgetId];
  const isLoading = useSelector(selectBudgetsLoading);

  const calculateProgress = (spent: number, total: number): number => {
    // Validate input numbers are positive
    if (spent < 0 || total <= 0) {
      return 0;
    }
    
    // Calculate percentage as (spent / total) * 100
    const percentage = (spent / total) * 100;
    
    // Clamp value between 0 and 100
    return Math.min(Math.max(percentage, 0), 100);
  };

  const renderProgressBar = () => {
    if (!showChart) return null;

    const chartData = progress ? [{
      x: 'Progress',
      y: calculateProgress(progress.spent, progress.spent + progress.remaining)
    }] : [];

    return (
      <View style={styles.progressContainer}>
        <Chart
          data={chartData}
          type="bar"
          height={height}
          width={width}
          loading={isLoading}
        />
      </View>
    );
  };

  const renderProgressStats = () => {
    if (!progress) return null;

    return (
      <View style={styles.statsContainer}>
        <View>
          <View style={styles.statItem}>
            <View style={styles.statLabelContainer}>
              <View style={styles.statDot} />
              <View>
                <View style={styles.statLabel}>
                  <View style={styles.statLabelText}>Spent</View>
                </View>
                <View style={styles.statValue}>
                  {formatCurrency(progress.spent, 'USD')}
                </View>
              </View>
            </View>
          </View>
          <View style={styles.statItem}>
            <View style={styles.statLabelContainer}>
              <View style={styles.statDot} />
              <View>
                <View style={styles.statLabel}>
                  <View style={styles.statLabelText}>Remaining</View>
                </View>
                <View style={styles.statValue}>
                  {formatCurrency(progress.remaining, 'USD')}
                </View>
              </View>
            </View>
          </View>
        </View>
        <View style={styles.percentageContainer}>
          <View style={styles.percentageLabel}>Progress</View>
          <View style={styles.percentageValue}>
            {formatPercentage(progress.percentage / 100, 1)}
          </View>
        </View>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {renderProgressBar()}
      {renderProgressStats()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16
  },
  progressContainer: {
    marginVertical: 8
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 8
  },
  statItem: {
    marginBottom: 12
  },
  statLabelContainer: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  statDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#007AFF',
    marginRight: 8
  },
  statLabel: {
    marginBottom: 4
  },
  statLabelText: {
    fontSize: 12,
    color: 'gray'
  },
  statValue: {
    fontSize: 16,
    fontWeight: 'bold'
  },
  percentageContainer: {
    alignItems: 'flex-end'
  },
  percentageLabel: {
    fontSize: 12,
    color: 'gray',
    marginBottom: 4
  },
  percentageValue: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#007AFF'
  }
});