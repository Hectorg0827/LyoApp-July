import SwiftUI

// MARK: - Basic Profile Manager
@MainActor
class ProfileManager: ObservableObject {
    @Published var user: ProfileUser = ProfileUser(
        username: "user123",
        name: "John Doe",
        bio: "Learning enthusiast",
        avatarURL: "",
        isVerified: false,
        followerCount: 100,
        followingCount: 50,
        postCount: 25
    )
    @Published var isLoading = false
    @Published var userStats: UserStats? = UserStats(postsCount: 25, followersCount: 100, followingCount: 50)
    @Published var userPosts: [ProfilePost] = []
    
    func updateProfile() {
        // Simulate profile update
    }
    
    func preload() async {
        isLoading = true
        // Simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        userPosts = generateSamplePosts()
        isLoading = false
    }
    
    func refresh() async {
        await preload()
    }
    
    func cleanup() {
        // Cleanup resources
    }
    
    func loadMorePosts() async {
        // Load more posts
        let morePosts = generateSamplePosts()
        userPosts.append(contentsOf: morePosts)
    }
    
    private func generateSamplePosts() -> [ProfilePost] {
        return (1...9).map { index in
            ProfilePost(
                id: "post_\(index)",
                username: user.username,
                userAvatar: user.avatarURL,
                content: "Sample post content \(index)",
                timestamp: Date(),
                likes: Int.random(in: 10...100),
                comments: Int.random(in: 0...20),
                imageURL: "sample_image_\(index)"
            )
        }
    }
}

struct UserStats {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
}

struct ProfilePost: Identifiable, Equatable {
    let id: String
    let username: String
    let userAvatar: String
    let content: String
    let timestamp: Date
    let likes: Int
    let comments: Int
    let imageURL: String
}

struct ProfileUser {
    let username: String
    let name: String
    let bio: String
    let avatarURL: String
    let isVerified: Bool
    let followerCount: Int
    let followingCount: Int
    let postCount: Int
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var profileManager = ProfileManager()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    // Provide a dummy binding for showingStoryDrawer (not used in ProfileView)
    @State private var showingStoryDrawer = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HeaderView(showingStoryDrawer: $showingStoryDrawer)

                if profileManager.isLoading {
                    DesignSystem.LoadingStateView(message: "Loading profile...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: DesignTokens.Spacing.lg) {
                            // Profile Header
                            profileHeader

                            // Stats Section
                            statsSection

                            // Action Buttons
                            actionButtons

                            // Content Tabs
                            contentTabs

                            // Content based on selected tab
                            contentSection
                        }
                        .padding(DesignTokens.Spacing.md)
                    }
                    .refreshable {
                        await profileManager.refresh()
                    }
                }
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Opens settings menu")
                    .accessibilityIdentifier("profile_settings_button")
                }
            }
            .task {
                await profileManager.preload()
            }
            .onDisappear {
                profileManager.cleanup()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Profile Image
            ZStack {
                DesignSystem.Avatar(
                    imageURL: appState.currentUser?.profileImageURL,
                    name: appState.currentUser?.fullName ?? "User",
                    size: 100
                )
                
                // Edit Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingEditProfile = true
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(DesignTokens.Colors.primary))
                        }
                        .offset(x: -8, y: -8)
                    }
                }
                .frame(width: 100, height: 100)
            }
            
            // User Info
            VStack(spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text(appState.currentUser?.fullName ?? "User Name")
                        .font(DesignTokens.Typography.title2)
                    
                    if appState.currentUser?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                }
                
                Text("@\(appState.currentUser?.username ?? "username")")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
                
                if let bio = appState.currentUser?.bio {
                    Text(bio)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.label)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
                
                // Level and XP
                HStack {
                    DesignSystem.Badge(text: "Level \(appState.currentUser?.level ?? 1)", style: .primary)
                    DesignSystem.Badge(text: "\(appState.currentUser?.experience ?? 0) XP", style: .secondary)
                }
            }
        }
    }
    
    private var statsSection: some View {
        HStack {
            StatView(title: "Posts", value: "\(profileManager.userStats?.postsCount ?? 0)")
            
            Divider()
                .frame(height: 40)
            
            StatView(title: "Followers", value: "\(profileManager.userStats?.followersCount ?? 0)")
            
            Divider()
                .frame(height: 40)
            
            StatView(title: "Following", value: "\(profileManager.userStats?.followingCount ?? 0)")
        }
        .cardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("User statistics")
        .accessibilityValue("Posts: \(profileManager.userStats?.postsCount ?? 0), Followers: \(profileManager.userStats?.followersCount ?? 0), Following: \(profileManager.userStats?.followingCount ?? 0)")
    }
    
    private var actionButtons: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Button("Edit Profile") {
                showingEditProfile = true
            }
            .secondaryButton()
            
            Button("Share Profile") {
                // Handle share profile
            }
            .secondaryButton()
        }
    }
    
    private var contentTabs: some View {
        HStack {
            ForEach(0..<4) { index in
                Button {
                    selectedTab = index
                } label: {
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: tabIcon(for: index))
                            .font(.title3)
                        
                        Text(tabTitle(for: index))
                            .font(DesignTokens.Typography.caption)
                    }
                    .foregroundColor(selectedTab == index ? DesignTokens.Colors.primary : DesignTokens.Colors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(DesignTokens.Colors.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
    }
    
    private var contentSection: some View {
        Group {
            switch selectedTab {
            case 0:
                postsSection
            case 1:
                achievementsSection
            case 2:
                coursesSection
            case 3:
                savedSection
            default:
                EmptyView()
            }
        }
    }
    
    private var postsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.xs) {
            ForEach(profileManager.userPosts) { post in
                PostThumbnail(post: post)
                    .onAppear {
                        // Load more when near the end
                        if post == profileManager.userPosts.last {
                            Task {
                                await profileManager.loadMorePosts()
                            }
                        }
                    }
            }
            
            if profileManager.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .gridCellColumns(3)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("User posts grid")
    }
    
    private var achievementsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignTokens.Spacing.md) {
            ForEach(sampleBadges) { badge in
                AchievementCard(badge: badge)
            }
        }
    }
    
    private var coursesSection: some View {
        LazyVStack(spacing: DesignTokens.Spacing.md) {
            ForEach(sampleCourses) { course in
                ProfileCourseRow(course: course)
            }
        }
    }
    
    private var savedSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.xs) {
            ForEach(profileManager.userPosts.shuffled()) { post in
                PostThumbnail(post: post)
            }
        }
    }
    
    private func tabIcon(for index: Int) -> String {
        switch index {
        case 0: return "grid.circle"
        case 1: return "trophy.circle"
        case 2: return "book.circle"
        case 3: return "bookmark.circle"
        default: return "circle"
        }
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Posts"
        case 1: return "Badges"
        case 2: return "Courses"
        case 3: return "Saved"
        default: return ""
        }
    }
}

