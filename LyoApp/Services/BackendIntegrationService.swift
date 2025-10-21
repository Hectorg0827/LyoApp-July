import Foundation
import SwiftUI
import Combine
import OSLog

// MARK: - Backend Integration Service
@MainActor
class BackendIntegrationService: ObservableObject {
    static let shared = BackendIntegrationService()
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var lastHealthCheck: Date?
    @Published var backendInfo: BackendInfo?
    @Published var isLoading = false
    @Published var error: APIClientError?
    
    // MARK: - Backend Status
    @Published var aiServiceStatus: String = "unknown"
    @Published var databaseStatus: String = "unknown"
    @Published var apiVersion: String = "unknown"
    
    // MARK: - Data Cache
    @Published var cachedFeedPosts: [FeedPost] = []
    @Published var cachedLearningResources: [APILearningResource] = []
    @Published var currentUser: ResponseAPIUser?
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let logger = Logger(subsystem: "com.lyo.app", category: "BackendIntegration")
    private var cancellables = Set<AnyCancellable>()
    private var healthCheckTimer: Timer?
    
    // Connection monitoring
    private var consecutiveFailures = 0
    private let maxConsecutiveFailures = 3
    
    enum ConnectionStatus {
        case unknown
        case connecting
        case connected
        case disconnected
        case error(String)
        
