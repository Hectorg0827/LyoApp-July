import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var networkManager = SimpleNetworkManager.shared
    @StateObject private var voiceActivationService = VoiceActivationService.shared
    @StateObject private var userDataManager = UserDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(authManager)
                .environmentObject(networkManager)
                .environmentObject(voiceActivationService)
                .environmentObject(userDataManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        print("🚀 LyoApp started")
        print("📱 Backend connection ready")
        
        // Load initial authentication state if available
        if authManager.isAuthenticated {
            Task {
                // Load any initial data if needed
                print("✅ User authenticated")
            }
        }
    }
}
