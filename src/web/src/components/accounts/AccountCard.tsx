// react version: ^18.0.0
// @emotion/styled version: ^11.0.0

/**
 * HUMAN TASKS:
 * 1. Verify account type icons match design system specifications
 * 2. Test real-time balance updates with backend integration
 * 3. Validate accessibility features with screen readers
 * 4. Review responsive behavior on mobile devices
 */

import React from 'react';
import styled from '@emotion/styled';
import Card from '../common/Card';
import { Account, AccountType } from '../../types';
import { formatCurrency, formatDate } from '../../utils/formatting';

// Requirement: UI Design Standards - 5.1.2 Dashboard Layout
export interface AccountCardProps {
  account: Account;
  onClick?: () => void;
}

// Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
const AccountContainer = styled.div`
  display: flex;
  flex-direction: column;
  gap: 12px;
`;

const AccountHeader = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
`;

const AccountInfo = styled.div`
  display: flex;
  flex-direction: column;
  gap: 4px;
`;

const AccountName = styled.h3`
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  color: ${({ theme }) => theme.colors.text.primary};
`;

const AccountType = styled.span`
  font-size: 14px;
  color: ${({ theme }) => theme.colors.text.secondary};
`;

const Balance = styled.div`
  font-size: 24px;
  font-weight: 700;
  color: ${({ theme }) => theme.colors.text.primary};
`;

const LastSynced = styled.div`
  font-size: 12px;
  color: ${({ theme }) => theme.colors.text.tertiary};
  margin-top: 8px;
`;

// Requirement: Account Management - 1.2 Scope/Account Management
const getAccountTypeLabel = (type: AccountType): string => {
  const labels = {
    [AccountType.CHECKING]: 'Checking Account',
    [AccountType.SAVINGS]: 'Savings Account',
    [AccountType.CREDIT]: 'Credit Card',
    [AccountType.INVESTMENT]: 'Investment Account'
  };
  return labels[type];
};

/**
 * AccountCard component displays financial account information in a card format
 * Requirements addressed:
 * - Account Management - 1.2 Scope/Account Management
 * - Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * - UI Design Standards - 5.1.2 Dashboard Layout
 */
const AccountCard: React.FC<AccountCardProps> = ({ account, onClick }) => {
  const formattedBalance = formatCurrency(account.balance, account.currency);
  const formattedLastSync = formatDate(account.lastSynced, 'MMM d, yyyy h:mm a');

  return (
    <Card
      elevation={1}
      padding={16}
      onClick={onClick}
      data-testid={`account-card-${account.id}`}
    >
      <AccountContainer>
        <AccountHeader>
          <AccountInfo>
            <AccountName>{account.name}</AccountName>
            <AccountType>{getAccountTypeLabel(account.type)}</AccountType>
          </AccountInfo>
          <Balance>{formattedBalance}</Balance>
        </AccountHeader>
        <LastSynced>Last updated: {formattedLastSync}</LastSynced>
      </AccountContainer>
    </Card>
  );
};

export default AccountCard;