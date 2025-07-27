import SwiftUI

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
                
                AsyncImage(url: URL(string: appState.currentUser?.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Text(appState.currentUser?.fullName.prefix(1) ?? "U")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
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
            // TODO: Replace with real data from UserDataManager
            ForEach([], id: \.id) { (course: LibraryCourse) in
                CompletedCourseCard(course: course)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    private var achievementsTab: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: DesignTokens.Spacing.md) {
            // TODO: Integrate with UserDataManager.shared.getUserAchievements()
            ForEach([Achievement]()) { achievement in
                AchievementCard(achievement: achievement)
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

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? DesignTokens.Colors.primaryGradient : DesignTokens.Colors.glassBg)
                    .frame(width: 60, height: 60)
                    .shadow(color: achievement.isUnlocked ? DesignTokens.Colors.primary.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 0)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.isUnlocked ? .white : DesignTokens.Colors.textSecondary)
            }
            
            VStack(spacing: DesignTokens.Spacing.xs) {
                Text(achievement.title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(achievement.description)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(achievement.isUnlocked ? DesignTokens.Colors.primary.opacity(0.3) : DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let unlockedDate: Date?
    
    // MARK: - Sample Data Removed
    // All sample achievements moved to UserDataManager for real data management
    // static let sampleAchievements = [] // Use UserDataManager.shared.getUserAchievements()
}

#Preview {
    ProfileView()
        .environmentObject(AppState())
}