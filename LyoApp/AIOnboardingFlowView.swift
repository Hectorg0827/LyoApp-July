import SwiftUI

/// AI Flow states for the onboarding process
enum AIFlowState {
    case gatheringTopic
    case generatingCourse
    case classroomActive
}

/// Main view that manages the AI onboarding flow from topic gathering to classroom
struct AIOnboardingFlowView: View {
    @State private var currentState: AIFlowState = .gatheringTopic
    @State private var detectedTopic: String = ""
    @State private var generatedCourse: CourseOutline?
    @State private var isGenerating = false
    @State private var generationError: String?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                DesignTokens.Colors.primaryBg.ignoresSafeArea()
                
                // State-based content
                switch currentState {
                case .gatheringTopic:
                    TopicGatheringView(
                        onTopicDetected: { topic in
                            detectedTopic = topic
                            transitionToGeneratingCourse()
                        },
                        onCancel: {
                            dismiss()
                        }
                    )
                    
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
                        generateCourse: generateCourse,
                        generateMockCourse: generateMockCourse
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
        withAnimation(.easeInOut(duration: 0.3)) {
            currentState = .classroomActive
        }
    }
    
    private func generateCourse() {
        isGenerating = true
        generationError = nil
        
        Task {
            do {
                let response = try await LyoAPIService.shared.generateCourseOutline(
                    title: "Understanding \(detectedTopic)",
                    description: "A comprehensive course on \(detectedTopic) tailored to your learning needs",
                    targetAudience: "General learners interested in \(detectedTopic)",
                    learningObjectives: [
                        "Understand the fundamental concepts of \(detectedTopic)",
                        "Apply key principles in practical scenarios",
                        "Identify real-world applications and use cases"
                    ],
                    difficultyLevel: "beginner",
                    estimatedDurationHours: 2
                )
                
                if let courseOutline = LyoAPIService.shared.convertToCourseOutline(from: response) {
                    generatedCourse = courseOutline
                    isGenerating = false
                    transitionToClassroom()
                } else {
                    throw APIError.decodingError("Failed to decode response")
                }
                
            } catch {
                generationError = error.localizedDescription
                isGenerating = false
                
                // Fallback to mock data if API fails
                print("⚠️ API failed, using mock data: \(error)")
                generateMockCourse()
            }
        }
    }
    
    private func generateMockCourse() {
        // Fallback mock course generation
        let mockCourse = CourseOutline(
            title: "Understanding \(detectedTopic)",
            description: "A comprehensive course on \(detectedTopic)",
            lessons: [
                LessonOutline(
                    title: "Introduction to \(detectedTopic)",
                    description: "Basic concepts and fundamentals",
                    contentType: .text,
                    estimatedDuration: 15
                ),
                LessonOutline(
                    title: "Deep Dive into \(detectedTopic)",
                    description: "Advanced concepts and applications",
                    contentType: .interactive,
                    estimatedDuration: 30
                ),
                LessonOutline(
                    title: "Practical Applications",
                    description: "Real-world examples and exercises",
                    contentType: .video,
                    estimatedDuration: 20
                )
            ]
        )
        
        generatedCourse = mockCourse
        isGenerating = false
        transitionToClassroom()
    }
}

/// View for gathering the learning topic through Socratic dialogue
struct TopicGatheringView: View {
    let onTopicDetected: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Header
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(DesignTokens.Colors.primary)
                
                Text("Hi there! I'm Lyo")
                    .font(DesignTokens.Typography.title1)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Let's discover what you'd like to learn today")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            
            Spacer()
            
            // Use simplified chat component
            SimpleChatView { detectedTopic in
                onTopicDetected(detectedTopic)
            }
            .padding()
            .padding(.bottom, 140) // Maximize bottom padding to clear Lyo button/nav
            
            Spacer()
            
            // Cancel button
            Button("Maybe later") {
                onCancel()
            }
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(DesignTokens.Colors.textSecondary)
            .padding()
        }
        .padding()
    }
}

/// Genesis screen showing course generation process
struct GenesisScreenView: View {
    let topic: String
    @Binding var isGenerating: Bool
    @Binding var error: String?
    let onCourseGenerated: (CourseOutline) -> Void
    let onCancel: () -> Void
    let generateCourse: () -> Void
    let generateMockCourse: () -> Void
    
    @State private var animationStep = 0
    @State private var pulseAnimation = false
    
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
                                
                                Button("Use Mock Data") {
                                    generateMockCourse()
                                }
                                .buttonStyle(.bordered)
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
            
