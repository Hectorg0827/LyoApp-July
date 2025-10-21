import SwiftUI

/// Minimal standalone AI Avatar launcher
/// This replaces the complex ContentView to isolate AI Avatar functionality
struct MinimalAILauncher: View {
    @EnvironmentObject var appState: AppState
    @State private var showAIAvatar = false
    @State private var isAuthenticated = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var fullName = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isRegistering = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [.purple.opacity(0.8), .blue.opacity(0.6), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if isAuthenticated {
                // Main launcher view
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Lyo branding
                    VStack(spacing: 16) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 50))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: .cyan.opacity(0.5), radius: 20)
                        
                        Text("Lyo AI Avatar")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Your AI Learning Companion")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Launch button
                    Button {
                        print("🚀 [MinimalLauncher] Launching AI Avatar...")
                        showAIAvatar = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                            Text("Start AI Session")
                                .font(.title3.bold())
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .cyan.opacity(0.3), radius: 10)
                    }
                    .padding(.horizontal, 40)
                    
                    // Logout button
                    Button {
                        print("🚪 [MinimalLauncher] Logging out...")
                        isAuthenticated = false
                        appState.isAuthenticated = false
                    } label: {
                        Text("Logout")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 40)
                }
            } else {
                // Simple login view
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Branding
                    VStack(spacing: 12) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 60))
                            .foregroundColor(.cyan)
                        
                        Text("Lyo AI")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Login to start your AI session")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Login/Register form
                    VStack(spacing: 16) {
                        // Show additional fields for registration
                        if isRegistering {
                            TextField("Full Name", text: $fullName)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                            
                            TextField("Username", text: $username)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        TextField("Email", text: $email)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        SecureField("Password", text: $password)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.top, 4)
                        }
                        
                        // Main action button (Login or Register)
                        Button {
                            if isRegistering {
                                performRegistration()
                            } else {
                                performLogin()
                            }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isRegistering ? "Create Account" : "Login")
                                        .font(.headline)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.cyan)
                            .cornerRadius(12)
                        }
                        .disabled(isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.5)
                        
                        // Toggle between login and register
                        Button {
                            withAnimation {
                                isRegistering.toggle()
                                errorMessage = nil
                            }
                        } label: {
                            Text(isRegistering ? "Already have an account? Login" : "Don't have an account? Register")
                                .font(.subheadline)
                                .foregroundColor(.cyan)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 40)
                    
                    // Quick test credentials
                    VStack(spacing: 8) {
                        Text("Quick Test")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                        
                        Button {
                            email = "test@test.com"
                            password = "Test123"
                        } label: {
                            Text("Fill Test Credentials")
                                .font(.caption)
                                .foregroundColor(.cyan)
                        }
                    }
                    .padding(.top, 8)
                    
                    Spacer()
                }
            }
        }
        .fullScreenCover(isPresented: $showAIAvatar) {
            AIAvatarView()
                .environmentObject(appState)
        }
    }
    
    private func performLogin() {
        print("🔐 [MinimalLauncher] Attempting REAL backend login...")
        errorMessage = nil
        isLoading = true
        
        // Clear any old mock tokens first
        print("🧹 [MinimalLauncher] Clearing old tokens...")
        TokenStore.shared.clearAllTokens()
        LyoWebSocketService.shared.disconnect()
        
        // Real backend authentication
        Task { @MainActor in
            do {
                // Call the real backend API
                print("📡 [MinimalLauncher] Calling backend login API...")
                let response = try await APIClient.shared.login(email: email, password: password)
                
                print("✅ [MinimalLauncher] Backend login successful!")
                print("   User: \(response.user.username)")
                print("   Token received: \(response.actualAccessToken.prefix(20))...")
                
                // Convert backend user to app user
                let user = User(
                    id: response.user.id,
                    username: response.user.username,
                    email: response.user.email,
                    fullName: response.user.fullName ?? response.user.username,
                    profileImage: response.user.profileImage
                )
                
                // Update app state with authenticated user
                appState.currentUser = user
                appState.isAuthenticated = true
                isAuthenticated = true
                errorMessage = nil
                
                // CRITICAL: Disconnect old WebSocket and reconnect with new token
                print("🔌 [MinimalLauncher] Reconnecting WebSocket with new token...")
                LyoWebSocketService.shared.disconnect()
                LyoWebSocketService.shared.connect(userId: response.user.id, appState: appState)
                
                print("✅ [MinimalLauncher] AppState updated with user and auth token")
                print("✅ [MinimalLauncher] WebSocket reconnected with real token")
                
            } catch let error as APIClientError {
                print("❌ [MinimalLauncher] Backend login failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                isLoading = false
            } catch {
                print("❌ [MinimalLauncher] Login error: \(error.localizedDescription)")
                errorMessage = "Login failed. Please check your credentials."
                isLoading = false
            }
            
            isLoading = false
        }
    }
    
    private func performRegistration() {
        print("📝 [MinimalLauncher] Attempting REAL backend registration...")
        errorMessage = nil
        isLoading = true
        
        // Clear any old mock tokens first
        print("🧹 [MinimalLauncher] Clearing old tokens...")
        TokenStore.shared.clearAllTokens()
        LyoWebSocketService.shared.disconnect()
        
        // Real backend registration
        Task { @MainActor in
            do {
                // Call the real backend API
                print("📡 [MinimalLauncher] Calling backend register API...")
                let response = try await APIClient.shared.register(
                    email: email,
                    password: password,
                    username: username,
                    fullName: fullName
                )
                
                print("✅ [MinimalLauncher] Backend registration successful!")
                print("   User: \(response.user.username)")
                print("   Token received: \(response.actualAccessToken.prefix(20))...")
                
                // Convert backend user to app user
                let user = User(
                    id: response.user.id,
                    username: response.user.username,
                    email: response.user.email,
                    fullName: response.user.fullName ?? response.user.username,
                    profileImage: response.user.profileImage
                )
                
                // Update app state with authenticated user
                appState.currentUser = user
                appState.isAuthenticated = true
                isAuthenticated = true
                errorMessage = nil
                
                // CRITICAL: Disconnect old WebSocket and reconnect with new token
                print("🔌 [MinimalLauncher] Reconnecting WebSocket with new token...")
                LyoWebSocketService.shared.disconnect()
                LyoWebSocketService.shared.connect(userId: response.user.id, appState: appState)
                
                print("✅ [MinimalLauncher] AppState updated with user and auth token")
                print("✅ [MinimalLauncher] WebSocket reconnected with real token")
                
            } catch let error as APIClientError {
                print("❌ [MinimalLauncher] Backend registration failed: \(error.localizedDescription)")
                errorMessage = error.localizedDescription
                isLoading = false
            } catch {
                print("❌ [MinimalLauncher] Registration error: \(error.localizedDescription)")
                errorMessage = "Registration failed. Please try again."
                isLoading = false
            }
            
            isLoading = false
        }
    }
    
    private var isFormValid: Bool {
        if isRegistering {
            return !email.isEmpty && !password.isEmpty && !username.isEmpty && !fullName.isEmpty && password.count >= 6
        } else {
            return !email.isEmpty && !password.isEmpty
        }
    }
}

#Preview {
    MinimalAILauncher()
        .environmentObject(AppState())
}
