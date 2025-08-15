import SwiftUI

// Backup LyoApp implementation (disabled from build to avoid duplicate @main/App types)
#if DEBUG && false
struct BackupLyoAppContainer: App {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var networkManager = SimpleNetworkManager.shared
    
    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                // Your original main app view
                ContentView()
                    .environmentObject(authManager)
                    .environmentObject(networkManager)
            } else {
                // Authentication view with backend integration
                WorkingAuthenticationView()
                    .environmentObject(authManager)
                    .environmentObject(networkManager)
            }
        }
    }
}

struct WorkingAuthenticationView_BuildOnly: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var networkManager: SimpleNetworkManager
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isLoginMode = true
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("LyoApp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isLoginMode ? "Welcome back!" : "Join the community")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                // Form
                VStack(spacing: 16) {
                    if !isLoginMode {
                        TextField("Full Name", text: $fullName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // Action Button
                Button(isLoginMode ? "Sign In" : "Create Account") {
                    performAuthentication()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading)
                
                // Toggle Mode
                Button(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Sign In") {
                    isLoginMode.toggle()
                    errorMessage = ""
                }
                .foregroundColor(.blue)
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                if isLoading {
                    ProgressView()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func performAuthentication() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                if isLoginMode {
                    let response = try await networkManager.login(email: email, password: password)
                    await MainActor.run {
                        authManager.currentUser = User(
                            username: response.user.username ?? response.user.name,
                            email: response.user.email,
                            fullName: response.user.name,
                            bio: response.user.bio ?? "Welcome to LyoApp!",
                            followers: 0,
                            following: 0,
                            posts: 0
                        )
                        authManager.isAuthenticated = true
                    }
                } else {
                    let response = try await networkManager.register(name: fullName, email: email, password: password)
                    await MainActor.run {
                        authManager.currentUser = User(
                            username: response.user.username ?? response.user.name,
                            email: response.user.email,
                            fullName: response.user.name,
                            bio: response.user.bio ?? "Welcome to LyoApp!",
                            followers: 0,
                            following: 0,
                            posts: 0
                        )
                        authManager.isAuthenticated = true
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}
#endif

#if false
@main
struct LyoApp: App {
    var body: some Scene {
        WindowGroup {
            WorkingAuthenticationView()
        }
    }
}

struct WorkingAuthenticationView: View {
    var body: some View {
        Text("Working Auth View")
    }
}
#endif
