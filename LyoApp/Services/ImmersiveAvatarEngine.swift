import Foundation
import SwiftUI
import Combine
import AVFoundation

// MARK: - Immersive Avatar Engine
@MainActor
class ImmersiveAvatarEngine: ObservableObject {
    @Published var conversationHistory: [ImmersiveMessage] = []
    @Published var currentMood: AvatarMood = .friendly
    @Published var isThinking: Bool = false
    @Published var isTyping: Bool = false
    @Published var quickActions: [QuickAction] = []
    @Published var networkComplexity: Double = 0.3
    @Published var statusMessage: String = "Ready to learn with you!"
    
    private let avatarAPIClient = AIAvatarAPIClient.shared
    private let speechRecognizer = SpeechRecognizer()
    private let hapticEngine = HapticFeedbackEngine()
    private var conversationContext = ConversationContext()
    
    // MARK: - Session Management
    
    func startSession() async {
        // Initialize conversation with dynamic greeting
        let greeting = generateContextualGreeting()
        let welcomeMessage = ImmersiveMessage(
            id: UUID(),
            content: greeting,
            isFromUser: false,
            timestamp: Date(),
            mood: currentMood,
            actions: generateWelcomeActions()
        )
        
        conversationHistory.append(welcomeMessage)
        updateQuickActions()
        
        // Start mood evolution
        startMoodEvolution()
    }
    
