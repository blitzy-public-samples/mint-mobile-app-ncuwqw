/**
 * HUMAN TASKS:
 * 1. Set up AWS CloudWatch credentials and access in deployment environment
 * 2. Configure Prometheus server endpoint in environment variables
 * 3. Verify metrics retention policies align with business requirements
 * 4. Set up appropriate IAM roles and permissions for CloudWatch access
 * 5. Configure alerting thresholds and notification channels
 */

// @aws-sdk/client-cloudwatch version: ^3.0.0
import { 
  CloudWatch, 
  PutMetricDataCommand, 
  MetricDatum, 
  Dimension 
} from '@aws-sdk/client-cloudwatch';

// prom-client version: ^14.0.0
import { 
  Registry, 
  Counter, 
  Histogram, 
  Gauge 
} from 'prom-client';

import { AppConfig } from '../../constants/config';

// Environment configuration
const ANALYTICS_ENABLED = process.env.REACT_APP_ANALYTICS_ENABLED === 'true';
const METRICS_ENDPOINT = process.env.REACT_APP_METRICS_ENDPOINT;

// Initialize clients
let cloudWatchClient: CloudWatch;
let prometheusRegistry: Registry;

// Prometheus metrics
let errorCounter: Counter;
let eventCounter: Counter;
let performanceHistogram: Histogram;
let activeUsersGauge: Gauge;

/**
 * Requirement: Performance Monitoring (2.5.1)
 * Initializes analytics services with AWS CloudWatch and Prometheus configurations
 */
export async function initializeAnalytics(config: {
  region: string;
  credentials: {
    accessKeyId: string;
    secretAccessKey: string;
  };
}): Promise<void> {
  if (!ANALYTICS_ENABLED) return;

  try {
    // Initialize CloudWatch
    cloudWatchClient = new CloudWatch({
      region: config.region,
      credentials: config.credentials
    });

    // Initialize Prometheus
    prometheusRegistry = new Registry();
    prometheusRegistry.setDefaultLabels({
      app: AppConfig.APP_NAME,
      version: AppConfig.VERSION
    });

    // Initialize Prometheus metrics
    errorCounter = new Counter({
      name: 'application_errors_total',
      help: 'Total number of application errors',
      labelNames: ['error_type', 'component']
    });

    eventCounter = new Counter({
      name: 'user_events_total',
      help: 'Total number of user events',
      labelNames: ['event_type', 'component']
    });

    performanceHistogram = new Histogram({
      name: 'performance_metrics',
      help: 'Application performance metrics',
      labelNames: ['metric_name', 'component'],
      buckets: [0.1, 0.5, 1, 2, 5, 10]
    });

    activeUsersGauge = new Gauge({
      name: 'active_users',
      help: 'Number of currently active users'
    });

    prometheusRegistry.registerMetric(errorCounter);
    prometheusRegistry.registerMetric(eventCounter);
    prometheusRegistry.registerMetric(performanceHistogram);
    prometheusRegistry.registerMetric(activeUsersGauge);

  } catch (error) {
    console.error('Failed to initialize analytics:', error);
    throw error;
  }
}

/**
 * Requirement: User Activity Tracking (1.2)
 * Tracks application events and user interactions
 */
export async function trackEvent(
  eventName: string,
  eventData: Record<string, any>
): Promise<void> {
  if (!ANALYTICS_ENABLED) return;

  try {
    const timestamp = new Date();
    const enrichedData = {
      ...eventData,
      timestamp,
      appVersion: AppConfig.VERSION,
      eventName
    };

    // Send to CloudWatch
    const metricData: MetricDatum = {
      MetricName: 'UserEvent',
      Timestamp: timestamp,
      Value: 1,
      Unit: 'Count',
      Dimensions: [
        { Name: 'EventName', Value: eventName },
        { Name: 'AppVersion', Value: AppConfig.VERSION }
      ]
    };

    await cloudWatchClient.send(new PutMetricDataCommand({
      Namespace: `${AppConfig.APP_NAME}/Events`,
      MetricData: [metricData]
    }));

    // Record in Prometheus
    eventCounter.inc({
      event_type: eventName,
      component: eventData.component || 'unknown'
    });

  } catch (error) {
    console.error('Failed to track event:', error);
    throw error;
  }
}

/**
 * Requirement: Logging Infrastructure (2.5.1)
 * Tracks application errors and exceptions
 */
export async function trackError(
  error: Error,
  errorContext: Record<string, any>
): Promise<void> {
  if (!ANALYTICS_ENABLED) return;

  try {
    const timestamp = new Date();
    const errorData = {
      name: error.name,
      message: error.message,
      stack: error.stack,
      context: errorContext,
      timestamp,
      appVersion: AppConfig.VERSION
    };

    // Send to CloudWatch
    const metricData: MetricDatum = {
      MetricName: 'ApplicationError',
      Timestamp: timestamp,
      Value: 1,
      Unit: 'Count',
      Dimensions: [
        { Name: 'ErrorType', Value: error.name },
        { Name: 'Component', Value: errorContext.component || 'unknown' },
        { Name: 'AppVersion', Value: AppConfig.VERSION }
      ]
    };

    await cloudWatchClient.send(new PutMetricDataCommand({
      Namespace: `${AppConfig.APP_NAME}/Errors`,
      MetricData: [metricData]
    }));

    // Record in Prometheus
    errorCounter.inc({
      error_type: error.name,
      component: errorContext.component || 'unknown'
    });

  } catch (trackingError) {
    console.error('Failed to track error:', trackingError);
    throw trackingError;
  }
}

/**
 * Requirement: Performance Monitoring (2.5.1)
 * Tracks performance metrics and timings
 */
export async function trackPerformance(
  metricName: string,
  value: number,
  dimensions: Record<string, string>
): Promise<void> {
  if (!ANALYTICS_ENABLED) return;

  try {
    const timestamp = new Date();

    // Format CloudWatch dimensions
    const cloudWatchDimensions: Dimension[] = Object.entries(dimensions).map(
      ([name, value]) => ({ Name: name, Value: value })
    );

    // Send to CloudWatch
    const metricData: MetricDatum = {
      MetricName: metricName,
      Timestamp: timestamp,
      Value: value,
      Unit: 'Milliseconds',
      Dimensions: [
        ...cloudWatchDimensions,
        { Name: 'AppVersion', Value: AppConfig.VERSION }
      ]
    };

    await cloudWatchClient.send(new PutMetricDataCommand({
      Namespace: `${AppConfig.APP_NAME}/Performance`,
      MetricData: [metricData]
    }));

    // Record in Prometheus
    performanceHistogram.observe(
      {
        metric_name: metricName,
        component: dimensions.component || 'unknown'
      },
      value
    );

  } catch (error) {
    console.error('Failed to track performance metric:', error);
    throw error;
  }
}