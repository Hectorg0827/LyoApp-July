import SwiftUI

// MARK: - Enhanced AI Classroom with 75/25 Split Layout

/// Main enhanced classroom view with 75% teaching area and 25% resource bar
struct EnhancedAIClassroomView: View {
    let topic: String
    let course: CourseOutlineLocal?
    let onExit: () -> Void

    // MARK: - Interactive Conversation State
    @State private var userInput: String = ""
    @State private var conversation: [ConversationEntry] = []
    @State private var isAwaitingAIResponse: Bool = false
    @State private var isRecording: Bool = false
    @State private var isDrawerOpen: Bool = false
    @FocusState private var isInputFocused: Bool

    // MARK: - Existing State
    @State private var currentLessonIndex = 0
    @State private var lessonContent: String = ""
    @State private var showingQuiz = false
    @State private var currentQuizQuestion: QuizQuestion?
    @State private var resources: [CuratedResource] = []
    @State private var avatarState: ClassroomAvatarState = .explaining
    @State private var progressPercentage: Double = 0.0
    @State private var codeInput: String = "# Write your code here\nprint(\"Hello, World!\")"
    @State private var codeOutput: String = ""
    @State private var isExecutingCode: Bool = false
    @State private var voiceEnabled: Bool = false

    // MARK: - Progressive Content Display
    @State private var contentChunks: [ContentChunk] = []
    @State private var currentChunkIndex: Int = 0
    @State private var showingMiniQuiz = false
    @State private var miniQuizQuestion: QuizQuestion?
    @State private var showingTutorQuestion = false
    @State private var tutorQuestion: String = ""
    @State private var tutorResponse: String = ""
    @State private var isWaitingForTutorResponse = false
    @State private var showingResources = false

    // MARK: - Adaptive Learning State
    @State private var showSkillsGraph: Bool = false
    @State private var currentMasteryLevel: Double = 0.0 // 0.0 to 1.0 (theta)
    @State private var knowledgeComponents: [KnowledgeComponent] = []
    @State private var adaptivePhase: AdaptivePhase = .assess
    @State private var aloCards: [ALOCard] = []

