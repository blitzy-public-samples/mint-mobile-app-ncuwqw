// react version: ^18.2.0
// react-native version: ^0.71.0
// @react-navigation/native version: ^6.1.0

/**
 * HUMAN TASKS:
 * 1. Verify accessibility compliance with WCAG guidelines
 * 2. Test dark mode appearance and contrast ratios
 * 3. Validate responsive layout on different screen sizes
 * 4. Review security settings with security team
 */

import React, { useState, useCallback } from 'react';
import { 
  StyleSheet, 
  View, 
  Text, 
  ScrollView, 
  Switch, 
  TouchableOpacity 
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import Header from '../../components/common/Header';
import Card from '../../components/common/Card';
import { useAuth } from '../../hooks/useAuth';

interface SettingsOption {
  title: string;
  description: string;
  type: 'toggle' | 'action';
  value: boolean;
  onPress: () => void;
}

/**
 * Settings screen component that provides user preferences, security settings,
 * and account management functionality
 * @requirements Account Management - 1.2 Scope/Account Management
 * @requirements Security Infrastructure - 1.1 System Overview/Security Infrastructure
 * @requirements Cross-platform UI - 2.2.1 Client Applications/React Native
 */
const SettingsScreen: React.FC = () => {
  const navigation = useNavigation();
  const { user, logout, isAuthenticated } = useAuth();

  // Settings state management
  const [settings, setSettings] = useState({
    notifications: {
      pushEnabled: true,
      emailEnabled: true,
      budgetAlerts: true,
      securityAlerts: true
    },
    security: {
      twoFactorEnabled: false,
      biometricEnabled: true,
      locationTracking: false
    },
    preferences: {
      darkMode: false,
      compactView: false,
      autoSync: true
    }
  });

  /**
   * Handle settings toggle with state update
   * @param settingKey - Setting identifier
   * @param value - New toggle value
   */
  const handleSettingToggle = useCallback((settingKey: string, value: boolean) => {
    const [category, setting] = settingKey.split('.');
    setSettings(prev => ({
      ...prev,
      [category]: {
        ...prev[category],
        [setting]: value
      }
    }));
  }, []);

  /**
   * Handle user logout process
   * @requirements Security Infrastructure - 1.1 System Overview/Security Infrastructure
   */
  const handleLogout = async (): Promise<void> => {
    try {
      await logout();
      navigation.navigate('Login');
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  // Notification settings options
  const notificationOptions: SettingsOption[] = [
    {
      title: 'Push Notifications',
      description: 'Receive important updates on your device',
      type: 'toggle',
      value: settings.notifications.pushEnabled,
      onPress: () => handleSettingToggle('notifications.pushEnabled', !settings.notifications.pushEnabled)
    },
    {
      title: 'Email Notifications',
      description: 'Receive updates via email',
      type: 'toggle',
      value: settings.notifications.emailEnabled,
      onPress: () => handleSettingToggle('notifications.emailEnabled', !settings.notifications.emailEnabled)
    },
    {
      title: 'Budget Alerts',
      description: 'Get notified about budget limits and goals',
      type: 'toggle',
      value: settings.notifications.budgetAlerts,
      onPress: () => handleSettingToggle('notifications.budgetAlerts', !settings.notifications.budgetAlerts)
    }
  ];

  // Security settings options
  const securityOptions: SettingsOption[] = [
    {
      title: 'Two-Factor Authentication',
      description: 'Add an extra layer of security to your account',
      type: 'toggle',
      value: settings.security.twoFactorEnabled,
      onPress: () => handleSettingToggle('security.twoFactorEnabled', !settings.security.twoFactorEnabled)
    },
    {
      title: 'Biometric Authentication',
      description: 'Use fingerprint or face recognition to login',
      type: 'toggle',
      value: settings.security.biometricEnabled,
      onPress: () => handleSettingToggle('security.biometricEnabled', !settings.security.biometricEnabled)
    }
  ];

  // Preference settings options
  const preferenceOptions: SettingsOption[] = [
    {
      title: 'Dark Mode',
      description: 'Switch between light and dark theme',
      type: 'toggle',
      value: settings.preferences.darkMode,
      onPress: () => handleSettingToggle('preferences.darkMode', !settings.preferences.darkMode)
    },
    {
      title: 'Compact View',
      description: 'Display more information in less space',
      type: 'toggle',
      value: settings.preferences.compactView,
      onPress: () => handleSettingToggle('preferences.compactView', !settings.preferences.compactView)
    },
    {
      title: 'Auto Sync',
      description: 'Automatically sync account data',
      type: 'toggle',
      value: settings.preferences.autoSync,
      onPress: () => handleSettingToggle('preferences.autoSync', !settings.preferences.autoSync)
    }
  ];

  const renderSettingOption = (option: SettingsOption) => (
    <View key={option.title} style={styles.optionContainer}>
      <View style={styles.optionTextContainer}>
        <Text style={styles.optionText}>{option.title}</Text>
        <Text style={styles.optionDescription}>{option.description}</Text>
      </View>
      {option.type === 'toggle' ? (
        <Switch
          value={option.value}
          onValueChange={option.onPress}
          accessibilityLabel={option.title}
          accessibilityHint={`Toggle ${option.title}`}
        />
      ) : (
        <TouchableOpacity
          onPress={option.onPress}
          accessibilityRole="button"
          accessibilityLabel={option.title}
        >
          <Text style={styles.actionText}>Configure</Text>
        </TouchableOpacity>
      )}
    </View>
  );

  return (
    <View style={styles.container}>
      <Header title="Settings" showBackButton />
      <ScrollView style={styles.content}>
        {isAuthenticated && (
          <Card elevation={1} padding={16}>
            <View style={styles.section}>
              <Text style={styles.sectionTitle}>Account</Text>
              <View style={styles.accountInfo}>
                <Text style={styles.accountText}>
                  {user?.email}
                </Text>
              </View>
            </View>
          </Card>
        )}

        <Card elevation={1} padding={16} style={styles.card}>
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Notifications</Text>
            {notificationOptions.map(renderSettingOption)}
          </View>
        </Card>

        <Card elevation={1} padding={16} style={styles.card}>
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Security</Text>
            {securityOptions.map(renderSettingOption)}
          </View>
        </Card>

        <Card elevation={1} padding={16} style={styles.card}>
          <View style={styles.section}>
            <Text style={styles.sectionTitle}>Preferences</Text>
            {preferenceOptions.map(renderSettingOption)}
          </View>
        </Card>

        {isAuthenticated && (
          <TouchableOpacity
            style={styles.logoutButton}
            onPress={handleLogout}
            accessibilityRole="button"
            accessibilityLabel="Logout"
          >
            <Text style={styles.logoutButtonText}>Logout</Text>
          </TouchableOpacity>
        )}
      </ScrollView>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F5F5F5'
  },
  content: {
    flex: 1,
    padding: 16
  },
  card: {
    marginBottom: 16
  },
  section: {
    marginBottom: 16
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 16,
    color: '#1A1A1A'
  },
  optionContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 12,
    borderBottomWidth: StyleSheet.hairlineWidth,
    borderBottomColor: '#E0E0E0'
  },
  optionTextContainer: {
    flex: 1,
    marginRight: 16
  },
  optionText: {
    fontSize: 16,
    color: '#1A1A1A',
    marginBottom: 4
  },
  optionDescription: {
    fontSize: 14,
    color: '#757575'
  },
  actionText: {
    color: '#2196F3',
    fontSize: 16
  },
  accountInfo: {
    paddingVertical: 8
  },
  accountText: {
    fontSize: 16,
    color: '#1A1A1A'
  },
  logoutButton: {
    backgroundColor: '#FF3B30',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginVertical: 24
  },
  logoutButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600'
  }
});

export default SettingsScreen;