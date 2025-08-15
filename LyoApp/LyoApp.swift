import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var networkManager = SimpleNetworkManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated || networkManager.isAuthenticated {
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(networkManager)
            } else {
                AuthenticationView()
                    .environmentObject(authManager) 
                    .environmentObject(networkManager)
            }
        }
    }
}
