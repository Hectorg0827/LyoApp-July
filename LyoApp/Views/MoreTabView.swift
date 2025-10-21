import SwiftUI

struct MoreTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingAIChat = false
    @State private var showingLearningAnalytics = false
    @State private var showingStudyGroups = false
    @State private var showingCommunity = false
    @State private var showingAchievements = false
    @State private var showingConnectivityTest = false
    @State private var showingEnvironmentPicker = false
    @State private var showingUnityTests = false
    
    // MARK: - API Integration State
    @State private var userStudyGroups: [StudyGroupAPI] = []
    @State private var availableStudyGroups: [StudyGroupAPI] = []
    @State private var groupRequests: [GroupRequest] = []
    @State private var userAchievements: [DetailedAchievement] = []
    @State private var isLoadingGroups = false
    @State private var isLoadingAchievements = false
    
    // API Client
    private let apiClient = APIClient.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Header
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Text("More")
                            .font(DesignTokens.Typography.title1)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("Explore additional features")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .padding(.top, DesignTokens.Spacing.xl)
                    
                    // Menu Items
                    VStack(spacing: DesignTokens.Spacing.md) {
                        MoreMenuItem(
                            icon: "sparkles",
                            title: "AI Assistant",
                            subtitle: "Chat with Lyo AI",
                            color: DesignTokens.Colors.primary
                        ) {
                            showingAIChat = true
                        }
                        
                        MoreMenuItem(
                            icon: "brain.filled",
                            title: "Learning Analytics",
                            subtitle: "Track your progress",
                            color: DesignTokens.Colors.neonPurple
                        ) {
                            showingLearningAnalytics = true
                        }
                        
                        MoreMenuItem(
                            icon: "book.circle",
                            title: "Study Groups",
                            subtitle: "Join collaborative learning",
                            color: DesignTokens.Colors.neonBlue
                        ) {
                            showingStudyGroups = true
                        }
                        
                        MoreMenuItem(
                            icon: "person.3.fill",
                            title: "Community",
                            subtitle: "Connect with learners",
                            color: DesignTokens.Colors.neonBlue
                        ) {
                            showingCommunity = true
                        }
                        
                        MoreMenuItem(
                            icon: "certificate.fill",
                            title: "Achievements",
                            subtitle: "View your accomplishments",
                            color: DesignTokens.Colors.neonYellow
                        ) {
                            showingAchievements = true
                        }
                        
                        MoreMenuItem(
                            icon: "person.crop.circle.fill",
                            title: "Profile",
                            subtitle: "Your account and stats",
                            color: DesignTokens.Colors.neonPink
                        ) {
                            showingProfile = true
                        }
                        
                        MoreMenuItem(
                            icon: "gearshape.fill",
                            title: "Settings",
                            subtitle: "App preferences",
                            color: DesignTokens.Colors.neonGreen
                        ) {
                            showingSettings = true
                        }
                        
                        MoreMenuItem(
                            icon: "network",
                            title: "Backend Status",
                            subtitle: "Test connection",
                            color: DesignTokens.Colors.neonOrange
                        ) {
                            showingConnectivityTest = true
                        }
                        
                        MoreMenuItem(
                            icon: "server.rack",
                            title: "System Status",
                            subtitle: "View system health",
                            color: DesignTokens.Colors.neonBlue
                        ) {
                            showingConnectivityTest = true
                        }
                        
                        // ✅ ENVIRONMENT TOGGLE (Development builds only)
                        #if DEBUG
                        MoreMenuItem(
                            icon: "globe",
                            title: "Environment: \(APIConfig.currentEnvironment.displayName)",
                            subtitle: APIConfig.baseURL,
                            color: APIConfig.currentEnvironment == .prod ? .green : .orange
                        ) {
                            showEnvironmentPicker()
                        }
                        
                        MoreMenuItem(
                            icon: "wrench.and.screwdriver.fill",
                            title: "Unity Integration Tests",
                            subtitle: "Test Unity classroom integration",
                            color: DesignTokens.Colors.primary
                        ) {
                            showingUnityTests = true
                        }
                        #endif
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
        }
        .sheet(isPresented: $showingProfile) {
            MoreTabProfileView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingAIChat) {
            AIFullChatViewWithCompletion { topic in
                showingAIChat = false
            }
        }
        .sheet(isPresented: $showingLearningAnalytics) {
            LearningAnalyticsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingStudyGroups) {
            StudyGroupsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingCommunity) {
            CommunityView()
                .environmentObject(appState)
        }
                        .sheet(isPresented: $showingAchievements) {
            AchievementsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingConnectivityTest) {
            Text("Backend connectivity test coming soon!")
                .padding()
        }
        .sheet(isPresented: $showingUnityTests) {
            UnityIntegrationTestView()
        }
        // ✅ Environment picker action sheet
        #if DEBUG
        .actionSheet(isPresented: $showingEnvironmentPicker) {
            ActionSheet(
                title: Text("Switch Environment"),
                message: Text("Choose the backend environment for this session"),
                buttons: environmentPickerButtons()
            )
        }
        #endif
    }
    
    // ✅ ENVIRONMENT PICKER METHODS
    #if DEBUG
    private func showEnvironmentPicker() {
        showingEnvironmentPicker = true
    }
    
    private func environmentPickerButtons() -> [ActionSheet.Button] {
        var buttons: [ActionSheet.Button] = []
        
        // Production-only mode - show current environment
        let title = "✓ \(APIConfig.currentBackend) (Fixed)"
        
        buttons.append(.default(Text(title)) {
            // No-op - production only
        })
        
        // Add info button explaining production-only mode
        buttons.append(.default(Text("ℹ️ Production Backend Only")) {
            // No-op - just info
        })
        
        buttons.append(.cancel())
        return buttons
    }
    
    private func switchToEnvironment(_ environment: String) {
        // Production-only mode - no switching allowed
        print("🚫 Environment switching disabled - production only")
    }
    #endif
}

