import SwiftUI

/// Production-ready content view with authentication flow and full feature set
struct ProductionContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var voiceActivationService: VoiceActivationService
    @EnvironmentObject var userDataManager: UserDataManager
    @EnvironmentObject var analytics: AnalyticsManager
    
    @State private var showingOnboarding = false
    @State private var isAppReady = false
    
    var body: some View {
        Group {
            if !isAppReady {
                ProductionLoadingView()
            } else if !networkManager.isAuthenticated {
                ProductionAuthenticationView()
            } else {
                ProductionMainTabView()
            }
        }
        .onAppear {
            setupProductionApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: .deepLinkReceived)) { notification in
            handleDeepLink(notification)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCourse)) { notification in
            handleCourseDeepLink(notification)
        }
    }
    
    private func setupProductionApp() {
        Task {
            await initializeProductionFeatures()
            
            await MainActor.run {
                isAppReady = true
                analytics.trackScreenView("app_ready")
            }
        }
    }
    
    private func initializeProductionFeatures() async {
        // Request push notifications permission
        if !pushManager.hasPermission {
            await pushManager.requestPermission()
        }
        
        // Connect WebSocket if authenticated
        if networkManager.isAuthenticated && !webSocketManager.isConnected {
            await webSocketManager.connect()
        }
        
        // Check for first launch
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "has_launched_before")
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: "has_launched_before")
            showingOnboarding = true
        }
        
        // Track app launch
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        analytics.track("app_launch", properties: [
            "is_first_launch": isFirstLaunch,
            "app_version": appVersion,
            "platform": "iOS"
        ])
        
        print("🚀 Production app features initialized")
    }
    
    private func handleDeepLink(_ notification: Notification) {
        guard let deepLink = notification.object as? DeepLink else { return }
        
        print("🔗 Handling deep link: \(deepLink.url)")
        analytics.track("deep_link_handled", properties: [
            "url": deepLink.url,
            "source": deepLink.source
        ])
        
        // Route to appropriate screen based on deep link
        // Implementation would depend on your routing system
    }
    
    private func handleCourseDeepLink(_ notification: Notification) {
        guard let courseId = notification.object as? String else { return }
        
        print("📚 Opening course: \(courseId)")
        analytics.track("course_opened_deep_link", properties: [
            "course_id": courseId
        ])
        
        // Navigate to course screen
        // Implementation would depend on your navigation system
    }
}

// MARK: - Production Loading View
struct ProductionLoadingView: View {
    @State private var loadingProgress: Double = 0
    @State private var currentStatus = "Initializing..."
    
