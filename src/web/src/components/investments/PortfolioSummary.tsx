// react version: ^18.0.0
// @emotion/styled version: ^11.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify performance calculation accuracy with financial team
// 2. Test responsiveness on various screen sizes and orientations
// 3. Validate color contrast ratios for accessibility compliance
// 4. Review loading state animations with UX team

import React from 'react';
import { View, StyleSheet } from 'react-native';
import styled from '@emotion/styled';
import Card from '../common/Card';
import InvestmentChart from './InvestmentChart';
import { formatCurrency, formatPercentage } from '../../utils/formatting';
import { useTheme } from '../../hooks/useTheme';

/**
 * Props interface for the PortfolioSummary component
 * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
 */
export interface PortfolioSummaryProps {
  totalValue: number;
  performance: number;
  allocationData: Array<{ asset: string; percentage: number }>;
  performanceData: Array<{ date: string; value: number }>;
  period: '1D' | '1W' | '1M' | '3M' | '1Y' | 'ALL';
  currency: string;
  loading: boolean;
}

/**
 * Styled components for portfolio summary
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
const StyledContainer = styled(View)<{ theme: any }>`
  flex: 1;
  padding: ${({ theme }) => theme.spacing.md}px;
`;

const StyledHeader = styled(View)<{ theme: any }>`
  flex-direction: row;
  justify-content: space-between;
  align-items: center;
  margin-bottom: ${({ theme }) => theme.spacing.md}px;
`;

const StyledValueContainer = styled(View)<{ theme: any }>`
  margin-bottom: ${({ theme }) => theme.spacing.sm}px;
`;

const StyledTotalValue = styled.Text<{ theme: any }>`
  font-size: ${({ theme }) => theme.typography.sizes.xl}px;
  font-weight: bold;
  color: ${({ theme }) => theme.colors.text.primary};
`;

const StyledPerformance = styled.Text<{ theme: any; isPositive: boolean }>`
  font-size: ${({ theme }) => theme.typography.sizes.md}px;
  color: ${({ theme, isPositive }) =>
    isPositive ? theme.colors.success : theme.colors.error};
`;

const StyledChartContainer = styled(View)<{ theme: any }>`
  margin-top: ${({ theme }) => theme.spacing.md}px;
  height: 200px;
`;

const StyledSectionTitle = styled.Text<{ theme: any }>`
  font-size: ${({ theme }) => theme.typography.sizes.lg}px;
  font-weight: 600;
  color: ${({ theme }) => theme.colors.text.primary};
  margin-bottom: ${({ theme }) => theme.spacing.sm}px;
`;

/**
 * PortfolioSummary component displays investment portfolio information
 * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
 * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
 */
const PortfolioSummary: React.FC<PortfolioSummaryProps> = ({
  totalValue,
  performance,
  allocationData,
  performanceData,
  period,
  currency,
  loading
}) => {
  const { theme } = useTheme();
  const isPositive = performance >= 0;

  /**
   * Transform allocation data for chart visualization
   * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
   */
  const chartAllocationData = React.useMemo(() => {
    return allocationData.map(item => ({
      date: item.asset,
      value: item.percentage
    }));
  }, [allocationData]);

  return (
    <Card elevation={1} padding={theme.spacing.lg}>
      <StyledContainer theme={theme}>
        {/* Portfolio Value and Performance Section */}
        <StyledHeader theme={theme}>
          <StyledValueContainer theme={theme}>
            <StyledTotalValue theme={theme}>
              {formatCurrency(totalValue, currency)}
            </StyledTotalValue>
            <StyledPerformance theme={theme} isPositive={isPositive}>
              {isPositive ? '↑' : '↓'} {formatPercentage(performance, 2)}
            </StyledPerformance>
          </StyledValueContainer>
        </StyledHeader>

        {/* Performance Chart Section */}
        <StyledSectionTitle theme={theme}>Performance</StyledSectionTitle>
        <StyledChartContainer theme={theme}>
          <InvestmentChart
            data={performanceData}
            type="performance"
            period={period}
            loading={loading}
          />
        </StyledChartContainer>

        {/* Asset Allocation Chart Section */}
        <StyledSectionTitle theme={theme}>Asset Allocation</StyledSectionTitle>
        <StyledChartContainer theme={theme}>
          <InvestmentChart
            data={chartAllocationData}
            type="allocation"
            period={period}
            loading={loading}
          />
        </StyledChartContainer>
      </StyledContainer>
    </Card>
  );
};

export default PortfolioSummary;