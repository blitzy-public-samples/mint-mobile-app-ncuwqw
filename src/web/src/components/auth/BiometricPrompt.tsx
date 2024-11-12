// react version: ^18.2.0
// react-native version: ^0.71.0
// @github/webauthn-json version: ^2.1.1

// Human Tasks:
// 1. Verify biometric hardware support on target devices
// 2. Test fallback authentication methods
// 3. Validate accessibility features for biometric prompts
// 4. Ensure proper error handling for unsupported devices

import React, { useState, useCallback, useEffect } from 'react';
import { StyleSheet, View, Text } from 'react-native';
import { create, supported } from '@github/webauthn-json';
import Modal from '../common/Modal';
import { useAuth } from '../../hooks/useAuth';

interface BiometricPromptProps {
  visible: boolean;
  onSuccess: () => void;
  onCancel: () => void;
  onError: (error: Error) => void;
  testID?: string;
}

/**
 * BiometricPrompt component that handles platform-specific biometric authentication
 * @requirements Multi-platform Authentication - Support cross-platform user authentication including biometric authentication
 * @requirements Security Standards - Implement secure biometric authentication following OWASP security standards
 */
const BiometricPrompt: React.FC<BiometricPromptProps> = ({
  visible,
  onSuccess,
  onCancel,
  onError,
  testID = 'biometric-prompt'
}) => {
  const { isAuthenticated, isLoading } = useAuth();
  const [isCheckingAvailability, setIsCheckingAvailability] = useState(false);
  const [isBiometricAvailable, setIsBiometricAvailable] = useState(false);

  /**
   * Check if biometric authentication is available on the device
   * @requirements Platform Security - Implement platform-specific biometric security measures
   */
  const checkBiometricAvailability = useCallback(async (): Promise<boolean> => {
    try {
      // Check if WebAuthn is supported by the browser
      if (!supported()) {
        return false;
      }

      // Check if platform authenticator is available
      const available = await PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
      return available;
    } catch (error) {
      console.error('Error checking biometric availability:', error);
      return false;
    }
  }, []);

  useEffect(() => {
    const checkAvailability = async () => {
      setIsCheckingAvailability(true);
      const available = await checkBiometricAvailability();
      setIsBiometricAvailable(available);
      setIsCheckingAvailability(false);

      if (!available && visible) {
        onError(new Error('Biometric authentication not available on this device'));
      }
    };

    if (visible) {
      checkAvailability();
    }
  }, [visible, checkBiometricAvailability, onError]);

  /**
   * Handle biometric authentication attempt
   * @requirements Security Standards - Implement secure biometric authentication following OWASP security standards
   */
  const handleBiometricAuth = async () => {
    try {
      // Create WebAuthn credential options
      const credential = await create({
        publicKey: {
          challenge: new Uint8Array(32).buffer, // Generate proper challenge in production
          rp: {
            name: 'Mint Replica Lite',
            id: window.location.hostname
          },
          user: {
            id: new Uint8Array(16), // Use actual user ID in production
            name: 'user@example.com', // Use actual user email in production
            displayName: 'User'
          },
          pubKeyCredParams: [
            { type: 'public-key', alg: -7 }, // ES256
            { type: 'public-key', alg: -257 } // RS256
          ],
          timeout: 60000,
          attestation: 'direct',
          authenticatorSelection: {
            authenticatorAttachment: 'platform',
            userVerification: 'required'
          }
        }
      });

      if (credential) {
        onSuccess();
      }
    } catch (error) {
      if (error instanceof Error) {
        onError(error);
      } else {
        onError(new Error('Unknown biometric authentication error'));
      }
    }
  };

  return (
    <Modal
      visible={visible}
      onClose={onCancel}
      title="Biometric Authentication"
      testID={testID}
    >
      <View style={styles.container}>
        {isCheckingAvailability ? (
          <Text style={styles.message}>
            Checking biometric availability...
          </Text>
        ) : isBiometricAvailable ? (
          <>
            <View style={styles.icon}>
              {/* Replace with actual fingerprint/face icon based on platform */}
              <Text>🔐</Text>
            </View>
            <Text style={styles.message}>
              Please verify your identity using biometric authentication
            </Text>
            <View style={styles.buttonContainer}>
              <Text
                style={styles.button}
                onPress={handleBiometricAuth}
                accessibilityRole="button"
                accessibilityLabel="Authenticate with biometrics"
              >
                Authenticate
              </Text>
              <Text
                style={[styles.button, styles.cancelButton]}
                onPress={onCancel}
                accessibilityRole="button"
                accessibilityLabel="Cancel biometric authentication"
              >
                Cancel
              </Text>
            </View>
          </>
        ) : (
          <Text style={styles.message}>
            Biometric authentication is not available on this device
          </Text>
        )}
      </View>
    </Modal>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  icon: {
    width: 64,
    height: 64,
    marginBottom: 16,
    justifyContent: 'center',
    alignItems: 'center',
  },
  message: {
    fontSize: 16,
    textAlign: 'center',
    marginBottom: 20,
    color: '#333',
  },
  buttonContainer: {
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 16,
  },
  button: {
    paddingVertical: 8,
    paddingHorizontal: 16,
    backgroundColor: '#007AFF',
    borderRadius: 8,
    color: '#FFFFFF',
    fontSize: 16,
    textAlign: 'center',
  },
  cancelButton: {
    backgroundColor: '#FF3B30',
  },
});

export default BiometricPrompt;