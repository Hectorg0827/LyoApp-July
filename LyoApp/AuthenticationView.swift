import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
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
                TextField("Full Name", text: $fullName)
                    .modernTextField()
                
                TextField("Username", text: $username)
                    .modernTextField()
                    .autocapitalization(.none)
            }
            
            TextField("Email", text: $email)
                .modernTextField(isFocused: emailFocused)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .onFocusChange { focused in
                    emailFocused = focused
                }
            
            SecureField("Password", text: $password)
                .modernTextField(isFocused: passwordFocused)
                .onFocusChange { focused in
                    passwordFocused = focused
                }
            
            if !isLoginMode {
                SecureField("Confirm Password", text: $confirmPassword)
                    .modernTextField()
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
        Button(isLoginMode ? "Sign In" : "Create Account") {
            performAuthentication()
        }
        .primaryButton(isLoading: isLoading)
        .disabled(isLoading || !isFormValid)
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
    
    private var socialLoginSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                VStack { Divider() }
                Text("OR")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                VStack { Divider() }
            }
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Button {
                    // Handle Apple Sign In
                } label: {
                    HStack {
                        Image(systemName: "apple.logo")
                        Text("Continue with Apple")
                    }
                }
                .secondaryButton()
                
                Button {
                    // Handle Google Sign In
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Continue with Google")
                    }
                }
                .secondaryButton()
            }
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
        isLoading = true
        
        Task {
            await MainActor.run {
                // Simulate API call
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    isLoading = false
                    
                    if isLoginMode {
                        performLogin()
                    } else {
                        performRegistration()
                    }
                }
            }
        }
    }
    
    private func performLogin() {
        // Simulate login logic
        if email.lowercased() == "demo@lyoapp.com" && password == "password" {
            let user = User(
                username: "demo_user",
                email: email,
                fullName: "Demo User",
                bio: "Welcome to LyoApp!",
                followers: 150,
                following: 200,
                posts: 25,
                isVerified: true
            )
            
            Task { @MainActor in
                appState.currentUser = user
                appState.isAuthenticated = true
            }
            
            NotificationCenter.default.post(
                name: .userDidLogin,
                object: user
            )
        } else {
            alertMessage = "Invalid credentials. Use demo@lyoapp.com / password"
            showAlert = true
        }
    }
    
    private func performRegistration() {
        // Simulate registration logic
        let user = User(
            username: username,
            email: email,
            fullName: fullName,
            bio: "New to LyoApp!"
        )
        
        Task { @MainActor in
            Task { @MainActor in
                appState.currentUser = user
                appState.isAuthenticated = true
            }
        }
        
        NotificationCenter.default.post(
            name: .userDidLogin,
            object: user
        )
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

#Preview {
    AuthenticationView()
        .environmentObject(AppState())
}
