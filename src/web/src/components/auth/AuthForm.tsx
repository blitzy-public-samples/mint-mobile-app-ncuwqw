/**
 * HUMAN TASKS:
 * 1. Verify password strength requirements with security team
 * 2. Test form accessibility with screen readers
 * 3. Validate error messages with UX team
 * 4. Ensure CSRF protection is enabled on the server
 */

// react version: ^18.2.0
// react-hook-form version: ^7.0.0
// yup version: ^1.0.0

import React, { useState, useCallback } from 'react';
import { useForm } from 'react-hook-form';
import * as yup from 'yup';
import { login, register } from '../../hooks/useAuth';
import Button from '../common/Button';
import Input from '../common/Input';

// Requirement: Security Standards - OWASP security standards compliance
const loginSchema = yup.object().shape({
  email: yup
    .string()
    .email('Please enter a valid email address')
    .required('Email is required'),
  password: yup
    .string()
    .min(8, 'Password must be at least 8 characters')
    .matches(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
      'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
    )
    .required('Password is required'),
});

// Requirement: Security Standards - OWASP security standards compliance
const registerSchema = yup.object().shape({
  email: yup
    .string()
    .email('Please enter a valid email address')
    .required('Email is required'),
  password: yup
    .string()
    .min(8, 'Password must be at least 8 characters')
    .matches(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
      'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
    )
    .required('Password is required'),
  name: yup
    .string()
    .required('Name is required')
    .min(2, 'Name must be at least 2 characters')
    .max(50, 'Name must not exceed 50 characters'),
});

interface AuthFormProps {
  mode: 'login' | 'register';
  onSuccess: (user: User) => void;
  onError: (error: Error) => void;
}

interface FormData {
  email: string;
  password: string;
  name?: string;
}

// Requirement: Multi-platform Authentication - Support cross-platform user authentication
const AuthForm: React.FC<AuthFormProps> = ({ mode, onSuccess, onError }) => {
  const [isSubmitting, setIsSubmitting] = useState(false);
  const validationSchema = mode === 'login' ? loginSchema : registerSchema;

  const {
    register: registerField,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<FormData>({
    mode: 'onBlur',
    resolver: yup.resolver(validationSchema),
  });

  // Requirement: Authentication Flow - Implement secure user authentication flow
  const onSubmit = useCallback(async (data: FormData) => {
    setIsSubmitting(true);
    try {
      if (mode === 'login') {
        const user = await login(data.email, data.password);
        onSuccess(user);
      } else {
        const user = await register(data.email, data.password, data.name!);
        onSuccess(user);
      }
      reset();
    } catch (error) {
      onError(error as Error);
    } finally {
      setIsSubmitting(false);
    }
  }, [mode, onSuccess, onError, reset]);

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <Input
        id="email"
        name="email"
        type="email"
        placeholder="Email address"
        {...registerField('email')}
        error={errors.email?.message}
        disabled={isSubmitting}
        required
      />

      <Input
        id="password"
        name="password"
        type="password"
        placeholder="Password"
        {...registerField('password')}
        error={errors.password?.message}
        disabled={isSubmitting}
        required
      />

      {mode === 'register' && (
        <Input
          id="name"
          name="name"
          type="text"
          placeholder="Full name"
          {...registerField('name')}
          error={errors.name?.message}
          disabled={isSubmitting}
          required
        />
      )}

      <Button
        variant="primary"
        size="large"
        disabled={isSubmitting}
        loading={isSubmitting}
        onPress={handleSubmit(onSubmit)}
        testID={`auth-form-submit-${mode}`}
      >
        {mode === 'login' ? 'Sign In' : 'Create Account'}
      </Button>
    </form>
  );
};

export default AuthForm;