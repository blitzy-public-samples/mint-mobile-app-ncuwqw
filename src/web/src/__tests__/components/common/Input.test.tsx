// HUMAN TASKS:
// 1. Run accessibility tests with actual screen readers (NVDA, VoiceOver)
// 2. Verify input validation behavior across different browsers
// 3. Test with different keyboard layouts for international compatibility

import React from 'react'; // ^18.0.0
import { render, fireEvent, screen } from '@testing-library/react'; // ^13.0.0
import userEvent from '@testing-library/user-event'; // ^14.0.0
import { describe, it, expect, jest } from '@jest/globals'; // ^29.0.0
import Input from '../../../components/common/Input';
import { validateEmail, validateAmount } from '../../../utils/validation';

// Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
describe('Input Component', () => {
  const defaultProps = {
    id: 'test-input',
    name: 'test',
    value: '',
    placeholder: 'Enter value',
    onChange: jest.fn(),
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  // Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
  it('renders correctly with default props', () => {
    render(<Input {...defaultProps} type="text" />);
    const input = screen.getByRole('textbox');
    
    expect(input).toBeInTheDocument();
    expect(input).toHaveAttribute('id', 'test-input');
    expect(input).toHaveAttribute('name', 'test');
    expect(input).toHaveAttribute('placeholder', 'Enter value');
    expect(input).not.toHaveAttribute('aria-invalid');
    expect(input).not.toHaveAttribute('aria-required');
  });

  // Requirement: Data Security - 2.4 Security Architecture/Input Validation
  it('handles text input correctly', async () => {
    const user = userEvent.setup();
    const onChange = jest.fn();
    
    render(<Input {...defaultProps} onChange={onChange} type="text" />);
    const input = screen.getByRole('textbox');
    
    await user.type(input, 'test value');
    expect(onChange).toHaveBeenCalledTimes(10);
    expect(onChange).toHaveBeenLastCalledWith('test value');
  });

  // Requirement: Data Security - 2.4 Security Architecture/Input Validation
  it('validates email input correctly', async () => {
    const user = userEvent.setup();
    const onChange = jest.fn();
    
    render(
      <Input
        {...defaultProps}
        onChange={onChange}
        type="email"
        required
      />
    );
    
    const input = screen.getByRole('textbox');
    
    // Test invalid email
    await user.type(input, 'invalid-email');
    await user.tab(); // Trigger blur event
    
    expect(screen.getByRole('alert')).toHaveTextContent('Invalid email address');
    expect(input).toHaveAttribute('aria-invalid', 'true');
    
    // Test valid email
    await user.clear(input);
    await user.type(input, 'valid@email.com');
    await user.tab();
    
    expect(screen.queryByRole('alert')).not.toBeInTheDocument();
  });

  // Requirement: Data Security - 2.4 Security Architecture/Input Validation
  it('validates amount input correctly', async () => {
    const user = userEvent.setup();
    const onChange = jest.fn();
    
    render(
      <Input
        {...defaultProps}
        onChange={onChange}
        type="currency"
        required
      />
    );
    
    const input = screen.getByRole('textbox');
    
    // Test invalid amount
    await user.type(input, 'abc');
    await user.tab();
    
    expect(onChange).toHaveBeenCalledTimes(0); // Should not call onChange for invalid input
    
    // Test valid amount
    await user.clear(input);
    await user.type(input, '123.45');
    await user.tab();
    
    expect(onChange).toHaveBeenCalledWith('123.45');
    expect(screen.queryByRole('alert')).not.toBeInTheDocument();
  });

  // Requirement: Accessibility - 5.1.7 Platform-Specific Implementation Notes/Web
  it('supports accessibility features', async () => {
    const user = userEvent.setup();
    
    render(
      <Input
        {...defaultProps}
        required
        error="Error message"
        type="text"
      />
    );
    
    const input = screen.getByRole('textbox');
    
    // Test ARIA attributes
    expect(input).toHaveAttribute('aria-required', 'true');
    expect(input).toHaveAttribute('aria-invalid', 'true');
    expect(input).toHaveAttribute('aria-describedby', 'test-input-error');
    
    // Test error message accessibility
    const errorMessage = screen.getByRole('alert');
    expect(errorMessage).toHaveTextContent('Error message');
    expect(errorMessage).toHaveAttribute('id', 'test-input-error');
  });

  // Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
  it('handles disabled state correctly', () => {
    render(
      <Input
        {...defaultProps}
        disabled
        type="text"
      />
    );
    
    const input = screen.getByRole('textbox');
    expect(input).toBeDisabled();
  });

  // Requirement: Data Security - 2.4 Security Architecture/Input Validation
  it('shows required field validation', async () => {
    const user = userEvent.setup();
    
    render(
      <Input
        {...defaultProps}
        required
        type="text"
      />
    );
    
    const input = screen.getByRole('textbox');
    await user.tab(); // Focus and blur to trigger validation
    await user.tab();
    
    expect(screen.getByRole('alert')).toHaveTextContent('This field is required');
  });

  // Requirement: Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
  it('handles focus and blur events correctly', async () => {
    const user = userEvent.setup();
    
    render(
      <Input
        {...defaultProps}
        type="text"
      />
    );
    
    const input = screen.getByRole('textbox');
    
    await user.click(input);
    expect(input).toHaveFocus();
    
    await user.tab();
    expect(input).not.toHaveFocus();
  });

  // Requirement: Data Security - 2.4 Security Architecture/Input Validation
  it('prevents more than 2 decimal places for currency input', async () => {
    const user = userEvent.setup();
    const onChange = jest.fn();
    
    render(
      <Input
        {...defaultProps}
        onChange={onChange}
        type="currency"
      />
    );
    
    const input = screen.getByRole('textbox');
    
    await user.type(input, '123.456');
    expect(onChange).toHaveBeenLastCalledWith('123.45');
  });
});