import Foundation
import SwiftUI
import Network
import OSLog

// MARK: - Network Error Handler
@MainActor
class NetworkErrorHandler: ObservableObject {
    static let shared = NetworkErrorHandler()
    
    @Published var isOnline = true
    @Published var currentError: NetworkError?
    @Published var showErrorAlert = false
    @Published var connectionQuality: ConnectionQuality = .excellent
    
    private let logger = Logger(subsystem: "com.lyo.app", category: "NetworkErrorHandler")
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    // Connection tracking
    @Published var backendReachable = true
    @Published var lastBackendCheck: Date?
    private var consecutiveFailures = 0
    private let maxRetries = 3
    
    enum ConnectionQuality {
        case excellent, good, poor, offline
        
        var description: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good" 
            case .poor: return "Poor"
            case .offline: return "Offline"
            }
        }
        
        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .yellow
            case .poor: return .orange
            case .offline: return .red
            }
        }
    }
    
    enum NetworkError: LocalizedError, Identifiable {
        case offline
        case backendUnreachable
        case timeout
        case rateLimited
        case serverError(Int)
        case authenticationFailed
        case invalidData
        case unknownError(String)
        
        var id: String { errorDescription ?? "unknown" }
        
        var errorDescription: String? {
            switch self {
            case .offline:
                return "No internet connection available"
            case .backendUnreachable:
                return "Cannot reach LyoApp servers"
            case .timeout:
                return "Request timed out. Please try again"
            case .rateLimited:
                return "Too many requests. Please wait and try again"
            case .serverError(let code):
                return "Server error (\(code)). Our team has been notified"
            case .authenticationFailed:
                return "Authentication failed. Please sign in again"
            case .invalidData:
                return "Invalid data received from server"
            case .unknownError(let message):
                return "An error occurred: \(message)"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .offline:
                return "Check your internet connection and try again"
            case .backendUnreachable:
                return "The app will work in offline mode with cached content"
            case .timeout:
                return "Check your connection strength and retry"
            case .rateLimited:
                return "Wait a moment before making more requests"
            case .serverError:
                return "Please try again later or contact support"
            case .authenticationFailed:
                return "Sign out and sign back in to refresh your session"
            case .invalidData:
                return "Please update the app to the latest version"
            case .unknownError:
                return "Please try again or contact support if the issue persists"
            }
        }
        
        var shouldRetry: Bool {
            switch self {
            case .offline, .timeout, .serverError:
                return true
            case .backendUnreachable:
                return false // Will use cached/mock data
            case .rateLimited, .authenticationFailed, .invalidData, .unknownError:
                return false
            }
        }
    }
    
    private init() {
        startNetworkMonitoring()
        logger.info("🌐 NetworkErrorHandler initialized")
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.updateConnectionQuality(path)
                
                if !self?.isOnline ?? false {
                    self?.handleNetworkError(.offline)
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionQuality(_ path: NWPath) {
        if !path.isExpensive && path.status == .satisfied {
            connectionQuality = .excellent
        } else if path.status == .satisfied {
            connectionQuality = .good
        } else if path.status == .requiresConnection {
            connectionQuality = .poor
        } else {
            connectionQuality = .offline
        }
    }
    
    // MARK: - Error Processing
    func handleAPIError(_ error: Error, context: String = "") -> NetworkError {
        logger.error("🚨 API Error in \(context): \(error.localizedDescription)")
        
        let networkError: NetworkError
        
        if let apiError = error as? APIClientError {
            networkError = processAPIError(apiError)
        } else if let urlError = error as? URLError {
            networkError = processURLError(urlError)
        } else {
            networkError = .unknownError(error.localizedDescription)
        }
        
        // Update backend reachability status
        updateBackendStatus(networkError)
        
        return networkError
    }
    
    private func processAPIError(_ error: APIClientError) -> NetworkError {
        switch error {
        case .unauthorized:
            return .authenticationFailed
        case .serverError(let code, _):
            return .serverError(code)
        case .rateLimited:
            return .rateLimited
        case .timeout:
            return .timeout
        case .networkError(let underlying):
            if let urlError = underlying as? URLError {
                return processURLError(urlError)
            }
            return .unknownError(underlying.localizedDescription)
        case .decodingFailed:
            return .invalidData
        case .notFound:
            return .backendUnreachable
        default:
            return .unknownError(error.localizedDescription)
        }
    }
    
    private func processURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .offline
        case .timedOut:
            return .timeout
        case .cannotFindHost, .cannotConnectToHost:
            return .backendUnreachable
        default:
            return .unknownError(error.localizedDescription)
        }
    }
    
    private func updateBackendStatus(_ error: NetworkError) {
        lastBackendCheck = Date()
        
        switch error {
        case .backendUnreachable, .serverError:
            consecutiveFailures += 1
            backendReachable = false
        case .offline, .timeout:
            consecutiveFailures += 1
        default:
            break
        }
        
        // Reset on successful requests (called from success paths)
        if consecutiveFailures >= maxRetries {
            logger.warning("⚠️ Backend marked as unreachable after \(consecutiveFailures) failures")
        }
    }
    
    // MARK: - Public Interface
    func handleNetworkError(_ error: NetworkError, showAlert: Bool = true) {
        currentError = error
        
        if showAlert {
            showErrorAlert = true
        }
        
        logger.error("🚨 Network Error: \(error.localizedDescription ?? "Unknown")")
    }
    
    func markBackendHealthy() {
        consecutiveFailures = 0
        backendReachable = true
        lastBackendCheck = Date()
    }
    
    func clearCurrentError() {
        currentError = nil
        showErrorAlert = false
    }
    
    // MARK: - Retry Logic
    func shouldRetryRequest(_ error: NetworkError) -> Bool {
        return error.shouldRetry && consecutiveFailures < maxRetries
    }
    
    func retryWithBackoff(attempt: Int) async {
        let delay = min(pow(2.0, Double(attempt)), 10.0) // Exponential backoff, max 10s
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
    
    // MARK: - User-Friendly Messages
    func getErrorDisplayMessage(_ error: NetworkError) -> (title: String, message: String, action: String?) {
        switch error {
        case .offline:
            return (
                title: "No Internet Connection",
                message: "You're currently offline. Some features may not be available.",
                action: "Use Offline Mode"
            )
        case .backendUnreachable:
            return (
                title: "Server Unavailable", 
                message: "LyoApp servers are temporarily unavailable. You can still browse cached content.",
                action: "Continue Offline"
            )
        case .authenticationFailed:
            return (
                title: "Authentication Required",
                message: "Your session has expired. Please sign in again.",
                action: "Sign In"
            )
        case .rateLimited:
            return (
                title: "Slow Down",
                message: "You're making requests too quickly. Please wait a moment.",
                action: "OK"
            )
        default:
            return (
                title: "Connection Issue",
                message: error.errorDescription ?? "An unexpected error occurred.",
                action: "Retry"
            )
        }
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Error Alert View Modifier
struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var errorHandler = NetworkErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert("Connection Issue", isPresented: $errorHandler.showErrorAlert) {
                if let error = errorHandler.currentError {
                    let display = errorHandler.getErrorDisplayMessage(error)
                    
                    Button("Dismiss") {
                        errorHandler.clearCurrentError()
                    }
                    
                    if let actionTitle = display.action, error.shouldRetry {
                        Button(actionTitle) {
                            errorHandler.clearCurrentError()
                            // Trigger retry logic in the view
                        }
                    }
                }
            } message: {
                if let error = errorHandler.currentError {
                    let display = errorHandler.getErrorDisplayMessage(error)
                    Text(display.message)
                }
            }
    }
}

// MARK: - SwiftUI Extensions
extension View {
    func handleNetworkErrors() -> some View {
        modifier(ErrorAlertModifier())
    }
}

// MARK: - Network Status Banner
struct NetworkStatusBanner: View {
    @ObservedObject var errorHandler = NetworkErrorHandler.shared
    
    var body: some View {
        Group {
            if !errorHandler.isOnline {
                HStack {
                    Image(systemName: "wifi.slash")
                    Text("Offline - Using cached content")
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.8))
                .foregroundColor(.white)
            } else if !errorHandler.backendReachable {
                HStack {
                    Image(systemName: "server.rack")
                    Text("Server unavailable - Limited functionality")
                    Spacer()
                }
                .padding(.horizontal) 
                .padding(.vertical, 8)
                .background(Color.yellow.opacity(0.8))
                .foregroundColor(.black)
            }
        }
    }
}