            // Progress indicators
            VStack(spacing: DesignTokens.Spacing.md) {
                HStack {
                    Text("AI Agents at Work")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                }
                
                VStack(spacing: DesignTokens.Spacing.sm) {
                    AgentStatusRow(
                        name: "Curriculum Agent",
                        isActive: animationStep >= 0,
                        isComplete: animationStep >= 3
                    )
                    
                    AgentStatusRow(
                        name: "Content Curation Agent",
                        isActive: animationStep >= 1,
                        isComplete: animationStep >= 3
                    )
                    
                    AgentStatusRow(
                        name: "Personalization Engine",
                        isActive: animationStep >= 2,
                        isComplete: animationStep >= 3
                    )
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

/// Temporary data structures for the course outline
struct CourseOutline {
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
    let course: CourseOutline?
    let onExit: () -> Void
    
    @State private var currentLessonIndex = 0
    @State private var currentLesson: LessonContent?
    @State private var showingSidebar = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Main content area
            VStack(spacing: 0) {
                // Header
                ClassroomHeader(
                    topic: topic,
                    currentLessonIndex: currentLessonIndex,
                    totalLessons: course?.lessons.count ?? 0,
                    onExit: onExit,
                    onToggleSidebar: { showingSidebar.toggle() }
                )
                
                // Lesson content
                if let lesson = currentLesson {
                    LessonContentView(lesson: lesson)
                } else {
                    // Welcome screen
                    ClassroomWelcomeView(
                        topic: topic,
                        course: course,
                        onStartLearning: {
                            loadFirstLesson()
                        }
                    )
                }
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
    
    private func loadFirstLesson() {
        guard let course = course,
              let firstLesson = course.lessons.first else {
            // TODO: Replace with UserDataManager lesson loading
            // currentLesson = UserDataManager.shared.getDefaultLesson()
            currentLesson = nil // No lesson until real data integration
            currentLessonIndex = 0
            return
        }
        
        Task {
            do {
                let response = try await LyoAPIService.shared.generateLessonContent(
                    courseId: "course_\(UUID().uuidString)",
                    lessonTitle: firstLesson.title,
                    lessonDescription: firstLesson.description,
                    learningObjectives: [
                        "Understand the core concepts",
                        "Apply what you've learned",
                        "Identify key principles"
                    ],
                    contentType: firstLesson.contentType.rawValue,
                    difficultyLevel: "beginner"
                )
                
                if let lessonContent = response.content {
                    currentLesson = lessonContent
                    currentLessonIndex = 0
                } else {
                    // TODO: Replace with UserDataManager fallback lesson
                    // currentLesson = UserDataManager.shared.getDefaultLesson()
                    currentLesson = nil // No lesson until real data integration
                    currentLessonIndex = 0
                }
                
            } catch {
                print("⚠️ Failed to load lesson content: \(error)")
                // TODO: Replace with UserDataManager fallback lesson
                // currentLesson = UserDataManager.shared.getDefaultLesson()
                currentLesson = nil // No lesson until real data integration
                currentLessonIndex = 0
            }
        }
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
    let course: CourseOutline?
    let onStartLearning: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            VStack(spacing: DesignTokens.Spacing.lg) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 64))
                    .foregroundColor(DesignTokens.Colors.primary)
                
                Text("Welcome to your AI Classroom!")
                    .font(DesignTokens.Typography.title1)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Topic: \(topic)")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.primary)
                
                if let course = course {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Course Outline:")
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        ForEach(course.lessons.indices, id: \.self) { index in
                            LessonRowView(lesson: course.lessons[index], index: index + 1)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.glassBg)
                    )
                }
            }
            
            Spacer()
            
            Button("Start Learning") {
                onStartLearning()
            }
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(DesignTokens.Colors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
            .padding(.horizontal)
        }
        .padding()
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
    @StateObject private var apiService = LyoAPIService.shared
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
                    .disabled(messageText.isEmpty || apiService.isLoading)
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
                do {
                    let response = try await apiService.sendMessageToMentor(
                        message: message,
                        context: ["topic": topic]
                    )
                    
                    // Add messages to WebSocket service for consistency
                    let userMessage = WebSocketMessage(
                        type: .mentorMessage,
                        content: message,
                        timestamp: Date().timeIntervalSince1970
                    )
                    
                    let mentorMessage = WebSocketMessage(
                        type: .mentorResponse,
                        content: response.response,
                        timestamp: Date().timeIntervalSince1970
                    )
                    
                    webSocketService.messages.append(userMessage)
                    webSocketService.messages.append(mentorMessage)
                    
                } catch {
                    print("❌ Failed to send message: \(error)")
                }
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

#Preview {
    AIOnboardingFlowView()
        .environmentObject(AppState())
}