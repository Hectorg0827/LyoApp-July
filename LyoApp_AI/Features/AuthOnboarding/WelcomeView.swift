import SwiftUI

struct WelcomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: Tokens.Spacing.xl) {
                Spacer()
                
                // Logo and Brand
                VStack(spacing: Tokens.Spacing.lg) {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Tokens.Colors.brand, Tokens.Colors.accent],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .overlay(
                            Text("Lyo")
                                .font(Typography.display3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                    
                    VStack(spacing: Tokens.Spacing.sm) {
                        Text("Welcome to Lyo")
                            .font(Typography.h1)
                            .foregroundColor(Tokens.Colors.textPrimary)
                        
                        Text("The revolutionary AI-powered learning platform that adapts to your unique style")
                            .font(Typography.bodyLarge)
                            .foregroundColor(Tokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                // Social Login Buttons
                VStack(spacing: Tokens.Spacing.md) {
                    NavigationLink(destination: SocialLoginView()) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Get Started")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Tokens.Colors.brand)
                        .cornerRadius(Tokens.Radius.md)
                    }
                    
                    Text("Join thousands of learners worldwide")
                        .font(Typography.caption)
                        .foregroundColor(Tokens.Colors.textTertiary)
                }
                
                Spacer()
            }
            .padding(Tokens.Spacing.xl)
            .background(
                LinearGradient(
                    colors: [
                        Tokens.Colors.primaryBg,
                        Tokens.Colors.secondaryBg.opacity(0.3),
                        Tokens.Colors.primaryBg
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct SocialLoginView: View {
    @EnvironmentObject var container: AppContainer
    @StateObject private var authState = AuthState() // Create locally to avoid dependency issues
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            // Header
            VStack(spacing: Tokens.Spacing.md) {
                Text("Sign In")
                    .font(Typography.h1)
                    .foregroundColor(Tokens.Colors.textPrimary)
                
                Text("Choose your preferred sign-in method")
                    .font(Typography.body)
                    .foregroundColor(Tokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Social Login Buttons
            VStack(spacing: Tokens.Spacing.md) {
                // Sign in with Apple
                Button(action: {
                    handleAppleSignIn()
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                        Text("Continue with Apple")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(Tokens.Radius.md)
                }
                
                // Sign in with Google
                LyoButton("Continue with Google", style: .secondary) {
                    handleGoogleSignIn()
                }
                
                // Sign in with Meta
                LyoButton("Continue with Facebook", style: .secondary) {
                    handleMetaSignIn()
                }
            }
            
            if isLoading {
                ProgressView()
                    .padding()
            }
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(Typography.caption)
                    .foregroundColor(Tokens.Colors.error)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            
            Spacer()
            
            // Terms and Privacy
            VStack(spacing: Tokens.Spacing.sm) {
                Text("By continuing, you agree to our")
                    .font(Typography.caption)
                    .foregroundColor(Tokens.Colors.textTertiary)
                
                HStack(spacing: Tokens.Spacing.sm) {
                    Button("Terms of Service") {
                        // Open terms
                    }
                    .font(Typography.caption)
                    .foregroundColor(Tokens.Colors.brand)
                    
                    Text("and")
                        .font(Typography.caption)
                        .foregroundColor(Tokens.Colors.textTertiary)
                    
                    Button("Privacy Policy") {
                        // Open privacy policy
                    }
                    .font(Typography.caption)
                    .foregroundColor(Tokens.Colors.brand)
                }
            }
        }
        .padding(Tokens.Spacing.xl)
        .background(Tokens.Colors.primaryBg)
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Authentication Methods
    private func generateNonce() -> String {
        // Generate a secure random nonce for Apple Sign In
        let nonce = UUID().uuidString
        return nonce
    }
    
    private func handleAppleSignIn() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Simulate Apple Sign In with mock tokens
                let mockTokens = AuthTokens(
                    accessToken: "mock_apple_token",
                    refreshToken: "mock_refresh_token", 
                    expiresIn: 3600,
                    tokenType: "Bearer"
                )
                
                await MainActor.run {
                    isLoading = false
                }
                
                await authState.login(with: mockTokens)
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        // Implement Google Sign In
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // For now, simulate success with mock data
                let mockTokens = AuthTokens(
                    accessToken: "mock_google_token",
                    refreshToken: "mock_refresh_token",
                    expiresIn: 3600,
                    tokenType: "Bearer"
                )
                
                await MainActor.run {
                    isLoading = false
                }
                
                await authState.login(with: mockTokens)
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func handleMetaSignIn() {
        // Implement Meta/Facebook Sign In
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // For now, simulate success with mock data
                let mockTokens = AuthTokens(
                    accessToken: "mock_meta_token",
                    refreshToken: "mock_refresh_token",
                    expiresIn: 3600,
                    tokenType: "Bearer"
                )
                
                await MainActor.run {
                    isLoading = false
                }
                
                await authState.login(with: mockTokens)
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SocialLoginView()
            .environmentObject(AppContainer.development())
    }
}
