import SwiftUI

// MARK: - Floating AI Avatar Wrapper
struct FloatingAIAvatar: View {
    @Binding var showingAIAvatar: Bool
    @EnvironmentObject var appState: AppState
    @State private var expansion: CGFloat = 0
    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 75, y: UIScreen.main.bounds.height - 250)
    @State private var isDragging = false
    @GestureState private var dragOffset = CGSize.zero
    @State private var showingQuickActions = false
    @State private var animationTimer: Timer?
    
    var body: some View {
        ZStack {
            // Quantum energy background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(0.3),
                            Color.blue.opacity(0.2),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 60
                    )
                )
                .scaleEffect(1 + expansion * 0.5)
                .opacity(0.8)
            
            // Main avatar button with contextual colors
            Circle()
                .fill(
                    LinearGradient(
                        colors: contextualColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 60, height: 60)
                .overlay(
                    ZStack {
                        Image(systemName: contextualIcon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .scaleEffect(1 + expansion * 0.2)
                        
                        // Activity indicator
                        if appState.isLoading || expansion > 0.5 {
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                .frame(width: 28, height: 28)
                                .rotationEffect(.degrees(expansion * 360))
                        }
                    }
                )
                .scaleEffect(isDragging ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            
            // Pulsing ring effect
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                .frame(width: 60, height: 60)
                .scaleEffect(1 + sin(expansion * .pi * 2) * 0.1)
        }
        .position(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
        .gesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in
                    state = value.translation
                    isDragging = true
                }
                .onEnded { value in
                    isDragging = false
                    updatePosition(with: value.translation)
                }
        )
        .onTapGesture {
            if !isDragging {
                triggerAvatarActivation()
            }
        }
        .onAppear {
            startPulseAnimation()
        }
        .accessibilityLabel("AI Learning Assistant")
        .accessibilityHint("Tap to chat with Lyo, your personal AI learning companion")
    }
    
    // MARK: - Contextual Properties
    private var contextualColors: [Color] {
        switch appState.selectedTab {
        case .home:
            return [.purple, .blue, .cyan]
        case .discover:
            return [.orange, .red, .pink]
        case .aiAvatar:
            return [.purple, .cyan, .blue]
        case .post:
            return [.yellow, .orange, .red]
        case .more:
            return [.indigo, .purple, .blue]
        }
    }
    
    private var contextualIcon: String {
        switch appState.selectedTab {
        case .home:
            return "brain.head.profile"
        case .discover:
            return "sparkles"
        case .aiAvatar:
            return "brain.head.profile"
        case .post:
            return "plus.bubble"
        case .more:
            return "ellipsis.bubble"
        }
    }
    
    private func updatePosition(with translation: CGSize) {
        let newX = position.x + translation.width
        let newY = position.y + translation.height
        
        let screenBounds = UIScreen.main.bounds
        let buttonSize: CGFloat = 60
        
        position.x = max(buttonSize/2, min(screenBounds.width - buttonSize/2, newX))
        position.y = max(buttonSize/2, min(screenBounds.height - buttonSize/2, newY))
    }
    
    private func triggerAvatarActivation() {
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Visual expansion effect
        withAnimation(.easeInOut(duration: 0.3)) {
            expansion = 1.0
        }
        
        // Set contextual greeting based on current tab
        setContextualGreeting()
        
        // Reset expansion and show avatar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeInOut(duration: 0.2)) {
                expansion = 0
            }
            showingAIAvatar = true
        }
    }
    
    private func setContextualGreeting() {
        // Set contextual avatar context based on current tab
        switch appState.selectedTab {
        case .home:
            appState.setAvatarContext("home_feed")
        case .discover:
            appState.setAvatarContext("discover_page")
        case .aiAvatar:
            appState.setAvatarContext("ai_avatar_chat")
        case .post:
            appState.setAvatarContext("create_post")
        case .more:
            appState.setAvatarContext("settings_menu")
        }
    }
    
    private func startPulseAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                expansion += 0.02
                if expansion > 1.0 {
                    expansion = 0
                }
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: SimplifiedAuthenticationManager
    @EnvironmentObject var voiceActivationService: VoiceActivationService
    @EnvironmentObject var userDataManager: UserDataManager
    @EnvironmentObject var avatarStore: AvatarStore  // NEW: Avatar store
    @State private var showingAIAvatar = false
    @State private var healthStatus: String = "Checking..."
    @State private var isBackendHealthy = false
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                // Main App Content
                authenticatedContent
            } else {
                // Login Screen
                AuthenticationView()
                    .environmentObject(appState)
                    .environmentObject(authManager)
            }
        }
        .onAppear {
            print("🔍 ContentView appeared")
            checkBackendHealth()
            
            // Development mode helpers (only active in DEBUG builds)
            #if DEBUG
            DevelopmentConfig.validate()
            
            // Optional: Auto-login with test credentials
            if DevelopmentConfig.shouldAutoLogin && !appState.isAuthenticated {
                Task {
                    await appState.performDevelopmentAutoLogin()
                }
            }
            
            // Optional: Skip authentication entirely
            if DevelopmentConfig.shouldSkipAuth && !appState.isAuthenticated {
                appState.enableDevelopmentMode()
            }
            #endif
        }
    }
    
    private var authenticatedContent: some View {
        ZStack {
            TabView(selection: $appState.selectedTab) {
                // Home Feed Tab - ✅ REAL BACKEND DATA ONLY
                HomeFeedView()
                    .tabItem {
                        Label("Home", systemImage: appState.selectedTab == .home ? "house.fill" : "house")
                    }
                    .tag(MainTab.home)
                
                // Discover Tab - ✅ REAL BACKEND DATA ONLY
                HomeFeedView()
                    .tabItem {
                        Label("Discover", systemImage: appState.selectedTab == .discover ? "safari.fill" : "safari")
                    }
                    .tag(MainTab.discover)
                
                // AI Avatar Tab  
                AIAvatarView()
                    .tabItem {
                        Label("AI Avatar", systemImage: appState.selectedTab == .aiAvatar ? "brain.head.profile" : "brain.head.profile")
                    }
                    .tag(MainTab.aiAvatar)
                
                // Create Post Tab (placeholder)
                Text("Create Post")
                    .tabItem {
                        Label("Post", systemImage: "plus")
                    }
                    .tag(MainTab.post)
                
                // More Tab
                MoreTabView()
                    .tabItem {
                        Label("More", systemImage: appState.selectedTab == .more ? "ellipsis.circle.fill" : "ellipsis.circle")
                    }
                    .tag(MainTab.more)
            }
            
            // Backend Health Indicator (top of screen)
            VStack {
                HStack {
                    Circle()
                        .fill(isBackendHealthy ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(healthStatus)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                Spacer()
            }
            
            // Floating AI Avatar - Available on every page (NEW: uses AvatarStore)
            // TODO: Re-enable after adding FloatingAvatarButton.swift to Xcode project
            // if avatarStore.avatar != nil {
            //     FloatingAvatarButton(showingChat: $showingAIAvatar)
            //         .environmentObject(avatarStore)
            // }
        }
        .fullScreenCover(isPresented: $showingAIAvatar) {
            AIAvatarView()
                .environmentObject(appState)
        }
    }
    
    private func checkBackendHealth() {
        print("🔍 Checking backend health...")
        Task {
            do {
                let healthResponse = try await APIClient.shared.healthCheck()
                let isHealthy = healthResponse.status == "healthy"
                await MainActor.run {
                    self.isBackendHealthy = isHealthy
                    self.healthStatus = isHealthy ? "Backend: Online ✅" : "Backend: Issues ⚠️"
                    print("📊 Backend health: \(isHealthy ? "✅ Healthy" : "❌ Issues")")
                }
            } catch {
                await MainActor.run {
                    self.isBackendHealthy = false
                    self.healthStatus = "Backend: Offline ❌"
                    print("❌ Backend health check failed: \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(SimplifiedAuthenticationManager.shared)
        .environmentObject(VoiceActivationService.shared)
        .environmentObject(UserDataManager.shared)
        .environmentObject(AvatarStore())  // NEW: Add avatar store
}
