// react version: ^18.0.0
// react-router-dom version: ^6.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify performance calculation thresholds with finance team
// 2. Test responsiveness on various screen sizes
// 3. Validate accessibility of charts and interactive elements
// 4. Review loading state animations with UX team
// 5. Configure error tracking for API failures

import React, { useEffect, useState } from 'react';
import { View, StyleSheet } from 'react-native';
import { useParams } from 'react-router-dom';

import InvestmentCard from '../../components/investments/InvestmentCard';
import InvestmentChart from '../../components/investments/InvestmentChart';
import PortfolioSummary from '../../components/investments/PortfolioSummary';
import { getInvestmentPerformance } from '../../services/api/investments';

/**
 * Interface for investment detail screen props
 * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
 */
interface InvestmentDetailScreenProps {
  route: {
    params: {
      investmentId: string;
    };
  };
  navigation: {
    goBack: () => void;
  };
}

/**
 * Interface for investment detail state
 * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
 */
interface InvestmentDetailState {
  loading: boolean;
  investment: {
    id: string;
    name: string;
    value: number;
    performance: number;
    holdings: number;
    currency: string;
  } | null;
  performanceData: Array<{ date: string; value: number }>;
  allocationData: Array<{ asset: string; percentage: number }>;
  selectedPeriod: '1D' | '1W' | '1M' | '3M' | '1Y' | 'ALL';
  error: string | null;
}

/**
 * Investment Detail Screen Component
 * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
 * @requirements Investment Tracking - 1.2 Scope/Investment Tracking
 */
const InvestmentDetailScreen: React.FC<InvestmentDetailScreenProps> = ({ route, navigation }) => {
  const { investmentId } = useParams<{ investmentId: string }>();
  
  const [state, setState] = useState<InvestmentDetailState>({
    loading: true,
    investment: null,
    performanceData: [],
    allocationData: [],
    selectedPeriod: '1M',
    error: null
  });

  /**
   * Fetches investment details and performance data
   * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
   */
  const fetchInvestmentData = async (period: '1D' | '1W' | '1M' | '3M' | '1Y' | 'ALL') => {
    try {
      setState(prev => ({ ...prev, loading: true, error: null }));
      
      const response = await getInvestmentPerformance(investmentId, period.toLowerCase() as any);
      
      if (response.data) {
        setState(prev => ({
          ...prev,
          investment: {
            id: investmentId,
            name: response.data.name || '',
            value: response.data.totalValue || 0,
            performance: response.data.returnPercentage || 0,
            holdings: response.data.holdings?.length || 0,
            currency: 'USD'
          },
          performanceData: response.data.performanceData || [],
          allocationData: response.data.holdings?.map(holding => ({
            asset: holding.symbol,
            percentage: (holding.value / response.data.totalValue) * 100
          })) || [],
          loading: false
        }));
      }
    } catch (error) {
      setState(prev => ({
        ...prev,
        loading: false,
        error: 'Failed to load investment data. Please try again.'
      }));
    }
  };

  /**
   * Handles period selection change
   * @requirements Investment Portfolio View - 5.1.5 Investment Portfolio View
   */
  const handlePeriodChange = (period: '1D' | '1W' | '1M' | '3M' | '1Y' | 'ALL') => {
    setState(prev => ({ ...prev, selectedPeriod: period }));
    fetchInvestmentData(period);
  };

  // Initial data fetch on component mount
  useEffect(() => {
    if (investmentId) {
      fetchInvestmentData(state.selectedPeriod);
    }
  }, [investmentId]);

  if (state.error) {
    return (
      <View style={styles.container}>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>{state.error}</Text>
          <Button title="Retry" onPress={() => fetchInvestmentData(state.selectedPeriod)} />
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      {/* Investment Summary Card */}
      {state.investment && (
        <View style={styles.summaryContainer}>
          <InvestmentCard
            id={state.investment.id}
            name={state.investment.name}
            value={state.investment.value}
            performance={state.investment.performance}
            holdings={state.investment.holdings}
            currency={state.investment.currency}
            onClick={() => {}} // Card is not clickable in detail view
          />
        </View>
      )}

      {/* Performance Chart */}
      <View style={styles.chartContainer}>
        <InvestmentChart
          data={state.performanceData}
          type="performance"
          period={state.selectedPeriod}
          loading={state.loading}
        />
      </View>

      {/* Portfolio Summary */}
      {state.investment && (
        <View style={styles.portfolioContainer}>
          <PortfolioSummary
            totalValue={state.investment.value}
            performance={state.investment.performance}
            allocationData={state.allocationData}
            performanceData={state.performanceData}
            period={state.selectedPeriod}
            currency={state.investment.currency}
            loading={state.loading}
          />
        </View>
      )}
    </View>
  );
};

/**
 * Styles for the investment detail screen
 * @requirements Cross-Platform UI - 2.2.1 Client Applications/React Native
 */
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: 'theme.colors.background',
    padding: 'theme.spacing.md'
  },
  summaryContainer: {
    marginBottom: 'theme.spacing.lg'
  },
  chartContainer: {
    marginVertical: 'theme.spacing.md',
    height: 300
  },
  portfolioContainer: {
    marginTop: 'theme.spacing.lg'
  },
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 'theme.spacing.lg'
  },
  errorText: {
    color: 'theme.colors.error',
    marginBottom: 'theme.spacing.md',
    textAlign: 'center'
  }
});

export default InvestmentDetailScreen;