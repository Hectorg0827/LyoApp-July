import SwiftUI
import Foundation

// MARK: - LearnView: Core Learning Interface

// MARK: - Basic Managers (Temporary)

@MainActor
class CourseManager: ObservableObject {
    @Published var courses: [LyoCourseChapter] = []
    @Published var isLoading = false
    
    var memoryUsage: UInt64 { 0 }
    
    func getCourse(for topic: String) -> [LyoCourseChapter] {
        return generateCourseContent(for: topic)
    }
    
    func preloadContent(for topic: String) async {
        // Simulate loading
        do {
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        } catch {
            // Handle cancellation gracefully
        }
        courses = generateCourseContent(for: topic)
    }
    
    func refreshCourse(for topic: String) {
        isLoading = true
        Task {
            await preloadContent(for: topic)
            isLoading = false
        }
    }
}

@MainActor
class AIChatManager: ObservableObject {
    @Published var messages: [String] = []
    @Published var isLoading = false
}

// MARK: - Main Learn View

struct LearnView: View {
    @StateObject private var courseManager = CourseManager()
    @StateObject private var aiChatManager = AIChatManager()
    @EnvironmentObject var appState: AppState
    @State private var selectedTopic = "Swift Programming"
    @State private var currentChapterIndex = 0
    @State private var showingQuiz = false
    @State private var currentQuestionIndex = 0
    @State private var showingAIChat = false
    @State private var animateEntrance = false
    
    // Analytics tracking
    @State private var courseStartTime: Date?
    
    private var currentCourse: [LyoCourseChapter] {
        courseManager.getCourse(for: selectedTopic)
    }
    
    private var currentChapter: LyoCourseChapter? {
        guard currentChapterIndex < currentCourse.count else { return nil }
        return currentCourse[currentChapterIndex]
    }
    
