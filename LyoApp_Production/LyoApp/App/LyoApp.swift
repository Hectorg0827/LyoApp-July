import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var networkManager = NetworkManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(networkManager)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Initialize app configuration
        Task {
            await performHealthCheck()
        }
    }
    
    private func performHealthCheck() async {
        do {
            let health = try await networkManager.healthCheck()
            print("✅ Backend health check passed: \(health.status)")
        } catch {
            print("❌ Backend health check failed: \(error.localizedDescription)")
        }
    }
}