    var body: some View {
        ZStack {
            // Main Content Area
            VStack(spacing: 0) {
                // MARK: - Minimalist Header
                minimalistHeader
                
                // MARK: - Unified Conversation + Content Area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 24) {
                            ForEach(conversation) { entry in
                                conversationEntryView(entry)
                                    .id(entry.id)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                        .padding(.bottom, 100)
                    }
                    .onChange(of: conversation.count) { _ in
                        if let lastEntry = conversation.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastEntry.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // MARK: - Persistent Bottom Interaction Bar
                bottomInteractionBar
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.05, blue: 0.13),
                        Color(red: 0.05, green: 0.08, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            
            // MARK: - Side Drawer for Settings/Resources
            if isDrawerOpen {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            isDrawerOpen = false
                        }
                    }
                    .transition(.opacity)
            }
            
            sideDrawer
                .offset(x: isDrawerOpen ? 0 : UIScreen.main.bounds.width)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDrawerOpen)
        }
        .onAppear {
            loadSavedProgress()
            loadLessonContent()
            fetchCuratedResources()
        }
        .overlay(
            Group {
                if showingQuiz, let quiz = currentQuizQuestion {
                    comprehensionCheckOverlay(quiz: quiz)
                }
            }
        )
    }
    
    // MARK: - Computed Properties
    private var canGoToNextLesson: Bool {
        guard let course = course else { return false }
        return currentLessonIndex < course.lessons.count - 1
    }

    // MARK: - Minimalist Header
    private var minimalistHeader: some View {
        HStack(spacing: 12) {
            // Exit button
            Button(action: onExit) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    )
            }
            
            // Lesson navigation
            HStack(spacing: 8) {
                // Previous lesson button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        previousLesson()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(currentLessonIndex > 0 ? .white.opacity(0.8) : .white.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(currentLessonIndex > 0 ? 0.15 : 0.05))
                        )
                }
                .disabled(currentLessonIndex == 0)
                
                // Lesson counter
                if let course = course {
                    Text("Lesson \(currentLessonIndex + 1)/\(course.lessons.count)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.1))
                        )
                }
                
                // Next lesson button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        nextLesson()
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(canGoToNextLesson ? .white.opacity(0.8) : .white.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(canGoToNextLesson ? 0.15 : 0.05))
                        )
                }
                .disabled(!canGoToNextLesson)
            }
            
            Spacer()
            
            // Right-side controls
            HStack(spacing: 16) {
                // Mastery "Brain" Icon
                Button(action: { withAnimation(.spring()) { showSkillsGraph.toggle() } }) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(showSkillsGraph ? .purple : .white.opacity(0.6))
                }
                
                // Progress Bar
                HStack(spacing: 8) {
                    ProgressView(value: progressPercentage)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.purple))
                        .frame(width: 80)
                    
                    Text("\(Int(progressPercentage * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 35)
                }
                
                // Settings/Drawer toggle
                Button(action: { withAnimation(.spring()) { isDrawerOpen.toggle() } }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color(red: 0.02, green: 0.05, blue: 0.13)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.3), Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .frame(maxWidth: UIScreen.main.bounds.width * progressPercentage)
                    , alignment: .bottomLeading
                )
        )
    }
    
    // MARK: - Conversation Entry View
    @ViewBuilder
    private func conversationEntryView(_ entry: ConversationEntry) -> some View {
        switch entry.type {
        case .userMessage:
            HStack(alignment: .top, spacing: 12) {
                Spacer(minLength: 40)
                VStack(alignment: .trailing, spacing: 4) {
                    Text(entry.content)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(18, corners: [.topLeft, .topRight, .bottomLeft])
                        .shadow(color: Color.blue.opacity(0.3), radius: 8, y: 4)
                    
                    Text("You")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.trailing, 4)
                }
            }
            
        case .aiResponse:
            HStack(alignment: .top, spacing: 12) {
                // AI Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.cyan.opacity(0.5), radius: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lyo")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                    
                    Text(entry.content)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.95))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                                )
                        )
                        .cornerRadius(18, corners: [.topRight, .bottomLeft, .bottomRight])
                }
                
                Spacer(minLength: 40)
            }
            
        case .lessonChunk:
            if let chunk = contentChunks.first(where: { $0.id.uuidString == entry.content }) {
                VStack(spacing: 0) {
                    switch chunk.type {
                    case .explanation:
                        explanationChunkView(chunk: chunk)
                    case .example:
                        exampleChunkView(chunk: chunk)
                    case .exercise:
                        exerciseChunkView(chunk: chunk)
                    case .summary:
                        summaryChunkView(chunk: chunk)
                    }
                    
                    // Mini quiz if required
                    if chunk.requiresQuiz && !chunkQuizCompleted(chunk) {
                        miniQuizInlineView
                    }
                }
            }
        }
    }
    
    // MARK: - Enhanced Content Chunk Views
    
    private func explanationChunkView(chunk: ContentChunk) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.cyan.opacity(0.4), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Concept Explained")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Let's break this down together")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.8))
                }
                
                Spacer()
            }
            
            Text(chunk.content)
                .font(.system(size: 17, design: .rounded))
                .lineSpacing(8)
                .foregroundColor(.white.opacity(0.95))
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.08),
                                Color.blue.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.cyan.opacity(0.15), radius: 20, y: 8)
    }
    
    private func exampleChunkView(chunk: ContentChunk) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.6), Color.orange.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "star.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.yellow.opacity(0.4), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Real-World Example")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("See it in action")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.yellow.opacity(0.8))
                }
                
                Spacer()
            }
            
            Text(chunk.content)
                .font(.system(size: 16, design: .monospaced))
                .lineSpacing(6)
                .foregroundColor(.white.opacity(0.95))
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.3))
                )
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.yellow.opacity(0.08),
                                Color.orange.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.3), Color.orange.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.yellow.opacity(0.15), radius: 20, y: 8)
    }
    
    private func exerciseChunkView(chunk: ContentChunk) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.purple.opacity(0.4), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Exercise")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("Test your understanding")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.purple.opacity(0.8))
                }
                
                Spacer()
            }
            
            Text(chunk.content)
                .font(.system(size: 17, design: .rounded))
                .lineSpacing(8)
                .foregroundColor(.white.opacity(0.95))
            
            // Interactive coding area placeholder
            interactiveContentView
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.08),
                                Color.pink.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.purple.opacity(0.15), radius: 20, y: 8)
    }
    
    private func summaryChunkView(chunk: ContentChunk) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.6), Color.teal.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .shadow(color: Color.green.opacity(0.4), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Takeaways")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("What you've learned")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green.opacity(0.8))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(chunk.content.components(separatedBy: "•").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { point in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.green)
                        Text(point.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                        Spacer()
                    }
                }
            }
        }
        .padding(24)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.green.opacity(0.08),
                                Color.teal.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green.opacity(0.3), Color.teal.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: Color.green.opacity(0.15), radius: 20, y: 8)
    }
    
    // MARK: - Bottom Interaction Bar
    private var bottomInteractionBar: some View {
        VStack(spacing: 0) {
            // Glassmorphic divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
            
            HStack(spacing: 14) {
                // Microphone button for speech input
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        isRecording.toggle()
                    }
                    // TODO: Implement speech recognition
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                isRecording
                                ? LinearGradient(
                                    colors: [Color.red.opacity(0.8), Color.orange.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        if isRecording {
                            Circle()
                                .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                .frame(width: 50, height: 50)
                                .scaleEffect(1.2)
                                .opacity(0)
                                .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: isRecording)
                        }
                        
                        Image(systemName: isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isRecording ? .white : .white.opacity(0.7))
                    }
                }
                
                // Text input field
                HStack(spacing: 8) {
                    TextField("Ask anything or say 'continue'...", text: $userInput)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit {
                            handleUserInput()
                        }
                    
                    if !userInput.isEmpty {
                        Button(action: { userInput = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                
                // Send button
                Button(action: handleUserInput) {
                    ZStack {
                        Circle()
                            .fill(
                                (userInput.isEmpty && !isAwaitingAIResponse)
                                ? LinearGradient(
                                    colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                : LinearGradient(
                                    colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(
                                color: userInput.isEmpty ? Color.clear : Color.purple.opacity(0.4),
                                radius: 8,
                                y: 4
                            )
                        
                        if isAwaitingAIResponse {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(userInput.isEmpty && !isAwaitingAIResponse)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(
            ZStack {
                // Glassmorphic background
                Color(red: 0.05, green: 0.08, blue: 0.18)
                    .opacity(0.95)
                
                // Blur effect simulation
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            .ignoresSafeArea()
        )
    }
    
    // MARK: - Side Drawer
    private var sideDrawer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Course Settings")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text(topic)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Button(action: { withAnimation(.spring()) { isDrawerOpen = false } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
                .padding(.top, 20)
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Lesson Progress
                if let course = course {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Lesson Progress")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("Lesson \(currentLessonIndex + 1) of \(course.lessons.count)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    )
                }
                
                // Settings Toggles
                VStack(alignment: .leading, spacing: 16) {
                    Text("Preferences")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Toggle(isOn: $voiceEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(.cyan)
                            Text("Voice Narration")
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.cyan)
                    
                    Toggle(isOn: $showSkillsGraph) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(.purple)
                            Text("Skills Graph")
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.purple)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                )
                
                // Curated Resources
                VStack(alignment: .leading, spacing: 16) {
                    Text("Additional Resources")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    if resources.isEmpty {
                        Text("No resources available yet")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding()
                    } else {
                        ForEach(resources.prefix(3)) { resource in
                            compactResourceCard(resource)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .frame(width: 320)
        .background(
            ZStack {
                Color(red: 0.03, green: 0.06, blue: 0.15)
                
                // Gradient overlay
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.1),
                        Color.clear,
                        Color.blue.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            .ignoresSafeArea()
        )
    }
    
    private func compactResourceCard(_ resource: CuratedResource) -> some View {
        HStack(spacing: 12) {
            Image(systemName: resource.type.iconName)
                .font(.system(size: 20))
                .foregroundColor(resource.type.color)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(resource.type.color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(resource.source)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Mini Quiz Inline View
    private var miniQuizInlineView: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.orange)
                
                Text("Quick Check")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if let quiz = miniQuizQuestion {
                VStack(spacing: 12) {
                    Text(quiz.question)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(quiz.answers.indices, id: \.self) { index in
                        Button(action: { checkMiniQuizAnswer(index) }) {
                            Text(quiz.answers[index])
                                .font(.system(size: 15))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
            } else {
                Button(action: generateMiniQuiz) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Quiz")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.orange.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                )
        )
        .padding(.top, 12)
    }

    // MARK: - Teaching Area (75%)
    private var teachingArea: some View {
        VStack(spacing: 20) {
            // Achievement tracker and progress
            achievementAndProgressSection

            // Course content cards
            courseContentSection

            // AI Tutor Question Button
            aiTutorQuestionButton

            // Additional Resources Button
            Button(action: { showingResources = true }) {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 18))
                    Text("Additional Resources")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }

            Spacer()

            // Continue button (only show when ready to proceed)
            if canContinueToNextChunk {
                continueButton
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
    }

    // MARK: - Achievement and Progress Section
    private var achievementAndProgressSection: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * progressPercentage)
                }
            }
            .frame(height: 4)
            .cornerRadius(2)

            // Achievement badges
            HStack(spacing: 12) {
                achievementBadge(icon: "star.fill", title: "Learning", color: .yellow)
                achievementBadge(icon: "brain.head.profile", title: "Understanding", color: .blue)
                achievementBadge(icon: "checkmark.circle.fill", title: "Progress", color: .green)
                Spacer()
                Text("\(Int(progressPercentage * 100))% Complete")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    private func achievementBadge(icon: String, title: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(color)
                )
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Course Content Section
    private var courseContentSection: some View {
        VStack(spacing: 16) {
            if contentChunks.isEmpty {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    Text("Preparing your lesson...")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, minHeight: 200)
            } else if currentChunkIndex < contentChunks.count {
                // Current chunk
                let chunk = contentChunks[currentChunkIndex]
                contentChunkCard(chunk: chunk)

                // Mini quiz if required and not yet completed
                if chunk.requiresQuiz && !chunkQuizCompleted(chunk) {
                    miniQuizSection
                }
            } else {
                // Lesson complete
                lessonCompleteCard
            }
        }
    }

    private func contentChunkCard(chunk: ContentChunk) -> some View {
        let chunkHeader = HStack {
            chunkTypeIcon(chunk.type)
            Text(chunk.type.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
            Spacer()
            Text("Chunk \(currentChunkIndex + 1) of \(contentChunks.count)")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        
        let chunkContentView = ScrollView {
            Text(chunk.content)
                .font(.system(size: 16))
                .lineSpacing(6)
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxHeight: 300)
        
        return VStack(alignment: .leading, spacing: 16) {
            chunkHeader
            chunkContentView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func chunkTypeIcon(_ type: ContentChunk.ChunkType) -> some View {
        let (icon, color) = type.iconAndColor
        return Circle()
            .fill(color.opacity(0.2))
            .frame(width: 24, height: 24)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
            )
    }

    // MARK: - Mini Quiz Section
    private var miniQuizSection: some View {
        VStack(spacing: 16) {
            Text("Quick Check")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            if let quiz = miniQuizQuestion {
                miniQuizCard(quiz: quiz)
            } else {
                Button(action: generateMiniQuiz) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Take Mini Quiz")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.orange.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func miniQuizCard(quiz: QuizQuestion) -> some View {
        VStack(spacing: 16) {
            Text(quiz.question)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            ForEach(quiz.answers.indices, id: \.self) { index in
                Button(action: { checkMiniQuizAnswer(index) }) {
                    Text(quiz.answers[index])
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - AI Tutor Question Button
    private var aiTutorQuestionButton: some View {
        Button(action: { showingTutorQuestion = true }) {
            HStack {
                Image(systemName: "message.circle.fill")
                    .font(.system(size: 18))
                Text("Ask AI Tutor")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.purple.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: continueToNextChunk) {
            HStack {
                Text(currentChunkIndex >= contentChunks.count - 1 ? "Complete Lesson" : "Continue")
                    .font(.system(size: 18, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Lesson Complete Card
    private var lessonCompleteCard: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("Lesson Complete!")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)

            Text("Great job! You've mastered this concept.")
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button(action: handleLessonComplete) {
                Text("Continue to Next Lesson")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.green)
                    .cornerRadius(16)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.green.opacity(0.3), lineWidth: 2)
                )
        )
    }

    // MARK: - Animated Lyo Avatar
    private var animatedLyoAvatar: some View {
        HStack(spacing: 16) {
            // Avatar orb with animation
            ZStack {
                // Glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)

                // Main orb
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                // Icon based on state
                Image(systemName: avatarState.iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }

            // Speech bubble
            VStack(alignment: .leading, spacing: 4) {
                Text(avatarState.message)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )

            Spacer()
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Lesson Intro Card
    private func lessonIntroCard(lesson: LessonOutline) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            lessonBadgeView(index: currentLessonIndex)
            lessonTitleView(lesson: lesson)
            lessonDescriptionView(lesson: lesson)
            lessonMetaInfoView(lesson: lesson)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private func lessonBadgeView(index: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.blue)
                .frame(width: 8, height: 8)

            Text("MODULE \(index + 1)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.blue)
                .tracking(1.2)
        }
    }
    
    private func lessonTitleView(lesson: LessonOutline) -> some View {
        Text(lesson.title)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(.white)
    }
    
    private func lessonDescriptionView(lesson: LessonOutline) -> some View {
        Text(lesson.description)
            .font(.system(size: 15))
            .foregroundColor(.white.opacity(0.7))
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func lessonMetaInfoView(lesson: LessonOutline) -> some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.system(size: 14))
                Text("\(lesson.estimatedDuration) min")
                    .font(.system(size: 13, weight: .medium))
            }

            HStack(spacing: 6) {
                Image(systemName: lesson.contentType.iconName)
                    .font(.system(size: 14))
                Text(lesson.contentType.displayName)
                    .font(.system(size: 13, weight: .medium))
            }
        }
        .foregroundColor(.white.opacity(0.6))
    }

    // MARK: - Content Views
    private var textContentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Key concepts
            keyConceptsSection

            // Main explanation
            Text(lessonContent.isEmpty ? "Let's explore this topic together! I'll guide you through each concept step by step..." : lessonContent)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )

            // Quick check button
            quickCheckButton
        }
    }

    private var videoContentView: some View {
        VStack(spacing: 16) {
            // Video placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 220)

                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Interactive Video Lesson")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Watch and learn at your own pace")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            // Video notes
            Text("📝 **Key Points to Watch For:**\n• Fundamental concepts\n• Real-world examples\n• Common mistakes to avoid")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.1))
                )
        }
    }

    private var interactiveContentView: some View {
        VStack(spacing: 16) {
            // Interactive code editor
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 16))
                    Text("Try It Yourself")
                        .font(.system(size: 16, weight: .semibold))

                    Spacer()

                    Button(action: { executeCode() }) {
                        HStack(spacing: 6) {
                            if isExecutingCode {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 12))
                            }
                            Text(isExecutingCode ? "Running..." : "Run")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [.green, .green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                    }
                    .disabled(isExecutingCode)
                }
                .foregroundColor(.white)

                // Code editor (editable)
                TextEditor(text: $codeInput)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.green.opacity(0.9))
                    .padding(16)
                    .frame(minHeight: 120)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(12)
                    .scrollContentBackground(.hidden)

                // Output
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))

                    ScrollView {
                        Text(codeOutput.isEmpty ? "// Run your code to see output" : codeOutput)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(codeOutput.isEmpty ? .white.opacity(0.4) : .white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 60)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.05))
                .cornerRadius(8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    private var quizContentView: some View {
        VStack(spacing: 16) {
            Text("🎯 Knowledge Check")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            quickCheckButton
        }
    }

    // MARK: - Key Concepts Section
    private var keyConceptsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.yellow)

                Text("Key Concepts")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                keyConceptRow(icon: "checkmark.circle.fill", text: "Understanding the fundamentals")
                keyConceptRow(icon: "checkmark.circle.fill", text: "Practical applications")
                keyConceptRow(icon: "checkmark.circle.fill", text: "Common patterns")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.yellow.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func keyConceptRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.green)

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }

    // MARK: - Quick Check Button
    private var quickCheckButton: some View {
        Button(action: {
            showingQuiz = true
            currentQuizQuestion = generateQuizQuestion()
        }) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 18))

                Text("Quick Comprehension Check")
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
    }

    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if currentLessonIndex > 0 {
                Button(action: previousLesson) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Previous")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                    )
                }
            }

            Spacer()

            if let course = course, currentLessonIndex < course.lessons.count - 1 {
                Button(action: nextLesson) {
                    HStack {
                        Text("Next Lesson")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
            }
        }
        .padding(.top, 12)
    }

    // MARK: - Resource Curation Bar (25%)
    private var resourceCurationBar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                Text("Curated Resources")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("Swipe →")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.05))

            // Horizontal scroll of resources
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(resources) { resource in
                        resourceCard(resource)
                    }

                    // Placeholder resources if empty
                    if resources.isEmpty {
                        placeholderResourceCards
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(Color.white.opacity(0.03))
    }

    private func resourceCard(_ resource: CuratedResource) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Icon and type
            HStack {
                Image(systemName: resource.type.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(resource.type.color)

                Spacer()

                Text(resource.type.displayName)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(resource.type.color.opacity(0.2)))
            }

            // Title
            Text(resource.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Source
            Text(resource.source)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            // Action button
            Button("View") {
                // Open resource
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(resource.type.color.opacity(0.3))
            .cornerRadius(8)
        }
        .padding(14)
        .frame(width: 160, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var placeholderResourceCards: some View {
        Group {
            placeholderCard(icon: "book.fill", title: "Python Crash Course", type: "Book", color: .orange)
            placeholderCard(icon: "play.rectangle.fill", title: "Python Tutorial", type: "Video", color: .red)
            placeholderCard(icon: "doc.text.fill", title: "Official Docs", type: "Documentation", color: .blue)
            placeholderCard(icon: "newspaper.fill", title: "Best Practices", type: "Article", color: .green)
        }
    }

    private func placeholderCard(icon: String, title: String, type: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                Spacer()
                Text(type)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(color.opacity(0.2)))
            }

            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            Text("Curated for you")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            Button("View") {
                // Action
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.3))
            .cornerRadius(8)
        }
        .padding(14)
        .frame(width: 160, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Comprehension Check Overlay
    private func comprehensionCheckOverlay(quiz: QuizQuestion) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    showingQuiz = false
                }

            // Quiz card
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Comprehension Check")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        Text("Test your understanding")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button(action: { showingQuiz = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Question
                Text(quiz.question)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.blue.opacity(0.15))
                    )

                // Options
                VStack(spacing: 12) {
                    ForEach(Array(quiz.answers.enumerated()), id: \.offset) { index, option in
                        quizOptionButton(option: option, index: index)
                    }
                }

                Spacer()
            }
            .padding(24)
            .frame(maxWidth: 400, maxHeight: 500)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.1, blue: 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 30)
        }
    }

    private func quizOptionButton(option: String, index: Int) -> some View {
        Button(action: {
            // Check answer
            checkAnswer(selectedIndex: index)
        }) {
            HStack {
                Text(String(UnicodeScalar(65 + index)!))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.blue.opacity(0.3)))

                Text(option)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Adaptive Learning UI Components

    /// Mastery level (theta) indicator
    private var masteryLevelIndicator: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                .frame(width: 32, height: 32)

            Circle()
                .trim(from: 0, to: currentMasteryLevel)
                .stroke(
                    LinearGradient(
                        colors: [.green, .yellow, .orange],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))

            Image(systemName: "brain")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
        }
    }

    /// Adaptive Learning Phase Badge
    private var adaptivePhaseBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: adaptivePhase.iconName)
                .font(.system(size: 12))

            Text(adaptivePhase.displayName)
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(adaptivePhase.color.opacity(0.3))
                .overlay(
                    Capsule()
                        .stroke(adaptivePhase.color, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10)
    }

    /// Adaptive Phase Indicator within content area
    private var adaptivePhaseIndicator: some View {
        HStack(spacing: 12) {
            // Phase indicators
            ForEach(AdaptivePhase.allCases, id: \.self) { phase in
                HStack(spacing: 6) {
                    Circle()
                        .fill(phase == adaptivePhase ? phase.color : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)

                    if phase == adaptivePhase {
                        Text(phase.displayName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }

            Spacer()

            // Mastery text
            Text("Mastery: \(Int(currentMasteryLevel * 100))%")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(masteryColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var masteryColor: Color {
        if currentMasteryLevel < 0.3 {
            return .red
        } else if currentMasteryLevel < 0.7 {
            return .yellow
        } else {
            return .green
        }
    }

    /// Skills Graph Overlay
    private var skillsGraphOverlay: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    showSkillsGraph = false
                }

            // Graph container
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Knowledge Graph")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text("Your learning pathway and mastery levels")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Button(action: { showSkillsGraph = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                // Knowledge Components Graph
                ScrollView {
                    VStack(spacing: 16) {
                        if knowledgeComponents.isEmpty {
                            // Generate sample KCs for demo
                            ForEach(sampleKnowledgeComponents) { kc in
                                knowledgeComponentCard(kc)
                            }
                        } else {
                            ForEach(knowledgeComponents) { kc in
                                knowledgeComponentCard(kc)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
            .frame(maxWidth: 600, maxHeight: 700)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.1, blue: 0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.5), radius: 40)
        }
    }

    private func knowledgeComponentCard(_ kc: KnowledgeComponent) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon
                Image(systemName: kc.iconName)
                    .font(.system(size: 20))
                    .foregroundColor(kc.color)
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(kc.color.opacity(0.2))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(kc.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(kc.alosCompleted)/\(kc.totalAlos) completed")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Mastery level
                VStack(spacing: 4) {
                    Text("\(Int(kc.masteryLevel * 100))%")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(masteryColorForLevel(kc.masteryLevel))

                    Text("θ = \(String(format: "%.2f", kc.masteryLevel))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [kc.color, kc.color.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * kc.masteryLevel)
                }
            }
            .frame(height: 4)
            .cornerRadius(2)

            // Prerequisites
            if !kc.prerequisites.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.left")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))

                    Text("Requires: \(kc.prerequisites.joined(separator: ", "))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(kc.color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func masteryColorForLevel(_ level: Double) -> Color {
        if level < 0.3 {
            return .red
        } else if level < 0.7 {
            return .yellow
        } else {
            return .green
        }
    }

    /// Knowledge Components Section (inline)
    private var knowledgeComponentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)

                Text("Knowledge Components")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Button("View Graph") {
                    showSkillsGraph = true
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.purple)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(knowledgeComponents.prefix(3)) { kc in
                        compactKCCard(kc)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.purple.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func compactKCCard(_ kc: KnowledgeComponent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: kc.iconName)
                .font(.system(size: 18))
                .foregroundColor(kc.color)

            Text(kc.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)

            Text("\(Int(kc.masteryLevel * 100))% mastery")
                .font(.system(size: 11))
                .foregroundColor(masteryColorForLevel(kc.masteryLevel))
        }
        .padding(12)
        .frame(width: 120, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }

    // MARK: - ALO Card Renderers

    /// ALO Explain Card (for text/explanation content)
    private var aloExplainCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ALO Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)

                Text("EXPLAIN")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.blue)
                    .tracking(1.2)

                Spacer()

                Text("ALO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
            }

            // Key concepts
            keyConceptsSection

            // Main explanation
            Text(lessonContent.isEmpty ? "Let's explore this topic together! I'll guide you through each concept step by step..." : lessonContent)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )

            // Quick check button
            quickCheckButton
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 1.5)
                )
        )
    }

    /// ALO Video Card
    private var aloVideoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ALO Header
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.red)

                Text("WATCH")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.red)
                    .tracking(1.2)

                Spacer()

                Text("ALO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
            }

            videoContentView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.red.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1.5)
                )
        )
    }

    /// ALO Exercise Card
    private var aloExerciseCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ALO Header
            HStack {
                Image(systemName: "hammer.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)

                Text("PRACTICE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
                    .tracking(1.2)

                Spacer()

                Text("ALO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
            }

            interactiveContentView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.green.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1.5)
                )
        )
    }

    /// ALO Quiz Card
    private var aloQuizCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // ALO Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.purple)

                Text("ASSESS")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple)
                    .tracking(1.2)

                Spacer()

                Text("ALO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.1)))
            }

            quizContentView
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.purple.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.purple.opacity(0.2), lineWidth: 1.5)
                )
        )
    }

    // MARK: - AI Tutor Question Overlay
    private var aiTutorQuestionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.purple)
                    Text("Ask AI Tutor")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showingTutorQuestion = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Question input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What would you like to know?")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)

                    TextEditor(text: $tutorQuestion)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .padding(12)
                        .frame(height: 100)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .scrollContentBackground(.hidden)
                }

                // Response area
                if !tutorResponse.isEmpty {
                    ScrollView {
                        Text(tutorResponse)
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 150)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: {
                        tutorQuestion = ""
                        tutorResponse = ""
                        showingTutorQuestion = false
                    }) {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                    }

                    Button(action: askTutorQuestion) {
                        HStack {
                            if isWaitingForTutorResponse {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isWaitingForTutorResponse ? "Thinking..." : "Ask Question")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                    .disabled(tutorQuestion.isEmpty || isWaitingForTutorResponse)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Resources Overlay
    private var resourcesOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text("Additional Resources")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { showingResources = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                // Resources list
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(resources) { resource in
                            resourceCard(resource)
                        }

                        if resources.isEmpty {
                            Text("No additional resources available for this lesson.")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.vertical, 40)
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Lesson Content Loading
    private func loadLessonContent() {
        // Update progress first
        updateProgress()

        // Initialize adaptive learning state
        initializeAdaptiveLearningState()

        // Generate progressive lesson content with AI
        Task {
            await generateProgressiveLessonContent()
            
            // Add welcome message to conversation
            await MainActor.run {
                conversation.append(ConversationEntry(
                    type: .aiResponse,
                    content: "Hi! I'm Lyo, your AI tutor. I'm excited to teach you about \(topic). Let's get started! 🚀"
                ))
                
                // Add first content chunk to conversation
                if let firstChunk = contentChunks.first {
                    conversation.append(ConversationEntry(
                        type: .lessonChunk,
                        content: firstChunk.id.uuidString
                    ))
                }
            }
        }
    }

    private func generateProgressiveLessonContent() async {
        guard let course = course, currentLessonIndex < course.lessons.count else { return }

        let currentLesson = course.lessons[currentLessonIndex]
        await MainActor.run {
            avatarState = .thinking
        }

        // Generate progressive chunks instead of single content block
        let prompt = """
        You are Lyo, an expert AI teacher creating engaging, progressive lesson content.
        Break down this lesson into 3-5 smaller chunks that build understanding progressively.

        Topic: \(topic)
        Lesson: \(currentLesson.title)
        Lesson Description: \(currentLesson.description)

        Create 3-5 content chunks with these guidelines:
        1. Each chunk should be 100-200 words
        2. Start with basic concepts and build complexity
        3. Include practical examples
        4. End with a summary or key takeaway
        5. Add mini-quizzes after complex chunks (mark with "QUIZ:true")

        Format each chunk as:
        TYPE: [explanation|example|exercise|summary]
        QUIZ: [true|false]
        CONTENT: [chunk content here]

        ---
        """

        // Simulate AI response with progressive chunks
        let mockChunks = [
            ContentChunk(
                type: .explanation,
                content: """
                Welcome to this lesson on \(topic)! Let's start with the fundamentals.

                \(currentLesson.title) is a crucial concept that builds upon what you've learned so far. At its core, this topic involves understanding how different components work together to achieve a specific goal.

                Think of it like building a house - you need a solid foundation before adding walls and a roof. We'll start with the basic principles and gradually build up to more complex applications.
                """,
                requiresQuiz: false
            ),
            ContentChunk(
                type: .example,
                content: """
                Let's look at a practical example to make this concept clearer.

                Imagine you're trying to \(topic.lowercased()) in a real-world scenario. The key steps would be:

                1. First, identify the core problem or goal
                2. Break it down into manageable components
                3. Apply the principles we've discussed
                4. Test and refine your approach

                This example shows how the theory translates into practice.
                """,
                requiresQuiz: true
            ),
            ContentChunk(
                type: .exercise,
                content: """
                Now it's your turn to practice! Try applying what you've learned.

                Take a moment to think about how you would approach a similar problem in your own work or studies. Consider the key principles and how they interconnect.

                Remember: practice is the best way to solidify your understanding. Don't worry about getting it perfect on the first try - learning is iterative!
                """,
                requiresQuiz: false
            ),
            ContentChunk(
                type: .summary,
                content: """
                Let's review what we've covered in this lesson:

                • The fundamental principles of \(topic)
                • How to apply these concepts in practice
                • Common pitfalls and how to avoid them
                • The importance of iterative learning

                You've made great progress! The next lesson will build on these foundations to help you master more advanced applications.
                """,
                requiresQuiz: false
            )
        ]

        await MainActor.run {
            contentChunks = mockChunks
            currentChunkIndex = 0
            avatarState = .explaining
        }
    }

    private func initializeAdaptiveLearningState() {
        // Initialize with sample knowledge components for demo
        if knowledgeComponents.isEmpty {
            knowledgeComponents = sampleKnowledgeComponents
        }

        // Set initial mastery level based on progress
        currentMasteryLevel = progressPercentage * 0.6 // Simulated mastery

        // Determine adaptive phase based on lesson type
        if let course = course, currentLessonIndex < course.lessons.count {
            let currentLesson = course.lessons[currentLessonIndex]

            switch currentLesson.contentType {
            case .text:
                adaptivePhase = .deliver
            case .video:
                adaptivePhase = .deliver
            case .interactive:
                adaptivePhase = .adapt
            case .quiz:
                adaptivePhase = .evaluate
            }
        }

        print("🧠 [Adaptive] Initialized - Phase: \(adaptivePhase.displayName), Mastery: \(Int(currentMasteryLevel * 100))%")
    }

    private func generateLessonContentWithAI() async {
        guard let course = course, currentLessonIndex < course.lessons.count else { return }

        let currentLesson = course.lessons[currentLessonIndex]
        await MainActor.run {
            avatarState = .thinking
        }

        let prompt = """
        You are Lyo, an expert AI teacher creating engaging lesson content.

        **Topic:** \(topic)
        **Lesson:** \(currentLesson.title)
        **Description:** \(currentLesson.description)
        **Duration:** \(currentLesson.estimatedDuration) minutes
        **Type:** \(currentLesson.contentType.rawValue)

        **Create lesson content that includes:**

        1. **Hook** - Start with an engaging question or real-world example (1-2 sentences)

        2. **Core Explanation** - Explain the concept clearly using:
           - Simple language
           - Real-world analogies
           - Practical examples (with code if relevant to \(topic))
           - Step-by-step breakdown

        3. **Key Insight** - One powerful takeaway (1 sentence)

        4. **Application** - How to use this in practice

        **Style Guidelines:**
        - Use conversational tone
        - Include specific examples
        - Break complex ideas into digestible parts
        - Keep it engaging and practical
        - Use bullet points for clarity

        **Format:** Write as if you're teaching one-on-one. Natural prose, no markdown headers.

        Generate the lesson content now:
        """

        do {
            print("🎓 [Classroom] Generating lesson content for: \(currentLesson.title)")
            let generatedContent = try await AIAvatarAPIClient.shared.generateWithGemini(prompt)

            await MainActor.run {
                lessonContent = generatedContent
                avatarState = .explaining
                print("✅ [Classroom] Lesson content generated successfully")
            }

        } catch {
            print("❌ [Classroom] Failed to generate content: \(error)")
            await MainActor.run {
                lessonContent = """
                **\(currentLesson.title)**

                Welcome to this lesson! Let's explore \(topic) together.

                In this session, we'll cover:
                • The fundamental concepts
                • Practical applications
                • Real-world examples
                • Common patterns and best practices

                \(currentLesson.description)

                Let's dive in and master these concepts step by step!
                """
                avatarState = .explaining
            }
        }
    }

    private func fetchCuratedResources() {
        // Fetch real resources from APIs
        Task {
            await fetchResourcesFromAPIs()
        }
    }

    private func fetchResourcesFromAPIs() async {
        guard let course = course, currentLessonIndex < course.lessons.count else { return }

        let currentLesson = course.lessons[currentLessonIndex]
        let searchQuery = "\(topic) \(currentLesson.title)"

        print("📚 [Resources] Fetching resources for: \(searchQuery)")

        // Fetch from Google Books
        if let books = await fetchGoogleBooks(query: searchQuery) {
            await MainActor.run {
                resources.append(contentsOf: books)
            }
        }

        // Fetch from YouTube
        if let videos = await fetchYouTubeVideos(query: searchQuery) {
            await MainActor.run {
                resources.append(contentsOf: videos)
            }
        }

        print("✅ [Resources] Fetched \(resources.count) resources")
    }

    private func fetchGoogleBooks(query: String) async -> [CuratedResource]? {
        // TODO: Implement Google Books integration
        print("⚠️ [Resources] Google Books not implemented")
        return []
    }

    private func fetchYouTubeVideos(query: String) async -> [CuratedResource]? {
        // TODO: Implement YouTube integration
        print("⚠️ [Resources] YouTube not implemented")
        return []
    }

    private func generateQuizQuestion() -> QuizQuestion {
        // Generate quiz based on actual lesson content
        Task {
            await generateQuizWithAI()
        }

        // Return placeholder while AI generates
        return QuizQuestion(
            question: "What is the main concept we just learned about?",
            answers: [
                "The fundamental principles",
                "Advanced techniques",
                "Common mistakes",
                "Historical context"
            ],
            correctAnswerIndex: 0
        )
    }

    private func generateQuizWithAI() async {
        guard let course = course, currentLessonIndex < course.lessons.count else { return }

        let currentLesson = course.lessons[currentLessonIndex]

        let prompt = """
        You are Lyo, creating a comprehension check quiz.

        **Lesson Content:**
        \(lessonContent)

        **Create ONE multiple-choice question that:**
        1. Tests understanding (not memorization)
        2. Has 4 clear options (A, B, C, D)
        3. Has only ONE correct answer
        4. Is relevant to what was just taught

        **Format your response EXACTLY like this:**
        QUESTION: [Your question here]
        A: [Option A]
        B: [Option B]
        C: [Option C]
        D: [Option D]
        CORRECT: [Letter of correct answer]

        Generate the quiz question now:
        """

        do {
            print("❓ [Quiz] Generating comprehension check...")
            let response = try await AIAvatarAPIClient.shared.generateWithGemini(prompt)

            // Parse the response
            let quiz = parseQuizResponse(response)

            await MainActor.run {
                currentQuizQuestion = quiz
                print("✅ [Quiz] Question generated: \(quiz.question)")
            }

        } catch {
            print("❌ [Quiz] Failed to generate: \(error)")
        }
    }

    private func parseQuizResponse(_ response: String) -> QuizQuestion {
        let lines = response.components(separatedBy: .newlines).filter { !$0.isEmpty }

        var question = "What did we learn?"
        var options: [String] = []
        var correctIndex = 0

        for line in lines {
            if line.starts(with: "QUESTION:") {
                question = line.replacingOccurrences(of: "QUESTION:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.starts(with: "A:") {
                options.append(line.replacingOccurrences(of: "A:", with: "").trimmingCharacters(in: .whitespaces))
            } else if line.starts(with: "B:") {
                options.append(line.replacingOccurrences(of: "B:", with: "").trimmingCharacters(in: .whitespaces))
            } else if line.starts(with: "C:") {
                options.append(line.replacingOccurrences(of: "C:", with: "").trimmingCharacters(in: .whitespaces))
            } else if line.starts(with: "D:") {
                options.append(line.replacingOccurrences(of: "D:", with: "").trimmingCharacters(in: .whitespaces))
            } else if line.starts(with: "CORRECT:") {
                let answer = line.replacingOccurrences(of: "CORRECT:", with: "").trimmingCharacters(in: .whitespaces).uppercased()
                if answer == "A" { correctIndex = 0 }
                else if answer == "B" { correctIndex = 1 }
                else if answer == "C" { correctIndex = 2 }
                else if answer == "D" { correctIndex = 3 }
            }
        }

        if options.count != 4 {
            options = ["Option A", "Option B", "Option C", "Option D"]
        }

        return QuizQuestion(question: question, answers: options, correctAnswerIndex: correctIndex)
    }

    private func checkAnswer(selectedIndex: Int) {
        if selectedIndex == currentQuizQuestion?.correctAnswerIndex {
            avatarState = .celebrating
            // Show success
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingQuiz = false
                avatarState = .explaining
            }
        } else {
            avatarState = .thinking
            // Show hint
        }
    }

    private func previousLesson() {
        if currentLessonIndex > 0 {
            currentLessonIndex -= 1
            
            // Reset conversation and content for new lesson
            conversation.removeAll()
            contentChunks.removeAll()
            currentChunkIndex = 0
            
            loadLessonContent()
            fetchCuratedResources()
            updateProgress()
            
            // Add transition message
            if let course = course {
                let lessonTitle = course.lessons[currentLessonIndex].title
                conversation.append(ConversationEntry(
                    type: .aiResponse,
                    content: "Welcome back to **\(lessonTitle)**! Let's review this together. 📖"
                ))
            }
        }
    }

    private func nextLesson() {
        if let course = course, currentLessonIndex < course.lessons.count - 1 {
            currentLessonIndex += 1
            
            // Reset conversation and content for new lesson
            conversation.removeAll()
            contentChunks.removeAll()
            currentChunkIndex = 0
            
            loadLessonContent()
            fetchCuratedResources()
            saveProgress()
            updateProgress()
            
            // Add transition message
            let lessonTitle = course.lessons[currentLessonIndex].title
            conversation.append(ConversationEntry(
                type: .aiResponse,
                content: "Excellent progress! Let's dive into **\(lessonTitle)**. 🚀"
            ))
        }
    }

    // MARK: - Code Execution
    private func executeCode() {
        isExecutingCode = true
        codeOutput = ""

        Task {
            do {
                // TODO: Implement code execution service
                await MainActor.run {
                    codeOutput = "// Code execution not implemented yet\n// This would run your code and show results"
                    isExecutingCode = false
                }
                print("✅ [CodeExec] Stub execution completed")

            } catch {
                await MainActor.run {
                    codeOutput = "❌ Error: \(error.localizedDescription)"
                    isExecutingCode = false
                }
                print("❌ [CodeExec] Execution failed: \(error)")
            }
        }
    }

    // MARK: - Progress Persistence
    private func saveProgress() {
        guard let course = course else { return }
        let courseId = "\(topic)-\(course.title)"
        LearningProgressService.shared.saveProgress(
            courseId: courseId,
            lessonIndex: currentLessonIndex,
            progress: progressPercentage
        )
    }

    private func loadSavedProgress() {
        guard let course = course else { return }
        let courseId = "\(topic)-\(course.title)"

        if let savedProgress = LearningProgressService.shared.loadProgress(courseId: courseId) {
            currentLessonIndex = savedProgress.currentLessonIndex
            progressPercentage = savedProgress.progressPercentage
            print("📖 [Progress] Restored: Lesson \(currentLessonIndex)")
        }
    }

    // MARK: - Voice Narration
    private func toggleVoice() {
        voiceEnabled.toggle()
        if !voiceEnabled {
            VoiceNarrationService.shared.stop()
        }
    }

    private func speakAvatarMessage() {
        if voiceEnabled {
            VoiceNarrationService.shared.speak(avatarState.message)
        }
    }

    private func speakLessonContent() {
        if voiceEnabled && !lessonContent.isEmpty {
            // Speak first paragraph only
            let firstParagraph = lessonContent.components(separatedBy: "\n\n").first ?? lessonContent
            VoiceNarrationService.shared.speak(firstParagraph)
        }
    }

    // MARK: - Progressive Content Methods
    private var canContinueToNextChunk: Bool {
        if contentChunks.isEmpty { return false }
        if currentChunkIndex >= contentChunks.count { return true } // Lesson complete

        let currentChunk = contentChunks[currentChunkIndex]
        return !currentChunk.requiresQuiz || chunkQuizCompleted(currentChunk)
    }

    private func chunkQuizCompleted(_ chunk: ContentChunk) -> Bool {
        // For now, assume quiz is completed if we've moved past this chunk
        // In a real implementation, you'd track quiz results
        currentChunkIndex > contentChunks.firstIndex(where: { $0.id == chunk.id }) ?? -1
    }

    private func continueToNextChunk() {
        if currentChunkIndex < contentChunks.count - 1 {
            currentChunkIndex += 1
            avatarState = .explaining
            updateProgress()
            
            // Add the next chunk to conversation
            let nextChunk = contentChunks[currentChunkIndex]
            conversation.append(ConversationEntry(
                type: .lessonChunk,
                content: nextChunk.id.uuidString
            ))
        } else {
            // Lesson complete
            handleLessonComplete()
        }
    }

    private func handleLessonComplete() {
        avatarState = .celebrating
        saveProgress()
        // Navigate to next lesson or show completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            nextLesson()
        }
    }

    private func updateProgress() {
        if let course = course {
            let baseProgress = Double(currentLessonIndex) / Double(course.lessons.count)
            let chunkProgress = Double(currentChunkIndex + 1) / Double(max(contentChunks.count, 1))
            let lessonProgress = chunkProgress / Double(course.lessons.count)
            progressPercentage = baseProgress + lessonProgress
        }
    }

    // MARK: - Mini Quiz Methods
    private func generateMiniQuiz() {
        // Generate a simple quiz based on current chunk
        let questions = [
            "What key concept did we just cover?",
            "Can you explain this in your own words?",
            "What's the most important takeaway from this section?"
        ]

        let answers = [
            ["The main concept", "A supporting idea", "An example", "Background information"],
            ["I understand it well", "I need clarification", "I can explain it", "I'm still learning"],
            ["Practice regularly", "Focus on examples", "Ask questions", "Review frequently"]
        ]

        let randomIndex = Int.random(in: 0..<questions.count)
        miniQuizQuestion = QuizQuestion(
            question: questions[randomIndex],
            answers: answers[randomIndex],
            correctAnswerIndex: 0 // Simplified - first answer is always "correct"
        )
        showingMiniQuiz = true
    }

    private func checkMiniQuizAnswer(_ selectedIndex: Int) {
        if let quiz = miniQuizQuestion {
            let isCorrect = selectedIndex == quiz.correctAnswerIndex
            avatarState = isCorrect ? .celebrating : .questioning

            // For now, any answer allows progression
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showingMiniQuiz = false
                miniQuizQuestion = nil
                continueToNextChunk()
            }
        }
    }

    // MARK: - User Input Handler
    private func handleUserInput() {
        guard !userInput.isEmpty else { return }
        
        let message = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add user message to conversation
        conversation.append(ConversationEntry(
            type: .userMessage,
            content: message
        ))
        
        userInput = ""
        isAwaitingAIResponse = true
        isInputFocused = false
        
        Task {
            // Simulate AI thinking time
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Check if user wants to continue or asking a question
            let lowercased = message.lowercased()
            
            // Handle lesson navigation commands
            if lowercased.contains("next lesson") || lowercased == "next lesson" {
                await MainActor.run {
                    isAwaitingAIResponse = false
                    
                    if canGoToNextLesson {
                        conversation.append(ConversationEntry(
                            type: .aiResponse,
                            content: "Absolutely! Let's move on to the next lesson. 🚀"
                        ))
                        nextLesson()
                    } else {
                        conversation.append(ConversationEntry(
                            type: .aiResponse,
                            content: "Great work! You've completed all lessons in this course! 🎓✨"
                        ))
                    }
                }
            } else if lowercased.contains("previous lesson") || lowercased.contains("prev lesson") || lowercased == "go back" {
                await MainActor.run {
                    isAwaitingAIResponse = false
                    
                    if currentLessonIndex > 0 {
                        conversation.append(ConversationEntry(
                            type: .aiResponse,
                            content: "Sure! Let's review the previous lesson. ⏮️"
                        ))
                        previousLesson()
                    } else {
                        conversation.append(ConversationEntry(
                            type: .aiResponse,
                            content: "You're already at the first lesson! There's nothing before this. 😊"
                        ))
                    }
                }
            } else if lowercased.contains("continue") || lowercased.contains("next") || lowercased.contains("go on") {
                // User wants to continue to next chunk
                await MainActor.run {
                    isAwaitingAIResponse = false
                    
                    if currentChunkIndex < contentChunks.count - 1 {
                        conversation.append(ConversationEntry(
                            type: .aiResponse,
                            content: "Great! Let's move on to the next concept. 📚"
                        ))
                        continueToNextChunk()
                    } else {
                        conversation.append(ConversationEntry(
                            type: .aiResponse,
                            content: "Awesome! You've completed this lesson. Ready for the next one? 🎉"
                        ))
                        handleLessonComplete()
                    }
                }
            } else {
                // It's a question - generate dynamic AI response
                let aiResponse = generateDynamicResponse(for: message)
                
                await MainActor.run {
                    conversation.append(ConversationEntry(
                        type: .aiResponse,
                        content: aiResponse
                    ))
                    
                    isAwaitingAIResponse = false
                    
                    // Offer to continue
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        conversation.append(ConversationEntry(
                            type: .aiResponse,
                            content: "Does that help clarify things? Feel free to ask more questions or say 'continue' when you're ready! 💡"
                        ))
                    }
                }
            }
        }
    }
    
    private func generateDynamicResponse(for question: String) -> String {
        let lowercased = question.lowercased()
        
        // Context-aware responses based on current chunk
        if currentChunkIndex < contentChunks.count {
            let currentChunk = contentChunks[currentChunkIndex]
            
            if lowercased.contains("what") || lowercased.contains("explain") {
                return "Great question! Let me break that down for you. In the context of \(topic), this concept means that we're looking at how different elements interact. Think of it like pieces of a puzzle coming together to form a complete picture. The key is understanding each piece individually before seeing the whole."
            } else if lowercased.contains("how") {
                return "Excellent question! The 'how' is really important here. The process involves breaking down the problem into smaller steps, applying the principles we've discussed, and then building up to the solution. It's all about taking it one step at a time!"
            } else if lowercased.contains("why") {
                return "That's a crucial question! The 'why' behind this is that it provides a foundation for everything else we'll learn. Without understanding this concept, the later topics would be much harder to grasp. It's like building a house - you need a solid foundation first!"
            } else if lowercased.contains("example") || lowercased.contains("show") {
                return "Great idea! Let me give you an example. Imagine you're working on a project related to \(topic). You would start by identifying your goal, then break it down into manageable pieces, and apply what you've learned step by step. Does that help illustrate the concept?"
            } else {
                return "That's an interesting question about '\(question)'. Based on what we've covered so far, I'd say the key thing to remember is that practice and repetition help solidify these concepts. The more you engage with the material, the clearer it becomes!"
            }
        }
        
        return "That's a thoughtful question! Let me help you understand this better. The key concept here relates directly to what we're learning about \(topic). Think about how the different pieces connect together!"
    }
    
    // MARK: - AI Tutor Methods
    private func askTutorQuestion() {
        guard !tutorQuestion.isEmpty else { return }

        isWaitingForTutorResponse = true
        avatarState = .thinking

        Task {
            await generateTutorResponse()
        }
    }

    private func generateTutorResponse() async {
        // Simulate AI response generation
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        let responses = [
            "That's a great question! Let me explain...",
            "I see you're curious about this concept. Here's what you need to know...",
            "Excellent question! This is actually a key point...",
            "I'm glad you asked! This helps clarify the concept..."
        ]

        let randomResponse = responses.randomElement() ?? responses[0]

        await MainActor.run {
            tutorResponse = randomResponse + "\n\nBased on your question about '\(tutorQuestion)', I can see you're engaging deeply with the material. This shows great curiosity and will help you master the subject more effectively."
            isWaitingForTutorResponse = false
            avatarState = .explaining
        }
    }
}

