import SwiftUI

@main
struct LyoApp: App {
    @StateObject private var container = AppContainer.production() // Use live backend services
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(container)
                .preferredColorScheme(.light)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        print("🚀 LyoApp started with live backend connection")
        print("📱 Backend URL: http://localhost:8002")
        print("🔐 Authentication: \(container.tokenProvider.isAuthenticated ? "Active" : "Required")")
        
        // Load initial authentication state
        if container.tokenProvider.isAuthenticated {
            Task {
                await container.loadCurrentUser()
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        Group {
            if container.isLoading {
                LoadingView()
            } else if container.isAuthenticated {
                MainAppView()
            } else {
                WelcomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: container.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: container.isLoading)
    }
}

struct LoadingView: View {
    @State private var rotation: Double = 0
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "book.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [DesignTokens.Colors.primary, DesignTokens.Colors.accent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        rotation = 360
                    }
                }
            
            Text("Lyo")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text("Connecting to learning platform...")
                .font(.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
    }
}

// Main app view with proper navigation
struct MainAppView: View {
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        MainTabView()
            .environmentObject(container)
    }
}

// MARK: - Development Previews
#Preview("Loading") {
    LoadingView()
}

#Preview("Main App") {
    MainAppView()
        .environmentObject(AppContainer.development())
}

#Preview("Welcome") {
    WelcomeView()
        .environmentObject(AppContainer.development())
}