// MARK: - Profile View (Local to MoreTabView)
struct MoreTabProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var selectedTab = 0
    
    private let tabs = ["Posts", "Courses", "Achievements"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile Header
                    profileHeader
                    
                    // Stats Section
                    statsSection
                    
                    // Action Buttons
                    actionButtons
                    
                    // Tab Selection
                    tabSelection
                    
                    // Tab Content
                    tabContent
                }
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(appState)
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Profile Image with AI Glow
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 0)
                
                Text(appState.currentUser?.fullName.prefix(1) ?? "U")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 110, height: 110)
                    .clipShape(Circle())
                
                // Level Badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.neonBlue)
                                .frame(width: 30, height: 30)
                                .shadow(color: DesignTokens.Colors.neonBlue.opacity(0.5), radius: 8, x: 0, y: 0)
                            
                            Text("\(appState.currentUser?.level ?? 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: -5, y: -5)
                    }
                }
                .frame(width: 120, height: 120)
            }
            
            // User Info
            VStack(spacing: DesignTokens.Spacing.sm) {
                HStack {
                    Text(appState.currentUser?.fullName ?? "User Name")
                        .font(DesignTokens.Typography.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    if appState.currentUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                }
                
                Text("@\(appState.currentUser?.username ?? "username")")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                if let bio = appState.currentUser?.bio {
                    Text(bio)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                // Join Date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .font(.caption)
                    
                    Text("Joined \(appState.currentUser?.joinedAt ?? Date(), style: .date)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
    
    private var statsSection: some View {
        HStack {
            Spacer()
            
            MoreTabStatCard(
                title: "Posts",
                value: "\(appState.currentUser?.posts ?? 0)",
                icon: "doc.text",
                color: DesignTokens.Colors.neonBlue
            )
            
            Spacer()
            
            MoreTabStatCard(
                title: "Followers",
                value: formatNumber(appState.currentUser?.followers ?? 0),
                icon: "person.3",
                color: DesignTokens.Colors.neonPurple
            )
            
            Spacer()
            
            MoreTabStatCard(
                title: "Following",
                value: formatNumber(appState.currentUser?.following ?? 0),
                icon: "person.2",
                color: DesignTokens.Colors.neonPink
            )
            
            Spacer()
            
            MoreTabStatCard(
                title: "XP",
                value: "\(appState.currentUser?.experience ?? 0)",
                icon: "star",
                color: DesignTokens.Colors.neonYellow
            )
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var actionButtons: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Button("Edit Profile") {
                showingEditProfile = true
            }
            .font(DesignTokens.Typography.bodyMedium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.primaryGradient)
            .cornerRadius(DesignTokens.Radius.button)
            
            Button("Share Profile") {
                // Share profile
            }
            .font(DesignTokens.Typography.bodyMedium)
            .foregroundColor(DesignTokens.Colors.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .strokeBorder(DesignTokens.Colors.primary, lineWidth: 1)
                    .background(DesignTokens.Colors.glassBg)
            )
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.lg)
    }
    
    private var tabSelection: some View {
        HStack {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(tab) {
                    selectedTab = index
                }
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(selectedTab == index ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    Rectangle()
                        .fill(selectedTab == index ? DesignTokens.Colors.primary : Color.clear)
                        .frame(height: 2)
                        .offset(y: DesignTokens.Spacing.md)
                )
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.lg)
    }
    
    private var tabContent: some View {
        Group {
            switch selectedTab {
            case 0:
                postsTab
            case 1:
                coursesTab
            case 2:
                achievementsTab
            default:
                postsTab
            }
        }
        .padding(.top, DesignTokens.Spacing.lg)
    }
    
    private var postsTab: some View {
        LazyVStack(spacing: DesignTokens.Spacing.md) {
            ForEach(0..<5) { index in
                MoreTabUserPostCard(index: index)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var coursesTab: some View {
        LazyVStack(spacing: DesignTokens.Spacing.md) {
            ForEach(0..<3) { index in
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Course \(index + 1)")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Completed")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.success)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.glassBg)
                )
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var achievementsTab: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignTokens.Spacing.md) {
            ForEach(0..<6) { index in
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.Colors.primaryGradient)
                            .frame(width: 60, height: 60)
                            .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 0)
                        
                        Image(systemName: "star.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text("Achievement \(index + 1)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                }
                .padding(DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.glassBg)
                )
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000000 {
            return "\(number / 1000000)M"
        } else if number >= 1000 {
            return "\(number / 1000)K"
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Supporting Views
struct MoreTabStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .fontWeight(.bold)
            
            Text(title)
                .font(DesignTokens.Typography.caption2)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
}

struct MoreTabUserPostCard: View {
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("2\(index) days ago")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
                
                Button {
                    // More options
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            Text("Just completed another AI course! The future of learning is here 🚀")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            HStack {
                Button {
                    // Like
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "heart")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("24")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Button {
                    // Comment
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "message")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("8")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
    }
}

struct MoreMenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Text(subtitle)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassBg)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Learning Analytics View
struct LearningAnalyticsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingDetailedStats = false
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        case allTime = "All Time"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Time Frame Selector
                    timeFrameSelector
                    
                    // Key Metrics
                    keyMetricsSection
                    
                    // Learning Progress
                    learningProgressSection
                    
                    // Course Completion Chart
                    courseCompletionSection
                    
                    // Study Streak
                    studyStreakSection
                    
                    // Learning Goals
                    learningGoalsSection
                    
                    // Detailed Statistics Button
                    detailedStatsButton
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Learning Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingDetailedStats) {
            DetailedAnalyticsView()
        }
    }
    
    private var timeFrameSelector: some View {
        HStack {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                Button(timeFrame.rawValue) {
                    withAnimation(DesignTokens.Animations.quick) {
                        selectedTimeFrame = timeFrame
                    }
                }
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(selectedTimeFrame == timeFrame ? .white : DesignTokens.Colors.textSecondary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                        .fill(selectedTimeFrame == timeFrame ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
                )
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Key Metrics")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: DesignTokens.Spacing.md) {
                MetricCard(
                    title: "Study Time",
                    value: "24h 30m",
                    subtitle: "This week",
                    icon: "clock.fill",
                    color: DesignTokens.Colors.neonBlue
                )
                
                MetricCard(
                    title: "Courses Completed",
                    value: "8",
                    subtitle: "+2 this week",
                    icon: "graduationcap.fill",
                    color: DesignTokens.Colors.neonPurple
                )
                
                MetricCard(
                    title: "Streak",
                    value: "15 days",
                    subtitle: "Personal best!",
                    icon: "flame.fill",
                    color: DesignTokens.Colors.neonOrange
                )
                
                MetricCard(
                    title: "XP Earned",
                    value: "2,450",
                    subtitle: "+150 today",
                    icon: "star.fill",
                    color: DesignTokens.Colors.neonYellow
                )
            }
        }
    }
    
    private var learningProgressSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Learning Progress")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                ProgressBarWithLabel(title: "Swift Programming", progress: 0.75, color: DesignTokens.Colors.neonBlue)
                ProgressBarWithLabel(title: "UI/UX Design", progress: 0.45, color: DesignTokens.Colors.neonPurple)
                ProgressBarWithLabel(title: "Data Science", progress: 0.30, color: DesignTokens.Colors.neonGreen)
                ProgressBarWithLabel(title: "Machine Learning", progress: 0.15, color: DesignTokens.Colors.neonPink)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private var courseCompletionSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Course Completion Rate")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("85%")
                        .font(DesignTokens.Typography.hero)
                        .foregroundColor(DesignTokens.Colors.primary)
                    
                    Text("Completion Rate")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                MoreTabCircularProgressView(progress: 0.85, color: DesignTokens.Colors.primary)
                    .frame(width: 80, height: 80)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private var studyStreakSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Study Streak")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            HStack {
                Image(systemName: "flame.fill")
                    .font(.title)
                    .foregroundColor(DesignTokens.Colors.neonOrange)
                
                VStack(alignment: .leading) {
                    Text("15 Days")
                        .font(DesignTokens.Typography.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Keep it going! 5 more days for a new record.")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private var learningGoalsSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Learning Goals")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                GoalProgressView(
                    title: "Complete 10 courses this month",
                    current: 8,
                    target: 10,
                    color: DesignTokens.Colors.neonBlue
                )
                
                GoalProgressView(
                    title: "Study 30 hours this week",
                    current: 24,
                    target: 30,
                    color: DesignTokens.Colors.neonPurple
                )
                
                GoalProgressView(
                    title: "Maintain 30-day streak",
                    current: 15,
                    target: 30,
                    color: DesignTokens.Colors.neonOrange
                )
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private var detailedStatsButton: some View {
        Button("View Detailed Statistics") {
            showingDetailedStats = true
        }
        .font(DesignTokens.Typography.buttonLabel)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.primaryGradient)
        .cornerRadius(DesignTokens.Radius.button)
    }
}

// MARK: - Study Groups View
struct StudyGroupsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @State private var showingCreateGroup = false
    @State private var searchText = ""
    
    private let tabs = ["My Groups", "Discover", "Requests"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selection
                tabSelector
                
                // Content based on selected tab
                TabView(selection: $selectedTab) {
                    myGroupsTab.tag(0)
                    discoverGroupsTab.tag(1)
                    requestsTab.tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Study Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { showingCreateGroup = true }
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showingCreateGroup) {
            CreateStudyGroupView()
        }
    }
    
    private var tabSelector: some View {
        HStack {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                Button(tab) {
                    withAnimation(DesignTokens.Animations.quick) {
                        selectedTab = index
                    }
                }
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(selectedTab == index ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    Rectangle()
                        .fill(selectedTab == index ? DesignTokens.Colors.primary : Color.clear)
                        .frame(height: 2)
                        .offset(y: DesignTokens.Spacing.md)
                )
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var myGroupsTab: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                if true { // userStudyGroups.isEmpty - TODO: implement proper state management
                    // Empty state
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "person.3")
                            .font(.system(size: 48))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("No Study Groups Yet")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("Join some study groups to connect with fellow learners")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(DesignTokens.Spacing.xl)
                } else {
                    // TODO: implement userStudyGroups state
                    Text("Study groups will appear here")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .onAppear {
            // TODO: implement loadUserStudyGroups()
        }
    }
    
    private var discoverGroupsTab: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    TextField("Search study groups...", text: $searchText)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.glassBg)
                )
                .padding(.horizontal, DesignTokens.Spacing.lg)
                
                // Available Groups
                if false { // isLoadingGroups - TODO: implement proper state
                    ProgressView("Loading study groups...")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(DesignTokens.Spacing.xl)
                } else if true { // availableStudyGroups.isEmpty - TODO: implement proper state
                    // Empty state
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 48))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("No Study Groups Found")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("Try adjusting your search or check back later")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(DesignTokens.Spacing.xl)
                } else {
                    // TODO: implement availableStudyGroups state
                    Text("Available study groups will appear here")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(DesignTokens.Spacing.xl)
                }
            }
        }
        .onAppear {
            // TODO: implement loadAvailableStudyGroups()
        }
    }
    
    private var requestsTab: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                if true { // groupRequests.isEmpty - TODO: implement proper state
                    // Empty state
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 48))
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("No Requests")
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text("Group join requests will appear here")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(DesignTokens.Spacing.xl)
                } else {
                    // TODO: implement groupRequests state
                    Text("Group requests will appear here")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .onAppear {
            // TODO: implement loadGroupRequests()
        }
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: AchievementCategory = .all
    
    enum AchievementCategory: String, CaseIterable {
        case all = "All"
        case learning = "Learning"
        case social = "Social"
        case streak = "Streak"
        case milestone = "Milestone"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Category Filter
                categorySelector
                
                // Achievements Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: DesignTokens.Spacing.md) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCardView(achievement: achievement)
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                }
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    Button(category.rawValue) {
                        withAnimation(DesignTokens.Animations.quick) {
                            selectedCategory = category
                        }
                    }
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(selectedCategory == category ? .white : DesignTokens.Colors.textSecondary)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .fill(selectedCategory == category ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
                    )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
    }
    
    private var filteredAchievements: [DetailedAchievement] {
        // TODO: implement userAchievements state
        return []
    }
}