// MARK: - Supporting Components

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Text(value)
                .font(DesignTokens.Typography.title2)
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct PostThumbnail: View {
    let post: ProfilePost
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(DesignTokens.Colors.gray200)
                .overlay(
                    Image(systemName: "text.alignleft")
                        .foregroundColor(DesignTokens.Colors.gray500)
                )
            // Overlay for post type
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "square.on.square")
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                Spacer()
            }
            .padding(4)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
}

struct AchievementCard: View {
    let badge: ProfileBadge
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: badge.iconName)
                .font(.largeTitle)
                .foregroundColor(badgeColor(for: badge.rarity))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(badgeColor(for: badge.rarity).opacity(0.1))
                )
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(badge.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .multilineTextAlignment(.center)
                
                Text(badge.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .cardStyle()
    }
    
    private func badgeColor(for rarity: BadgeRarity) -> Color {
        switch rarity {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

struct ProfileCourseRow: View {
    let course: ProfileCourse
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .fill(DesignTokens.Colors.gray200)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(course.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .lineLimit(1)
                
                Text(course.instructor)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
                
                if course.progress > 0 {
                    HStack {
                        Text("\(Int(course.progress * 100))% complete")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                        
                        Spacer()
                        
                        ProgressView(value: course.progress)
                            .frame(width: 60, height: 60)
                            .tint(DesignTokens.Colors.primary)
                    }
                } else {
                    Text("Not started")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                }
            }
            
            Spacer()
            
            Button("Continue") {
                // Handle continue course
            }
            .font(DesignTokens.Typography.caption)
            .foregroundColor(DesignTokens.Colors.primary)
        }
        .cardStyle()
    }
}

// MARK: - Sample Data and Missing Components

// Sample badges data
let sampleBadges = [
    ProfileBadge(id: "1", title: "First Steps", description: "Completed your first lesson", rarity: .common, iconName: "star.fill"),
    ProfileBadge(id: "2", title: "Streak Master", description: "Maintained a 7-day learning streak", rarity: .rare, iconName: "flame.fill"),
    ProfileBadge(id: "3", title: "Quiz Champion", description: "Scored 100% on 5 quizzes", rarity: .epic, iconName: "trophy.fill"),
    ProfileBadge(id: "4", title: "Course Completionist", description: "Finished an entire course", rarity: .legendary, iconName: "graduation.cap.fill")
]

// Sample courses data
let sampleCourses = [
    ProfileCourse(id: "1", title: "Swift Programming Basics", instructor: "Dr. Jane Smith", thumbnailURL: "", progress: 0.7),
    ProfileCourse(id: "2", title: "iOS Development", instructor: "John Developer", thumbnailURL: "", progress: 0.3),
    ProfileCourse(id: "3", title: "SwiftUI Fundamentals", instructor: "UI Expert", thumbnailURL: "", progress: 0.0),
    ProfileCourse(id: "4", title: "Advanced iOS", instructor: "Senior Dev", thumbnailURL: "", progress: 1.0)
]

struct ProfileBadge: Identifiable {
    let id: String
    let title: String
    let description: String
    let rarity: BadgeRarity
    let iconName: String
}

enum BadgeRarity: String, CaseIterable {
    case common, rare, epic, legendary
}

struct ProfileCourse: Identifiable {
    let id: String
    let title: String
    let instructor: String
    let thumbnailURL: String
    let progress: Double
}



#Preview {
    ProfileView()
        .environmentObject(AppState())
}
