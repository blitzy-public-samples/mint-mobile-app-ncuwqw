// HUMAN TASKS:
// 1. Test form accessibility with screen readers
// 2. Verify form validation behavior across different browsers
// 3. Test profile update functionality with slow network conditions
// 4. Validate theme-aware styling matches design system specifications

// React version: ^18.0.0
// React Native version: ^0.71.0
// Yup version: ^1.0.0

import React from 'react';
import { StyleSheet, View, ScrollView } from 'react-native';
import * as Yup from 'yup';
import Card from '../../components/common/Card';
import Form from '../../components/common/Form';
import { useAuth } from '../../hooks/useAuth';

// Requirement: Account Management - Define profile form data interface
interface ProfileFormData {
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  preferredCurrency: string;
}

// Requirement: Data Security - Implement form validation schema
const validationSchema = Yup.object().shape({
  firstName: Yup.string()
    .required('First name is required')
    .min(2, 'First name must be at least 2 characters')
    .max(50, 'First name must not exceed 50 characters'),
  lastName: Yup.string()
    .required('Last name is required')
    .min(2, 'Last name must be at least 2 characters')
    .max(50, 'Last name must not exceed 50 characters'),
  email: Yup.string()
    .required('Email is required')
    .email('Invalid email format'),
  phoneNumber: Yup.string()
    .matches(/^\+?[\d\s-]{10,}$/, 'Invalid phone number format')
    .required('Phone number is required'),
  preferredCurrency: Yup.string()
    .required('Preferred currency is required')
    .matches(/^[A-Z]{3}$/, 'Invalid currency code format')
});

// Requirement: Cross-Platform UI - Create profile screen component
const ProfileScreen: React.FC = React.memo(() => {
  const { user, isLoading } = useAuth();

  // Requirement: Account Management - Handle profile update submission
  const handleProfileUpdate = async (formData: ProfileFormData): Promise<void> => {
    try {
      // TODO: Implement profile update API call through useAuth hook
      console.log('Updating profile:', formData);
    } catch (error) {
      console.error('Profile update failed:', error);
      throw new Error('Failed to update profile. Please try again.');
    }
  };

  // Requirement: Cross-Platform UI - Initialize form with user data
  const initialValues: ProfileFormData = {
    firstName: user?.firstName || '',
    lastName: user?.lastName || '',
    email: user?.email || '',
    phoneNumber: user?.phoneNumber || '',
    preferredCurrency: user?.preferredCurrency || 'USD'
  };

  return (
    <View style={styles.container}>
      <ScrollView 
        style={styles.scrollContainer}
        contentContainerStyle={styles.formContainer}
        testID="profile-screen-scroll-view"
      >
        {/* Requirement: Cross-Platform UI - Render profile sections */}
        <Card elevation={2} padding={24}>
          <View style={styles.section}>
            <Form
              initialValues={initialValues}
              validationSchema={validationSchema}
              onSubmit={handleProfileUpdate}
              loading={isLoading}
            >
              {/* Form fields will be rendered by the Form component */}
              {/* The Form component handles the rendering of Input components */}
              {/* and proper error display based on the validation schema */}
            </Form>
          </View>
        </Card>
      </ScrollView>
    </View>
  );
});

// Requirement: Cross-Platform UI - Define theme-aware styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'theme.colors.background'
  },
  scrollContainer: {
    padding: 16
  },
  section: {
    marginBottom: 24
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
    color: 'theme.colors.text'
  },
  formContainer: {
    width: '100%',
    maxWidth: 600,
    alignSelf: 'center'
  }
});

ProfileScreen.displayName = 'ProfileScreen';

export default ProfileScreen;