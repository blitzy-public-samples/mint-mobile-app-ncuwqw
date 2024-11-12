// react version: ^18.0.0
// react-redux version: ^8.0.0
// react-router-dom version: ^6.0.0
// @emotion/styled version: ^11.0.0

/**
 * HUMAN TASKS:
 * 1. Verify real-time sync integration with backend services
 * 2. Test account unlinking flow with error scenarios
 * 3. Validate accessibility features with screen readers
 * 4. Review responsive layout on different screen sizes
 */

import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import styled from '@emotion/styled';

import AccountCard from '../../components/accounts/AccountCard';
import Loading from '../../components/common/Loading';
import Error from '../../components/common/Error';
import Card from '../../components/common/Card';
import { Account } from '../../types';
import {
  selectAccountById,
  syncAccountData,
  unlinkExistingAccount
} from '../../store/slices/accountsSlice';

// Requirement: Cross-Platform UI - 2.2.1 Client Applications/React Native
const Container = styled.div`
  display: flex;
  flex-direction: column;
  gap: 24px;
  max-width: 800px;
  margin: 0 auto;
  padding: 24px;

  @media (max-width: 768px) {
    padding: 16px;
  }
`;

const ActionButtons = styled.div`
  display: flex;
  gap: 16px;
  margin-top: 16px;
`;

const Button = styled.button<{ variant?: 'primary' | 'danger' }>`
  padding: 12px 24px;
  border-radius: 8px;
  border: none;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s ease;

  background-color: ${({ variant, theme }) =>
    variant === 'danger' ? theme.colors.semantic.error : theme.colors.primary};
  color: ${({ theme }) => theme.colors.white};

  &:hover {
    opacity: 0.9;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
`;

const SyncStatus = styled.div`
  font-size: 14px;
  color: ${({ theme }) => theme.colors.text.secondary};
`;

/**
 * AccountDetailScreen component displays detailed information about a specific financial account
 * Requirements addressed:
 * - Account Management - 1.2 Scope/Account Management
 * - Financial Tracking - 1.2 Scope/Financial Tracking
 * - Cross-Platform UI - 2.2.1 Client Applications/React Native
 */
const AccountDetailScreen: React.FC = () => {
  const { accountId } = useParams<{ accountId: string }>();
  const navigate = useNavigate();
  const dispatch = useDispatch();

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [isSyncing, setIsSyncing] = useState(false);

  // Requirement: Account Management - Display detailed financial account information
  const account = useSelector((state) => selectAccountById(state, accountId!));

  useEffect(() => {
    if (!account) {
      setError('Account not found');
    }
  }, [account]);

  // Requirement: Account Management - Real-time balance updates and sync capabilities
  const handleSync = async () => {
    try {
      setIsSyncing(true);
      setError(null);
      await dispatch(syncAccountData(accountId!)).unwrap();
    } catch (err) {
      setError('Failed to sync account. Please try again.');
    } finally {
      setIsSyncing(false);
    }
  };

  // Requirement: Account Management - Account unlinking functionality
  const handleUnlink = async () => {
    if (!window.confirm('Are you sure you want to unlink this account?')) {
      return;
    }

    try {
      setIsLoading(true);
      setError(null);
      await dispatch(unlinkExistingAccount(accountId!)).unwrap();
      navigate('/accounts');
    } catch (err) {
      setError('Failed to unlink account. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  if (!accountId) {
    return <Error message="Invalid account ID" type="NOT_FOUND" />;
  }

  if (error) {
    return (
      <Error
        message={error}
        type="GENERIC"
        onRetry={() => setError(null)}
        testID="account-detail-error"
      />
    );
  }

  if (!account) {
    return <Loading size="large" message="Loading account details..." />;
  }

  return (
    <Container>
      {/* Requirement: Account Management - Display account summary information */}
      <AccountCard account={account} />

      {/* Requirement: Financial Tracking - Account sync status and management */}
      <Card elevation={1} padding={24}>
        <SyncStatus>
          Last synced: {new Date(account.lastSynced).toLocaleString()}
        </SyncStatus>
        <ActionButtons>
          <Button
            onClick={handleSync}
            disabled={isSyncing}
            data-testid="sync-button"
          >
            {isSyncing ? 'Syncing...' : 'Sync Now'}
          </Button>
          <Button
            variant="danger"
            onClick={handleUnlink}
            disabled={isLoading}
            data-testid="unlink-button"
          >
            {isLoading ? 'Unlinking...' : 'Unlink Account'}
          </Button>
        </ActionButtons>
      </Card>

      {/* Loading overlay for sync operations */}
      {isSyncing && (
        <Loading
          size="small"
          message="Syncing account data..."
          testID="sync-loading"
        />
      )}
    </Container>
  );
};

export default AccountDetailScreen;