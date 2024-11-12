/**
 * HUMAN TASKS:
 * 1. Verify email service configuration for password reset notifications
 * 2. Test password reset flow in all supported email clients
 * 3. Validate error message display across different browsers and screen sizes
 */

// react version: ^18.2.0
// react-hook-form version: ^7.0.0
// yup version: ^1.0.0
// @react-navigation/native version: ^6.0.0

import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { useNavigation } from '@react-navigation/native';
import * as yup from 'yup';
import styled from '@emotion/styled';

// Internal imports
import { useAuth } from '../../hooks/useAuth';
import Button from '../../components/common/Button';
import Input from '../../components/common/Input';

// Form validation schema
// Requirement: Security Standards - Implement secure password recovery following OWASP security standards
const forgotPasswordSchema = yup.object().shape({
  email: yup
    .string()
    .required('Email is required')
    .email('Please enter a valid email address')
    .max(255, 'Email must not exceed 255 characters')
});

// Form data interface
interface ForgotPasswordFormData {
  email: string;
}

// Requirement: Multi-platform Authentication - Support cross-platform user authentication for web platform
const ForgotPasswordScreen: React.FC = () => {
  const navigation = useNavigation();
  const { forgotPassword } = useAuth();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState<string>('');
  const [submitSuccess, setSubmitSuccess] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors }
  } = useForm<ForgotPasswordFormData>({
    mode: 'onBlur',
    defaultValues: {
      email: ''
    }
  });

  // Requirement: Authentication Flow - Implement secure password reset flow with email verification
  const onSubmit = async (data: ForgotPasswordFormData) => {
    try {
      setIsSubmitting(true);
      setSubmitError('');
      setSubmitSuccess(false);

      await forgotPassword(data.email);
      
      setSubmitSuccess(true);
      setTimeout(() => {
        navigation.navigate('Login' as never);
      }, 3000);
    } catch (error) {
      setSubmitError(
        error instanceof Error 
          ? error.message 
          : 'An error occurred while processing your request. Please try again.'
      );
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Container>
      <Form onSubmit={handleSubmit(onSubmit)}>
        <Title>Reset Password</Title>
        
        <Description>
          Enter your email address and we'll send you instructions to reset your password.
        </Description>

        <InputWrapper>
          <Input
            id="email"
            name="email"
            type="email"
            placeholder="Enter your email address"
            error={errors.email?.message}
            {...register('email')}
            disabled={isSubmitting || submitSuccess}
          />
        </InputWrapper>

        {submitError && (
          <ErrorText role="alert">{submitError}</ErrorText>
        )}

        {submitSuccess && (
          <SuccessText role="alert">
            Password reset instructions have been sent to your email address.
            Redirecting to login...
          </SuccessText>
        )}

        <ButtonWrapper>
          <Button
            variant="primary"
            disabled={isSubmitting || submitSuccess}
            loading={isSubmitting}
            onPress={handleSubmit(onSubmit)}
            testID="submit-button"
          >
            Reset Password
          </Button>
        </ButtonWrapper>

        <BackButton
          variant="text"
          onPress={() => navigation.navigate('Login' as never)}
          disabled={isSubmitting}
          testID="back-button"
        >
          Back to Login
        </BackButton>
      </Form>
    </Container>
  );
};

const Container = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: ${({ theme }) => theme.spacing.lg}px;
  background-color: ${({ theme }) => theme.colors.background};
`;

const Form = styled.form`
  width: 100%;
  max-width: 400px;
  padding: ${({ theme }) => theme.spacing.xl}px;
  background-color: ${({ theme }) => theme.colors.surface};
  border-radius: ${({ theme }) => theme.shape.borderRadius.md}px;
  box-shadow: ${({ theme }) => theme.shadows.medium};
`;

const Title = styled.h1`
  margin: 0 0 ${({ theme }) => theme.spacing.md}px;
  color: ${({ theme }) => theme.colors.text.primary};
  font-size: ${({ theme }) => theme.typography.h4.fontSize}px;
  font-weight: ${({ theme }) => theme.typography.h4.fontWeight};
  text-align: center;
`;

const Description = styled.p`
  margin: 0 0 ${({ theme }) => theme.spacing.lg}px;
  color: ${({ theme }) => theme.colors.text.secondary};
  font-size: ${({ theme }) => theme.typography.body2.fontSize}px;
  line-height: ${({ theme }) => theme.typography.body2.lineHeight}px;
  text-align: center;
`;

const InputWrapper = styled.div`
  margin-bottom: ${({ theme }) => theme.spacing.md}px;
`;

const ButtonWrapper = styled.div`
  margin-top: ${({ theme }) => theme.spacing.lg}px;
`;

const BackButton = styled(Button)`
  margin-top: ${({ theme }) => theme.spacing.md}px;
  width: 100%;
`;

const ErrorText = styled.div`
  color: ${({ theme }) => theme.colors.error};
  font-size: ${({ theme }) => theme.typography.caption.fontSize}px;
  text-align: center;
  margin-top: ${({ theme }) => theme.spacing.sm}px;
`;

const SuccessText = styled.div`
  color: ${({ theme }) => theme.colors.success};
  font-size: ${({ theme }) => theme.typography.caption.fontSize}px;
  text-align: center;
  margin-top: ${({ theme }) => theme.spacing.sm}px;
`;

export default ForgotPasswordScreen;