    private var progress: Double {
        guard !currentCourse.isEmpty else { return 0 }
        return Double(currentChapterIndex) / Double(currentCourse.count)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.Colors.background.ignoresSafeArea()
                
                if appState.isLoading {
                    DesignSystem.LoadingStateView(message: "Loading course content...")
                        .accessibilityIdentifier("course_loading")
                } else if appState.currentError != nil {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Something went wrong")
                            .font(DesignTokens.Typography.title2)
                        
                        Text(appState.currentError?.localizedDescription ?? "Unknown error")
                            .font(DesignTokens.Typography.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        Button("Try Again") {
                            appState.clearError()
                            courseManager.refreshCourse(for: selectedTopic)
                        }
                        .font(DesignTokens.Typography.buttonLabel)
                        .foregroundColor(.white)
                        .padding()
                        .background(DesignTokens.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }
                    .padding()
                    .accessibilityIdentifier("course_error")
                } else {
                    mainContent
                        .opacity(animateEntrance ? 1 : 0)
                        .animation(DesignTokens.Animations.smooth, value: animateEntrance)
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5)) {
                    animateEntrance = true
                }
                
                // Analytics tracking removed - implement when AnalyticsManager is available
                courseStartTime = Date()
                
                // Pre-load course content
                Task {
                    await courseManager.preloadContent(for: selectedTopic)
                }
            }
            .onChange(of: currentChapterIndex) { _, newValue in
                // Analytics tracking removed - implement when AnalyticsManager is available
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("learn_view")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 0) {
            if let chapter = currentChapter {
                if showingQuiz {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text("Quiz Mode")
                            .font(DesignTokens.Typography.title1)
                        
                        Text("Quiz feature coming soon!")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                        
                        Button("Complete Quiz") {
                            withAnimation(DesignTokens.Animations.smooth) {
                                showingQuiz = false
                                currentQuestionIndex = 0
                                
                                // Auto-advance to next chapter after quiz completion
                                if currentChapterIndex < currentCourse.count - 1 {
                                    currentChapterIndex += 1
                                }
                            }
                        }
                        .font(DesignTokens.Typography.buttonLabel)
                        .foregroundColor(.white)
                        .padding()
                        .background(DesignTokens.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }
                    .padding()
                    .accessibilityIdentifier("course_quiz")
                } else if showingAIChat {
                    VStack(spacing: DesignTokens.Spacing.lg) {
                        Text("AI Chat")
                            .font(DesignTokens.Typography.title1)
                        
                        Text("AI Chat feature coming soon!")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.secondary)
                        
                        Button("Close") {
                            withAnimation(DesignTokens.Animations.smooth) {
                                showingAIChat = false
                            }
                        }
                        .font(DesignTokens.Typography.buttonLabel)
                        .foregroundColor(.white)
                        .padding()
                        .background(DesignTokens.Colors.primary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    }
                    .padding()
                    .accessibilityIdentifier("ai_chat")
                } else {
                    mainCourseView(chapter: chapter)
                }
            } else {
                // Course completion or empty state
                CourseCompletionView(
                    topic: selectedTopic,
                    onRestart: {
                        withAnimation(DesignTokens.Animations.smooth) {
                            currentChapterIndex = 0
                        }
                    },
                    onNewTopic: {
                        // Could implement topic selection here
                    }
                )
                .accessibilityIdentifier("course_completion")
            }
        }
    }
    
    @ViewBuilder
    private func mainCourseView(chapter: LyoCourseChapter) -> some View {
        VStack(spacing: 0) {
            // Course Header
            CourseHeaderView(
                topic: selectedTopic,
                progress: progress,
                currentChapter: currentChapterIndex,
                totalChapters: currentCourse.count
            )
            
            // Course Content with lazy loading
            LazyVStack(spacing: 0) {
                CourseContentView(
                    chapter: chapter,
                    onStartQuiz: {
                        withAnimation(DesignTokens.Animations.smooth) {
                            showingQuiz = true
                            currentQuestionIndex = 0
                        }
                    }
                )
            }
            .background(DesignTokens.Colors.background)
            
            Spacer()
            
            // Action Bar
            VStack(spacing: DesignTokens.Spacing.md) {
                // AI Chat Button
                Button(action: {
                    withAnimation(DesignTokens.Animations.smooth) {
                        showingAIChat = true
                    }
                    
                    // Analytics tracking removed - implement when AnalyticsManager is available
                }) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("Chat with Lyo")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
                .accessibilityIdentifier("ai_chat_button")
                .accessibilityHint("Opens AI chat interface")
                
                // Navigation
                HStack(spacing: DesignTokens.Spacing.md) {
                    // Previous Button
                    Button(action: {
                        withAnimation(DesignTokens.Animations.smooth) {
                            if currentChapterIndex > 0 {
                                currentChapterIndex -= 1
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Previous")
                        }
                        .foregroundColor(currentChapterIndex > 0 ? DesignTokens.Colors.primary : DesignTokens.Colors.textTertiary)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .fill(DesignTokens.Colors.glassBg)
                        )
                    }
                    .disabled(currentChapterIndex == 0)
                    
                    Spacer()
                    
                    // Chapter Indicator
                    Text("Chapter \(currentChapterIndex + 1) of \(currentCourse.count)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    // Next Button
                    Button(action: {
                        withAnimation(DesignTokens.Animations.smooth) {
                            if currentChapterIndex < currentCourse.count - 1 {
                                currentChapterIndex += 1
                            }
                        }
                    }) {
                        HStack {
                            Text(currentChapterIndex < currentCourse.count - 1 ? "Next" : "Complete")
                            Image(systemName: currentChapterIndex < currentCourse.count - 1 ? "chevron.right" : "checkmark")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.vertical, DesignTokens.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .fill(DesignTokens.Colors.primaryGradient)
                        )
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
    }
}

// MARK: - Course Completion View
struct CourseCompletionView: View {
    let topic: String
    let onRestart: () -> Void
    let onNewTopic: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Spacer()
            
            // Celebration Animation
            ZStack {
                Circle()
                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "graduation.cap.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text("Congratulations!")
                    .font(.title)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                
                Text("You've completed the \(topic) course!")
                    .font(.title3)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Button(action: onNewTopic) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Start New Course")
                    }
                    .padding()
                    .background(Color.primary)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .accessibilityIdentifier("new_course_button")
                .accessibilityHint("Start a new learning course")
                
                Button(action: onRestart) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Review Course")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                }
                .accessibilityIdentifier("review_course_button")
                .accessibilityHint("Review the course content")
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("course_completion")
    }
}

// MARK: - Course UI Components

struct CourseHeaderView: View {
    let topic: String
    let progress: Double
    let currentChapter: Int
    let totalChapters: Int
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("AI CLASSROOM")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .textCase(.uppercase)
                        .tracking(1)
                        .accessibilityHidden(true) // Hide from VoiceOver as it's decorative
                    
                    Text(topic)
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityLabel("Course topic: \(topic)")
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                    Text("Chapter \(currentChapter + 1) of \(totalChapters)")
                        .font(.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .accessibilityLabel("Currently on chapter \(currentChapter + 1) of \(totalChapters) total chapters")
                    
                    CircularProgressView(progress: progress)
                        .accessibilityLabel("Course completion progress")
                        .accessibilityValue(String(format: "%.0f%% complete", progress * 100))
                }
            }
            
            ProgressView(value: progress)
                .accessibilityLabel("Course progress: Chapter \(currentChapter + 1) of \(totalChapters), \(String(format: "%.0f", progress * 100))% complete")
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            Rectangle()
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    Rectangle()
                        .fill(DesignTokens.Colors.glassBorder)
                        .frame(height: 1),
                    alignment: .bottom
                )
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("course_header")
    }
}

struct CourseContentView: View {
    let chapter: LyoCourseChapter
    let onStartQuiz: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                // chapterHeaderSection starts here
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack {
                        Text(chapter.title)
                            .font(.title)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityLabel("Chapter title: \(chapter.title)")
                        
                        Spacer()
                        
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .accessibilityHidden(true)
                            
                            Text("\(chapter.estimatedDuration) min")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                                .accessibilityLabel("Estimated time: \(chapter.estimatedDuration) minutes")
                        }
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                .fill(DesignTokens.Colors.glassBg)
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Estimated time: \(chapter.estimatedDuration) minutes")
                    }
                    
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Text(chapter.difficulty.displayName)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(chapter.difficulty.color)
                            )
                            .accessibilityLabel("Difficulty: \(chapter.difficulty.displayName)")
                        
                        ForEach(chapter.concepts, id: \.self) { concept in
                            Text(concept)
                                .font(.caption2)
                                .foregroundColor(DesignTokens.Colors.primary)
                                .padding(.horizontal, DesignTokens.Spacing.sm)
                                .padding(.vertical, DesignTokens.Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                        .fill(DesignTokens.Colors.primary.opacity(0.1))
                                )
                                .accessibilityLabel("Concept: \(concept)")
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Chapter information")
                }
                // chapterHeaderSection ends here
                
                // Chapter Content
                Text(chapter.content)
                    .font(.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineSpacing(4)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Chapter content: \(chapter.content)")
                    .accessibilityAddTraits(.allowsDirectInteraction)
                    .dynamicTypeSize(.medium...DynamicTypeSize.accessibility3)
                
                // Key Points
                if !chapter.keyPoints.isEmpty {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Key Points")
                            .font(.title3)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            ForEach(Array(chapter.keyPoints.enumerated()), id: \.offset) { index, point in
                                HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                                    Circle()
                                        .fill(DesignTokens.Colors.primary)
                                        .frame(width: 6, height: 6)
                                        .padding(.top, 8)
                                        .accessibilityHidden(true)
                                    
                                    Text(point)
                                        .font(.body)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                        .accessibilityLabel("Key point \(index + 1): \(point)")
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Key point \(index + 1): \(point)")
                            }
                        }
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            .fill(DesignTokens.Colors.glassBg)
                    )
                    .accessibilityIdentifier("key_points_section")
                }
                
                // Quiz Section
                if !chapter.exercises.isEmpty {
                    VStack(spacing: DesignTokens.Spacing.md) {
                        HStack {
                            Text("Chapter Quiz")
                                .font(.title3)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            
                            Spacer()
                            
                            Text("\(chapter.exercises.count) questions")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Text("Test your understanding of this chapter with a quick quiz.")
                            .font(.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Button(action: onStartQuiz) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Quiz")
                            }
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .accessibilityIdentifier("quiz_button")
                        .accessibilityHint("Start the chapter quiz")
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                            .fill(DesignTokens.Colors.glassBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                    .strokeBorder(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .accessibilityIdentifier("quiz_section")
                }
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("course_content")
    }
}

struct CourseQuizView: View {
    let chapter: LyoCourseChapter
    @Binding var currentQuestionIndex: Int
    let onQuizComplete: () -> Void
    
    @State private var selectedAnswer: Int? = nil
    @State private var showingExplanation = false
    @State private var correctAnswers = 0
    @State private var isComplete = false
    @FocusState private var questionFocused: Bool
    
    // Analytics tracking
    @State private var quizStartTime: Date?
    @State private var questionStartTime: Date?
    
    private var currentExercise: Exercise? {
        guard currentQuestionIndex < chapter.exercises.count else { return nil }
        return chapter.exercises[currentQuestionIndex]
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            if let exercise = currentExercise {
                // Quiz Header
                VStack(spacing: DesignTokens.Spacing.md) {
                    HStack {
                        Text("Quiz")
                            .font(.title2)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        
                        Spacer()
                        
                        Text("Question \(currentQuestionIndex + 1) of \(chapter.exercises.count)")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .accessibilityLabel("Question \(currentQuestionIndex + 1) of \(chapter.exercises.count)")
                    }
                    
                    ProgressView(value: Double(currentQuestionIndex + 1) / Double(chapter.exercises.count))
                        .accessibilityLabel("Quiz progress: Question \(currentQuestionIndex + 1) of \(chapter.exercises.count)")
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("quiz_header")
                
                // Question
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text(exercise.question)
                        .font(.title3)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityLabel("Question: \(exercise.question)")
                        .accessibilityIdentifier("quiz_question")
                        .focused($questionFocused)
                    
                    QuizAnswerOptionsView(
                        exercise: exercise,
                        selectedAnswer: $selectedAnswer,
                        showingExplanation: showingExplanation
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Answer options")
                    
                    // Explanation
                    if showingExplanation {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("Explanation")
                                .font(.title3)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text(exercise.explanation)
                                .font(.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .padding(DesignTokens.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                .fill(DesignTokens.Colors.glassBg)
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Explanation: \(exercise.explanation)")
                        .accessibilityAddTraits(.allowsDirectInteraction)
                    }
                }
                
                Spacer()
                
                // Action Button
                HStack {
                    if showingExplanation {
                        Button(action: nextQuestion) {
                            HStack {
                                Image(systemName: currentQuestionIndex < chapter.exercises.count - 1 ? "arrow.right" : "checkmark")
                                Text(currentQuestionIndex < chapter.exercises.count - 1 ? "Next Question" : "Complete Quiz")
                            }
                            .padding()
                            .background(Color.primary)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .accessibilityIdentifier("next_button")
                        .accessibilityHint(currentQuestionIndex < chapter.exercises.count - 1 ? "Move to next question" : "Complete the quiz")
                    } else {
                        Button(action: submitAnswer) {
                            Text("Submit Answer")
                                .padding()
                                .background(selectedAnswer != nil ? Color.primary : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled(selectedAnswer == nil)
                        .accessibilityIdentifier("submit_answer_button")
                        .accessibilityHint("Submit your selected answer")
                    }
                }
            } else if isComplete {
                // Quiz Complete
                VStack(spacing: DesignTokens.Spacing.xl) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(DesignTokens.Colors.primary)
                    
                    Text("Quiz Complete!")
                        .font(.title)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("You scored \(correctAnswers) out of \(chapter.exercises.count)")
                        .font(.title3)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Button(action: onQuizComplete) {
                        Text("Continue to Next Chapter")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, DesignTokens.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .fill(DesignTokens.Colors.primaryGradient)
                            )
                    }
                }
                .padding(DesignTokens.Spacing.xl)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .onAppear {
            // Analytics tracking removed - implement when AnalyticsManager is available
            quizStartTime = Date()
            questionStartTime = Date()
        }
    }
    
    private func submitAnswer() {
        guard let answer = selectedAnswer, let exercise = currentExercise else { return }
        
        let isCorrect = answer == exercise.correctAnswer
        if isCorrect {
            correctAnswers += 1
        }
        
        // Analytics tracking removed - implement when AnalyticsManager is available
        
        withAnimation(.spring()) {
            showingExplanation = true
        }
    }
    
    private func nextQuestion() {
        if currentQuestionIndex < chapter.exercises.count - 1 {
            currentQuestionIndex += 1
            selectedAnswer = nil
            showingExplanation = false
            questionStartTime = Date() // Reset timer for next question
        } else {
            // Analytics tracking removed - implement when AnalyticsManager is available
            isComplete = true
        }
    }
}

struct CourseAIAssistantView: View {
    let topic: String
    let currentChapter: LyoCourseChapter
    @Binding var userMessage: String
    @State private var aiResponse: String = ""
    @State private var isThinking = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // AI Assistant Header
            Text("AI Assistant for \(topic)")
                .font(DesignTokens.Typography.title2)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.top)
            
            // Response Area
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    if isThinking {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                                .scaleEffect(0.8)
                            Text("AI is thinking...")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    } else if !aiResponse.isEmpty {
                        Text(aiResponse)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .fill(DesignTokens.Colors.glassBg)
                            )
                    } else {
                        Text("Ask me anything about \(currentChapter.title)")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                            .italic()
                    }
                }
                .padding()
            }
            
            // Input Area
            HStack {
                TextField("Ask a question...", text: $userMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(DesignTokens.Typography.body)
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(DesignTokens.Colors.primary)
                        .clipShape(Circle())
                }
                .disabled(userMessage.isEmpty)
            }
            .padding()
        }
        .background(DesignTokens.Colors.primaryBg)
    }
    
    private func sendMessage() {
        guard !userMessage.isEmpty else { return }
        
        let _ = userMessage.count // Track message length (analytics placeholder)
        let _ = Date() // Track message start time (analytics placeholder)
        userMessage = ""
        
        isThinking = true
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isThinking = false
            
            // Generate contextual response based on chapter and user message
            let responses = [
                "Great question! In \(currentChapter.title), the key concept is about understanding the fundamentals. Let me explain it step by step...",
                "That's an excellent observation! When we look at \(currentChapter.title), we can see that this relates to the broader principles we're learning.",
                "I'd be happy to clarify that! The main idea in this chapter is that learning happens through practice and understanding core concepts.",
                "Perfect question for this chapter! Let me break down how this concept applies to real-world scenarios..."
            ]
            
            aiResponse = responses.randomElement() ?? "I'm here to help you understand this concept better!"
            
            // Analytics tracking removed - implement when AnalyticsManager is available
        }
    }
}

