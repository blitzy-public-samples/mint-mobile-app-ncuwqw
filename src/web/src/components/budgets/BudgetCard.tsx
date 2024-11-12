// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify theme colors match design system specifications
// 2. Test card responsiveness across different screen sizes
// 3. Validate accessibility features with screen readers
// 4. Test touch interactions on mobile devices

import React from 'react';
import { StyleSheet, View, Text, TouchableOpacity } from 'react-native';
import Card from '../common/Card';
import BudgetProgress from './BudgetProgress';
import { theme } from '../../styles/theme';

/**
 * Props interface for the BudgetCard component
 */
interface BudgetCardProps {
  category: string;
  budgetAmount: number;
  spentAmount: number;
  period: string;
  onPress: () => void;
}

/**
 * A reusable card component that displays budget information with progress visualization
 * 
 * @requirement Budget Progress Monitoring - 1.2 Scope/Budget Management/Progress monitoring
 * Implements real-time budget progress visualization
 * 
 * @requirement Category-based Budgeting - 1.2 Scope/Budget Management/Category-based budgeting
 * Displays budget information organized by spending categories
 * 
 * @requirement Budget vs Actual Reporting - 1.2 Scope/Budget Management/Budget vs. actual reporting
 * Shows comparison between budgeted amounts and actual spending
 */
const BudgetCard: React.FC<BudgetCardProps> = ({
  category,
  budgetAmount,
  spentAmount,
  period,
  onPress
}) => {
  // Format currency values for display
  const formatCurrency = (amount: number): string => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(amount);
  };

  return (
    <Card
      elevation={2}
      padding={theme.spacing.md}
      onClick={onPress}
    >
      <View style={styles.container}>
        {/* Header section with category and period */}
        <View style={styles.header}>
          <Text 
            style={styles.categoryText}
            accessibilityRole="header"
          >
            {category}
          </Text>
          <Text 
            style={styles.periodText}
            accessibilityLabel={`Budget period: ${period}`}
          >
            {period}
          </Text>
        </View>

        {/* Amount section showing budget and spent amounts */}
        <View style={styles.amountContainer}>
          <View>
            <Text 
              style={styles.amountText}
              accessibilityLabel={`Budget amount: ${formatCurrency(budgetAmount)}`}
            >
              {formatCurrency(budgetAmount)}
            </Text>
            <Text style={styles.spentText}>Budget</Text>
          </View>
          <View>
            <Text 
              style={[
                styles.amountText,
                spentAmount > budgetAmount && { color: theme.colors.semantic.error }
              ]}
              accessibilityLabel={`Spent amount: ${formatCurrency(spentAmount)}`}
            >
              {formatCurrency(spentAmount)}
            </Text>
            <Text style={styles.spentText}>Spent</Text>
          </View>
        </View>

        {/* Progress visualization */}
        <BudgetProgress
          budgetAmount={budgetAmount}
          spentAmount={spentAmount}
          showChart={true}
        />
      </View>
    </Card>
  );
};

const styles = StyleSheet.create({
  container: {
    width: '100%',
    marginBottom: theme.spacing.md
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: theme.spacing.sm
  },
  categoryText: {
    fontSize: 16,
    fontWeight: 'bold',
    color: theme.colors.text.primary
  },
  periodText: {
    fontSize: 12,
    color: theme.colors.text.secondary
  },
  amountContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: theme.spacing.md
  },
  amountText: {
    fontSize: 14,
    color: theme.colors.text.primary
  },
  spentText: {
    color: theme.colors.text.secondary
  }
});

export default BudgetCard;