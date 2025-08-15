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
        VStack(spacing: Tokens.Spacing.lg) {
            Image(systemName: "book.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Tokens.Colors.primary, Tokens.Colors.accent],
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
                .foregroundColor(Tokens.Colors.primary)
            
            Text("Connecting to learning platform...")
                .font(.body)
                .foregroundColor(Tokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Tokens.Colors.surfaceBackground.ignoresSafeArea())
    }
}

// Temporary main app view - will be replaced with proper navigation
struct MainAppView: View {
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        NavigationView {
            VStack(spacing: Tokens.Spacing.lg) {
                Text("Welcome to Lyo!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                if let user = container.currentUser {
                    Text("Hello, \(user.displayName)!")
                        .font(.title2)
                        .foregroundColor(Tokens.Colors.textSecondary)
                    
                    Text("Email: \(user.email)")
                        .font(.body)
                        .foregroundColor(Tokens.Colors.textSecondary)
                    
                    Text("Points: \(user.stats.totalPoints)")
                        .font(.body)
                        .foregroundColor(Tokens.Colors.primary)
                    
                    Text("Streak: \(user.stats.streak) days")
                        .font(.body)
                        .foregroundColor(Tokens.Colors.accent)
                }
                
                Spacer()
                
                AccessibleButton(
                    title: "Sign Out",
                    style: .secondary,
                    size: .large
                ) {
                    Task {
                        await container.signOut()
                    }
                }
            }
            .padding(Tokens.Spacing.lg)
            .navigationTitle("Lyo")
            .navigationBarTitleDisplayMode(.inline)
        }
        .background(Tokens.Colors.surfaceBackground.ignoresSafeArea())
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
