//
// NetworkReachability.swift
// MintReplicaLite
//
// Human Tasks:
// 1. Ensure Network framework capability is enabled in project settings
// 2. Add "Privacy - Local Network Usage Description" to Info.plist if testing on physical devices
// 3. Configure minimum deployment target to iOS 14.0 or later

import Foundation // iOS 14.0+
import Network   // iOS 14.0+
import Combine   // iOS 14.0+

// MARK: - Notifications
extension Notification.Name {
    // Requirement: Real-time Data Flows (3.3.3)
    // Notification for broadcasting network status changes throughout the app
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}

// MARK: - Network Status Enum
// Requirement: Network Monitoring (2.5.1)
// Represents possible network connectivity states
@objc public enum NetworkStatus: String {
    case available
    case unavailable
    case unknown
}

// MARK: - Network Type Enum
// Requirement: Network Monitoring (2.5.1)
// Represents different types of network interfaces
@objc public enum NetworkType: String {
    case wifi
    case cellular
    case ethernet
    case other
    case none
}

// MARK: - NetworkReachability Class
// Requirement: iOS Platform Support (4.1)
// Singleton class for monitoring network connectivity using NWPathMonitor
@objc final public class NetworkReachability: NSObject {
    
    // MARK: - Singleton Instance
    public static let shared = NetworkReachability()
    
    // MARK: - Private Properties
    private let pathMonitor: NWPathMonitor
    private let monitorQueue: DispatchQueue
    private(set) var status: CurrentValueSubject<NetworkStatus, Never>
    private(set) var networkType: CurrentValueSubject<NetworkType, Never>
    private(set) var isMonitoring: Bool
    
    // MARK: - Initialization
    private override init() {
        // Initialize NWPathMonitor with default parameters
        self.pathMonitor = NWPathMonitor()
        
        // Create dedicated serial dispatch queue for monitoring
        self.monitorQueue = DispatchQueue(label: "com.mintReplica.network.monitor", qos: .utility)
        
        // Initialize status with unknown state
        self.status = CurrentValueSubject<NetworkStatus, Never>(.unknown)
        
        // Initialize network type with none
        self.networkType = CurrentValueSubject<NetworkType, Never>(.none)
        
        // Set initial monitoring state
        self.isMonitoring = false
        
        super.init()
    }
    
    // MARK: - Public Methods
    
    // Requirement: Real-time Data Flows (3.3.3)
    // Starts monitoring network reachability on dedicated queue
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            
            // Update network status
            let newStatus: NetworkStatus = path.status == .satisfied ? .available : .unavailable
            self.status.send(newStatus)
            
            // Determine network type
            let newNetworkType: NetworkType
            if path.usesInterfaceType(.wifi) {
                newNetworkType = .wifi
            } else if path.usesInterfaceType(.cellular) {
                newNetworkType = .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                newNetworkType = .ethernet
            } else if path.status == .satisfied {
                newNetworkType = .other
            } else {
                newNetworkType = .none
            }
            self.networkType.send(newNetworkType)
            
            // Post notification for observers
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .networkStatusChanged, object: self)
            }
        }
        
        // Start monitoring on dedicated queue
        pathMonitor.start(queue: monitorQueue)
        isMonitoring = true
    }
    
    // Requirement: Network Monitoring (2.5.1)
    // Stops network reachability monitoring and cleans up resources
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        pathMonitor.cancel()
        status.send(.unknown)
        networkType.send(.none)
        isMonitoring = false
        
        // Post notification for observers
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .networkStatusChanged, object: self)
        }
    }
    
    // Requirement: Network Monitoring (2.5.1)
    // Checks if network is currently reachable
    public func isReachable() -> Bool {
        return status.value == .available
    }
    
    // Requirement: Network Monitoring (2.5.1)
    // Gets current network connectivity status
    public func currentStatus() -> NetworkStatus {
        return status.value
    }
    
    // Requirement: Network Monitoring (2.5.1)
    // Gets current network interface type
    public func currentNetworkType() -> NetworkType {
        return networkType.value
    }
    
    // MARK: - Deinitializer
    deinit {
        if isMonitoring {
            stopMonitoring()
        }
    }
}