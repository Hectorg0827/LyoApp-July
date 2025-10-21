import Foundation
import os.log
import UIKit
import Darwin

// MARK: - Production Logging System
class ProductionLogger: ObservableObject {
    static let shared = ProductionLogger()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LyoApp", category: "ProductionLogger")
    private let queue = DispatchQueue(label: "ProductionLogger", qos: .utility)
    
    // Log storage for analytics
    private var logEntries: [LogEntry] = []
    private let maxLogEntries = 1000
    
    // Performance metrics
    @Published var performanceMetrics = PerformanceMetrics()
    
    // Error tracking
    private var errorCounts: [String: Int] = [:]
    private var errorThresholds: [LogLevel: Int] = [
        .error: 10,
        .warning: 25,
        .critical: 1
    ]
    
    private init() {
        logger.info("🎯 ProductionLogger initialized")
        startPerformanceMonitoring()
    }
    
    // MARK: - Main Logging Interface
    
    /// Log with correlation ID and structured data
    func log(
        level: LogLevel,
        category: LogCategory,
        message: String,
        correlationId: String? = nil,
        metadata: [String: Any]? = nil,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            correlationId: correlationId ?? generateCorrelationId(),
            metadata: metadata,
            error: error,
            file: URL(fileURLWithPath: file).lastPathComponent,
            function: function,
            line: line
        )
        
        // Store log entry
        queue.async { [weak self] in
            self?.storeLogEntry(entry)
        }
        
        // Send to system logger
        logToSystem(entry)
        
        // Check thresholds and alert if needed
        checkErrorThresholds(entry)
        