        var displayText: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .connecting:
                return "Connecting..."
            case .connected:
                return "Connected"
            case .disconnected:
                return "Disconnected"
            case .error(let message):
                return "Error: \(message)"
            }
        }
        
        var isHealthy: Bool {
            if case .connected = self {
                return true
            }
            return false
        }
    }
    
    struct BackendInfo {
        let status: String
        let version: String
        let service: String?
        let environment: String?
        let capabilities: [String]
        
        init(from health: SystemHealthResponse) {
            self.status = health.status
            self.version = health.version ?? "unknown"
            self.service = health.service ?? health.services?["api"]
            self.environment = health.environment
            let endpointStatuses = health.endpoints ?? health.services ?? [:]
            if endpointStatuses.isEmpty {
                self.capabilities = ["health_check"]
            } else {
                self.capabilities = endpointStatuses.keys.sorted()
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        setupBindings()
        startPeriodicHealthCheck()
        logger.info("🔧 BackendIntegrationService initialized")
    }
    
    private func setupBindings() {
        // Monitor APIClient errors
        apiClient.$lastError
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
        
        // Monitor APIClient loading state
        apiClient.$isLoading
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Connection Management
    func connect() async {
        logger.info("🔌 Attempting to connect to backend")
        
        connectionStatus = .connecting
        isLoading = true
        error = nil
        
        do {
            let health = try await apiClient.healthCheck()
            
            // Update status
            connectionStatus = .connected
            isConnected = true
            lastHealthCheck = Date()
            consecutiveFailures = 0
            
            // Update backend info
            backendInfo = BackendInfo(from: health)
            updateServiceStatus(from: health)
            
            logger.info("✅ Successfully connected to backend: \(health.status)")
            
        } catch {
            handleConnectionError(error)
        }
        
        isLoading = false
    }
    
    func disconnect() {
        logger.info("🔌 Disconnecting from backend")
        
        connectionStatus = .disconnected
        isConnected = false
        backendInfo = nil
        stopHealthCheck()
        
        // Clear cached data
        clearCache()
    }
    
    private func handleConnectionError(_ error: Error) {
        consecutiveFailures += 1
        
        let errorMessage: String
        if let apiError = error as? APIClientError {
            errorMessage = apiError.localizedDescription
            self.error = apiError
        } else {
            errorMessage = error.localizedDescription
            self.error = APIClientError.networkError(error)
        }
        
        connectionStatus = .error(errorMessage)
        isConnected = false
        
        logger.error("❌ Backend connection failed: \(errorMessage)")
        
        // If we've had too many failures, stop trying
        if consecutiveFailures >= maxConsecutiveFailures {
            logger.warning("⚠️ Too many consecutive failures (\(self.consecutiveFailures)), stopping auto-reconnect")
            stopHealthCheck()
        }
    }
    
    // MARK: - Health Monitoring
    func performHealthCheck() async {
        do {
            let health = try await apiClient.healthCheck()
            
            lastHealthCheck = Date()
            updateServiceStatus(from: health)
            
            if !isConnected {
                connectionStatus = .connected
                isConnected = true
                consecutiveFailures = 0
                logger.info("🔄 Backend connection restored")
            }
            
        } catch {
            if isConnected {
                handleConnectionError(error)
            }
        }
    }
    
    private func updateServiceStatus(from health: SystemHealthResponse) {
        apiVersion = health.version ?? "unknown"
        databaseStatus = health.services?["database"] ?? "unknown"
        aiServiceStatus = health.services?["ai"] ?? "unknown"
    }
    
    private func startPeriodicHealthCheck() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task {
                await self?.performHealthCheck()
            }
        }
    }
    
    private func stopHealthCheck() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    // MARK: - Authentication Integration
    func authenticateUser(email: String, password: String) async throws -> ResponseAPIUser {
        logger.info("🔐 Authenticating user: \(email)")
        
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.authenticate(email: email, password: password)
            
            // Store auth token
            apiClient.setAuthToken(response.actualAccessToken)
            
            // Cache user info
            currentUser = response.user
            
            logger.info("✅ User authenticated successfully")
            return response.user
            
        } catch {
            logger.error("❌ Authentication failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func signOut() {
        logger.info("🔓 Signing out user")
        
        apiClient.clearAuthTokens()
        currentUser = nil
        clearCache()
    }
    
    // MARK: - Feed Integration
    func loadFeedContent(page: Int = 1, limit: Int = 20, refresh: Bool = false) async throws -> [FeedPost] {
        logger.info("📰 Loading feed content (page: \(page), limit: \(limit), refresh: \(refresh))")
        
        if refresh {
            cachedFeedPosts.removeAll()
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.loadFeed(page: page, limit: limit)
            
            if page == 1 || refresh {
                cachedFeedPosts = response.posts
            } else {
                cachedFeedPosts.append(contentsOf: response.posts)
            }
            
            logger.info("✅ Loaded \(response.posts.count) feed posts")
            return response.posts
            
        } catch {
            logger.error("❌ Failed to load feed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Learning Resources Integration
    func loadLearningResources(query: String? = nil, limit: Int = 20, refresh: Bool = false) async throws -> [APILearningResource] {
        logger.info("📚 Loading learning resources (query: \(query ?? "nil"), limit: \(limit), refresh: \(refresh))")
        
        if refresh {
            cachedLearningResources.removeAll()
        }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await apiClient.fetchLearningResources(query: query, limit: limit)
            
            if refresh {
                cachedLearningResources = response.resources
            } else {
                // Avoid duplicates when appending
                let newResources = response.resources.filter { newResource in
                    !cachedLearningResources.contains { $0.id == newResource.id }
                }
                cachedLearningResources.append(contentsOf: newResources)
            }
            
            logger.info("✅ Loaded \(response.resources.count) learning resources")
            return response.resources
            
        } catch {
            logger.error("❌ Failed to load learning resources: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - AI Integration
    func generateAIContent(prompt: String, maxTokens: Int = 1000) async throws -> String {
        logger.info("🤖 Generating AI content for prompt")

        isLoading = true
        error = nil

        // Only use real AI service - no fallback content
        let response = try await apiClient.generateAIContent(prompt: prompt, maxTokens: maxTokens)

        logger.info("✅ AI content generated successfully")
        return response.generatedText
    }
    
    func checkAIServiceStatus() async throws -> String {
        logger.info("🔍 Checking AI service status")
        
        do {
            let response = try await apiClient.checkAIStatus()
            aiServiceStatus = response.status
            
            logger.info("✅ AI service status: \(response.status)")
            return response.status
            
        } catch {
            logger.error("❌ Failed to check AI status: \(error.localizedDescription)")
            aiServiceStatus = "unavailable"
            return "unavailable"
        }
    }
    
    // MARK: - Cache Management
    private func clearCache() {
        cachedFeedPosts.removeAll()
        cachedLearningResources.removeAll()
        logger.info("🧹 Cache cleared")
    }
    
    func refreshAllData() async {
        logger.info("🔄 Refreshing all data")
        
        // Perform health check
        await performHealthCheck()
        
        // Refresh feed if we have cached data
        if !cachedFeedPosts.isEmpty {
            _ = try? await loadFeedContent(refresh: true)
        }
        
        // Refresh learning resources if we have cached data
        if !cachedLearningResources.isEmpty {
            _ = try? await loadLearningResources(refresh: true)
        }
    }
    
    // MARK: - Debug & Diagnostics
    func getConnectionDiagnostics() -> [String: Any] {
        return [
            "isConnected": isConnected,
            "connectionStatus": connectionStatus.displayText,
            "lastHealthCheck": lastHealthCheck?.ISO8601Format() ?? "Never",
            "consecutiveFailures": consecutiveFailures,
            "backendInfo": backendInfo != nil ? [
                "status": backendInfo!.status,
                "version": backendInfo!.version,
                "service": backendInfo!.service ?? "Unknown",
                "environment": backendInfo!.environment ?? "Unknown"
            ] : "Not available",
            "cachedFeedPosts": cachedFeedPosts.count,
            "cachedLearningResources": cachedLearningResources.count,
            "hasCurrentUser": currentUser != nil
        ]
    }
    
    deinit {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
}

// MARK: - SwiftUI Integration
extension BackendIntegrationService {
    var connectionStatusColor: Color {
        switch connectionStatus {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .disconnected:
            return .gray
        case .error:
            return .red
        case .unknown:
            return .yellow
        }
    }
    
    var connectionStatusIcon: String {
        switch connectionStatus {
        case .connected:
            return "checkmark.circle.fill"
        case .connecting:
            return "arrow.triangle.2.circlepath"
        case .disconnected:
            return "xmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}