// MARK: - Stub Services (Temporary implementations for compilation)
class LearningProgressService {
    static let shared = LearningProgressService()

    func saveProgress(courseId: String, lessonIndex: Int, progress: Double) {
        // Stub implementation - does nothing
        print("📖 [Progress Stub] Saved: course=\(courseId), lesson=\(lessonIndex), progress=\(progress)")
    }

    func loadProgress(courseId: String) -> (currentLessonIndex: Int, progressPercentage: Double)? {
        // Stub implementation - returns nil
        print("📖 [Progress Stub] Load requested for: \(courseId)")
        return nil
    }
}

class VoiceNarrationService {
    static let shared = VoiceNarrationService()

    func speak(_ text: String) {
        // Stub implementation - does nothing
        print("🗣️ [Voice Stub] Would speak: \(text.prefix(50))...")
    }

    func stop() {
        // Stub implementation - does nothing
        print("🗣️ [Voice Stub] Stopped speaking")
    }
}

// MARK: - Supporting Types

struct ContentChunk: Identifiable {
    let id = UUID()
    let type: ChunkType
    let content: String
    let requiresQuiz: Bool

    enum ChunkType {
        case explanation, example, exercise, summary

        var displayName: String {
            switch self {
            case .explanation: return "Explanation"
            case .example: return "Example"
            case .exercise: return "Practice"
            case .summary: return "Summary"
            }
        }

