import Foundation
import Network
import os.log

// MARK: - Network Monitor Service
@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LyoApp", category: "NetworkMonitor")
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
    
    // Published properties for SwiftUI observation
    @Published var isConnected: Bool = false
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive: Bool = false
    @Published var isConstrained: Bool = false
    @Published var networkStatus: NetworkStatus = .unknown
    
    // IPv6 and failover tracking
    @Published var supportsIPv4: Bool = false
    @Published var supportsIPv6: Bool = false
    @Published var activeInterface: InterfaceType = .unknown
    
    // Connection quality metrics
    private var connectionQuality: ConnectionQuality = .unknown
    private var lastConnectionCheck: Date = Date()
    private var consecutiveFailures: Int = 0
    
    private init() {
        startMonitoring()
        logger.info("🌐 NetworkMonitor initialized")
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Network Monitoring
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                await self?.updateNetworkState(path)
            }
        }
        monitor.start(queue: monitorQueue)
        logger.info("🔄 Network monitoring started")
    }
    
    private func stopMonitoring() {
        monitor.cancel()
        logger.info("⏹️ Network monitoring stopped")
    }
    
    private func updateNetworkState(_ path: NWPath) {
        let wasConnected = isConnected
        let previousType = connectionType
        
        // Basic connectivity
        isConnected = path.status == .satisfied
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        // IP version support
        supportsIPv4 = path.supportsIPv4
        supportsIPv6 = path.supportsIPv6
        
        // Connection type detection
        connectionType = determineConnectionType(from: path)
        activeInterface = determineActiveInterface(from: path)
        
        // Network status
        networkStatus = determineNetworkStatus(from: path)
        
        // Log significant changes
        if wasConnected != isConnected {
            if isConnected {
                logger.info("🌐 ✅ Network connection restored - Type: \(connectionType.description)")
                consecutiveFailures = 0
            } else {
                logger.warning("🌐 ❌ Network connection lost")
                consecutiveFailures += 1
            }
        } else if previousType != connectionType && isConnected {
            logger.info("🌐 🔄 Connection type changed: \(previousType.description) → \(connectionType.description)")
        }
        
        // Update connection quality
        updateConnectionQuality()
        
        // Notify listeners of significant changes
        if wasConnected != isConnected || previousType != connectionType {
            NotificationCenter.default.post(
                name: .networkStatusChanged,
                object: nil,
                userInfo: [
                    "isConnected": isConnected,
                    "connectionType": connectionType.rawValue,
                    "previouslyConnected": wasConnected
                ]
            )
        }
    }
    
    // MARK: - Connection Type Detection
    
    private func determineConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.other) {
            return .other
        } else {
            return .unknown
        }
    }
    
    private func determineActiveInterface(from path: NWPath) -> InterfaceType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
    
    private func determineNetworkStatus(from path: NWPath) -> NetworkStatus {
        switch path.status {
        case .satisfied:
            return isExpensive ? .connectedExpensive : .connectedNormal
        case .unsatisfied:
            return .disconnected
        case .requiresConnection:
            return .requiresConnection
        @unknown default:
            return .unknown
        }
    }
    
    // MARK: - Connection Quality Assessment
    
    private func updateConnectionQuality() {
        lastConnectionCheck = Date()
        
        if !isConnected {
            connectionQuality = .poor
            return
        }
        
        // Assess quality based on connection type and constraints
        if isConstrained || isExpensive {
            connectionQuality = .fair
        } else if connectionType == .wifi && !isConstrained {
            connectionQuality = .excellent
        } else if connectionType == .cellular && !isExpensive {
            connectionQuality = .good
        } else {
            connectionQuality = .fair
        }
    }
    
    // MARK: - Network Test Methods
    
    /// Test network connectivity with a lightweight request
    func performConnectivityTest() async -> ConnectivityTestResult {
        let correlationId = UUID().uuidString.prefix(8).lowercased()
        logger.info("[\(correlationId)] 🧪 Starting connectivity test")
        
        guard isConnected else {
            logger.warning("[\(correlationId)] ❌ Connectivity test skipped - no network connection")
            return ConnectivityTestResult(
                isSuccessful: false,
                responseTime: 0,
                error: "No network connection available",
                timestamp: Date(),
                correlationId: String(correlationId)
            )
        }
        
        let startTime = Date()
        
        do {
            // Use health check endpoint for connectivity test
            let _ = try await APIClient.shared.healthCheck()
            
            let responseTime = Date().timeIntervalSince(startTime)
            logger.info("[\(correlationId)] ✅ Connectivity test successful - \(Int(responseTime * 1000))ms")
            
            return ConnectivityTestResult(
                isSuccessful: true,
                responseTime: responseTime,
                error: nil,
                timestamp: Date(),
                correlationId: String(correlationId)
            )
            
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            logger.error("[\(correlationId)] ❌ Connectivity test failed: \(error) - \(Int(responseTime * 1000))ms")
            
            consecutiveFailures += 1
            
            return ConnectivityTestResult(
                isSuccessful: false,
                responseTime: responseTime,
                error: error.localizedDescription,
                timestamp: Date(),
                correlationId: String(correlationId)
            )
        }
    }
    
    // MARK: - Retry Logic with Exponential Backoff
    
    /// Perform network request with automatic retry logic
    func performWithRetry<T>(
        maxRetries: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let correlationId = UUID().uuidString.prefix(8).lowercased()
        var delay = initialDelay
        
        for attempt in 1...maxRetries {
            do {
                logger.info("[\(correlationId)] 🔄 Network operation attempt \(attempt)/\(maxRetries)")
                
                // Check network status before attempting
                guard isConnected else {
                    throw NetworkError.noConnection
                }
                
                let result = try await operation()
                
                if attempt > 1 {
                    logger.info("[\(correlationId)] ✅ Network operation succeeded on attempt \(attempt)")
                }
                
                return result
                
            } catch {
                logger.warning("[\(correlationId)] ⚠️ Network operation failed on attempt \(attempt): \(error)")
                
                // Don't retry on certain errors
                if shouldNotRetry(error) {
                    logger.error("[\(correlationId)] ❌ Non-retryable error, giving up: \(error)")
                    throw error
                }
                
                // If this was the last attempt, throw the error
                if attempt == maxRetries {
                    logger.error("[\(correlationId)] ❌ All retry attempts exhausted, final error: \(error)")
                    throw error
                }
                
                // Wait before retrying with exponential backoff
                logger.info("[\(correlationId)] ⏳ Waiting \(delay)s before retry...")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                // Increase delay for next attempt (exponential backoff with jitter)
                delay = min(delay * 2.0 + Double.random(in: 0...1), maxDelay)
            }
        }
        
        throw NetworkError.retryExhausted
    }
    
    private func shouldNotRetry(_ error: Error) -> Bool {
        // Don't retry on authentication errors, bad requests, etc.
        if let apiError = error as? APIClientError {
            switch apiError {
            case .unauthorized, .badRequest, .encodingFailed:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    // MARK: - Public Properties and Methods
    
    var networkSummary: String {
        if !isConnected {
            return "Disconnected"
        }
        
        var summary = "\(connectionType.description)"
        
        if isExpensive {
            summary += " (Expensive)"
        }
        
        if isConstrained {
            summary += " (Constrained)"
        }
        
        if supportsIPv6 && supportsIPv4 {
            summary += " (IPv4/IPv6)"
        } else if supportsIPv6 {
            summary += " (IPv6)"
        } else if supportsIPv4 {
            summary += " (IPv4)"
        }
        
        return summary
    }
    
    var detailedNetworkInfo: NetworkInfo {
        return NetworkInfo(
            isConnected: isConnected,
            connectionType: connectionType,
            isExpensive: isExpensive,
            isConstrained: isConstrained,
            supportsIPv4: supportsIPv4,
            supportsIPv6: supportsIPv6,
            activeInterface: activeInterface,
            networkStatus: networkStatus,
            connectionQuality: connectionQuality,
            consecutiveFailures: consecutiveFailures,
            lastConnectionCheck: lastConnectionCheck
        )
    }
}

// MARK: - Enums and Types

enum ConnectionType: String, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case other = "other"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .other: return "Other"
        case .unknown: return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "antenna.radiowaves.left.and.right"
        case .ethernet: return "cable.connector"
        case .other: return "network"
        case .unknown: return "questionmark.diamond"
        }
    }
}

