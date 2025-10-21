import SwiftUI

// MARK: - Course Builder Flow View
// 6-step wizard for creating a personalized course (similar to QuickAvatarSetupView)

/// Coordinator for course builder flow steps (lightweight version)
@MainActor
final class CourseBuilderFlowCoordinator: ObservableObject {
    @Published var currentStep: CourseBuilderStep = .topic
    @Published var draft: CourseBlueprint
    
    let avatar: Avatar?
    let learningBlueprint: LearningBlueprint?
    
    init(avatar: Avatar?, learningBlueprint: LearningBlueprint?) {
        self.avatar = avatar
        self.learningBlueprint = learningBlueprint
        
        // Pre-fill from diagnostic and avatar
        let personality = avatar?.profile.basePersonality
        self.draft = CourseBlueprint(
            topic: learningBlueprint?.title ?? "",
            scope: "",
            level: .beginner,
            pedagogy: personality.map { TeachingStyle.fromPersonality($0) } ?? .balanced,
            avatarPersonality: personality
        )
    }
    
    func nextStep() {
        if let next = currentStep.next {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentStep = next
            }
        }
    }
    
    func previousStep() {
        if let previous = currentStep.previous {
            withAnimation(.easeInOut(duration: 0.4)) {
                currentStep = previous
            }
        }
    }
}

enum CourseBuilderStep: Int, CaseIterable {
    case topic = 0
    case level = 1
    case outcomes = 2
    case schedule = 3
    case style = 4
    case confirm = 5
    
    var title: String {
        switch self {
        case .topic: return "What do you want to learn?"
        case .level: return "Your experience level"
        case .outcomes: return "What you'll achieve"
        case .schedule: return "Your schedule"
        case .style: return "How you learn best"
        case .confirm: return "Ready to start?"
        }
    }
    
    var icon: String {
        switch self {
        case .topic: return "lightbulb.fill"
        case .level: return "chart.bar.fill"
        case .outcomes: return "target"
        case .schedule: return "calendar"
        case .style: return "paintbrush.fill"
        case .confirm: return "checkmark.circle.fill"
        }
    }
    
    var next: CourseBuilderStep? {
        CourseBuilderStep(rawValue: rawValue + 1)
    }
    
    var previous: CourseBuilderStep? {
        rawValue > 0 ? CourseBuilderStep(rawValue: rawValue - 1) : nil
    }
}

// MARK: - Main Course Builder View

struct CourseBuilderFlowView: View {
    @StateObject private var coordinator: CourseBuilderFlowCoordinator
    let onComplete: (CourseBlueprint) -> Void
    
    init(
        avatar: Avatar?,
        learningBlueprint: LearningBlueprint?,
        onComplete: @escaping (CourseBlueprint) -> Void
    ) {
        _coordinator = StateObject(wrappedValue: CourseBuilderFlowCoordinator(
            avatar: avatar,
            learningBlueprint: learningBlueprint
        ))
        self.onComplete = onComplete
    }
    
    var body: some View {
        ZStack {
            DesignTokens.Colors.primaryBg.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress bar
                CourseBuilderProgressBar(
                    current: coordinator.currentStep.rawValue,
                    total: CourseBuilderStep.allCases.count
                )
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.md)
                
                // Step content
                TabView(selection: $coordinator.currentStep) {
                    CourseTopicStepView(coordinator: coordinator)
                        .tag(CourseBuilderStep.topic)
                    
                    CourseLevelStepView(coordinator: coordinator)
                        .tag(CourseBuilderStep.level)
                    
                    CourseOutcomesStepView(coordinator: coordinator)
                        .tag(CourseBuilderStep.outcomes)
                    
                    CourseScheduleStepView(coordinator: coordinator)
                        .tag(CourseBuilderStep.schedule)
                    
                    CourseStyleStepView(coordinator: coordinator)
                        .tag(CourseBuilderStep.style)
                    
                    CourseConfirmStepView(
                        coordinator: coordinator,
                        onComplete: {
                            onComplete(coordinator.draft)
                        }
                    )
                    .tag(CourseBuilderStep.confirm)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: coordinator.currentStep)
            }
        }
    }
}

// MARK: - Progress Bar

struct CourseBuilderProgressBar: View {
    let current: Int
    let total: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? DesignTokens.Colors.accent : Color.white.opacity(0.2))
                    .frame(height: 4)
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
    }
}

// MARK: - Step 1: Topic

