// react version: ^18.0.0
// @emotion/styled version: ^11.0.0

// Human Tasks:
// 1. Verify error icon assets are properly loaded and sized
// 2. Test error component accessibility with screen readers
// 3. Validate error messages with localization team
// 4. Test error component responsiveness across different screen sizes

import React from 'react';
import styled from '@emotion/styled';
import { useTheme } from '../../hooks/useTheme';
import { Theme } from '../../styles/theme';

/**
 * Enum defining supported error types
 * @requirements Error Handling - 6.3.3 Security Controls/Error Handling
 */
export enum ErrorType {
  NETWORK = 'network',
  VALIDATION = 'validation',
  SERVER = 'server',
  UNAUTHORIZED = 'unauthorized',
  NOT_FOUND = 'notFound',
  GENERIC = 'generic'
}

/**
 * Props interface for the Error component
 */
interface ErrorProps {
  message?: string;
  type?: ErrorType;
  onRetry?: () => void;
  testID?: string;
}

const Container = styled.div<{ theme: Theme }>`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: ${({ theme }) => theme.spacing.lg}px;
  text-align: center;
  min-height: 200px;
  width: 100%;
  max-width: 400px;
  margin: 0 auto;
`;

const IconContainer = styled.div<{ theme: Theme }>`
  margin-bottom: ${({ theme }) => theme.spacing.md}px;
  color: ${({ theme }) => theme.colors.semantic.error};
  font-size: 48px;
`;

const Message = styled.p<{ theme: Theme }>`
  ${({ theme }) => theme.typography.scale.body1};
  color: ${({ theme }) => theme.colors.text};
  margin-bottom: ${({ theme }) => theme.spacing.md}px;
`;

const RetryButton = styled.button<{ theme: Theme }>`
  ${({ theme }) => theme.typography.scale.body2};
  background-color: ${({ theme }) => theme.colors.primary};
  color: ${({ theme }) => theme.colors.white};
  border: none;
  border-radius: ${({ theme }) => theme.shape.borderRadius.md}px;
  padding: ${({ theme }) => theme.spacing.sm}px ${({ theme }) => theme.spacing.md}px;
  cursor: pointer;
  transition: opacity 0.2s ease;

  &:hover {
    opacity: 0.9;
  }

  &:focus {
    outline: none;
    box-shadow: 0 0 0 2px ${({ theme }) => theme.colors.semantic.focus};
  }
`;

/**
 * Get default error message based on error type
 * @requirements Error Handling - 6.3.3 Security Controls/Error Handling
 */
const getDefaultMessage = (type: ErrorType): string => {
  switch (type) {
    case ErrorType.NETWORK:
      return 'Unable to connect. Please check your internet connection.';
    case ErrorType.VALIDATION:
      return 'Please check your input and try again.';
    case ErrorType.SERVER:
      return 'An unexpected error occurred. Please try again later.';
    case ErrorType.UNAUTHORIZED:
      return 'You are not authorized to perform this action.';
    case ErrorType.NOT_FOUND:
      return 'The requested resource was not found.';
    case ErrorType.GENERIC:
    default:
      return 'Something went wrong. Please try again.';
  }
};

/**
 * Get error icon based on error type
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
const getErrorIcon = (type: ErrorType): string => {
  switch (type) {
    case ErrorType.NETWORK:
      return '🌐';
    case ErrorType.VALIDATION:
      return '⚠️';
    case ErrorType.SERVER:
      return '🔧';
    case ErrorType.UNAUTHORIZED:
      return '🔒';
    case ErrorType.NOT_FOUND:
      return '🔍';
    case ErrorType.GENERIC:
    default:
      return '❌';
  }
};

/**
 * Error component for displaying error states with optional retry functionality
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Error Handling - 6.3.3 Security Controls/Error Handling
 */
export const Error: React.FC<ErrorProps> = ({
  message,
  type = ErrorType.GENERIC,
  onRetry,
  testID
}) => {
  const { theme } = useTheme();
  const displayMessage = message || getDefaultMessage(type);
  const icon = getErrorIcon(type);

  return (
    <Container theme={theme} data-testid={testID}>
      <IconContainer theme={theme} role="img" aria-label={`${type} error icon`}>
        {icon}
      </IconContainer>
      <Message theme={theme} role="alert">
        {displayMessage}
      </Message>
      {onRetry && (
        <RetryButton
          theme={theme}
          onClick={onRetry}
          aria-label="Retry"
          data-testid={`${testID}-retry-button`}
        >
          Try Again
        </RetryButton>
      )}
    </Container>
  );
};