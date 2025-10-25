import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var container: AppContainer
    @Environment(\.dismiss) var dismiss
    @State private var showingSettings = false
    @State private var showingEditProfile = false
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
                .environmentObject(container)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(container)
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
                
                if let user = container.currentUser, let avatarUrl = user.avatarUrl {
                    OptimizedAsyncImage(url: URL(string: avatarUrl))
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(DesignTokens.Colors.primary, lineWidth: 3))
                        .shadow(radius: DesignTokens.Radius.sm)
                } else {
                    Text(container.currentUser?.displayName.prefix(1) ?? "U")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                }
                
                // Level Badge
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.accent)
                                .frame(width: 30, height: 30)
                                .shadow(color: DesignTokens.Colors.accent.opacity(0.5), radius: 8, x: 0, y: 0)
                            
                            Text("\(container.currentUser?.stats.level ?? 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .frame(width: 120, height: 120)
            }
            
            // User Info
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(container.currentUser?.displayName ?? "User")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                if let bio = container.currentUser?.bio, !bio.isEmpty {
                    Text(bio)
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
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
                value: "12",
                icon: "doc.text",
                color: DesignTokens.Colors.accent
            )
            
            Spacer()
            
            StatCard(
                title: "Courses",
                value: "\(container.currentUser?.stats.completedCourses ?? 0)",
                icon: "graduationcap",
                color: DesignTokens.Colors.primary
            )
            
            Spacer()
            
            StatCard(
                title: "Points",
                value: "\(container.currentUser?.stats.totalPoints ?? 0)",
                icon: "star",
                color: DesignTokens.Colors.success
            )
            
            Spacer()
            
            StatCard(
                title: "Streak",
                value: "\(container.currentUser?.stats.streak ?? 0)",
                icon: "flame",
                color: DesignTokens.Colors.warning
            )
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var actionButtons: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            AccessibleButton(
                title: "Edit Profile",
                style: .primary,
                size: .medium
            ) {
                showingEditProfile = true
            }
            
            AccessibleButton(
                title: "Share Profile",
                style: .secondary,
                size: .medium
            ) {
                // Share profile action
                shareProfile()
            }
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
            ForEach(0..<3) { index in
                UserPostCard(index: index)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var coursesTab: some View {
        LazyVStack(spacing: DesignTokens.Spacing.md) {
            // Mock completed courses
            ForEach(mockCompletedCourses(), id: \.id) { course in
                CompletedCourseCard(course: course)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var achievementsTab: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible()), count: 2),
            spacing: DesignTokens.Spacing.md
        ) {
            ForEach(mockAchievements(), id: \.id) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private func shareProfile() {
        // Implementation for sharing profile
        print("Sharing profile...")
    }
    
    private func mockCompletedCourses() -> [Course] {
        return [
            Course(
                id: "1",
                title: "SwiftUI Masterclass",
                description: "Complete iOS development course",
                instructor: "John Appleseed",
                thumbnailUrl: "",
                category: .programming,
                difficulty: .intermediate,
                duration: 8.5,
                rating: 4.8,
                enrollmentCount: 1250,
                isEnrolled: true,
                progress: 1.0,
                lessons: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }
    
    private func mockAchievements() -> [Achievement] {
        return [
            Achievement(
                id: "1",
                title: "First Course",
                description: "Completed your first course",
                iconName: "graduationcap.fill",
                isUnlocked: true,
                unlockedAt: Date()
            ),
            Achievement(
                id: "2",
                title: "Week Streak",
                description: "7 days learning streak",
                iconName: "flame.fill",
                isUnlocked: true,
                unlockedAt: Date().addingTimeInterval(-86400 * 3)
            ),
            Achievement(
                id: "3",
                title: "AI Explorer",
                description: "Completed 5 AI courses",
                iconName: "brain.head.profile",
                isUnlocked: false,
                unlockedAt: nil
            ),
            Achievement(
                id: "4",
                title: "Social Learner",
                description: "Made 10 posts",
                iconName: "person.3.fill",
                isUnlocked: false,
                unlockedAt: nil
            )
        ]
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(DesignTokens.Typography.titleMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(title)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct UserPostCard: View {
    let index: Int
    
    private let mockPosts = [
        "Just completed my first AI course! The future of learning is incredible 🚀",
        "Working on a new SwiftUI project. Loving the declarative syntax!",
        "Excited to share my latest machine learning model results 📊"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Circle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("You")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("\(index + 1) day\(index == 0 ? "" : "s") ago")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    // More options
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            Text(mockPosts[index % mockPosts.count])
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            HStack {
                Button {
                    // Like
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "heart")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("\((index + 1) * 8)")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Button {
                    // Comment
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "message")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("\((index + 1) * 3)")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.md)
        .cardStyle()
    }
}

struct CompletedCourseCard: View {
    let course: Course
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
        OptimizedAsyncImage(url: URL(string: course.thumbnailUrl))
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(course.title)
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(course.instructor)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.success)
                        .font(.caption)
                    
                    Text("Completed")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.success)
                    
                    Spacer()
                    
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .foregroundColor(DesignTokens.Colors.accent)
                        Text("\(course.rating, specifier: "%.1f")")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .cardStyle()
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: achievement.iconName)
                .font(.system(size: 32))
                .foregroundColor(achievement.isUnlocked ? DesignTokens.Colors.primary : DesignTokens.Colors.textTertiary)
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(achievement.title)
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .cardStyle()
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .strokeBorder(
                    achievement.isUnlocked ? DesignTokens.Colors.primary.opacity(0.3) : DesignTokens.Colors.glassBorder,
                    lineWidth: 1
                )
        )
    }
}

// Temporary views for sheets
struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Edit Profile")
                    .font(.title)
                
                Spacer()
                
                Text("Profile editing coming soon!")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var container: AppContainer
    
    var body: some View {
        NavigationView {
            List {
                Section("Account") {
                    Button("Sign Out") {
                        Task {
                            await container.signOut()
                        }
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Achievement model for mock data
struct Achievement {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let isUnlocked: Bool
    let unlockedAt: Date?
}

#Preview {
    ProfileView()
        .environmentObject(AppContainer.development())
}
