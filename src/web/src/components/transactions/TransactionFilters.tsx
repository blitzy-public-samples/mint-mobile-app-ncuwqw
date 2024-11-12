/**
 * HUMAN TASKS:
 * 1. Verify date picker localization settings match application requirements
 * 2. Test filter performance with large transaction datasets
 * 3. Validate accessibility of filter controls with screen readers
 */

// React v18.0.0
import React, { useState, useCallback, useEffect } from 'react';
// React Native v0.71.0
import { StyleSheet, View } from 'react-native';
// @react-native-community/datetimepicker v7.0.0
import DatePicker from '@react-native-community/datetimepicker';

// Internal imports
import Input from '../common/Input';
import Button from '../common/Button';
import { Transaction, TransactionType } from '../../types';
import { validateAmount } from '../../utils/validation';

// Requirement: Financial Tracking - Define filter criteria interface
interface TransactionFilters {
  dateRange: {
    startDate: Date | null;
    endDate: Date | null;
  };
  transactionType: TransactionType | null;
  categoryId: string | null;
  amountRange: {
    min: number | null;
    max: number | null;
  };
  searchTerm: string;
}

// Requirement: Transaction Management - Define component props
interface TransactionFiltersProps {
  onFilterChange: (filters: TransactionFilters) => void;
  initialFilters: TransactionFilters;
}

// Requirement: Financial Tracking - Default filter values
const defaultFilters: TransactionFilters = {
  dateRange: {
    startDate: null,
    endDate: null,
  },
  transactionType: null,
  categoryId: null,
  amountRange: {
    min: null,
    max: null,
  },
  searchTerm: '',
};

// Requirement: Transaction Management - Main filter component
const TransactionFilters: React.FC<TransactionFiltersProps> = ({
  onFilterChange,
  initialFilters,
}) => {
  // Initialize state with provided filters or defaults
  const [filters, setFilters] = useState<TransactionFilters>(
    initialFilters || defaultFilters
  );

  // Requirement: Financial Tracking - Handle filter changes
  const handleFilterChange = useCallback(
    (updates: Partial<TransactionFilters>) => {
      const newFilters = {
        ...filters,
        ...updates,
      };

      // Validate amount range if changed
      if (updates.amountRange) {
        const { min, max } = updates.amountRange;
        if (
          (min !== null && !validateAmount(min)) ||
          (max !== null && !validateAmount(max)) ||
          (min !== null && max !== null && min > max)
        ) {
          return; // Invalid amount range
        }
      }

      setFilters(newFilters);
      onFilterChange(newFilters);
    },
    [filters, onFilterChange]
  );

  // Requirement: Transaction Management - Handle date range changes
  const handleDateChange = useCallback(
    (type: 'startDate' | 'endDate', date: Date | null) => {
      handleFilterChange({
        dateRange: {
          ...filters.dateRange,
          [type]: date,
        },
      });
    },
    [filters.dateRange, handleFilterChange]
  );

  // Requirement: Financial Tracking - Reset filters to default
  const resetFilters = useCallback(() => {
    setFilters(defaultFilters);
    onFilterChange(defaultFilters);
  }, [onFilterChange]);

  return (
    <View style={styles.container}>
      {/* Date Range Filters */}
      <View style={styles.dateContainer}>
        <View style={styles.dateInput}>
          <DatePicker
            value={filters.dateRange.startDate || new Date()}
            onChange={(_, date) => handleDateChange('startDate', date || null)}
            mode="date"
            maximumDate={filters.dateRange.endDate || new Date()}
          />
        </View>
        <View style={styles.dateInput}>
          <DatePicker
            value={filters.dateRange.endDate || new Date()}
            onChange={(_, date) => handleDateChange('endDate', date || null)}
            mode="date"
            minimumDate={filters.dateRange.startDate || undefined}
          />
        </View>
      </View>

      {/* Transaction Type Filter */}
      <View style={styles.row}>
        <Input
          id="transaction-type"
          name="transactionType"
          type="text"
          value={filters.transactionType || ''}
          placeholder="Transaction Type"
          onChange={(value) =>
            handleFilterChange({
              transactionType: value ? (value as TransactionType) : null,
            })
          }
        />
      </View>

      {/* Category Filter */}
      <View style={styles.row}>
        <Input
          id="category"
          name="category"
          type="text"
          value={filters.categoryId || ''}
          placeholder="Category"
          onChange={(value) =>
            handleFilterChange({ categoryId: value || null })
          }
        />
      </View>

      {/* Amount Range Filters */}
      <View style={styles.row}>
        <View style={styles.amountInput}>
          <Input
            id="min-amount"
            name="minAmount"
            type="currency"
            value={filters.amountRange.min?.toString() || ''}
            placeholder="Min Amount"
            onChange={(value) =>
              handleFilterChange({
                amountRange: {
                  ...filters.amountRange,
                  min: value ? parseFloat(value) : null,
                },
              })
            }
          />
        </View>
        <View style={styles.amountInput}>
          <Input
            id="max-amount"
            name="maxAmount"
            type="currency"
            value={filters.amountRange.max?.toString() || ''}
            placeholder="Max Amount"
            onChange={(value) =>
              handleFilterChange({
                amountRange: {
                  ...filters.amountRange,
                  max: value ? parseFloat(value) : null,
                },
              })
            }
          />
        </View>
      </View>

      {/* Search Term Filter */}
      <View style={styles.row}>
        <Input
          id="search"
          name="search"
          type="text"
          value={filters.searchTerm}
          placeholder="Search transactions..."
          onChange={(value) => handleFilterChange({ searchTerm: value })}
        />
      </View>

      {/* Filter Actions */}
      <View style={styles.actions}>
        <Button
          onPress={resetFilters}
          variant="secondary"
        >
          Reset Filters
        </Button>
      </View>
    </View>
  );
};

// Requirement: Cross-Platform UI Consistency - Define component styles
const styles = StyleSheet.create({
  container: {
    padding: 16,
    backgroundColor: '#ffffff',
    borderRadius: 8,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  dateContainer: {
    flexDirection: 'row',
    marginBottom: 16,
    justifyContent: 'space-between',
  },
  dateInput: {
    flex: 1,
    marginHorizontal: 4,
  },
  row: {
    marginBottom: 16,
  },
  amountInput: {
    flex: 1,
    marginHorizontal: 4,
  },
  actions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    marginTop: 8,
  },
});

export default TransactionFilters;