        var iconAndColor: (String, Color) {
            switch self {
            case .explanation: return ("book.fill", .blue)
            case .example: return ("lightbulb.fill", .yellow)
            case .exercise: return ("hammer.fill", .orange)
            case .summary: return ("checkmark.circle.fill", .green)
            }
        }
    }
}

enum ClassroomAvatarState {
    case explaining, thinking, celebrating, questioning

    var iconName: String {
        switch self {
        case .explaining: return "sparkles"
        case .thinking: return "brain.head.profile"
        case .celebrating: return "party.popper.fill"
        case .questioning: return "questionmark.bubble"
        }
    }

    var message: String {
        switch self {
        case .explaining:
            return "Let me guide you through this concept..."
        case .thinking:
            return "Hmm, let's think about this together..."
        case .celebrating:
            return "🎉 Excellent! You've got this!"
        case .questioning:
            return "Can you explain this in your own words?"
        }
    }
}

struct CuratedResource: Identifiable {
    let id = UUID()
    let type: ResourceType
    let title: String
    let source: String
    let url: String
}

enum ResourceType {
    case book, video, article, documentation, interactive

    var iconName: String {
        switch self {
        case .book: return "book.fill"
        case .video: return "play.rectangle.fill"
        case .article: return "newspaper.fill"
        case .documentation: return "doc.text.fill"
        case .interactive: return "play.circle.fill"
        }
    }

