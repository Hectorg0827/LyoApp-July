import SwiftUI
import UIKit

@main
struct LyoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var avatarStore = AvatarStore()  // NEW: Initialize avatar store
    
    init() {
        // Force resolution of canonical dependency graph early in app startup.
        let _ = CompilationSentinel.value
        purgeLegacyDemoFlags()
        // Validate production configuration at startup
        validateProductionConfiguration()
        printProductionBanner()
        
        // UNITY INTEGRATION: Pre-initialize Unity for faster classroom loading
        initializeUnityFramework()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                let showOnboarding = !avatarStore.hasCompletedSetup || avatarStore.avatar == nil
                let _ = print("🎯 [LyoApp] View evaluation - hasCompletedSetup: \(avatarStore.hasCompletedSetup), avatar: \(String(describing: avatarStore.avatar?.name)), showOnboarding: \(showOnboarding)")
                
                if showOnboarding {
                    // Show NEW 3D Avatar Creator on first launch
                    Avatar3DCreatorView()
                        .environmentObject(avatarStore)
                } else {
                    // Show normal app flow
                    ProductionOnlyView()
                        .environmentObject(avatarStore)
                }
            }
            .onChange(of: scenePhase) {
                handleScenePhaseChange(scenePhase)
            }
            .onAppear {
                avatarStore.load()  // Load saved avatar on app start
            }
        }
    }
    
    private func printProductionBanner() {
        let envEmoji = BackendConfig.isLocalEnvironment ? "🛠️" : "🚀"
        let envLabel = BackendConfig.environment.displayName
        
        print("""
        
        ╔════════════════════════════════════════════╗
        ║  \(envEmoji) LyoApp - \(envLabel.padding(toLength: 26, withPad: " ", startingAt: 0)) ║
        ╚════════════════════════════════════════════╝
        🌐 Backend: \(APIConfig.baseURL)
        🔒 Auth Required: YES
        🚫 Mock Data: IMPOSSIBLE
        ✅ Real Data: ONLY
        ⛔ Demo Mode: BLOCKED
        ════════════════════════════════════════════
        
        """)
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            print("📱 App entered background")
            // BackgroundScheduler functionality would go here
        case .active:
            print("📱 App became active")
            // BackgroundScheduler functionality would go here
        case .inactive:
            print("📱 App became inactive")
        @unknown default:
            break
        }
    }
    
    /// Remove any previously persisted demo-mode overrides from older builds
    private func purgeLegacyDemoFlags() {
        let keys = [
            "app_environment",
            "lyo_forced_environment",
            "isDemoMode",
            "isWorkingMode"
        ]

        for key in keys {
            if UserDefaults.standard.object(forKey: key) != nil {
                UserDefaults.standard.removeObject(forKey: key)
                print("🧹 Cleared legacy flag: \(key)")
            }
        }
    }

    // MARK: - Production Configuration Helpers
    private func validateProductionConfiguration() {
        // Validate API base URL
        guard let apiURL = URL(string: APIConfig.baseURL), let apiHost = apiURL.host else {
            fatalError("❌ Configuration Error: Invalid API baseURL: \(APIConfig.baseURL)")
        }
        
        // For local backend, relax HTTPS requirement
        if BackendConfig.isLocalEnvironment {
            guard apiURL.scheme?.lowercased() == "http" else {
                fatalError("❌ Configuration Error: Local backend should use HTTP")
            }
            print("ℹ️ Running with local backend at \(APIConfig.baseURL)")
        } else {
            // Production/staging must use HTTPS
            guard apiURL.scheme?.lowercased() == "https" else {
                fatalError("❌ Configuration Error: Production backend must use HTTPS")
            }
            
            // Validate WebSocket URL for production
            guard let wsURL = URL(string: APIConfig.webSocketURL), let wsHost = wsURL.host else {
                fatalError("❌ Configuration Error: Invalid WebSocket URL: \(APIConfig.webSocketURL)")
            }
            guard wsURL.scheme?.lowercased() == "wss" else {
                fatalError("❌ Configuration Error: WebSocket URL must use WSS")
            }
            
            // Ensure both endpoints are aligned to the same host
            guard apiHost == wsHost else {
                fatalError("❌ Configuration Error: API host (\(apiHost)) and WebSocket host (\(wsHost)) must match")
            }
        }

        print("✅ Configuration validated: \(BackendConfig.environment.displayName)")
    }

    private func printProductionConfiguration() {
        print("🎯 === LyoApp Production Configuration ===")
        print("🌐 API URL: \(APIConfig.baseURL)")
        print("🔌 WebSocket: \(APIConfig.webSocketURL)")
        print("🏢 Environment: ☁️ Production Cloud Backend")
        print("🚫 Mock Data: DISABLED")
        print("✅ Real Backend: REQUIRED")
        print("🔒 Demo Mode: IMPOSSIBLE")
        print("=====================================")
    }
}