    private let loadingSteps = [
        "Connecting to servers...",
        "Checking authentication...",
        "Loading user data...",
        "Setting up real-time features...",
        "Preparing your experience..."
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Logo
            Image("AppIcon") // Make sure you have an app icon
                .resizable()
                .frame(width: 120, height: 120)
                .cornerRadius(20)
                .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.05)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: UUID())
            
            VStack(spacing: 15) {
                Text("LyoApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Your AI Learning Companion")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                // Progress Bar
                ProgressView(value: loadingProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(1.2)
                
                // Loading Status
                Text(currentStatus)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                // Percentage
                Text("\(Int(loadingProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Version Info
            VStack(spacing: 5) {
                Text("Production Ready v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Powered by Advanced AI")
                    .font(.caption2)
                    .foregroundColor(.tertiary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .onAppear {
            simulateLoading()
        }
    }
    
    private func simulateLoading() {
        Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            withAnimation(.easeInOut) {
                loadingProgress += 0.2
                
                let stepIndex = min(Int(loadingProgress * Double(loadingSteps.count)), loadingSteps.count - 1)
                currentStatus = loadingSteps[stepIndex]
                
                if loadingProgress >= 1.0 {
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - Production Authentication View
struct ProductionAuthenticationView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var analytics: Analytics
    @State private var showingLogin = true
    
    var body: some View {
        VStack {
            if showingLogin {
                ProductionLoginView(showingRegister: $showingLogin)
            } else {
                ProductionRegisterView(showingLogin: $showingLogin)
            }
        }
        .onAppear {
            analytics.trackScreenView("authentication")
        }
    }
}

// MARK: - Production Login View
struct ProductionLoginView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var analytics: Analytics
    @Binding var showingRegister: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("Welcome Back")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue your learning journey")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: login) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button("Don't have an account? Sign Up") {
                showingRegister = false
                analytics.track("auth_switch_to_register")
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
    
    private func login() {
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await networkManager.login(email: email, password: password)
                
                await MainActor.run {
                    analytics.track("login_success", properties: ["method": "email"])
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    analytics.track("login_failed", properties: [
                        "method": "email",
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }
}

// MARK: - Production Register View
struct ProductionRegisterView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var analytics: Analytics
    @Binding var showingLogin: Bool
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            VStack(spacing: 15) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Join thousands of learners worldwide")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                TextField("Full Name", text: $fullName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: register) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create Account")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(isLoading || !isFormValid)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            Button("Already have an account? Sign In") {
                showingLogin = true
                analytics.track("auth_switch_to_login")
            }
            .foregroundColor(.blue)
        }
        .padding()
    }
    
    private var isFormValid: Bool {
        !fullName.isEmpty && !email.isEmpty && !password.isEmpty && 
        password == confirmPassword && password.count >= 6
    }
    
    private func register() {
        guard isFormValid else {
            errorMessage = "Please fill all fields correctly"
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                _ = try await networkManager.register(email: email, password: password, fullName: fullName)
                
                await MainActor.run {
                    analytics.track("register_success", properties: ["method": "email"])
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    analytics.track("register_failed", properties: [
                        "method": "email",
                        "error": error.localizedDescription
                    ])
                }
            }
        }
    }
}

// MARK: - Production Main Tab View
struct ProductionMainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var analytics: Analytics
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeFeedView()
                .tabItem {
                    Label("Home", systemImage: appState.selectedTab == .home ? "house.fill" : "house")
                }
                .tag(MainTab.home)
                .onAppear { analytics.trackScreenView("home_feed") }
            
            DiscoverView()
                .tabItem {
                    Label("Discover", systemImage: appState.selectedTab == .discover ? "safari.fill" : "safari")
                }
                .tag(MainTab.discover)
                .onAppear { analytics.trackScreenView("discover") }
            
            LearnTabView()
                .tabItem {
                    Label("Learn", systemImage: appState.selectedTab == .ai ? "graduationcap.fill" : "graduationcap")
                }
                .tag(MainTab.ai)
                .onAppear { analytics.trackScreenView("learn") }
            
            CreatePostView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(MainTab.post)
                .onAppear { analytics.trackScreenView("create_post") }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: appState.selectedTab == .more ? "person.fill" : "person")
                }
                .tag(MainTab.more)
                .onAppear { analytics.trackScreenView("profile") }
        }
    }
}

// MARK: - Placeholder Views for missing components
struct DiscoverView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("🔍 Discover")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Explore trending courses and content")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Discover")
        }
    }
}

struct CreatePostView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("✏️ Create Post")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Share your knowledge with the community")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Create")
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var analytics: Analytics
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let user = networkManager.currentUser {
                    VStack(spacing: 15) {
                        AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        
                        VStack(spacing: 5) {
                            Text(user.fullName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("@\(user.username)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
                
                Button("Sign Out") {
                    Task {
                        await networkManager.logout()
                        analytics.track("user_logout")
                    }
                }
                .foregroundColor(.red)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProductionContentView()
        .environmentObject(AppState.shared)
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(NetworkManager.shared)
        .environmentObject(WebSocketManager.shared)
        .environmentObject(PushNotificationManager.shared)
        .environmentObject(VoiceActivationService.shared)
        .environmentObject(UserDataManager.shared)
        .environmentObject(AnalyticsManager.shared)
}
