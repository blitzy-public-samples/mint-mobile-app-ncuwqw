// HUMAN TASKS:
// 1. Test form accessibility with screen readers
// 2. Verify form validation behavior across different browsers
// 3. Test form submission with slow network conditions
// 4. Validate form styling matches design system specifications

// React version: ^18.0.0
// React Native version: ^0.71.0

import React, { ReactNode } from 'react';
import { StyleSheet, View, ViewStyle } from 'react-native';
import { useForm, FormState } from '../../hooks/useForm';
import Input from './Input';
import Button from './Button';

// Requirement: Cross-Platform UI Consistency - Define form component props interface
interface FormProps {
  initialValues: Record<string, any>;
  validationSchema: Record<string, (value: any) => string | undefined>;
  onSubmit: (values: Record<string, any>) => Promise<void>;
  children: ReactNode;
  submitButtonText: string;
  loading?: boolean;
  style?: ViewStyle;
}

// Requirement: Cross-Platform UI Consistency - Create reusable form component
const Form: React.FC<FormProps> = React.memo(({
  initialValues,
  validationSchema,
  onSubmit,
  children,
  submitButtonText,
  loading = false,
  style,
}) => {
  // Requirement: Data Security - Initialize form state and validation
  const {
    values,
    errors,
    touched,
    handleChange,
    handleBlur,
    handleSubmit,
    isSubmitting,
    isValid
  } = useForm({
    initialValues,
    validationSchema,
    onSubmit
  });

  // Requirement: Cross-Platform UI Consistency - Clone and enhance form children
  const enhanceFormChildren = (children: ReactNode): ReactNode => {
    return React.Children.map(children, (child) => {
      if (!React.isValidElement(child)) {
        return child;
      }

      if (child.type === Input) {
        const name = child.props.name;
        return React.cloneElement(child, {
          value: values[name] || '',
          error: touched[name] ? errors[name] : undefined,
          onChange: (value: any) => handleChange({ 
            target: { name, value, type: child.props.type } 
          }),
          onBlur: () => handleBlur({ 
            target: { name, value: values[name] } 
          })
        });
      }

      if (child.props.children) {
        return React.cloneElement(child, {
          children: enhanceFormChildren(child.props.children)
        });
      }

      return child;
    });
  };

  // Requirement: Input Validation - Handle form submission with validation
  const handleFormSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    await handleSubmit(e);
  };

  return (
    <View 
      style={[styles.container, style]}
      accessible={true}
      accessibilityRole="form"
    >
      <View style={styles.fieldContainer}>
        {enhanceFormChildren(children)}
      </View>
      
      <View style={styles.submitButton}>
        <Button
          variant="primary"
          onPress={handleFormSubmit}
          loading={loading || isSubmitting}
          disabled={!isValid || loading || isSubmitting}
          testID="form-submit-button"
        >
          {submitButtonText}
        </Button>
      </View>
    </View>
  );
});

// Requirement: Cross-Platform UI Consistency - Define consistent form styles
const styles = StyleSheet.create({
  container: {
    width: '100%',
    padding: 16,
  },
  fieldContainer: {
    marginBottom: 16,
  },
  submitButton: {
    marginTop: 24,
  },
  errorText: {
    color: 'theme.colors.error',
    fontSize: 12,
    marginTop: 4,
  },
});

Form.displayName = 'Form';

export default Form;