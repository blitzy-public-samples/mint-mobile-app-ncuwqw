// React version: ^18.2.0
// React Native version: ^0.71.0
// @react-navigation/native version: ^6.1.0

// HUMAN TASKS:
// 1. Verify error message strings match design system guidelines
// 2. Test form submission under poor network conditions
// 3. Validate screen behavior with screen readers
// 4. Test budget creation with maximum allowed values

import React, { useState } from 'react';
import { StyleSheet, View, ScrollView } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import type { NavigationProp, ParamListBase } from '@react-navigation/native';

// Internal component imports
import { Header } from '../../components/common/Header';
import { BudgetForm } from '../../components/budgets/BudgetForm';
import { createBudget } from '../../services/api/budgets';

// Requirement: Cross-Platform UI - Define consistent props interface
interface CreateBudgetScreenProps {
  navigation: NavigationProp<ParamListBase>;
}

// Requirement: Budget Management - Implement budget creation screen
const CreateBudgetScreen: React.FC<CreateBudgetScreenProps> = () => {
  const navigation = useNavigation();
  const [loading, setLoading] = useState<boolean>(false);

  // Requirement: Input Validation - Handle budget creation with validation
  const handleCreateBudget = async (budgetData: {
    name: string;
    categoryId: string;
    amount: number;
    period: BudgetPeriod;
    startDate: Date;
    endDate: Date;
    alertThreshold?: number;
  }): Promise<void> => {
    try {
      setLoading(true);
      await createBudget(budgetData);
      navigation.goBack();
    } catch (error) {
      // Error handling will be managed by the form component
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const handleCancel = (): void => {
    navigation.goBack();
  };

  return (
    <View style={styles.container}>
      {/* Requirement: Cross-Platform UI - Implement consistent header */}
      <Header
        title="Create Budget"
        showBackButton={true}
        style={styles.header}
      />
      
      {/* Requirement: Cross-Platform UI - Implement scrollable form container */}
      <ScrollView 
        style={styles.content}
        contentContainerStyle={styles.contentContainer}
        keyboardShouldPersistTaps="handled"
      >
        {/* Requirement: Budget Management - Render budget creation form */}
        <BudgetForm
          budget={null}
          onSubmit={handleCreateBudget}
          onCancel={handleCancel}
          loading={loading}
        />
      </ScrollView>
    </View>
  );
};

// Requirement: Cross-Platform UI - Define consistent styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  header: {
    elevation: 2,
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  content: {
    flex: 1,
  },
  contentContainer: {
    padding: 16,
    maxWidth: 800,
    alignSelf: 'center',
    width: '100%',
  },
});

export default CreateBudgetScreen;