/**
 * HUMAN TASKS:
 * 1. Ensure AWS CloudWatch credentials are properly configured in the deployment environment
 * 2. Verify Prometheus endpoint is accessible and metrics are being collected
 * 3. Set up appropriate IAM roles for CloudWatch access
 * 4. Configure retention periods for metrics data
 * 5. Set up monitoring dashboards and alerts in AWS CloudWatch
 */

import { AppConfig } from '../constants/config';
import { 
  trackEvent, 
  trackError as trackErrorBase, 
  trackPerformance as trackPerformanceBase 
} from '../services/analytics';

/**
 * Requirement: User Activity Tracking (1.2)
 * Tracks page view events with standardized context and error handling
 */
export async function logPageView(
  pageName: string,
  additionalData: Record<string, any> = {}
): Promise<void> {
  if (!pageName || typeof pageName !== 'string') {
    throw new Error('Invalid page name provided');
  }

  try {
    const eventData = {
      ...additionalData,
      page: pageName,
      timestamp: new Date().toISOString(),
      appName: AppConfig.APP_NAME,
      appVersion: AppConfig.VERSION,
      sessionId: getSessionId(),
      component: 'page_view'
    };

    await trackEvent('PAGE_VIEW', eventData);
  } catch (error) {
    console.error(`Failed to log page view for ${pageName}:`, error);
    throw error;
  }
}

/**
 * Requirement: User Activity Tracking (1.2)
 * Tracks user interaction events with proper context
 */
export async function logUserAction(
  actionName: string,
  actionData: Record<string, any> = {}
): Promise<void> {
  if (!actionName || typeof actionName !== 'string') {
    throw new Error('Invalid action name provided');
  }

  try {
    const enrichedData = {
      ...actionData,
      action: actionName,
      timestamp: new Date().toISOString(),
      appName: AppConfig.APP_NAME,
      appVersion: AppConfig.VERSION,
      sessionId: getSessionId(),
      component: actionData.component || 'user_action'
    };

    await trackEvent('USER_ACTION', enrichedData);
  } catch (error) {
    console.error(`Failed to log user action ${actionName}:`, error);
    throw error;
  }
}

/**
 * Requirement: Performance Monitoring (2.5.1)
 * Tracks application errors with full stack traces and context
 */
export async function logError(
  error: Error,
  errorContext: string
): Promise<void> {
  if (!(error instanceof Error)) {
    throw new Error('Invalid error object provided');
  }

  try {
    const enrichedContext = {
      context: errorContext,
      timestamp: new Date().toISOString(),
      appName: AppConfig.APP_NAME,
      appVersion: AppConfig.VERSION,
      component: 'error_tracking',
      sessionId: getSessionId(),
      environment: process.env.NODE_ENV,
      severity: getSeverityLevel(error),
      source: 'client'
    };

    await trackErrorBase(error, enrichedContext);
  } catch (trackingError) {
    console.error('Failed to log error:', trackingError);
    throw trackingError;
  }
}

/**
 * Requirement: Performance Monitoring (2.5.1)
 * Tracks performance and business metrics with dimensions
 */
export async function logMetric(
  metricName: string,
  value: number,
  tags: Record<string, string> = {}
): Promise<void> {
  if (!metricName || typeof metricName !== 'string') {
    throw new Error('Invalid metric name provided');
  }

  if (typeof value !== 'number' || isNaN(value)) {
    throw new Error('Invalid metric value provided');
  }

  try {
    const enrichedTags = {
      ...tags,
      appName: AppConfig.APP_NAME,
      appVersion: AppConfig.VERSION,
      environment: process.env.NODE_ENV,
      component: tags.component || 'metrics'
    };

    await trackPerformanceBase(metricName, value, enrichedTags);
  } catch (error) {
    console.error(`Failed to log metric ${metricName}:`, error);
    throw error;
  }
}

// Helper function to get or generate session ID
function getSessionId(): string {
  let sessionId = sessionStorage.getItem('analytics_session_id');
  if (!sessionId) {
    sessionId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    sessionStorage.setItem('analytics_session_id', sessionId);
  }
  return sessionId;
}

// Helper function to determine error severity
function getSeverityLevel(error: Error): string {
  if (error instanceof TypeError || error instanceof ReferenceError) {
    return 'high';
  } else if (error instanceof SyntaxError) {
    return 'critical';
  } else {
    return 'medium';
  }
}