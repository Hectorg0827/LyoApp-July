import SwiftUI
import Combine

struct EnhancedAIClassroomView: View {
    @StateObject private var viewModel: EnhancedAIClassroomViewModel
    @State private var showComprehensionCheck = false
    @State private var showSummary = false
    @State private var showSkillsGraph = false
    @State private var showSideDrawer = false
    @State private var userInput: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    init(courseOutline: CourseOutlineLocal) {
        _viewModel = StateObject(wrappedValue: EnhancedAIClassroomViewModel(courseOutline: courseOutline))
    }

    var body: some View {
        ZStack {
            DesignTokens.colors.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                minimalistHeader
                
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: DesignTokens.spacing.medium) {
                            ForEach(viewModel.conversationHistory) { entry in
                                conversationEntryView(entry)
                                    .id(entry.id)
                            }
                        }
                        .padding(.horizontal, DesignTokens.spacing.medium)
                        .padding(.top, DesignTokens.spacing.small)
                    }
                    .onChange(of: viewModel.conversationHistory.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }
                
                bottomInteractionBar
            }
            .navigationBarHidden(true)
            .blur(radius: showComprehensionCheck || showSummary || showSkillsGraph ? 20 : 0)
            .disabled(showComprehensionCheck || showSummary || showSkillsGraph)

            if showComprehensionCheck {
                comprehensionCheckOverlay
            }
            
            if showSummary {
                summaryOverlay
            }

            if showSkillsGraph {
                skillsGraphOverlay
            }
            
            if showSideDrawer {
                sideDrawer
            }
        }
        .onAppear {
            viewModel.startLesson()
        }
    }

    private var minimalistHeader: some View {
        HStack {
            Button(action: {
                // Action for back button
            }) {
                Image(systemName: "arrow.left")
                    .font(DesignTokens.font.body)
                    .foregroundColor(DesignTokens.colors.textColor)
            }
            .accessibilityLabel("Back")
            .accessibilityHint("Returns to the previous screen")

            Spacer()
            
            Text(viewModel.courseOutline.title)
                .font(DesignTokens.font.headline)
                .foregroundColor(DesignTokens.colors.textColor)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button(action: { withAnimation { showSideDrawer.toggle() } }) {
                Image(systemName: "ellipsis")
                    .font(DesignTokens.font.body)
                    .foregroundColor(DesignTokens.colors.textColor)
            }
            .accessibilityLabel("Options")
            .accessibilityHint("Opens the lesson options menu")
        }
        .padding(DesignTokens.spacing.medium)
        .background(DesignTokens.colors.backgroundColor.opacity(0.8))
    }

    private func conversationEntryView(_ entry: ConversationEntry) -> some View {
        HStack(alignment: .top, spacing: DesignTokens.spacing.small) {
            if entry.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(DesignTokens.colors.accentColor)
                    .frame(width: 30, height: 30)
                    .accessibilityLabel("AI Assistant")
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.spacing.small) {
                ForEach(entry.content) { chunk in
                    switch chunk.type {
                    case .explanation:
                        explanationChunkView(chunk.text)
                    case .example:
                        exampleChunkView(chunk.text)
                    case .exercise:
                        exerciseChunkView(chunk.text)
                    case .summary:
                        summaryChunkView(chunk.text)
                    }
                }
            }
            .padding(DesignTokens.spacing.medium)
            .background(entry.role == .assistant ? DesignTokens.colors.secondaryBackgroundColor : Color.clear)
            .cornerRadius(DesignTokens.cornerRadius.large)
            
            if entry.role == .user {
                Spacer()
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(DesignTokens.colors.textColor)
                    .frame(width: 30, height: 30)
                    .accessibilityLabel("User")
            }
        }
    }

    private func explanationChunkView(_ text: String) -> some View {
        Text(text)
            .font(DesignTokens.font.body)
            .foregroundColor(DesignTokens.colors.textColor)
            .lineSpacing(DesignTokens.spacing.xsmall)
            .accessibilityLabel("Explanation")
            .accessibilityValue(text)
    }

    private func exampleChunkView(_ text: String) -> some View {
        VStack(alignment: .leading) {
            Text("Example")
                .font(DesignTokens.font.caption)
                .foregroundColor(DesignTokens.colors.accentColor)
                .padding(.bottom, DesignTokens.spacing.xxsmall)
            Text(text)
                .font(DesignTokens.font.code)
                .foregroundColor(DesignTokens.colors.textColor)
                .padding(DesignTokens.spacing.small)
                .background(DesignTokens.colors.backgroundColor)
                .cornerRadius(DesignTokens.cornerRadius.medium)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Code Example")
        .accessibilityValue(text)
    }

    private func exerciseChunkView(_ text: String) -> some View {
        VStack(alignment: .leading) {
            Text("Exercise")
                .font(DesignTokens.font.caption)
                .foregroundColor(DesignTokens.colors.accentColor)
                .padding(.bottom, DesignTokens.spacing.xxsmall)
            Text(text)
                .font(DesignTokens.font.body)
                .foregroundColor(DesignTokens.colors.textColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exercise")
        .accessibilityValue(text)
    }
    
    private func summaryChunkView(_ text: String) -> some View {
        VStack(alignment: .leading) {
            Text("Summary")
                .font(DesignTokens.font.caption)
                .foregroundColor(DesignTokens.colors.accentColor)
                .padding(.bottom, DesignTokens.spacing.xxsmall)
            Text(text)
                .font(DesignTokens.font.body)
                .foregroundColor(DesignTokens.colors.textColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Summary")
        .accessibilityValue(text)
    }

    private var bottomInteractionBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: DesignTokens.spacing.medium) {
                Button(action: { withAnimation { showComprehensionCheck.toggle() } }) {
                    Label("Check", systemImage: "questionmark.circle")
                }
                .buttonStyle(CapsuleButtonStyle(backgroundColor: DesignTokens.colors.accentColor, foregroundColor: Color.white))
                .accessibilityHint("Check your understanding of the lesson")

                Button(action: { withAnimation { showSummary.toggle() } }) {
                    Label("Summary", systemImage: "doc.text")
                }
                .buttonStyle(CapsuleButtonStyle(backgroundColor: DesignTokens.colors.accentColor, foregroundColor: Color.white))
                .accessibilityHint("View a summary of the lesson")

                Button(action: { withAnimation { showSkillsGraph.toggle() } }) {
                    Label("Skills", systemImage: "chart.bar")
                }
                .buttonStyle(CapsuleButtonStyle(backgroundColor: DesignTokens.colors.accentColor, foregroundColor: Color.white))
                .accessibilityHint("View your skills graph")
            }
            .padding(.vertical, DesignTokens.spacing.small)

            HStack(spacing: DesignTokens.spacing.small) {
                TextField("Ask a question...", text: $userInput)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(DesignTokens.spacing.small)
                    .background(DesignTokens.colors.secondaryBackgroundColor)
                    .cornerRadius(DesignTokens.cornerRadius.large)
                    .focused($isTextFieldFocused)
                    .accessibilityLabel("Question input")
                    .accessibilityHint("Type your question about the lesson here")

                Button(action: {
                    viewModel.send(message: userInput)
                    userInput = ""
                    isTextFieldFocused = false
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(DesignTokens.colors.accentColor)
                }
                .disabled(userInput.isEmpty)
                .accessibilityLabel("Send")
                .accessibilityHint("Sends your question to the AI assistant")
            }
            .padding(DesignTokens.spacing.medium)
        }
        .background(DesignTokens.colors.backgroundColor.opacity(0.9))
    }

    private var sideDrawer: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: DesignTokens.spacing.large) {
                Text("Lesson Options")
                    .font(DesignTokens.font.title)
                    .foregroundColor(DesignTokens.colors.textColor)
                
                Button("Restart Lesson") {
                    viewModel.restartLesson()
                    withAnimation { showSideDrawer = false }
                }
                .buttonStyle(SideDrawerButtonStyle())
                .accessibilityHint("Restarts the current lesson from the beginning")

                Button("View Course Outline") {
                    // Action to view course outline
                    withAnimation { showSideDrawer = false }
                }
                .buttonStyle(SideDrawerButtonStyle())
                .accessibilityHint("Shows the full outline for this course")

                Spacer()
            }
            .padding(DesignTokens.spacing.large)
            .frame(width: 300)
            .background(DesignTokens.colors.secondaryBackgroundColor)
            .transition(.move(edge: .trailing))
            .onTapGesture {
                // To prevent taps from passing through
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.5))
        .onTapGesture {
            withAnimation { showSideDrawer = false }
        }
    }

    private var comprehensionCheckOverlay: some View {
        VStack {
            Text("Comprehension Check")
                .font(DesignTokens.font.title)
                .foregroundColor(DesignTokens.colors.textColor)
                .padding()

            Text(viewModel.comprehensionQuestion)
                .font(DesignTokens.font.body)
                .foregroundColor(DesignTokens.colors.textColor)
                .multilineTextAlignment(.center)
                .padding()

            Button("Got it!") {
                withAnimation { showComprehensionCheck = false }
            }
            .buttonStyle(CapsuleButtonStyle(backgroundColor: DesignTokens.colors.accentColor, foregroundColor: Color.white))
            .padding()
        }
        .frame(maxWidth: .infinity)
        .padding(DesignTokens.spacing.large)
        .background(DesignTokens.colors.secondaryBackgroundColor)
        .cornerRadius(DesignTokens.cornerRadius.large)
        .shadow(radius: 10)
        .padding(.horizontal, DesignTokens.spacing.large)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Comprehension Check")
        .accessibilityAddTraits(.isModal)
    }
    
    private var summaryOverlay: some View {
        VStack {
            Text("Lesson Summary")
                .font(DesignTokens.font.title)
                .foregroundColor(DesignTokens.colors.textColor)
                .padding()

            ScrollView {
                Text(viewModel.lessonSummary)
                    .font(DesignTokens.font.body)
                    .foregroundColor(DesignTokens.colors.textColor)
                    .padding()
            }

            Button("Close") {
                withAnimation { showSummary = false }
            }
            .buttonStyle(CapsuleButtonStyle(backgroundColor: DesignTokens.colors.accentColor, foregroundColor: Color.white))
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
        .padding(DesignTokens.spacing.large)
        .background(DesignTokens.colors.secondaryBackgroundColor)
        .cornerRadius(DesignTokens.cornerRadius.large)
        .shadow(radius: 10)
        .padding(.horizontal, DesignTokens.spacing.large)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Lesson Summary")
        .accessibilityAddTraits(.isModal)
    }
    
    private var skillsGraphOverlay: some View {
        VStack {
            Text("Skills Graph")
                .font(DesignTokens.font.title)
                .foregroundColor(DesignTokens.colors.textColor)
                .padding()

            // Placeholder for skills graph view
            Text("Skills graph will be displayed here.")
                .font(DesignTokens.font.body)
                .foregroundColor(DesignTokens.colors.textColor)
                .padding()

            Button("Close") {
                withAnimation { showSkillsGraph = false }
            }
            .buttonStyle(CapsuleButtonStyle(backgroundColor: DesignTokens.colors.accentColor, foregroundColor: Color.white))
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: 500)
        .padding(DesignTokens.spacing.large)
        .background(DesignTokens.colors.secondaryBackgroundColor)
        .cornerRadius(DesignTokens.cornerRadius.large)
        .shadow(radius: 10)
        .padding(.horizontal, DesignTokens.spacing.large)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Skills Graph")
        .accessibilityAddTraits(.isModal)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastEntry = viewModel.conversationHistory.last {
            withAnimation {
                proxy.scrollTo(lastEntry.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - View Models and Data Structures

class EnhancedAIClassroomViewModel: ObservableObject {
    @Published var conversationHistory: [ConversationEntry] = []
    @Published var comprehensionQuestion: String = "This is a sample comprehension question to check your understanding."
    @Published var lessonSummary: String = "This is a summary of the lesson content covered so far."
    
    let courseOutline: CourseOutlineLocal
    private var cancellables = Set<AnyCancellable>()
    private var currentChunkIndex = 0

    init(courseOutline: CourseOutlineLocal) {
        self.courseOutline = courseOutline
    }

    func startLesson() {
        let initialMessage = "Welcome to your lesson on \(courseOutline.title). Let's begin!"
        let initialEntry = ConversationEntry(role: .assistant, content: [ContentChunk(type: .explanation, text: initialMessage)])
        conversationHistory.append(initialEntry)
        
        // Simulate receiving lesson content
        DispatchQueue
                .lineSpacing(6)
                .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.95))
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .fill(DesignTokens.Colors.neutral900.opacity(0.3))
                )
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .glassEffect(DesignTokens.Glass.frostedLayer)
        )
        .shadow(color: DesignTokens.Colors.warning.opacity(0.15), radius: 20, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example: \(chunk.content)")
    }
    
    private func exerciseChunkView(chunk: ContentChunk) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Circle()
                    .fill(LinearGradient(colors: [DesignTokens.Colors.neonPurple.opacity(0.6), DesignTokens.Colors.neonPink.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    )
                    .shadow(color: DesignTokens.Colors.neonPurple.opacity(0.4), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Practice Exercise")
                        .font(DesignTokens.Typography.titleLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Text("Test your understanding")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.neonPurple.opacity(0.8))
                }
                
                Spacer()
            }
            
            Text(chunk.content)
                .font(DesignTokens.Typography.bodyLarge)
                .lineSpacing(8)
                .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.95))
            
            interactiveContentView
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .glassEffect(DesignTokens.Glass.frostedLayer)
        )
        .shadow(color: DesignTokens.Colors.neonPurple.opacity(0.15), radius: 20, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Exercise: \(chunk.content)")
    }
    
    private func summaryChunkView(chunk: ContentChunk) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
            HStack(spacing: DesignTokens.Spacing.md) {
                Circle()
                    .fill(LinearGradient(colors: [DesignTokens.Colors.success.opacity(0.6), DesignTokens.Colors.neonGreen.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    )
                    .shadow(color: DesignTokens.Colors.success.opacity(0.4), radius: 8, y: 4)
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Key Takeaways")
                        .font(DesignTokens.Typography.titleLarge)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Text("What you've learned")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.success.opacity(0.8))
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                ForEach(chunk.content.components(separatedBy: "•").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, id: \.self) { point in
                    HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(DesignTokens.Colors.success)
                        Text(point.trimmingCharacters(in: .whitespacesAndNewlines))
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.95))
                        Spacer()
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                .glassEffect(DesignTokens.Glass.frostedLayer)
        )
        .shadow(color: DesignTokens.Colors.success.opacity(0.15), radius: 20, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Summary: \(chunk.content)")
    }
    
    // MARK: - Bottom Interaction Bar
    private var bottomInteractionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LinearGradient(colors: [DesignTokens.Colors.neutral700.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 1)
            
            HStack(spacing: DesignTokens.Spacing.md) {
                Button(action: {
                    withAnimation(DesignTokens.Animations.snappy) { isRecording.toggle() }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                isRecording
                                ? LinearGradient(colors: [DesignTokens.Colors.error, DesignTokens.Colors.neonOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [DesignTokens.Colors.neutral700, DesignTokens.Colors.neutral800], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .frame(width: 44, height: 44)
                        
                        if isRecording {
                            Circle()
                                .stroke(DesignTokens.Colors.error.opacity(0.5), lineWidth: 2)
                                .frame(width: 50, height: 50)
                                .scaleEffect(1.2)
                                .opacity(0)
                                .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: isRecording)
                        }
                        
                        Image(systemName: isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(isRecording ? .white : DesignTokens.Colors.textSecondary)
                    }
                }
                .accessibilityLabel(isRecording ? "Stop recording" : "Start voice input")
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    TextField("Ask anything or say 'continue'...", text: $userInput)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit(handleUserInput)
                    
                    if !userInput.isEmpty {
                        Button(action: { userInput = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(DesignTokens.Colors.textTertiary)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityLabel("Clear text input")
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.round, style: .continuous)
                        .fill(DesignTokens.Colors.neutral800)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.round, style: .continuous)
                                .stroke(DesignTokens.Colors.neutral600, lineWidth: 1)
                        )
                )
                
                Button(action: handleUserInput) {
                    ZStack {
                        Circle()
                            .fill(
                                (userInput.isEmpty && !isAwaitingAIResponse)
                                ? LinearGradient(colors: [DesignTokens.Colors.neutral700, DesignTokens.Colors.neutral800], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : DesignTokens.Colors.brandGradient
                            )
                            .frame(width: 44, height: 44)
                            .shadow(
                                color: userInput.isEmpty ? .clear : DesignTokens.Colors.brand.opacity(0.4),
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
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(
            DesignTokens.Colors.backgroundSecondary.opacity(0.95)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Side Drawer
    private var sideDrawer: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
                HStack {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                        Text("Course Settings")
                            .font(DesignTokens.Typography.headlineSmall)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Text(topic)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { withAnimation(DesignTokens.Animations.snappy) { isDrawerOpen = false } }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(DesignTokens.Colors.neutral800))
                    }
                    .accessibilityLabel("Close settings")
                }
                .padding(.top, DesignTokens.Spacing.lg)
                
                Divider().background(DesignTokens.Colors.neutral700)
                
                if let course = course {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        Text("Lesson Progress")
                            .font(DesignTokens.Typography.titleMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("Lesson \(currentLessonIndex + 1) of \(course.lessons.count)")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                            .fill(DesignTokens.Colors.neutral800)
                    )
                }
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text("Preferences")
                        .font(DesignTokens.Typography.titleMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Toggle(isOn: $voiceEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(DesignTokens.Colors.neonBlue)
                            Text("Voice Narration")
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }
                    }
                    .tint(DesignTokens.Colors.neonBlue)
                    
                    Toggle(isOn: $showSkillsGraph) {
                        HStack {
                            Image(systemName: "brain.head.profile")
                                .foregroundColor(DesignTokens.Colors.neonPurple)
                            Text("Skills Graph")
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                        }
                    }
                    .tint(DesignTokens.Colors.neonPurple)
                }
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                        .fill(DesignTokens.Colors.neutral800)
                )
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    Text("Additional Resources")
                        .font(DesignTokens.Typography.titleMedium)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    if resources.isEmpty {
                        Text("No resources available yet")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                            .padding()
                    } else {
                        ForEach(resources.prefix(3)) { resource in
                            compactResourceCard(resource)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .frame(width: 320)
        .background(
            DesignTokens.Colors.backgroundElevated
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
    
    private func compactResourceCard(_ resource: CuratedResource) -> some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: resource.type.iconName)
                .font(.system(size: 20))
                .foregroundColor(resource.type.color)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .fill(resource.type.color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(resource.title)
                    .font(DesignTokens.Typography.labelLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(resource.source)
                    .font(DesignTokens.Typography.labelSmall)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md, style: .continuous)
                .fill(DesignTokens.Colors.neutral800.opacity(0.5))
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(resource.type.rawValue) resource: \(resource.title) from \(resource.source)")
    }
    
    // MARK: - Comprehension Check Overlay
    private func comprehensionCheckOverlay(quiz: QuizQuestion) -> some View {
        ZStack {
            DesignTokens.Colors.backgroundPrimary.opacity(0.8)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on tap
                }

            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Comprehension Check")
                    .font(DesignTokens.Typography.titleLarge)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                Text(quiz.question)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(quiz.answers.indices, id: \.self) { index in
                        Button(action: { checkAnswer(index) }) {
                            Text(quiz.answers[index])
                                .font(DesignTokens.Typography.buttonLabel)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg, style: .continuous)
                                        .glassEffect(DesignTokens.Glass.interactiveLayer)
                                )
                        }
                        .accessibilityLabel("Answer: \(quiz.answers[index])")
                    }
                }
                .padding(.horizontal)
            }
            .padding(DesignTokens.Spacing.xxl)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl, style: .continuous)
                    .glassEffect(DesignTokens.Glass.frostedLayer)
            )
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .transition(.scale.combined(with: .opacity))
        }
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel("Comprehension Check. Question: \(quiz.question)")
    }

    // MARK: - Teaching Area (DEPRECATED - Replaced by Conversation Flow)
    /*
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
    */

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
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Placeholder for different interactive types
            switch currentInteractiveType {
            case .codeEditor:
                codeEditorView
            case .multipleChoice:
                multipleChoiceView
            case .fillInTheBlank:
                fillInTheBlankView
            }
            
            // Submit / Check Answer Button
            Button(action: checkInteractiveAnswer) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check Answer")
                }
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.brandGradient)
                .cornerRadius(DesignTokens.Radius.button)
                .shadow(color: DesignTokens.Colors.brand.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(isInteractiveAnswerCorrect)
            .accessibilityLabel("Check your answer")
            
            // Feedback
            if let feedback = interactiveFeedback {
                Text(feedback)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(isInteractiveAnswerCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill((isInteractiveAnswerCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error).opacity(0.1))
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    private var codeEditorView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Your turn to code:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            TextEditor(text: $interactiveCodeInput)
                .font(DesignTokens.Typography.techLabel)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(DesignTokens.Spacing.md)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.neutral900)
                )
                .cornerRadius(DesignTokens.Radius.md)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Code editor. Type your code here.")
    }
    
    private var multipleChoiceView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Choose the correct option:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            ForEach(0..<4) { index in
                Button(action: { interactiveSelectedOption = index }) {
                    HStack {
                        Text("Option \(index + 1)")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Spacer()
                        if interactiveSelectedOption == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignTokens.Colors.success)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(interactiveSelectedOption == index ? DesignTokens.Colors.success.opacity(0.1) : DesignTokens.Colors.neutral800)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .stroke(interactiveSelectedOption == index ? DesignTokens.Colors.success : DesignTokens.Colors.neutral600, lineWidth: 1.5)
                            )
                    )
                }
                .accessibilityLabel("Option \(index + 1)")
            }
        }
    }
    
    private var fillInTheBlankView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Fill in the missing word:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            HStack {
                Text("The quick brown fox jumps over the lazy")
                    .font(DesignTokens.Typography.bodyLarge)
                
                TextField("word", text: $interactiveBlankInput)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.neonBlue)
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        Rectangle()
                            .fill(DesignTokens.Colors.neonBlue.opacity(0.1))
                            .frame(height: 2)
                        , alignment: .bottom
                    )
                    .frame(width: 80)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fill in the blank. The quick brown fox jumps over the lazy [input field].")
    }
    
    // MARK: - Helper Functions
    // MARK: - Skills Graph View
    private var skillsGraphView: some View {
        ZStack {
            // Background and Grid
            DesignTokens.Colors.backgroundPrimary.ignoresSafeArea()
            
            // Radial Gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [DesignTokens.Colors.neonPurple.opacity(0.2), .clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
            
            // Grid Lines
            ForEach(0..<5) { i in
                Circle()
                    .stroke(DesignTokens.Colors.neutral700.opacity(0.5), lineWidth: 1)
                    .frame(width: CGFloat(i + 1) * 100, height: CGFloat(i + 1) * 100)
            }
            
            // Skill Nodes
            if let course = course {
                ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                    let angle = (2 * .pi / Double(course.lessons.count)) * Double(index)
                    let radius = 200.0
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.neutral800)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            masteryLevels[lesson.id] ?? 0 > 0.7 ? DesignTokens.Colors.neonPurple : DesignTokens.Colors.neutral600,
                                            lineWidth: 2
                                        )
                                )
                            
                            Image(systemName: lesson.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(masteryLevels[lesson.id] ?? 0 > 0.7 ? DesignTokens.Colors.neonPurple : DesignTokens.Colors.textTertiary)
                            
                            Circle()
                                .trim(from: 0, to: masteryLevels[lesson.id] ?? 0)
                                .stroke(DesignTokens.Colors.neonPurple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 58, height: 58)
                                .rotationEffect(.degrees(-90))
                                .animation(DesignTokens.Animations.smooth, value: masteryLevels[lesson.id])
                        }
                        
                        Text(lesson.title)
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                    }
                    .offset(x: x, y: y)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Skill: \(lesson.title). Mastery: \(Int((masteryLevels[lesson.id] ?? 0) * 100)) percent.")
                }
            }
            
            // Central "Brain"
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.neonPurple)
                    .shadow(color: DesignTokens.Colors.neonPurple.opacity(0.5), radius: 15)
                
                Text("Mastery Map")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(topic)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Mastery Map for \(topic)")
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helper Functions
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
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Placeholder for different interactive types
            switch currentInteractiveType {
            case .codeEditor:
                codeEditorView
            case .multipleChoice:
                multipleChoiceView
            case .fillInTheBlank:
                fillInTheBlankView
            }
            
            // Submit / Check Answer Button
            Button(action: checkInteractiveAnswer) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check Answer")
                }
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.brandGradient)
                .cornerRadius(DesignTokens.Radius.button)
                .shadow(color: DesignTokens.Colors.brand.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(isInteractiveAnswerCorrect)
            .accessibilityLabel("Check your answer")
            
            // Feedback
            if let feedback = interactiveFeedback {
                Text(feedback)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(isInteractiveAnswerCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill((isInteractiveAnswerCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error).opacity(0.1))
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    private var codeEditorView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Your turn to code:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            TextEditor(text: $interactiveCodeInput)
                .font(DesignTokens.Typography.techLabel)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(DesignTokens.Spacing.md)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.neutral900)
                )
                .cornerRadius(DesignTokens.Radius.md)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Code editor. Type your code here.")
    }
    
    private var multipleChoiceView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Choose the correct option:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            ForEach(0..<4) { index in
                Button(action: { interactiveSelectedOption = index }) {
                    HStack {
                        Text("Option \(index + 1)")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Spacer()
                        if interactiveSelectedOption == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignTokens.Colors.success)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(interactiveSelectedOption == index ? DesignTokens.Colors.success.opacity(0.1) : DesignTokens.Colors.neutral800)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .stroke(interactiveSelectedOption == index ? DesignTokens.Colors.success : DesignTokens.Colors.neutral600, lineWidth: 1.5)
                            )
                    )
                }
                .accessibilityLabel("Option \(index + 1)")
            }
        }
    }
    
    private var fillInTheBlankView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Fill in the missing word:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            HStack {
                Text("The quick brown fox jumps over the lazy")
                    .font(DesignTokens.Typography.bodyLarge)
                
                TextField("word", text: $interactiveBlankInput)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.neonBlue)
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        Rectangle()
                            .fill(DesignTokens.Colors.neonBlue.opacity(0.1))
                            .frame(height: 2)
                        , alignment: .bottom
                    )
                    .frame(width: 80)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fill in the blank. The quick brown fox jumps over the lazy [input field].")
    }
    
    // MARK: - Helper Functions
    // MARK: - Skills Graph View
    private var skillsGraphView: some View {
        ZStack {
            // Background and Grid
            DesignTokens.Colors.backgroundPrimary.ignoresSafeArea()
            
            // Radial Gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [DesignTokens.Colors.neonPurple.opacity(0.2), .clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
            
            // Grid Lines
            ForEach(0..<5) { i in
                Circle()
                    .stroke(DesignTokens.Colors.neutral700.opacity(0.5), lineWidth: 1)
                    .frame(width: CGFloat(i + 1) * 100, height: CGFloat(i + 1) * 100)
            }
            
            // Skill Nodes
            if let course = course {
                ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                    let angle = (2 * .pi / Double(course.lessons.count)) * Double(index)
                    let radius = 200.0
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.neutral800)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            masteryLevels[lesson.id] ?? 0 > 0.7 ? DesignTokens.Colors.neonPurple : DesignTokens.Colors.neutral600,
                                            lineWidth: 2
                                        )
                                )
                            
                            Image(systemName: lesson.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(masteryLevels[lesson.id] ?? 0 > 0.7 ? DesignTokens.Colors.neonPurple : DesignTokens.Colors.textTertiary)
                            
                            Circle()
                                .trim(from: 0, to: masteryLevels[lesson.id] ?? 0)
                                .stroke(DesignTokens.Colors.neonPurple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 58, height: 58)
                                .rotationEffect(.degrees(-90))
                                .animation(DesignTokens.Animations.smooth, value: masteryLevels[lesson.id])
                        }
                        
                        Text(lesson.title)
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                    }
                    .offset(x: x, y: y)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Skill: \(lesson.title). Mastery: \(Int((masteryLevels[lesson.id] ?? 0) * 100)) percent.")
                }
            }
            
            // Central "Brain"
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.neonPurple)
                    .shadow(color: DesignTokens.Colors.neonPurple.opacity(0.5), radius: 15)
                
                Text("Mastery Map")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(topic)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Mastery Map for \(topic)")
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helper Functions
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
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Placeholder for different interactive types
            switch currentInteractiveType {
            case .codeEditor:
                codeEditorView
            case .multipleChoice:
                multipleChoiceView
            case .fillInTheBlank:
                fillInTheBlankView
            }
            
            // Submit / Check Answer Button
            Button(action: checkInteractiveAnswer) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check Answer")
                }
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.brandGradient)
                .cornerRadius(DesignTokens.Radius.button)
                .shadow(color: DesignTokens.Colors.brand.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(isInteractiveAnswerCorrect)
            .accessibilityLabel("Check your answer")
            
            // Feedback
            if let feedback = interactiveFeedback {
                Text(feedback)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(isInteractiveAnswerCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill((isInteractiveAnswerCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error).opacity(0.1))
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    private var codeEditorView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Your turn to code:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            TextEditor(text: $interactiveCodeInput)
                .font(DesignTokens.Typography.techLabel)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(DesignTokens.Spacing.md)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.neutral900)
                )
                .cornerRadius(DesignTokens.Radius.md)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Code editor. Type your code here.")
    }
    
    private var multipleChoiceView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Choose the correct option:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            ForEach(0..<4) { index in
                Button(action: { interactiveSelectedOption = index }) {
                    HStack {
                        Text("Option \(index + 1)")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Spacer()
                        if interactiveSelectedOption == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignTokens.Colors.success)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(interactiveSelectedOption == index ? DesignTokens.Colors.success.opacity(0.1) : DesignTokens.Colors.neutral800)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .stroke(interactiveSelectedOption == index ? DesignTokens.Colors.success : DesignTokens.Colors.neutral600, lineWidth: 1.5)
                            )
                    )
                }
                .accessibilityLabel("Option \(index + 1)")
            }
        }
    }
    
    private var fillInTheBlankView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Fill in the missing word:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            HStack {
                Text("The quick brown fox jumps over the lazy")
                    .font(DesignTokens.Typography.bodyLarge)
                
                TextField("word", text: $interactiveBlankInput)
                    .font(DesignTokens.Typography.bodyLarge)
                    .foregroundColor(DesignTokens.Colors.neonBlue)
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        Rectangle()
                            .fill(DesignTokens.Colors.neonBlue.opacity(0.1))
                            .frame(height: 2)
                        , alignment: .bottom
                    )
                    .frame(width: 80)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Fill in the blank. The quick brown fox jumps over the lazy [input field].")
    }
    
    // MARK: - Helper Functions
    // MARK: - Skills Graph View
    private var skillsGraphView: some View {
        ZStack {
            // Background and Grid
            DesignTokens.Colors.backgroundPrimary.ignoresSafeArea()
            
            // Radial Gradient
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [DesignTokens.Colors.neonPurple.opacity(0.2), .clear]),
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
            
            // Grid Lines
            ForEach(0..<5) { i in
                Circle()
                    .stroke(DesignTokens.Colors.neutral700.opacity(0.5), lineWidth: 1)
                    .frame(width: CGFloat(i + 1) * 100, height: CGFloat(i + 1) * 100)
            }
            
            // Skill Nodes
            if let course = course {
                ForEach(Array(course.lessons.enumerated()), id: \.element.id) { index, lesson in
                    let angle = (2 * .pi / Double(course.lessons.count)) * Double(index)
                    let radius = 200.0
                    let x = cos(angle) * radius
                    let y = sin(angle) * radius
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        ZStack {
                            Circle()
                                .fill(DesignTokens.Colors.neutral800)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            masteryLevels[lesson.id] ?? 0 > 0.7 ? DesignTokens.Colors.neonPurple : DesignTokens.Colors.neutral600,
                                            lineWidth: 2
                                        )
                                )
                            
                            Image(systemName: lesson.iconName)
                                .font(.system(size: 24))
                                .foregroundColor(masteryLevels[lesson.id] ?? 0 > 0.7 ? DesignTokens.Colors.neonPurple : DesignTokens.Colors.textTertiary)
                            
                            Circle()
                                .trim(from: 0, to: masteryLevels[lesson.id] ?? 0)
                                .stroke(DesignTokens.Colors.neonPurple, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 58, height: 58)
                                .rotationEffect(.degrees(-90))
                                .animation(DesignTokens.Animations.smooth, value: masteryLevels[lesson.id])
                        }
                        
                        Text(lesson.title)
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .frame(width: 80)
                            .multilineTextAlignment(.center)
                    }
                    .offset(x: x, y: y)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Skill: \(lesson.title). Mastery: \(Int((masteryLevels[lesson.id] ?? 0) * 100)) percent.")
                }
            }
            
            // Central "Brain"
            VStack(spacing: DesignTokens.Spacing.md) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.neonPurple)
                    .shadow(color: DesignTokens.Colors.neonPurple.opacity(0.5), radius: 15)
                
                Text("Mastery Map")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(topic)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Mastery Map for \(topic)")
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helper Functions
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
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Placeholder for different interactive types
            switch currentInteractiveType {
            case .codeEditor:
                codeEditorView
            case .multipleChoice:
                multipleChoiceView
            case .fillInTheBlank:
                fillInTheBlankView
            }
            
            // Submit / Check Answer Button
            Button(action: checkInteractiveAnswer) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check Answer")
                }
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.brandGradient)
                .cornerRadius(DesignTokens.Radius.button)
                .shadow(color: DesignTokens.Colors.brand.opacity(0.3), radius: 8, y: 4)
            }
            .disabled(isInteractiveAnswerCorrect)
            .accessibilityLabel("Check your answer")
            
            // Feedback
            if let feedback = interactiveFeedback {
                Text(feedback)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(isInteractiveAnswerCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill((isInteractiveAnswerCorrect ? DesignTokens.Colors.success : DesignTokens.Colors.error).opacity(0.1))
                    )
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .padding(.top, DesignTokens.Spacing.md)
    }
    
    private var codeEditorView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Your turn to code:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            TextEditor(text: $interactiveCodeInput)
                .font(DesignTokens.Typography.techLabel)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(DesignTokens.Spacing.md)
                .frame(height: 150)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.neutral900)
                )
                .cornerRadius(DesignTokens.Radius.md)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Code editor. Type your code here.")
    }
    
    private var multipleChoiceView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Choose the correct option:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            ForEach(0..<4) { index in
                Button(action: { interactiveSelectedOption = index }) {
                    HStack {
                        Text("Option \(index + 1)")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        Spacer()
                        if interactiveSelectedOption == index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(DesignTokens.Colors.success)
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(interactiveSelectedOption == index ? DesignTokens.Colors.success.opacity(0.1) : DesignTokens.Colors.neutral800)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .stroke(interactiveSelectedOption == index ? DesignTokens.Colors.success : DesignTokens.Colors.neutral600, lineWidth: 1.5)
                            )
                    )
                }
                .accessibilityLabel("Option \(index + 1)")
            }
        }
    }
    
    private var fillInTheBlankView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Fill in the missing word:")
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            HStack {
                Text("The quick brown fox jumps over the lazy")
                    .font(DesignTokens.Typography.bodyLarge)
                
                TextField("word", text: $interactiveBlankInput)
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
