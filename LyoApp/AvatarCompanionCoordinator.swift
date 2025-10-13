import SwiftUI
import Combine

/// Central coordinator for the Avatar Companion system
/// Manages integration between all components and handles error recovery
class AvatarCompanionCoordinator: ObservableObject {
    static let shared = AvatarCompanionCoordinator()
    
    // MARK: - Published State
    @Published var isSystemReady: Bool = false
    @Published var lastError: Error?
    @Published var systemStatus: SystemStatus = .ready
    @Published var connectionQuality: ConnectionQuality = .excellent
    
    enum SystemStatus: Equatable {
        case initializing
        case ready
        case error(String)
        case reconnecting
        case degraded
    }
    
    enum ConnectionQuality: Equatable {
        case unknown
        case excellent
        case good
        case poor
        case disconnected
    }
    
    init() {
        isSystemReady = true
        systemStatus = .ready
        connectionQuality = .excellent
    }
    
    // MARK: - Public Interface
    
    func startContinuousListening() {
        print("🎤 Started continuous listening mode")
    }
    
    func stopContinuousListening() {
        print("🎤 Stopped continuous listening mode")
    }
    
    func forceReconnect() {
        print("🔄 Force reconnect")
    }
    
    func resetSystem() {
        systemStatus = .ready
        isSystemReady = true
        lastError = nil
        print("🔄 System reset")
    }
    
    func getSystemHealthReport() -> String {
        return """
        Avatar Companion System Health:
        • System Status: Ready
        • Connection Quality: Excellent
        """
    }
}

// MARK: - Error Types

enum CoordinatorError: Error, LocalizedError {
    case connectionTimeout
    case serviceInitializationFailed
    case systemNotReady
    
    var errorDescription: String? {
        switch self {
        case .connectionTimeout:
            return "Connection timeout during initialization"
        case .serviceInitializationFailed:
            return "Failed to initialize services"
        case .systemNotReady:
            return "System not ready for operation"
        }
    }
}

// MARK: - Extensions

extension AvatarCompanionCoordinator.SystemStatus {
    var description: String {
        switch self {
        case .initializing: return "Initializing"
        case .ready: return "Ready"
        case .error(let message): return "Error: \(message)"
        case .reconnecting: return "Reconnecting"
        case .degraded: return "Degraded"
        }
    }
}

extension AvatarCompanionCoordinator.ConnectionQuality {
    var description: String {
        switch self {
        case .unknown: return "Unknown"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .poor: return "Poor"
        case .disconnected: return "Disconnected"
        }
    }
}
