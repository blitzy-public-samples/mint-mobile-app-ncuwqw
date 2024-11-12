/**
 * HUMAN TASKS:
 * 1. Configure Redux DevTools browser extension in development environment
 * 2. Set up error tracking service integration for Redux state errors
 * 3. Configure performance monitoring for Redux state updates
 * 4. Verify Redux persist storage configuration for offline support
 */

// @reduxjs/toolkit version: ^1.9.5
import { configureStore, combineReducers } from '@reduxjs/toolkit';
// redux-persist version: ^6.0.0
import { 
  persistStore, 
  persistReducer,
  FLUSH,
  REHYDRATE,
  PAUSE,
  PERSIST,
  PURGE,
  REGISTER
} from 'redux-persist';
// @react-native-async-storage/async-storage version: ^1.19.0
import AsyncStorage from '@react-native-async-storage/async-storage';

// Import reducers
import accountsReducer from './slices/accountsSlice';
import authReducer from './slices/authSlice';
import budgetsReducer from './slices/budgetsSlice';
import goalsReducer from './slices/goalsSlice';
import investmentsReducer from './slices/investmentsSlice';
import transactionsReducer from './slices/transactionsSlice';
import uiReducer from './slices/uiSlice';

// Requirement: State Management - Configure Redux persist for offline data access
const persistConfig = {
  key: 'root',
  storage: AsyncStorage,
  whitelist: ['auth', 'accounts', 'transactions', 'budgets', 'goals', 'investments'],
  blacklist: ['ui'] // UI state should not be persisted
};

// Combine all reducers
const rootReducer = combineReducers({
  accounts: accountsReducer,
  auth: authReducer,
  budgets: budgetsReducer,
  goals: goalsReducer,
  investments: investmentsReducer,
  transactions: transactionsReducer,
  ui: uiReducer
});

// Create persisted reducer
const persistedReducer = persistReducer(persistConfig, rootReducer);

// Requirement: State Management - Configure Redux store with middleware and enhancers
const setupStore = () => {
  const store = configureStore({
    reducer: persistedReducer,
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware({
        serializableCheck: {
          ignoredActions: [FLUSH, REHYDRATE, PAUSE, PERSIST, PURGE, REGISTER],
        },
      }),
    devTools: process.env.NODE_ENV !== 'production',
  });

  // Enable hot module replacement for reducers in development
  if (process.env.NODE_ENV !== 'production' && module.hot) {
    module.hot.accept('./slices/accountsSlice', () => store.replaceReducer(persistedReducer));
    module.hot.accept('./slices/authSlice', () => store.replaceReducer(persistedReducer));
    module.hot.accept('./slices/budgetsSlice', () => store.replaceReducer(persistedReducer));
    module.hot.accept('./slices/goalsSlice', () => store.replaceReducer(persistedReducer));
    module.hot.accept('./slices/investmentsSlice', () => store.replaceReducer(persistedReducer));
    module.hot.accept('./slices/transactionsSlice', () => store.replaceReducer(persistedReducer));
    module.hot.accept('./slices/uiSlice', () => store.replaceReducer(persistedReducer));
  }

  return store;
};

// Create store instance
export const store = setupStore();

// Create persistor
export const persistor = persistStore(store);

// Requirement: Cross-Platform Data Synchronization - Export types for TypeScript support
export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;