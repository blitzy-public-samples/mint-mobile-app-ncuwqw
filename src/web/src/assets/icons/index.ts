// react-native-svg version: ^13.0.0
// react version: ^18.0.0

// Human Tasks:
// 1. Verify all SVG assets are properly optimized and minified
// 2. Ensure SVG assets meet accessibility guidelines for minimum tap target sizes
// 3. Test icon rendering across different device resolutions and pixel densities
// 4. Validate icon color contrast ratios in both light and dark themes

import React from 'react';
import { ViewStyle } from 'react-native';
import { Svg, SvgProps } from 'react-native-svg';
import { shared } from '../../constants/colors';

// Global constants for standardized icon sizing and coloring
const DEFAULT_ICON_SIZE = 24;
const DEFAULT_ICON_COLOR = shared.secondary.main;

// Standard interface for all icon components
interface IconProps extends SvgProps {
  size?: number;
  color?: string;
  style?: ViewStyle;
}

/**
 * Creates a standardized icon component with consistent props and styling
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const createIcon = (SvgComponent: React.ComponentType<SvgProps>, defaultProps?: Partial<IconProps>): React.FC<IconProps> => {
  return ({ size = DEFAULT_ICON_SIZE, color = DEFAULT_ICON_COLOR, style, ...props }: IconProps) => {
    return (
      <SvgComponent
        width={size}
        height={size}
        color={color}
        style={style}
        {...defaultProps}
        {...props}
      />
    );
  };
};

/**
 * Navigation icons for app-wide navigation
 * @requirements Mobile-Specific Adaptations - 5.1.6 Mobile-Specific Adaptations
 */
export const NavigationIcons = {
  home: createIcon(require('./navigation/home.svg')),
  transactions: createIcon(require('./navigation/transactions.svg')),
  budgets: createIcon(require('./navigation/budgets.svg')),
  goals: createIcon(require('./navigation/goals.svg')),
  investments: createIcon(require('./navigation/investments.svg')),
  settings: createIcon(require('./navigation/settings.svg'))
};

/**
 * Action icons for common user interactions
 * @requirements Cross-Platform UI Consistency - 2.2.1 Client Applications/React Native
 */
export const ActionIcons = {
  add: createIcon(require('./actions/add.svg')),
  edit: createIcon(require('./actions/edit.svg')),
  delete: createIcon(require('./actions/delete.svg')),
  sync: createIcon(require('./actions/sync.svg')),
  filter: createIcon(require('./actions/filter.svg')),
  search: createIcon(require('./actions/search.svg'))
};

/**
 * Financial category and type icons
 * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
 */
export const FinancialIcons = {
  wallet: createIcon(require('./financial/wallet.svg')),
  creditCard: createIcon(require('./financial/credit-card.svg')),
  bankAccount: createIcon(require('./financial/bank-account.svg')),
  investment: createIcon(require('./financial/investment.svg')),
  budget: createIcon(require('./financial/budget.svg')),
  goal: createIcon(require('./financial/goal.svg'))
};

/**
 * Status and notification icons with semantic colors
 * @requirements Financial Data Visualization - 5.1.5 Investment Portfolio View
 */
export const StatusIcons = {
  success: createIcon(require('./status/success.svg'), { color: shared.success.main }),
  warning: createIcon(require('./status/warning.svg'), { color: shared.warning.main }),
  error: createIcon(require('./status/error.svg'), { color: shared.error.main }),
  info: createIcon(require('./status/info.svg'), { color: shared.info.main })
};

// Re-export createIcon utility for custom icon creation
export { createIcon };