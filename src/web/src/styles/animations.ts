// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify animation performance on lower-end mobile devices
// 2. Test animation timing across different screen sizes
// 3. Validate animation curves with design team
// 4. Ensure animations can be disabled for reduced motion preferences

import { Animated, Easing } from 'react-native'; // ^0.71.0
import { card } from '../constants/styles';

// Animation duration constants (in milliseconds)
const ANIMATION_DURATION_FAST = 150;
const ANIMATION_DURATION_NORMAL = 300;
const ANIMATION_DURATION_SLOW = 500;

// Default spring animation configuration
const SPRING_CONFIG_DEFAULT = {
  damping: 20,
  stiffness: 90,
};

/**
 * Creates a fade animation configuration
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
const createFadeAnimation = (
  duration: number,
  isVisible: boolean
): { value: Animated.Value; timing: Animated.CompositeAnimation } => {
  const value = new Animated.Value(isVisible ? 1 : 0);
  
  const timing = Animated.timing(value, {
    toValue: isVisible ? 1 : 0,
    duration,
    easing: Easing.inOut(Easing.ease),
    useNativeDriver: true,
  });

  return { value, timing };
};

/**
 * Creates a slide animation configuration
 * @requirements Progressive Enhancement - 5.1.7 Platform-Specific Implementation Notes/Web
 */
const createSlideAnimation = (
  duration: number,
  direction: 'up' | 'down' | 'left' | 'right',
  distance: number
): { value: Animated.Value; timing: Animated.CompositeAnimation; transform: any } => {
  const value = new Animated.Value(0);
  
  const getTransform = () => {
    switch (direction) {
      case 'up':
        return [{ translateY: value.interpolate({
          inputRange: [0, 1],
          outputRange: [distance, 0],
        })}];
      case 'down':
        return [{ translateY: value.interpolate({
          inputRange: [0, 1],
          outputRange: [-distance, 0],
        })}];
      case 'left':
        return [{ translateX: value.interpolate({
          inputRange: [0, 1],
          outputRange: [distance, 0],
        })}];
      case 'right':
        return [{ translateX: value.interpolate({
          inputRange: [0, 1],
          outputRange: [-distance, 0],
        })}];
    }
  };

  const timing = Animated.timing(value, {
    toValue: 1,
    duration,
    easing: Easing.out(Easing.cubic),
    useNativeDriver: true,
  });

  return { value, timing, transform: getTransform() };
};

/**
 * Creates chart animation configuration with spring physics
 * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
 */
const createChartAnimation = (
  dataPoints: number[],
  config: Partial<typeof SPRING_CONFIG_DEFAULT> = {}
): { values: Animated.Value[]; springs: Animated.CompositeAnimation[] } => {
  const springConfig = {
    ...SPRING_CONFIG_DEFAULT,
    ...config,
  };

  const values = dataPoints.map(() => new Animated.Value(0));
  
  const springs = values.map((value, index) =>
    Animated.spring(value, {
      toValue: dataPoints[index],
      ...springConfig,
      useNativeDriver: true,
    })
  );

  return { values, springs };
};

/**
 * Fade animation presets
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const fadeIn = {
  animation: (callback?: () => void) => {
    const { value, timing } = createFadeAnimation(ANIMATION_DURATION_NORMAL, true);
    if (callback) timing.start(callback);
    return timing;
  },
  style: (value: Animated.Value) => ({
    opacity: value,
  }),
};

export const fadeOut = {
  animation: (callback?: () => void) => {
    const { value, timing } = createFadeAnimation(ANIMATION_DURATION_NORMAL, false);
    if (callback) timing.start(callback);
    return timing;
  },
  style: (value: Animated.Value) => ({
    opacity: value,
  }),
};

/**
 * Slide animation presets
 * @requirements Progressive Enhancement - 5.1.7 Platform-Specific Implementation Notes/Web
 */
export const slideUp = {
  animation: (callback?: () => void) => {
    const { value, timing } = createSlideAnimation(ANIMATION_DURATION_NORMAL, 'up', 100);
    if (callback) timing.start(callback);
    return timing;
  },
  style: (value: Animated.Value) => ({
    transform: [{ 
      translateY: value.interpolate({
        inputRange: [0, 1],
        outputRange: [100, 0],
      }),
    }],
  }),
};

export const slideDown = {
  animation: (callback?: () => void) => {
    const { value, timing } = createSlideAnimation(ANIMATION_DURATION_NORMAL, 'down', 100);
    if (callback) timing.start(callback);
    return timing;
  },
  style: (value: Animated.Value) => ({
    transform: [{ 
      translateY: value.interpolate({
        inputRange: [0, 1],
        outputRange: [-100, 0],
      }),
    }],
  }),
};

/**
 * Chart animation configurations
 * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
 */
export const chartAnimations = {
  dataPoint: (value: number, config?: Partial<typeof SPRING_CONFIG_DEFAULT>) => {
    const { values, springs } = createChartAnimation([value], config);
    return {
      animation: springs[0],
      style: {
        transform: [{ scale: values[0] }],
      },
    };
  },
  series: (dataPoints: number[], config?: Partial<typeof SPRING_CONFIG_DEFAULT>) => {
    const { values, springs } = createChartAnimation(dataPoints, config);
    return {
      animations: springs,
      styles: values.map(value => ({
        transform: [{ scale: value }],
      })),
    };
  },
};