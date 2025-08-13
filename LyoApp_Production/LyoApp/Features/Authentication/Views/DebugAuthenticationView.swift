import SwiftUI

struct DebugAuthenticationView: View {
    @State private var isLoginMode = true
    @State private var email = "test@lyo.app"
    @State private var password = "password123"
    @State private var fullName = "Test User"
    @State private var debugMessage = ""
    @State private var isLoading = false
    
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Logo/Header
                    VStack(spacing: 10) {
                        Image(systemName: "graduation.cap.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("Welcome to Lyo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Debug Authentication Mode")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 20)
                    
                    // Debug Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("🔧 Debug Information:")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        Text("Backend: \(BackendConfig.fullBaseURL)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Auth Status: \(authManager.isAuthenticated ? "✅ Authenticated" : "❌ Not Authenticated")")
                            .font(.caption)
                            .foregroundColor(authManager.isAuthenticated ? .green : .red)
                        
                        Text("Network: \(authManager.networkManager.isConnected ? "🟢 Connected" : "🔴 Offline")")
                            .font(.caption)
                            .foregroundColor(authManager.networkManager.isConnected ? .green : .red)
                        
                        if !debugMessage.isEmpty {
                            Text("Debug: \(debugMessage)")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 4)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Form
                    VStack(spacing: 16) {
                        if !isLoginMode {
                            TextField("Full Name", text: $fullName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .autocapitalization(.words)
                        }
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // Test Connection Button
                        Button("🧪 Test Backend Connection") {
                            Task {
                                await testBackendConnection()
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal, 30)
                    
                    // Error Message
                    if let errorMessage = authManager.errorMessage {
                        Text("❌ Error: \(errorMessage)")
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    // Primary Button
                    Button(action: {
                        debugMessage = "🔄 Starting authentication..."
                        Task {
                            if isLoginMode {
                                debugMessage = "📤 Calling login..."
                                await authManager.login(email: email, password: password)
                                debugMessage = "✅ Login call completed"
                            } else {
                                debugMessage = "📤 Calling register..."
                                await authManager.register(email: email, password: password, fullName: fullName)
                                debugMessage = "✅ Register call completed"
                            }
                        }
                    }) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            }
                            Text(isLoginMode ? "🔐 Log In" : "📝 Sign Up")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    .disabled(authManager.isLoading || email.isEmpty || password.isEmpty || (!isLoginMode && fullName.isEmpty))
                    .padding(.horizontal, 30)
                    
                    // Toggle Mode
                    Button(action: {
                        isLoginMode.toggle()
                        authManager.errorMessage = nil
                        debugMessage = "Switched to \(isLoginMode ? "Login" : "Register") mode"
                    }) {
                        HStack {
                            Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                                .foregroundColor(.secondary)
                            Text(isLoginMode ? "Sign Up" : "Log In")
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemBackground))
        }
        .onAppear {
            debugMessage = "View appeared - checking auth status..."
            authManager.checkAuthenticationStatus()
        }
    }
    
    private func testBackendConnection() async {
        debugMessage = "🧪 Testing backend connection..."
        
        do {
            let health = try await authManager.networkManager.healthCheck()
            debugMessage = "✅ Backend connected! Status: \(health.status)"
        } catch {
            debugMessage = "❌ Backend connection failed: \(error.localizedDescription)"
        }
    }
}
