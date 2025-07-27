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
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    
                    Spacer(minLength: 20)
                }
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
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
    }
}

// MARK: - Profile View
struct ProfileView: View {
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
                    
                    Text("Joined \(appState.currentUser?.joinDate ?? Date(), style: .date)")
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
            
            StatCard(
                title: "Posts",
                value: "\(appState.currentUser?.posts ?? 0)",
                icon: "doc.text",
                color: DesignTokens.Colors.neonBlue
            )
            
            Spacer()
            
            StatCard(
                title: "Followers",
                value: formatNumber(appState.currentUser?.followers ?? 0),
                icon: "person.3",
                color: DesignTokens.Colors.neonPurple
            )
            
            Spacer()
            
            StatCard(
                title: "Following",
                value: formatNumber(appState.currentUser?.following ?? 0),
                icon: "person.2",
                color: DesignTokens.Colors.neonPink
            )
            
            Spacer()
            
            StatCard(
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
                UserPostCard(index: index)
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
struct StatCard: View {
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

struct UserPostCard: View {
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
                
                CircularProgressView(progress: 0.85, color: DesignTokens.Colors.primary)
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
                ForEach(sampleStudyGroups.filter { $0.isMember }) { group in
                    StudyGroupCard(group: group, showJoinButton: false)
                }
            }
            .padding(DesignTokens.Spacing.lg)
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
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(sampleStudyGroups.filter { !$0.isMember }) { group in
                        StudyGroupCard(group: group, showJoinButton: true)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
    }
    
    private var requestsTab: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(sampleGroupRequests) { request in
                    GroupRequestCard(request: request)
                }
            }
            .padding(DesignTokens.Spacing.lg)
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
        if selectedCategory == .all {
            return sampleDetailedAchievements
        }
        return sampleDetailedAchievements.filter { $0.category == selectedCategory }
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

struct CircularProgressView: View {
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

// MARK: - Data Models

struct StudyGroup: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let subject: String
    let memberCount: Int
    let isPrivate: Bool
    let isMember: Bool
    let lastActivity: Date
    let difficulty: String
    let tags: [String]
}

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

// MARK: - Sample Data

let sampleStudyGroups = [
    StudyGroup(name: "Swift Mastery", description: "Advanced Swift programming techniques", subject: "Programming", memberCount: 24, isPrivate: false, isMember: true, lastActivity: Date(), difficulty: "Advanced", tags: ["Swift", "iOS", "Mobile"]),
    StudyGroup(name: "UI/UX Bootcamp", description: "Design thinking and user experience", subject: "Design", memberCount: 18, isPrivate: false, isMember: true, lastActivity: Date().addingTimeInterval(-3600), difficulty: "Intermediate", tags: ["Design", "UX", "Figma"]),
    StudyGroup(name: "Data Science Club", description: "Machine learning and data analysis", subject: "Data Science", memberCount: 31, isPrivate: false, isMember: false, lastActivity: Date().addingTimeInterval(-7200), difficulty: "Advanced", tags: ["Python", "ML", "Data"]),
    StudyGroup(name: "Web Dev Beginners", description: "Learn web development from scratch", subject: "Web Development", memberCount: 45, isPrivate: false, isMember: false, lastActivity: Date().addingTimeInterval(-1800), difficulty: "Beginner", tags: ["HTML", "CSS", "JavaScript"])
]

let sampleGroupRequests = [
    GroupRequest(groupName: "AI Study Group", requesterName: "Alex Johnson", requesterAvatar: "👨‍💻", message: "I'd love to join your AI study group. I have experience with TensorFlow.", timestamp: Date().addingTimeInterval(-3600)),
    GroupRequest(groupName: "Swift Mastery", requesterName: "Sarah Chen", requesterAvatar: "👩‍💼", message: "Excited to learn advanced Swift concepts with the group!", timestamp: Date().addingTimeInterval(-7200))
]

let sampleDetailedAchievements = [
    DetailedAchievement(title: "First Steps", description: "Complete your first course", icon: "foot.2", category: .learning, isUnlocked: true, progress: 1.0, maxProgress: 1, xpReward: 100, unlockedDate: Date().addingTimeInterval(-86400 * 30)),
    DetailedAchievement(title: "Speed Learner", description: "Complete 5 courses in one week", icon: "bolt.fill", category: .learning, isUnlocked: true, progress: 1.0, maxProgress: 5, xpReward: 500, unlockedDate: Date().addingTimeInterval(-86400 * 7)),
    DetailedAchievement(title: "Streak Master", description: "Maintain a 30-day learning streak", icon: "flame.fill", category: .streak, isUnlocked: false, progress: 0.5, maxProgress: 30, xpReward: 1000, unlockedDate: nil),
    DetailedAchievement(title: "Social Butterfly", description: "Join 10 study groups", icon: "person.3.fill", category: .social, isUnlocked: false, progress: 0.3, maxProgress: 10, xpReward: 750, unlockedDate: nil),
    DetailedAchievement(title: "Milestone 100", description: "Complete 100 courses", icon: "mountain.2.fill", category: .milestone, isUnlocked: false, progress: 0.08, maxProgress: 100, xpReward: 5000, unlockedDate: nil)
]

struct StudyGroupCard: View {
    let group: StudyGroup
    let showJoinButton: Bool
    @State private var hasJoined = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(group.name)
                        .font(DesignTokens.Typography.title3)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(group.subject)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(group.memberCount) members")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Text(group.difficulty)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(difficultyColor)
                        .padding(.horizontal, DesignTokens.Spacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(difficultyColor.opacity(0.2))
                        )
                }
            }
            
