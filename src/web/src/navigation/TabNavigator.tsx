// react version: ^18.0.0
// @react-navigation/bottom-tabs version: ^6.0.0
// react-native version: ^0.71.0
// @expo/vector-icons version: ^13.0.0

// Human Tasks:
// 1. Verify that all required navigation dependencies are installed in package.json
// 2. Ensure icon assets are properly loaded in the Expo configuration
// 3. Test navigation behavior across different screen sizes and orientations
// 4. Validate tab bar appearance in both light and dark themes

import React from 'react';
import { useWindowDimensions } from 'react-native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { MaterialCommunityIcons } from '@expo/vector-icons';

// Internal imports
import { ROUTES } from '../constants/routes';
import DashboardScreen from '../screens/dashboard/DashboardScreen';

// Define the type for navigation parameters
interface TabParamList {
  Dashboard: undefined;
  Transactions: undefined;
  Budgets: undefined;
  Goals: undefined;
  Investments: undefined;
}

// Create bottom tab navigator
const Tab = createBottomTabNavigator<TabParamList>();

/**
 * Returns the appropriate icon component for each tab
 * @requirements Core Feature Navigation - 1.2 Scope/In Scope
 */
const getTabBarIcon = (route: string, focused: boolean) => {
  let iconName: keyof typeof MaterialCommunityIcons.glyphMap;

  switch (route) {
    case 'Dashboard':
      iconName = 'view-dashboard';
      break;
    case 'Transactions':
      iconName = 'wallet';
      break;
    case 'Budgets':
      iconName = 'chart-bar';
      break;
    case 'Goals':
      iconName = 'target';
      break;
    case 'Investments':
      iconName = 'chart-line';
      break;
    default:
      iconName = 'view-dashboard';
  }

  return (
    <MaterialCommunityIcons
      name={iconName}
      size={24}
      color={focused ? 'theme.colors.primary' : 'theme.colors.inactive'}
      style={styles.tabBarIcon}
    />
  );
};

/**
 * Main tab navigation component for the application
 * @requirements Cross-platform Navigation - 1.1 System Overview/Client Applications
 * @requirements Mobile Adaptations - 5.1.6 Mobile-Specific Adaptations
 */
export const TabNavigator: React.FC = () => {
  const { width } = useWindowDimensions();
  const isLargeScreen = width >= 768;

  return (
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ focused }) => getTabBarIcon(route.name, focused),
        tabBarActiveTintColor: 'theme.colors.primary',
        tabBarInactiveTintColor: 'theme.colors.inactive',
        tabBarLabelStyle: styles.tabBarLabel,
        tabBarStyle: {
          ...styles.tabBar,
          height: isLargeScreen ? 70 : 60,
          paddingBottom: isLargeScreen ? 10 : 5,
        },
        headerShown: false,
      })}
    >
      <Tab.Screen
        name="Dashboard"
        component={DashboardScreen}
        options={{
          title: 'Dashboard',
          tabBarTestID: 'dashboard-tab',
        }}
      />
      
      <Tab.Screen
        name="Transactions"
        component={DashboardScreen} // Placeholder until TransactionScreen is implemented
        options={{
          title: 'Transactions',
          tabBarTestID: 'transactions-tab',
        }}
      />
      
      <Tab.Screen
        name="Budgets"
        component={DashboardScreen} // Placeholder until BudgetScreen is implemented
        options={{
          title: 'Budgets',
          tabBarTestID: 'budgets-tab',
        }}
      />
      
      <Tab.Screen
        name="Goals"
        component={DashboardScreen} // Placeholder until GoalScreen is implemented
        options={{
          title: 'Goals',
          tabBarTestID: 'goals-tab',
        }}
      />
      
      <Tab.Screen
        name="Investments"
        component={DashboardScreen} // Placeholder until InvestmentScreen is implemented
        options={{
          title: 'Investments',
          tabBarTestID: 'investments-tab',
        }}
      />
    </Tab.Navigator>
  );
};

/**
 * Component styles
 * @requirements Mobile Adaptations - 5.1.6 Mobile-Specific Adaptations
 */
const styles = {
  tabBar: {
    height: 60,
    paddingBottom: 5,
    borderTopWidth: 1,
    borderTopColor: 'theme.colors.border',
    elevation: 8,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: -2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  tabBarLabel: {
    fontSize: 12,
    marginBottom: 3,
    fontFamily: 'theme.fonts.regular',
  },
  tabBarIcon: {
    marginTop: 3,
  },
};

export default TabNavigator;