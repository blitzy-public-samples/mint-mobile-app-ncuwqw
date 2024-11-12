/**
 * HUMAN TASKS:
 * 1. Configure Firebase project and obtain configuration credentials
 * 2. Add Firebase configuration to environment variables
 * 3. Enable Firebase Cloud Messaging in Firebase Console
 * 4. Configure VAPID keys for web push notifications
 * 5. Set up SSL certificate for service worker registration
 */

// firebase/app v9.0.0
import { initializeApp } from 'firebase/app';
// firebase/messaging v9.0.0
import { getMessaging, getToken, onMessage, Messaging } from 'firebase/messaging';
import { APIResponse, APIError } from '../../types';
import { storage } from '../../utils/storage';
import { apiInstance } from '../../utils/api';

// Global storage keys for notification preferences and FCM token
const NOTIFICATION_STORAGE_KEY = '@mint_replica_lite_web/notification_preferences';
const FCM_TOKEN_KEY = '@mint_replica_lite_web/fcm_token';

// Notification preference interface
interface NotificationPreferences {
    budgetAlerts: boolean;
    transactionAlerts: boolean;
    goalAlerts: boolean;
    marketingAlerts: boolean;
}

// Default notification preferences
const DEFAULT_PREFERENCES: NotificationPreferences = {
    budgetAlerts: true,
    transactionAlerts: true,
    goalAlerts: true,
    marketingAlerts: false
};

/**
 * Initializes the notification service and requests necessary permissions
 * Requirement: Push Notifications - Integration with Web Push Notification service
 */
async function initializeNotifications(): Promise<boolean> {
    try {
        // Check browser support for notifications
        if (!('Notification' in window)) {
            console.error('This browser does not support notifications');
            return false;
        }

        // Request notification permission if not granted
        const permission = await Notification.requestPermission();
        if (permission !== 'granted') {
            console.warn('Notification permission not granted');
            return false;
        }

        // Initialize Firebase messaging
        const messaging = getMessaging();
        const token = await getToken(messaging, {
            vapidKey: process.env.FIREBASE_VAPID_KEY
        });

        if (!token) {
            console.error('Failed to obtain FCM token');
            return false;
        }

        // Store token securely
        await storage.setItem(FCM_TOKEN_KEY, token, true);
        
        // Register token with backend
        await registerNotificationToken(token);

        return true;
    } catch (error) {
        console.error('Failed to initialize notifications:', error);
        return false;
    }
}

/**
 * Registers FCM token with backend service
 * Requirement: Push Notifications - Integration with Web Push Notification service
 */
async function registerNotificationToken(token: string): Promise<APIResponse<any>> {
    try {
        const response = await apiInstance.post('/api/notifications/register', {
            token,
            platform: 'web',
            preferences: await storage.getItem(NOTIFICATION_STORAGE_KEY) || DEFAULT_PREFERENCES
        });
        return response;
    } catch (error) {
        throw new Error(`Failed to register notification token: ${error.message}`);
    }
}

/**
 * Processes incoming notifications and displays them
 * Requirement: Alert Management - Customizable alerts and notifications
 */
async function handleNotification(payload: any): Promise<void> {
    try {
        const preferences = await storage.getItem(NOTIFICATION_STORAGE_KEY) || DEFAULT_PREFERENCES;
        
        // Check if notification type is enabled in preferences
        const notificationType = payload.data?.type || 'general';
        if (!shouldShowNotification(notificationType, preferences)) {
            return;
        }

        // Display notification
        const notification = new Notification(payload.notification.title, {
            body: payload.notification.body,
            icon: '/icons/notification-icon.png',
            badge: '/icons/notification-badge.png',
            data: payload.data
        });

        // Handle notification click
        notification.onclick = () => {
            handleNotificationClick(payload.data);
        };

        // Track notification metrics
        await apiInstance.post('/api/notifications/metrics', {
            type: notificationType,
            action: 'display',
            messageId: payload.data?.messageId
        });
    } catch (error) {
        console.error('Failed to handle notification:', error);
    }
}

/**
 * Updates user notification preferences
 * Requirement: Alert Management - Customizable alerts and notifications
 */
