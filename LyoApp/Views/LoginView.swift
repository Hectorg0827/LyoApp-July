import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var loginError: String?
    @State private var registerError: String?
    @State private var isRegistering = false
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.4, blue: 0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer()
                            .frame(height: 50)
                        
                        // Logo and Welcome
                        VStack(spacing: 20) {
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text(isRegistering ? "Join LyoApp" : "Welcome Back")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text(isRegistering ? "Create your account to start learning" : "Sign in to continue your learning journey")
                                .font(.body)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Login/Register Form
                        VStack(spacing: 20) {
                            if isRegistering {
                                // Registration fields
                                VStack(spacing: 16) {
                                    CustomTextField(
                                        placeholder: "Full Name",
                                        text: $fullName,
                                        keyboardType: .default,
                                        systemImage: "person"
                                    )
                                    .textContentType(.name)
                                    
                                    CustomTextField(
                                        placeholder: "Username",
                                        text: $username,
                                        keyboardType: .default,
                                        systemImage: "at"
                                    )
                                    .textContentType(.username)
                                    
                                    CustomTextField(
                                        placeholder: "Email",
                                        text: $email,
                                        keyboardType: .emailAddress,
                                        systemImage: "envelope"
                                    )
                                    .textContentType(.emailAddress)
                                    
                                    CustomSecureField(
                                        placeholder: "Password",
                                        text: $password,
                                        systemImage: "lock"
                                    )
                                    .textContentType(.newPassword)
                                    .submitLabel(.go)
                                }
                            } else {
                                // Login fields
                                VStack(spacing: 16) {
                                    CustomTextField(
                                        placeholder: "Email",
                                        text: $email,
                                        keyboardType: .emailAddress,
                                        systemImage: "envelope"
                                    )
                                    .textContentType(.emailAddress)
                                    
                                    CustomSecureField(
                                        placeholder: "Password",
                                        text: $password,
                                        systemImage: "lock"
                                    )
                                    .textContentType(.password)
                                    .submitLabel(.go)
                                }
                            }
                            
                            // Error messages
                            if let loginError = loginError, !isRegistering {
                                VStack(spacing: 8) {
                                    Text(loginError)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .padding(.horizontal)
                                }
                            }
                            
                            if let registerError = registerError, isRegistering {
                                Text(registerError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .padding(.horizontal)
                            }
                            
                            // Action Button
                            Button(action: {
                                if isRegistering {
                                    Task { await register() }
                                } else {
                                    Task { await login() }
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(isRegistering ? "Create Account" : "Sign In")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.9))
                                .foregroundColor(Color(red: 0.1, green: 0.2, blue: 0.4))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                            }
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            
                            // Toggle between login and register
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    isRegistering.toggle()
                                    // Clear errors when toggling
                                    loginError = nil
                                    registerError = nil
                                }
                            }) {
                                Text(isRegistering ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                                    .foregroundColor(.white)
                                    .font(.body)
                            }
                            .disabled(isLoading)
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer()
                            .frame(height: 50)
                    }
                }
            }
        }
        .tint(.white) // cursor/focus color for text fields on dark background
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        if isRegistering {
            return !email.isEmpty && !password.isEmpty && !fullName.isEmpty && !username.isEmpty && isValidEmail(email)
        } else {
            return !email.isEmpty && !password.isEmpty && isValidEmail(email)
        }
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    // MARK: - Authentication Methods
    
    @MainActor
    private func login() async {
        guard !isLoading else { return }
        
        isLoading = true
        loginError = nil
        
        do {
            print("🔐 Attempting login for email: \(email)")
            let response = try await APIClient.shared.login(email: email, password: password)
            
            // Store tokens and update app state
            appState.setAuthTokens(
                accessToken: response.actualAccessToken,
                refreshToken: response.refreshToken ?? response.actualAccessToken,
                userId: response.user.id
            )
            
            print("✅ Login successful for user: \(response.user.email)")
            
        } catch APIClientError.unauthorized {
            loginError = "Invalid email or password. Please try again."
            print("❌ Login failed: Invalid credentials")
        } catch APIClientError.serverError(let code, let message) {
            if code == 401 {
                loginError = "Invalid email or password. Please try again."
            } else if code == 404 {
                loginError = "Authentication service temporarily unavailable. Please try again later."
            } else if code >= 500 {
                loginError = "Server error. Please try again later."
            } else {
                loginError = message ?? "Login failed. Please try again."
            }
            print("❌ Login failed with server response: \(code)")
        } catch let transportError as URLError {
            if transportError.localizedDescription.contains("offline") {
                loginError = "No internet connection. Please check your connection and try again."
            } else {
                loginError = "Network error. Please check your connection and try again."
            }
        } catch let error {
            self.loginError = "Login failed: \(error.localizedDescription)"
            print("❌ Login error: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    private func register() async {
        guard !isLoading else { return }
        
        isLoading = true
        registerError = nil
        
        do {
            print("🔐 Attempting registration for email: \(email)")
            let response = try await APIClient.shared.register(
                email: email,
                password: password,
                username: username,
                fullName: fullName
            )
            
            // Store tokens and update app state
            appState.setAuthTokens(
                accessToken: response.actualAccessToken,
                refreshToken: response.refreshToken ?? response.actualAccessToken,
                userId: response.user.id
            )
            
            print("✅ Registration successful for user: \(response.user.email)")
            
        } catch APIClientError.serverError(let code, let data) {
            if code == 409 {
                registerError = "An account with this email already exists. Please sign in instead."
            } else if code == 400, let data = data, let dataObj = data.data(using: .utf8),
                      let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: dataObj) {
                registerError = errorResponse.detail ?? errorResponse.message ?? "Registration failed. Please check your information."
            } else {
                registerError = "Server error (\(code)). Please try again later."
            }
        } catch APIClientError.networkError(let transportError) {
            if transportError.localizedDescription.contains("offline") {
                registerError = "No internet connection. Please check your connection and try again."
            } else {
                registerError = "Network error. Please check your connection and try again."
            }
        } catch let error {
            self.registerError = "Registration failed: \(error.localizedDescription)"
            print("❌ Registration error: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Custom UI Components

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            // Use custom prompt to control placeholder color for legibility
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundColor(.white.opacity(0.75))
            )
            .keyboardType(keyboardType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

struct CustomSecureField: View {
    let placeholder: String
    @Binding var text: String
    let systemImage: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 20)
            
            SecureField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundColor(.white.opacity(0.75))
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
        )
    }
}

#Preview {
    LoginView()
        .environmentObject(AppState())
}

