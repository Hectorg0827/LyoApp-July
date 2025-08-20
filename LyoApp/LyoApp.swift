import SwiftUI

@main
struct LyoApp: App {
    // Create state objects lazily to prevent initialization hanging
    @StateObject private var safeAppManager = SafeAppManager()
    
    var body: some Scene {
        WindowGroup {
            SafeAppView()
                .environmentObject(safeAppManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        print("🚀 LyoApp started safely")
        safeAppManager.initializeServices()
    }
}

// MARK: - Safe App Manager
@MainActor
class SafeAppManager: ObservableObject {
    @Published var appState: AppState?
    @Published var authManager: AuthenticationManager?
    @Published var networkManager: SimpleNetworkManager?
    @Published var voiceActivationService: VoiceActivationService?
    @Published var userDataManager: UserDataManager?
    @Published var isLoading = true
    @Published var initializationError: String?
    
    func initializeServices() {
        Task { @MainActor in
            do {
                print("📱 Starting safe service initialization...")
                
                // Initialize services one by one with error handling
                await initializeAppState()
                await initializeNetworkManager()
                await initializeAuthManager()
                await initializeVoiceService()
                await initializeUserDataManager()
                
                isLoading = false
                print("✅ All services initialized successfully")
                
            } catch {
                isLoading = false
                initializationError = "Failed to initialize app: \(error.localizedDescription)"
                print("❌ Service initialization failed: \(error)")
            }
        }
    }
    
    private func initializeAppState() async {
        do {
            appState = AppState.shared
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms delay
            print("✅ AppState initialized")
        } catch {
            print("❌ AppState failed: \(error)")
        }
    }
    
    private func initializeNetworkManager() async {
        do {
            networkManager = SimpleNetworkManager.shared
            try await Task.sleep(nanoseconds: 10_000_000)
            print("✅ NetworkManager initialized")
        } catch {
            print("❌ NetworkManager failed: \(error)")
        }
    }
    
    private func initializeAuthManager() async {
        do {
            authManager = AuthenticationManager.shared
            try await Task.sleep(nanoseconds: 10_000_000)
            print("✅ AuthManager initialized")
        } catch {
            print("❌ AuthManager failed: \(error)")
        }
    }
    
    private func initializeVoiceService() async {
        do {
            voiceActivationService = VoiceActivationService.shared
            try await Task.sleep(nanoseconds: 10_000_000)
            print("✅ VoiceActivationService initialized")
        } catch {
            print("❌ VoiceActivationService failed: \(error)")
        }
    }
    
    private func initializeUserDataManager() async {
        do {
            userDataManager = UserDataManager.shared
            try await Task.sleep(nanoseconds: 10_000_000)
            print("✅ UserDataManager initialized")
        } catch {
            print("❌ UserDataManager failed: \(error)")
        }
    }
}

// MARK: - Safe App View
struct SafeAppView: View {
    @EnvironmentObject var safeAppManager: SafeAppManager
    
    var body: some View {
        if safeAppManager.isLoading {
            LoadingView()
        } else if let error = safeAppManager.initializationError {
            ErrorView(message: error)
        } else if let appState = safeAppManager.appState,
                  let authManager = safeAppManager.authManager,
                  let networkManager = safeAppManager.networkManager,
                  let voiceService = safeAppManager.voiceActivationService,
                  let userManager = safeAppManager.userDataManager {
            
            ContentView()
                .environmentObject(appState)
                .environmentObject(authManager)
                .environmentObject(networkManager)
                .environmentObject(voiceService)
                .environmentObject(userManager)
        } else {
            FallbackView()
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
struct ErrorView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("⚠️")
                .font(.system(size: 60))
            
            Text("Initialization Error")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
                .padding()
            
            Button("Try Again") {
                // This would restart the app or retry initialization
                exit(0)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

// MARK: - Fallback View
struct FallbackView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("🔧")
                .font(.system(size: 60))
            
            Text("LyoApp")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text("Running in safe mode")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text("Some features may be limited")
                .font(.body)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("• Core functionality available")
                Text("• Limited connectivity")
                Text("• Basic user interface")
            }
            .font(.caption)
            .foregroundColor(.gray)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
