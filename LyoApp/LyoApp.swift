import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(.dark) // Force dark mode for futuristic design
                .onAppear {
                    appState.initializeServices()
                    setupFuturisticAppearance()
                }
                .onChange(of: appState.isDarkMode) { _, _ in
                    appState.saveUserPreferences()
                }
        }
    }
    
    private func setupFuturisticAppearance() {
        // Configure global UI appearance for futuristic theme
        
        // TabBar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundColor = UIColor.clear
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        
        // Navigation Bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithTransparentBackground()
        navBarAppearance.backgroundColor = UIColor(DesignTokens.Colors.glassBg)
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(DesignTokens.Colors.textPrimary),
            .font: UIFont.systemFont(ofSize: 20, weight: .semibold)
        ]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView(appState: appState)
            } else {
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
    }
}
