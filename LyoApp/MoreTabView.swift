import SwiftUI

struct MoreTabView: View {
    @State private var showingProfile = false
    @State private var showingSettings = false
    
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
                            subtitle: "Courses and tutorials",
                            color: DesignTokens.Colors.neonPurple
                        ) {
                            // Navigate to Learn
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
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
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
