import SwiftUI
import Foundation

struct AICourseGeneratorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var avatarService = AIAvatarService.shared
    @Environment(\.dismiss) private var dismiss
    
    // Course Configuration
    @State private var courseTitle = ""
    @State private var courseTopic = "Swift Programming"
    @State private var difficulty: CourseDifficulty = .intermediate
    @State private var duration: CourseDuration = .fourWeeks
    @State private var learningStyle: AILearningStyle = .socratic
    @State private var includeProjects = true
    @State private var includeAssessments = true
    @State private var includeMentorship = true
    
    // Generation State
    @State private var isGenerating = false
    @State private var generatedCourse: AICourse?
    @State private var generationProgress: Double = 0.0
    @State private var currentGenerationStep = ""
    @State private var showingPreview = false
    
    // Available Topics
    let availableTopics = [
        "Swift Programming", "SwiftUI", "iOS Development", "UIKit", 
        "Core Data", "Networking", "Architecture Patterns", "Testing",
        "Performance Optimization", "App Store Deployment",
        "Machine Learning", "ARKit", "WidgetKit", "App Clips"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Header
                    courseGeneratorHeader
                    
                    if !isGenerating && generatedCourse == nil {
                        // Configuration Form
                        courseConfigurationForm
                        
                        // Generate Button
                        generateCourseButton
                    } else if isGenerating {
                        // Generation Progress
                        courseGenerationProgress
                    } else if let course = generatedCourse {
                        // Generated Course Preview
                        generatedCourseView(course: course)
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.primaryBg)
            .navigationTitle("AI Course Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if generatedCourse != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Create New") {
                            resetCourseGenerator()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var courseGeneratorHeader: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "graduation.cap")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text("AI-Powered Course Generator")
                .font(DesignTokens.Typography.title2)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Create personalized learning paths with superior AI capabilities")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.lg)
    }
    
    // MARK: - Configuration Form
    private var courseConfigurationForm: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Course Basic Info
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Course Configuration")
                    .font(DesignTokens.Typography.title3)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    TextField("Course Title (optional)", text: $courseTitle)
                        .textFieldStyle(.roundedBorder)
                    
                    Picker("Topic", selection: $courseTopic) {
                        ForEach(availableTopics, id: \.self) { topic in
                            Text(topic).tag(topic)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.glassBg)
            .cornerRadius(DesignTokens.Radius.lg)
            
            // Learning Preferences
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Learning Preferences")
                    .font(DesignTokens.Typography.title3)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Difficulty Level
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Difficulty Level")
                            .font(DesignTokens.Typography.bodyMedium)
                        
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(CourseDifficulty.allCases, id: \.self) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Duration
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Course Duration")
                            .font(DesignTokens.Typography.bodyMedium)
                        
                        Picker("Duration", selection: $duration) {
                            ForEach(CourseDuration.allCases, id: \.self) { duration in
                                Text(duration.displayName).tag(duration)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Learning Style
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Teaching Approach")
                            .font(DesignTokens.Typography.bodyMedium)
                        
                        Picker("Learning Style", selection: $learningStyle) {
                            ForEach(AILearningStyle.allCases, id: \.self) { style in
                                VStack(alignment: .leading) {
                                    Text(style.displayName)
                                    Text(style.description)
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                .tag(style)
                            }
                        }
                        .pickerStyle(.navigationLink)
                    }
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.glassBg)
            .cornerRadius(DesignTokens.Radius.lg)
            
            // Course Features
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text("Course Features")
                    .font(DesignTokens.Typography.title3)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Toggle("Include Hands-on Projects", isOn: $includeProjects)
                    Toggle("Include Adaptive Assessments", isOn: $includeAssessments)
                    Toggle("Include AI Mentorship", isOn: $includeMentorship)
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.glassBg)
            .cornerRadius(DesignTokens.Radius.lg)
        }
    }
    
    // MARK: - Generate Button
    private var generateCourseButton: some View {
        Button {
            generateCourse()
        } label: {
            HStack {
                Image(systemName: "brain.head.profile")
                Text("Generate Course with AI")
            }
            .font(DesignTokens.Typography.bodyMedium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(DesignTokens.Spacing.lg)
            .background(
                LinearGradient(
                    colors: [DesignTokens.Colors.primary, DesignTokens.Colors.primary.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(DesignTokens.Radius.button)
        }
        .disabled(isGenerating)
    }
    
    // MARK: - Generation Progress
    private var courseGenerationProgress: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Text("Generating Your Course")
                .font(DesignTokens.Typography.title2)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            // AI Brain Animation
            ZStack {
                Circle()
                    .stroke(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: generationProgress)
                    .stroke(DesignTokens.Colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: generationProgress)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            Text(currentGenerationStep)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            ProgressView(value: generationProgress)
                .progressViewStyle(.linear)
                .tint(DesignTokens.Colors.primary)
        }
        .padding(DesignTokens.Spacing.xl)
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.lg)
    }
    
    // MARK: - Generated Course View
    private func generatedCourseView(course: AICourse) -> some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Course Header
            CourseHeaderView(course: course)
            
            // Course Overview
            CourseOverviewView(course: course)
            
            // Course Modules
            CourseModulesView(course: course)
            
            // Action Buttons
            HStack(spacing: DesignTokens.Spacing.md) {
                Button("Preview Course") {
                    showingPreview = true
                }
                .buttonStyle(.bordered)
                
                Button("Start Learning") {
                    startCourse(course)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $showingPreview) {
            CoursePreviewView(course: course)
        }
    }
    
    // MARK: - Methods
    
    private func generateCourse() {
        isGenerating = true
        generationProgress = 0.0
        
        Task {
            await performCourseGeneration()
        }
    }
    
    private func performCourseGeneration() async {
        let steps = [
            "Analyzing learning requirements...",
            "Generating course structure...",
            "Creating learning modules...",
            "Designing assessments...",
            "Adding interactive elements...",
            "Optimizing for your learning style...",
            "Finalizing course content..."
        ]
        
        for (index, step) in steps.enumerated() {
            await MainActor.run {
                currentGenerationStep = step
                generationProgress = Double(index + 1) / Double(steps.count)
            }
            
            // Simulate AI processing time
            try? await Task.sleep(nanoseconds: UInt64.random(in: 500_000_000...1_500_000_000))
        }
        
        // Generate the actual course using the AI backend
        let coursePrompt = """
        Generate a comprehensive \(difficulty.rawValue) level course on "\(courseTopic)" with the following specifications:
        
        Title: \(courseTitle.isEmpty ? "Auto-generated" : courseTitle)
        Duration: \(duration.displayName)
        Learning Style: \(learningStyle.displayName)
        Include Projects: \(includeProjects)
        Include Assessments: \(includeAssessments)
        Include Mentorship: \(includeMentorship)
        
        Use \(learningStyle.rawValue) teaching methods and create a structured course with modules, lessons, and practical exercises.
        """
        
        do {
            let courseContent = try await avatarService.apiClient.generateCourseWithBackend(coursePrompt, difficulty: difficulty.rawValue)
            
            await MainActor.run {
                generatedCourse = AICourse(
                    id: UUID(),
                    title: courseTitle.isEmpty ? "AI-Generated \(courseTopic) Course" : courseTitle,
                    topic: courseTopic,
                    difficulty: difficulty,
                    duration: duration,
                    learningStyle: learningStyle,
                    description: courseContent,
                    modules: generateCourseModules(),
                    includeProjects: includeProjects,
                    includeAssessments: includeAssessments,
                    includeMentorship: includeMentorship,
                    createdAt: Date()
                )
                isGenerating = false
            }
        } catch {
            await MainActor.run {
                // Show error - no fallback
                errorMessage = "Failed to generate course: \(error.localizedDescription). Please check your connection and try again."
                isGenerating = false
            }
            print("❌ [AICourseGen] Course generation failed - no fallback")
        }
    }
    
    private func generateCourseModules() -> [CourseModule] {
        let moduleCount = duration.weekCount
        var modules: [CourseModule] = []
        
        for i in 1...moduleCount {
            modules.append(CourseModule(
                id: UUID(),
                title: "Module \(i): \(getModuleTitle(for: i, topic: courseTopic))",
                description: "Deep dive into \(getModuleTitle(for: i, topic: courseTopic))",
                lessons: generateLessons(for: i),
                weekNumber: i,
                estimatedHours: difficulty.hoursPerWeek
            ))
        }
        
        return modules
    }
    
    private func generateLessons(for moduleNumber: Int) -> [CourseLesson] {
        return [
            CourseLesson(
                id: UUID(),
                title: "Lesson \(moduleNumber).1: Introduction",
                content: "Introduction to module topics",
                type: .video,
                estimatedMinutes: 30
            ),
            CourseLesson(
                id: UUID(),
                title: "Lesson \(moduleNumber).2: Hands-on Practice",
                content: "Practical exercises and coding",
                type: .interactive,
                estimatedMinutes: 45
            ),
            CourseLesson(
                id: UUID(),
                title: "Lesson \(moduleNumber).3: Assessment",
                content: "Knowledge check and evaluation",
                type: .assessment,
                estimatedMinutes: 15
            )
        ]
    }
    
    private func getModuleTitle(for moduleNumber: Int, topic: String) -> String {
        let moduleTitles: [String: [String]] = [
            "Swift Programming": ["Fundamentals", "Object-Oriented Programming", "Advanced Features", "Best Practices"],
            "SwiftUI": ["Views and Layouts", "State Management", "Navigation", "Advanced UI"],
            "iOS Development": ["Getting Started", "Interface Building", "Data & Networking", "App Store Ready"]
        ]
        
        let titles = moduleTitles[topic] ?? ["Foundation", "Intermediate", "Advanced", "Mastery"]
        return titles[min(moduleNumber - 1, titles.count - 1)]
    }
    
    // REMOVED: generateFallbackCourse() - No fallback, fail with error message
    
    private func startCourse(_ course: AICourse) {
        // Navigate to course learning interface
        appState.startGeneratedCourse(course)
        dismiss()
    }
    
    private func resetCourseGenerator() {
        generatedCourse = nil
        isGenerating = false
        generationProgress = 0.0
        currentGenerationStep = ""
    }
}

// MARK: - Supporting Views

struct CourseHeaderView: View {
    let course: AICourse
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: course.learningStyle.icon)
                    .font(.system(size: 24))
                    .foregroundColor(DesignTokens.Colors.primary)
                
                VStack(alignment: .leading) {
                    Text(course.title)
                        .font(DesignTokens.Typography.title3)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("\(course.difficulty.displayName) • \(course.duration.displayName)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: DesignTokens.Spacing.lg) {
                CourseStatView(title: "Modules", value: "\(course.modules.count)", icon: "books.vertical")
                CourseStatView(title: "Est. Time", value: "\(course.totalEstimatedHours)h", icon: "clock")
                CourseStatView(title: "Style", value: course.learningStyle.shortName, icon: "brain.head.profile")
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.lg)
    }
}

