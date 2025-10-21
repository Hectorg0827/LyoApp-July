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
    @State private var generatedCourse: CourseOutlineLocal?
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
                        generateMockCourse: {
                            #if DEBUG
                            generateMockCourse()
                            #endif
                        }
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
                // Create proper Codable request
                struct CourseGenerationRequest: Codable {
                    let title: String
                    let description: String
                    let targetAudience: String
                    let learningObjectives: [String]
                    let difficultyLevel: String
                    let estimatedDurationHours: Int
                }
                
                let requestBody = CourseGenerationRequest(
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
                
                // FIX: Add leading slash so APIClient builds a valid URL
                let response: CourseOutlineResponse = try await APIClient.shared.post(
                    "/ai/generate-course",
                    body: requestBody
                )
                
                if let courseOutline = response.course {
                    // Convert API response to local model
                    generatedCourse = CourseOutlineLocal(
                        title: courseOutline.title,
                        description: courseOutline.title, // fallback to title if no description
                        lessons: [] // For now, empty lessons until we have proper data structure
                    )
                    isGenerating = false
                    transitionToClassroom()
                } else {
                    throw APIError.decodingError(NSError(domain: "Decode", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"]))
                }
                
            } catch {
                generationError = error.localizedDescription
                isGenerating = false
                
                // In production, do not use mock data
                #if DEBUG
                print("⚠️ API failed, using mock data: \(error)")
                generateMockCourse()
                #else
                print("⚠️ API failed: \(error)")
                #endif
            }
        }
    }
    
    private func generateMockCourse() {
        // Fallback mock course generation
        let mockCourse = CourseOutlineLocal(
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
