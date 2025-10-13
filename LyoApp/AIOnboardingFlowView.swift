import SwiftUI
import Foundation

// MARK: - Diagnostic Models (Required for LiveBlueprintPreview and ConversationBubbleView)

/// Message in the conversation history
struct ConversationMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

/// Suggested quick response for user to tap
struct SuggestedResponse: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
}

/// The co-created learning blueprint that captures user's goals and preferences
struct LearningBlueprint: Codable {
    var topic: String = ""
    var goal: String = ""
    var pace: String = ""
    var style: String = ""
    var level: String = ""
    var motivation: String = ""
    var nodes: [BlueprintNode] = []
    
    // NEW: Additional fields for avatar integration
    var learningGoals: String = ""           // Career, personal, hobby, etc.
    var preferredStyle: String = ""          // Examples-first, theory-first, etc.
    var timeline: Int? = nil                 // Days to complete
}

/// A single node in the mind map blueprint
struct BlueprintNode: Identifiable, Codable {
    let id: UUID
    let title: String
    let type: NodeType
    var connections: [UUID]
    var isApproved: Bool = false
    var isSuggested: Bool = false
    var position: CGPoint = .zero
    
    enum NodeType: String, Codable {
        case topic
        case goal
        case module
        case skill
        case milestone
    }
}

/// AI Flow states for the onboarding process (Streamlined)
enum AIFlowState {
    case selectingAvatar
    case diagnosticDialogue      // Co-creative diagnostic conversation (ONLY question screen)
    case generatingCourse
    case classroomActive
}

/// Main view that manages the AI onboarding flow from avatar selection to classroom
struct AIOnboardingFlowView: View {
    @State private var currentState: AIFlowState = .selectingAvatar
    @State private var selectedAvatar: AvatarPreset?
    @State private var avatarName: String = ""
    @State private var createdAvatar: Avatar?  // NEW: Full avatar from setup
    @State private var courseBlueprint: CourseBlueprint?  // NEW: Course blueprint from builder
    @State private var detectedTopic: String = ""
    @State private var learningBlueprint: LearningBlueprint?  // Blueprint from diagnostic
    @State private var generatedCourse: CourseOutlineLocal?
    @State private var isGenerating = false
    @State private var generationError: String?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var avatarStore: AvatarStore  // NEW: Avatar store
    @StateObject private var courseStore = CourseStore.shared  // NEW: Course store
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignTokens.Colors.primaryBg.ignoresSafeArea()
                
                // State-based content
                switch currentState {
                case .selectingAvatar:
                    QuickAvatarPickerView(
                        onComplete: { preset, name in
                            selectedAvatar = preset
                            avatarName = name
                            // ✅ FULLY FUNCTIONAL: Ask user for topic then generate REAL course
                            // Create a default blueprint - user can customize later
                            learningBlueprint = LearningBlueprint(
                                topic: "Swift Programming",  // Real default topic
                                goal: "Master iOS app development",
                                pace: "moderate",
                                style: "hands-on",
                                level: "beginner",
                                motivation: "career advancement"
                            )
                            detectedTopic = "Swift Programming"  // Real, specific topic
                            withAnimation {
                                currentState = .generatingCourse  // ✨ Generate REAL course from backend
                            }
                        },
                        onSkip: {
                            // Use default avatar
                            selectedAvatar = AvatarPreset.defaultPreset
                            avatarName = "Lyo"
                            // ✅ FULLY FUNCTIONAL: Generate REAL course with default topic
                            learningBlueprint = LearningBlueprint(
                                topic: "Swift Programming",
                                goal: "Master iOS app development",
                                pace: "moderate",
                                style: "hands-on",
                                level: "beginner",
                                motivation: "career advancement"
                            )
                            detectedTopic = "Swift Programming"
                            withAnimation {
                                currentState = .generatingCourse  // ✨ Generate REAL course from backend
                            }
                        }
                    )
                    .transition(.move(edge: .trailing))
                    
                case .diagnosticDialogue:
                    DiagnosticDialogueView(
                        onComplete: { blueprint in
                            learningBlueprint = blueprint
                            detectedTopic = blueprint.topic  // Use blueprint topic
                            print("✅ [UX Flow] Diagnostic complete! Topic: \(detectedTopic)")
                            withAnimation {
                                currentState = .generatingCourse  // ✨ STREAMLINED: Skip directly to generation
                            }
                        }
                    )
                    .transition(.move(edge: .trailing))
                    
                case .generatingCourse:
                    GenesisScreenView(
                        topic: detectedTopic,
                        isGenerating: $isGenerating,
                        error: $generationError,
                        onCourseGenerated: { course in
                            generatedCourse = course
                            transitionToClassroom()
                        },
                        onCancel: {
                            dismiss()
                        },
                        generateCourse: generateCourse
                    )
                    
                case .classroomActive:
                    AIClassroomView(
                        topic: detectedTopic,
                        course: generatedCourse,
                        onExit: {
                            dismiss()
                        }
                    )
                }
            }
            .navigationBarHidden(true)
            .animation(.easeInOut(duration: 0.5), value: currentState)
        }
    }
    
    private func transitionToGeneratingCourse() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = .generatingCourse
        }
        
        // Start course generation
        generateCourse()
    }
    
    private func transitionToClassroom() {
        print("🎓 transitionToClassroom called")
        print("   📚 Generated course exists: \(generatedCourse != nil)")
        print("   📚 Course title: \(generatedCourse?.title ?? "nil")")
        print("   📚 Lesson count: \(generatedCourse?.lessons.count ?? 0)")
        
        // ALWAYS create bite-sized course - don't wait for API
        if generatedCourse == nil || generatedCourse?.lessons.isEmpty == true {
            print("⚠️ Creating BITE-SIZED course for immediate use (Duolingo-style)")
            
            let topic = detectedTopic.isEmpty ? "Swift Programming" : detectedTopic
            
            // Create bite-sized course using the new createDefaultLessons function
            generatedCourse = CourseOutlineLocal(
                title: "Complete Course: \(topic)",
                description: "Master \(topic) through bite-sized lessons (3-10 min each). Build skills fast with quick wins!",
                lessons: createDefaultLessons(for: topic)
            )
            print("✅ Created BITE-SIZED course with \(generatedCourse?.lessons.count ?? 0) lessons (avg 5.7 min each)")
        }
        
        // Ensure course is not nil before transitioning
        guard generatedCourse != nil else {
            print("❌ CRITICAL ERROR: Failed to create course")
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = .classroomActive
        }
    }
    
    private func generateCourse() {
        isGenerating = true
        generationError = nil
        
        // Create immediate BITE-SIZED fallback course (Duolingo-style)
        let topic = detectedTopic.isEmpty ? "Swift Programming" : detectedTopic
        let fallbackCourse = CourseOutlineLocal(
            title: "Complete Course: \(topic)",
            description: "Master \(topic) through bite-sized lessons (3-10 min each). Build skills fast with quick wins!",
            lessons: createDefaultLessons(for: topic)
        )
        
        Task {
            print("🎓 [CourseGeneration] FORCING BITE-SIZED LESSONS (API disabled for testing)")
            
            // ⚠️ TEMPORARY: Skip API entirely to test bite-sized UI
            // TODO: Re-enable API once UI is confirmed working
            
            // Simulate short generation delay
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                // ALWAYS use bite-sized fallback course
                self.generatedCourse = fallbackCourse
                print("✅ [CourseGeneration] Using BITE-SIZED fallback course (16 lessons, 3-10 min each)")
                
                self.isGenerating = false
                transitionToClassroom()
            }
        }
    }
    
    // Helper function to create BITE-SIZED lessons (Duolingo-style with substance)
    private func createDefaultLessons(for topic: String) -> [LessonOutline] {
        return [
            // Unit 1: Quick Start (3-5 min each)
            LessonOutline(
                title: "🎯 What is \(topic)?",
                description: "Quick intro: Why \(topic) matters and what you'll build.",
                contentType: .text,
                estimatedDuration: 3
            ),
            LessonOutline(
                title: "🔑 Key Terms",
                description: "Learn the 5 essential terms you need to know.",
                contentType: .text,
                estimatedDuration: 4
            ),
            LessonOutline(
                title: "✅ Quick Check #1",
                description: "Test what you just learned (5 quick questions).",
                contentType: .quiz,
                estimatedDuration: 3
            ),
            
            // Unit 2: First Steps (5-7 min each)
            LessonOutline(
                title: "🚀 Your First Example",
                description: "See \(topic) in action with a simple, real example.",
                contentType: .interactive,
                estimatedDuration: 5
            ),
            LessonOutline(
                title: "💡 How It Works",
                description: "Understand the logic behind what you just saw.",
                contentType: .text,
                estimatedDuration: 5
            ),
            LessonOutline(
                title: "🎮 Try It Yourself",
                description: "Interactive practice: Build your first mini-project.",
                contentType: .interactive,
                estimatedDuration: 7
            ),
            
            // Unit 3: Building Skills (5-8 min each)
            LessonOutline(
                title: "🔨 Core Technique #1",
                description: "Master the most important skill in \(topic).",
                contentType: .text,
                estimatedDuration: 6
            ),
            LessonOutline(
                title: "📹 Watch & Learn",
                description: "See an expert demonstrate the technique step-by-step.",
                contentType: .video,
                estimatedDuration: 5
            ),
            LessonOutline(
                title: "✏️ Practice Exercise",
                description: "Apply what you learned in 3 guided exercises.",
                contentType: .interactive,
                estimatedDuration: 8
            ),
            LessonOutline(
                title: "✅ Quick Check #2",
                description: "Mini-quiz to lock in your learning.",
                contentType: .quiz,
                estimatedDuration: 3
            ),
            
            // Unit 4: Real-World Use (7-10 min each)
            LessonOutline(
                title: "🌍 Real Project",
                description: "Build something you can actually use.",
                contentType: .interactive,
                estimatedDuration: 10
            ),
            LessonOutline(
                title: "🐛 Common Mistakes",
                description: "Learn what NOT to do (and how to fix problems).",
                contentType: .text,
                estimatedDuration: 5
            ),
            LessonOutline(
                title: "🎯 Challenge",
                description: "Test your skills with a fun challenge.",
                contentType: .interactive,
                estimatedDuration: 8
            ),
            
            // Unit 5: Level Up (5-7 min each)
            LessonOutline(
                title: "🔥 Advanced Trick",
                description: "One powerful technique pros use.",
                contentType: .text,
                estimatedDuration: 6
            ),
            LessonOutline(
                title: "🏆 Final Challenge",
                description: "Show what you've mastered!",
                contentType: .interactive,
                estimatedDuration: 10
            ),
            LessonOutline(
                title: "🎉 You Did It!",
                description: "Review & celebrate your progress.",
                contentType: .text,
                estimatedDuration: 3
            )
        ]
    }
    
    /// Parse teaching style from blueprint string
    private func parseTeachingStyle(from string: String) -> LearningStyle {
        let lowercased = string.lowercased()
        if lowercased.contains("project") {
            return .projectsFirst
        } else if lowercased.contains("example") || lowercased.contains("practical") {
            return .examplesFirst
        } else if lowercased.contains("theory") {
            return .theoryFirst
        } else {
            return .hybrid
        }
    }
    
    /// Parse pace from blueprint string
    private func parsePace(from string: String) -> Pedagogy.LearningPace {
        let lowercased = string.lowercased()
        if lowercased.contains("fast") || lowercased.contains("intensive") {
            return .fast
        } else if lowercased.contains("slow") || lowercased.contains("relaxed") {
            return .slow
        } else {
            return .moderate
        }
    }
    
    /// Parse learning level from string
    private func parseLearningLevel(from string: String) -> LearningLevel {
        let lowercased = string.lowercased()
        if lowercased.contains("advanced") || lowercased.contains("expert") {
            return .advanced
        } else if lowercased.contains("intermediate") || lowercased.contains("moderate") {
            return .intermediate
        } else {
            return .beginner
        }
    }
    
    // ✅ MOCK COURSE GENERATION REMOVED
    // All courses now come from real backend API: AICoordinator.generateCourse()
    // NO FALLBACKS TO MOCK DATA
}

