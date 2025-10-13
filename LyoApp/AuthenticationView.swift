import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: SimplifiedAuthenticationManager
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var username = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var emailFocused = false
    @State private var passwordFocused = false
    @StateObject private var appleSignInHelper = AppleSignInHelper()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Header
                    headerSection
                    
                    // Form
                    formSection
                    
                    // Action Button
                    actionButton
                    
                    // Toggle Mode
                    toggleModeSection
                    
                    // Working Mode Access
                    workingModeSection
                    
                    // Social Login
                    socialLoginSection
                    
                    Spacer()
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.background)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .navigationBarHidden(true)
        }
        .alert("Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // App Logo/Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundStyle(DesignTokens.Colors.primaryGradient)
                .padding(.bottom, DesignTokens.Spacing.sm)
            
            Text("LyoApp")
                .font(DesignTokens.Typography.hero)
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(isLoginMode ? "Welcome back!" : "Join the community")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
        }
        .padding(.top, DesignTokens.Spacing.xxl)
    }
    
    private var formSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            if !isLoginMode {
                TextField(
                    "",
                    text: $fullName,
                    prompt: Text("Full Name").foregroundColor(DesignTokens.Colors.textSecondary)
                )
                .modernTextField()
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .tint(DesignTokens.Colors.primary)
                
                TextField(
                    "",
                    text: $username,
                    prompt: Text("Username").foregroundColor(DesignTokens.Colors.textSecondary)
                )
                .modernTextField()
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .tint(DesignTokens.Colors.primary)
            }
            
            TextField(
                "",
                text: $email,
                prompt: Text("Email").foregroundColor(DesignTokens.Colors.textSecondary)
            )
            .modernTextField(isFocused: emailFocused)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .onFocusChange { focused in
                emailFocused = focused
            }
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .tint(DesignTokens.Colors.primary)
            
            SecureField(
                "",
                text: $password,
                prompt: Text("Password").foregroundColor(DesignTokens.Colors.textSecondary)
            )
            .modernTextField(isFocused: passwordFocused)
            .textContentType(isLoginMode ? .password : .newPassword)
            .onFocusChange { focused in
                passwordFocused = focused
            }
            .foregroundStyle(DesignTokens.Colors.textPrimary)
            .tint(DesignTokens.Colors.primary)
            
            if !isLoginMode {
                SecureField(
                    "",
                    text: $confirmPassword,
                    prompt: Text("Confirm Password").foregroundColor(DesignTokens.Colors.textSecondary)
                )
                .modernTextField()
                .textContentType(.newPassword)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
                .tint(DesignTokens.Colors.primary)
            }
            
            if isLoginMode {
                HStack {
                    Spacer()
                    Button("Forgot Password?") {
                        // Handle forgot password
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
        .cardStyle()
    }
    
    private var actionButton: some View {
        VStack(spacing: 8) {
            Button(isLoginMode ? "Sign In" : "Create Account") {
                performAuthentication()
            }
            .primaryButton(isLoading: isLoading)
            .disabled(isLoading || !isFormValid)
            
            // Debug info (remove this after testing)
            #if DEBUG
            if !isFormValid {
                Text("Form incomplete: \(validationDebugText)")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            #endif
        }
    }
    
    private var validationDebugText: String {
        if isLoginMode {
            var issues: [String] = []
            if email.isEmpty { issues.append("email empty") }
            else if !isValidEmail(email) { issues.append("email invalid") }
            if password.isEmpty { issues.append("password empty") }
            return issues.joined(separator: ", ")
        } else {
            var issues: [String] = []
            if email.isEmpty { issues.append("email empty") }
            else if !isValidEmail(email) { issues.append("email invalid") }
            if password.isEmpty { issues.append("password empty") }
            else if password.count < 6 { issues.append("password too short") }
            if confirmPassword.isEmpty { issues.append("confirm password empty") }
            else if password != confirmPassword { issues.append("passwords don't match") }
            if fullName.isEmpty { issues.append("full name empty") }
            if username.isEmpty { issues.append("username empty") }
            return issues.joined(separator: ", ")
        }
    }
    
    private var toggleModeSection: some View {
        HStack {
            Text(isLoginMode ? "Don't have an account?" : "Already have an account?")
                .font(DesignTokens.Typography.footnote)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
            
            Button(isLoginMode ? "Sign Up" : "Sign In") {
                withAnimation(DesignTokens.Animations.smooth) {
                    isLoginMode.toggle()
                    clearForm()
                }
            }
            .font(DesignTokens.Typography.footnote)
            .foregroundColor(DesignTokens.Colors.primary)
        }
    }
    
    private var workingModeSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                VStack { Divider() }
                Text("SECURE LOGIN REQUIRED")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                VStack { Divider() }
            }
            
            Text("Create an account or sign in to access your personalized learning experience")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    private var socialLoginSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                VStack { Divider() }
                Text("OR")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                VStack { Divider() }
            }
            
            // Always show informational message about limitations
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("Social Sign-In Not Yet Available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                
                Text("Please use email registration above.\nApple/Google Sign-In requires Apple Developer Account setup.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
        }
        .padding(.top, DesignTokens.Spacing.lg)
    }
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty && isValidEmail(email)
        } else {
            return !email.isEmpty && !password.isEmpty && !confirmPassword.isEmpty &&
                   !fullName.isEmpty && !username.isEmpty && isValidEmail(email) &&
                   password == confirmPassword && password.count >= 6
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: email)
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        fullName = ""
        username = ""
    }
    
    private func performAuthentication() {
        print("🔐 performAuthentication called")
        print("🔐 isLoginMode: \(isLoginMode)")
        print("🔐 email: \(email)")
        print("🔐 password: \(password.isEmpty ? "empty" : "filled")")
        
        isLoading = true
        
        Task {
            do {
                if isLoginMode {
                    print("🔐 Attempting login...")
                    try await performLogin()
                } else {
                    print("🔐 Attempting registration...")
                    print("🔐 username: \(username)")
                    print("🔐 fullName: \(fullName)")
                    try await performRegistration()
                }
            } catch {
                print("❌ Authentication error: \(error)")
                await MainActor.run {
                    isLoading = false
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func performLogin() async throws {
        print("🔐 performLogin: calling authManager.login")
        let result = await authManager.login(username: email, password: password)
        print("🔐 performLogin: got result")
        
        switch result {
        case .success(let user):
            print("✅ Login successful: \(user.username)")
            await MainActor.run {
                isLoading = false
                print("✅ Setting authenticated user")
                appState.setAuthenticatedUser(user)
                print("✅ User authenticated, isAuthenticated: \(appState.isAuthenticated)")
            }
        case .failure(let authError):
            print("❌ Login failed: \(authError)")
            throw authError
        }
    }
    
    private func performRegistration() async throws {
        print("🔐 performRegistration: calling authManager.register")
        print("🔐   username: \(username)")
        print("🔐   email: \(email)")
        print("🔐   fullName: \(fullName)")
        
        let result = await authManager.register(
            username: username,
            email: email,
            password: password,
            fullName: fullName
        )
        print("🔐 performRegistration: got result")
        
        switch result {
        case .success(let user):
            print("✅ Registration successful: \(user.username)")
            await MainActor.run {
                isLoading = false
                print("✅ Setting authenticated user")
                appState.setAuthenticatedUser(user)
                print("✅ User authenticated, isAuthenticated: \(appState.isAuthenticated)")
            }
        case .failure(let authError):
            print("❌ Registration failed: \(authError)")
            throw authError
        }
    }
    
    // MARK: - Social Authentication Handlers
    
    private func handleAppleSignIn() {
        print("🍎 Apple Sign-In button tapped")
        isLoading = true
        
        Task {
            do {
                print("🍎 Requesting Apple Sign-In...")
                let result = try await appleSignInHelper.signIn()
                print("🍎 Apple Sign-In successful: \(result.userIdentifier)")
                
                // Create user from Apple Sign-In result
                let user = User(
                    id: UUID(),
                    username: result.email?.split(separator: "@").first.map(String.init) ?? "user_\(UUID().uuidString.prefix(8))",
                    email: result.email ?? "\(result.userIdentifier)@appleid.privaterelay.com",
                    fullName: result.fullName ?? "Apple User",
                    bio: "Signed in with Apple"
                )
                
                print("🍎 Storing Apple user: \(user.email)")
                // Store user locally
                await authManager.storeAppleUser(user)
                
                await MainActor.run {
                    print("🍎 Setting authenticated user")
                    isLoading = false
                    appState.setAuthenticatedUser(user)
                }
            } catch {
                print("❌ Apple Sign-In error: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    
                    // Check if this is a simulator/cancellation error
                    let nsError = error as NSError
                    if nsError.code == 1000 || nsError.domain.contains("ASAuthorization") {
                        alertMessage = """
                        Apple Sign-In is not available in Simulator.
                        
                        Please either:
                        • Use email registration (form above)
                        • Test on a real iOS device
                        
                        Note: Apple Sign-In requires proper App ID configuration in your Apple Developer account.
                        """
                    } else {
                        alertMessage = "Apple Sign-In failed: \(error.localizedDescription)"
                    }
                    showAlert = true
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        isLoading = true
        alertMessage = "Google Sign-In integration requires Google SDK setup. Please use email registration for now."
        showAlert = true
        isLoading = false
        
        // TODO: Implement Google Sign-In with GoogleSignIn SDK
        // This requires:
        // 1. Google Cloud Console configuration
        // 2. GoogleSignIn SDK integration
        // 3. Backend endpoint for /auth/google
    }
}

// MARK: - Focus State Extension
extension View {
    func onFocusChange(_ action: @escaping (Bool) -> Void) -> some View {
        self.modifier(FocusChangeModifier(action: action))
    }
}

struct FocusChangeModifier: ViewModifier {
    let action: (Bool) -> Void
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, newValue in
                action(newValue)
            }
    }
}

// MARK: - Apple Sign-In Helper
@MainActor
class AppleSignInHelper: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private var continuation: CheckedContinuation<AppleSignInResult, Error>?
    
    struct AppleSignInResult {
        let userIdentifier: String
        let email: String?
        let fullName: String?
    }
    
    func signIn() async throws -> AppleSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                continuation?.resume(throwing: NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential"]))
                continuation = nil
                return
            }
            
            let userIdentifier = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName: String? = {
                if let givenName = appleIDCredential.fullName?.givenName,
                   let familyName = appleIDCredential.fullName?.familyName {
                    return "\(givenName) \(familyName)"
                }
                return nil
            }()
            
            let result = AppleSignInResult(
                userIdentifier: userIdentifier,
                email: email,
                fullName: fullName
            )
            
            continuation?.resume(returning: result)
            continuation = nil
        }
    }
    
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            // Check for specific error codes
            let nsError = error as NSError
            print("🍎 Apple Sign-In error: \(nsError.code) - \(nsError.localizedDescription)")
            
            // Error 1000 = User canceled or simulator limitation
            if nsError.code == 1000 {
                let simulatorError = NSError(
                    domain: "AppleSignIn",
                    code: nsError.code,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Apple Sign-In may not work properly in Simulator. Please use email registration or test on a real device."
                    ]
                )
                continuation?.resume(throwing: simulatorError)
            } else {
                continuation?.resume(throwing: error)
            }
            continuation = nil
        }
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AppState())
}
