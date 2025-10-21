import SwiftUI
import AVKit

/// Main AI Classroom View - Immersive, cinematic learning experience
/// Supports both horizontal (focus mode) and vertical (exploration mode) orientations
struct AIClassroomView: View {
    // MARK: - Properties
    let course: Course
    let lesson: Lesson

    @StateObject private var viewModel = ClassroomViewModel()
    @StateObject private var liveOrchestrator = LiveLearningOrchestrator.shared
    @StateObject private var microQuizManager = IntelligentMicroQuizManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - State
    @State private var viewState = ClassroomViewState()
    @State private var showingContentDrawer = false
    @State private var showingNotes = false
    @State private var showingLiveChat = false
    @State private var liveQuestion = ""
    @State private var lastInteractionTime = Date()
    @State private var autoHideTimer: Timer?

    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()

            if viewState.orientation == .horizontal {
                horizontalModeLayout
            } else {
                verticalModeLayout
            }

            // Floating Avatar Overlay
            AvatarOverlayView(
                mood: viewState.avatarMood,
                isThinking: viewModel.isProcessing,
                orientation: viewState.orientation
            )
            .onTapGesture {
                handleAvatarTap()
            }

            // Control Layer (auto-hiding)
            if viewState.controlsVisible {
                controlLayer
                    .transition(.opacity)
            }

