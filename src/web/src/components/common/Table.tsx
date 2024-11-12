// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify table responsiveness across different screen sizes
// 2. Test table sorting performance with large datasets
// 3. Validate accessibility features with screen readers
// 4. Test touch interactions on mobile devices
// 5. Verify table styling consistency with design system

import React from 'react';
import {
  StyleSheet,
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  ViewStyle,
} from 'react-native';
import Loading from './Loading';
import EmptyState from './EmptyState';
import { theme } from '../../styles/theme';

interface Column {
  id: string;
  title: string;
  width?: string;
  sortable?: boolean;
  renderCell?: (item: any) => React.ReactElement;
}

interface TableProps {
  columns: Column[];
  data: any[];
  isLoading?: boolean;
  emptyStateMessage?: string;
  onRowPress?: (item: any) => void;
  onSort?: (columnId: string, direction: 'asc' | 'desc') => void;
  containerStyle?: ViewStyle;
}

/**
 * Renders a table header with sort indicators
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
const renderHeader = (
  columns: Column[],
  onSort?: (columnId: string, direction: 'asc' | 'desc') => void
): React.ReactElement => {
  const [sortColumn, setSortColumn] = React.useState<string | null>(null);
  const [sortDirection, setSortDirection] = React.useState<'asc' | 'desc'>('asc');

  const handleSort = (columnId: string) => {
    const newDirection = sortColumn === columnId && sortDirection === 'asc' ? 'desc' : 'asc';
    setSortColumn(columnId);
    setSortDirection(newDirection);
    onSort?.(columnId, newDirection);
  };

  return (
    <View style={styles.header}>
      {columns.map((column) => (
        <TouchableOpacity
          key={column.id}
          style={[
            styles.cell,
            column.width ? { width: column.width } : { flex: 1 },
          ]}
          onPress={() => column.sortable && handleSort(column.id)}
          disabled={!column.sortable}
          accessibilityRole="columnheader"
        >
          <Text style={styles.headerText}>
            {column.title}
            {column.sortable && sortColumn === column.id && (
              <Text> {sortDirection === 'asc' ? '↑' : '↓'}</Text>
            )}
          </Text>
        </TouchableOpacity>
      ))}
    </View>
  );
};

/**
 * Renders a table row with custom cell rendering
 * @requirements Financial Data Display - 1.2 Scope/Financial Tracking
 */
const renderRow = (
  rowData: any,
  columns: Column[],
  onPress?: (item: any) => void
): React.ReactElement => {
  return (
    <TouchableOpacity
      style={styles.row}
      onPress={() => onPress?.(rowData)}
      disabled={!onPress}
      accessibilityRole="row"
    >
      {columns.map((column) => (
        <View
          key={column.id}
          style={[
            styles.cell,
            column.width ? { width: column.width } : { flex: 1 },
          ]}
          accessibilityRole="cell"
        >
          {column.renderCell ? (
            column.renderCell(rowData)
          ) : (
            <Text style={styles.cellText}>{rowData[column.id]}</Text>
          )}
        </View>
      ))}
    </TouchableOpacity>
  );
};

/**
 * Table component for displaying structured data with sorting and responsive layout
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 * @requirements Financial Data Display - 1.2 Scope/Financial Tracking
 */
export const Table: React.FunctionComponent<TableProps> = ({
  columns,
  data,
  isLoading,
  emptyStateMessage = 'No data available',
  onRowPress,
  onSort,
  containerStyle,
}) => {
  if (isLoading) {
    return <Loading size="large" message="Loading data..." />;
  }

  if (!data.length) {
    return (
      <EmptyState
        title="No Data"
        message={emptyStateMessage}
        containerStyle={containerStyle}
      />
    );
  }

  return (
    <View style={[styles.container, containerStyle]}>
      <ScrollView horizontal showsHorizontalScrollIndicator={true}>
        <View>
          {renderHeader(columns, onSort)}
          <ScrollView>
            {data.map((item, index) => (
              <React.Fragment key={index}>
                {renderRow(item, columns, onRowPress)}
              </React.Fragment>
            ))}
          </ScrollView>
        </View>
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    borderRadius: theme.shape.borderRadius.md,
    backgroundColor: theme.colors.background.paper,
    overflow: 'hidden',
  },
  header: {
    flexDirection: 'row',
    backgroundColor: theme.colors.background.secondary,
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
  },
  row: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: theme.colors.border,
    minHeight: 48,
  },
  cell: {
    padding: theme.spacing.sm,
    justifyContent: 'center',
  },
  headerText: {
    fontSize: theme.typography.scale.body2.fontSize,
    fontWeight: theme.typography.fontWeights.medium,
    color: theme.colors.text.secondary,
  },
  cellText: {
    fontSize: theme.typography.scale.body2.fontSize,
    color: theme.colors.text.primary,
  },
});