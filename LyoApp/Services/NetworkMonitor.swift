import Foundation
import Network
import SwiftUI

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .ethernet
        } else {
            connectionType = .unknown
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    // MARK: - Retry Helper (exponential backoff + jitter)
    func performWithRetry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 0.5,
        jitter: TimeInterval = 0.2,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var attempt = 0
        var delay = initialDelay
        
        while true {
            attempt += 1
            
            if !isConnected {
                // If offline, wait a bit before attempting
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            
            do {
                return try await operation()
            } catch {
                if attempt >= maxAttempts {
                    throw error
                }
                // backoff with jitter
                let jitterAmount = Double.random(in: -jitter...jitter)
                let nextDelay = max(0.1, delay + jitterAmount)
                try? await Task.sleep(nanoseconds: UInt64(nextDelay * 1_000_000_000))
                delay *= 2
            }
        }
    }
}
