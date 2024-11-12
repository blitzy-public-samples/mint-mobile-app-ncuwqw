//
// SyncServiceTests.swift
// MintReplicaLiteTests
//

import XCTest // iOS 14.0+
import Combine // iOS 14.0+
@testable import MintReplicaLite

/// Test suite for SyncService functionality
/// Validates requirements from:
/// - Cross-platform data synchronization (Section 1.2 Scope/Account Management)
/// - Real-time balance updates (Section 1.2 Scope/Account Management)
/// - Automated transaction import (Section 1.2 Scope/Financial Tracking)
final class SyncServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: SyncService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Test Lifecycle
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        sut = SyncService.shared
        
        // Clear test database
        CoreDataManager.shared.clearDatabase()
        
        // Reset API client state
        APIClient.shared.request(.getAccounts, responseType: AccountSyncResponse.self)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &cancellables)
    }
    
    override func tearDown() {
        sut.stopAutoSync()
        CoreDataManager.shared.clearDatabase()
        cancellables.removeAll()
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    /// Tests successful manual sync operation
    /// Validates real-time balance updates requirement
    func testStartSync_Success() {
        // Given
        let syncExpectation = expectation(description: "Sync should complete successfully")
        let mockAccounts = [
            AccountData(id: "acc1", name: "Checking", type: "checking", balance: 1000.0),
            AccountData(id: "acc2", name: "Savings", type: "savings", balance: 5000.0)
        ]
        let mockTransactions = [
            TransactionData(id: "tx1", amount: 100.0, date: Date(), description: "Test", category: "food", accountId: "acc1", modificationDate: Date())
        ]
        
        // When
        sut.startSync()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        syncExpectation.fulfill()
                    case .failure(let error):
                        XCTFail("Sync failed with error: \(error)")
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Test timed out")
            
            // Verify accounts were synced
            CoreDataManager.shared.performBackgroundTask { context in
                let accountsFetch = NSFetchRequest<Account>(entityName: "Account")
                let accounts = try? context.fetch(accountsFetch)
                XCTAssertEqual(accounts?.count, mockAccounts.count)
                
                // Verify transactions were synced
                let transactionsFetch = NSFetchRequest<Transaction>(entityName: "Transaction")
                let transactions = try? context.fetch(transactionsFetch)
                XCTAssertEqual(transactions?.count, mockTransactions.count)
            }
        }
    }
    
    /// Tests sync operation failure handling
    func testStartSync_Failure() {
        // Given
        let errorExpectation = expectation(description: "Sync should fail with error")
        let mockError = APIError.serverError(500, "Internal Server Error")
        
        // When
        sut.startSync()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Sync should have failed")
                    case .failure(let error):
                        XCTAssertNotNil(error)
                        errorExpectation.fulfill()
                    }
                },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: 5.0) { error in
            XCTAssertNil(error, "Test timed out")
            
            // Verify database wasn't modified
            CoreDataManager.shared.performBackgroundTask { context in
                let accountsFetch = NSFetchRequest<Account>(entityName: "Account")
                let accounts = try? context.fetch(accountsFetch)
                XCTAssertEqual(accounts?.count, 0)
            }
        }
    }
    
    /// Tests automatic background sync functionality
    /// Validates cross-platform data synchronization requirement
    func testAutoSync() {
        // Given
        let syncExpectation = expectation(description: "Auto sync should complete multiple cycles")
        syncExpectation.expectedFulfillmentCount = 2
        let interval: TimeInterval = 2.0
        
        // When
        sut.startAutoSync(interval: interval)
        
        // Monitor sync completions
        var syncCount = 0
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { _ in
                syncCount += 1
                if syncCount >= 2 {
                    syncExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Then
        waitForExpectations(timeout: interval * 3) { error in
            XCTAssertNil(error, "Test timed out")
            XCTAssertGreaterThanOrEqual(syncCount, 2, "Should complete at least 2 sync cycles")
            
            // Verify sync state
            CoreDataManager.shared.performBackgroundTask { context in
                let accountsFetch = NSFetchRequest<Account>(entityName: "Account")
                let accounts = try? context.fetch(accountsFetch)
                XCTAssertNotNil(accounts)
            }
        }
    }
    
    /// Tests stopping automatic sync functionality
    func testStopAutoSync() {
        // Given
        let syncExpectation = expectation(description: "Auto sync should stop")
        let interval: TimeInterval = 1.0
        
        // When
        sut.startAutoSync(interval: interval)
        
        // Monitor sync activity
        var syncCount = 0
        NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)
            .sink { _ in
                syncCount += 1
            }
            .store(in: &cancellables)
        
        // Stop auto-sync after first cycle
        DispatchQueue.main.asyncAfter(deadline: .now() + interval * 1.5) {
            self.sut.stopAutoSync()
            
            // Wait to verify no more syncs occur
            DispatchQueue.main.asyncAfter(deadline: .now() + interval * 2) {
                syncExpectation.fulfill()
            }
        }
        
        // Then
        waitForExpectations(timeout: interval * 4) { error in
            XCTAssertNil(error, "Test timed out")
            XCTAssertLessThanOrEqual(syncCount, 2, "Should not continue syncing after stop")
            
            // Verify cancellables were cleaned up
            XCTAssertTrue(self.cancellables.count <= 1, "Should remove sync subscriptions")
        }
    }
}