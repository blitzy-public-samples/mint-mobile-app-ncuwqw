// react version: ^18.0.0
// react-native version: ^0.71.0
// react-redux version: ^8.0.0

/**
 * HUMAN TASKS:
 * 1. Verify chart performance with large datasets
 * 2. Test real-time budget updates in development environment
 * 3. Validate accessibility features for budget progress visualization
 * 4. Test responsive layout on different screen sizes
 */

import React from 'react';
import { View, StyleSheet, ScrollView } from 'react-native';
import { useSelector } from 'react-redux';
import { Budget } from '../../types';
import { Chart } from '../common/Chart';
import { BudgetProgress } from '../budgets/BudgetProgress';
import { 
  selectAllBudgets, 
  selectBudgetsLoading 
} from '../../store/slices/budgetsSlice';
import { formatCurrency } from '../../utils/formatting';

interface BudgetOverviewProps {
  showChart?: boolean;
  maxCategories?: number;
}

/**
 * A component that provides an overview of all budget categories and their progress
 * on the dashboard.
 * 
 * @requirement Budget Management - 1.2 Scope/Budget Management
 * Implements budget progress monitoring and budget vs. actual reporting visualization
 * 
 * @requirement Real-time Data Flow - 3.3.3 Real-time Data Flows
 * Displays real-time budget updates and progress in the dashboard view
 */
export const BudgetOverview: React.FC<BudgetOverviewProps> = ({
  showChart = true,
  maxCategories = 5
}) => {
  const budgets = useSelector(selectAllBudgets);
  const isLoading = useSelector(selectBudgetsLoading);

  const calculateTotalBudget = (budgets: Budget[]): number => {
    if (!budgets?.length) return 0;
    return budgets.reduce((total, budget) => total + budget.amount, 0);
  };

  const calculateTotalSpent = (budgets: Budget[]): number => {
    if (!budgets?.length) return 0;
    const progress = budgets.reduce((total, budget) => {
      const spent = budget.amount - (budget.amount * (budget.alertThreshold / 100));
      return total + spent;
    }, 0);
    return progress;
  };

  const renderBudgetSummary = () => {
    const totalBudget = calculateTotalBudget(budgets);
    const totalSpent = calculateTotalSpent(budgets);
    const remainingBudget = totalBudget - totalSpent;

    return (
      <View style={styles.summaryContainer}>
        <View style={styles.headerText}>Budget Summary</View>
        <View style={styles.totalText}>
          {formatCurrency(totalBudget, 'USD')}
        </View>
        <View style={styles.subtotalText}>
          Spent: {formatCurrency(totalSpent, 'USD')}
        </View>
        <View style={styles.subtotalText}>
          Remaining: {formatCurrency(remainingBudget, 'USD')}
        </View>
        {showChart && (
          <Chart
            data={[
              { x: 'Spent', y: totalSpent },
              { x: 'Remaining', y: remainingBudget }
            ]}
            type="pie"
            height={200}
            width={300}
            loading={isLoading}
          />
        )}
      </View>
    );
  };

  const renderCategoryBreakdown = () => {
    // Sort budgets by amount and take top categories based on maxCategories
    const topBudgets = [...budgets]
      .sort((a, b) => b.amount - a.amount)
      .slice(0, maxCategories);

    return (
      <View style={styles.categoryContainer}>
        <View style={styles.headerText}>Category Breakdown</View>
        <ScrollView>
          {topBudgets.map((budget) => (
            <BudgetProgress
              key={budget.id}
              budgetId={budget.id}
              showChart={showChart}
              height={150}
              width={300}
            />
          ))}
        </ScrollView>
      </View>
    );
  };

  return (
    <View style={styles.container}>
      {renderBudgetSummary()}
      {renderCategoryBreakdown()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16
  },
  summaryContainer: {
    marginBottom: 16
  },
  categoryContainer: {
    marginTop: 16
  },
  headerText: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 8
  },
  totalText: {
    fontSize: 24,
    fontWeight: 'bold',
    marginVertical: 8
  },
  subtotalText: {
    fontSize: 14,
    color: 'gray',
    marginBottom: 4
  }
});