    func processMessage(_ content: String) async {
        // Add user message
        let userMessage = ImmersiveMessage(
            id: UUID(),
            content: content,
            isFromUser: true,
            timestamp: Date()
        )
        
        conversationHistory.append(userMessage)
        
        // Update context
        conversationContext.addInteraction(content, isFromUser: true)
        
        // Start AI processing
        isThinking = true
        networkComplexity = min(networkComplexity + 0.1, 1.0)
        
        // Trigger haptic feedback
        hapticEngine.lightImpact()
        
        // Simulate processing delay with dynamic response generation
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))
        
        // Generate AI response
        let aiResponse = await generateIntelligentResponse(to: content)
        
        let aiMessage = ImmersiveMessage(
            id: UUID(),
            content: aiResponse.content,
            isFromUser: false,
            timestamp: Date(),
            mood: currentMood,
            actions: aiResponse.actions,
            suggestions: aiResponse.suggestions
        )
        
        conversationHistory.append(aiMessage)
        conversationContext.addInteraction(aiResponse.content, isFromUser: false)
        
        isThinking = false
        updateQuickActions()
        evolveMood(basedOn: content)
    }
    
    func performAction(_ action: QuickAction) async {
        // Add action as user message
        let actionMessage = ImmersiveMessage(
            id: UUID(),
            content: "🎯 " + action.title,
            isFromUser: true,
            timestamp: Date(),
            actionPerformed: action
        )
        
        conversationHistory.append(actionMessage)
        
        isThinking = true
        hapticEngine.mediumImpact()
        
        // Generate action-specific response
        let response = await generateActionResponse(for: action)
        
        let aiMessage = ImmersiveMessage(
            id: UUID(),
            content: response.content,
            isFromUser: false,
            timestamp: Date(),
            mood: currentMood,
            actions: response.actions
        )
        
        conversationHistory.append(aiMessage)
        isThinking = false
        
        updateQuickActions()
    }
    
    func handleMessageAction(_ action: MessageAction, for message: ImmersiveMessage) async {
        switch action.type {
        case .like:
            hapticEngine.lightImpact()
            // Update user preferences
            conversationContext.addPreference(message.content, weight: 0.1)
            
        case .share:
            // Handle sharing logic
            await handleShare(message: message)
            
        case .expand:
            await expandMessage(message)
            
        case .clarify:
            await requestClarification(for: message)
            
        case .practice:
            await generatePracticeExercise(basedOn: message)
        }
    }
    
    // MARK: - Voice Integration
    
    func startVoiceRecording() {
        speechRecognizer.startRecording { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let transcript):
                    await self?.processMessage(transcript)
                case .failure(let error):
                    self?.showVoiceError(error)
                }
            }
        }
    }
    
    func stopVoiceRecording() {
        speechRecognizer.stopRecording()
    }
    
    // MARK: - Response Generation
    
    private func generateIntelligentResponse(to userInput: String) async -> AIResponse {
        do {
            // Try superior backend first
            let backendResponse = try await avatarAPIClient.generateWithSuperiorBackend(userInput)
            
            return AIResponse(
                content: backendResponse,
                actions: generateContextualActions(for: userInput),
                suggestions: generateSmartSuggestions(for: userInput)
            )
            
        } catch {
            // Fallback to intelligent local response
            return generateAdvancedLocalResponse(for: userInput)
        }
    }
    
    private func generateAdvancedLocalResponse(for input: String) -> AIResponse {
        let lowercaseInput = input.lowercased()
        let context = conversationContext
        
        // Analyze user intent
        let intent = analyzeUserIntent(input)
        let emotionalTone = analyzeEmotionalTone(input)
        
        var response = ""
        var actions: [MessageAction] = []
        var suggestions: [String] = []
        
        switch intent {
        case .seeking_course:
            response = generateCourseRecommendationResponse(input, context: context)
            actions = [
                MessageAction(id: UUID(), type: .practice, title: "Start Learning", iconName: "play.circle"),
                MessageAction(id: UUID(), type: .expand, title: "More Details", iconName: "info.circle")
            ]
            suggestions = ["What specific topics interest you?", "What's your current skill level?"]
            
        case .asking_question:
            response = generateSocraticResponse(input, context: context)
            actions = [
                MessageAction(id: UUID(), type: .clarify, title: "Clarify", iconName: "questionmark.circle"),
                MessageAction(id: UUID(), type: .expand, title: "Deep Dive", iconName: "arrow.down.circle")
            ]
            suggestions = generateRelatedQuestions(input)
            
        case .sharing_progress:
            response = generateProgressAcknowledgment(input, tone: emotionalTone)
            actions = [
                MessageAction(id: UUID(), type: .share, title: "Share Achievement", iconName: "square.and.arrow.up"),
                MessageAction(id: UUID(), type: .practice, title: "Next Challenge", iconName: "target")
            ]
            suggestions = ["What did you find most challenging?", "Ready for the next level?"]
            
        case .expressing_confusion:
            response = generateSupportiveGuidance(input, context: context)
            actions = [
                MessageAction(id: UUID(), type: .clarify, title: "Break It Down", iconName: "list.bullet"),
                MessageAction(id: UUID(), type: .practice, title: "Practice", iconName: "repeat")
            ]
            suggestions = ["Let's try a different approach", "Would examples help?"]
            
        case .general_conversation:
            response = generateEngagingResponse(input, mood: currentMood, context: context)
            actions = generateContextualActions(for: input)
            suggestions = generateContextualSuggestions(input, context: context)
        }
        
        return AIResponse(content: response, actions: actions, suggestions: suggestions)
    }
    
    private func generateActionResponse(for action: QuickAction) async -> AIResponse {
        var response = ""
        var actions: [MessageAction] = []
        
        switch action.type {
        case .generateCourse:
            response = """
            🎓 **Excellent choice!** I'm creating a personalized learning journey for you.
            
            **Course: \(action.title)**
            
            I'll design this course using advanced pedagogical principles:
            • **Adaptive pacing** that matches your learning style
            • **Socratic questioning** to develop critical thinking
            • **Hands-on projects** for practical application
            • **Progressive challenges** that build confidence
            
            This course will automatically save to your personal library as you progress. You'll be able to share it with others once completed!
            
            Ready to begin this learning adventure? 🚀
            """
            
            actions = [
                MessageAction(id: UUID(), type: .practice, title: "Start Course", iconName: "play.circle.fill"),
                MessageAction(id: UUID(), type: .expand, title: "Customize", iconName: "slider.horizontal.3")
            ]
            
        case .quickHelp:
            response = """
            🤝 **I'm here to help!** What specific challenge are you facing?
            
            I can assist with:
            • **Explaining complex concepts** through analogies and examples
            • **Breaking down problems** into manageable steps
            • **Providing practice exercises** tailored to your level
            • **Connecting ideas** to real-world applications
            
            The more specific your question, the more targeted my help can be!
            """
            
        case .practiceMode:
            response = """
            🎯 **Practice Mode Activated!** Let's sharpen your skills together.
            
            I'll create interactive challenges based on:
            • Your current learning objectives
            • Areas where you need more confidence
            • Real-world problem scenarios
            • Progressive difficulty scaling
            
            Each practice session adapts to your performance and provides immediate feedback!
            """
            
            actions = [
                MessageAction(id: UUID(), type: .practice, title: "Start Practice", iconName: "target"),
                MessageAction(id: UUID(), type: .clarify, title: "Choose Topic", iconName: "list.bullet")
            ]
            
        case .explore:
            response = """
            🌟 **Discovery Mode!** Let's explore new territories of knowledge together.
            
            I can guide you through:
            • **Trending topics** in your field of interest
            • **Interdisciplinary connections** you might not have considered
            • **Cutting-edge developments** and their implications
            • **Creative applications** of what you've learned
            
            What sparks your curiosity today?
            """
        }
        
        return AIResponse(content: response, actions: actions, suggestions: [])
    }
    
    // MARK: - Context and Mood Management
    
    private func evolveMood(basedOn input: String) {
        let sentiment = analyzeSentiment(input)
        let enthusiasm = analyzeEnthusiasm(input)
        
        if enthusiasm > 0.7 {
            currentMood = .excited
        } else if sentiment > 0.6 {
            currentMood = .supportive
        } else if sentiment < 0.3 {
            currentMood = .empathetic
        } else if input.contains("?") && input.count > 20 {
            currentMood = .curious
        } else {
            currentMood = .friendly
        }
        
        statusMessage = generateStatusMessage()
    }
    
    private func startMoodEvolution() {
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task { @MainActor in
                // Gradually evolve mood based on conversation context
                if self.conversationContext.recentInteractionCount > 5 {
                    self.currentMood = .engaged
                } else if self.conversationContext.complexityScore > 0.8 {
                    self.currentMood = .thoughtful
                }
                
                self.statusMessage = self.generateStatusMessage()
            }
        }
    }
    
    private func updateQuickActions() {
        let recentTopics = conversationContext.extractRecentTopics()
        
        var newActions: [QuickAction] = [
            QuickAction(
                id: UUID(),
                type: .quickHelp,
                title: "Quick Help",
                description: "Get instant assistance",
                iconName: "questionmark.circle"
            )
        ]
        
        // Add contextual actions based on conversation
        if recentTopics.contains(where: { $0.contains("course") || $0.contains("learn") }) {
            newActions.append(QuickAction(
                id: UUID(),
                type: .generateCourse,
                title: "Create Course",
                description: "Generate a learning path",
                iconName: "graduation.cap"
            ))
        }
        
        if recentTopics.contains(where: { $0.contains("practice") || $0.contains("exercise") }) {
            newActions.append(QuickAction(
                id: UUID(),
                type: .practiceMode,
                title: "Practice Mode",
                description: "Interactive exercises",
                iconName: "target"
            ))
        }
        
        newActions.append(QuickAction(
            id: UUID(),
            type: .explore,
            title: "Explore",
            description: "Discover new topics",
            iconName: "safari"
        ))
        
        quickActions = newActions
    }
    
    // MARK: - Helper Methods
    
    private func generateContextualGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting = hour < 12 ? "Good morning" : hour < 18 ? "Good afternoon" : "Good evening"
        
        let personalizedGreetings = [
            "\(timeGreeting)! I'm Lyo, your AI learning companion. What shall we explore today? 🌟",
            "Welcome back! I'm excited to continue our learning journey together. What's on your mind? 🚀",
            "\(timeGreeting)! Ready to dive into some fascinating topics? I'm here to make learning engaging and fun! ✨",
            "Hello there! I'm Lyo, and I'm passionate about helping you discover and master new concepts. What interests you today? 🎯"
        ]
        
        return personalizedGreetings.randomElement() ?? personalizedGreetings.first!
    }
    
    private func generateWelcomeActions() -> [MessageAction] {
        return [
            MessageAction(id: UUID(), type: .practice, title: "Start Learning", iconName: "play.circle"),
            MessageAction(id: UUID(), type: .expand, title: "Explore Topics", iconName: "safari"),
            MessageAction(id: UUID(), type: .clarify, title: "How It Works", iconName: "info.circle")
        ]
    }
    
    private func generateStatusMessage() -> String {
        switch currentMood {
        case .friendly:
            return "Ready to help you learn and grow! 😊"
        case .excited:
            return "This is so exciting! Let's dive deeper! 🚀"
        case .supportive:
            return "I'm here to support your learning journey 💪"
        case .curious:
            return "Your questions spark my curiosity too! 🤔"
        case .empathetic:
            return "Learning can be challenging, but you've got this! 🌱"
        case .thoughtful:
            return "Let me think about the best way to explain this... 💭"
        case .engaged:
            return "I love how engaged you are in learning! 🔥"
        }
    }
    
    // MARK: - Advanced Analysis Methods
    
    private func analyzeUserIntent(_ input: String) -> UserIntent {
        let lowercaseInput = input.lowercased()
        
        if lowercaseInput.contains(regexp: "(create|generate|make|build).*(course|lesson|curriculum)") {
            return .seeking_course
        } else if lowercaseInput.contains("?") || lowercaseInput.contains(regexp: "(what|how|why|when|where)") {
            return .asking_question
        } else if lowercaseInput.contains(regexp: "(completed|finished|learned|mastered|understood)") {
            return .sharing_progress
        } else if lowercaseInput.contains(regexp: "(confused|stuck|difficult|hard|don't understand)") {
            return .expressing_confusion
        } else {
            return .general_conversation
        }
    }
    
    private func analyzeEmotionalTone(_ input: String) -> EmotionalTone {
        let positiveWords = ["great", "awesome", "love", "excited", "amazing", "fantastic", "excellent"]
        let negativeWords = ["difficult", "hard", "confused", "frustrated", "stuck", "worried"]
        let neutralWords = ["okay", "fine", "alright", "sure", "yes", "no"]
        
        let positiveScore = positiveWords.reduce(0) { input.lowercased().contains($1) ? $0 + 1 : $0 }
        let negativeScore = negativeWords.reduce(0) { input.lowercased().contains($1) ? $0 + 1 : $0 }
        let neutralScore = neutralWords.reduce(0) { input.lowercased().contains($1) ? $0 + 1 : $0 }
        
        if positiveScore > negativeScore && positiveScore > neutralScore {
            return .positive
        } else if negativeScore > positiveScore && negativeScore > neutralScore {
            return .negative
        } else {
            return .neutral
        }
    }
    
    private func analyzeSentiment(_ input: String) -> Double {
        // Simple sentiment analysis - could be enhanced with ML models
        let positiveWords = ["good", "great", "excellent", "amazing", "love", "like", "enjoy", "fantastic"]
        let negativeWords = ["bad", "terrible", "hate", "dislike", "difficult", "hard", "frustrated", "confused"]
        
        let positiveCount = positiveWords.reduce(0) { input.lowercased().contains($1) ? $0 + 1 : $0 }
        let negativeCount = negativeWords.reduce(0) { input.lowercased().contains($1) ? $0 + 1 : $0 }
        
        let totalEmotionalWords = positiveCount + negativeCount
        
        if totalEmotionalWords == 0 {
            return 0.5 // Neutral
        }
        
        return Double(positiveCount) / Double(totalEmotionalWords)
    }
    
    private func analyzeEnthusiasm(_ input: String) -> Double {
        let enthusiasticIndicators = ["!", "awesome", "amazing", "excited", "can't wait", "love it", "fantastic"]
        let enthusiasmScore = enthusiasticIndicators.reduce(0) { total, indicator in
            return input.lowercased().contains(indicator) ? total + 1 : total
        }
        
        return min(Double(enthusiasmScore) * 0.2, 1.0)
    }
    
    // Additional helper methods for message actions
    private func handleShare(message: ImmersiveMessage) async {
        // Implementation for sharing functionality
        hapticEngine.successFeedback()
    }
    
    private func expandMessage(_ message: ImmersiveMessage) async {
        let expandedContent = """
        📚 **Expanded Explanation:**
        
        \(message.content)
        
        **Key Concepts:**
        • This topic connects to several fundamental principles
        • Understanding this can help with related areas
        • There are practical applications you can explore
        
        Would you like me to elaborate on any specific aspect?
        """
        
        let expandedMessage = ImmersiveMessage(
            id: UUID(),
            content: expandedContent,
            isFromUser: false,
            timestamp: Date(),
            mood: .thoughtful,
            actions: [
                MessageAction(id: UUID(), type: .practice, title: "Practice", iconName: "target"),
                MessageAction(id: UUID(), type: .clarify, title: "Questions", iconName: "questionmark.circle")
            ]
        )
        
        conversationHistory.append(expandedMessage)
    }
    
    private func requestClarification(for message: ImmersiveMessage) async {
        let clarificationMessage = ImmersiveMessage(
            id: UUID(),
            content: "🤔 I'd love to help clarify this further. What specific aspect would you like me to explain in more detail?",
            isFromUser: false,
            timestamp: Date(),
            mood: .curious,
            suggestions: [
                "Can you give me an example?",
                "How does this work in practice?",
                "What are the key steps?",
                "Why is this important?"
            ]
        )
        
        conversationHistory.append(clarificationMessage)
    }
    
    private func generatePracticeExercise(basedOn message: ImmersiveMessage) async {
        let practiceMessage = ImmersiveMessage(
            id: UUID(),
            content: "🎯 **Practice Exercise Generated!**\n\nBased on our discussion, here's a hands-on exercise to reinforce your understanding:\n\n• Apply the concept in a real scenario\n• Work through the problem step-by-step\n• Reflect on the outcome\n\nReady to give it a try?",
            isFromUser: false,
            timestamp: Date(),
            mood: .engaged,
            actions: [
                MessageAction(id: UUID(), type: .practice, title: "Start Exercise", iconName: "play.circle.fill"),
                MessageAction(id: UUID(), type: .clarify, title: "Get Hints", iconName: "lightbulb")
            ]
        )
        
        conversationHistory.append(practiceMessage)
    }
    
    private func showVoiceError(_ error: Error) {
        statusMessage = "Voice recognition error. Please try again."
    }
    
    // Placeholder response generation methods - these would be fully implemented
    private func generateCourseRecommendationResponse(_ input: String, context: ConversationContext) -> String {
        return "🎓 I'd love to create a personalized course for you! Based on your interest in \(input), I can design a comprehensive learning path with interactive modules and practical projects."
    }
    
    private func generateSocraticResponse(_ input: String, context: ConversationContext) -> String {
        return "🤔 That's a fascinating question! Instead of giving you a direct answer, let me guide you to discover it yourself: What do you think might be the underlying principle here?"
    }
    
    private func generateProgressAcknowledgment(_ input: String, tone: EmotionalTone) -> String {
        switch tone {
        case .positive:
            return "🎉 That's fantastic progress! I can see how much effort you've put in. What aspect of this learning journey has been most rewarding for you?"
        case .negative:
            return "💪 I understand this has been challenging, but remember that struggle is part of deep learning. You're building resilience and understanding. What would help you feel more confident?"
        case .neutral:
            return "📈 I appreciate you sharing your progress. Every step forward, no matter how small, is meaningful. What would you like to focus on next?"
        }
    }
    
    private func generateSupportiveGuidance(_ input: String, context: ConversationContext) -> String {
        return "🌱 It's completely normal to feel confused when learning something new. Let's break this down together into smaller, more manageable pieces. What part would you like to explore first?"
    }
    
    private func generateEngagingResponse(_ input: String, mood: AvatarMood, context: ConversationContext) -> String {
        return "💭 That's an interesting perspective! I love how you're thinking about this. It connects to several important concepts we could explore further."
    }
    
    private func generateContextualActions(for input: String) -> [MessageAction] {
        return [
            MessageAction(id: UUID(), type: .like, title: "👍", iconName: "hand.thumbsup"),
            MessageAction(id: UUID(), type: .share, title: "Share", iconName: "square.and.arrow.up")
        ]
    }
    
    private func generateSmartSuggestions(for input: String) -> [String] {
        return ["Tell me more about this", "Can you give an example?", "How does this apply to real life?"]
    }
    
    private func generateRelatedQuestions(_ input: String) -> [String] {
        return ["What's the deeper principle here?", "How might this connect to other topics?", "What questions does this raise for you?"]
    }
    
    private func generateContextualSuggestions(_ input: String, context: ConversationContext) -> [String] {
        return ["Let's explore this further", "What interests you most about this?", "Ready for a practical example?"]
    }
}

