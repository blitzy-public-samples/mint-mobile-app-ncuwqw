/**
 * HUMAN TASKS:
 * 1. Ensure React ^18.0.0 is installed in package.json
 * 2. Configure ESLint rules for React Hooks
 * 3. Set up unit tests for useForm hook using React Testing Library
 */

import { useState, useCallback, ChangeEvent, FocusEvent, FormEvent } from 'react'; // ^18.0.0
import { validateEmail, validatePassword, validateAmount } from '../utils/validation';
import type { APIError } from '../types';

// Requirement: Account Management - Define form state and configuration interfaces
export interface FormState {
  values: Record<string, any>;
  errors: Record<string, string>;
  touched: Record<string, boolean>;
}

interface FormConfig {
  initialValues: Record<string, any>;
  validationSchema: Record<string, (value: any) => string | undefined>;
  onSubmit: (values: Record<string, any>) => Promise<void>;
}

// Requirement: Data Security - Implement secure form validation and submission handling
export function useForm({
  initialValues,
  validationSchema,
  onSubmit
}: FormConfig) {
  // Initialize form state
  const [values, setValues] = useState<Record<string, any>>(initialValues);
  const [errors, setErrors] = useState<Record<string, string>>({});
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Requirement: Data Security - Validate individual field value
  const validateField = useCallback((name: string, value: any): string | undefined => {
    // Use validation schema if provided for the field
    if (validationSchema[name]) {
      return validationSchema[name](value);
    }

    // Requirement: Account Management - Built-in validation for common fields
    switch (name) {
      case 'email':
        return !validateEmail(value) ? 'Invalid email address' : undefined;
      case 'password':
        const passwordValidation = validatePassword(value);
        return !passwordValidation.isValid ? passwordValidation.error : undefined;
      case 'amount':
        return !validateAmount(Number(value)) ? 'Invalid amount' : undefined;
      default:
        return undefined;
    }
  }, [validationSchema]);

  // Requirement: Account Management - Handle input change events
  const handleChange = useCallback((e: ChangeEvent<HTMLInputElement>) => {
    const { name, value, type } = e.target;
    
    // Handle different input types
    const processedValue = type === 'number' ? 
      (value === '' ? '' : Number(value)) : 
      type === 'checkbox' ? 
        (e.target as HTMLInputElement).checked : 
        value;

    setValues(prev => ({
      ...prev,
      [name]: processedValue
    }));

    // Validate field if already touched
    if (touched[name]) {
      const error = validateField(name, processedValue);
      setErrors(prev => ({
        ...prev,
        [name]: error || ''
      }));
    }
  }, [touched, validateField]);

  // Requirement: Data Security - Handle input blur events for validation
  const handleBlur = useCallback((e: FocusEvent<HTMLInputElement>) => {
    const { name, value } = e.target;

    // Mark field as touched
    setTouched(prev => ({
      ...prev,
      [name]: true
    }));

    // Validate field
    const error = validateField(name, value);
    setErrors(prev => ({
      ...prev,
      [name]: error || ''
    }));
  }, [validateField]);

  // Requirement: Data Security - Validate all form fields
  const validateForm = useCallback((): boolean => {
    const newErrors: Record<string, string> = {};
    let isValid = true;

    // Validate all fields using schema
    Object.keys(values).forEach(fieldName => {
      const error = validateField(fieldName, values[fieldName]);
      if (error) {
        newErrors[fieldName] = error;
        isValid = false;
      }
    });

    setErrors(newErrors);
    return isValid;
  }, [values, validateField]);

  // Requirement: Account Management - Handle form submission
  const handleSubmit = useCallback(async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    
    // Validate all fields before submission
    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);

    try {
      await onSubmit(values);
    } catch (error) {
      // Handle API errors
      const apiError = error as APIError;
      if (apiError.errors) {
        // Map API errors to form fields
        const fieldErrors: Record<string, string> = {};
        apiError.errors.forEach(error => {
          const [field, message] = error.split(':');
          fieldErrors[field.trim()] = message.trim();
        });
        setErrors(fieldErrors);
      }
    } finally {
      setIsSubmitting(false);
    }
  }, [values, validateForm, onSubmit]);

  // Reset form to initial state
  const reset = useCallback(() => {
    setValues(initialValues);
    setErrors({});
    setTouched({});
    setIsSubmitting(false);
  }, [initialValues]);

  // Calculate form validity
  const isValid = Object.keys(errors).length === 0;

  return {
    values,
    errors,
    touched,
    handleChange,
    handleBlur,
    handleSubmit,
    reset,
    isSubmitting,
    isValid
  };
}