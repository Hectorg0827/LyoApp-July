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
        print("📊 Container isLoading: \(container.isLoading)")
        print("🎯 Container isAuthenticated: \(container.isAuthenticated)")
        
        // Load initial authentication state
        if container.tokenProvider.isAuthenticated {
            Task {
                print("🔄 Loading current user...")
                await container.loadCurrentUser()
                print("✅ Current user load completed")
            }
        } else {
            print("ℹ️ No stored authentication found")
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var container: AppContainer
    @State private var hasError = false
    @State private var errorMessage = ""
    
    var body: some View {
        Group {
            if hasError {
                // Error fallback view
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(DesignTokens.Colors.warning)
                    
                    Text("Something went wrong")
                        .font(DesignTokens.Typography.headlineMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(errorMessage)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        hasError = false
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                    .padding()
                    .background(DesignTokens.Colors.glassBg)
                    .cornerRadius(DesignTokens.Radius.md)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            } else if container.isLoading {
                LoadingView()
            } else if container.isAuthenticated {
                SafeMainAppView()
            } else {
                SafeWelcomeView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: container.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: container.isLoading)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AppError"))) { notification in
            if let error = notification.object as? Error {
                hasError = true
                errorMessage = error.localizedDescription
            }
        }
    }
}

// Safe wrapper for MainAppView
struct SafeMainAppView: View {
    @EnvironmentObject var container: AppContainer
    @State private var viewError: Error?
    
    var body: some View {
        Group {
            if viewError != nil {
                // Fallback to a simple main view
                SimpleMainView()
            } else {
                MainAppView()
                    .onAppear {
                        viewError = nil
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ViewError"))) { notification in
            if let error = notification.object as? Error {
                viewError = error
            }
        }
    }
}

// Simple fallback main view
struct SimpleMainView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Welcome to Lyo!")
                .font(DesignTokens.Typography.headlineLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Your learning journey starts here.")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            // Simple navigation buttons
            VStack(spacing: DesignTokens.Spacing.md) {
                Button("Explore Courses") {
                    // Navigate to courses
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(DesignTokens.Colors.primary)
                .cornerRadius(DesignTokens.Radius.md)
                
                Button("Browse Content") {
                    // Navigate to content
                }
                .foregroundColor(DesignTokens.Colors.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(DesignTokens.Colors.glassBg)
                .cornerRadius(DesignTokens.Radius.md)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
    }
}

// Safe wrapper for WelcomeView  
struct SafeWelcomeView: View {
    @State private var viewError: Error?
    
    var body: some View {
        Group {
            if viewError != nil {
                SimpleWelcomeView()
            } else {
                WelcomeView()
                    .onAppear {
                        viewError = nil
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ViewError"))) { notification in
            if let error = notification.object as? Error {
                viewError = error
            }
        }
    }
}

// Simple fallback welcome view
struct SimpleWelcomeView: View {
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            // Simple branding
            VStack(spacing: DesignTokens.Spacing.lg) {
                Circle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .frame(width: 120, height: 120)
                    .overlay(
                        Text("L")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text("Welcome to Lyo")
                    .font(DesignTokens.Typography.headlineLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("The AI-powered learning platform")
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Simple sign in button
            Button(action: {
                Task {
                    await container.signIn(with: "mock", token: "demo_token")
                }
            }) {
                Text("Get Started")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.Colors.primary)
                    .cornerRadius(DesignTokens.Radius.md)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
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