// MARK: - Course Navigation
struct CourseNavigationView: View {
    let currentChapter: Int
    let totalChapters: Int
    let canGoNext: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Previous Button
            Button(action: onPrevious) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Previous")
                }
                .foregroundColor(currentChapter > 0 ? DesignTokens.Colors.primary : DesignTokens.Colors.textTertiary)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                        .fill(DesignTokens.Colors.glassBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                        )
                )
            }
            .disabled(currentChapter == 0)
            
            Spacer()
            
            // Chapter Indicator
            Text("Chapter \(currentChapter + 1) of \(totalChapters)")
                .font(.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Spacer()
            
            // Next Button
            Button(action: onNext) {
                HStack {
                    Text(currentChapter < totalChapters - 1 ? "Next" : "Complete")
                    Image(systemName: currentChapter < totalChapters - 1 ? "chevron.right" : "checkmark")
                }
                .foregroundColor(.white)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                        .fill(
                            canGoNext
                                ? DesignTokens.Colors.primaryGradient
                                : LinearGradient(
                                    gradient: Gradient(colors: [DesignTokens.Colors.textTertiary, DesignTokens.Colors.textTertiary]),
                                    startPoint: .top, endPoint: .bottom
                                )
                        )
                )
            }
            .disabled(!canGoNext)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            Rectangle()
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    Rectangle()
                        .fill(DesignTokens.Colors.glassBorder)
                        .frame(height: 1),
                    alignment: .top
                )
        )
    }
}

