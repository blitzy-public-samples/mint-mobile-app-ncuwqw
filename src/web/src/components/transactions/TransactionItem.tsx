// react version: ^18.0.0
// @emotion/styled version: ^11.0.0

/**
 * HUMAN TASKS:
 * 1. Verify currency formatting matches the financial institution's display format
 * 2. Test component accessibility with screen readers
 * 3. Validate color contrast ratios for transaction types in both light and dark themes
 */

import React from 'react';
import styled from '@emotion/styled';
import { Transaction, TransactionType, TransactionStatus } from '../../types';
import Card from '../common/Card';
import { formatCurrency, formatDate } from '../../utils/formatting';

// Requirement: Transaction Display - Show transaction details in a consistent and readable format
export interface TransactionItemProps {
  transaction: Transaction;
  onClick?: () => void;
}

// Styled components for transaction details
const TransactionContainer = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 100%;
`;

const TransactionDetails = styled.div`
  display: flex;
  flex-direction: column;
  gap: 4px;
`;

const Description = styled.span`
  font-size: 1rem;
  font-weight: 500;
  color: ${({ theme }) => theme.colors.text.primary};
`;

const DateText = styled.span`
  font-size: 0.875rem;
  color: ${({ theme }) => theme.colors.text.secondary};
`;

const Amount = styled.span<{ type: TransactionType }>`
  font-size: 1.125rem;
  font-weight: 600;
  color: ${({ theme, type }) =>
    type === TransactionType.CREDIT
      ? theme.colors.success
      : theme.colors.error};
`;

const StatusIndicator = styled.div<{ status: TransactionStatus }>`
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 8px;
  background-color: ${({ theme, status }) => {
    switch (status) {
      case TransactionStatus.POSTED:
        return theme.colors.success;
      case TransactionStatus.PENDING:
        return theme.colors.warning;
      case TransactionStatus.CANCELLED:
        return theme.colors.error;
      default:
        return theme.colors.text.secondary;
    }
  }};
`;

const StatusContainer = styled.div`
  display: flex;
  align-items: center;
`;

// Requirement: Financial Tracking - Display individual transaction details with automated categorization and filtering
const TransactionItem: React.FC<TransactionItemProps> = ({ transaction, onClick }) => {
  const {
    amount,
    description,
    date,
    type,
    status
  } = transaction;

  // Format amount with proper currency symbol and decimals
  const formattedAmount = formatCurrency(amount, 'USD');
  
  // Format date in a consistent, readable format
  const formattedDate = formatDate(date, 'MMM dd, yyyy');

  // Add +/- prefix based on transaction type
  const displayAmount = `${type === TransactionType.CREDIT ? '+' : '-'}${formattedAmount}`;

  return (
    <Card
      elevation={1}
      padding={16}
      onClick={onClick}
    >
      <TransactionContainer>
        <TransactionDetails>
          <Description>{description}</Description>
          <StatusContainer>
            <StatusIndicator status={status} />
            <DateText>{formattedDate}</DateText>
          </StatusContainer>
        </TransactionDetails>
        <Amount type={type}>
          {displayAmount}
        </Amount>
      </TransactionContainer>
    </Card>
  );
};

export default TransactionItem;