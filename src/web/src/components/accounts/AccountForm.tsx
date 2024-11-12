/**
 * HUMAN TASKS:
 * 1. Verify Plaid integration configuration in environment variables
 * 2. Test form accessibility with screen readers
 * 3. Validate form security with penetration testing
 * 4. Ensure proper SSL/TLS configuration for credential transmission
 */

// React version: ^18.0.0
// React Native version: ^0.71.0
// Yup version: ^1.0.0

import React, { useState, useCallback } from 'react';
import { StyleSheet, View } from 'react-native';
import * as yup from 'yup';

import { Account, AccountType, APIResponse } from '../../types';
import Form from '../common/Form';
import Input from '../common/Input';
import { linkAccount, updateAccountSettings } from '../../services/api/accounts';

// Requirement: Account Management - Define interface for form props
interface AccountFormProps {
  account: Account | null;
  onSubmit: (account: Account) => Promise<void>;
  onCancel: () => void;
  loading: boolean;
}

// Requirement: Data Security - Define validation schema for account data
const validationSchema = yup.object().shape({
  name: yup
    .string()
    .required('Account name is required')
    .min(2, 'Account name must be at least 2 characters')
    .max(50, 'Account name must not exceed 50 characters'),
  type: yup
    .string()
    .oneOf(Object.values(AccountType), 'Invalid account type')
    .required('Account type is required'),
  institutionId: yup
    .string()
    .required('Institution ID is required')
    .matches(/^[A-Za-z0-9_-]+$/, 'Invalid institution ID format'),
  credentials: yup.object().when('isNew', {
    is: true,
    then: yup.object().required('Credentials are required for new accounts')
  })
});

// Requirement: Account Management - Create form component for account management
const AccountForm: React.FC<AccountFormProps> = React.memo(({ 
  account, 
  onSubmit, 
  onCancel, 
  loading 
}) => {
  // Track form submission state
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Initialize form with account data or defaults
  const initialValues = {
    name: account?.name || '',
    type: account?.type || AccountType.CHECKING,
    institutionId: account?.institutionId || '',
    credentials: {},
    isNew: !account
  };

  // Requirement: Data Security - Handle form submission with validation
  const handleSubmit = useCallback(async (formData: typeof initialValues) => {
    try {
      setSubmitting(true);
      setError(null);

      // Transform form data for API
      const accountData = {
        ...formData,
        id: account?.id,
        balance: account?.balance || 0
      };

      // Call appropriate API based on whether we're creating or updating
      const response = formData.isNew
        ? await linkAccount({
            institutionId: accountData.institutionId,
            credentials: accountData.credentials,
            accountType: accountData.type as AccountType
          })
        : await updateAccountSettings(account!.id, {
            name: accountData.name,
            isActive: true
          });

      // Handle successful submission
      await onSubmit(response as Account);
    } catch (err) {
      // Handle API errors
      setError(err instanceof Error ? err.message : 'An error occurred');
    } finally {
      setSubmitting(false);
    }
  }, [account, onSubmit]);

  return (
    <View style={styles.container}>
      <Form
        initialValues={initialValues}
        validationSchema={validationSchema}
        onSubmit={handleSubmit}
        submitButtonText={account ? 'Update Account' : 'Add Account'}
        loading={loading || submitting}
      >
        <View style={styles.fieldContainer}>
          <Input
            id="account-name"
            name="name"
            type="text"
            placeholder="Account Name"
            required
          />
        </View>

        <View style={styles.fieldContainer}>
          <Input
            id="account-type"
            name="type"
            type="text"
            placeholder="Account Type"
            required
          />
        </View>

        <View style={styles.fieldContainer}>
          <Input
            id="institution-id"
            name="institutionId"
            type="text"
            placeholder="Institution ID"
            required
          />
        </View>

        {!account && (
          <View style={styles.fieldContainer}>
            <Input
              id="username"
              name="credentials.username"
              type="text"
              placeholder="Institution Username"
              required
            />
            <Input
              id="password"
              name="credentials.password"
              type="password"
              placeholder="Institution Password"
              required
            />
          </View>
        )}

        {error && (
          <View style={styles.fieldContainer}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}

        <View style={styles.buttonContainer}>
          <Button onPress={onCancel} variant="secondary">
            Cancel
          </Button>
          <Button type="submit" variant="primary">
            {account ? 'Update Account' : 'Add Account'}
          </Button>
        </View>
      </Form>
    </View>
  );
});

// Requirement: Cross-Platform UI Consistency - Define consistent styles
const styles = StyleSheet.create({
  container: {
    width: '100%',
    padding: 16
  },
  fieldContainer: {
    marginBottom: 16
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginTop: 24
  },
  errorText: {
    color: 'red',
    fontSize: 14,
    marginTop: 8
  }
});

AccountForm.displayName = 'AccountForm';

export default AccountForm;