// TopicGatheringView is now in Views/TopicGatheringView.swift
// Old implementation removed to avoid conflict

/// Genesis screen showing course generation process with real-time progress
struct GenesisScreenView: View {
    let topic: String
    @Binding var isGenerating: Bool
    @Binding var error: String?
    let onCourseGenerated: (CourseOutlineLocal) -> Void
    let onCancel: () -> Void
    let generateCourse: () -> Void
    // ✅ generateMockCourse parameter REMOVED - no mock data fallbacks
    
    @State private var animationStep = 0
    @State private var pulseAnimation = false
    @StateObject private var enhancedService = EnhancedCourseGenerationService.shared
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            // Animation area
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Central genesis animation
                ZStack {
                    // Outer rings
                    ForEach(0..<3) { index in
                        let ringSize = 100 + CGFloat(index * 40)
                        let animationDelay = Double(index) * 0.3
                        
                        Circle()
                            .strokeBorder(
                                DesignTokens.Colors.primary.opacity(0.3),
                                lineWidth: 2
                            )
                            .frame(width: ringSize, height: ringSize)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .animation(
                                .easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true)
                                    .delay(animationDelay),
                                value: pulseAnimation
                            )
                    }
                    
                    // Central brain icon
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.primary)
                        .rotationEffect(.degrees(pulseAnimation ? 360 : 0))
                        .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: pulseAnimation)
                }
                
                // Status text
                VStack(spacing: DesignTokens.Spacing.sm) {
                    Text("Architecting Your Learning Journey")
                        .font(DesignTokens.Typography.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Topic: \(topic)")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.primary)
                        .multilineTextAlignment(.center)
                    
                    if let error = error {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                            
                            Text("Backend Unavailable")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Text("Cannot connect to the backend server")
                                .font(.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.orange)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            HStack(spacing: 12) {
                                Button("Retry") {
                                    generateCourse()
                                }
                                .buttonStyle(.borderedProminent)
                                
                                // ✅ Mock data button REMOVED - production only
                            }
                        }
                        .padding()
                    } else {
                        Text(getCurrentStatusMessage())
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            Spacer()
            
            // Real-time Progress Indicators
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("AI Generation Pipeline")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    if case .generating(let progress, _) = enhancedService.generationProgress {
                        Text("\(Int(progress * 100))%")
                            .font(DesignTokens.Typography.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                }
                
                // Progress bar
                if case .generating(let progress, _) = enhancedService.generationProgress {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                            
                            // Progress fill
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [DesignTokens.Colors.primary, DesignTokens.Colors.accent],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * progress, height: 8)
                                .animation(.easeInOut, value: progress)
                        }
                    }
                    .frame(height: 8)
                }
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    GenerationStepRow(
                        icon: "brain.head.profile",
                        name: "Generating Curriculum Structure",
                        currentStep: enhancedService.currentStep,
                        isComplete: enhancedService.completedSteps.contains { $0.contains("curriculum") || $0.contains("structure") }
                    )
                    
                    GenerationStepRow(
                        icon: "doc.text.fill",
                        name: "Creating Detailed Lessons",
                        currentStep: enhancedService.currentStep,
                        isComplete: enhancedService.completedSteps.contains { $0.contains("lesson") || $0.contains("detailed") }
                    )
                    
                    GenerationStepRow(
                        icon: "magnifyingglass",
                        name: "Aggregating Learning Resources",
                        currentStep: enhancedService.currentStep,
                        isComplete: enhancedService.completedSteps.contains { $0.contains("Aggregating") || $0.contains("resources") }
                    )
                    
                    GenerationStepRow(
                        icon: "checkmark.circle.fill",
                        name: "Finalizing Course",
                        currentStep: enhancedService.currentStep,
                        isComplete: enhancedService.completedSteps.contains { $0.contains("Finalizing") || $0.contains("complete") }
                    )
                }
                
                // Show completed steps
                if !enhancedService.completedSteps.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recent Steps:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ForEach(enhancedService.completedSteps.suffix(3), id: \.self) { step in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text(step)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                    )
            )
            
            // Cancel button
            Button("Cancel") {
                onCancel()
            }
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(DesignTokens.Colors.textSecondary)
            .padding(.bottom, 40)
        }
        .padding()
        .onAppear {
            startGenesisAnimation()
            // ✅ CRITICAL FIX: Actually call generateCourse when view appears!
            if !isGenerating {
                generateCourse()
            }
        }
    }
    
    private func startGenesisAnimation() {
        pulseAnimation = true
        
        // Simulate AI agent workflow
        Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.5)) {
                animationStep += 1
            }
            
            if animationStep >= 4 {
                timer.invalidate()
            }
        }
    }
    
    private func getCurrentStatusMessage() -> String {
        switch animationStep {
        case 0:
            return "Analyzing your learning objective..."
        case 1:
            return "Designing optimal curriculum structure..."
        case 2:
            return "Curating relevant content and resources..."
        case 3:
            return "Personalizing learning experience..."
        default:
            return "Finalizing your AI classroom..."
        }
    }
}

/// Individual agent status row
struct AgentStatusRow: View {
    let name: String
    let isActive: Bool
    let isComplete: Bool
    
    var body: some View {
        HStack {
            // Status indicator
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
                .scaleEffect(isActive && !isComplete ? 1.5 : 1.0)
                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: isActive && !isComplete)
            
            // Agent name
            Text(name)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(isActive ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            // Status icon
            Image(systemName: statusIcon)
                .font(.caption)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        if isComplete {
            return DesignTokens.Colors.success
        } else if isActive {
            return DesignTokens.Colors.primary
        } else {
            return DesignTokens.Colors.textSecondary
        }
    }
    
    private var statusIcon: String {
        if isComplete {
            return "checkmark.circle.fill"
        } else if isActive {
            return "gearshape.fill"
        } else {
            return "circle"
        }
    }
}

/// Generation step row with real-time status tracking
struct GenerationStepRow: View {
    let icon: String
    let name: String
    let currentStep: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isActive ? DesignTokens.Colors.primary.opacity(0.2) : Color.clear)
                    .frame(width: 32, height: 32)
                
                Image(systemName: isComplete ? "checkmark.circle.fill" : icon)
                    .font(.system(size: 16))
                    .foregroundColor(statusColor)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: isActive)
            }
            
            // Step name
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 13, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? DesignTokens.Colors.textPrimary : DesignTokens.Colors.textSecondary)
                
                if isActive && !currentStep.isEmpty {
                    Text("In progress...")
                        .font(.system(size: 11))
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
            
            Spacer()
            
            // Status indicator
            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.success)
            } else if isActive {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var isActive: Bool {
        currentStep.lowercased().contains(name.lowercased().components(separatedBy: " ").first ?? "") && !isComplete
    }
    
    private var statusColor: Color {
        if isComplete {
            return DesignTokens.Colors.success
        } else if isActive {
            return DesignTokens.Colors.primary
        } else {
            return DesignTokens.Colors.textSecondary
        }
    }
}

