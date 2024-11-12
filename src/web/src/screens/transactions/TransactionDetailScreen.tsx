// HUMAN TASKS:
// 1. Verify proper error handling for network timeouts
// 2. Test screen behavior with different transaction types and states
// 3. Validate accessibility features with screen readers
// 4. Test form validation with various input scenarios

// react version: ^18.0.0
// react-router-dom version: ^6.0.0
// react-native version: ^0.71.0

import React, { useState, useEffect } from 'react';
import { StyleSheet, View } from 'react-native';
import { useParams, useNavigate } from 'react-router-dom';
import { TransactionForm, TransactionFormProps } from '../../components/transactions/TransactionForm';
import { TransactionItem, TransactionItemProps } from '../../components/transactions/TransactionItem';
import { Loading } from '../../components/common/Loading';
import { Error } from '../../components/common/Error';
import {
  getTransactionById,
  updateTransaction,
  deleteTransaction
} from '../../services/api/transactions';

// Requirement: Financial Tracking - Enable detailed transaction viewing and management
const TransactionDetailScreen: React.FC = () => {
  const { transactionId } = useParams<{ transactionId: string }>();
  const navigate = useNavigate();

  const [transaction, setTransaction] = useState<TransactionItemProps['transaction'] | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [isEditing, setIsEditing] = useState(false);

  // Requirement: Transaction Management - Fetch transaction details
  useEffect(() => {
    const fetchTransactionDetails = async () => {
      try {
        if (!transactionId) {
          throw new Error('Transaction ID is required');
        }

        setIsLoading(true);
        const response = await getTransactionById(transactionId);
        setTransaction(response.data);
        setError(null);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Failed to load transaction details');
      } finally {
        setIsLoading(false);
      }
    };

    fetchTransactionDetails();
  }, [transactionId]);

  // Requirement: Transaction Management - Handle transaction updates
  const handleUpdateTransaction = async (updatedData: Partial<TransactionItemProps['transaction']>) => {
    try {
      if (!transaction?.id) {
        throw new Error('Transaction ID is missing');
      }

      setIsLoading(true);
      const response = await updateTransaction(transaction.id, {
        categoryId: updatedData.categoryId,
        description: updatedData.description
      });

      setTransaction(response.data);
      setIsEditing(false);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update transaction');
    } finally {
      setIsLoading(false);
    }
  };

  // Requirement: Transaction Management - Handle transaction deletion
  const handleDeleteTransaction = async () => {
    try {
      if (!transaction?.id) {
        throw new Error('Transaction ID is missing');
      }

      const confirmed = window.confirm('Are you sure you want to delete this transaction?');
      if (!confirmed) return;

      setIsLoading(true);
      await deleteTransaction(transaction.id);
      navigate('/transactions', { replace: true });
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete transaction');
      setIsLoading(false);
    }
  };

  if (isLoading) {
    return (
      <View style={styles.container}>
        <Loading size="large" message="Loading transaction details..." />
      </View>
    );
  }

  if (error) {
    return (
      <View style={styles.container}>
        <Error
          message={error}
          type="generic"
          onRetry={() => {
            setError(null);
            setIsLoading(true);
          }}
        />
      </View>
    );
  }

  if (!transaction) {
    return (
      <View style={styles.container}>
        <Error
          message="Transaction not found"
          type="notFound"
          onRetry={() => navigate('/transactions')}
        />
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <h1>Transaction Details</h1>
        <View style={styles.actionButtons}>
          {!isEditing && (
            <>
              <button
                onClick={() => setIsEditing(true)}
                aria-label="Edit transaction"
              >
                Edit
              </button>
              <button
                onClick={handleDeleteTransaction}
                aria-label="Delete transaction"
              >
                Delete
              </button>
            </>
          )}
        </View>
      </View>

      {isEditing ? (
        <TransactionForm
          transaction={transaction}
          accountId={transaction.accountId}
          onSuccess={(updatedTransaction) => {
            setTransaction(updatedTransaction);
            setIsEditing(false);
          }}
          onCancel={() => setIsEditing(false)}
        />
      ) : (
        <TransactionItem
          transaction={transaction}
          onClick={() => setIsEditing(true)}
        />
      )}
    </View>
  );
};

// Requirement: Cross-Platform UI Consistency - Define styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#FFFFFF'
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16
  },
  actionButtons: {
    flexDirection: 'row',
    gap: 8,
    marginTop: 16
  }
});

export default TransactionDetailScreen;