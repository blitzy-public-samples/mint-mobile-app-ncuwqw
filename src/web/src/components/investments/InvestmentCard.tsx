// react version: ^18.0.0
// @emotion/styled version: ^11.0.0

// Human Tasks:
// 1. Verify performance color thresholds match design specifications
// 2. Test accessibility of color contrast for performance indicators
// 3. Validate responsive behavior on mobile devices
// 4. Review currency formatting for all supported regions

import React from 'react';
import styled from '@emotion/styled';
import Card from '../common/Card';
import { useTheme } from '../../hooks/useTheme';
import type { Theme } from '../../styles/theme';
import { formatCurrency, formatPercentage } from '../../utils/formatting';

/**
 * Props interface for the InvestmentCard component
 * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
 */
export interface InvestmentCardProps {
  id: string;
  name: string;
  value: number;
  performance: number;
  holdings: number;
  currency: string;
  onClick: () => void;
}

/**
 * Styled container for investment name
 * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
 */
const InvestmentName = styled.h3<{ theme: Theme }>`
  margin: 0;
  color: ${({ theme }) => theme.colors.text.primary};
  font-family: ${({ theme }) => theme.typography.fontFamily};
  font-size: ${({ theme }) => theme.typography.scale.h3.fontSize}px;
  line-height: ${({ theme }) => theme.typography.scale.h3.lineHeight}px;
  font-weight: ${({ theme }) => theme.typography.fontWeights.medium};
`;

/**
 * Styled container for investment value
 * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
 */
const ValueContainer = styled.div<{ theme: Theme }>`
  margin-top: ${({ theme }) => theme.spacing.sm}px;
  color: ${({ theme }) => theme.colors.text.primary};
  font-family: ${({ theme }) => theme.typography.fontFamily};
  font-size: ${({ theme }) => theme.typography.scale.h2.fontSize}px;
  line-height: ${({ theme }) => theme.typography.scale.h2.lineHeight}px;
  font-weight: ${({ theme }) => theme.typography.fontWeights.bold};
`;

/**
 * Styled container for performance metrics
 * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
 */
const PerformanceContainer = styled.div<{ theme: Theme; $isPositive: boolean }>`
  margin-top: ${({ theme }) => theme.spacing.xs}px;
  color: ${({ theme, $isPositive }) =>
    $isPositive ? theme.colors.semantic.success : theme.colors.semantic.error};
  font-family: ${({ theme }) => theme.typography.fontFamily};
  font-size: ${({ theme }) => theme.typography.scale.body2.fontSize}px;
  line-height: ${({ theme }) => theme.typography.scale.body2.lineHeight}px;
  font-weight: ${({ theme }) => theme.typography.fontWeights.medium};
`;

/**
 * Styled container for holdings information
 * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
 */
const HoldingsContainer = styled.div<{ theme: Theme }>`
  margin-top: ${({ theme }) => theme.spacing.md}px;
  color: ${({ theme }) => theme.colors.text.secondary};
  font-family: ${({ theme }) => theme.typography.fontFamily};
  font-size: ${({ theme }) => theme.typography.scale.body2.fontSize}px;
  line-height: ${({ theme }) => theme.typography.scale.body2.lineHeight}px;
`;

/**
 * InvestmentCard component for displaying investment account information
 * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
 * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
 * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
 */
const InvestmentCard: React.FC<InvestmentCardProps> = ({
  id,
  name,
  value,
  performance,
  holdings,
  currency,
  onClick,
}) => {
  const { theme } = useTheme();
  const isPositivePerformance = performance >= 0;

  return (
    <Card
      elevation={1}
      padding={theme.spacing.md}
      onClick={onClick}
      data-testid={`investment-card-${id}`}
    >
      <InvestmentName theme={theme}>{name}</InvestmentName>
      
      <ValueContainer theme={theme}>
        {formatCurrency(value, currency)}
      </ValueContainer>
      
      <PerformanceContainer 
        theme={theme} 
        $isPositive={isPositivePerformance}
      >
        {formatPercentage(performance / 100, 2)}
      </PerformanceContainer>
      
      <HoldingsContainer theme={theme}>
        {holdings} {holdings === 1 ? 'holding' : 'holdings'}
      </HoldingsContainer>
    </Card>
  );
};

export default InvestmentCard;