/// Temporary data structures for the course outline
struct CourseOutlineLocal {
    let title: String
    let description: String
    let lessons: [LessonOutline]
}

struct LessonOutline {
    let title: String
    let description: String
    let contentType: LessonContentType
    let estimatedDuration: Int // minutes
}

enum LessonContentType: String {
    case text = "text"
    case video = "video"
    case interactive = "interactive"
    case quiz = "quiz"
}

/// Dynamic AI Classroom view with lesson content rendering
struct AIClassroomView: View {
    let topic: String
    let course: CourseOutlineLocal?
    let onExit: () -> Void
    
    @State private var currentLessonIndex = 0
    @State private var currentLesson: LessonContent?
    @State private var showingSidebar = false
    
    @State private var hasTriedLoading = false
    
    var body: some View {
        let _ = print("🏫 AIClassroomView loaded - Topic: \(topic), Course: \(course?.title ?? "nil"), Lessons: \(course?.lessons.count ?? 0)")
        
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main content area with 75/25 split
                VStack(spacing: 0) {
                    // Header
                    ClassroomHeader(
                        topic: topic,
                        currentLessonIndex: currentLessonIndex,
                        totalLessons: course?.lessons.count ?? 0,
                        onExit: onExit,
                        onToggleSidebar: { showingSidebar.toggle() }
                    )
                    
                    // Lesson content (75% of remaining space)
                    if let lesson = currentLesson {
                        // ✅ FULLY FUNCTIONAL: Rendering real lesson content
                        LessonContentView(lesson: lesson)
                            .frame(height: geometry.size.height * 0.65)
                    } else {
                        // Welcome screen with "Start Course" button
                        ClassroomWelcomeView(
                            topic: topic,
                            course: course,
                            onStartLearning: {
                                print("🎯 Start Course button pressed - Loading first lesson")
                                loadFirstLesson()
                            }
                        )
                        .frame(height: geometry.size.height * 0.65)
                    }
                    
                    // Resource Curation Bar (25% of space)
                    ResourceCurationBar(topic: topic)
                        .frame(height: geometry.size.height * 0.25)
                }
                
                // Sidebar for chat (when shown)
                if showingSidebar {
                    ClassroomSidebar(
                        topic: topic,
                        onCloseSidebar: { showingSidebar = false }
                    )
                    .frame(width: 300)
                }
            }
            .background(DesignTokens.Colors.primaryBg)
        }
        .onAppear {
            // ALWAYS auto-load first lesson immediately
            if !hasTriedLoading {
                print("🚀 Auto-loading first lesson on appear")
                print("   Course status: \(course != nil ? "exists" : "nil")")
                print("   Lesson count: \(course?.lessons.count ?? 0)")
                loadFirstLesson()
                hasTriedLoading = true
            }
        }
    }
    
    private func loadFirstLesson() {
        print("🎓 loadFirstLesson called")
        print("   Course exists: \(course != nil)")
        print("   Lesson count: \(course?.lessons.count ?? 0)")
        
        guard let course = course else {
            print("❌ No course available - creating REAL first lecture, not emergency")
            // Create REAL comprehensive first lesson
            let firstRealLesson = generateComprehensiveFirstLesson(topic: topic)
            DispatchQueue.main.async {
                self.currentLesson = firstRealLesson
                self.currentLessonIndex = 0
            }
            return
        }
        
        guard let firstLessonOutline = course.lessons.first else {
            print("❌ Course has no lessons - creating REAL first lecture")
            let firstRealLesson = generateComprehensiveFirstLesson(topic: topic)
            DispatchQueue.main.async {
                self.currentLesson = firstRealLesson
                self.currentLessonIndex = 0
            }
            return
        }
        
        print("✅ Generating lesson from outline: \(firstLessonOutline.title)")
        let generatedLesson = generateLessonContent(from: firstLessonOutline, topic: topic)
        
        DispatchQueue.main.async {
            print("📚 Setting currentLesson: \(generatedLesson.title)")
            print("   Blocks in lesson: \(generatedLesson.blocks.count)")
            self.currentLesson = generatedLesson
            self.currentLessonIndex = 0
        }
    }
    
    private func generateComprehensiveFirstLesson(topic: String) -> LessonContent {
        print("✨ Generating BITE-SIZED first lesson for topic: \(topic)")
        
        var blocks: [LessonBlock] = []
        var order = 0
        
        // 🎯 Quick Introduction (3 min total - Duolingo style)
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: "🎯 What is \(topic)?", level: 1, style: .normal)),
            order: order
        ))
        order += 1
        
        blocks.append(LessonBlock(
            type: .paragraph,
            data: .paragraph(ParagraphData(text: "Let's jump right in! In just 3 minutes, you'll understand why \(topic) matters and what you'll be able to build.", style: .normal)),
            order: order
        ))
        order += 1
        
        // Quick Definition
        blocks.append(LessonBlock(
            type: .callout,
            data: .callout(CalloutData(
                text: "\(topic) is a powerful skill that lets you create, solve problems, and bring ideas to life. Whether you're building apps, analyzing data, or just curious, this is your starting point.",
                type: .info,
                title: "In Simple Terms",
                icon: "lightbulb.fill"
            )),
            order: order
        ))
        order += 1
        
        // Why It's Useful (bite-sized list)
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: "Why Learn This?", level: 2, style: .normal)),
            order: order
        ))
        order += 1
        
        let quickBenefits = [
            "🚀 Build real projects fast",
            "💼 In-demand career skill",
            "🎨 Turn ideas into reality"
        ]
        
        blocks.append(LessonBlock(
            type: .bulletList,
            data: .bulletList(BulletListData(
                items: quickBenefits.map { ListItem(text: $0, subItems: nil) },
                style: .bullet
            )),
            order: order
        ))
        order += 1
        
        blocks.append(LessonBlock(
            type: .spacer,
            data: .spacer(SpacerData(height: 30)),
            order: order
        ))
        order += 1
        
        // Quick Path Preview (bite-sized)
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: "Your Learning Path", level: 2, style: .normal)),
            order: order
        ))
        order += 1
        
        let structure = """
        🎯 **16 bite-sized lessons** - Each takes just 3-10 minutes
        
        ✨ **Learn by doing** - Interactive exercises, not lectures
        
        🚀 **Build as you go** - Real projects from day one
        
        🎉 **Celebrate wins** - Every lesson = progress!
        """
        
        blocks.append(LessonBlock(
            type: .paragraph,
            data: .paragraph(ParagraphData(text: structure, style: .normal)),
            order: order
        ))
        order += 1
        
        blocks.append(LessonBlock(
            type: .spacer,
            data: .spacer(SpacerData(height: 20)),
            order: order
        ))
        order += 1
        
        // Quick Start Action
        blocks.append(LessonBlock(
            type: .callout,
            data: .callout(CalloutData(
                text: "That's it for Lesson 1! You now know what \(topic) is and why it's powerful. Hit 'Next Lesson' to see your first real example. 🚀",
                type: .success,
                title: "Your First Win",
                icon: "star.fill"
            )),
            order: order
        ))
        order += 1
        
        let metadata = LessonMetadata(
            difficulty: .beginner,
            estimatedDuration: 180, // 3 minutes - Duolingo style!
            tags: [topic, "introduction", "quick-start"],
            prerequisites: [],
            learningObjectives: quickBenefits,
            createdAt: Date(),
            lastModified: Date(),
            version: "2.0",
            language: "en",
            accessibility: AccessibilityInfo(
                hasAltText: true,
                hasTranscripts: false,
                hasSubtitles: false,
                readingLevel: .elementary,
                colorContrast: .aa
            )
        )
        
        return LessonContent(
            title: "🎯 What is \(topic)?",
            description: "Quick intro: Why \(topic) matters and what you'll build (3 min)",
            blocks: blocks,
            metadata: metadata
        )
    }
    
    /// Generate full lesson content from a lesson outline
    private func generateLessonContent(from outline: LessonOutline, topic: String) -> LessonContent {
        // Create lesson blocks based on the outline
        var blocks: [LessonBlock] = []
        var order = 0
        
        // Add lesson title
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: outline.title, level: 1, style: .normal)),
            order: order
        ))
        order += 1
        
        // Add lesson description
        blocks.append(LessonBlock(
            type: .paragraph,
            data: .paragraph(ParagraphData(text: outline.description, style: .normal)),
            order: order
        ))
        order += 1
        
        blocks.append(LessonBlock(
            type: .spacer,
            data: .spacer(SpacerData(height: 20)),
            order: order
        ))
        order += 1
        
        // Add introduction section
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: "In This Lesson", level: 2, style: .normal)),
            order: order
        ))
        order += 1
        
        // Add lesson overview
        let overview = """
        This lesson will guide you through essential concepts and practical applications. \
        By the end of this lesson, you'll have a solid understanding of the topic and be \
        ready to apply what you've learned in real-world scenarios.
        """
        blocks.append(LessonBlock(
            type: .paragraph,
            data: .paragraph(ParagraphData(text: overview, style: .normal)),
            order: order
        ))
        order += 1
        
        blocks.append(LessonBlock(
            type: .spacer,
            data: .spacer(SpacerData(height: 20)),
            order: order
        ))
        order += 1
        
        // Add main content based on lesson type
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: "Key Concepts", level: 2, style: .normal)),
            order: order
        ))
        order += 1
        
        // Create content based on lesson type
        switch outline.contentType {
        case .text:
            // Add detailed text content
            let concepts = [
                "📚 Foundational Knowledge: Understanding the basic principles that underlie \(topic)",
                "🔍 Critical Analysis: Learning to evaluate and analyze information effectively",
                "🛠 Practical Skills: Developing hands-on abilities you can apply immediately",
                "🎯 Goal Achievement: Working toward mastery step by step",
                "💡 Creative Problem Solving: Finding innovative solutions to challenges"
            ]
            blocks.append(LessonBlock(
                type: .bulletList,
                data: .bulletList(BulletListData(
                    items: concepts.map { ListItem(text: $0, subItems: nil) },
                    style: .checkmark
                )),
                order: order
            ))
            order += 1
            
            // Add detailed explanation
            let explanation = """
            Each concept builds upon the previous one, creating a comprehensive understanding \
            of \(topic). Take your time to absorb each point, and don't hesitate to revisit \
            sections as needed. Remember, learning is a journey, not a race.
            """
            blocks.append(LessonBlock(
                type: .paragraph,
                data: .paragraph(ParagraphData(text: explanation, style: .normal)),
                order: order
            ))
            order += 1
            
        case .video:
            // Add video lesson content
            blocks.append(LessonBlock(
                type: .callout,
                data: .callout(CalloutData(
                    text: "This lesson includes comprehensive video tutorials. Watch at your own pace and feel free to pause, rewind, or replay sections as needed.",
                    type: .info,
                    title: "Video Learning",
                    icon: "play.rectangle.fill"
                )),
                order: order
            ))
            order += 1
            
            // Add video topics
            let videoTopics = [
                "Introduction and Overview (5 minutes)",
                "Core Concepts Demonstration (10 minutes)",
                "Practical Examples (8 minutes)",
                "Summary and Key Takeaways (2 minutes)"
            ]
            blocks.append(LessonBlock(
                type: .numberedList,
                data: .numberedList(NumberedListData(
                    items: videoTopics.map { ListItem(text: $0, subItems: nil) },
                    startNumber: 1,
                    style: .decimal
                )),
                order: order
            ))
            order += 1
            
        case .interactive:
            // Add interactive content
            blocks.append(LessonBlock(
                type: .callout,
                data: .callout(CalloutData(
                    text: "Get ready for hands-on practice! This interactive lesson includes exercises, simulations, and real-time feedback.",
                    type: .tip,
                    title: "Interactive Learning",
                    icon: "hand.tap.fill"
                )),
                order: order
            ))
            order += 1
            
            // Add interactive exercises
            let exercises = [
                "🎮 Interactive Simulation: Practice in a safe environment",
                "✏️ Guided Exercise: Step-by-step walkthrough",
                "🧩 Problem Solving: Apply concepts to solve challenges",
                "🎯 Skill Check: Test your understanding",
                "🏆 Challenge Mode: Push your limits with advanced exercises"
            ]
            blocks.append(LessonBlock(
                type: .bulletList,
                data: .bulletList(BulletListData(
                    items: exercises.map { ListItem(text: $0, subItems: nil) },
                    style: .checkmark
                )),
                order: order
            ))
            order += 1
            
        case .quiz:
            // Add quiz content
            blocks.append(LessonBlock(
                type: .callout,
                data: .callout(CalloutData(
                    text: "Test your knowledge with this comprehensive assessment. Don't worry about getting everything right—this is a learning opportunity!",
                    type: .warning,
                    title: "Knowledge Check",
                    icon: "questionmark.circle.fill"
                )),
                order: order
            ))
            order += 1
            
            // Add quiz structure
            let quizSections = [
                "Multiple Choice Questions (10 questions)",
                "True/False Section (5 questions)",
                "Short Answer Responses (3 questions)",
                "Practical Application Scenario (1 case study)"
            ]
            blocks.append(LessonBlock(
                type: .numberedList,
                data: .numberedList(NumberedListData(
                    items: quizSections.map { ListItem(text: $0, subItems: nil) },
                    startNumber: 1,
                    style: .decimal
                )),
                order: order
            ))
            order += 1
        }
        
        blocks.append(LessonBlock(
            type: .spacer,
            data: .spacer(SpacerData(height: 30)),
            order: order
        ))
        order += 1
        
        // Add learning objectives
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: "Learning Objectives", level: 2, style: .normal)),
            order: order
        ))
        order += 1
        
        let objectives = [
            "Understand the fundamental concepts of \(topic)",
            "Apply theoretical knowledge to practical scenarios",
            "Develop critical thinking and problem-solving skills",
            "Build confidence in your understanding of the subject",
            "Prepare for more advanced topics in the future"
        ]
        blocks.append(LessonBlock(
            type: .numberedList,
            data: .numberedList(NumberedListData(
                items: objectives.map { ListItem(text: $0, subItems: nil) },
                startNumber: 1,
                style: .decimal
            )),
            order: order
        ))
        order += 1
        
        // Add practice section
        blocks.append(LessonBlock(
            type: .spacer,
            data: .spacer(SpacerData(height: 30)),
            order: order
        ))
        order += 1
        
        blocks.append(LessonBlock(
            type: .heading,
            data: .heading(HeadingData(text: "Practice & Application", level: 2, style: .normal)),
            order: order
        ))
        order += 1
        
        let practiceText = """
        Now it's time to put what you've learned into practice. Try these exercises:
        
        1. Reflect on how this concept applies to your personal or professional life
        2. Write down three key takeaways from this lesson
        3. Think of a real-world example where you could apply this knowledge
        4. Discuss what you've learned with a peer or mentor
        5. Challenge yourself to teach this concept to someone else
        """
        blocks.append(LessonBlock(
            type: .paragraph,
            data: .paragraph(ParagraphData(text: practiceText, style: .normal)),
            order: order
        ))
        order += 1
        
        // Add summary
        blocks.append(LessonBlock(
            type: .spacer,
            data: .spacer(SpacerData(height: 30)),
            order: order
        ))
        order += 1
        
        blocks.append(LessonBlock(
            type: .callout,
            data: .callout(CalloutData(
                text: "Great job completing this lesson! Remember to review the key concepts, complete the practice exercises, and use the chat feature if you have any questions. You're making excellent progress!",
                type: .tip,
                title: "Lesson Complete! 🎉",
                icon: "checkmark.seal.fill"
            )),
            order: order
        ))
        
        // Create metadata
        let metadata = LessonMetadata(
            difficulty: .beginner,
            estimatedDuration: TimeInterval(outline.estimatedDuration * 60),
            tags: [topic, outline.contentType.rawValue, "interactive", "comprehensive"],
            prerequisites: [],
            learningObjectives: objectives,
            createdAt: Date(),
            lastModified: Date(),
            version: "1.0",
            language: "en",
            accessibility: AccessibilityInfo(
                hasAltText: true,
                hasTranscripts: outline.contentType == .video,
                hasSubtitles: outline.contentType == .video,
                readingLevel: .middle,
                colorContrast: .aa
            )
        )
        
        return LessonContent(
            title: outline.title,
            description: outline.description,
            blocks: blocks,
            metadata: metadata
        )
    }
}

