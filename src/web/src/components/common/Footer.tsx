// react version: ^18.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify footer links are up-to-date with current legal documents
// 2. Ensure accessibility compliance with WCAG guidelines
// 3. Test footer responsiveness across all supported breakpoints
// 4. Validate footer appearance in both light and dark themes

import React from 'react';
import { StyleSheet, View, Text, Pressable } from 'react-native';
import { useTheme } from '../../hooks/useTheme';
import { Container, Flex } from '../../styles/layout';

/**
 * Footer component providing consistent navigation and legal information
 * @returns {JSX.Element} Rendered footer component
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 * @requirements Responsive Design - 5.1.7 Platform-Specific Implementation Notes/Web
 * @requirements Dark Mode Support - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const Footer = React.memo(() => {
  const { theme, isDarkMode } = useTheme();

  const navigationLinks = [
    { label: 'About Us', href: '/about' },
    { label: 'Privacy Policy', href: '/privacy' },
    { label: 'Terms of Service', href: '/terms' },
    { label: 'Security', href: '/security' },
    { label: 'Contact', href: '/contact' },
  ];

  const handleLinkPress = (href: string) => {
    window.location.href = href;
  };

  return (
    <View style={[
      styles.container,
      {
        borderTopColor: theme.colors.border,
        backgroundColor: theme.colors.background,
      }
    ]}>
      <View style={[Container.fluid]}>
        <View style={[styles.content]}>
          <View style={[Flex.row, styles.linkContainer]}>
            {navigationLinks.map((link) => (
              <Pressable
                key={link.href}
                onPress={() => handleLinkPress(link.href)}
                accessibilityRole="link"
                accessibilityLabel={link.label}
              >
                <Text
                  style={[
                    styles.link,
                    { color: theme.colors.text.secondary }
                  ]}
                >
                  {link.label}
                </Text>
              </Pressable>
            ))}
          </View>
          <Text
            style={[
              styles.copyright,
              { color: theme.colors.text.secondary }
            ]}
          >
            © {new Date().getFullYear()} Mint Replica Lite. All rights reserved.
          </Text>
        </View>
      </View>
    </View>
  );
});

const styles = StyleSheet.create({
  container: {
    borderTopWidth: 1,
    paddingVertical: 24, // theme.spacing.lg
  },
  content: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 16, // theme.spacing.md
  },
  linkContainer: {
    flexDirection: 'row',
    gap: 16, // theme.spacing.md
  },
  link: {
    fontSize: 14, // theme.typography.caption.fontSize
    textDecorationLine: 'none',
  },
  copyright: {
    fontSize: 14, // theme.typography.caption.fontSize
    marginTop: 8, // theme.spacing.sm
  },
});

export default Footer;