// MARK: - Supporting Models and Enums

struct ImmersiveMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let mood: AvatarMood?
    let actions: [MessageAction]
    let suggestions: [String]
    let actionPerformed: QuickAction?
    
    init(id: UUID, content: String, isFromUser: Bool, timestamp: Date, mood: AvatarMood? = nil, actions: [MessageAction] = [], suggestions: [String] = [], actionPerformed: QuickAction? = nil) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.mood = mood
        self.actions = actions
        self.suggestions = suggestions
        self.actionPerformed = actionPerformed
    }
}

struct MessageAction: Identifiable, Codable {
    let id: UUID
    let type: MessageActionType
    let title: String
    let iconName: String
}

enum MessageActionType: String, Codable {
    case like, share, expand, clarify, practice
}

struct QuickAction: Identifiable, Codable {
    let id: UUID
    let type: QuickActionType
    let title: String
    let description: String
    let iconName: String
}

enum QuickActionType: String, Codable {
    case generateCourse, quickHelp, practiceMode, explore
}

struct AIResponse {
    let content: String
    let actions: [MessageAction]
    let suggestions: [String]
}

enum AvatarMood: String, Codable, CaseIterable {
    case friendly, excited, supportive, curious, empathetic, thoughtful, engaged
    
    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .excited: return "Excited"
        case .supportive: return "Supportive"
        case .curious: return "Curious"
        case .empathetic: return "Empathetic"
        case .thoughtful: return "Thoughtful"
        case .engaged: return "Engaged"
        }
    }
}