// MARK: - API Integration Methods
extension MoreTabView {
    
    /// Load user's study groups from API
    func loadUserStudyGroups() async {
        // TODO: Implement when study groups API is available
        print("📚 Loading user study groups from API...")
        // For now, keep empty to encourage real API integration
    }
    
    /// Load available study groups from API
    func loadAvailableStudyGroups() async {
        isLoadingGroups = true
        defer { isLoadingGroups = false }
        
        // TODO: Implement when study groups API is available
        print("🔍 Loading available study groups from API...")
        // For now, keep empty to encourage real API integration
    }
    
    /// Load group join requests from API
    func loadGroupRequests() async {
        // TODO: Implement when group requests API is available
        print("📮 Loading group requests from API...")
        // For now, keep empty to encourage real API integration
    }
    
    /// Load user achievements from API
    func loadUserAchievements() async {
        isLoadingAchievements = true
        defer { isLoadingAchievements = false }
        
        // TODO: Implement when achievements API is available
        print("🏆 Loading user achievements from API...")
        // For now, keep empty to encourage real API integration
    }
}

// MARK: - Supporting Views and Components

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(value)
                .font(DesignTokens.Typography.title2)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .fontWeight(.bold)
            
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text(subtitle)
                .font(DesignTokens.Typography.caption2)
                .foregroundColor(color)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
}