            // Micro Quiz Overlay
            if viewState.showingQuiz, let quiz = viewModel.currentQuiz {
                MicroQuizOverlay(
                    quiz: quiz,
                    onComplete: { passed in
                        handleQuizCompletion(passed: passed)
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(100)
            }

            // Content Card Drawer
            if showingContentDrawer {
                ContentCardDrawer(
                    cards: viewModel.curatedCards,
                    onCardSelected: { card in
                        viewState.selectedContentCard = card
                        showingContentDrawer = false
                    },
                    onClose: {
                        showingContentDrawer = false
                    }
                )
                .transition(.move(edge: .trailing))
                .zIndex(50)
            }
            
            // Live Chat Overlay
            if showingLiveChat {
                LiveChatOverlay(
                    orchestrator: liveOrchestrator,
                    onClose: {
                        showingLiveChat = false
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(60)
            }

            // Completion Overlay
            if viewState.playbackState == .completed {
                LessonCompletionOverlay(
                    lesson: lesson,
                    accuracy: viewModel.quizAccuracy,
                    xpEarned: viewModel.xpEarned,
                    onContinue: {
                        handleContinueToNext()
                    },
                    onReview: {
                        handleReviewMistakes()
                    },
                    onExit: {
                        dismiss()
                    }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(200)
            }
        }
        .navigationBarHidden(true)
        .statusBarHidden(viewState.orientation == .horizontal)
        .onAppear {
            setupClassroom()
        }
        .onDisappear {
            cleanup()
        }
        .gesture(
            TapGesture(count: 1)
                .onEnded { _ in
                    handleSingleTap()
                }
        )
    }

    // MARK: - Horizontal Mode Layout (Focus Mode)
    private var horizontalModeLayout: some View {
        ZStack {
            // Main Lecture Player (Full Screen)
            LecturePlayerView(
                chunk: viewModel.currentChunk,
                playbackState: $viewState.playbackState,
                onChunkCompleted: {
                    handleChunkCompletion()
                }
            )
            .ignoresSafeArea()

            // Progress Bar (Bottom)
            VStack {
                Spacer()
                if !viewState.controlsVisible {
                    progressBar
                        .padding(.bottom, 8)
                }
            }
        }
    }

    // MARK: - Vertical Mode Layout (Exploration Mode)
    private var verticalModeLayout: some View {
        VStack(spacing: 0) {
            // Top 50%: Video Player (Resized)
            LecturePlayerView(
                chunk: viewModel.currentChunk,
                playbackState: $viewState.playbackState,
                onChunkCompleted: {
                    handleChunkCompletion()
                }
            )
            .frame(height: UIScreen.main.bounds.height * 0.5)
            .clipped()

            // Bottom 50%: Scrollable Content
            ScrollView {
                VStack(spacing: 20) {
                    // Progress Overview
                    progressOverviewSection

                    // Notes Section
                    notesSection

                    // Recommended Resources
                    recommendedResourcesSection

                    // Next Up Preview
                    nextUpSection
                }
                .padding()
            }
            .background(DesignTokens.Colors.backgroundPrimary)
        }
    }

    // MARK: - Control Layer
    private var controlLayer: some View {
        VStack {
            // Top Bar
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }

                Spacer()

                Text(lesson.title)
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(.white)
                    .textReadability()

                Spacer()

                Button(action: { viewState.orientation = viewState.orientation == .horizontal ? .vertical : .horizontal }) {
                    Image(systemName: viewState.orientation == .horizontal ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            Spacer()

            // Center Controls
            HStack(spacing: 40) {
                // Skip Back 10s
                Button(action: { viewModel.skipBackward() }) {
                    Image(systemName: "gobackward.10")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }

                // Play/Pause
                Button(action: { togglePlayback() }) {
                    Image(systemName: viewState.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 64, weight: .regular))
                        .foregroundColor(.white)
                }
                .scaleEffect(viewState.playbackState == .playing ? 1.0 : 1.1)
                .animation(.spring(response: 0.3), value: viewState.playbackState)

                // Skip Forward 10s
                Button(action: { viewModel.skipForward() }) {
                    Image(systemName: "goforward.10")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.3))
                    .blur(radius: 20)
            )

            Spacer()

            // Bottom Bar
            HStack(spacing: 12) {
                // Previous Lesson Button
                Button(action: { handleNavigateToPreviousLesson() }) {
                    Label("Previous", systemImage: "chevron.left")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                }
                .disabled(viewModel.navigateToPreviousLesson(course: course) == nil)
                
                Button(action: { showingNotes.toggle() }) {
                    Label("Notes", systemImage: "note.text")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                }
                
                Button(action: { showingLiveChat.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(DesignTokens.Typography.labelMedium)
                        if liveOrchestrator.connectionStatus == .connected {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.black.opacity(0.5)))
                }

                Spacer()

                progressBar

                Spacer()

                Button(action: { showingContentDrawer.toggle() }) {
                    Label("Resources", systemImage: "books.vertical")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                }
                
                // Next Lesson Button
                Button(action: { handleNavigateToNextLesson() }) {
                    Label("Next", systemImage: "chevron.right")
                        .font(DesignTokens.Typography.labelMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.5)))
                }
                .disabled(viewModel.nextLesson == nil)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 8) {
            Text("\(viewModel.currentChunkIndex + 1)/\(viewModel.totalChunks)")
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(.white)
                .monospacedDigit()

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)

                    // Progress
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.Colors.brand)
                        .frame(width: geometry.size.width * viewModel.lessonProgress, height: 4)
                }
            }
            .frame(height: 4)

            Text(viewModel.remainingTimeFormatted)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(.white.opacity(0.8))
                .monospacedDigit()
        }
        .frame(maxWidth: 250)
    }

    // MARK: - Vertical Mode Sections

    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Progress")
                .font(DesignTokens.Typography.titleLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            HStack(spacing: 16) {
                StatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(Int(viewModel.lessonProgress * 100))%",
                    label: "Complete",
                    color: DesignTokens.Colors.success
                )

                StatCard(
                    icon: "clock.fill",
                    value: viewModel.timeSpentFormatted,
                    label: "Time Spent",
                    color: DesignTokens.Colors.info
                )

                StatCard(
                    icon: "star.fill",
                    value: "\(viewModel.xpEarned)",
                    label: "XP Earned",
                    color: DesignTokens.Colors.neonYellow
                )
            }
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Spacer()

                Button("Add Note") {
                    // TODO: Add note functionality
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(DesignTokens.Colors.brand)
            }

            if viewModel.notes.isEmpty {
                Text("No notes yet. Tap 'Add Note' to capture key insights.")
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(DesignTokens.Colors.backgroundSecondary)
                    )
            } else {
                ForEach(viewModel.notes) { note in
                    NoteCard(note: note)
                }
            }
        }
    }

    private var recommendedResourcesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Resources")
                .font(DesignTokens.Typography.titleLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.curatedCards) { card in
                        ContentCardCompact(card: card)
                            .onTapGesture {
                                viewState.selectedContentCard = card
                            }
                    }
                }
            }
        }
    }

    private var nextUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Up")
                .font(DesignTokens.Typography.titleLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            if let nextLesson = viewModel.nextLesson {
                NextLessonCard(lesson: nextLesson) {
                    handleNavigateToLesson(nextLesson)
                }
            } else {
                Text("You're at the end of this module! Great job! 🎉")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
    }

    // MARK: - Methods

    private func setupClassroom() {
        viewModel.loadLesson(lesson, courseId: course.id)
        viewModel.updateNextLesson(course: course)
        viewModel.loadCuratedContent()
        startAutoHideTimer()
        
        // Connect to live learning WebSocket
        // TODO: Get actual userId from UserDataManager
        liveOrchestrator.connect(userId: "user-123")
        liveOrchestrator.setCurrentLesson(lesson)
        
        // Listen for struggle/mastery notifications
        setupLiveLearningNotifications()

        // Start playback after a brief moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if viewState.playbackState == .paused {
                togglePlayback()
            }
        }
    }

    private func cleanup() {
        autoHideTimer?.invalidate()
        viewModel.saveProgress()
        liveOrchestrator.disconnect()
    }
    
    private func setupLiveLearningNotifications() {
        // Listen for struggle detection
        NotificationCenter.default.addObserver(
            forName: .userStrugglingWithConcept,
            object: nil,
            queue: .main
        ) { [self] notification in
            if let concept = notification.object as? String {
                handleStruggleDetected(concept: concept)
            }
        }
        
        // Listen for concept mastery
        NotificationCenter.default.addObserver(
            forName: .userMasteredConcept,
            object: nil,
            queue: .main
        ) { [self] notification in
            if let achievement = notification.object as? String {
                handleConceptMastered(achievement: achievement)
            }
        }
        
        // Listen for knowledge gaps detected
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("knowledgeGapDetected"),
            object: nil,
            queue: .main
        ) { [self] notification in
            if let gapData = notification.object as? [String: Any],
               let concept = gapData["concept"] as? String,
               let severity = gapData["severity"] as? String {
                print("🔍 [Classroom] Gap detected: \(concept) (severity: \(severity))")
                // Gap is automatically handled by microQuizManager
                // Show visual indicator if critical
                if severity == "critical" {
                    withAnimation {
                        viewState.avatarMood = .supportive
                    }
                }
            }
        }
        
        // Listen for quiz performance notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("quizPerformancePoor"),
            object: nil,
            queue: .main
        ) { [self] notification in
            print("⚠️ [Classroom] Poor quiz performance detected")
            withAnimation {
                viewState.avatarMood = .supportive
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("quizPerformanceExcellent"),
            object: nil,
            queue: .main
        ) { [self] notification in
            print("🎉 [Classroom] Excellent quiz performance!")
            viewModel.xpEarned += 15 // Bonus XP
            HapticManager.shared.success()
        }
    }

    private func handleSingleTap() {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewState.controlsVisible.toggle()
        }

        if viewState.controlsVisible {
            resetAutoHideTimer()
        }

        HapticManager.shared.light()
    }

    private func handleAvatarTap() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            viewState.avatarMood = [.friendly, .excited, .supportive, .curious].randomElement() ?? .friendly
        }

        HapticManager.shared.medium()
    }

    private func togglePlayback() {
        withAnimation {
            viewState.playbackState = viewState.playbackState == .playing ? .paused : .playing
        }

        HapticManager.shared.light()
    }

    private func handleChunkCompletion() {
        // Report progress to live orchestrator
        reportProgress()
        
        // Check if there's a quiz for this chunk
        if let quiz = viewModel.currentChunk?.quiz {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                viewState.playbackState = .paused
                viewState.showingQuiz = true
                viewModel.currentQuiz = quiz
            }
        } else {
            // Check if we should generate an adaptive micro-quiz
            // (every 3rd chunk or when gaps detected)
            let shouldGenerateQuiz = (viewModel.currentChunkIndex + 1) % 3 == 0 || !microQuizManager.detectedGaps.isEmpty
            
            if shouldGenerateQuiz {
                Task {
                    await generateAdaptiveQuiz()
                }
            } else {
                // Move to next chunk
                viewModel.moveToNextChunk()
            }
        }
    }

    private func handleQuizCompletion(passed: Bool) {
        withAnimation {
            viewState.showingQuiz = false
        }
        
        // Submit quiz results to microQuizManager for adaptive tracking
        Task {
            if let intelligentQuiz = microQuizManager.currentQuiz,
               let currentQuiz = viewModel.currentQuiz {
                // Collect answers (simplified - in production, collect from quiz UI)
                var answers: [String: String] = [:]
                for (index, question) in intelligentQuiz.questions.enumerated() {
                    answers[question.id] = passed ? question.correctAnswer : question.options.first ?? ""
                }
                
                let result = await microQuizManager.submitQuiz(intelligentQuiz, answers: answers)
                
                // Update mastery map and check for gaps
                await MainActor.run {
                    // Show mastery feedback
                    let masteryLevel = microQuizManager.getMastery(for: lesson.title)
                    print("📊 [Quiz] Current mastery: \(masteryLevel)")
                    
                    // Check for newly detected gaps
                    if !result.detectedGaps.isEmpty {
                        print("🔍 [Quiz] Gaps detected: \(result.detectedGaps.map { $0.concept })")
                    }
                }
            }
        }

        if passed {
            viewState.avatarMood = .excited
            viewModel.xpEarned += 10
            HapticManager.shared.success()

            // Move to next chunk after celebration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                viewModel.moveToNextChunk()

                if viewModel.currentChunkIndex >= viewModel.totalChunks {
                    // Lesson completed!
                    withAnimation {
                        viewState.playbackState = .completed
                    }
                } else {
                    withAnimation {
                        viewState.playbackState = .playing
                    }
                }
            }
        } else {
            viewState.avatarMood = .supportive
            HapticManager.shared.warning()

            // Allow retry
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    viewState.playbackState = .playing
                }
            }
        }
    }

    private func handleContinueToNext() {
        if let nextLesson = viewModel.navigateToNextLesson(course: course) {
            handleNavigateToLesson(nextLesson)
        } else {
            // End of course - show completion and dismiss
            dismiss()
        }
    }

    private func handleNavigateToLesson(_ targetLesson: Lesson) {
        // Save current progress
        viewModel.saveProgress()
        
        // Navigate to new lesson by recreating the view
        // This is a simple approach - in a more complex app, you'd use navigation coordinator
        let newView = AIClassroomView(course: course, lesson: targetLesson)
        // For now, we'll dismiss and let the parent view handle navigation
        // TODO: Implement proper navigation coordinator pattern
        dismiss()
        
        print("🎯 [Classroom] Navigating to lesson: \(targetLesson.title)")
    }

    private func handleNavigateToNextLesson() {
        if let nextLesson = viewModel.navigateToNextLesson(course: course) {
            handleNavigateToLesson(nextLesson)
        }
    }

    private func handleNavigateToPreviousLesson() {
        if let prevLesson = viewModel.navigateToPreviousLesson(course: course) {
            handleNavigateToLesson(prevLesson)
        }
    }

    private func handleReviewMistakes() {
        // TODO: Review incorrect quiz answers
    }
    
    // MARK: - Live Learning Handlers
    
    private func handleStruggleDetected(concept: String) {
        print("🆘 [Classroom] Struggle detected with: \(concept)")
        
        // Show avatar with supportive mood
        withAnimation {
            viewState.avatarMood = .supportive
        }
        
        // Pause and offer help
        if viewState.playbackState == .playing {
            togglePlayback()
        }
        
        // Show suggested actions from live orchestrator
        if !liveOrchestrator.suggestedActions.isEmpty {
            // TODO: Show action sheet with suggestions
            print("💡 [Classroom] Suggestions: \(liveOrchestrator.suggestedActions)")
        }
        
        HapticManager.shared.warning()
    }
    
    private func handleConceptMastered(achievement: String) {
        print("🎉 [Classroom] Concept mastered: \(achievement)")
        
        // Show avatar with excited mood
        withAnimation {
            viewState.avatarMood = .excited
        }
        
        // Award bonus XP
        viewModel.xpEarned += 25
        
        HapticManager.shared.success()
    }
    
    private func askLiveQuestion() {
        guard !liveQuestion.isEmpty else { return }
        
        // Send question to live orchestrator
        liveOrchestrator.askQuestion(liveQuestion)
        
        // Clear input and show thinking state
        liveQuestion = ""
        
        HapticManager.shared.light()
    }
    
    private func reportProgress() {
        let progress = Float(viewModel.lessonProgress)
        liveOrchestrator.reportProgress(percentage: progress)
    }
    
    // MARK: - Adaptive Quiz Generation
    
    private func generateAdaptiveQuiz() async {
        // Generate quiz based on current lesson and detected gaps
        await microQuizManager.generateAdaptiveQuiz(for: lesson)
        
        // Show the generated quiz if available
        if let intelligentQuiz = microQuizManager.currentQuiz {
            // Convert IntelligentMicroQuiz to Quiz format for UI
            let quiz = Quiz(
                id: UUID(uuidString: intelligentQuiz.id) ?? UUID(),
                questions: intelligentQuiz.questions.map { iq in
                    QuizQuestion(
                        id: UUID(uuidString: iq.id) ?? UUID(),
                        question: iq.question,
                        answers: iq.options,
                        correctAnswerIndex: iq.options.firstIndex(of: iq.correctAnswer) ?? 0,
                        explanation: iq.explanation,
                        difficulty: .medium
                    )
                }
            )
            
            // Show quiz in UI
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    self.viewState.playbackState = .paused
                    self.viewState.showingQuiz = true
                    self.viewModel.currentQuiz = quiz
                }
            }
        } else {
            // No quiz generated, continue to next chunk
            viewModel.moveToNextChunk()
        }
    }

    private func startAutoHideTimer() {
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            checkAutoHide()
        }
    }

    private func resetAutoHideTimer() {
        lastInteractionTime = Date()
    }

    private func checkAutoHide() {
        guard viewState.controlsVisible else { return }

        let timeSinceInteraction = Date().timeIntervalSince(lastInteractionTime)
        if timeSinceInteraction >= 3.0 && viewState.playbackState == .playing {
            withAnimation(.easeOut(duration: 0.3)) {
                viewState.controlsVisible = false
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(DesignTokens.Typography.titleMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)

            Text(label)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
    }
}

struct NoteCard: View {
    let note: LessonNote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(DesignTokens.Colors.textTertiary)

                Spacer()

                if note.isAIGenerated {
                    Label("AI", systemImage: "sparkles")
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.brand)
                }
            }

            Text(note.content)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
    }
}

