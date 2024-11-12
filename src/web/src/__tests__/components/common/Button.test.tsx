// react version: ^18.0.0
// @testing-library/react-native version: ^11.0.0
// @jest/globals version: ^29.0.0

// Human Tasks:
// 1. Verify color contrast ratios meet WCAG guidelines for all button variants
// 2. Test keyboard navigation and focus states
// 3. Validate touch target sizes on physical devices
// 4. Test with screen readers to ensure proper accessibility announcements

import React from 'react';
import { render, fireEvent, act, cleanup } from '@testing-library/react-native';
import { expect, describe, it, beforeEach, afterEach, jest } from '@jest/globals';
import Button, { ButtonProps } from '../../../components/common/Button';
import { CommonStyles } from '../../../constants/styles';

// Mock the useTheme hook
jest.mock('../../../hooks/useTheme', () => ({
  useTheme: () => ({
    theme: {
      text: {
        inverse: '#FFFFFF',
      },
    },
  }),
}));

describe('Button Component', () => {
  let onPressMock: jest.Mock;

  beforeEach(() => {
    onPressMock = jest.fn();
  });

  afterEach(() => {
    cleanup();
    jest.clearAllMocks();
  });

  /**
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
   */
  it('renders correctly with default props', () => {
    const { getByTestId, getByText } = render(
      <Button testID="test-button" onPress={onPressMock}>
        Test Button
      </Button>
    );

    const button = getByTestId('test-button');
    const buttonText = getByText('Test Button');

    expect(button).toBeTruthy();
    expect(buttonText).toBeTruthy();
    expect(button.props.accessibilityRole).toBe('button');
    expect(button.props.accessibilityState).toEqual({
      disabled: false,
      busy: false,
    });
  });

  /**
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
   */
  it('handles press events correctly', () => {
    const { getByTestId } = render(
      <Button testID="test-button" onPress={onPressMock}>
        Test Button
      </Button>
    );

    const button = getByTestId('test-button');
    fireEvent.press(button);

    expect(onPressMock).toHaveBeenCalledTimes(1);
  });

  /**
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
   */
  it('applies correct styles for each variant', () => {
    const variants: Array<ButtonProps['variant']> = ['primary', 'secondary', 'outline', 'text'];

    variants.forEach((variant) => {
      const { getByTestId } = render(
        <Button testID={`${variant}-button`} variant={variant} onPress={onPressMock}>
          {variant} Button
        </Button>
      );

      const button = getByTestId(`${variant}-button`);
      const buttonStyles = button.props.style({ pressed: false });

      expect(buttonStyles).toMatchObject({
        ...CommonStyles.button,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        minWidth: 80,
      });

      cleanup();
    });
  });

  /**
   * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
   */
  it('applies correct styles for different sizes', () => {
    const sizes: Array<ButtonProps['size']> = ['small', 'medium', 'large'];

    sizes.forEach((size) => {
      const { getByTestId } = render(
        <Button testID={`${size}-button`} size={size} onPress={onPressMock}>
          {size} Button
        </Button>
      );

      const button = getByTestId(`${size}-button`);
      const buttonStyles = button.props.style({ pressed: false });

      if (size === 'small') {
        expect(buttonStyles).toMatchObject({
          height: 32,
          paddingHorizontal: 12,
          minWidth: 64,
        });
      } else if (size === 'large') {
        expect(buttonStyles).toMatchObject({
          height: 48,
          paddingHorizontal: 24,
          minWidth: 96,
        });
      }

      cleanup();
    });
  });

  /**
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
   */
  it('handles disabled state correctly', () => {
    const { getByTestId } = render(
      <Button testID="disabled-button" disabled onPress={onPressMock}>
        Disabled Button
      </Button>
    );

    const button = getByTestId('disabled-button');
    const buttonStyles = button.props.style({ pressed: false });

    expect(button.props.disabled).toBe(true);
    expect(button.props.accessibilityState.disabled).toBe(true);
    expect(buttonStyles).toMatchObject({
      opacity: 0.5, // OPACITY_DISABLED value
    });

    fireEvent.press(button);
    expect(onPressMock).not.toHaveBeenCalled();
  });

  /**
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
   */
  it('shows loading state correctly', () => {
    const { getByTestId, queryByText } = render(
      <Button testID="loading-button" loading onPress={onPressMock}>
        Loading Button
      </Button>
    );

    const button = getByTestId('loading-button');
    const buttonText = queryByText('Loading Button');
    const activityIndicator = button.findByProps({ 
      size: 'small',
      color: '#FFFFFF' // theme.text.inverse for primary variant
    });

    expect(button.props.disabled).toBe(true);
    expect(button.props.accessibilityState).toEqual({
      disabled: true,
      busy: true,
    });
    expect(buttonText).toBeNull();
    expect(activityIndicator).toBeTruthy();
  });

  /**
   * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
   */
  it('applies custom styles correctly', () => {
    const customStyle = {
      marginTop: 20,
      backgroundColor: 'red',
    };

    const { getByTestId } = render(
      <Button testID="custom-style-button" style={customStyle} onPress={onPressMock}>
        Custom Style Button
      </Button>
    );

    const button = getByTestId('custom-style-button');
    const buttonStyles = button.props.style({ pressed: false });

    expect(buttonStyles).toMatchObject(customStyle);
  });

  /**
   * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
   */
  it('handles pressed state correctly', () => {
    const { getByTestId } = render(
      <Button testID="pressed-button" onPress={onPressMock}>
        Pressed Button
      </Button>
    );

    const button = getByTestId('pressed-button');
    const pressedStyles = button.props.style({ pressed: true });

    expect(pressedStyles).toMatchObject({
      opacity: 0.7, // OPACITY_PRESSED value
    });
  });
});