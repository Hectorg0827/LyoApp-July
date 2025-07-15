import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var notifications = true
    @State private var darkMode = false
    @State private var autoPlay = true
    @State private var dataUsage = "WiFi Only"
    @State private var language = "English"
    @State private var showingAbout = false
    @State private var showingPrivacy = false
    
    private let dataUsageOptions = ["WiFi Only", "WiFi + Cellular", "Never"]
    private let languageOptions = ["English", "Spanish", "French", "German", "Japanese"]
    
    var body: some View {
        NavigationView {
            List {
                // Account Section
                Section("Account") {
                    accountSettings
                }
                
                // Preferences Section
                Section("Preferences") {
                    preferencesSettings
                }
                
                // Privacy & Security Section
                Section("Privacy & Security") {
                    privacySettings
                }
                
                // About Section
                Section("About") {
                    aboutSettings
                }
                
                // Danger Zone
                Section("Account Actions") {
                    dangerZoneSettings
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
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingPrivacy) {
            PrivacyPolicyView()
        }
        .onAppear {
            darkMode = appState.isDarkMode
        }
    }
    
    private var accountSettings: some View {
        Group {
            HStack {
                DesignSystem.Avatar(
                    imageURL: appState.currentUser?.profileImageURL,
                    name: appState.currentUser?.fullName ?? "User",
                    size: 50
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.currentUser?.fullName ?? "User Name")
                        .font(DesignTokens.Typography.bodyMedium)
                    
                    Text(appState.currentUser?.email ?? "user@example.com")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.secondaryLabel)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                    .font(.caption)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Handle edit profile
            }
            
            SettingsRow(
                icon: "bell.fill",
                title: "Notifications",
                iconColor: DesignTokens.Colors.primary
            ) {
                Toggle("", isOn: $notifications)
                    .labelsHidden()
            }
            
            SettingsRow(
                icon: "moon.fill",
                title: "Dark Mode",
                iconColor: DesignTokens.Colors.secondary
            ) {
                Toggle("", isOn: $darkMode)
                    .labelsHidden()
                    .onChange(of: darkMode) { _, newValue in
                        appState.isDarkMode = newValue
                        appState.toggleDarkMode()
                    }
            }
        }
    }
    
    private var preferencesSettings: some View {
        Group {
            SettingsRow(
                icon: "play.circle.fill",
                title: "Auto-play Videos",
                iconColor: DesignTokens.Colors.success
            ) {
                Toggle("", isOn: $autoPlay)
                    .labelsHidden()
            }
            
            SettingsRow(
                icon: "wifi",
                title: "Data Usage",
                iconColor: DesignTokens.Colors.info
            ) {
                Picker("Data Usage", selection: $dataUsage) {
                    ForEach(dataUsageOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
            }
            
            SettingsRow(
                icon: "globe",
                title: "Language",
                iconColor: DesignTokens.Colors.warning
            ) {
                Picker("Language", selection: $language) {
                    ForEach(languageOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
            }
        }
    }
    
    private var privacySettings: some View {
        Group {
            SettingsNavigationRow(
                icon: "lock.fill",
                title: "Privacy Policy",
                iconColor: DesignTokens.Colors.error
            ) {
                showingPrivacy = true
            }
            
            SettingsNavigationRow(
                icon: "shield.fill",
                title: "Security",
                iconColor: DesignTokens.Colors.primary
            ) {
                // Handle security settings
            }
            
            SettingsNavigationRow(
                icon: "hand.raised.fill",
                title: "Blocked Users",
                iconColor: DesignTokens.Colors.secondary
            ) {
                // Handle blocked users
            }
        }
    }
    
    private var aboutSettings: some View {
        Group {
            SettingsNavigationRow(
                icon: "info.circle.fill",
                title: "About LyoApp",
                iconColor: DesignTokens.Colors.info
            ) {
                showingAbout = true
            }
            
            SettingsNavigationRow(
                icon: "star.fill",
                title: "Rate App",
                iconColor: DesignTokens.Colors.warning
            ) {
                // Handle rate app
            }
            
            SettingsNavigationRow(
                icon: "envelope.fill",
                title: "Contact Support",
                iconColor: DesignTokens.Colors.success
            ) {
                // Handle contact support
            }
        }
    }
    
    private var dangerZoneSettings: some View {
        Group {
            SettingsNavigationRow(
                icon: "arrow.right.square.fill",
                title: "Sign Out",
                iconColor: DesignTokens.Colors.error
            ) {
                signOut()
            }
            
            SettingsNavigationRow(
                icon: "trash.fill",
                title: "Delete Account",
                iconColor: DesignTokens.Colors.error,
                textColor: DesignTokens.Colors.error
            ) {
                // Handle delete account
            }
        }
    }
    
    private func signOut() {
        appState.currentUser = nil
        appState.isAuthenticated = false
        
        NotificationCenter.default.post(
            name: .userDidLogout,
            object: nil
        )
        
        dismiss()
    }
}

// MARK: - Settings Components

struct SettingsRow<Content: View>: View {
    let icon: String
    let title: String
    let iconColor: Color
    let textColor: Color
    let content: Content
    
    init(
        icon: String,
        title: String,
        iconColor: Color,
        textColor: Color = DesignTokens.Colors.label,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.textColor = textColor
        self.content = content()
    }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(title)
                .font(DesignTokens.Typography.body)
                .foregroundColor(textColor)
            
            Spacer()
            
            content
        }
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let title: String
    let iconColor: Color
    let textColor: Color
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        iconColor: Color,
        textColor: Color = DesignTokens.Colors.label,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.iconColor = iconColor
        self.textColor = textColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 20)
                
                Text(title)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Views

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // App Icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 80))
                        .foregroundStyle(DesignTokens.Colors.primaryGradient)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text("LyoApp")
                            .font(DesignTokens.Typography.hero)
                            .foregroundColor(DesignTokens.Colors.primary)
                        
                        Text("Version 1.0.0")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.secondaryLabel)
                    }
                    
                    Text("LyoApp is your ultimate learning companion, featuring AI-powered assistance, community engagement, and gamified learning experiences.")
                        .font(DesignTokens.Typography.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Features")
                            .font(DesignTokens.Typography.title3)
                        
                        SettingsFeatureRow(icon: "lightbulb.circle.fill", title: "AI Learning Companion", description: "Get personalized, Socratic guidance from Lyo")
                        SettingsFeatureRow(icon: "person.3.fill", title: "Community", description: "Connect with learners worldwide")
                        SettingsFeatureRow(icon: "trophy.fill", title: "Gamification", description: "Earn badges and level up")
                        SettingsFeatureRow(icon: "book.fill", title: "Courses", description: "Access to premium learning content")
                    }
                    .cardStyle()
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("About")
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

struct SettingsFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(DesignTokens.Colors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DesignTokens.Typography.bodyMedium)
                
                Text(description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.secondaryLabel)
            }
            
            Spacer()
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text("Privacy Policy")
                        .font(DesignTokens.Typography.title1)
                    
                    Text("Last updated: \(Date(), style: .date)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.secondaryLabel)
                    
                    privacySection(
                        title: "Information We Collect",
                        content: "We collect information you provide directly to us, such as when you create an account, update your profile, or communicate with us."
                    )
                    
                    privacySection(
                        title: "How We Use Your Information",
                        content: "We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you."
                    )
                    
                    privacySection(
                        title: "Information Sharing",
                        content: "We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy."
                    )
                    
                    privacySection(
                        title: "Data Security",
                        content: "We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction."
                    )
                    
                    privacySection(
                        title: "Contact Us",
                        content: "If you have any questions about this Privacy Policy, please contact us at privacy@lyoapp.com"
                    )
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("Privacy Policy")
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
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Text(title)
                .font(DesignTokens.Typography.title3)
            
            Text(content)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.secondaryLabel)
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState
    @State private var fullName = ""
    @State private var username = ""
    @State private var bio = ""
    @State private var email = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Profile Image Section
                    VStack(spacing: DesignTokens.Spacing.md) {
                        DesignSystem.Avatar(
                            imageURL: appState.currentUser?.profileImageURL,
                            name: appState.currentUser?.fullName ?? "User",
                            size: 100
                        )
                        
                        Button("Change Photo") {
                            // Handle photo change
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                    }
                    
                    // Form Fields
                    VStack(spacing: DesignTokens.Spacing.md) {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("Full Name")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.secondaryLabel)
                            
                            TextField("Enter your full name", text: $fullName)
                                .modernTextField()
                        }
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("Username")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.secondaryLabel)
                            
                            TextField("Enter your username", text: $username)
                                .modernTextField()
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("Bio")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.secondaryLabel)
                            
                            TextField("Tell us about yourself", text: $bio, axis: .vertical)
                                .modernTextField()
                                .lineLimit(3...6)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text("Email")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.secondaryLabel)
                            
                            TextField("Enter your email", text: $email)
                                .modernTextField()
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                    }
                    .cardStyle()
                    
                    Button("Save Changes") {
                        saveProfile()
                    }
                    .primaryButton()
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentUserData()
        }
    }
    
    private func loadCurrentUserData() {
        if let user = appState.currentUser {
            fullName = user.fullName
            username = user.username
            bio = user.bio ?? ""
            email = user.email
        }
    }
    
    private func saveProfile() {
        // Update user profile
        if var user = appState.currentUser {
            user.fullName = fullName
            user.username = username
            user.bio = bio.isEmpty ? nil : bio
            user.email = email
            
            appState.currentUser = user
        }
        
        dismiss()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