struct CourseTopicStepView: View {
    @ObservedObject var coordinator: CourseBuilderFlowCoordinator
    @State private var topicText: String = ""
    @State private var scopeText: String = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.Colors.accent)
                    
                    Text("What do you want to learn?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Tell us what you're curious about")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                // Topic input
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Topic or subject")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("e.g., Python programming, Calculus, History of Rome", text: $topicText)
                        .font(.system(size: 18))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .onChange(of: topicText) { _, newValue in
                            coordinator.draft.topic = newValue
                        }
                }
                
                // Scope input
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("What specifically? (optional)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("e.g., SwiftUI basics, Derivatives and integrals", text: $scopeText)
                        .font(.system(size: 18))
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .onChange(of: scopeText) { _, newValue in
                            coordinator.draft.scope = newValue
                        }
                }
                
                Spacer(minLength: 40)
                
                // Next button
                Button(action: {
                    coordinator.nextStep()
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }) {
                    HStack {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.Colors.accent)
                    .cornerRadius(16)
                }
                .disabled(topicText.isEmpty)
                .opacity(topicText.isEmpty ? 0.5 : 1.0)
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .onAppear {
            topicText = coordinator.draft.topic
            scopeText = coordinator.draft.scope
        }
    }
}

// MARK: - Step 2: Level

