// react version: ^18.0.0
// react-native version: ^0.71.0
// yup version: ^1.0.0

// HUMAN TASKS:
// 1. Verify biometric authentication hardware support on target devices
// 2. Test password change flow with various password managers
// 3. Validate accessibility of security settings for screen readers
// 4. Configure proper error monitoring for security operations

import React, { useState, useCallback } from 'react';
import { StyleSheet, View, ScrollView } from 'react-native';
import * as Yup from 'yup';

import Button from '../../components/common/Button';
import Form from '../../components/common/Form';
import { useAuth } from '../../hooks/useAuth';
import { encryptData } from '../../utils/encryption';

// Interface for security form values
interface SecurityFormValues {
  currentPassword: string;
  newPassword: string;
  confirmPassword: string;
}

// Validation schema for password change form
const validationSchema = Yup.object().shape({
  currentPassword: Yup.string()
    .required('Current password is required')
    .min(8, 'Password must be at least 8 characters'),
  newPassword: Yup.string()
    .required('New password is required')
    .min(8, 'Password must be at least 8 characters')
    .matches(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/,
      'Password must contain at least one uppercase letter, one lowercase letter, one number, and one special character'
    )
    .notOneOf(
      [Yup.ref('currentPassword')],
      'New password must be different from current password'
    ),
  confirmPassword: Yup.string()
    .required('Please confirm your new password')
    .oneOf([Yup.ref('newPassword')], 'Passwords must match'),
});

/**
 * Security settings screen component that allows users to manage security preferences
 * @requirements Security Settings Management - 6.1 AUTHENTICATION AND AUTHORIZATION/6.1.1 Authentication Flow
 * @requirements Multi-platform Authentication - 1.2 Scope/Account Management
 * @requirements Data Security - 2.4 Security Architecture/Client Security
 */
const SecurityScreen: React.FC = React.memo(() => {
  const { changePassword } = useAuth();
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Initial form values
  const initialValues: SecurityFormValues = {
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  };

  /**
   * Handle password change submission
   * @requirements Data Security - 2.4 Security Architecture/Client Security
   */
  const handlePasswordChange = useCallback(async (values: SecurityFormValues) => {
    setLoading(true);
    setMessage(null);

    try {
      // Encrypt sensitive password data before transmission
      const encryptedCurrentPassword = await encryptData(values.currentPassword, 'password');
      const encryptedNewPassword = await encryptData(values.newPassword, 'password');

      // Call authentication service to change password
      await changePassword({
        currentPassword: encryptedCurrentPassword,
        newPassword: encryptedNewPassword,
      });

      setMessage({
        type: 'success',
        text: 'Password successfully updated',
      });
    } catch (error) {
      setMessage({
        type: 'error',
        text: error instanceof Error ? error.message : 'Failed to update password',
      });
    } finally {
      setLoading(false);
    }
  }, [changePassword]);

  return (
    <ScrollView 
      style={styles.container}
      contentContainerStyle={styles.content}
      testID="security-screen"
    >
      <View style={styles.section}>
        <Form
          initialValues={initialValues}
          validationSchema={validationSchema}
          onSubmit={handlePasswordChange}
          submitButtonText="Update Password"
          loading={loading}
        >
          {/* Form fields will be automatically handled by the Form component */}
          <View style={styles.message}>
            {message && (
              <Text
                style={[
                  styles.messageText,
                  message.type === 'error' ? styles.errorText : styles.successText
                ]}
              >
                {message.text}
              </Text>
            )}
          </View>
        </Form>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Additional Security Options</Text>
        <Button
          variant="outline"
          onPress={() => {
            // Biometric authentication toggle implementation
            // This is a placeholder for future implementation
          }}
          testID="biometric-auth-button"
        >
          Enable Biometric Authentication
        </Button>
      </View>
    </ScrollView>
  );
});

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'theme.colors.background',
  },
  content: {
    padding: 16,
    flex: 1,
  },
  section: {
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    marginBottom: 16,
  },
  message: {
    marginTop: 8,
    marginBottom: 8,
  },
  messageText: {
    fontSize: 14,
    textAlign: 'center',
  },
  successText: {
    color: 'theme.colors.success',
  },
  errorText: {
    color: 'theme.colors.error',
  },
});

SecurityScreen.displayName = 'SecurityScreen';

export default SecurityScreen;