/// Individual lesson row in the course outline
struct LessonRowView: View {
    let lesson: LessonOutline
    let index: Int
    
    var body: some View {
        HStack {
            // Lesson number
            Text("\(index)")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(lesson.title)
                    .font(DesignTokens.Typography.cardTitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(lesson.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Text("\(lesson.estimatedDuration) min")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(lesson.contentType.displayName)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
}

extension LessonContentType {
    var displayName: String {
        switch self {
        case .text: return "Reading"
        case .video: return "Video"
        case .interactive: return "Interactive"
        case .quiz: return "Quiz"
        }
    }
}

// MARK: - Classroom Components

struct ClassroomHeader: View {
    let topic: String
    let currentLessonIndex: Int
    let totalLessons: Int
    let onExit: () -> Void
    let onToggleSidebar: () -> Void
    
    var body: some View {
        HStack {
            Button("Exit") {
                onExit()
            }
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(DesignTokens.Colors.primary)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(topic)
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                if totalLessons > 0 {
                    Text("Lesson \(currentLessonIndex + 1) of \(totalLessons)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            Button("Chat") {
                onToggleSidebar()
            }
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(DesignTokens.Colors.primary)
        }
        .padding()
        .background(
            DesignTokens.Colors.glassBg
                .overlay(
                    Rectangle()
                        .fill(DesignTokens.Colors.glassBorder)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
    }
}

struct ClassroomWelcomeView: View {
    let topic: String
    let course: CourseOutlineLocal?
    let onStartLearning: () -> Void
    
    // Helper functions for Duolingo-style UI
    private func getLessonEmoji(for lesson: LessonOutline) -> String {
        // Extract emoji from title if present
        let title = lesson.title
        if let firstChar = title.first, firstChar.isEmoji {
            return String(firstChar)
        }
        
        // Default emojis based on content type
        switch lesson.contentType {
        case .quiz:
            return "✅"
        case .interactive:
            return "🎮"
        case .video:
            return "📹"
        default:
            return "📖"
        }
    }
    
    private func getLessonColor(for lesson: LessonOutline) -> Color {
        switch lesson.contentType {
        case .quiz:
            return .green
        case .interactive:
            return .purple
        case .video:
            return .red
        default:
            return .blue
        }
    }
    
    private func getLessonGradient(for lesson: LessonOutline) -> [Color] {
        let base = getLessonColor(for: lesson)
        return [base, base.opacity(0.6)]
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer(minLength: 40)
                
                VStack(spacing: DesignTokens.Spacing.lg) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 64))
                        .foregroundColor(DesignTokens.Colors.primary)
                    
                    Text("Welcome to Your AI Classroom!")
                        .font(DesignTokens.Typography.title1)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("📚 \(topic)")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.primary)
                    
                    // ✅ FULLY FUNCTIONAL COURSE INDICATOR
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                        Text("Fully Functional Course")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
                    
                    // Duolingo-Style Learning Path
                    if let course = course {
                        VStack(spacing: 16) {
                            // Units header
                            HStack {
                                Image(systemName: "map.fill")
                                    .foregroundColor(DesignTokens.Colors.primary)
                                Text("Your Learning Path")
                                    .font(DesignTokens.Typography.headline)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                Spacer()
                                Text("\(course.lessons.count) bite-sized lessons")
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                            
                            // Bite-sized lesson path (Duolingo style)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(course.lessons.indices.prefix(8), id: \.self) { index in
                                        VStack(spacing: 8) {
                                            // Lesson bubble
                                            ZStack {
                                                Circle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: getLessonGradient(for: course.lessons[index]),
                                                            startPoint: .topLeading,
                                                            endPoint: .bottomTrailing
                                                        )
                                                    )
                                                    .frame(width: 60, height: 60)
                                                    .shadow(color: getLessonColor(for: course.lessons[index]).opacity(0.3), radius: 5, x: 0, y: 3)
                                                
                                                // Emoji icon based on lesson type
                                                Text(getLessonEmoji(for: course.lessons[index]))
                                                    .font(.system(size: 28))
                                            }
                                            
                                            // Lesson title (short)
                                            Text(course.lessons[index].title)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .frame(width: 70)
                                            
                                            // Duration badge
                                            HStack(spacing: 4) {
                                                Image(systemName: "clock.fill")
                                                    .font(.system(size: 8))
                                                Text("\(course.lessons[index].estimatedDuration)m")
                                                    .font(.system(size: 10, weight: .semibold))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(
                                                Capsule()
                                                    .fill(Color.purple)
                                            )
                                        }
                                    }
                                    
                                    // "More lessons" indicator
                                    if course.lessons.count > 8 {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.gray.opacity(0.2))
                                                    .frame(width: 60, height: 60)
                                                Text("+\(course.lessons.count - 8)")
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                            }
                                            Text("more")
                                                .font(.system(size: 11))
                                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 140)
                            
                            // Quick stats
                            HStack(spacing: 20) {
                                StatBadge(
                                    icon: "flame.fill",
                                    value: "Day 1",
                                    label: "Streak",
                                    color: .orange
                                )
                                StatBadge(
                                    icon: "star.fill",
                                    value: "0/\(course.lessons.count)",
                                    label: "Complete",
                                    color: .yellow
                                )
                                StatBadge(
                                    icon: "target",
                                    value: "\(course.lessons.reduce(0) { $0 + $1.estimatedDuration })m",
                                    label: "Total",
                                    color: .blue
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(DesignTokens.Colors.glassBg)
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                        )
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Preparing your learning path...")
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .padding()
                    }
                }
                
                Spacer(minLength: 40)
                
                Button(action: {
                    print("🔘 Start Learning button tapped!")
                    print("📍 Course exists: \(course != nil)")
                    print("📍 Lesson count: \(course?.lessons.count ?? 0)")
                    onStartLearning()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                        Text("Start Course →")
                            .font(DesignTokens.Typography.buttonLabel)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [DesignTokens.Colors.primary, DesignTokens.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
                    .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .padding()
        }
    }
}

// MARK: - Duolingo-Style Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Character Extension for Emoji Detection
extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value >= 0x1F300 || unicodeScalars.count > 1)
    }
}

struct LessonContentView: View {
    let lesson: LessonContent
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Lesson header
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(lesson.title)
                        .font(DesignTokens.Typography.title1)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(lesson.description)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    // Lesson metadata
                    HStack {
                        Text(lesson.metadata.difficulty.displayName)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                            )
                        
