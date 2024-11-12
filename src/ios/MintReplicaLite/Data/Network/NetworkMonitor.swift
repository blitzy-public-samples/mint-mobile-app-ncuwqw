//
// NetworkMonitor.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify minimum iOS version (14.0+) requirement in project settings
// 2. Configure background task handling for network monitoring in capabilities
// 3. Review and adjust dispatch queue QoS level based on production metrics
// 4. Test network transitions with different carrier and WiFi configurations

// Network framework - iOS 14.0+
import Network
// Foundation framework - iOS 14.0+
import Foundation
// Combine framework - iOS 14.0+
import Combine

// Import relative to current file location
import ../../../Common/Utils/Logger

/// Defines different types of network connections
/// Implements Network Reachability requirement from Section 2.2.1
public enum ConnectionType {
    case wifi
    case cellular
    case ethernet
    case unknown
    
    public var description: String {
        switch self {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .ethernet:
            return "Ethernet"
        case .unknown:
            return "Unknown"
        }
    }
}

/// Notification name for connectivity status changes
extension NSNotification.Name {
    static let connectivityStatusChanged = NSNotification.Name("NetworkMonitorConnectivityStatusChanged")
}

/// Main class responsible for monitoring network connectivity
/// Implements Network Reachability requirement from Section 2.2.1 and
/// Real-time Synchronization requirement from Section 1.1
public final class NetworkMonitor {
    // MARK: - Properties
    
    /// Shared singleton instance
    public static let shared = NetworkMonitor()
    
    /// The underlying NWPathMonitor instance
    private let monitor: NWPathMonitor
    
    /// Dedicated dispatch queue for network monitoring
    private let monitorQueue: DispatchQueue
    
    /// Publisher for current connection status
    public let isConnected: CurrentValueSubject<Bool, Never>
    
    /// Publisher for current connection type
    public let connectionType: CurrentValueSubject<ConnectionType, Never>
    
    /// Flag indicating if monitoring is active
    private(set) var isMonitoring: Bool
    
    // MARK: - Initialization
    
    private init() {
        self.monitor = NWPathMonitor()
        self.monitorQueue = DispatchQueue(label: "com.mintreplicalite.networkmonitor", qos: .utility)
        self.isConnected = CurrentValueSubject<Bool, Never>(false)
        self.connectionType = CurrentValueSubject<ConnectionType, Never>(.unknown)
        self.isMonitoring = false
        
        setupPathUpdateHandler()
    }
    
    // MARK: - Private Methods
    
    private func setupPathUpdateHandler() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.handlePathUpdate(path)
        }
    }
    
    /// Handles network path status changes
    /// Implements Real-time Synchronization requirement from Section 1.1
    private func handlePathUpdate(_ path: NWPath) {
        // Determine connection status
        let isConnected = path.status == .satisfied
        let previousConnectionType = connectionType.value
        
        // Determine connection type
        let newConnectionType: ConnectionType
        if path.usesInterfaceType(.wifi) {
            newConnectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            newConnectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            newConnectionType = .ethernet
        } else {
            newConnectionType = .unknown
        }
        
        // Update publishers
        self.isConnected.send(isConnected)
        self.connectionType.send(newConnectionType)
        
        // Log connectivity change
        Logger.shared.log(
            "Network status changed - Connected: \(isConnected), Type: \(newConnectionType.description)",
            level: .info,
            category: .network
        )
        
        // Post notification for observers
        NotificationCenter.default.post(
            name: .connectivityStatusChanged,
            object: self,
            userInfo: [
                "isConnected": isConnected,
                "connectionType": newConnectionType,
                "previousConnectionType": previousConnectionType
            ]
        )
    }
    
    // MARK: - Public Methods
    
    /// Begins monitoring network reachability
    /// Implements Network Reachability requirement from Section 2.2.1
    public func startMonitoring() {
        guard !isMonitoring else {
            Logger.shared.log(
                "Network monitoring already active",
                level: .warning,
                category: .network
            )
            return
        }
        
        monitor.start(queue: monitorQueue)
        isMonitoring = true
        
        Logger.shared.log(
            "Network monitoring started",
            level: .info,
            category: .network
        )
    }
    
    /// Stops monitoring network reachability
    public func stopMonitoring() {
        guard isMonitoring else {
            Logger.shared.log(
                "Network monitoring already inactive",
                level: .warning,
                category: .network
            )
            return
        }
        
        monitor.cancel()
        isMonitoring = false
        
        Logger.shared.log(
            "Network monitoring stopped",
            level: .info,
            category: .network
        )
    }
}