struct CourseOverviewView: View {
    let course: AICourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Course Overview")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(course.description)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.lg)
    }
}

struct CourseModulesView: View {
    let course: AICourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Course Modules")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            ForEach(course.modules) { module in
                ModuleRowView(module: module)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.lg)
    }
}

struct ModuleRowView: View {
    let module: CourseModule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(module.title)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("\(module.lessons.count) lessons • ~\(module.estimatedHours)h")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            Text("Week \(module.weekNumber)")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(DesignTokens.Colors.primary.opacity(0.1))
                .cornerRadius(4)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.primaryBg)
        .cornerRadius(DesignTokens.Radius.md)
    }
}

struct CourseStatView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(value)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(title)
                .font(DesignTokens.Typography.caption2)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
}

// MARK: - Course Preview View
struct CoursePreviewView: View {
    let course: AICourse
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    CourseHeaderView(course: course)
                    CourseOverviewView(course: course)
                    CourseModulesView(course: course)
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .navigationTitle("Course Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Data Models

enum CourseDifficulty: String, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate" 
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
    
    var hoursPerWeek: Int {
        switch self {
        case .beginner: return 3
        case .intermediate: return 5
        case .advanced: return 8
        }
    }
}

enum CourseDuration: String, CaseIterable {
    case twoWeeks = "2weeks"
    case fourWeeks = "4weeks" 
    case eightWeeks = "8weeks"
    