    var displayName: String {
        switch self {
        case .book: return "Book"
        case .video: return "Video"
        case .article: return "Article"
        case .documentation: return "Docs"
        case .interactive: return "Interactive"
        }
    }

    var color: Color {
        switch self {
        case .book: return .orange
        case .video: return .red
        case .article: return .green
        case .documentation: return .blue
        case .interactive: return .purple
        }
    }
}



// MARK: - Adaptive Learning Data Models

/// Adaptive Learning Phase (Assess → Adapt → Deliver → Evaluate)
enum AdaptivePhase: String, CaseIterable, Hashable {
    case assess = "Assess"
    case adapt = "Adapt"
    case deliver = "Deliver"
    case evaluate = "Evaluate"

    var displayName: String { rawValue }

    var iconName: String {
        switch self {
        case .assess: return "magnifyingglass"
        case .adapt: return "slider.horizontal.3"
        case .deliver: return "book.fill"
        case .evaluate: return "checkmark.seal.fill"
        }
    }

    var color: Color {
        switch self {
        case .assess: return .blue
        case .adapt: return .purple
        case .deliver: return .green
        case .evaluate: return .orange
        }
    }
}

/// Knowledge Component (KC) - A unit of knowledge in the skills graph
struct KnowledgeComponent: Identifiable {
    let id = UUID()
    let name: String
    let masteryLevel: Double // 0.0 to 1.0 (theta)
    let prerequisites: [String]
    let totalAlos: Int
    let alosCompleted: Int
    let iconName: String
    let color: Color

