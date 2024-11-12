/**
 * HUMAN TASKS:
 * 1. Verify API endpoint configuration for investment data providers
 * 2. Set up monitoring for investment data sync performance
 * 3. Configure rate limits for investment API endpoints
 * 4. Set up alerts for investment performance thresholds
 */

// axios version: ^0.24.0
import { AxiosResponse } from 'axios';
import { apiInstance, handleApiError } from '../utils/api';
import { 
    Account, 
    AccountType, 
    Transaction, 
    APIResponse, 
    APIError 
} from '../../types';

/**
 * Interface for investment account data
 * Requirement: Investment Tracking - Basic portfolio monitoring
 */
export interface Investment {
    id: string;
    accountId: string;
    symbol: string;
    name: string;
    quantity: number;
    currentPrice: number;
    totalValue: number;
    costBasis: number;
    returnAmount: number;
    returnPercentage: number;
    lastUpdated: Date;
}

/**
 * Interface for portfolio summary data
 * Requirement: Investment Tracking - Basic portfolio monitoring
 */
export interface PortfolioSummary {
    totalValue: number;
    totalCostBasis: number;
    totalReturn: number;
    totalReturnPercentage: number;
    holdings: Investment[];
}

/**
 * Interface for investment performance data
 * Requirement: Performance Metrics - Simple performance metrics tracking
 */
export interface PerformanceMetrics {
    returnAmount: number;
    returnPercentage: number;
    period: string;
    startDate: Date;
    endDate: Date;
}

/**
 * Retrieves all investment accounts for the authenticated user
 * Requirement: Investment Tracking - Investment account integration
 */
export async function getInvestmentAccounts(): Promise<APIResponse<Account[]>> {
    try {
        const response = await apiInstance.get<APIResponse<Account[]>>('/api/v1/investments/accounts');
        const accounts = response.data.filter(account => account.type === AccountType.INVESTMENT);
        return {
            data: accounts,
            status: 200,
            message: 'Investment accounts retrieved successfully',
            timestamp: new Date()
        };
    } catch (error) {
        throw handleApiError(error);
    }
}

/**
 * Retrieves portfolio summary including total value and performance metrics
 * Requirement: Investment Tracking - Basic portfolio monitoring
 */
export async function getPortfolioSummary(): Promise<APIResponse<PortfolioSummary>> {
    try {
        const response = await apiInstance.get<APIResponse<PortfolioSummary>>('/api/v1/investments/portfolio');
        return {
            data: response.data,
            status: 200,
            message: 'Portfolio summary retrieved successfully',
            timestamp: new Date()
        };
    } catch (error) {
        throw handleApiError(error);
    }
}

/**
 * Retrieves investment transactions with optional filtering
 * Requirement: Transaction Categorization - Investment transaction categorization
 */
export async function getInvestmentTransactions(
    accountId: string,
    filters?: {
        startDate?: Date;
        endDate?: Date;
        type?: string;
        symbol?: string;
    }
): Promise<APIResponse<Transaction[]>> {
    try {
        if (!accountId) {
            throw new Error('Account ID is required');
        }

        const queryParams = new URLSearchParams();
        queryParams.append('accountId', accountId);

        if (filters) {
            if (filters.startDate) {
                queryParams.append('startDate', filters.startDate.toISOString());
            }
            if (filters.endDate) {
                queryParams.append('endDate', filters.endDate.toISOString());
            }
            if (filters.type) {
                queryParams.append('type', filters.type);
            }
            if (filters.symbol) {
                queryParams.append('symbol', filters.symbol);
            }
        }

        const response = await apiInstance.get<APIResponse<Transaction[]>>(
            `/api/v1/investments/transactions?${queryParams.toString()}`
        );

        return {
            data: response.data,
            status: 200,
            message: 'Investment transactions retrieved successfully',
            timestamp: new Date()
        };
    } catch (error) {
        throw handleApiError(error);
    }
}

/**
 * Retrieves performance metrics for specific investment or entire portfolio
 * Requirement: Performance Metrics - Simple performance metrics tracking
 */
export async function getInvestmentPerformance(
    investmentId: string,
    period: '1d' | '1w' | '1m' | '3m' | '6m' | '1y' | 'ytd' | 'all'
): Promise<APIResponse<PerformanceMetrics>> {
    try {
        if (!investmentId) {
            throw new Error('Investment ID is required');
        }

        const validPeriods = ['1d', '1w', '1m', '3m', '6m', '1y', 'ytd', 'all'];
        if (!validPeriods.includes(period)) {
            throw new Error('Invalid period specified');
        }

        const response = await apiInstance.get<APIResponse<PerformanceMetrics>>(
            `/api/v1/investments/performance`,
            {
                params: {
                    investmentId,
                    period
                }
            }
        );

        return {
            data: response.data,
            status: 200,
            message: 'Investment performance metrics retrieved successfully',
            timestamp: new Date()
        };
    } catch (error) {
        throw handleApiError(error);
    }
}