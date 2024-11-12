//
// Logger.swift
// MintReplicaLite
//
// HUMAN TASKS:
// 1. Verify log file permissions in production environment
// 2. Configure log rotation size limits based on device storage analysis
// 3. Set up ELK Stack endpoints for log forwarding
// 4. Review log retention policies with compliance team
// 5. Validate logging performance impact in production scenarios

// Foundation framework - iOS 14.0+
import Foundation
// OS Logging framework - iOS 14.0+
import os.log
// Internal imports
import Common.Constants.AppConstants

/// Defines different severity levels for logging with associated emoji indicators
/// Implements Security Controls/Audit Logging requirement from Section 6.3.3
enum LogLevel: String {
    case debug
    case info
    case warning
    case error
    case critical
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

/// Categorizes logs for better organization and filtering
/// Implements System Monitoring and Logging requirement from Section 2.5.1
enum LogCategory: String {
    case network
    case security
    case database
    case sync
    case userAction
    case performance
    case general
}

/// Main logging class that handles all logging operations with thread safety
/// Implements System Monitoring and Logging requirement from Section 2.5.1
final class Logger {
    // MARK: - Properties
    
    private let osLog: OSLog
    private var fileHandle: FileHandle?
    private let logFilePath: String
    private let loggingQueue: DispatchQueue
    private let isDebugMode: Bool
    private var enabledLevels: Set<LogLevel>
    
    // Constants
    private enum Constants {
        static let maxLogFileSize = 10 * 1024 * 1024 // 10MB
        static let logRetentionDays = 7
        static let dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        static let logFileExtension = "log"
        static let logArchiveExtension = "archive"
    }
    
    // MARK: - Singleton
    
    static let shared = Logger(subsystem: AppBundleIdentifier, debugMode: false)
    
    // MARK: - Initialization
    
    init(subsystem: String, debugMode: Bool) {
        self.osLog = OSLog(subsystem: subsystem, category: "General")
        self.loggingQueue = DispatchQueue(label: "\(subsystem).logger", qos: .utility)
        self.isDebugMode = debugMode
        
        // Configure enabled log levels based on environment
        self.enabledLevels = debugMode ?
            [.debug, .info, .warning, .error, .critical] :
            [.info, .warning, .error, .critical]
        
        // Set up log file path
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.logFilePath = documentsPath.appendingPathComponent("app.log").path
        
        // Initialize file handle for persistent logging
        do {
            if !FileManager.default.fileExists(atPath: logFilePath) {
                FileManager.default.createFile(atPath: logFilePath, contents: nil)
            }
            self.fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: logFilePath))
            try self.fileHandle?.seekToEnd()
        } catch {
            os_log("Failed to initialize log file: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
        
        // Initial log rotation check
        rotateLogs()
    }
    
    deinit {
        fileHandle?.closeFile()
    }
    
    // MARK: - Public Methods
    
    /// Main logging function that handles message formatting and persistence
    /// Implements Security Controls/Audit Logging requirement from Section 6.3.3
    func log(
        _ message: String,
        level: LogLevel,
        category: LogCategory,
        file: String? = #file,
        function: String? = #function,
        line: Int = #line
    ) {
        guard enabledLevels.contains(level) else { return }
        
        loggingQueue.async { [weak self] in
            guard let self = self else { return }
            
            let timestamp = self.formattedTimestamp()
            let contextInfo = "[\(AppVersion)][\(AppBundleIdentifier)]"
            
            var logMessage = "\(timestamp) \(level.emoji) [\(level.rawValue.uppercased())] [\(category.rawValue)] \(contextInfo) \(message)"
            
            // Add source location in debug mode
            if self.isDebugMode, let fileName = file?.components(separatedBy: "/").last {
                logMessage += "\n\t📍 \(fileName):\(line) - \(function ?? "")"
            }
            
            // Write to OS logging system
            os_log("%{public}@", log: self.osLog, type: level.osLogType, logMessage)
            
            // Persist to log file
            self.writeToFile(logMessage + "\n")
            
            // Check for log rotation
            self.checkRotationNeeds()
        }
    }
    
    // MARK: - Private Methods
    
    private func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = Constants.dateFormat
        return formatter.string(from: Date())
    }
    
    private func writeToFile(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        do {
            try fileHandle?.write(contentsOf: data)
        } catch {
            os_log("Failed to write to log file: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
    }
    
    private func checkRotationNeeds() {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: logFilePath)
            let fileSize = attributes[.size] as? Int64 ?? 0
            if fileSize > Constants.maxLogFileSize {
                rotateLogs()
            }
        } catch {
            os_log("Failed to check log file size: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
    }
    
    /// Manages log file rotation to prevent excessive disk usage
    /// Implements System Monitoring and Logging requirement from Section 2.5.1
    private func rotateLogs() {
        loggingQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.fileHandle?.closeFile()
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
            let timestamp = dateFormatter.string(from: Date())
            
            let archivePath = self.logFilePath + ".\(timestamp).\(Constants.logArchiveExtension)"
            
            do {
                if FileManager.default.fileExists(atPath: self.logFilePath) {
                    try FileManager.default.moveItem(atPath: self.logFilePath, toPath: archivePath)
                }
                FileManager.default.createFile(atPath: self.logFilePath, contents: nil)
                self.fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: self.logFilePath))
                
                // Clean up old logs after rotation
                self.cleanupOldLogs()
            } catch {
                os_log("Failed to rotate log file: %{public}@", log: self.osLog, type: .error, error.localizedDescription)
            }
        }
    }
    
    /// Removes old log files based on retention policy
    /// Implements System Monitoring and Logging requirement from Section 2.5.1
    private func cleanupOldLogs() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.creationDateKey])
            let oldLogs = contents.filter { $0.pathExtension == Constants.logArchiveExtension }
            
            let cutoffDate = Date().addingTimeInterval(-Double(Constants.logRetentionDays * 24 * 60 * 60))
            
            for logURL in oldLogs {
                if let attributes = try? fileManager.attributesOfItem(atPath: logURL.path),
                   let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try? fileManager.removeItem(at: logURL)
                }
            }
        } catch {
            os_log("Failed to cleanup old logs: %{public}@", log: osLog, type: .error, error.localizedDescription)
        }
    }
}