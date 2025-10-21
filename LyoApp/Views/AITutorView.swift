import SwiftUI
import Foundation

struct AITutorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var avatarService = AIAvatarService.shared
    @State private var currentQuestion = ""
    @State private var studentResponse = ""
    @State private var isInSocraticMode = true
    @State private var currentTopic = "General Learning"
    @State private var learningDepth: Double = 0.5
    @State private var showingTopicSelector = false
    
    // Socratic Teaching States
    @State private var socraticStage: SocraticStage = .inquiry
    @State private var questionsAsked: [String] = []
    @State private var insights: [String] = []
    @State private var currentInsight = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with Teaching Mode Toggle
                tutorHeaderView
                
                // Socratic Teaching Interface
                if isInSocraticMode {
                    socraticTeachingView
                } else {
                    // Traditional chat fallback
                    traditionalChatView  
                }
                
                // Input Area
                tutorInputView
            }
            .navigationTitle("Lyo Tutor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        appState.dismissAvatar()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingTopicSelector = true
                    } label: {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTopicSelector) {
            SocraticTopicSelector(selectedTopic: $currentTopic, learningDepth: $learningDepth)
        }
        .onAppear {
            initializeSocraticSession()
        }
    }
    
    // MARK: - Tutor Header
    private var tutorHeaderView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Teaching Mode Toggle
            HStack {
                Text("Teaching Mode:")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Picker("Mode", selection: $isInSocraticMode) {
                    Text("Socratic").tag(true)
                    Text("Traditional").tag(false)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Spacer()
            }
            
            // Current Topic & Learning Depth
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Topic: \(currentTopic)")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    HStack {
                        Text("Depth:")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text(depthDescription)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                }
                
                Spacer()
                
                // Socratic Stage Indicator
                if isInSocraticMode {
                    VStack {
                        Text("Stage")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text(socraticStage.displayName)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignTokens.Colors.primary.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.glassBg)
        .overlay(
            Rectangle()
                .fill(DesignTokens.Colors.glassBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Socratic Teaching Interface
    private var socraticTeachingView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.lg) {
                    // Current Question Display
                    if !currentQuestion.isEmpty {
                        SocraticQuestionCard(
                            question: currentQuestion,
                            stage: socraticStage,
                            onHint: {
                                // Provide contextual hint
                                generateHint()
                            }
                        )
                        .id("current-question")
                    }
                    
                    // Previous Questions & Insights
                    ForEach(Array(zip(questionsAsked.indices, questionsAsked)), id: \.0) { index, question in
                        SocraticExchangeCard(
                            question: question,
                            insight: insights.indices.contains(index) ? insights[index] : nil,
                            index: index
                        )
                    }
                    
                    // Insight Development Area
                    if !currentInsight.isEmpty {
                        InsightCard(insight: currentInsight)
                            .id("current-insight")
                    }
                    
                    // Learning Progress Visualization  
                    SocraticProgressView(
                        questionsAsked: questionsAsked.count,
                        insightsGained: insights.count,
                        currentStage: socraticStage
                    )
                }
                .padding(DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.primaryBg)
            .onChange(of: currentQuestion) { _, _ in
                withAnimation(.easeInOut) {
                    proxy.scrollTo("current-question", anchor: .bottom)
                }
            }
            .onChange(of: currentInsight) { _, _ in
                withAnimation(.easeInOut) {
                    proxy.scrollTo("current-insight", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Traditional Chat View (Fallback)
    private var traditionalChatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(avatarService.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    if avatarService.isTyping {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.primaryBg)
            .onChange(of: avatarService.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(avatarService.messages.last?.id ?? "typing", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Tutor Input
    private var tutorInputView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Socratic Response Helpers
            if isInSocraticMode && !currentQuestion.isEmpty {
                socraticResponseHelpers
            }
            
            // Main Input
            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField(inputPlaceholder, text: $studentResponse, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(avatarService.isLoading)
                
                // Send Button
                Button {
                    if isInSocraticMode {
                        processSocraticResponse()
                    } else {
                        sendTraditionalMessage()
                    }
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(studentResponse.isEmpty ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.primary)
                        .clipShape(Circle())
                }
                .disabled(studentResponse.isEmpty || avatarService.isLoading)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.lg)
        }
        .background(DesignTokens.Colors.glassBg)
        .overlay(
            Rectangle()
                .fill(DesignTokens.Colors.glassBorder)
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Socratic Response Helpers
    private var socraticResponseHelpers: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                SocraticHelperButton(title: "I'm not sure...", icon: "questionmark.circle") {
                    studentResponse = "I'm not sure about this. Can you help me think through it?"
                }
                
                SocraticHelperButton(title: "Let me think...", icon: "brain") {
                    studentResponse = "Let me think about this step by step..."
                }
                
                SocraticHelperButton(title: "I think...", icon: "lightbulb") {
                    studentResponse = "I think the answer might be related to..."
                }
                
                SocraticHelperButton(title: "What if...", icon: "arrow.triangle.branch") {
                    studentResponse = "What if we approach this differently?"
                }
                
                SocraticHelperButton(title: "Need hint", icon: "hand.raised") {
                    generateHint()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
    
    // MARK: - Helper Methods
    
    private func initializeSocraticSession() {
        socraticStage = .inquiry
        generateInitialQuestion()
    }
    
    private func generateInitialQuestion() {
        let questions = [
            "What do you find most intriguing about \(currentTopic)?",
            "If you had to explain \(currentTopic) to a friend, where would you start?",
            "What questions come to mind when you think about \(currentTopic)?",
            "What assumptions might we have about \(currentTopic) that could be wrong?"
        ]
        
        currentQuestion = questions.randomElement() ?? questions.first!
    }
    
    private func processSocraticResponse() {
        guard !studentResponse.isEmpty else { return }
        
        let response = studentResponse
        studentResponse = ""
        
        // Record the exchange
        questionsAsked.append(currentQuestion)
        
        Task {
            // Process response through AI for next question
            let nextQuestion = await generateSocraticFollowUp(response: response)
            
            await MainActor.run {
                currentQuestion = nextQuestion
                
                // Advance socratic stage if appropriate
                advanceSocraticStage(basedOn: response)
                
                // Generate insight if ready
                if socraticStage == .synthesis {
                    generateInsight(from: response)
                }
            }
        }
    }
    
    private func generateSocraticFollowUp(response: String) async -> String {
        // Use the superior AI backend to generate contextual socratic follow-ups
        do {
            let prompt = """
            Acting as a Socratic tutor, the student just responded: "\(response)"
            
            Current topic: \(currentTopic)
            Current stage: \(socraticStage.rawValue)
            Learning depth: \(Int(learningDepth * 100))%
            
            Generate the next Socratic question that:
            1. Builds on their response
            2. Guides them deeper into understanding
            3. Challenges assumptions gently
            4. Maintains curiosity and engagement
            
            Focus on \(socraticStage.focusArea). Keep the question concise and thought-provoking.
            """
            
            let nextQuestion = try await avatarService.apiClient.generateWithSuperiorBackend(prompt)
            return nextQuestion
            
        } catch {
            // Fallback to structured questions
            return generateFallbackSocraticQuestion(for: response)
        }
    }
    
    private func generateFallbackSocraticQuestion(for response: String) -> String {
        let responseWords = response.lowercased()
        
        switch socraticStage {
        case .inquiry:
            if responseWords.contains("because") {
                return "What evidence supports that reasoning?"
            } else if responseWords.contains("think") {
                return "What led you to that thinking?"
            } else {
                return "Can you tell me more about what you mean by that?"
            }
            
        case .hypothesis:
            return "What would happen if your hypothesis is wrong?"
            
        case .analysis:
            return "How does this connect to what we discussed earlier?"
            
        case .synthesis:
            return "What's the most important insight you've gained from our discussion?"
        }
    }
    
    private func advanceSocraticStage(basedOn response: String) {
        let responseWords = response.lowercased()
        
        // Simple heuristics for stage advancement
        if socraticStage == .inquiry && questionsAsked.count >= 3 {
            socraticStage = .hypothesis
        } else if socraticStage == .hypothesis && (responseWords.contains("if") || responseWords.contains("might")) {
            socraticStage = .analysis
        } else if socraticStage == .analysis && questionsAsked.count >= 6 {
            socraticStage = .synthesis
        }
    }
    
    private func generateInsight(from response: String) {
        let potentialInsights = [
            "You've discovered that learning happens through questioning, not just answering!",
            "Notice how your understanding deepened when you had to explain your reasoning?",
            "Your thinking evolved as we explored different perspectives together.",
            "You've demonstrated that the best learning comes from curiosity and inquiry."
        ]
        
        currentInsight = potentialInsights.randomElement() ?? potentialInsights.first!
        insights.append(currentInsight)
        
        // Clear after showing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            currentInsight = ""
        }
    }
    
    private func generateHint() {
        let hints = [
            "💡 Think about the fundamental principles involved...",
            "🤔 Consider what you already know that might apply here...",
            "🔍 What questions would help you break this down further?",
            "🌟 What patterns do you notice in similar situations?"
        ]
        
        currentInsight = hints.randomElement() ?? hints.first!
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            currentInsight = ""
        }
    }
    
    private func sendTraditionalMessage() {
        guard !studentResponse.isEmpty else { return }
        
        let message = studentResponse
        studentResponse = ""
        
        Task {
            await avatarService.sendMessage(message)
        }
    }
    
    // MARK: - Computed Properties
    
    private var inputPlaceholder: String {
        if isInSocraticMode {
            switch socraticStage {
            case .inquiry: return "Share your thoughts and questions..."
            case .hypothesis: return "What's your hypothesis?"
            case .analysis: return "How would you analyze this?"
            case .synthesis: return "What insights have you gained?"
            }
        } else {
            return "Ask Lyo anything..."
        }
    }
    
    private var depthDescription: String {
        switch learningDepth {
        case 0...0.3: return "Surface"
        case 0.3...0.7: return "Intermediate"
        default: return "Deep"
        }
    }
}

// MARK: - Socratic Stage Enum
enum SocraticStage: String, CaseIterable {
    case inquiry = "inquiry"
    case hypothesis = "hypothesis"
    case analysis = "analysis"
    case synthesis = "synthesis"
    
    var displayName: String {
        switch self {
        case .inquiry: return "Inquiry"
        case .hypothesis: return "Hypothesis"
        case .analysis: return "Analysis"
        case .synthesis: return "Synthesis"
        }
    }
    
    var focusArea: String {
        switch self {
        case .inquiry: return "questioning and exploration"
        case .hypothesis: return "forming educated guesses"
        case .analysis: return "examining evidence and reasoning"
        case .synthesis: return "connecting insights and understanding"
        }
    }
    
    var color: Color {
        switch self {
        case .inquiry: return .blue
        case .hypothesis: return .orange
        case .analysis: return .green
        case .synthesis: return .purple
        }
    }
}

// MARK: - Supporting Views
struct SocraticQuestionCard: View {
    let question: String
    let stage: SocraticStage
    let onHint: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text(stage.displayName.uppercased())
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(stage.color)
                    .cornerRadius(4)
                
                Spacer()
                
                Button(action: onHint) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
            
            Text(question)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(stage.color.opacity(0.3), lineWidth: 2)
        )
    }
}

struct SocraticExchangeCard: View {
    let question: String
    let insight: String?
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            HStack {
                Text("Question \(index + 1)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
                
                if insight != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.success)
                }
            }
            
            Text(question)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            if let insight = insight {
                Text("💡 \(insight)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .padding(8)
                    .background(DesignTokens.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg.opacity(0.5))
        .cornerRadius(DesignTokens.Radius.md)
    }
}

struct InsightCard: View {
    let insight: String
    
    var body: some View {
        HStack {
            Image(systemName: "sparkles")
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(insight)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.lg)
        .background(DesignTokens.Colors.primary.opacity(0.1))
        .cornerRadius(DesignTokens.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .stroke(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SocraticProgressView: View {
    let questionsAsked: Int
    let insightsGained: Int
    let currentStage: SocraticStage
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Text("Learning Progress")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            HStack(spacing: DesignTokens.Spacing.md) {
                ProgressMetric(title: "Questions", value: questionsAsked, icon: "questionmark.circle")
                ProgressMetric(title: "Insights", value: insightsGained, icon: "lightbulb")
                ProgressMetric(title: "Stage", value: currentStage.displayName, icon: "brain")
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg.opacity(0.3))
        .cornerRadius(DesignTokens.Radius.md)
    }
}

struct ProgressMetric<T>: View {
    let title: String
    let value: T
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text("\(value)")
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text(title)
                .font(DesignTokens.Typography.caption2)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
}

struct SocraticHelperButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                
                Text(title)
                    .font(DesignTokens.Typography.caption)
            }
            .foregroundColor(DesignTokens.Colors.primary)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(DesignTokens.Colors.primary.opacity(0.1))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }
}

struct SocraticTopicSelector: View {
    @Binding var selectedTopic: String
    @Binding var learningDepth: Double
    @Environment(\.dismiss) private var dismiss
    
    let topics = [
        "Swift Programming", "iOS Development", "SwiftUI", "Data Structures", 
        "Algorithms", "System Design", "Machine Learning", "UI/UX Design",
        "Critical Thinking", "Problem Solving", "Philosophy of Technology"
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Learning Topic") {
                    ForEach(topics, id: \.self) { topic in
                        HStack {
                            Text(topic)
                            Spacer()
                            if selectedTopic == topic {
                                Image(systemName: "checkmark")
                                    .foregroundColor(DesignTokens.Colors.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTopic = topic
                        }
                    }
                }
                
                Section("Learning Depth") {
                    VStack {
                        Slider(value: $learningDepth, in: 0...1)
                        
                        HStack {
                            Text("Surface")
                                .font(DesignTokens.Typography.caption)
                            Spacer()
                            Text("Deep")
                                .font(DesignTokens.Typography.caption)
                        }
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            .navigationTitle("Socratic Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AITutorView()
        .environmentObject(AppState())
}