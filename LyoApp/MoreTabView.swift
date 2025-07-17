import SwiftUI

struct MoreTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingProfile = false
    @State private var showingSettings = false
    @State private var showingLibrary = false
    @State private var showingAIChat = false
    
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
                            icon: "person.3.fill",
                            title: "Community",
                            subtitle: "Connect with learners",
                            color: DesignTokens.Colors.neonBlue
                        ) {
                            // Navigate to Community
                        }
                        
                        MoreMenuItem(
                            icon: "brain.head.profile",
                            title: "Learn",
                            subtitle: "AI-powered courses",
                            color: DesignTokens.Colors.neonPurple
                        ) {
                            showingLibrary = true
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
        .sheet(isPresented: $showingLibrary) {
            LibraryView()
        }
        .sheet(isPresented: $showingAIChat) {
            AIFullChatViewWithCompletion { topic in
                showingAIChat = false
            }
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
