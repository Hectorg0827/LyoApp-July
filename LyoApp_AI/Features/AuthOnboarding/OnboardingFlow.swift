import SwiftUI
import UserNotifications

struct OnboardingFlow: View {
    @EnvironmentObject var authState: AuthState
    @State private var currentStep = 0
    
    private let totalSteps = 5
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                    .progressViewStyle(LinearProgressViewStyle())
                    .tint(Tokens.Colors.brand)
                    .padding(.horizontal, Tokens.Spacing.lg)
                    .padding(.vertical, Tokens.Spacing.sm)
                
                // Current step content
                TabView(selection: $currentStep) {
                    LegalConsentView(onContinue: nextStep)
                        .tag(0)
                    
                    RoleSelectionView(onContinue: nextStep)
                        .tag(1)
                    
                    SubjectsGoalsView(onContinue: nextStep)
                        .tag(2)
                    
                    PrivacySettingsView(onContinue: nextStep)
                        .tag(3)
                    
                    NotificationPermissionView(onComplete: completeOnboarding)
                        .tag(4)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Tokens.Colors.primaryBg)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func nextStep() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentStep < totalSteps - 1 {
                currentStep += 1
            }
        }
    }
    
    private func completeOnboarding() {
        // Mark onboarding as complete
        authState.completeOnboarding()
    }
}

// MARK: - Legal Consent Step
struct LegalConsentView: View {
    @State private var hasAccepted = false
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            VStack(spacing: Tokens.Spacing.md) {
                Text("Legal Agreement")
                    .font(Typography.h1)
                    .foregroundColor(Tokens.Colors.textPrimary)
                
                Text("Before we begin, please review and accept our terms")
                    .font(Typography.body)
                    .foregroundColor(Tokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: Tokens.Spacing.lg) {
                LyoCard {
                    VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                        Text("Terms of Service & Privacy Policy")
                            .font(Typography.h5)
                            .foregroundColor(Tokens.Colors.textPrimary)
                        
                        Text("By using Lyo, you agree to our Terms of Service and Privacy Policy. We collect and process your data to provide personalized learning experiences while protecting your privacy.")
                            .font(Typography.body)
                            .foregroundColor(Tokens.Colors.textSecondary)
                        
                        HStack(spacing: Tokens.Spacing.md) {
                            Button("Read Terms") {
                                // Open terms
                            }
                            .font(Typography.labelLarge)
                            .foregroundColor(Tokens.Colors.brand)
                            
                            Button("Read Privacy Policy") {
                                // Open privacy
                            }
                            .font(Typography.labelLarge)
                            .foregroundColor(Tokens.Colors.brand)
                        }
                    }
                }
                
                // Acceptance checkbox
                HStack(alignment: .top, spacing: Tokens.Spacing.sm) {
                    Button(action: {
                        hasAccepted.toggle()
                    }) {
                        Image(systemName: hasAccepted ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundColor(hasAccepted ? Tokens.Colors.brand : Tokens.Colors.border)
                    }
                    
                    Text("I agree to the Terms of Service and Privacy Policy")
                        .font(Typography.body)
                        .foregroundColor(Tokens.Colors.textSecondary)
                }
                .padding(.horizontal, Tokens.Spacing.sm)
            }
            
            Spacer()
            
            LyoButton(
                "Continue",
                style: hasAccepted ? .primary : .secondary,
                action: onContinue
            )
            .disabled(!hasAccepted)
        }
        .padding(Tokens.Spacing.xl)
    }
}

// MARK: - Role Selection Step
struct RoleSelectionView: View {
    @State private var selectedRole: UserRole?
    let onContinue: () -> Void
    
    enum UserRole: String, CaseIterable {
        case student = "student"
        case teacher = "teacher"
        case guardian = "guardian"
        
        var title: String {
            switch self {
            case .student: return "Student"
            case .teacher: return "Teacher"
            case .guardian: return "Parent/Guardian"
            }
        }
        
        var description: String {
            switch self {
            case .student: return "I want to learn new skills and subjects"
            case .teacher: return "I want to teach and share knowledge"
            case .guardian: return "I'm here to support my child's learning"
            }
        }
        