        // Update performance metrics
        updatePerformanceMetrics(entry)
    }
    
    // MARK: - Convenience Logging Methods
    
    func debug(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil) {
        log(level: .debug, category: .general, message: message, correlationId: correlationId, metadata: metadata)
    }
    
    func info(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil) {
        log(level: .info, category: .general, message: message, correlationId: correlationId, metadata: metadata)
    }
    
    func warning(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil, error: Error? = nil) {
        log(level: .warning, category: .general, message: message, correlationId: correlationId, metadata: metadata, error: error)
    }
    
    func error(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil, error: Error? = nil) {
        log(level: .error, category: .general, message: message, correlationId: correlationId, metadata: metadata, error: error)
    }
    
    func critical(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil, error: Error? = nil) {
        log(level: .critical, category: .general, message: message, correlationId: correlationId, metadata: metadata, error: error)
    }
    
    // MARK: - Category-Specific Logging
    
    func logNetworkRequest(endpoint: String, method: String, correlationId: String, responseTime: TimeInterval? = nil, statusCode: Int? = nil, error: Error? = nil) {
        let metadata: [String: Any] = [
            "endpoint": endpoint,
            "method": method,
            "response_time_ms": responseTime.map { Int($0 * 1000) } ?? 0,
            "status_code": statusCode ?? 0
        ]
        
        let level: LogLevel = error != nil ? .error : .info
        let message = "Network request: \(method) \(endpoint)"
        
        log(level: level, category: .network, message: message, correlationId: correlationId, metadata: metadata, error: error)
    }
    
    func logUserAction(_ action: String, correlationId: String? = nil, metadata: [String: Any]? = nil) {
        log(level: .info, category: .userAction, message: "User action: \(action)", correlationId: correlationId, metadata: metadata)
    }
    
    func logPerformanceEvent(event: String, duration: TimeInterval, correlationId: String? = nil, metadata: [String: Any]? = nil) {
        var eventMetadata = metadata ?? [:]
        eventMetadata["duration_ms"] = Int(duration * 1000)
        
        let level: LogLevel = duration > 2.0 ? .warning : .info
        log(level: level, category: .performance, message: "Performance: \(event)", correlationId: correlationId, metadata: eventMetadata)
    }
    
    func logSecurityEvent(_ event: String, correlationId: String? = nil, metadata: [String: Any]? = nil, error: Error? = nil) {
        log(level: .critical, category: .security, message: "Security event: \(event)", correlationId: correlationId, metadata: metadata, error: error)
    }
    
    // MARK: - Performance Monitoring
    
    private func startPerformanceMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            self?.updateSystemMetrics()
        }
    }
    
    private func updateSystemMetrics() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Memory usage
            let memoryInfo = self.getMemoryUsage()
            
            // CPU usage (simplified)
            let cpuUsage = self.getCPUUsage()
            
            DispatchQueue.main.async {
                self.performanceMetrics.memoryUsageMB = memoryInfo.used / 1024 / 1024
                self.performanceMetrics.cpuUsagePercent = cpuUsage
                self.performanceMetrics.lastUpdated = Date()
            }
            
            // Log performance metrics if concerning
            if memoryInfo.used > 200 * 1024 * 1024 { // > 200MB
                self.log(level: .warning, category: .performance, 
                        message: "High memory usage detected", 
                        metadata: ["memory_mb": Int(memoryInfo.used / 1024 / 1024)])
            }
        }
    }
    
    private func getMemoryUsage() -> (used: UInt64, total: UInt64) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return (used: info.resident_size, total: info.virtual_size)
        } else {
            return (used: 0, total: 0)
        }
    }
    
    private func getCPUUsage() -> Double {
        // Simplified CPU usage - would need more complex implementation for accurate reading
        return 0.0
    }
    
    // MARK: - Log Management
    
    private func storeLogEntry(_ entry: LogEntry) {
        logEntries.append(entry)
        
        // Maintain log size limit
        if logEntries.count > maxLogEntries {
            logEntries.removeFirst(logEntries.count - maxLogEntries)
        }
    }
    
    private func logToSystem(_ entry: LogEntry) {
        let formattedMessage = formatLogMessage(entry)
        
        switch entry.level {
        case .debug:
            logger.debug("\(formattedMessage)")
        case .info:
            logger.info("\(formattedMessage)")
        case .warning:
            logger.warning("\(formattedMessage)")
        case .error:
            logger.error("\(formattedMessage)")
        case .critical:
            logger.critical("\(formattedMessage)")
        }
    }
    
    private func formatLogMessage(_ entry: LogEntry) -> String {
        var components: [String] = []
        
        // Add correlation ID
        components.append("[\(entry.correlationId)]")
        
        // Add category
        components.append("[\(entry.category.rawValue.uppercased())]")
        
        // Add message
        components.append(entry.message)
        
        // Add location info for warnings and above
        if entry.level.severity >= LogLevel.warning.severity {
            components.append("(\(entry.file):\(entry.line))")
        }
        
        // Add error if present
        if let error = entry.error {
            components.append("Error: \(error.localizedDescription)")
        }
        
        // Add metadata if present
        if let metadata = entry.metadata, !metadata.isEmpty {
            let metadataString = metadata.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            components.append("{\(metadataString)}")
        }
        
        return components.joined(separator: " ")
    }
    
    // MARK: - Error Threshold Monitoring
    
    private func checkErrorThresholds(_ entry: LogEntry) {
        guard entry.level.severity >= LogLevel.warning.severity else { return }
        
        let errorKey = "\(entry.category.rawValue)_\(entry.level.rawValue)"
        errorCounts[errorKey, default: 0] += 1
        
        if let threshold = errorThresholds[entry.level],
           errorCounts[errorKey, default: 0] >= threshold {
            
            // Log critical alert
            logger.critical("🚨 Error threshold reached: \(errorKey) - \(errorCounts[errorKey, default: 0]) occurrences")
            
            // Could trigger remote alerting here in production
            triggerErrorAlert(category: entry.category, level: entry.level, count: errorCounts[errorKey, default: 0])
            
            // Reset counter to avoid spam
            errorCounts[errorKey] = 0
        }
    }
    
    private func triggerErrorAlert(category: LogCategory, level: LogLevel, count: Int) {
        // In production, this could send alerts to monitoring systems
        // For now, just log locally
        log(level: .critical, category: .system, 
            message: "Error threshold alert", 
            metadata: [
                "category": category.rawValue,
                "level": level.rawValue,
                "count": count
            ])
    }
    
    // MARK: - Analytics and Reporting
    
    func getLogSummary(since: Date = Date().addingTimeInterval(-3600)) -> LogSummary {
        let recentLogs = logEntries.filter { $0.timestamp >= since }
        
        let errorCount = recentLogs.filter { $0.level == .error }.count
        let warningCount = recentLogs.filter { $0.level == .warning }.count
        let criticalCount = recentLogs.filter { $0.level == .critical }.count
        
        let categoryBreakdown = Dictionary(grouping: recentLogs, by: { $0.category })
            .mapValues { $0.count }
        
        return LogSummary(
            totalLogs: recentLogs.count,
            errorCount: errorCount,
            warningCount: warningCount,
            criticalCount: criticalCount,
            categoryBreakdown: categoryBreakdown,
            timeRange: since...Date()
        )
    }
    
    func exportLogs(since: Date = Date().addingTimeInterval(-3600)) -> String {
        let recentLogs = logEntries.filter { $0.timestamp >= since }
        
        let dateFormatter = ISO8601DateFormatter()
        
        var output = "=== LyoApp Production Logs ===\n"
        output += "Export Time: \(dateFormatter.string(from: Date()))\n"
        output += "Logs Since: \(dateFormatter.string(from: since))\n"
        output += "Total Entries: \(recentLogs.count)\n\n"
        
        for entry in recentLogs {
            output += "[\(dateFormatter.string(from: entry.timestamp))] "
            output += "\(entry.level.rawValue.uppercased()) "
            output += "[\(entry.category.rawValue)] "
            output += "[\(entry.correlationId)] "
            output += entry.message
            
            if let error = entry.error {
                output += " | Error: \(error.localizedDescription)"
            }
            
            if let metadata = entry.metadata, !metadata.isEmpty {
                let metadataStr = metadata.map { "\($0.key)=\($0.value)" }.joined(separator: " ")
                output += " | \(metadataStr)"
            }
            
            output += "\n"
        }
        
        return output
    }
    
    // MARK: - Utility Methods
    
    private func generateCorrelationId() -> String {
        return UUID().uuidString.prefix(8).lowercased().description
    }
    
    private func updatePerformanceMetrics(_ entry: LogEntry) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch entry.level {
            case .error:
                self.performanceMetrics.errorCount += 1
            case .warning:
                self.performanceMetrics.warningCount += 1
            case .critical:
                self.performanceMetrics.criticalCount += 1
            default:
                break
            }
        }
    }
}