struct CourseLevelStepView: View {
    @ObservedObject var coordinator: CourseBuilderFlowCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.Colors.accent)
                    
                    Text("Your experience level")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("How familiar are you with \(coordinator.draft.topic)?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                // Level options
                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(CourseLevel.allCases, id: \.self) { level in
                        Button(action: {
                            coordinator.draft.level = level
                            UISelectionFeedbackGenerator().selectionChanged()
                        }) {
                            HStack {
                                Text(level.emoji)
                                    .font(.system(size: 32))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(level.rawValue)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(level.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                if coordinator.draft.level == level {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                }
                            }
                            .padding()
                            .background(
                                coordinator.draft.level == level
                                    ? Color.white.opacity(0.15)
                                    : Color.white.opacity(0.05)
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        coordinator.draft.level == level
                                            ? DesignTokens.Colors.accent
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                // Navigation buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button(action: {
                        coordinator.previousStep()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    Button(action: {
                        coordinator.nextStep()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.accent)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Step 3: Outcomes

struct CourseOutcomesStepView: View {
    @ObservedObject var coordinator: CourseBuilderFlowCoordinator
    @State private var customOutcome: String = ""
    
    var suggestedOutcomes: [String] {
        // Generate based on topic and level
        let topic = coordinator.draft.topic
        switch coordinator.draft.level {
        case .beginner:
            return [
                "Understand core \(topic) concepts",
                "Build a simple \(topic) project",
                "Gain confidence with fundamentals"
            ]
        case .intermediate:
            return [
                "Master intermediate \(topic) techniques",
                "Build real-world \(topic) applications",
                "Solve complex \(topic) problems"
            ]
        case .advanced:
            return [
                "Achieve expert-level \(topic) proficiency",
                "Contribute to advanced \(topic) projects",
                "Teach \(topic) to others"
            ]
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "target")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.Colors.accent)
                    
                    Text("What you'll achieve")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Select your learning goals")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                // Suggested outcomes
                VStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(suggestedOutcomes, id: \.self) { outcome in
                        Button(action: {
                            if coordinator.draft.outcomes.contains(outcome) {
                                coordinator.draft.outcomes.removeAll { $0 == outcome }
                            } else {
                                coordinator.draft.outcomes.append(outcome)
                            }
                            UISelectionFeedbackGenerator().selectionChanged()
                        }) {
                            HStack {
                                Image(systemName: coordinator.draft.outcomes.contains(outcome) ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundStyle(DesignTokens.Colors.accent)
                                
                                Text(outcome)
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                        }
                    }
                }
                
                // Add custom outcome
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Add your own goal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        TextField("Custom goal...", text: $customOutcome)
                            .font(.system(size: 16))
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                            .foregroundColor(.white)
                        
                        Button(action: {
                            if !customOutcome.isEmpty {
                                coordinator.draft.outcomes.append(customOutcome)
                                customOutcome = ""
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(DesignTokens.Colors.accent)
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                // Navigation buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button(action: {
                        coordinator.previousStep()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    Button(action: {
                        coordinator.nextStep()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.accent)
                        .cornerRadius(16)
                    }
                    .disabled(coordinator.draft.outcomes.isEmpty)
                    .opacity(coordinator.draft.outcomes.isEmpty ? 0.5 : 1.0)
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Step 4: Schedule

struct CourseScheduleStepView: View {
    @ObservedObject var coordinator: CourseBuilderFlowCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "calendar")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.Colors.accent)
                    
                    Text("Your schedule")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("How much time can you dedicate?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                // Minutes per day
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Minutes per day")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach([15, 30, 45, 60], id: \.self) { minutes in
                            Button(action: {
                                coordinator.draft.schedule.minutesPerDay = minutes
                                UISelectionFeedbackGenerator().selectionChanged()
                            }) {
                                Text("\(minutes) min")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(
                                        coordinator.draft.schedule.minutesPerDay == minutes
                                            ? .black : .white
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        coordinator.draft.schedule.minutesPerDay == minutes
                                            ? DesignTokens.Colors.accent
                                            : Color.white.opacity(0.1)
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Days per week
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Days per week")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach([3, 5, 7], id: \.self) { days in
                            Button(action: {
                                coordinator.draft.schedule.daysPerWeek = days
                                UISelectionFeedbackGenerator().selectionChanged()
                            }) {
                                Text("\(days) days")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(
                                        coordinator.draft.schedule.daysPerWeek == days
                                            ? .black : .white
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        coordinator.draft.schedule.daysPerWeek == days
                                            ? DesignTokens.Colors.accent
                                            : Color.white.opacity(0.1)
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Preferred time
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("Preferred time of day")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(PreferredTime.allCases, id: \.self) { time in
                            Button(action: {
                                coordinator.draft.schedule.preferredTime = time
                                UISelectionFeedbackGenerator().selectionChanged()
                            }) {
                                HStack {
                                    Text(time.emoji)
                                        .font(.system(size: 24))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(time.rawValue)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        
                                        Text(time.description)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    if coordinator.draft.schedule.preferredTime == time {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(DesignTokens.Colors.accent)
                                    }
                                }
                                .padding()
                                .background(
                                    coordinator.draft.schedule.preferredTime == time
                                        ? Color.white.opacity(0.15)
                                        : Color.white.opacity(0.05)
                                )
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                
                // Summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your commitment")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("\(coordinator.draft.schedule.totalMinutesPerWeek) minutes per week")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(DesignTokens.Colors.accent)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(12)
                
                Spacer(minLength: 40)
                
                // Navigation buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button(action: {
                        coordinator.previousStep()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    Button(action: {
                        coordinator.nextStep()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.accent)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Step 5: Teaching Style

struct CourseStyleStepView: View {
    @ObservedObject var coordinator: CourseBuilderFlowCoordinator
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.Colors.accent)
                    
                    Text("How you learn best")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let avatar = coordinator.avatar {
                        Text("\(avatar.name) suggests: \(TeachingStyle.fromPersonality(avatar.profile.basePersonality).rawValue)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                // Teaching styles
                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(TeachingStyle.allCases, id: \.self) { style in
                        Button(action: {
                            coordinator.draft.pedagogy = style
                            UISelectionFeedbackGenerator().selectionChanged()
                        }) {
                            HStack(alignment: .top) {
                                Text(style.emoji)
                                    .font(.system(size: 32))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(style.rawValue)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    
                                    Text(style.description)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                                
                                if coordinator.draft.pedagogy == style {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(DesignTokens.Colors.accent)
                                }
                            }
                            .padding()
                            .background(
                                coordinator.draft.pedagogy == style
                                    ? Color.white.opacity(0.15)
                                    : Color.white.opacity(0.05)
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        coordinator.draft.pedagogy == style
                                            ? DesignTokens.Colors.accent
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                        }
                    }
                }
                
                Spacer(minLength: 40)
                
                // Navigation buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button(action: {
                        coordinator.previousStep()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    Button(action: {
                        coordinator.nextStep()
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }) {
                        HStack {
                            Text("Continue")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.accent)
                        .cornerRadius(16)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Step 6: Confirm

struct CourseConfirmStepView: View {
    @ObservedObject var coordinator: CourseBuilderFlowCoordinator
    let onComplete: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // Header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(DesignTokens.Colors.accent)
                    
                    Text("Ready to start?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Review your course plan")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                // Course summary
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    SummaryRow(icon: "lightbulb.fill", title: "Topic", value: coordinator.draft.topic)
                    SummaryRow(icon: "chart.bar.fill", title: "Level", value: coordinator.draft.level.rawValue)
                    SummaryRow(icon: "calendar", title: "Schedule", value: coordinator.draft.schedule.formattedSchedule)
                    SummaryRow(icon: "paintbrush.fill", title: "Style", value: coordinator.draft.pedagogy.rawValue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundStyle(DesignTokens.Colors.accent)
                            Text("Goals")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(coordinator.draft.outcomes, id: \.self) { outcome in
                                HStack(alignment: .top) {
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.6))
                                    Text(outcome)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                
                Spacer(minLength: 40)
                
                // Navigation buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button(action: {
                        coordinator.previousStep()
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Back")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(16)
                    }
                    
                    Button(action: {
                        onComplete()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                    }) {
                        HStack {
                            Text("Create My Course")
                            Image(systemName: "sparkles")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [DesignTokens.Colors.accent, DesignTokens.Colors.neonYellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(DesignTokens.Colors.accent)
            
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