        var icon: String {
            switch self {
            case .student: return "graduationcap"
            case .teacher: return "person.chalkboard"
            case .guardian: return "figure.and.child.holdinghands"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            VStack(spacing: Tokens.Spacing.md) {
                Text("What's your role?")
                    .font(Typography.h1)
                    .foregroundColor(Tokens.Colors.textPrimary)
                
                Text("Help us customize your experience")
                    .font(Typography.body)
                    .foregroundColor(Tokens.Colors.textSecondary)
            }
            
            Spacer()
            
            VStack(spacing: Tokens.Spacing.md) {
                ForEach(UserRole.allCases, id: \.rawValue) { role in
                    RoleCard(
                        role: role,
                        isSelected: selectedRole == role,
                        onSelect: { selectedRole = role }
                    )
                }
            }
            
            Spacer()
            
            LyoButton(
                "Continue",
                style: selectedRole != nil ? .primary : .secondary,
                action: onContinue
            )
            .disabled(selectedRole == nil)
        }
        .padding(Tokens.Spacing.xl)
    }
}

struct RoleCard: View {
    let role: RoleSelectionView.UserRole
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: Tokens.Spacing.md) {
                Image(systemName: role.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Tokens.Colors.brand : Tokens.Colors.textSecondary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                    Text(role.title)
                        .font(Typography.h6)
                        .foregroundColor(Tokens.Colors.textPrimary)
                    
                    Text(role.description)
                        .font(Typography.body)
                        .foregroundColor(Tokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? Tokens.Colors.brand : Tokens.Colors.border)
            }
            .padding(Tokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: Tokens.Radius.md)
                    .fill(Tokens.Colors.secondaryBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: Tokens.Radius.md)
                            .stroke(isSelected ? Tokens.Colors.brand : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Subjects & Goals Step
struct SubjectsGoalsView: View {
    @State private var selectedSubjects: Set<String> = []
    @State private var learningGoal = ""
    let onContinue: () -> Void
    
    private let availableSubjects = [
        "Mathematics", "Science", "Technology", "Programming",
        "Language Arts", "History", "Art", "Music",
        "Business", "Health", "Sports", "Cooking"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: Tokens.Spacing.xl) {
                VStack(spacing: Tokens.Spacing.md) {
                    Text("What interests you?")
                        .font(Typography.h1)
                        .foregroundColor(Tokens.Colors.textPrimary)
                    
                    Text("Select your subjects and set a learning goal")
                        .font(Typography.body)
                        .foregroundColor(Tokens.Colors.textSecondary)
                }
                
                // Subject selection
                VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                    Text("Subjects")
                        .font(Typography.h5)
                        .foregroundColor(Tokens.Colors.textPrimary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Tokens.Spacing.sm) {
                        ForEach(availableSubjects, id: \.self) { subject in
                            Chip(
                                subject,
                                isSelected: selectedSubjects.contains(subject),
                                action: {
                                    if selectedSubjects.contains(subject) {
                                        selectedSubjects.remove(subject)
                                    } else {
                                        selectedSubjects.insert(subject)
                                    }
                                }
                            )
                        }
                    }
                }
                
                // Learning goal
                VStack(alignment: .leading, spacing: Tokens.Spacing.md) {
                    Text("Primary Learning Goal")
                        .font(Typography.h5)
                        .foregroundColor(Tokens.Colors.textPrimary)
                    
                    TextField("What do you want to achieve?", text: $learningGoal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(Typography.body)
                }
                
                LyoButton(
                    "Continue",
                    style: !selectedSubjects.isEmpty ? .primary : .secondary,
                    action: onContinue
                )
                .disabled(selectedSubjects.isEmpty)
            }
            .padding(Tokens.Spacing.xl)
        }
    }
}

// MARK: - Privacy Settings Step
struct PrivacySettingsView: View {
    @State private var profileIsPrivate = true
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            VStack(spacing: Tokens.Spacing.md) {
                Text("Privacy Settings")
                    .font(Typography.h1)
                    .foregroundColor(Tokens.Colors.textPrimary)
                
                Text("Control who can see your profile and activity")
                    .font(Typography.body)
                    .foregroundColor(Tokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: Tokens.Spacing.lg) {
                LyoCard {
                    VStack(spacing: Tokens.Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                                Text("Private Profile")
                                    .font(Typography.h6)
                                    .foregroundColor(Tokens.Colors.textPrimary)
                                
                                Text("Only approved followers can see your posts and activity")
                                    .font(Typography.body)
                                    .foregroundColor(Tokens.Colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $profileIsPrivate)
                                .toggleStyle(SwitchToggleStyle(tint: Tokens.Colors.brand))
                        }
                    }
                }
                
                if profileIsPrivate {
                    LyoCard {
                        VStack(alignment: .leading, spacing: Tokens.Spacing.sm) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(Tokens.Colors.info)
                                Text("Recommended for Students")
                                    .font(Typography.labelLarge)
                                    .foregroundColor(Tokens.Colors.info)
                            }
                            
                            Text("With a private profile, people will need to send you a follow request to see your posts and learning progress.")
                                .font(Typography.body)
                                .foregroundColor(Tokens.Colors.textSecondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            LyoButton("Continue", action: onContinue)
        }
        .padding(Tokens.Spacing.xl)
    }
}

// MARK: - Notification Permission Step
struct NotificationPermissionView: View {
    @State private var hasRequested = false
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.xl) {
            VStack(spacing: Tokens.Spacing.md) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 64))
                    .foregroundColor(Tokens.Colors.brand)
                
                Text("Stay Updated")
                    .font(Typography.h1)
                    .foregroundColor(Tokens.Colors.textPrimary)
                
                Text("Get notified about new lessons, messages, and achievements")
                    .font(Typography.body)
                    .foregroundColor(Tokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: Tokens.Spacing.lg) {
                VStack(spacing: Tokens.Spacing.md) {
                    FeatureRow(icon: "graduationcap", title: "Learning Reminders", subtitle: "Daily study streaks and lesson notifications")
                    FeatureRow(icon: "message", title: "Messages", subtitle: "New messages from tutors and classmates")
                    FeatureRow(icon: "trophy", title: "Achievements", subtitle: "Celebrate your learning milestones")
                }
                
                if !hasRequested {
                    LyoButton("Enable Notifications") {
                        requestNotificationPermission()
                    }
                } else {
                    LyoButton("Get Started", action: onComplete)
                }
                
                if !hasRequested {
                    Button("Not Now") {
                        onComplete()
                    }
                    .font(Typography.body)
                    .foregroundColor(Tokens.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(Tokens.Spacing.xl)
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                hasRequested = true
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: Tokens.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Tokens.Colors.brand)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: Tokens.Spacing.xs) {
                Text(title)
                    .font(Typography.h6)
                    .foregroundColor(Tokens.Colors.textPrimary)
                
                Text(subtitle)
                    .font(Typography.body)
                    .foregroundColor(Tokens.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingFlow()
        .environmentObject(AuthState())
}