// MARK: - Data Structures

struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let message: String
    let correlationId: String
    let metadata: [String: Any]?
    let error: Error?
    let file: String
    let function: String
    let line: Int
}

enum LogLevel: String, CaseIterable {
    case debug = "debug"
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    // Separate numeric severity for comparisons
    var severity: Int {
        switch self {
        case .debug: return 0
        case .info: return 1
        case .warning: return 2
        case .error: return 3
        case .critical: return 4
        }
    }
}

enum LogCategory: String, CaseIterable {
    case general = "general"
    case network = "network"
    case authentication = "auth"
    case userAction = "user_action"
    case performance = "performance"
    case security = "security"
    case ai = "ai"
    case feed = "feed"
    case system = "system"
    case ui = "ui"
}

struct PerformanceMetrics: Codable {
    var memoryUsageMB: UInt64 = 0
    var cpuUsagePercent: Double = 0.0
    var errorCount: Int = 0
    var warningCount: Int = 0
    var criticalCount: Int = 0
    var lastUpdated: Date = Date()
    
    var summary: String {
        return "Memory: \(memoryUsageMB)MB, Errors: \(errorCount), Warnings: \(warningCount)"
    }
}

struct LogSummary {
    let totalLogs: Int
    let errorCount: Int
    let warningCount: Int
    let criticalCount: Int
    let categoryBreakdown: [LogCategory: Int]
    let timeRange: ClosedRange<Date>
    
    var healthScore: Double {
        guard totalLogs > 0 else { return 1.0 }
        let problemCount = errorCount + warningCount + (criticalCount * 5)
        let score = max(0.0, 1.0 - Double(problemCount) / Double(totalLogs))
        return score
    }
    
    var status: String {
        let score = healthScore
        if score >= 0.9 {
            return "Excellent"
        } else if score >= 0.7 {
            return "Good"
        } else if score >= 0.5 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
}

// MARK: - Global Logging Functions
func logInfo(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil) {
    ProductionLogger.shared.info(message, correlationId: correlationId, metadata: metadata)
}

func logWarning(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil, error: Error? = nil) {
    ProductionLogger.shared.warning(message, correlationId: correlationId, metadata: metadata, error: error)
}

func logError(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil, error: Error? = nil) {
    ProductionLogger.shared.error(message, correlationId: correlationId, metadata: metadata, error: error)
}

func logCritical(_ message: String, correlationId: String? = nil, metadata: [String: Any]? = nil, error: Error? = nil) {
    ProductionLogger.shared.critical(message, correlationId: correlationId, metadata: metadata, error: error)
}
