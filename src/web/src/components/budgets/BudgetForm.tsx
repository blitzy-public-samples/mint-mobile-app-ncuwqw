// HUMAN TASKS:
// 1. Verify form validation messages match design system guidelines
// 2. Test form submission with slow network conditions
// 3. Ensure proper handling of currency formatting across different locales
// 4. Validate accessibility compliance with screen readers

// React version: ^18.0.0
// React Native version: ^0.71.0
// yup version: ^0.32.11

import React from 'react';
import { StyleSheet, View } from 'react-native';
import * as yup from 'yup';
import Form from '../common/Form';
import { useForm, FormState } from '../../hooks/useForm';
import { createBudget, updateBudget } from '../../services/api/budgets';

// Requirement: Budget Management - Define interfaces for budget form
interface BudgetFormProps {
  budget: Budget | null;
  onSubmit: (budget: Budget) => Promise<void>;
  onCancel: () => void;
  loading: boolean;
}

interface BudgetFormValues {
  name: string;
  amount: number;
  categoryId: string;
  period: BudgetPeriod;
  startDate: Date;
  description: string;
}

// Requirement: Input Validation - Define validation schema
const validationSchema = yup.object().shape({
  name: yup
    .string()
    .required('Budget name is required')
    .min(3, 'Name must be at least 3 characters')
    .max(50, 'Name must not exceed 50 characters'),
  amount: yup
    .number()
    .required('Budget amount is required')
    .positive('Amount must be greater than 0')
    .max(1000000, 'Amount must not exceed 1,000,000'),
  categoryId: yup
    .string()
    .required('Category selection is required'),
  period: yup
    .string()
    .oneOf(['MONTHLY', 'QUARTERLY', 'YEARLY'], 'Invalid budget period')
    .required('Budget period is required'),
  startDate: yup
    .date()
    .required('Start date is required')
    .min(new Date(), 'Start date must be in the future'),
  description: yup
    .string()
    .max(200, 'Description must not exceed 200 characters')
});

// Requirement: Cross-Platform UI - Create memo-ized form component
const BudgetForm: React.FC<BudgetFormProps> = React.memo(({
  budget,
  onSubmit,
  onCancel,
  loading
}) => {
  // Initialize form with existing budget data or defaults
  const initialValues: BudgetFormValues = {
    name: budget?.name || '',
    amount: budget?.amount || 0,
    categoryId: budget?.categoryId || '',
    period: budget?.period || 'MONTHLY',
    startDate: budget?.startDate || new Date(),
    description: budget?.description || ''
  };

  // Requirement: Input Validation - Handle form submission
  const handleSubmit = async (values: BudgetFormValues): Promise<void> => {
    try {
      // Transform form values to Budget interface format
      const budgetData = {
        ...values,
        amount: Number(values.amount),
        startDate: new Date(values.startDate),
        updatedAt: new Date()
      };

      // Create new budget or update existing one
      const response = budget
        ? await updateBudget(budget.id, budgetData)
        : await createBudget(budgetData);

      // Call parent submission handler
      await onSubmit(response.data);
    } catch (error) {
      // Handle API errors through form validation
      if (error.errors) {
        const formErrors: Record<string, string> = {};
        error.errors.forEach((err: string) => {
          const [field, message] = err.split(':');
          formErrors[field.trim()] = message.trim();
        });
        throw formErrors;
      }
      throw new Error('Failed to save budget. Please try again.');
    }
  };

  return (
    <View style={styles.container}>
      <Form
        initialValues={initialValues}
        validationSchema={validationSchema}
        onSubmit={handleSubmit}
        submitButtonText={budget ? 'Update Budget' : 'Create Budget'}
        loading={loading}
      >
        <View style={styles.inputContainer}>
          <Input
            name="name"
            label="Budget Name"
            placeholder="Enter budget name"
            testID="budget-name-input"
          />
          
          <Input
            name="amount"
            label="Budget Amount"
            placeholder="0.00"
            keyboardType="decimal-pad"
            testID="budget-amount-input"
          />
          
          <Select
            name="categoryId"
            label="Category"
            placeholder="Select a category"
            testID="budget-category-select"
          />
          
          <Select
            name="period"
            label="Budget Period"
            placeholder="Select period"
            options={[
              { label: 'Monthly', value: 'MONTHLY' },
              { label: 'Quarterly', value: 'QUARTERLY' },
              { label: 'Yearly', value: 'YEARLY' }
            ]}
            testID="budget-period-select"
          />
          
          <DatePicker
            name="startDate"
            label="Start Date"
            minimumDate={new Date()}
            testID="budget-start-date-picker"
          />
          
          <Input
            name="description"
            label="Description"
            placeholder="Enter budget description"
            multiline
            numberOfLines={3}
            testID="budget-description-input"
          />
        </View>

        <View style={styles.buttonContainer}>
          <Button
            variant="secondary"
            onPress={onCancel}
            testID="budget-cancel-button"
          >
            Cancel
          </Button>
        </View>
      </Form>
    </View>
  );
});

// Requirement: Cross-Platform UI - Define consistent styles
const styles = StyleSheet.create({
  container: {
    width: '100%',
    padding: 16
  },
  inputContainer: {
    marginBottom: 16
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 24
  }
});

BudgetForm.displayName = 'BudgetForm';

export default BudgetForm;