    var displayName: String {
        switch self {
        case .twoWeeks: return "2 Weeks"
        case .fourWeeks: return "4 Weeks"
        case .eightWeeks: return "8 Weeks"
        }
    }
    
    var weekCount: Int {
        switch self {
        case .twoWeeks: return 2
        case .fourWeeks: return 4
        case .eightWeeks: return 8
        }
    }
}

enum AILearningStyle: String, CaseIterable {
    case socratic = "socratic"
    case project = "project"
    case traditional = "traditional"
    case adaptive = "adaptive"
    
    var displayName: String {
        switch self {
        case .socratic: return "Socratic Method"
        case .project: return "Project-Based"
        case .traditional: return "Traditional"
        case .adaptive: return "Adaptive Learning"
        }
    }
    
    var description: String {
        switch self {
        case .socratic: return "Question-driven discovery learning"
        case .project: return "Learn by building real applications"
        case .traditional: return "Structured lessons and exercises"
        case .adaptive: return "AI-adjusted difficulty and pace"
        }
    }
    
    var shortName: String {
        switch self {
        case .socratic: return "Socratic"
        case .project: return "Project"
        case .traditional: return "Standard"
        case .adaptive: return "Adaptive"
        }
    }
    
    var icon: String {
        switch self {
        case .socratic: return "questionmark.circle"
        case .project: return "hammer"
        case .traditional: return "book"
        case .adaptive: return "brain.head.profile"
        }
    }
}

struct AICourse: Identifiable {
    let id: UUID
    let title: String
    let topic: String
    let difficulty: CourseDifficulty
    let duration: CourseDuration
    let learningStyle: AILearningStyle
    let description: String
    let modules: [CourseModule]
    let includeProjects: Bool
    let includeAssessments: Bool
    let includeMentorship: Bool
    let createdAt: Date
    
    var totalEstimatedHours: Int {
        return modules.reduce(0) { $0 + $1.estimatedHours }
    }
}

struct CourseModule: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let lessons: [CourseLesson]
    let weekNumber: Int
    let estimatedHours: Int
}

struct CourseLesson: Identifiable {
    let id: UUID
    let title: String
    let content: String
    let type: LessonType
    let estimatedMinutes: Int
}

enum LessonType {
    case video
    case reading
    case interactive
    case assessment
    case project
}

// MARK: - AppState Extension
extension AppState {
    func startGeneratedCourse(_ course: AICourse) {
        // Implementation would navigate to course learning interface
        print("Starting course: \(course.title)")
    }
}

#Preview {
    AICourseGeneratorView()
        .environmentObject(AppState())
}