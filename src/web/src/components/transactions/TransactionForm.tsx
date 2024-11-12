// HUMAN TASKS:
// 1. Verify form accessibility with screen readers
// 2. Test form validation with different locales and currency formats
// 3. Verify proper handling of timezone differences in date selection
// 4. Test form submission under poor network conditions

// React version: ^18.0.0
// React Native version: ^0.71.0
// yup version: ^1.0.0

import React, { useState, useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import * as yup from 'yup';
import Form from '../common/Form';
import { 
  Transaction, 
  TransactionType 
} from '../../types';
import { 
  createTransaction, 
  updateTransaction 
} from '../../services/api/transactions';

// Requirement: Input Validation - Define validation schema for transaction data
const validationSchema = yup.object().shape({
  amount: yup
    .number()
    .required('Amount is required')
    .test('non-zero', 'Amount must be non-zero', value => value !== 0),
  description: yup
    .string()
    .required('Description is required')
    .min(2, 'Description must be at least 2 characters')
    .max(100, 'Description must not exceed 100 characters'),
  categoryId: yup
    .string()
    .required('Category is required')
    .matches(/^[0-9a-fA-F]{24}$/, 'Invalid category ID format'),
  date: yup
    .date()
    .required('Date is required')
    .max(new Date(), 'Date cannot be in the future'),
  type: yup
    .string()
    .oneOf(Object.values(TransactionType), 'Invalid transaction type')
    .required('Transaction type is required')
});

// Requirement: Financial Tracking - Define transaction form props interface
interface TransactionFormProps {
  transaction: Transaction | null;
  accountId: string;
  onSuccess: (transaction: Transaction) => void;
  onCancel: () => void;
}

// Requirement: Financial Tracking - Define form data interface
interface TransactionFormData {
  amount: number;
  description: string;
  categoryId: string;
  date: Date;
  type: TransactionType;
}

// Requirement: Financial Tracking - Implement transaction form component
const TransactionForm: React.FC<TransactionFormProps> = React.memo(({
  transaction,
  accountId,
  onSuccess,
  onCancel
}) => {
  // Initialize loading state for form submission
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Initialize form initial values
  const initialValues: TransactionFormData = {
    amount: transaction?.amount || 0,
    description: transaction?.description || '',
    categoryId: transaction?.categoryId || '',
    date: transaction?.date || new Date(),
    type: transaction?.type || TransactionType.DEBIT
  };

  // Requirement: Input Validation - Handle form submission
  const handleSubmit = async (values: TransactionFormData) => {
    try {
      setIsSubmitting(true);

      // Format the data for API submission
      const transactionData = {
        ...values,
        accountId,
        // Ensure proper number formatting for amount
        amount: Math.abs(values.amount) * (values.type === TransactionType.DEBIT ? -1 : 1)
      };

      let response;
      if (transaction) {
        // Update existing transaction
        response = await updateTransaction(transaction.id, {
          categoryId: values.categoryId,
          description: values.description
        });
      } else {
        // Create new transaction
        response = await createTransaction(transactionData);
      }

      // Call success callback with the response data
      onSuccess(response.data);
    } catch (error) {
      // Log error for monitoring
      console.error('Transaction submission failed:', error);
      throw new Error(error instanceof Error ? error.message : 'Failed to submit transaction');
    } finally {
      setIsSubmitting(false);
    }
  };

  // Requirement: Financial Tracking - Render transaction form
  return (
    <View style={styles.container}>
      <Form
        initialValues={initialValues}
        validationSchema={validationSchema}
        onSubmit={handleSubmit}
        submitButtonText={transaction ? 'Update Transaction' : 'Create Transaction'}
        loading={isSubmitting}
        style={styles.form}
      >
        <View style={styles.fieldContainer}>
          <View style={styles.amountContainer}>
            {/* Amount input with proper numeric formatting */}
            <input
              type="number"
              name="amount"
              placeholder="0.00"
              step="0.01"
              min="0"
              style={styles.amountInput}
              aria-label="Transaction amount"
            />
          </View>

          {/* Transaction type selection */}
          <View style={styles.typeContainer}>
            <select
              name="type"
              defaultValue={initialValues.type}
              aria-label="Transaction type"
            >
              <option value={TransactionType.DEBIT}>Expense</option>
              <option value={TransactionType.CREDIT}>Income</option>
            </select>
          </View>
        </View>

        <View style={styles.fieldContainer}>
          {/* Description input */}
          <input
            type="text"
            name="description"
            placeholder="Transaction description"
            maxLength={100}
            aria-label="Transaction description"
          />
        </View>

        <View style={styles.fieldContainer}>
          {/* Category selection */}
          <select
            name="categoryId"
            defaultValue={initialValues.categoryId}
            aria-label="Transaction category"
          >
            <option value="">Select category</option>
            {/* Categories would be populated from a categories context/prop */}
          </select>
        </View>

        <View style={styles.dateContainer}>
          {/* Date selection with proper localization */}
          <input
            type="date"
            name="date"
            defaultValue={initialValues.date.toISOString().split('T')[0]}
            max={new Date().toISOString().split('T')[0]}
            aria-label="Transaction date"
          />
        </View>
      </Form>

      {/* Cancel button */}
      <View style={styles.cancelButton}>
        <button
          onClick={onCancel}
          disabled={isSubmitting}
          aria-label="Cancel transaction"
        >
          Cancel
        </button>
      </View>
    </View>
  );
});

// Requirement: Cross-Platform UI Consistency - Define styles
const styles = StyleSheet.create({
  container: {
    width: '100%',
    padding: 16
  },
  form: {
    width: '100%'
  },
  fieldContainer: {
    marginBottom: 16
  },
  amountContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8
  },
  amountInput: {
    textAlign: 'right',
    fontVariant: ['tabular-nums']
  },
  typeContainer: {
    marginLeft: 8
  },
  dateContainer: {
    flexDirection: 'row',
    alignItems: 'center'
  },
  cancelButton: {
    marginTop: 16,
    alignItems: 'center'
  }
});

// Set display name for debugging
TransactionForm.displayName = 'TransactionForm';

export default TransactionForm;