async function updateNotificationPreferences(preferences: Partial<NotificationPreferences>): Promise<void> {
    try {
        // Validate preferences
        const currentPreferences = await storage.getItem(NOTIFICATION_STORAGE_KEY) || DEFAULT_PREFERENCES;
        const updatedPreferences = {
            ...currentPreferences,
            ...preferences
        };

        // Store updated preferences
        await storage.setItem(NOTIFICATION_STORAGE_KEY, updatedPreferences);

        // Sync with backend
        await apiInstance.put('/api/notifications/preferences', {
            preferences: updatedPreferences
        });

        // Update local notification handlers
        await updateNotificationHandlers(updatedPreferences);
    } catch (error) {
        throw new Error(`Failed to update notification preferences: ${error.message}`);
    }
}

/**
 * Core notification service class handling all notification operations
 * Requirement: Real-time Updates - Event-driven architecture
 */
class NotificationService {
    private isInitialized: boolean;
    private messaging: Messaging | null;
    private preferences: NotificationPreferences;

    constructor() {
        this.isInitialized = false;
        this.messaging = null;
        this.preferences = DEFAULT_PREFERENCES;

        // Initialize Firebase
        const firebaseConfig = {
            apiKey: process.env.FIREBASE_API_KEY,
            projectId: process.env.FIREBASE_PROJECT_ID,
            messagingSenderId: process.env.FIREBASE_MESSAGING_SENDER_ID,
            appId: process.env.FIREBASE_APP_ID
        };
        initializeApp(firebaseConfig);
    }

    /**
     * Initializes the notification service
     * Requirement: Push Notifications - Integration with Web Push Notification service
     */
    async initialize(): Promise<boolean> {
        try {
            // Initialize notifications
            const initialized = await initializeNotifications();
            if (!initialized) {
                return false;
            }

            // Set up messaging instance
            this.messaging = getMessaging();
            
            // Load preferences
            this.preferences = await storage.getItem(NOTIFICATION_STORAGE_KEY) || DEFAULT_PREFERENCES;

            // Set up message handler
            onMessage(this.messaging, (payload) => {
                handleNotification(payload);
            });

            this.isInitialized = true;
            return true;
        } catch (error) {
            console.error('Failed to initialize NotificationService:', error);
            return false;
        }
    }

    /**
     * Subscribes to specific notification topics
     * Requirement: Real-time Updates - Event-driven architecture
     */
    async subscribe(topic: string): Promise<void> {
        if (!this.isInitialized || !this.messaging) {
            throw new Error('NotificationService not initialized');
        }

        try {
            // Validate topic
            if (!topic || typeof topic !== 'string') {
                throw new Error('Invalid topic');
            }

            const token = await storage.getItem(FCM_TOKEN_KEY);
            if (!token) {
                throw new Error('FCM token not found');
            }

            // Subscribe to topic
            await apiInstance.post('/api/notifications/subscribe', {
                token,
                topic
            });

            // Update preferences
            const updatedPreferences = {
                ...this.preferences,
                [`${topic}Alerts`]: true
            };
            await storage.setItem(NOTIFICATION_STORAGE_KEY, updatedPreferences);
            this.preferences = updatedPreferences;
        } catch (error) {
            throw new Error(`Failed to subscribe to topic: ${error.message}`);
        }
    }
}

// Helper function to check if notification should be shown
function shouldShowNotification(type: string, preferences: NotificationPreferences): boolean {
    switch (type) {
        case 'budget':
            return preferences.budgetAlerts;
        case 'transaction':
            return preferences.transactionAlerts;
        case 'goal':
            return preferences.goalAlerts;
        case 'marketing':
            return preferences.marketingAlerts;
        default:
            return true;
    }
}

// Helper function to handle notification clicks
function handleNotificationClick(data: any): void {
    if (data?.url) {
        window.open(data.url, '_blank');
    } else {
        window.focus();
    }
}

// Helper function to update notification handlers based on preferences
async function updateNotificationHandlers(preferences: NotificationPreferences): Promise<void> {
    if (!('Notification' in window)) {
        return;
    }

    // Update service worker notification handlers if applicable
    if ('serviceWorker' in navigator) {
        const registration = await navigator.serviceWorker.ready;
        if (registration.pushManager) {
            // Update push subscription state based on preferences
            const subscription = await registration.pushManager.getSubscription();
            if (subscription && !Object.values(preferences).some(Boolean)) {
                await subscription.unsubscribe();
            }
        }
    }
}

// Create singleton instance
export const notificationService = new NotificationService();

// Export class for testing and extended usage
export { NotificationService };