struct ContentCardCompact: View {
    let card: ContentCard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail
            if let thumbnailURL = card.thumbnailURL {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(card.kind.color.opacity(0.3))
                        .overlay(
                            Image(systemName: card.kind.iconName)
                                .font(.largeTitle)
                                .foregroundColor(card.kind.color)
                        )
                }
                .frame(width: 180, height: 100)
                .clipped()
                .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(DesignTokens.Typography.titleSmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)

                Text("\(card.source) • \(card.estMinutes) min")
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .padding(.horizontal, 4)
        }
        .frame(width: 180)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
    }
}

struct NextLessonCard: View {
    let lesson: Lesson
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "play.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(DesignTokens.Colors.brand)

            VStack(alignment: .leading, spacing: 4) {
                Text("Lesson \(lesson.lessonNumber)")
                    .font(DesignTokens.Typography.labelMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)

                Text(lesson.title)
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text("\(lesson.estimatedDuration) min")
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(DesignTokens.Colors.backgroundSecondary)
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Supporting Models

struct LessonNote: Identifiable {
    let id = UUID()
    let content: String
    let timestamp: Date
    let isAIGenerated: Bool

    init(content: String, timestamp: Date = Date(), isAIGenerated: Bool = false) {
        self.content = content
        self.timestamp = timestamp
        self.isAIGenerated = isAIGenerated
    }
}

#Preview {
    AIClassroomView(
        course: .mockCourse,
        lesson: .mockLesson1
    )
}