// MARK: - Utility: CircularProgressView
struct CircularProgressView: View {
    var progress: Double // 0.0 to 1.0
    var lineSize: CGFloat = 6
    var size: CGFloat = 32
    var body: some View {
        ZStack {
            Circle()
                .stroke(DesignTokens.Colors.glassBorder, lineWidth: lineSize)
                .frame(width: size, height: size)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(DesignTokens.Colors.primary, style: StrokeStyle(lineWidth: lineSize, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: size, height: size)
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
}

// MARK: - QuizAnswerOptionsView
struct QuizAnswerOptionsView: View {
    let exercise: Exercise
    @Binding var selectedAnswer: Int?
    let showingExplanation: Bool
    var body: some View {
        return VStack(spacing: DesignTokens.Spacing.md) {
            ForEach(0..<exercise.options.count, id: \.self) { index in
                QuizAnswerOptionButton(
                    option: exercise.options[index],
                    isSelected: selectedAnswer == index,
                    isCorrect: showingExplanation && index == exercise.correctAnswer,
                    isIncorrect: showingExplanation && index == selectedAnswer && index != exercise.correctAnswer,
                    showingExplanation: showingExplanation,
                    onTap: {
                        if !showingExplanation {
                            selectedAnswer = index
                        }
                    }
                )
            }
        }
    }
}

struct QuizAnswerOptionButton: View {
    let option: String
    let isSelected: Bool
    let isCorrect: Bool
    let isIncorrect: Bool
    let showingExplanation: Bool
    let onTap: () -> Void
    
    private var backgroundColor: Color {
        if isCorrect {
            return Color.green.opacity(0.1)
        } else if isIncorrect {
            return Color.red.opacity(0.1)
        } else if isSelected {
            return DesignTokens.Colors.primary.opacity(0.1)
        } else {
            return DesignTokens.Colors.glassBg
        }
    }
    
    private var borderColor: Color {
        if isCorrect {
            return Color.green
        } else if isIncorrect {
            return Color.red
        } else if isSelected {
            return DesignTokens.Colors.primary
        } else {
            return DesignTokens.Colors.glassBorder
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(option)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                } else if isIncorrect {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.red)
                } else if isSelected {
                    Circle().fill(DesignTokens.Colors.primary).frame(width: 20)
                } else {
                    Circle().stroke(DesignTokens.Colors.glassBorder, lineWidth: 2).frame(width: 20)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .strokeBorder(borderColor, lineWidth: 1)
                    )
            )
        }
        .disabled(showingExplanation)
    }
}

// MARK: - Missing View Components
// (Learning models moved to Models.swift for better organization)

/// Error state view for error handling
struct ErrorStateView: View {
    let error: AppError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(DesignTokens.Typography.title2)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(error.localizedDescription)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: onRetry)
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(.white)
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                        .fill(DesignTokens.Colors.primary)
                )
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.background.ignoresSafeArea())
    }
}

/// AI Chat view for learning assistance
struct AIChatView: View {
    let currentChapter: LyoCourseChapter
    @ObservedObject var aiChatManager: AIChatManager
    let onClose: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                Text("AI Chat coming soon!")
                    .font(DesignTokens.Typography.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Chat with Lyo about \(currentChapter.title)")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Button("Close", action: onClose)
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .fill(DesignTokens.Colors.primary)
                    )
            }
            .padding(DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.background.ignoresSafeArea())
            .navigationTitle("Chat with Lyo")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onClose)
                }
            }
        }
    }
}

// MARK: - Course UI Components
// (All course-related components are defined above)