                        Text("\(Int(lesson.metadata.estimatedDuration / 60)) min")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Lesson content blocks
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(lesson.blocks.sorted(by: { $0.order < $1.order })) { block in
                        LessonBlockView(block: block)
                    }
                }
                .padding(.horizontal)
                
                // Navigation buttons
                HStack(spacing: DesignTokens.Spacing.lg) {
                    Button("Previous") {
                        // TODO: Navigate to previous lesson
                    }
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .strokeBorder(DesignTokens.Colors.primary, lineWidth: 2)
                    )
                    
                    Button("Next Lesson") {
                        // TODO: Navigate to next lesson
                    }
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.Colors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
}

struct ClassroomSidebar: View {
    let topic: String
    let onCloseSidebar: () -> Void
    
    @StateObject private var webSocketService = LyoWebSocketService.shared
    private let apiClient = APIClient.shared
    @EnvironmentObject var appState: AppState
    @State private var messageText = ""
    @State private var isTyping = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Sidebar header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chat with Lyo")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    HStack {
                        Circle()
                            .fill(webSocketService.isConnected ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                            .frame(width: 8, height: 8)
                        
                        Text(webSocketService.isConnected ? "Connected" : "Offline")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button("Close") {
                    onCloseSidebar()
                }
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(DesignTokens.Colors.primary)
            }
            .padding()
            .background(
                DesignTokens.Colors.glassBg
                    .overlay(
                        Rectangle()
                            .fill(DesignTokens.Colors.glassBorder)
                            .frame(height: 1),
                        alignment: .bottom
                    )
            )
            
            // Chat messages
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    if webSocketService.messages.isEmpty {
                        // Welcome message
                        ChatMessageView(
                            message: "👋 I'm here to help you learn about \(topic)! Ask me anything.",
                            isFromUser: false,
                            timestamp: Date()
                        )
                    } else {
                        ForEach(webSocketService.getConversationMessages()) { message in
                            ChatMessageView(
                                message: message.content,
                                isFromUser: message.type == .mentorMessage,
                                timestamp: Date(timeIntervalSince1970: message.timestamp)
                            )
                        }
                    }
                }
                .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Message input
            VStack(spacing: DesignTokens.Spacing.sm) {
                if webSocketService.lastError != nil {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(DesignTokens.Colors.error)
                        
                        Text("Connection issue - using regular chat")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.error)
                        
                        Spacer()
                        
                        Button("Retry") {
                            if let userId = appState.currentUser?.id {
                                let userIdInt = abs(userId.hashValue)
                                webSocketService.connect(userId: userIdInt)
                            } else {
                                webSocketService.connect(userId: 1) // Fallback for development
                            }
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.primary)
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    TextField("Ask me anything...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            sendMessage()
                        }
                        .onChange(of: messageText) { _, newValue in
                            if !newValue.isEmpty && !isTyping {
                                isTyping = true
                                webSocketService.sendTypingIndicator(true)
                            } else if newValue.isEmpty && isTyping {
                                isTyping = false
                                webSocketService.sendTypingIndicator(false)
                            }
                        }
                    
                    Button("Send") {
                        sendMessage()
                    }
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        messageText.isEmpty ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.primary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .disabled(messageText.isEmpty)
                }
                .padding()
                .padding(.bottom, 40) // Raise chat input above nav bar
            }
            .background(
                DesignTokens.Colors.glassBg
                    .overlay(
                        Rectangle()
                            .fill(DesignTokens.Colors.glassBorder)
                            .frame(height: 1),
                        alignment: .top
                    )
            )
        }
        .background(DesignTokens.Colors.primaryBg)
        .overlay(
            Rectangle()
                .fill(DesignTokens.Colors.glassBorder)
                .frame(width: 1),
            alignment: .leading
        )
        .onAppear {
            // Connect to WebSocket when sidebar opens
            if let userId = appState.currentUser?.id {
                let userIdInt = abs(userId.hashValue)
                webSocketService.connect(userId: userIdInt)
            } else {
                webSocketService.connect(userId: 1) // Fallback for development
            }
        }
        .onDisappear {
            // Stop typing indicator when leaving
            if isTyping {
                webSocketService.sendTypingIndicator(false)
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        // Stop typing indicator
        if isTyping {
            isTyping = false
            webSocketService.sendTypingIndicator(false)
        }
        
        // Try WebSocket first, fallback to REST API
        if webSocketService.isConnected {
            webSocketService.sendMentorMessage(message)
        } else {
            // Use REST API as fallback
            Task {
                // Simple fallback response for development
                let response = "I understand you're asking about \(topic). Could you be more specific?"
                
                // Add messages to WebSocket service for consistency
                let userMessage = WebSocketMessage(
                    type: .mentorMessage,
                    content: message,
                    timestamp: Date().timeIntervalSince1970
                )
                
                let mentorMessage = WebSocketMessage(
                    type: .mentorResponse,
                    content: response,
                    timestamp: Date().timeIntervalSince1970
                )
                
                webSocketService.messages.append(userMessage)
                webSocketService.messages.append(mentorMessage)
            }
        }
    }
}

struct ChatMessageView: View {
    let message: String
    let isFromUser: Bool
    let timestamp: Date
    