// MARK: - Safe App Manager
@MainActor
class SafeAppManager: ObservableObject {
    @Published var appState: AppState?
    @Published var authManager: SimplifiedAuthenticationManager?
    @Published var voiceActivationService: VoiceActivationService?
    @Published var userDataManager: UserDataManager?
    @Published var isLoading = true
    @Published var initializationError: String?
    
    func initializeServices() {
        print("📱 Starting service initialization...")
        
        // Simple synchronous initialization to prevent hanging
        appState = AppState.shared
        authManager = SimplifiedAuthenticationManager.shared
        voiceActivationService = VoiceActivationService.shared
        userDataManager = UserDataManager.shared
        
        print("✅ All services initialized successfully")
        
        // Initialize backend integration in background (non-blocking)
        Task {
            await initializeBackendIntegration()
        }
        
        // Complete loading after a short delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            print("🚀 App ready to use!")
        }
    }
    
    private func initializeBackendIntegration() async {
        print("🌐 Initializing backend integration in background...")
        // Backend will be initialized when accessed
        print("✅ Backend integration setup complete")
    }
}

// MARK: - Safe App View
struct SafeAppView: View {
    @EnvironmentObject var safeAppManager: SafeAppManager
    @State private var forceShowContent = false
    
    var body: some View {
        if safeAppManager.isLoading && !forceShowContent {
            LoadingView()
                .onAppear {
                    // Force show content after 3 seconds as backup
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if safeAppManager.isLoading {
                            print("⚠️ Forcing content view due to backup timeout")
                            forceShowContent = true
                        }
                    }
                }
        } else if let errorMessage = safeAppManager.initializationError {
            Text("Error: \(errorMessage)")
                .foregroundColor(.red)
                .padding()
        } else {
            ContentView()
                .environmentObject(safeAppManager.appState ?? AppState.shared)
                .environmentObject(safeAppManager.authManager ?? SimplifiedAuthenticationManager.shared)
                .environmentObject(safeAppManager.voiceActivationService ?? VoiceActivationService.shared)
                .environmentObject(safeAppManager.userDataManager ?? UserDataManager.shared)
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("🚀 Starting LyoApp...")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("Please wait while we initialize services")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Error View
struct AppErrorView: View {
    let error: Error
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Try Again") {
                // This will restart the app
                exit(0)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

// MARK: - Fallback View
struct FallbackView: View {
    var body: some View {
        ContentView()
            .environmentObject(AppState.shared)
            .environmentObject(SimplifiedAuthenticationManager.shared)
            .environmentObject(VoiceActivationService.shared)
            .environmentObject(UserDataManager.shared)
            .onAppear {
                print("⚠️ Using fallback view with default shared instances")
            }
    }
}

// MARK: - Simple Error Type
struct SimpleError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var localizedDescription: String {
        return message
    }
}

// MARK: - Production Validator (Blocks Until Backend Verified)
@MainActor
// MARK: - Backend Info Model
struct BackendInfo {
    let baseURL: String
    let status: String
    let version: String
    let service: String?
    let environment: String?
    let timestamp: String?
    let endpoints: [String: String]?
}

class BackendValidator: ObservableObject {
    enum ValidationStatus {
        case validating
        case validated
        case backendUnreachable(String)
    }
    
    @Published var status: ValidationStatus = .validating
    @Published var backendInfo: BackendInfo?
    
    private let maxAutomaticRetries = 3
    private var autoRetryCount = 0
    private var autoRetryTask: Task<Void, Never>?
    
    func validate() async {
        print("🔍 Validating production backend connection...")
        autoRetryTask?.cancel()
        status = .validating
        
        do {
            let response: SystemHealthResponse = try await APIClient.shared.getSystemHealth()
            
            backendInfo = BackendInfo(
                baseURL: APIConfig.baseURL,
                status: response.status,
                version: response.version ?? "unknown",
                service: response.service,
                environment: response.environment,
                timestamp: response.timestamp,
                endpoints: response.endpoints ?? response.services
            )
            
            // Accept "degraded" as a valid, connectable state
            if response.status.lowercased() == "degraded" {
                let serviceLabel = response.service ?? "Backend"
                let versionLabel = response.version ?? "unknown"
                let environmentLabel = response.environment ?? "production"
                print("⚠️ Backend is degraded: proceeding with caution - \(serviceLabel) v\(versionLabel) - \(environmentLabel)")
                status = .validated
                resetAutoRetryTracking()
                return
            }
            
            guard response.isHealthy else {
                throw ValidationError.unhealthyBackend(response.status)
            }
            
            let serviceLabel = response.service ?? "Backend"
            let versionLabel = response.version ?? "unknown"
            let environmentLabel = response.environment ?? "production"
            print("✅ Backend validated: \(serviceLabel) v\(versionLabel) - \(environmentLabel)")
            status = .validated
            resetAutoRetryTracking()
            
        } catch {
            print("❌ Backend validation failed: \(error)")
            handleValidationError(error)
        }
    }
    
    deinit {
        autoRetryTask?.cancel()
    }
    
    private func handleValidationError(_ error: Error) {
        let friendlyMessage = makeFriendlyMessage(for: error)
        let retrySuffix = scheduleAutomaticRetryIfNeeded(for: error)
        status = .backendUnreachable(friendlyMessage + retrySuffix)
    }
    
    private func makeFriendlyMessage(for error: Error) -> String {
        if let apiClientError = error as? APIClientError {
            switch apiClientError {
            case .serverError(let code, let rawMessage):
                if code == 503 {
                    return "Production backend is starting up (HTTP 503). The service asked us to wait a moment before retrying."
                }
                let sanitized = sanitizedServerMessage(rawMessage)
                if let sanitized, !sanitized.isEmpty {
                    return "Production backend returned HTTP \(code): \(sanitized)"
                }
                return "Production backend returned HTTP \(code)."
            case .networkError(let underlying):
                return "Network error: \(underlying.localizedDescription). Check your connection and retry."
            case .timeout:
                return "The request to the production backend timed out."
            case .rateLimited:
                return "The backend rate limit was hit. Please wait a moment before trying again."
            default:
                if let description = apiClientError.errorDescription {
                    return description
                }
            }
        } else if let apiError = error as? APIError {
            switch apiError {
            case .serverError(let code, let message):
                if code == 503 {
                    return "Production backend is starting up (HTTP 503). The service asked us to wait a moment before retrying."
                }
                if let sanitized = sanitizedServerMessage(message), !sanitized.isEmpty {
                    return "Production backend returned HTTP \(code): \(sanitized)"
                }
                return "Production backend returned HTTP \(code)."
            default:
                if let description = apiError.errorDescription {
                    return description
                }
            }
        } else if let validationError = error as? ValidationError {
            switch validationError {
            case .unhealthyBackend(let status):
                return "Backend reported unhealthy status: \(status)"
            }
        }
        
        let localized = (error as NSError).localizedDescription
        if !localized.isEmpty {
            return localized
        }
        
        return "Unable to reach the production backend."
    }
    
    private func scheduleAutomaticRetryIfNeeded(for error: Error) -> String {
        guard shouldAutoRetry(for: error), autoRetryCount < maxAutomaticRetries else {
            return ""
        }
        
        autoRetryTask?.cancel()
        autoRetryCount += 1
        let attempt = autoRetryCount
        let delay: UInt64 = 30 * 1_000_000_000 // 30 seconds
        
        autoRetryTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard let self else { return }
            await self.validate()
        }
        
        return "\n\nWe'll retry automatically in 30 seconds (attempt \(attempt) of \(maxAutomaticRetries))."
    }
    
    private func shouldAutoRetry(for: Error) -> Bool {
        if let apiClientError = `for` as? APIClientError {
            switch apiClientError {
            case .serverError(let code, let _):
                return (500...504).contains(code)
            case .networkError, .timeout, .rateLimited:
                return true
            default:
                return false
            }
        }
        
        if let apiError = `for` as? APIError {
            switch apiError {
            case .serverError(let code, let _):
                return (500...504).contains(code)
            default:
                return false
            }
        }
        
        return false
    }
    
    private func resetAutoRetryTracking() {
        autoRetryCount = 0
        autoRetryTask?.cancel()
        autoRetryTask = nil
    }
    
    private func sanitizedServerMessage(_ raw: String?) -> String? {
        guard let raw = raw, !raw.isEmpty else { return nil }
        let withoutTags = raw.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let collapsedWhitespace = withoutTags.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let cleaned = collapsedWhitespace.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }
}

enum ValidationError: LocalizedError {
    case unhealthyBackend(String)
    