enum NetworkStatus: String, CaseIterable {
    case connectedNormal = "connected_normal"
    case connectedExpensive = "connected_expensive"
    case disconnected = "disconnected"
    case requiresConnection = "requires_connection"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .connectedNormal: return "Connected"
        case .connectedExpensive: return "Connected (Expensive)"
        case .disconnected: return "Disconnected"
        case .requiresConnection: return "Requires Connection"
        case .unknown: return "Unknown"
        }
    }
}

enum InterfaceType: String, CaseIterable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case unknown = "unknown"
}

enum ConnectionQuality: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case unknown = "unknown"
    
    var description: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .unknown: return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        case .unknown: return "gray"
        }
    }
}

enum NetworkError: LocalizedError {
    case noConnection
    case retryExhausted
    case timeout
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No network connection available"
        case .retryExhausted:
            return "Network request failed after all retry attempts"
        case .timeout:
            return "Network request timed out"
        case .invalidResponse:
            return "Invalid network response received"
        }
    }
}

// MARK: - Data Structures

struct ConnectivityTestResult {
    let isSuccessful: Bool
    let responseTime: TimeInterval
    let error: String?
    let timestamp: Date
    let correlationId: String
    
    var responseTimeMs: Int {
        return Int(responseTime * 1000)
    }
    
    var summary: String {
        if isSuccessful {
            return "✅ Connected (\(responseTimeMs)ms)"
        } else {
            return "❌ Failed: \(error ?? "Unknown error")"
        }
    }
}

struct NetworkInfo {
    let isConnected: Bool
    let connectionType: ConnectionType
    let isExpensive: Bool
    let isConstrained: Bool
    let supportsIPv4: Bool
    let supportsIPv6: Bool
    let activeInterface: InterfaceType
    let networkStatus: NetworkStatus
    let connectionQuality: ConnectionQuality
    let consecutiveFailures: Int
    let lastConnectionCheck: Date
}

// MARK: - Notification Names

extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
}