// react version: ^18.0.0
// react-native version: ^0.71.0
// victory-native version: ^36.6.8

// Human Tasks:
// 1. Verify chart performance with large datasets
// 2. Test chart animations on low-end devices
// 3. Validate chart accessibility features
// 4. Ensure proper chart rendering across different screen sizes
// 5. Test touch interactions on mobile devices

import React from 'react';
import { View, StyleSheet } from 'react-native';
import {
  VictoryLine,
  VictoryBar,
  VictoryPie,
  VictoryChart,
  VictoryAxis,
  VictoryTheme,
  VictoryContainer,
} from 'victory-native';
import { colors, spacing } from '../../styles/theme';
import { Loading } from './Loading';
import useResponsive from '../../hooks/useResponsive';

interface ChartProps {
  data: Array<{ x: number | string; y: number }>;
  type: 'line' | 'bar' | 'pie';
  height?: number;
  width?: number;
  loading?: boolean;
  color?: string;
}

/**
 * A reusable chart component for financial data visualization
 * @requirements Financial Tracking - 1.2 Scope/Financial Tracking
 * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
 * @requirements Budget Management - 1.2 Scope/Budget Management
 */
export const Chart: React.FunctionComponent<ChartProps> = ({
  data,
  type,
  height,
  width,
  loading = false,
  color = colors.primary,
}) => {
  const { currentBreakpoint, width: screenWidth } = useResponsive();

  // Calculate responsive dimensions if not provided
  const chartWidth = width || (currentBreakpoint === 'xs' ? screenWidth - spacing.lg * 2 : 600);
  const chartHeight = height || (currentBreakpoint === 'xs' ? 300 : 400);

  if (loading) {
    return (
      <View style={styles.container}>
        <Loading size="large" color={color} message="Loading chart data..." />
      </View>
    );
  }

  /**
   * Renders the appropriate chart type based on props
   * @requirements Financial Tracking - 1.2 Scope/Financial Tracking
   */
  const renderChart = () => {
    const commonProps = {
      data,
      animate: {
        duration: 500,
        onLoad: { duration: 500 },
      },
      style: {
        data: { fill: color, stroke: color },
      },
    };

    switch (type) {
      case 'line':
        return (
          <VictoryChart
            width={chartWidth}
            height={chartHeight}
            theme={VictoryTheme.material}
            containerComponent={
              <VictoryContainer responsive={true} />
            }
          >
            <VictoryAxis
              dependentAxis
              style={{
                grid: { stroke: colors.border },
                tickLabels: { fill: colors.text },
              }}
            />
            <VictoryAxis
              style={{
                grid: { stroke: colors.border },
                tickLabels: { fill: colors.text },
              }}
            />
            <VictoryLine
              {...commonProps}
              style={{
                data: { stroke: color },
                parent: { border: `1px solid ${colors.border}` },
              }}
            />
          </VictoryChart>
        );

      case 'bar':
        return (
          <VictoryChart
            width={chartWidth}
            height={chartHeight}
            theme={VictoryTheme.material}
            domainPadding={{ x: 20 }}
            containerComponent={
              <VictoryContainer responsive={true} />
            }
          >
            <VictoryAxis
              dependentAxis
              style={{
                grid: { stroke: colors.border },
                tickLabels: { fill: colors.text },
              }}
            />
            <VictoryAxis
              style={{
                grid: { stroke: colors.border },
                tickLabels: { fill: colors.text },
              }}
            />
            <VictoryBar
              {...commonProps}
              barRatio={0.8}
              cornerRadius={{ top: 4 }}
            />
          </VictoryChart>
        );

      case 'pie':
        return (
          <VictoryPie
            {...commonProps}
            width={chartWidth}
            height={chartHeight}
            colorScale={[color, colors.secondary, colors.tertiary]}
            innerRadius={70}
            labelRadius={({ innerRadius }: any) => (innerRadius + 40)}
            style={{
              labels: {
                fill: colors.text,
                fontSize: 14,
              },
            }}
            containerComponent={
              <VictoryContainer responsive={true} />
            }
          />
        );

      default:
        return null;
    }
  };

  return (
    <View style={[styles.container, { padding: spacing.md }]}>
      {renderChart()}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});