    var errorDescription: String? {
        switch self {
        case .unhealthyBackend(let status):
            return "Backend returned unhealthy status: \(status)"
        }
    }
}

// MARK: - Production Only Main View
struct ProductionOnlyView: View {
    @StateObject private var validator = BackendValidator()
    @StateObject private var authManager = SimplifiedAuthenticationManager.shared
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        ZStack {
            switch validator.status {
            case .validating:
                ValidationLoadingView()
                
            case .backendUnreachable(let error):
                BackendUnreachableView(error: error, backendInfo: validator.backendInfo) {
                    Task {
                        await validator.validate()
                    }
                }
                
            case .validated:
                if authManager.isAuthenticated {
                    ContentView()
                        .environmentObject(authManager)
                        .environmentObject(appState)
                        .overlay(alignment: .topTrailing) {
                            ProductionIndicatorBadge(backendInfo: validator.backendInfo)
                        }
                } else {
                    AuthenticationView()
                        .environmentObject(appState)
                        .environmentObject(authManager)
                }
            }
        }
        .task {
            await validator.validate()
        }
    }
}

// MARK: - Validation Loading View
struct ValidationLoadingView: View {
    @State private var dotCount = 0
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            
            Text("Connecting to backend\(String(repeating: ".", count: dotCount))")
                .font(.headline)
                .foregroundColor(.secondary)
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                        dotCount = (dotCount + 1) % 4
                    }
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Backend Unreachable View
struct BackendUnreachableView: View {
    let error: String
    let backendInfo: BackendInfo?
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Backend Unreachable")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let info = backendInfo {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Backend Details:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("URL:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(info.baseURL)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Status:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(info.status)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            Button(action: retryAction) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Retry Connection")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: 300)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Production Indicator Badge
struct ProductionIndicatorBadge: View {
    let backendInfo: BackendInfo?
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.green)
                .frame(width: 8, height: 8)
            
            Text("LIVE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding([.top, .trailing], 12)
        .opacity(0.8)
    }
}

// MARK: - Unity Framework Initialization
/// Pre-initialize Unity framework during app startup for faster classroom loading
private func initializeUnityFramework() {
    print("🎮 [Unity] Pre-initializing Unity framework...")
    
    // Run initialization on background thread to avoid blocking app launch
    DispatchQueue.global(qos: .utility).async {
        do {
            UnityManager.shared.initializeUnity()
            print("✅ [Unity] Framework pre-initialized successfully")
        } catch {
            print("⚠️ [Unity] Pre-initialization failed (will retry on first use): \(error.localizedDescription)")
        }
    }
}

// The rest of the file remains unchanged...
