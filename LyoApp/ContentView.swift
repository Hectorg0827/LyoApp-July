import SwiftUI

struct ContentView: View {
    @State private var isLoading = false
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var networkManager: SimpleNetworkManager
    @EnvironmentObject var voiceActivationService: VoiceActivationService
    @EnvironmentObject var userDataManager: UserDataManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🚀 LyoApp Content View")
                .font(.title)
                .foregroundColor(.blue)
                .padding()
            
            Text("Debug: ContentView loaded successfully")
                .foregroundColor(.green)
                .font(.caption)
            
            // Service status indicators
            VStack(alignment: .leading, spacing: 5) {
                ServiceStatusRow(name: "Authentication", isWorking: authManager != nil)
                ServiceStatusRow(name: "Network", isWorking: networkManager != nil)
                ServiceStatusRow(name: "User Data", isWorking: userDataManager != nil)
                ServiceStatusRow(name: "Voice Service", isWorking: voiceActivationService != nil)
                ServiceStatusRow(name: "App State", isWorking: appState != nil)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
            if isLoading {
                ProgressView("Loading...")
            } else {
                VStack {
                    Text("Welcome to LyoApp!")
                        .font(.headline)
                    
                    // Authenticated user info
                    if let user = authManager.currentUser {
                        Text("Hello, \(user.fullName)!")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    } else if authManager.isAuthenticated {
                        Text("User authenticated")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    } else {
                        Text("Not authenticated")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 200, height: 100)
                        .overlay(
                            Text("Test Content")
                                .foregroundColor(.white)
                        )
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            print("🔍 ContentView appeared")
            print("📊 Services status:")
            print("  - AuthManager: \(authManager != nil ? "✅" : "❌")")
            print("  - NetworkManager: \(networkManager != nil ? "✅" : "❌")")
            print("  - UserDataManager: \(userDataManager != nil ? "✅" : "❌")")
            print("  - VoiceService: \(voiceActivationService != nil ? "✅" : "❌")")
            print("  - AppState: \(appState != nil ? "✅" : "❌")")
        }
    }
}

struct ServiceStatusRow: View {
    let name: String
    let isWorking: Bool
    
    var body: some View {
        HStack {
            Text("• \(name):")
                .font(.caption)
            Spacer()
            Text(isWorking ? "✅" : "❌")
                .font(.caption)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(SimpleNetworkManager.shared)
        .environmentObject(VoiceActivationService.shared)
        .environmentObject(UserDataManager.shared)
}
