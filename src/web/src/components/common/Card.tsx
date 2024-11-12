// react version: ^18.0.0
// @emotion/styled version: ^11.0.0

// Human Tasks:
// 1. Verify card elevation shadows match design system specifications
// 2. Test card interactions across different browsers and devices
// 3. Validate card accessibility with screen readers
// 4. Review responsive behavior on different screen sizes

import React from 'react';
import styled from '@emotion/styled';
import { useTheme } from '../../hooks/useTheme';
import type { Theme } from '../../styles/theme';

/**
 * Props interface for the Card component
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export interface CardProps {
  children: React.ReactNode;
  elevation?: number;
  padding?: string | number;
  borderRadius?: string | number;
  onClick?: () => void;
  className?: string;
}

/**
 * Styled container component with theme-aware styling
 * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const StyledCard = styled.div<{
  theme: Theme;
  $elevation: number;
  $padding: string | number;
  $borderRadius: string | number;
  $isClickable: boolean;
}>`
  background-color: ${({ theme }) => theme.colors.background};
  border-radius: ${({ theme, $borderRadius }) =>
    typeof $borderRadius === 'number'
      ? `${$borderRadius}px`
      : $borderRadius || `${theme.shape.borderRadius.md}px`};
  padding: ${({ theme, $padding }) =>
    typeof $padding === 'number'
      ? `${$padding}px`
      : $padding || theme.spacing.md}px;
  box-shadow: ${({ theme, $elevation }) => {
    switch ($elevation) {
      case 0:
        return 'none';
      case 2:
        return theme.shape.shadow.md;
      case 3:
        return theme.shape.shadow.lg;
      case 1:
      default:
        return theme.shape.shadow.sm;
    }
  }};
  transition: box-shadow 0.2s ease-in-out, transform 0.2s ease-in-out;
  
  ${({ $isClickable }) =>
    $isClickable &&
    `
    cursor: pointer;
    &:hover {
      transform: translateY(-2px);
    }
    &:active {
      transform: translateY(0);
    }
  `}

  /* Responsive Design Support */
  @media (max-width: 768px) {
    padding: ${({ theme, $padding }) =>
      typeof $padding === 'number'
        ? `${$padding * 0.75}px`
        : $padding || theme.spacing.sm}px;
  }
`;

/**
 * Card component providing a consistent container with theme-aware styling
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const Card: React.FC<CardProps> = ({
  children,
  elevation = 1,
  padding,
  borderRadius,
  onClick,
  className,
}) => {
  const { theme } = useTheme();

  return (
    <StyledCard
      theme={theme}
      $elevation={elevation}
      $padding={padding}
      $borderRadius={borderRadius}
      $isClickable={!!onClick}
      onClick={onClick}
      className={className}
      role={onClick ? 'button' : 'article'}
      tabIndex={onClick ? 0 : undefined}
    >
      {children}
    </StyledCard>
  );
};

export default Card;