enum UserIntent: String, Codable {
    case seeking_course, asking_question, sharing_progress, expressing_confusion, general_conversation
}

enum EmotionalTone: String, Codable {
    case positive, negative, neutral
}

// MARK: - Supporting Classes

class ConversationContext {
    private var interactions: [(String, Bool, Date)] = [] // content, isFromUser, timestamp
    private var topics: [String: Int] = [:] // topic frequency
    private var userPreferences: [String: Double] = [:] // preference weights
    
    var recentInteractionCount: Int {
        let recentTime = Date().addingTimeInterval(-300) // Last 5 minutes
        return interactions.filter { $0.2 > recentTime }.count
    }
    
    var complexityScore: Double {
        let recentInteractions = interactions.suffix(10)
        let avgLength = recentInteractions.map { $0.0.count }.reduce(0, +) / max(recentInteractions.count, 1)
        return min(Double(avgLength) / 100.0, 1.0)
    }
    
    func addInteraction(_ content: String, isFromUser: Bool) {
        interactions.append((content, isFromUser, Date()))
        
        // Extract and count topics
        extractTopics(from: content).forEach { topic in
            topics[topic, default: 0] += 1
        }
        
        // Limit memory
        if interactions.count > 100 {
            interactions.removeFirst(50)
        }
    }
    
    func addPreference(_ content: String, weight: Double) {
        let key = content.lowercased().prefix(50).trimmingCharacters(in: .whitespacesAndNewlines)
        userPreferences[String(key)] = (userPreferences[String(key)] ?? 0.0) + weight
    }
    
    func extractRecentTopics() -> [String] {
        return Array(topics.sorted { $0.value > $1.value }.prefix(5).map { $0.key })
    }
    
    private func extractTopics(from content: String) -> [String] {
        let commonTopics = ["swift", "ios", "programming", "design", "ai", "machine learning", "web development", "course", "learning", "tutorial"]
        return commonTopics.filter { content.lowercased().contains($0) }
    }
}

// MARK: - String Extension for Regex
extension String {
    func contains(regexp pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}

#Preview {
    let engine = ImmersiveAvatarEngine()
    return Text("Immersive Avatar Engine")
}