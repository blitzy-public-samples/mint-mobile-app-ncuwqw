// React version: ^18.0.0
// React Native version: ^0.71.0
// React Redux version: ^8.0.0
// React Router DOM version: ^6.0.0

// HUMAN TASKS:
// 1. Verify loading states and error handling in different network conditions
// 2. Test budget deletion confirmation dialog accessibility
// 3. Validate form submission feedback across different devices
// 4. Review responsive layout on various screen sizes

import React, { useEffect, useState } from 'react';
import { StyleSheet, View, ScrollView } from 'react-native';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import {
  selectSelectedBudget,
  selectBudgetsLoading,
  selectBudgetsError,
  fetchBudgetById,
  updateExistingBudget,
  removeBudget
} from '../../store/slices/budgetsSlice';
import BudgetForm from '../../components/budgets/BudgetForm';
import BudgetProgress from '../../components/budgets/BudgetProgress';
import Loading from '../../components/common/Loading';

// Requirement: Cross-Platform UI - Define component interface
interface BudgetDetailScreenProps {}

// Requirement: Budget Management - Implement budget details screen
const BudgetDetailScreen: React.FC<BudgetDetailScreenProps> = () => {
  // Extract budget ID from URL parameters
  const { budgetId } = useParams<{ budgetId: string }>();
  const navigate = useNavigate();
  const dispatch = useDispatch();

  // Local state for delete confirmation
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<boolean>(false);

  // Select budget data and loading states from Redux store
  const budget = useSelector(selectSelectedBudget);
  const isLoading = useSelector(selectBudgetsLoading);
  const error = useSelector(selectBudgetsError);

  // Requirement: Budget Management - Fetch budget details on mount
  useEffect(() => {
    if (budgetId) {
      dispatch(fetchBudgetById(budgetId));
    }
  }, [budgetId, dispatch]);

  // Requirement: Budget Management - Handle budget updates
  const handleBudgetUpdate = async (updatedBudget: Budget): Promise<void> => {
    try {
      if (!budgetId) return;

      await dispatch(updateExistingBudget({
        budgetId,
        data: updatedBudget
      })).unwrap();

      // Navigate back to budgets list on successful update
      navigate('/budgets');
    } catch (error) {
      console.error('Failed to update budget:', error);
      // Error handling is managed by Redux slice
    }
  };

  // Requirement: Budget Management - Handle budget deletion
  const handleBudgetDelete = async (): Promise<void> => {
    try {
      if (!budgetId) return;

      await dispatch(removeBudget(budgetId)).unwrap();
      
      // Navigate back to budgets list on successful deletion
      navigate('/budgets');
    } catch (error) {
      console.error('Failed to delete budget:', error);
      // Error handling is managed by Redux slice
    }
  };

  // Handle cancel action
  const handleCancel = (): void => {
    navigate('/budgets');
  };

  // Show loading state while fetching budget data
  if (isLoading && !budget) {
    return (
      <View style={styles.container}>
        <Loading 
          size="large"
          message="Loading budget details..."
        />
      </View>
    );
  }

  // Show error state if fetch failed
  if (error && !budget) {
    return (
      <View style={styles.container}>
        <View style={styles.content}>
          <Text>Error loading budget: {error}</Text>
        </View>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.content}>
        {/* Requirement: Budget Management - Display budget progress */}
        <View style={styles.progressSection}>
          <BudgetProgress
            budgetId={budgetId || ''}
            showChart={true}
            height={200}
            width={window.innerWidth - 32} // Responsive width
          />
        </View>

        {/* Requirement: Budget Management - Budget edit form */}
        <View style={styles.header}>
          <BudgetForm
            budget={budget}
            onSubmit={handleBudgetUpdate}
            onCancel={handleCancel}
            loading={isLoading}
          />
        </View>

        {/* Action buttons */}
        <View style={styles.actionButtons}>
          <Button
            variant="danger"
            onPress={() => setShowDeleteConfirm(true)}
            testID="delete-budget-button"
          >
            Delete Budget
          </Button>
        </View>

        {/* Delete confirmation dialog */}
        {showDeleteConfirm && (
          <Dialog
            title="Delete Budget"
            message="Are you sure you want to delete this budget? This action cannot be undone."
            confirmLabel="Delete"
            cancelLabel="Cancel"
            onConfirm={handleBudgetDelete}
            onCancel={() => setShowDeleteConfirm(false)}
            type="danger"
          />
        )}
      </View>
    </ScrollView>
  );
};

// Requirement: Cross-Platform UI - Define consistent styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'white'
  },
  content: {
    padding: 16
  },
  header: {
    marginBottom: 24
  },
  progressSection: {
    marginVertical: 24
  },
  actionButtons: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 16
  }
});

export default BudgetDetailScreen;