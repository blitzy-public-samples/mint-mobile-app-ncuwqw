// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify chart performance with large datasets
// 2. Test responsiveness across different screen sizes
// 3. Validate theme color contrast for accessibility
// 4. Test chart interactions on touch devices
// 5. Verify chart animations performance

import React, { useMemo } from 'react';
import { View, StyleSheet } from 'react-native';
import { Chart } from '../common/Chart';
import { Theme } from '../../styles/theme';
import useResponsive from '../../hooks/useResponsive';

interface InvestmentChartProps {
  data: Array<{ date: string; value: number }>;
  type: 'performance' | 'allocation';
  period: '1D' | '1W' | '1M' | '3M' | '1Y' | 'ALL';
  loading?: boolean;
  style?: ViewStyle;
}

/**
 * A specialized chart component for investment visualization
 * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
 * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
 */
export const InvestmentChart: React.FunctionComponent<InvestmentChartProps> = ({
  data,
  type,
  period,
  loading = false,
  style,
}) => {
  const { currentBreakpoint, width: screenWidth } = useResponsive();

  /**
   * Calculate responsive chart dimensions based on screen size
   * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
   */
  const getChartDimensions = useMemo(() => {
    const baseHeight = currentBreakpoint === 'xs' ? 200 : 300;
    const baseWidth = currentBreakpoint === 'xs' 
      ? screenWidth - (Theme.spacing.md * 2)
      : Math.min(screenWidth * 0.8, 800);

    return {
      height: baseHeight,
      width: baseWidth,
    };
  }, [currentBreakpoint, screenWidth]);

  /**
   * Format investment data for chart visualization
   * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
   */
  const formatPerformanceData = useMemo(() => {
    if (!data?.length) return [];

    const periodFilters = {
      '1D': 1,
      '1W': 7,
      '1M': 30,
      '3M': 90,
      '1Y': 365,
      'ALL': Number.MAX_SAFE_INTEGER,
    };

    const filteredData = data
      .slice(-periodFilters[period])
      .map((item, index, array) => {
        const percentageChange = index > 0
          ? ((item.value - array[0].value) / array[0].value) * 100
          : 0;

        return {
          x: item.date,
          y: type === 'performance' ? percentageChange : item.value,
        };
      });

    return filteredData;
  }, [data, period, type]);

  /**
   * Determine chart type and color based on visualization type
   * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
   */
  const chartConfig = useMemo(() => {
    return {
      type: type === 'performance' ? 'line' : 'pie',
      color: type === 'performance' 
        ? Theme.colors.primary 
        : Theme.colors.secondary,
    };
  }, [type]);

  if (!data?.length) {
    return (
      <View style={[styles.noDataContainer, style]}>
        <Text>No investment data available</Text>
      </View>
    );
  }

  return (
    <View style={[styles.container, style]}>
      <View style={styles.chartContainer}>
        <Chart
          data={formatPerformanceData}
          type={chartConfig.type}
          height={getChartDimensions.height}
          width={getChartDimensions.width}
          loading={loading}
          color={chartConfig.color}
        />
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Theme.spacing.md,
  },
  chartContainer: {
    width: '100%',
    minHeight: 200,
    marginVertical: Theme.spacing.md,
  },
  noDataContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: Theme.spacing.lg,
  },
});