struct ProgressBarWithLabel: View {
    let title: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(color)
                .scaleEffect(y: 2)
        }
    }
}

struct MoreTabCircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
        }
    }
}

struct GoalProgressView: View {
    let title: String
    let current: Int
    let target: Int
    let color: Color
    
    private var progress: Double {
        Double(current) / Double(target)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Text(title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("\(current)/\(target)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(color)
                .scaleEffect(y: 2)
        }
    }
}

// MARK: - Missing View Stubs

struct DetailedAnalyticsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Detailed Analytics")
                    .font(.title)
                Text("Advanced analytics coming soon!")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Analytics")
        }
    }
}

struct CreateStudyGroupView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Create Study Group")
                    .font(.title)
                Text("Group creation coming soon!")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Create Group")
        }
    }
}

struct StudyGroupCard: View {
    let group: StudyGroupAPI
    let showJoinButton: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(group.name)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(group.description.isEmpty ? "No description" : group.description)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            if showJoinButton {
                Button("Join Group") {
                    // Join group action
                }
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.primary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
}

struct GroupRequestCard: View {
    let request: GroupRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(request.groupName)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Request from \(request.requesterName)")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
}

struct AchievementCardView: View {
    let achievement: DetailedAchievement
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: achievement.icon)
                .font(.title)
                .foregroundColor(achievement.isUnlocked ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
            
            Text(achievement.title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
}

struct MoreTabCommunityView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Community")
                    .font(.title)
                Text("Community features coming soon!")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Community")
        }
    }
}

// MARK: - Data Models

struct GroupRequest: Identifiable {
    let id = UUID()
    let groupName: String
    let requesterName: String
    let requesterAvatar: String
    let message: String
    let timestamp: Date
}

struct DetailedAchievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let category: AchievementsView.AchievementCategory
    let isUnlocked: Bool
    let progress: Double
    let maxProgress: Int
    let xpReward: Int
    let unlockedDate: Date?
}
