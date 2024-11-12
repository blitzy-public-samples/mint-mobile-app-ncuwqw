// HUMAN TASKS:
// 1. Verify input component accessibility with screen reader testing
// 2. Test input validation across different browsers
// 3. Validate currency input formatting matches design specifications

import React, { useState, useCallback, ChangeEvent } from 'react'; // ^18.0.0
import styled from '@emotion/styled'; // ^11.0.0
import { validateEmail, validateAmount } from '../../utils/validation';
import { Theme } from '../../styles/theme';

// Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
interface InputProps {
  id: string;
  name: string;
  value: string;
  placeholder: string;
  type: 'text' | 'email' | 'password' | 'number' | 'currency';
  disabled?: boolean;
  required?: boolean;
  error?: string;
  onChange: (value: any) => void;
}

// Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
const StyledInput = styled.input<{ error?: string; theme: Theme }>`
  width: 100%;
  font-family: ${({ theme }) => theme.typography.fontFamily};
  font-size: ${({ theme }) => theme.typography.scale.body1.fontSize}px;
  line-height: ${({ theme }) => theme.typography.scale.body1.lineHeight}px;
  padding: ${({ theme }) => theme.spacing.sm}px ${({ theme }) => theme.spacing.md}px;
  border: 1px solid ${({ theme, error }) => 
    error ? theme.colors.semantic.error : theme.colors.semantic.border};
  border-radius: ${({ theme }) => theme.shape.borderRadius.sm}px;
  color: ${({ theme }) => theme.colors.semantic.text};
  background-color: ${({ theme }) => theme.colors.semantic.background};
  transition: border-color 0.2s ease, box-shadow 0.2s ease;

  &:focus {
    outline: none;
    border-color: ${({ theme }) => theme.colors.semantic.primary};
    box-shadow: 0 0 0 2px ${({ theme }) => `${theme.colors.semantic.primary}33`};
  }

  &:disabled {
    background-color: ${({ theme }) => theme.colors.semantic.disabled};
    cursor: not-allowed;
  }

  &::placeholder {
    color: ${({ theme }) => theme.colors.semantic.placeholder};
  }
`;

// Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
const ErrorText = styled.span<{ theme: Theme }>`
  display: block;
  margin-top: ${({ theme }) => theme.spacing.xs}px;
  color: ${({ theme }) => theme.colors.semantic.error};
  font-size: ${({ theme }) => theme.typography.scale.caption.fontSize}px;
  line-height: ${({ theme }) => theme.typography.scale.caption.lineHeight}px;
`;

// Requirement: Data Security - 2.4 Security Architecture/Input Validation
const Input: React.FC<InputProps> = ({
  id,
  name,
  value,
  placeholder,
  type = 'text',
  disabled = false,
  required = false,
  error,
  onChange,
}) => {
  const [validationError, setValidationError] = useState<string>('');
  const [isTouched, setIsTouched] = useState(false);

  // Requirement: Data Security - 2.4 Security Architecture/Input Validation
  const validateInput = useCallback((value: string, type: string): string => {
    if (!value && required) {
      return 'This field is required';
    }

    if (value) {
      switch (type) {
        case 'email':
          return !validateEmail(value) ? 'Invalid email address' : '';
        case 'currency':
          return !validateAmount(parseFloat(value)) ? 'Invalid amount' : '';
        default:
          return '';
      }
    }

    return '';
  }, [required]);

  // Handle input changes with validation
  const handleChange = useCallback((e: ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    let processedValue = newValue;

    // Format currency input
    if (type === 'currency' && newValue) {
      const numericValue = newValue.replace(/[^0-9.]/g, '');
      const parts = numericValue.split('.');
      if (parts[1]?.length > 2) {
        return; // Prevent more than 2 decimal places
      }
      processedValue = numericValue;
    }

    // Validate and update value
    const validationError = validateInput(processedValue, type);
    setValidationError(validationError);
    onChange(processedValue);
  }, [type, validateInput, onChange]);

  // Handle blur event for validation feedback
  const handleBlur = useCallback(() => {
    setIsTouched(true);
    setValidationError(validateInput(value, type));
  }, [value, type, validateInput]);

  // Requirement: Accessibility - 5.1.7 Platform-Specific Implementation Notes/Web
  const inputProps = {
    id,
    name,
    value,
    onChange: handleChange,
    onBlur: handleBlur,
    placeholder,
    disabled,
    required,
    'aria-required': required,
    'aria-invalid': !!(error || validationError),
    'aria-describedby': (error || validationError) ? `${id}-error` : undefined,
    type: type === 'currency' ? 'text' : type,
    inputMode: type === 'currency' ? 'decimal' : undefined,
    pattern: type === 'currency' ? '[0-9]*\\.?[0-9]*' : undefined,
  };

  const displayError = (error || (isTouched && validationError));

  return (
    <div>
      <StyledInput
        {...inputProps}
        error={displayError}
      />
      {displayError && (
        <ErrorText id={`${id}-error`} role="alert">
          {error || validationError}
        </ErrorText>
      )}
    </div>
  );
};

export default Input;