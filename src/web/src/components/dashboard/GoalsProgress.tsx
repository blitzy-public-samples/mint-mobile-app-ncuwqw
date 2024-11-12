// react version: ^18.0.0
// react-redux version: ^8.0.0
// react-native version: ^0.71.0

// Human Tasks:
// 1. Verify goal progress calculations match business requirements
// 2. Test loading states across different network conditions
// 3. Validate accessibility of progress indicators with screen readers
// 4. Review responsive layout behavior on various screen sizes

import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { useSelector } from 'react-redux';
import Card from '../common/Card';
import GoalProgress from '../goals/GoalProgress';
import { 
  selectGoals, 
  selectGoalsLoading, 
  selectGoalsError 
} from '../../store/slices/goalsSlice';

/**
 * Props interface for the GoalsProgress component
 * @requirements Cross-Platform Compatibility - 2.2.1 Client Applications
 */
interface GoalsProgressProps {
  maxGoals?: number;
}

/**
 * A React Native component that displays a summary of financial goals progress
 * @requirements Goal Management - 1.2 Scope/Goal Management
 * @requirements Dashboard UI - 5.1.2 Dashboard Layout
 * @requirements Cross-Platform Compatibility - 2.2.1 Client Applications
 */
const GoalsProgress: React.FC<GoalsProgressProps> = ({ maxGoals = 3 }) => {
  const goals = useSelector(selectGoals);
  const isLoading = useSelector(selectGoalsLoading);
  const error = useSelector(selectGoalsError);

  /**
   * Renders the list of goal progress items
   * @requirements Goal Management - 1.2 Scope/Goal Management
   */
  const renderGoalsList = () => {
    if (!goals || goals.length === 0) {
      return (
        <View style={styles.emptyState}>
          <Text style={styles.emptyStateText}>
            No active goals found. Create a goal to start tracking your progress.
          </Text>
        </View>
      );
    }

    // Sort goals by progress percentage and take top N goals
    const sortedGoals = [...goals]
      .sort((a, b) => 
        (b.currentAmount / b.targetAmount) - (a.currentAmount / a.targetAmount)
      )
      .slice(0, maxGoals);

    return (
      <ScrollView 
        style={styles.goalsList}
        showsVerticalScrollIndicator={false}
      >
        {sortedGoals.map((goal, index) => (
          <View 
            key={goal.id} 
            style={[
              styles.goalItem,
              index < sortedGoals.length - 1 && styles.goalItemMargin
            ]}
          >
            <GoalProgress
              goal={goal}
              showChart={true}
              height={120}
              width={300}
            />
          </View>
        ))}
      </ScrollView>
    );
  };

  if (isLoading) {
    return (
      <Card elevation={1} padding={16}>
        <View style={styles.loadingContainer}>
          <Text>Loading goals progress...</Text>
        </View>
      </Card>
    );
  }

  if (error) {
    return (
      <Card elevation={1} padding={16}>
        <View style={styles.errorContainer}>
          <Text style={styles.errorText}>
            Error loading goals: {error}
          </Text>
        </View>
      </Card>
    );
  }

  return (
    <Card 
      elevation={2}
      padding={16}
      className="goals-progress-card"
    >
      <View style={styles.container}>
        <View style={styles.header}>
          <Text style={styles.title}>Goals Progress</Text>
        </View>
        {renderGoalsList()}
      </View>
    </Card>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    marginVertical: 8,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  title: {
    fontSize: 18,
    fontWeight: '600',
  },
  goalsList: {
    paddingHorizontal: 8,
  },
  goalItem: {
    width: '100%',
  },
  goalItemMargin: {
    marginBottom: 16,
  },
  emptyState: {
    alignItems: 'center',
    padding: 16,
  },
  emptyStateText: {
    fontSize: 16,
    color: 'rgba(0, 0, 0, 0.6)',
    textAlign: 'center',
  },
  errorContainer: {
    alignItems: 'center',
    padding: 16,
  },
  errorText: {
    fontSize: 16,
    color: 'red',
    textAlign: 'center',
  },
  loadingContainer: {
    alignItems: 'center',
    padding: 16,
  },
});

export default GoalsProgress;