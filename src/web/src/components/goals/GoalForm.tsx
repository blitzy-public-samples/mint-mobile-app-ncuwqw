// HUMAN TASKS:
// 1. Test form accessibility with screen readers
// 2. Verify form validation behavior across different browsers
// 3. Test goal amount input with various currency formats
// 4. Validate account linking functionality with real account data
// 5. Test form submission with slow network conditions

// React version: ^18.0.0
// React Native version: ^0.71.0
// Yup version: ^1.0.0

import React from 'react';
import { StyleSheet, View } from 'react-native';
import * as Yup from 'yup';
import Form from '../common/Form';
import Input from '../common/Input';
import { useForm, FormState } from '../../hooks/useForm';

// Requirement: Goal Management - Define interfaces for goal form
interface GoalFormProps {
  initialGoal: Goal | null;
  onSubmit: (goal: Goal) => Promise<void>;
  loading: boolean;
  accounts: Account[];
}

interface GoalFormValues {
  name: string;
  targetAmount: number;
  currentAmount: number;
  targetDate: Date;
  linkedAccountIds: string[];
  description: string;
}

// Requirement: Data Security - Define validation schema
const validationSchema = Yup.object().shape({
  name: Yup.string()
    .required('Goal name is required')
    .min(3, 'Goal name must be at least 3 characters')
    .max(50, 'Goal name must not exceed 50 characters'),
  targetAmount: Yup.number()
    .required('Target amount is required')
    .positive('Target amount must be positive')
    .max(1000000000, 'Target amount is too large'),
  currentAmount: Yup.number()
    .required('Current amount is required')
    .min(0, 'Current amount cannot be negative')
    .test('max', 'Current amount cannot exceed target amount', 
      function(value) {
        return value <= this.parent.targetAmount;
      }),
  targetDate: Yup.date()
    .required('Target date is required')
    .min(new Date(), 'Target date must be in the future'),
  linkedAccountIds: Yup.array()
    .of(Yup.string())
    .min(1, 'At least one account must be linked'),
  description: Yup.string()
    .max(500, 'Description must not exceed 500 characters')
});

// Requirement: Cross-Platform UI Consistency - Create goal form component
const GoalForm: React.FC<GoalFormProps> = React.memo(({ 
  initialGoal, 
  onSubmit, 
  loading, 
  accounts 
}) => {
  // Initialize form with default values or existing goal data
  const initialValues: GoalFormValues = {
    name: initialGoal?.name || '',
    targetAmount: initialGoal?.targetAmount || 0,
    currentAmount: initialGoal?.currentAmount || 0,
    targetDate: initialGoal?.targetDate || new Date(),
    linkedAccountIds: initialGoal?.linkedAccountIds || [],
    description: initialGoal?.description || ''
  };

  // Requirement: Goal Management - Handle form submission
  const handleSubmit = async (values: GoalFormValues) => {
    const transformedGoal: Goal = {
      id: initialGoal?.id || undefined,
      name: values.name.trim(),
      targetAmount: Number(values.targetAmount),
      currentAmount: Number(values.currentAmount),
      targetDate: new Date(values.targetDate),
      linkedAccountIds: values.linkedAccountIds,
      description: values.description.trim(),
      progress: (Number(values.currentAmount) / Number(values.targetAmount)) * 100,
      createdAt: initialGoal?.createdAt || new Date(),
      updatedAt: new Date()
    };

    await onSubmit(transformedGoal);
  };

  // Requirement: Cross-Platform UI Consistency - Render form with validation
  return (
    <View style={styles.container}>
      <Form
        initialValues={initialValues}
        validationSchema={validationSchema}
        onSubmit={handleSubmit}
        loading={loading}
      >
        <View style={styles.inputContainer}>
          <Input
            id="goal-name"
            name="name"
            placeholder="Goal Name"
            type="text"
            required
          />
        </View>

        <View style={styles.inputContainer}>
          <Input
            id="target-amount"
            name="targetAmount"
            placeholder="Target Amount"
            type="currency"
            required
          />
        </View>

        <View style={styles.inputContainer}>
          <Input
            id="current-amount"
            name="currentAmount"
            placeholder="Current Amount"
            type="currency"
            required
          />
        </View>

        <View style={styles.datePickerContainer}>
          <Input
            id="target-date"
            name="targetDate"
            placeholder="Target Date"
            type="date"
            required
          />
        </View>

        <View style={styles.accountsContainer}>
          <Input
            id="linked-accounts"
            name="linkedAccountIds"
            placeholder="Select Accounts"
            type="select"
            options={accounts.map(account => ({
              value: account.id,
              label: account.name
            }))}
            multiple
            required
          />
        </View>

        <View style={styles.inputContainer}>
          <Input
            id="description"
            name="description"
            placeholder="Goal Description"
            type="text"
            required={false}
          />
        </View>
      </Form>
    </View>
  );
});

// Requirement: Cross-Platform UI Consistency - Define consistent styles
const styles = StyleSheet.create({
  container: {
    width: '100%',
    padding: 16
  },
  inputContainer: {
    marginBottom: 16
  },
  accountsContainer: {
    marginTop: 16,
    marginBottom: 24
  },
  datePickerContainer: {
    marginBottom: 16
  },
  errorText: {
    color: 'theme.colors.error',
    fontSize: 12,
    marginTop: 4
  }
});

GoalForm.displayName = 'GoalForm';

export default GoalForm;