    init(
        name: String,
        masteryLevel: Double,
        prerequisites: [String] = [],
        totalAlos: Int = 5,
        alosCompleted: Int = 0,
        iconName: String = "circle.fill",
        color: Color = .blue
    ) {
        self.name = name
        self.masteryLevel = masteryLevel
        self.prerequisites = prerequisites
        self.totalAlos = totalAlos
        self.alosCompleted = alosCompleted
        self.iconName = iconName
        self.color = color
    }
}

/// ALO Card - Atomic Learning Object
struct ALOCard: Identifiable {
    let id = UUID()
    let type: ALOType
    let title: String
    let content: String
    let difficulty: Double // 0.0 to 1.0

    enum ALOType {
        case explain, example, exercise, quiz, project
    }
}

/// Sample Knowledge Components for demo
private var sampleKnowledgeComponents: [KnowledgeComponent] {
    [
        KnowledgeComponent(
            name: "Basic Syntax",
            masteryLevel: 0.85,
            prerequisites: [],
            totalAlos: 4,
            alosCompleted: 3,
            iconName: "character.cursor.ibeam",
            color: .blue
        ),
        KnowledgeComponent(
            name: "Variables & Types",
            masteryLevel: 0.72,
            prerequisites: ["Basic Syntax"],
            totalAlos: 5,
            alosCompleted: 4,
            iconName: "number.square",
            color: .green
        ),
        KnowledgeComponent(
            name: "Control Flow",
            masteryLevel: 0.45,
            prerequisites: ["Variables & Types"],
            totalAlos: 6,
            alosCompleted: 2,
            iconName: "arrow.triangle.branch",
            color: .orange
        ),
        KnowledgeComponent(
            name: "Functions",
            masteryLevel: 0.20,
            prerequisites: ["Control Flow"],
            totalAlos: 7,
            alosCompleted: 1,
            iconName: "function",
            color: .purple
        ),
        KnowledgeComponent(
            name: "Classes & Objects",
            masteryLevel: 0.0,
            prerequisites: ["Functions"],
            totalAlos: 8,
            alosCompleted: 0,
            iconName: "cube.box",
            color: .red
        )
    ]
}

// MARK: - Conversation Entry Model
struct ConversationEntry: Identifiable, Equatable {
    let id = UUID()
    let type: EntryType
    let content: String
    
    enum EntryType: Equatable {
        case userMessage
        case aiResponse
        case lessonChunk
    }
}

// MARK: - Corner Radius Helper
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - LessonContentType Extension
extension LessonContentType {
    var iconName: String {
        switch self {
        case .text: return "doc.text"
        case .video: return "play.rectangle"
        case .interactive: return "hand.tap"
        case .quiz: return "questionmark.circle"
        }
    }
}

// MARK: - Preview
#Preview {
    EnhancedAIClassroomView(
        topic: "Python Programming",
        course: CourseOutlineLocal(
            title: "Python Fundamentals",
            description: "Learn Python from scratch",
            lessons: [
                LessonOutline(title: "Introduction", description: "Getting started", contentType: .text, estimatedDuration: 15),
                LessonOutline(title: "Variables", description: "Learn about variables", contentType: .interactive, estimatedDuration: 20)
            ]
        ),
        onExit: {}
    )
}