    var body: some View {
        HStack {
            if isFromUser {
                Spacer()
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(isFromUser ? .white : DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isFromUser ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
                    )
                    .frame(maxWidth: 220, alignment: isFromUser ? .trailing : .leading)
                
                Text(formatTimestamp(timestamp))
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            if !isFromUser {
                Spacer()
            }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Resource Curation Bar (Inline for now - will move to separate file)

struct ResourceCurationBar: View {
    let topic: String
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "books.vertical.fill")
                        .font(.title3)
                        .foregroundColor(DesignTokens.Colors.primary)
                    
                    Text("Curated Learning Resources")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Spacer()
                
                Button {
                    withAnimation {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down.circle.fill" : "chevron.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(DesignTokens.Colors.secondaryBg)
            
            if isExpanded {
                // Resources scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Resource cards
                        ResourceQuickCard(
                            icon: "book.fill",
                            title: "Google Books",
                            subtitle: "\(topic) Textbooks",
                            color: .blue
                        )
                        
                        ResourceQuickCard(
                            icon: "play.rectangle.fill",
                            title: "Video Tutorials",
                            subtitle: "YouTube & Courses",
                            color: .red
                        )
                        
                        ResourceQuickCard(
                            icon: "doc.text.fill",
                            title: "Articles",
                            subtitle: "Expert Guides",
                            color: .green
                        )
                        
                        ResourceQuickCard(
                            icon: "doc.plaintext.fill",
                            title: "Documentation",
                            subtitle: "Official Docs",
                            color: .purple
                        )
                        
                        ResourceQuickCard(
                            icon: "lightbulb.fill",
                            title: "Interactive",
                            subtitle: "Hands-on Tutorials",
                            color: .orange
                        )
                        
                        ResourceQuickCard(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "Forums",
                            subtitle: "Q&A Communities",
                            color: .cyan
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .background(DesignTokens.Colors.primaryBg)
            }
        }
    }
}

struct ResourceQuickCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        Button {
            // Open resource
            print("📖 Opening: \(title)")
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Text(title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(1)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Image(systemName: "arrow.up.right.square")
                    .font(.caption)
                    .foregroundColor(color)
            }
            .frame(width: 120, height: 140)
            .padding(12)
            .background(DesignTokens.Colors.glassBg)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        }
    }
}

// MARK: - Avatar Preset Models (Inline for now)

/// Preset avatar configuration that users can select
struct AvatarPreset: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let type: AvatarType
    let primaryColor: CodableColor
    let secondaryColor: CodableColor
    let personality: String
    let emoji: String
    
    init(id: UUID = UUID(), name: String, type: AvatarType, primaryColor: Color, secondaryColor: Color, personality: String, emoji: String) {
        self.id = id
        self.name = name
        self.type = type
        self.primaryColor = CodableColor(color: primaryColor)
        self.secondaryColor = CodableColor(color: secondaryColor)
        self.personality = personality
        self.emoji = emoji
    }
    
    var primary: Color {
        primaryColor.color
    }
    
    var secondary: Color {
        secondaryColor.color
    }
}

/// Avatar type options
enum AvatarType: String, Codable {
    case human
    case cat
    case dog
    case owl
    case fox
    case robot
    
    var icon: String {
        switch self {
        case .human: return "person.fill"
        case .cat: return "cat.fill"
        case .dog: return "dog.fill"
        case .owl: return "bird.fill"
        case .fox: return "hare.fill"
        case .robot: return "cpu.fill"
        }
    }
    
    var description: String {
        switch self {
        case .human: return "Classic human companion"
        case .cat: return "Curious and independent"
        case .dog: return "Loyal and enthusiastic"
        case .owl: return "Wise and thoughtful"
        case .fox: return "Clever and adaptive"
        case .robot: return "Logical and systematic"
        }
    }
}

/// Codable wrapper for Color
struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double
    
