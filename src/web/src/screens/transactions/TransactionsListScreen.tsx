/**
 * HUMAN TASKS:
 * 1. Verify pagination performance with large transaction datasets
 * 2. Test search functionality with various input patterns
 * 3. Validate filter combinations for edge cases
 * 4. Ensure accessibility of transaction list with screen readers
 */

// react version: ^18.0.0
import React, { useEffect, useState, useCallback } from 'react';
// react-redux version: ^8.0.0
import { useDispatch, useSelector } from 'react-redux';
// react-router-dom version: ^6.0.0
import { useNavigate } from 'react-router-dom';
// @emotion/styled version: ^11.0.0
import styled from '@emotion/styled';

// Internal imports
import TransactionFilters from '../../components/transactions/TransactionFilters';
import TransactionItem from '../../components/transactions/TransactionItem';
import Loading from '../../components/common/Loading';
import Error from '../../components/common/Error';
import EmptyState from '../../components/common/EmptyState';
import { Transaction, TransactionFilters as ITransactionFilters } from '../../types';
import { fetchTransactions, searchTransactions } from '../../store/slices/transactionsSlice';

// Styled components for layout
const Container = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  padding: 1.5rem;
  max-width: 1200px;
  margin: 0 auto;
  width: 100%;
`;

const TransactionsList = styled.div`
  display: flex;
  flex-direction: column;
  gap: 1rem;
`;

const PaginationContainer = styled.div`
  display: flex;
  justify-content: center;
  gap: 1rem;
  margin-top: 1rem;
`;

const PageButton = styled.button<{ isActive?: boolean }>`
  padding: 0.5rem 1rem;
  border: 1px solid ${({ theme }) => theme.colors.border};
  border-radius: ${({ theme }) => theme.shape.borderRadius.sm}px;
  background-color: ${({ isActive, theme }) => 
    isActive ? theme.colors.primary : theme.colors.background};
  color: ${({ isActive, theme }) => 
    isActive ? theme.colors.white : theme.colors.text};
  cursor: pointer;
  transition: all 0.2s ease;

  &:hover {
    background-color: ${({ theme }) => theme.colors.primary};
    color: ${({ theme }) => theme.colors.white};
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
`;

// Requirement: Transaction List View - Show transaction details in a consistent and readable format
const TransactionsListScreen: React.FC = () => {
  // Redux state and dispatch
  const dispatch = useDispatch();
  const navigate = useNavigate();
  
  // Local state for pagination and filters
  const [currentPage, setCurrentPage] = useState(1);
  const [filters, setFilters] = useState<ITransactionFilters>({
    dateRange: {
      startDate: null,
      endDate: null
    },
    transactionType: null,
    categoryId: null,
    amountRange: {
      min: null,
      max: null
    },
    searchTerm: ''
  });

  // Select transactions state from Redux store
  const {
    items: transactions,
    loading,
    error,
    totalPages
  } = useSelector((state: any) => state.transactions);

  // Requirement: Financial Tracking - Implements transaction search/filtering
  const handleFilterChange = useCallback((newFilters: ITransactionFilters) => {
    setFilters(newFilters);
    setCurrentPage(1); // Reset to first page when filters change
    dispatch(fetchTransactions({
      page: 1,
      ...newFilters
    }));
  }, [dispatch]);

  // Handle pagination
  const handlePageChange = useCallback((page: number) => {
    setCurrentPage(page);
    dispatch(fetchTransactions({
      page,
      ...filters
    }));
  }, [dispatch, filters]);

  // Requirement: Transaction List View - Navigate to transaction details
  const handleTransactionClick = useCallback((transactionId: string) => {
    navigate(`/transactions/${transactionId}`);
  }, [navigate]);

  // Fetch transactions on component mount and filter changes
  useEffect(() => {
    dispatch(fetchTransactions({
      page: currentPage,
      ...filters
    }));
  }, [dispatch, currentPage]);

  // Render loading state
  if (loading) {
    return (
      <Container>
        <Loading 
          size="large"
          message="Loading transactions..."
        />
      </Container>
    );
  }

  // Render error state
  if (error) {
    return (
      <Container>
        <Error
          message="Failed to load transactions"
          type="network"
          onRetry={() => handlePageChange(currentPage)}
        />
      </Container>
    );
  }

  // Render empty state
  if (!transactions || transactions.length === 0) {
    return (
      <Container>
        <TransactionFilters
          onFilterChange={handleFilterChange}
          initialFilters={filters}
        />
        <EmptyState
          title="No Transactions Found"
          message="Try adjusting your filters or add a new transaction"
          actionButtonText="Add Transaction"
          onActionButtonPress={() => navigate('/transactions/new')}
        />
      </Container>
    );
  }

  // Requirement: Transaction List View - Show transaction details with search, filter, and sort
  return (
    <Container>
      <TransactionFilters
        onFilterChange={handleFilterChange}
        initialFilters={filters}
      />
      
      <TransactionsList>
        {transactions.map((transaction: Transaction) => (
          <TransactionItem
            key={transaction.id}
            transaction={transaction}
            onClick={() => handleTransactionClick(transaction.id)}
          />
        ))}
      </TransactionsList>

      <PaginationContainer>
        <PageButton
          onClick={() => handlePageChange(currentPage - 1)}
          disabled={currentPage === 1}
        >
          Previous
        </PageButton>
        
        {Array.from({ length: totalPages }, (_, i) => i + 1).map((page) => (
          <PageButton
            key={page}
            isActive={page === currentPage}
            onClick={() => handlePageChange(page)}
          >
            {page}
          </PageButton>
        ))}
        
        <PageButton
          onClick={() => handlePageChange(currentPage + 1)}
          disabled={currentPage === totalPages}
        >
          Next
        </PageButton>
      </PaginationContainer>
    </Container>
  );
};

export default TransactionsListScreen;