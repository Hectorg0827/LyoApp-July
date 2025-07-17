import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var voiceActivationService = VoiceActivationService()
    
    var body: some Scene {
        WindowGroup {
            MainTabView(appState: appState)
                .environmentObject(appState)
                .environmentObject(voiceActivationService)
                .preferredColorScheme(.dark) // Force dark mode for futuristic design
                .onAppear {
                    appState.initializeServices()
                    setupFuturisticAppearance()
                    // Start voice activation service if enabled
                    if appState.isListeningForWakeWord {
                        voiceActivationService.startListening()
                    }
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

// ContentView is in its own file