            // Description
            Text(group.description)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .lineLimit(2)
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(group.tags, id: \.self) { tag in
                        Text(tag)
                            .font(DesignTokens.Typography.caption2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.glassBg)
                            )
                    }
                }
            }
            
            // Footer
            HStack {
                Text("Active \(timeAgoString(from: group.lastActivity))")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
                
                if showJoinButton && !hasJoined {
                    Button("Join Group") {
                        withAnimation(DesignTokens.Animations.quick) {
                            hasJoined = true
                        }
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                    .background(DesignTokens.Colors.primary)
                    .cornerRadius(DesignTokens.Radius.button)
                } else if hasJoined {
                    Text("Joined!")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.success)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private var difficultyColor: Color {
        switch group.difficulty {
        case "Beginner": return DesignTokens.Colors.success
        case "Intermediate": return DesignTokens.Colors.warning
        case "Advanced": return DesignTokens.Colors.error
        default: return DesignTokens.Colors.textSecondary
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

struct GroupRequestCard: View {
    let request: GroupRequest
    @State private var responded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text(request.requesterAvatar)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(request.requesterName)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("wants to join \(request.groupName)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Text(timeAgoString(from: request.timestamp))
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Text(request.message)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            if !responded {
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button("Accept") {
                        withAnimation(DesignTokens.Animations.quick) {
                            responded = true
                        }
                    }
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.success)
                    .cornerRadius(DesignTokens.Radius.button)
                    
                    Button("Decline") {
                        withAnimation(DesignTokens.Animations.quick) {
                            responded = true
                        }
                    }
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(DesignTokens.Colors.error)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.sm)
                    .background(DesignTokens.Colors.glassBg)
                    .cornerRadius(DesignTokens.Radius.button)
                }
            } else {
                Text("Response sent")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.success)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return "\(Int(interval / 86400))d ago"
        }
    }
}

struct AchievementCardView: View {
    let achievement: DetailedAchievement
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Icon and Title
            VStack(spacing: DesignTokens.Spacing.sm) {
                ZStack {
                    if achievement.isUnlocked {
                        Circle()
                            .fill(DesignTokens.Colors.primaryGradient)
                            .frame(width: 60, height: 60)
                    } else {
                        Circle()
                            .fill(DesignTokens.Colors.glassBg)
                            .frame(width: 60, height: 60)
                    }
                    
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(achievement.isUnlocked ? .white : DesignTokens.Colors.textSecondary)
                }
                
                Text(achievement.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            // Progress or Completion
            if achievement.isUnlocked {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.success)
                    
                    Text("Unlocked")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.success)
                }
            } else {
                VStack(spacing: DesignTokens.Spacing.xs) {
                    ProgressView(value: achievement.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .tint(DesignTokens.Colors.primary)
                        .scaleEffect(y: 1.5)
                    
                    Text("\(Int(achievement.progress * Double(achievement.maxProgress)))/\(achievement.maxProgress)")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            // XP Reward
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(DesignTokens.Colors.neonYellow)
                    .font(.caption)
                
                Text("\(achievement.xpReward) XP")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
                .opacity(achievement.isUnlocked ? 1.0 : 0.6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .strokeBorder(
                    achievement.isUnlocked ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                    lineWidth: achievement.isUnlocked ? 2 : 1
                )
        )
    }
}

// Placeholder views for missing functionality
struct DetailedAnalyticsView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Detailed analytics coming soon!")
                    .font(DesignTokens.Typography.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding()
            }
            .navigationTitle("Detailed Analytics")
        }
    }
}

struct CreateStudyGroupView: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var description = ""
    @State private var isPrivate = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Group Details") {
                    TextField("Group Name", text: $groupName)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Privacy") {
                    Toggle("Private Group", isOn: $isPrivate)
                }
            }
            .navigationTitle("Create Study Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") { dismiss() }
                        .disabled(groupName.isEmpty)
                }
            }
        }
    }
}

struct CommunityView: View {
    var body: some View {
        Text("Community View")
    }
}