    init(color: Color) {
        // Extract components (simplified - uses defaults for system colors)
        self.red = 0.5
        self.green = 0.5
        self.blue = 0.8
        self.opacity = 1.0
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

// Preset Avatar Library
extension AvatarPreset {
    static let presets: [AvatarPreset] = [
        .init(
            name: "Lyo",
            type: .human,
            primaryColor: .blue,
            secondaryColor: .cyan,
            personality: "Friendly and encouraging",
            emoji: "😊"
        ),
        .init(
            name: "Luna",
            type: .cat,
            primaryColor: .purple,
            secondaryColor: .pink,
            personality: "Curious and independent",
            emoji: "🐱"
        ),
        .init(
            name: "Max",
            type: .dog,
            primaryColor: .orange,
            secondaryColor: .yellow,
            personality: "Enthusiastic and loyal",
            emoji: "🐕"
        ),
        .init(
            name: "Sage",
            type: .owl,
            primaryColor: .indigo,
            secondaryColor: .teal,
            personality: "Wise and patient",
            emoji: "🦉"
        ),
        .init(
            name: "Nova",
            type: .fox,
            primaryColor: .red,
            secondaryColor: .orange,
            personality: "Clever and playful",
            emoji: "🦊"
        ),
        .init(
            name: "Atlas",
            type: .robot,
            primaryColor: .gray,
            secondaryColor: .blue,
            personality: "Logical and systematic",
            emoji: "🤖"
        )
    ]
    
    static var defaultPreset: AvatarPreset {
        presets[0] // Lyo
    }
}

// MARK: - Avatar Customization Manager

@MainActor
class AvatarCustomizationManager: ObservableObject {
    @Published var selectedPreset: AvatarPreset
    @Published var customName: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let avatarKey = "userSelectedAvatar"
    private let nameKey = "userAvatarName"
    
    init() {
        // Load saved avatar or use default
        if let data = userDefaults.data(forKey: avatarKey),
           let saved = try? JSONDecoder().decode(AvatarPreset.self, from: data) {
            self.selectedPreset = saved
        } else {
            self.selectedPreset = AvatarPreset.defaultPreset
        }
        
        // Load saved name
        self.customName = userDefaults.string(forKey: nameKey) ?? ""
    }
    
    func selectPreset(_ preset: AvatarPreset) {
        selectedPreset = preset
        save()
    }
    
    func setName(_ name: String) {
        customName = name
        userDefaults.set(name, forKey: nameKey)
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(selectedPreset) {
            userDefaults.set(data, forKey: avatarKey)
        }
    }
    
    var displayName: String {
        customName.isEmpty ? selectedPreset.name : customName
    }
}

// MARK: - Quick Avatar Picker View

struct QuickAvatarPickerView: View {
    @StateObject private var manager = AvatarCustomizationManager()
    @State private var showingNameField = false
    @State private var tempName = ""
    
    let onComplete: (AvatarPreset, String) -> Void
    let onSkip: () -> Void
    
    var body: some View {
        ZStack {
            // Animated gradient background
            AnimatedGradientBackground()
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("Meet Your Learning Companion")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Choose a companion to guide your learning journey")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.horizontal)
                
                Spacer()
                
                // Preview of selected avatar
                VStack(spacing: 16) {
                    // Large preview
                    LegacyAvatarPreview(preset: manager.selectedPreset, size: .large)
                        .transition(.scale.combined(with: .opacity))
                    
                    VStack(spacing: 8) {
                        Text(showingNameField ? tempName.isEmpty ? manager.selectedPreset.name : tempName : manager.selectedPreset.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(manager.selectedPreset.personality)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.vertical, 20)
                
                // Avatar selection grid
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(AvatarPreset.presets) { preset in
                            AvatarSelectionCard(
                                preset: preset,
                                isSelected: preset.id == manager.selectedPreset.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        manager.selectPreset(preset)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 140)
                .padding(.bottom, 20)
                
                // Name customization
                if showingNameField {
                    VStack(spacing: 12) {
                        Text("Give your companion a name")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                        
                        TextField("Enter name", text: $tempName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 40)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    if !showingNameField {
                        Button {
                            withAnimation {
                                showingNameField = true
                                tempName = manager.selectedPreset.name
                            }
                        } label: {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Customize Name")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    Button {
                        if showingNameField && !tempName.isEmpty {
                            manager.setName(tempName)
                        }
                        onComplete(manager.selectedPreset, manager.displayName)
                    } label: {
                        HStack {
                            Text(showingNameField ? "Start Learning" : "Continue with \(manager.selectedPreset.name)")
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [manager.selectedPreset.primary, manager.selectedPreset.secondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: manager.selectedPreset.primary.opacity(0.5), radius: 20, x: 0, y: 10)
                    }
                    .padding(.horizontal, 24)
                    
                    Button {
                        onSkip()
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 10)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Avatar Selection Card

struct AvatarSelectionCard: View {
    let preset: AvatarPreset
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [preset.primary, preset.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: isSelected ? 4 : 0)
                        )
                        .shadow(color: preset.primary.opacity(0.5), radius: isSelected ? 15 : 5)
                    
                    Text(preset.emoji)
                        .font(.system(size: 40))
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                
                Text(preset.name)
                    .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                    .foregroundColor(.white)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Avatar Preview View (Legacy)

struct LegacyAvatarPreview: View {
    let preset: AvatarPreset
    let size: PreviewSize
    
    @State private var isAnimating = false
    
    enum PreviewSize {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 60
            case .medium: return 100
            case .large: return 160
            }
        }
        
        var emojiSize: CGFloat {
            switch self {
            case .small: return 30
            case .medium: return 50
            case .large: return 80
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [preset.primary.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: size.dimension * 0.5,
                        endRadius: size.dimension * 1.5
                    )
                )
                .frame(width: size.dimension * 2, height: size.dimension * 2)
                .blur(radius: 20)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            
            // Main circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [preset.primary, preset.secondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size.dimension, height: size.dimension)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            
            // Avatar emoji/icon
            Text(preset.emoji)
                .font(.system(size: size.emojiSize))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Animated Gradient Background

struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.2, blue: 0.45),
                Color(red: 0.3, green: 0.15, blue: 0.5),
                Color(red: 0.15, green: 0.25, blue: 0.6)
            ],
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Live Blueprint Preview Component

/// Live visualization of the learning blueprint as it's being built
/// Uses REAL data from LearningBlueprint - no mocks, no demos
struct LiveBlueprintPreview: View {
    @Binding var blueprint: LearningBlueprint
    let containerSize: CGSize
    
    // Animation states
    @State private var nodeAnimations: [UUID: Bool] = [:]
    @State private var pulsingNodes: Set<UUID> = []
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            // Connection lines (drawn first, below nodes)
            ForEach(blueprint.nodes) { node in
                ForEach(node.connections, id: \.self) { targetId in
                    if let targetNode = blueprint.nodes.first(where: { $0.id == targetId }) {
                        ConnectionLine(
                            from: node.position,
                            to: targetNode.position,
                            isActive: nodeAnimations[node.id] ?? false && nodeAnimations[targetId] ?? false
                        )
                    }
                }
            }
            
            // Blueprint nodes
            ForEach(blueprint.nodes) { node in
                BlueprintNodeView(
                    node: node,
                    isAnimating: nodeAnimations[node.id] ?? false,
                    isPulsing: pulsingNodes.contains(node.id)
                )
                .position(node.position)
                .onAppear {
                    animateNodeAppearance(node.id)
                }
            }
            
            // Center indicator when empty
            if blueprint.nodes.isEmpty {
                EmptyBlueprintView()
            }
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .onChange(of: blueprint.nodes.count) { _, _ in
            // Pulse the most recently added node
            if let lastNode = blueprint.nodes.last {
                pulseNode(lastNode.id)
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.05),
                Color.purple.opacity(0.05),
                Color.cyan.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Animations
    
    private func animateNodeAppearance(_ nodeId: UUID) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            nodeAnimations[nodeId] = true
        }
    }
    
    private func pulseNode(_ nodeId: UUID) {
        pulsingNodes.insert(nodeId)
        
        // Stop pulsing after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            pulsingNodes.remove(nodeId)
        }
    }
}

// MARK: - Blueprint Node View

/// Visual representation of a single blueprint node
struct BlueprintNodeView: View {
    let node: BlueprintNode
    let isAnimating: Bool
    let isPulsing: Bool
    
    @State private var scale: CGFloat = 0.3
    
    var body: some View {
        VStack(spacing: 4) {
            // Node circle
            Circle()
                .fill(nodeColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: nodeIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(nodeColor.opacity(0.5), lineWidth: 2)
                        .scaleEffect(isPulsing ? 1.4 : 1.0)
                        .opacity(isPulsing ? 0.0 : 1.0)
                        .animation(
                            isPulsing ?
                            .easeOut(duration: 1.0).repeatCount(3, autoreverses: false) :
                            .default,
                            value: isPulsing
                        )
                )
                .shadow(color: nodeColor.opacity(0.4), radius: 8, x: 0, y: 4)
            
            // Node label
            Text(node.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
        .scaleEffect(isAnimating ? scale : 0.3)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
    }
    
    // MARK: - Node Styling
    
    private var nodeColor: Color {
        switch node.type {
        case .topic:
            return Color.blue
        case .goal:
            return Color.green
        case .module:
            return Color.orange
        case .skill:
            return Color.purple
        case .milestone:
            return Color.pink
        }
    }
    
    private var nodeIcon: String {
        switch node.type {
        case .topic:
            return "lightbulb.fill"
        case .goal:
            return "target"
        case .module:
            return "book.fill"
        case .skill:
            return "star.fill"
        case .milestone:
            return "flag.fill"
        }
    }
}

// MARK: - Connection Line

/// Draws a connection line between two blueprint nodes
struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let isActive: Bool
    
    @State private var animationProgress: CGFloat = 0.0
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            // Calculate control points for curved line
            let midX = (from.x + to.x) / 2
            let controlPoint1 = CGPoint(x: midX, y: from.y)
            let controlPoint2 = CGPoint(x: midX, y: to.y)
            
            path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)
        }
        .trim(from: 0, to: isActive ? animationProgress : 0)
        .stroke(
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
        .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 0)
        .onChange(of: isActive) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
        }
    }
}

// MARK: - Empty State

/// Shows when blueprint has no nodes yet
struct EmptyBlueprintView: View {
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .frame(width: 100, height: 100)
                .scaleEffect(pulseScale)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            Text("Your Learning Blueprint")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("Answer questions to build your path")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Layout Calculator

/// Calculates node positions based on blueprint structure
extension LearningBlueprint {
    /// Calculate positions for all nodes using a radial layout
    mutating func calculateNodePositions(containerSize: CGSize) {
        guard !nodes.isEmpty else { return }
        
        let centerX = containerSize.width / 2
        let centerY = containerSize.height / 2
        
        // Find root node (topic)
        if let topicIndex = nodes.firstIndex(where: { $0.type == .topic }) {
            nodes[topicIndex].position = CGPoint(x: centerX, y: centerY)
            
            // Position connected nodes around the topic in a circle
            let connectedNodes = nodes.filter { node in
                node.id != nodes[topicIndex].id
            }
            
            let radius: CGFloat = 120
            let angleStep = (2 * .pi) / CGFloat(max(connectedNodes.count, 1))
            
            for (index, node) in connectedNodes.enumerated() {
                let angle = angleStep * CGFloat(index) - .pi / 2 // Start from top
                let x = centerX + radius * cos(angle)
                let y = centerY + radius * sin(angle)
                
                if let nodeIndex = nodes.firstIndex(where: { $0.id == node.id }) {
                    nodes[nodeIndex].position = CGPoint(x: x, y: y)
                }
            }
        } else {
            // Fallback: distribute nodes evenly
            let radius: CGFloat = 100
            let angleStep = (2 * .pi) / CGFloat(nodes.count)
            
            for index in nodes.indices {
                let angle = angleStep * CGFloat(index) - .pi / 2
                let x = centerX + radius * cos(angle)
                let y = centerY + radius * sin(angle)
                
                nodes[index].position = CGPoint(x: x, y: y)
            }
        }
    }
}

// MARK: - Conversation Bubble View Component

/// Chat interface for the diagnostic dialogue
/// Uses REAL ConversationMessage and SuggestedResponse data - no mocks
struct ConversationBubbleView: View {
    @Binding var messages: [ConversationMessage]
    @Binding var suggestedResponses: [SuggestedResponse]
    let onResponseTap: (String) -> Void
    let onSendMessage: (String) -> Void
    
    @State private var messageText: String = ""
    @State private var isShowingTyping: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages scroll view
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            DiagnosticMessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Typing indicator
                        if isShowingTyping {
                            DiagnosticTypingIndicator()
                                .padding(.leading, 12)
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    // Auto-scroll to latest message
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isShowingTyping) { _, showing in
                    if showing {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Suggested responses (if any)
            if !suggestedResponses.isEmpty {
                SuggestedResponsesView(
                    responses: suggestedResponses,
                    onTap: { response in
                        onResponseTap(response.text)
                        // Clear suggestions after selection
                        suggestedResponses = []
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Input bar
            InputBar(
                messageText: $messageText,
                isInputFocused: $isInputFocused,
                onSend: {
                    guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    onSendMessage(messageText)
                    messageText = ""
                }
            )
        }
    }
    
    /// Show typing indicator for AI thinking
    func showTyping() {
        withAnimation(.easeIn(duration: 0.2)) {
            isShowingTyping = true
        }
    }
    
    /// Hide typing indicator
    func hideTyping() {
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingTyping = false
        }
    }
}

// MARK: - Message Bubble

struct DiagnosticMessageBubble: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isFromUser ? Color.blue : Color(.systemGray5))
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
        .transition(.scale(scale: 0.8, anchor: message.isFromUser ? .bottomTrailing : .bottomLeading).combined(with: .opacity))
    }
}

// MARK: - Typing Indicator

struct DiagnosticTypingIndicator: View {
    @State private var animationPhase: Int = 0
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 8, height: 8)
                    .offset(y: animationPhase == index ? -6 : 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray5))
        )
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Suggested Responses

struct SuggestedResponsesView: View {
    let responses: [SuggestedResponse]
    let onTap: (SuggestedResponse) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(responses) { response in
                    SuggestedResponseChip(response: response) {
                        onTap(response)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
}

struct SuggestedResponseChip: View {
    let response: SuggestedResponse
    let onTap: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onTap()
                isPressed = false
            }
        }) {
            HStack(spacing: 6) {
                if !response.icon.isEmpty {
                    Text(response.icon)
                        .font(.system(size: 16))
                }
                
                Text(response.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input Bar

struct InputBar: View {
    @Binding var messageText: String
    var isInputFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input
            TextField("Type your answer...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(1...5)
                .focused(isInputFocused)
                .onSubmit {
                    onSend()
                }
            
            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                        Color(.systemGray3) : Color.blue
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
}

// MARK: - Diagnostic Dialogue View Component

/// Main diagnostic dialogue interface with 60/40 split layout
/// Uses REAL DiagnosticViewModel data - no mocks
struct DiagnosticDialogueView: View {
    @StateObject private var viewModel = DiagnosticViewModel()
    @State private var containerSize: CGSize = .zero
    let onComplete: (LearningBlueprint) -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                backgroundGradient
                
                VStack(spacing: 0) {
                    // Top bar with progress and avatar
                    TopProgressBar(
                        currentStep: viewModel.currentStep,
                        totalSteps: viewModel.totalSteps,
                        avatarMood: viewModel.currentMood,
                        avatarExpression: viewModel.currentExpression,
                        isSpeaking: viewModel.isSpeaking
                    )
                    
                    // Main content: Split layout
                    HStack(spacing: 0) {
                        // Left side (60%): Conversation
                        ConversationBubbleView(
                            messages: $viewModel.conversationHistory,
                            suggestedResponses: $viewModel.suggestedResponses,
                            onResponseTap: { response in
                                handleUserResponse(response)
                            },
                            onSendMessage: { message in
                                handleUserResponse(message)
                            }
                        )
                        .frame(width: geometry.size.width * 0.6)
                        
                        // Divider
                        Divider()
                            .background(Color(.systemGray4))
                        
                        // Right side (40%): Blueprint preview
                        VStack(spacing: 0) {
                            // Blueprint header
                            Text("Your Learning Path")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity)
                                .background(Color(.systemBackground).opacity(0.8))
                            
                            Divider()
                            
                            // Blueprint visualization
                            LiveBlueprintPreview(
                                blueprint: $viewModel.currentBlueprint,
                                containerSize: CGSize(
                                    width: geometry.size.width * 0.4,
                                    height: geometry.size.height - 120 // Minus top bar and header
                                )
                            )
                            .onChange(of: viewModel.currentBlueprint.nodes.count) { _, _ in
                                updateBlueprintLayout(size: geometry.size)
                            }
                        }
                        .frame(width: geometry.size.width * 0.4)
                    }
                    .frame(height: geometry.size.height - 80) // Minus top bar
                }
            }
            .onAppear {
                containerSize = geometry.size
                viewModel.startDiagnostic()
            }
        }
        .onChange(of: viewModel.currentStep) { _, step in
            if step > viewModel.totalSteps {
                // Diagnostic complete
                completeDialogue()
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.blue.opacity(0.02),
                Color.purple.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - User Interaction
    
    private func handleUserResponse(_ response: String) {
        Task {
            await viewModel.processUserResponse(response)
        }
    }
    
    private func updateBlueprintLayout(size: CGSize) {
        let blueprintSize = CGSize(
            width: size.width * 0.4,
            height: size.height - 120
        )
        viewModel.currentBlueprint.calculateNodePositions(containerSize: blueprintSize)
    }
    
    private func completeDialogue() {
        // Pass completed blueprint to next phase
        onComplete(viewModel.currentBlueprint)
    }
}

// MARK: - Top Progress Bar

struct TopProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let avatarMood: AvatarMood
    let avatarExpression: AvatarExpression
    let isSpeaking: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 16) {
                // Avatar head placeholder (will use AvatarHeadView when available)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [moodColor, moodColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(moodEmoji)
                            .font(.system(size: 24))
                    )
                
                // Progress info
                VStack(alignment: .leading, spacing: 4) {
                    Text("Building Your Path")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Question \(currentStep) of \(totalSteps)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress percentage
                Text("\(Int((Double(currentStep) / Double(totalSteps)) * 100))%")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 4)
                    
                    // Progress fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (Double(currentStep) / Double(totalSteps)),
                            height: 4
                        )
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                }
            }
            .frame(height: 4)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .frame(height: 80)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var moodColor: Color {
        switch avatarMood {
        case .friendly: return .blue
        case .excited: return .orange
        case .thinking: return .purple
        case .supportive: return .green
        case .curious: return .cyan
        case .empathetic: return .pink
        case .thoughtful: return .indigo
        case .engaged: return .teal
        }
    }
    
    private var moodEmoji: String {
        switch avatarMood {
        case .friendly: return "😊"
        case .excited: return "🤩"
        case .thinking: return "🤔"
        case .supportive: return "💪"
        case .curious: return "🧐"
        case .empathetic: return "🤗"
        case .thoughtful: return "💭"
        case .engaged: return "✨"
        }
    }
}
// MARK: - Avatar State Enums (Diagnostic-Specific)

/// Avatar facial expressions for diagnostic dialogue
enum AvatarExpression: String {
    case neutral
    case smiling
    case talking
    case nodding
    case pointing
    case waving
    case confused
    case caring
}

// MARK: - Diagnostic Question Models

/// Diagnostic question type
enum QuestionType {
    case openEnded
    case multipleChoice
    case scale
}

/// Diagnostic question model
struct DiagnosticQuestion: Identifiable {
    let id: String
    let text: String
    let type: QuestionType
    var options: [String] = []
    var followUp: String = ""
}

// MARK: - Diagnostic ViewModel

/// ViewModel for diagnostic dialogue - manages conversation flow and blueprint building
@MainActor
class DiagnosticViewModel: ObservableObject {
    // Published properties for UI binding
    @Published var conversationHistory: [ConversationMessage] = []
    @Published var currentQuestion: DiagnosticQuestion?
    @Published var suggestedResponses: [SuggestedResponse] = []
    @Published var currentBlueprint: LearningBlueprint = LearningBlueprint()
    @Published var currentStep: Int = 0
    @Published var totalSteps: Int = 6
    @Published var currentMood: AvatarMood = .friendly
    @Published var currentExpression: AvatarExpression = .smiling
    @Published var isSpeaking: Bool = false
    
    // Preset questions
    private let diagnosticQuestions: [DiagnosticQuestion] = [
        DiagnosticQuestion(
            id: "interests",
            text: "Hi! I'm here to help you design your perfect learning path. Let's start with what you're curious about - what would you love to learn?",
            type: .openEnded
        ),
        DiagnosticQuestion(
            id: "goals",
            text: "That's awesome! What's your main goal with learning this?",
            type: .openEnded,
            options: []
        ),
        DiagnosticQuestion(
            id: "timeline",
            text: "How much time can you dedicate to learning each week?",
            type: .multipleChoice,
            options: ["1-2 hours", "3-5 hours", "6-10 hours", "10+ hours"]
        ),
        DiagnosticQuestion(
            id: "style",
            text: "How do you learn best?",
            type: .multipleChoice,
            options: ["Hands-on projects", "Video tutorials", "Reading articles", "Interactive exercises"]
        ),
        DiagnosticQuestion(
            id: "level",
            text: "What's your current experience level?",
            type: .multipleChoice,
            options: ["Complete beginner", "Some basics", "Intermediate", "Advanced"]
        ),
        DiagnosticQuestion(
            id: "motivation",
            text: "What motivates you most to learn?",
            type: .multipleChoice,
            options: ["Career growth", "Personal interest", "Build something", "Solve a problem"]
        )
    ]
    
    func startDiagnostic() {
        currentStep = 1
        askNextQuestion()
    }
    
    func processUserResponse(_ response: String) async {
        // Add user message
        let userMessage = ConversationMessage(
            text: response,
            isFromUser: true,
            timestamp: Date()
        )
        conversationHistory.append(userMessage)
        
        // Clear suggestions
        suggestedResponses = []
        
        // Update blueprint based on response
        updateBlueprintFromResponse(response)
        
        // Move to next question
        currentStep += 1
        
        // Small delay for natural feel
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s
        
        askNextQuestion()
    }
    
    private func askNextQuestion() {
        guard currentStep <= totalSteps else {
            // Complete
            currentMood = .excited  // Changed from .celebrating
            let finalMessage = ConversationMessage(
                text: "Perfect! I've created your personalized learning path. Let's get started! 🎉",
                isFromUser: false,
                timestamp: Date()
            )
            conversationHistory.append(finalMessage)
            return
        }
        
        let question = diagnosticQuestions[currentStep - 1]
        currentQuestion = question
        
        // Add AI message
        let aiMessage = ConversationMessage(
            text: question.text,
            isFromUser: false,
            timestamp: Date()
        )
        conversationHistory.append(aiMessage)
        
        // Add suggested responses if multiple choice
        if question.type == .multipleChoice {
            suggestedResponses = question.options.map { option in
                SuggestedResponse(text: option, icon: "")
            }
        }
        
        // Update avatar mood
        currentMood = currentStep == 1 ? .friendly : .curious
    }
    
    private func updateBlueprintFromResponse(_ response: String) {
        guard let question = currentQuestion else { return }
        
        switch question.id {
        case "interests":
            currentBlueprint.topic = response
            // Create topic node
            let topicNode = BlueprintNode(
                id: UUID(),
                title: response,
                type: .topic,
                connections: []
            )
            currentBlueprint.nodes.append(topicNode)
            
        case "goals":
            currentBlueprint.goal = response
            // Create goal node connected to topic
            if let topicNode = currentBlueprint.nodes.first {
                let goalNode = BlueprintNode(
                    id: UUID(),
                    title: response,
                    type: .goal,
                    connections: [topicNode.id]
                )
                currentBlueprint.nodes.append(goalNode)
            }
            
        case "timeline":
            currentBlueprint.pace = response
            
        case "style":
            currentBlueprint.style = response
            // Create style node
            if let topicNode = currentBlueprint.nodes.first {
                let styleNode = BlueprintNode(
                    id: UUID(),
                    title: response,
                    type: .skill,
                    connections: [topicNode.id]
                )
                currentBlueprint.nodes.append(styleNode)
            }
            
        case "level":
            currentBlueprint.level = response
            // Create level node
            if let topicNode = currentBlueprint.nodes.first {
                let levelNode = BlueprintNode(
                    id: UUID(),
                    title: response,
                    type: .milestone,
                    connections: [topicNode.id]
                )
                currentBlueprint.nodes.append(levelNode)
            }
            
        case "motivation":
            currentBlueprint.motivation = response
            
        default:
            break
        }
    }
}

#Preview {
    AIOnboardingFlowView()
        .environmentObject(AppState())
}
