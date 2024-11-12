// react version: ^18.2.0
// react-native version: ^0.71.0
// @react-navigation/native version: ^6.1.0

/**
 * HUMAN TASKS:
 * 1. Verify header height meets minimum touch target size (44px) for accessibility
 * 2. Test header responsiveness across different screen sizes
 * 3. Validate color contrast ratios in both light and dark themes
 * 4. Ensure logo assets are properly optimized and cached
 */

import React from 'react';
import { StyleSheet, View, Text, Pressable } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { ROUTES } from '../../constants/routes';
import { useAuth } from '../../hooks/useAuth';
import Button from './Button';

interface HeaderProps {
  title?: string;
  showBackButton?: boolean;
  style?: StyleProp<ViewStyle>;
}

/**
 * A responsive header component for the Mint Replica Lite web application
 * @requirements Cross-platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Multi-platform Authentication - 1.2 Scope/Account Management
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const Header: React.FC<HeaderProps> = ({
  title = 'Mint Replica Lite',
  showBackButton = false,
  style
}) => {
  const navigation = useNavigation();
  const { user, isAuthenticated, logout } = useAuth();

  const handleBack = () => {
    if (navigation.canGoBack()) {
      navigation.goBack();
    }
  };

  const handleNavigate = (route: string) => {
    navigation.navigate(route);
  };

  const handleLogout = async () => {
    try {
      await logout();
      navigation.navigate(ROUTES.AUTH.LOGIN);
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };

  return (
    <View style={[styles.container, style]}>
      <View style={styles.leftSection}>
        {showBackButton && (
          <Pressable
            onPress={handleBack}
            style={styles.backButton}
            accessibilityRole="button"
            accessibilityLabel="Go back"
          >
            <Text style={styles.backButtonText}>←</Text>
          </Pressable>
        )}
        
        <Pressable
          onPress={() => handleNavigate(ROUTES.DASHBOARD.HOME)}
          style={styles.logoContainer}
          accessibilityRole="link"
          accessibilityLabel="Go to home"
        >
          <View style={styles.logo} />
          <Text style={styles.title}>{title}</Text>
        </Pressable>
      </View>

      <View style={styles.navigationLinks}>
        {isAuthenticated && (
          <>
            <Pressable
              onPress={() => handleNavigate(ROUTES.DASHBOARD.OVERVIEW)}
              style={styles.navLink}
              accessibilityRole="link"
            >
              <Text style={styles.navLinkText}>Overview</Text>
            </Pressable>
            <Pressable
              onPress={() => handleNavigate(ROUTES.SETTINGS.MAIN)}
              style={styles.navLink}
              accessibilityRole="link"
            >
              <Text style={styles.navLinkText}>Settings</Text>
            </Pressable>
          </>
        )}
      </View>

      <View style={styles.rightSection}>
        {isAuthenticated ? (
          <View style={styles.userMenu}>
            <Pressable
              style={styles.profileButton}
              onPress={() => handleNavigate(ROUTES.SETTINGS.PROFILE)}
              accessibilityRole="button"
              accessibilityLabel="User profile"
            >
              <Text style={styles.profileText}>
                {user?.email?.split('@')[0]}
              </Text>
            </Pressable>
            <Button
              variant="outline"
              size="small"
              onPress={handleLogout}
              style={styles.logoutButton}
            >
              Logout
            </Button>
          </View>
        ) : (
          <View style={styles.authButtons}>
            <Button
              variant="outline"
              size="small"
              onPress={() => handleNavigate(ROUTES.AUTH.LOGIN)}
              style={styles.loginButton}
            >
              Login
            </Button>
            <Button
              variant="primary"
              size="small"
              onPress={() => handleNavigate(ROUTES.AUTH.REGISTER)}
              style={styles.registerButton}
            >
              Register
            </Button>
          </View>
        )}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    height: 64,
    backgroundColor: '#FFFFFF',
    shadowColor: '#000000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 4,
  },
  leftSection: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  backButton: {
    padding: 8,
    marginRight: 8,
  },
  backButtonText: {
    fontSize: 24,
    color: '#000000',
  },
  logoContainer: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  logo: {
    width: 32,
    height: 32,
    marginRight: 8,
    backgroundColor: '#00A6A4', // Brand color placeholder
    borderRadius: 16,
  },
  title: {
    fontSize: 20,
    fontWeight: '600',
    color: '#000000',
  },
  navigationLinks: {
    flexDirection: 'row',
    gap: 16,
    marginLeft: 32,
  },
  navLink: {
    padding: 8,
  },
  navLinkText: {
    fontSize: 16,
    color: '#4A4A4A',
  },
  rightSection: {
    marginLeft: 'auto',
  },
  userMenu: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 16,
  },
  profileButton: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 8,
  },
  profileText: {
    fontSize: 16,
    color: '#000000',
    fontWeight: '500',
  },
  authButtons: {
    flexDirection: 'row',
    gap: 8,
  },
  loginButton: {
    minWidth: 80,
  },
  registerButton: {
    minWidth: 80,
  },
  logoutButton: {
    minWidth: 80,
  },
});

export default Header;