import SwiftUI
import Combine

@main
struct LyoApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var voiceActivationService = VoiceActivationService.shared
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some Scene {
        WindowGroup {
            MainTabView(appState: appState)
                .environmentObject(appState)
                .environmentObject(voiceActivationService)
                .preferredColorScheme(.dark) // Force dark mode for futuristic design
                .onAppear {
                    appState.initializeServices()
                    setupFuturisticAppearance()
                    initializeAvatarCompanion()
                }
                .onChange(of: appState.isDarkMode) { _, _ in
                    appState.saveUserPreferences()
                }
        }
    }
    
    private func initializeAvatarCompanion() {
        // Avatar Companion system is automatically initialized by the coordinator
        print("🤖 Avatar Companion system starting...")
        
        // Configure voice activation service
        voiceActivationService.configure(
            appState: appState,
            webSocketService: LyoWebSocketService.shared
        )
        
        // Start voice activation if enabled
        if appState.isListeningForWakeWord {
            voiceActivationService.startListening()
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
