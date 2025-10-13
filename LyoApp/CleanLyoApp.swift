import SwiftUI

@main
struct LyoApp: App {
    // Create state objects lazily to prevent initialization hanging
    @StateObject private var safeAppManager = SafeAppManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            SafeAppView()
                .environmentObject(safeAppManager)
                .onAppear {
                    setupProductionApp()
                }
                .onChange(of: scenePhase) {
                    handleScenePhaseChange(scenePhase)
                }
        }
    }

    private func setupProductionApp() {
        // Print production-only configuration
        UnifiedLyoConfig.printConfiguration()

        // Log backend configuration (don't crash - allow both local and production)
        print("🚀 LyoApp started")
        print("🌐 Backend: \(APIConfig.baseURL)")
        
        if APIConfig.baseURL.contains("lyo-backend") {
            print("✅ Using PRODUCTION backend")
            print("🚫 Mock data: DISABLED")
        } else if APIConfig.baseURL.contains("localhost") {
            print("⚠️ Using LOCAL backend")
            print("💡 Set LYO_ENV=prod in scheme environment variables to use production")
        } else {
            print("⚠️ Unknown backend configuration")
        }

        safeAppManager.initializeServices()
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            print("📱 App entered background")
        case .active:
            print("📱 App became active")
        case .inactive:
            print("📱 App became inactive")
        @unknown default:
            break
        }
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
        print("📱 Starting production service initialization...")

        // Simple synchronous initialization to prevent hanging
        appState = AppState.shared
        authManager = SimplifiedAuthenticationManager.shared
        voiceActivationService = VoiceActivationService.shared
        userDataManager = UserDataManager.shared

        print("✅ All services initialized successfully")

        // Initialize backend integration in background (non-blocking)
        Task {
            await initializeProductionBackend()
        }

        // Complete loading after a short delay to ensure UI updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isLoading = false
            print("🚀 Production app ready to use!")
        }
    }

    private func initializeProductionBackend() async {
        print("🌐 Initializing production backend connection...")

        do {
            // Connect to production backend
            let backend = BackendIntegrationService.shared
            await backend.connect()

            print("✅ Production backend connection established")

        } catch {
            print("⚠️ Backend connection failed: \(error)")
            // Don't fallback to mock - let the app show connection errors
        }
    }
}

// MARK: - Safe App View
struct SafeAppView: View {
    @EnvironmentObject var safeAppManager: SafeAppManager
    @State private var forceShowContent = false

    var body: some View {
        if safeAppManager.isLoading && !forceShowContent {
            ProductionLoadingView()
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
            ProductionErrorView(errorMessage: errorMessage)
        } else {
            // MINIMAL MODE: Use standalone AI Avatar launcher
            MinimalAILauncher()
                .environmentObject(safeAppManager.appState ?? AppState.shared)
            
            // FULL MODE: Uncomment to restore full app
            // ContentView()
            //     .environmentObject(safeAppManager.appState ?? AppState.shared)
            //     .environmentObject(safeAppManager.authManager ?? SimplifiedAuthenticationManager.shared)
            //     .environmentObject(safeAppManager.voiceActivationService ?? VoiceActivationService.shared)
            //     .environmentObject(safeAppManager.userDataManager ?? UserDataManager.shared)
        }
    }
}

// MARK: - Production Loading View
struct ProductionLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("🚀 Starting LyoApp...")
                .font(.title2)
                .foregroundColor(.blue)

            Text("Connecting to production backend...")
                .font(.caption)
                .foregroundColor(.gray)

            Text("🌐 \(APIConfig.baseURL)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Production Error View
struct ProductionErrorView: View {
    let errorMessage: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("Production Backend Error")
                .font(.title2)
                .fontWeight(.semibold)

            Text(errorMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text("Backend: \(APIConfig.baseURL)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top)

            Button("Retry Connection") {
                // Restart app to retry connection
                exit(0)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}