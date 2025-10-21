import Foundation
import SwiftUI

@MainActor
class LearningChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isProcessing: Bool = false
    @Published var currentQuickActions: [QuickAction]?
    @Published var generatedJourney: CourseJourney?
    @Published var countdown: Int?
    
    // Services
    private let analytics = LearningHubAnalytics.shared
    
    // Conversation state
    private var conversationState: ConversationState = .greeting
    private var currentTopic: String = ""
    private var currentLevel: CourseLevel?
    private var currentFocus: String?
    private var conversationStartTime: Date?
    
    // Start the conversation
    func startConversation() {
        conversationState = .waitingForTopic
        conversationStartTime = Date()
        analytics.trackConversationStarted()
    }
    
    // Send user message
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(
            content: inputText,
            isFromUser: true,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(userMessage)
        }
        
        let userInput = inputText
        inputText = ""
        isProcessing = true
        
        // Track analytics
        analytics.trackUserMessage(content: userInput, conversationState: conversationState.rawValue)
        
        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Process message based on conversation state
        Task {
            // Simulate network delay for realism
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            await processUserInput(userInput)
            isProcessing = false
        }
    }
    
    // Handle quick action selection
    func handleQuickAction(_ action: QuickAction) {
        // Track analytics
        analytics.trackQuickActionSelected(actionTitle: action.title, actionValue: action.value)
        
        // Simulate user typing the selected action
        let userMessage = ChatMessage(
            content: action.title,
            isFromUser: true,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(userMessage)
            currentQuickActions = nil
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        isProcessing = true
        
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            
            // Handle based on action value
            if action.value == "yes" || action.value == "no" {
                if action.value == "yes" {
                    await askForLevel()
                } else {
                    await endConversation()
                }
            } else if ["beginner", "intermediate", "advanced", "explanation"].contains(action.value) {
                await handleLevelSelection(action.value)
            } else {
                // It's a clarifying question answer
                await handleClarification(action.title)
            }
            
            isProcessing = false
        }
    }
    
    // Process user input based on conversation state
    private func processUserInput(_ input: String) async {
        switch conversationState {
        case .greeting:
            conversationState = .waitingForTopic
            
        case .waitingForTopic:
            await handleTopicInput(input)
            
        case .clarifyingTopic:
            await handleClarification(input)
            
        case .selectingLevel:
            await handleLevelSelection(input)
            
        case .generatingCourse:
            // Should not receive input here
            break
        }
    }
    
    // Handle initial topic input
    private func handleTopicInput(_ input: String) async {
        currentTopic = input
        
        // Analyze intent
        let intent = analyzeIntent(input)
        
        switch intent {
        case .quickExplanation:
            await provideQuickExplanation(input)
            
        case .fullCourse:
            // Check if topic is specific enough
            if isTopicSpecific(input) {
                await askForLevel()
            } else {
                await askClarifyingQuestion(input)
            }
            
        case .unclear:
            await askClarifyingQuestion(input)
        }
    }
    
    // Analyze user intent
    private func analyzeIntent(_ input: String) -> LearningIntent {
        let lowercased = input.lowercased()
        
        // Keywords for quick explanation
        if lowercased.contains("what is") ||
           lowercased.contains("explain") ||
           lowercased.contains("tell me about") {
            return .quickExplanation
        }
        
        // Keywords for full course
        if lowercased.contains("learn") ||
           lowercased.contains("course") ||
           lowercased.contains("master") ||
           lowercased.contains("study") {
            return .fullCourse
        }
        
        // Default to full course for most queries
        return .fullCourse
    }
    
    // Check if topic is specific enough
    private func isTopicSpecific(_ input: String) -> Bool {
        let words = input.split(separator: " ")
        return words.count >= 3
    }
    
    // Provide quick explanation in chat
    private func provideQuickExplanation(_ topic: String) async {
        let aiMessage = ChatMessage(
            content: "Let me give you a quick explanation about \(topic)...",
            isFromUser: false,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(aiMessage)
        }
        
        // Simulate API call for explanation
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let explanation = ChatMessage(
            content: generateQuickExplanation(for: topic),
            isFromUser: false,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(explanation)
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        // Offer to create full course
        let followUp = ChatMessage(
            content: "Would you like a full immersive course on this topic?",
            isFromUser: false,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(followUp)
            currentQuickActions = [
                QuickAction(icon: "✓", title: "Yes, create a course", subtitle: nil, value: "yes"),
                QuickAction(icon: "✗", title: "No, I'm good", subtitle: nil, value: "no")
            ]
        }
        
        conversationState = .waitingForTopic
    }
    
    // Generate quick explanation
    private func generateQuickExplanation(for topic: String) -> String {
        return """
        \(topic.capitalized) is a fascinating subject! Here's a brief overview:
        
        • Core concept: Understanding the fundamental principles
        • Key applications: Real-world uses and implementations
        • Why it matters: Impact on technology and society
        
        This is just a quick summary. A full course would include interactive labs, quizzes, and hands-on projects in an immersive Unity environment!
        """
    }
    
    // Ask clarifying question
    private func askClarifyingQuestion(_ topic: String) async {
        conversationState = .clarifyingTopic
        
        let aiMessage = ChatMessage(
            content: "Interesting! To create the perfect course for you, could you be more specific about what aspect of \(topic) interests you most?",
            isFromUser: false,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(aiMessage)
        }
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        // Generate quick action options based on topic
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentQuickActions = generateClarifyingOptions(for: topic)
        }
    }
    
    // Generate clarifying options
    private func generateClarifyingOptions(for topic: String) -> [QuickAction] {
        let lowercased = topic.lowercased()
        
        if lowercased.contains("machine learning") || lowercased.contains("ml") || lowercased.contains("ai") {
            return [
                QuickAction(icon: "🤖", title: "Building ML models", subtitle: "Hands-on implementation", value: "building"),
                QuickAction(icon: "📚", title: "Understanding theory", subtitle: "Mathematical foundations", value: "theory"),
                QuickAction(icon: "🌍", title: "Real-world applications", subtitle: "Practical use cases", value: "applications")
            ]
        } else if lowercased.contains("quantum") || lowercased.contains("physics") {
            return [
                QuickAction(icon: "⚛️", title: "Core principles", subtitle: "Wave-particle duality, superposition", value: "principles"),
                QuickAction(icon: "💻", title: "Quantum computing", subtitle: "Qubits and algorithms", value: "computing"),
                QuickAction(icon: "🔬", title: "Experimental physics", subtitle: "Lab techniques", value: "experimental")
            ]
        } else if lowercased.contains("program") || lowercased.contains("code") || lowercased.contains("swift") {
            return [
                QuickAction(icon: "📱", title: "iOS Development", subtitle: "Build iPhone apps", value: "ios"),
                QuickAction(icon: "🎮", title: "Game Development", subtitle: "Create interactive games", value: "games"),
                QuickAction(icon: "🌐", title: "Web Development", subtitle: "Full-stack applications", value: "web")
            ]
        } else {
            return [
                QuickAction(icon: "📖", title: "Fundamentals", subtitle: "Start from the basics", value: "fundamentals"),
                QuickAction(icon: "🚀", title: "Advanced topics", subtitle: "Deep dive", value: "advanced"),
                QuickAction(icon: "💼", title: "Practical applications", subtitle: "Real-world use", value: "practical")
            ]
        }
    }
    
    // Handle clarification
    private func handleClarification(_ input: String) async {
        currentFocus = input
        
        let aiMessage = ChatMessage(
            content: "Perfect! Now I have a clear picture. Let me ask about your experience level.",
            isFromUser: false,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(aiMessage)
            currentQuickActions = nil
        }
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        await askForLevel()
    }
    
    // Ask for course level
    private func askForLevel() async {
        conversationState = .selectingLevel
        
        let aiMessage = ChatMessage(
            content: "What level would you like?",
            isFromUser: false,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(aiMessage)
        }
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            currentQuickActions = [
                QuickAction(
                    icon: "🌱",
                    title: "Beginner",
                    subtitle: "Never studied this before",
                    value: "beginner"
                ),
                QuickAction(
                    icon: "📚",
                    title: "Intermediate",
                    subtitle: "Know the basics",
                    value: "intermediate"
                ),
                QuickAction(
                    icon: "🎓",
                    title: "Advanced",
                    subtitle: "Ready for deep dive",
                    value: "advanced"
                ),
                QuickAction(
                    icon: "💬",
                    title: "Quick Explanation",
                    subtitle: "Just a simple overview",
                    value: "explanation"
                )
            ]
        }
    }
    
    // Handle level selection
    private func handleLevelSelection(_ input: String) async {
        let lowercased = input.lowercased()
        
        if lowercased.contains("explanation") || lowercased.contains("simple") || lowercased.contains("quick") {
            await provideQuickExplanation(currentTopic)
            return
        }
        
        // Determine level
        if lowercased.contains("beginner") || lowercased.contains("🌱") {
            currentLevel = .beginner
        } else if lowercased.contains("intermediate") || lowercased.contains("📚") {
            currentLevel = .intermediate
        } else {
            currentLevel = .advanced
        }
        
        // Track level preference
        analytics.trackLevelPreference(level: currentLevel?.rawValue ?? "beginner")
        
        let aiMessage = ChatMessage(
            content: "Excellent! Creating your personalized learning journey...",
            isFromUser: false,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(aiMessage)
            currentQuickActions = nil
        }
        
        // Track course generation started
        analytics.trackCourseGenerationStarted(
            topic: currentTopic,
            level: currentLevel?.rawValue ?? "beginner",
            focus: currentFocus
        )
        
        // Generate course
        await generateCourse()
    }
    
    // Generate course journey
    private func generateCourse() async {
        conversationState = .generatingCourse
        
        // Use real AI backend for course generation
        let aiService = AICourseGenerationService.shared
        
        do {
            // Convert course level to LearningLevel enum
            let learningLevel: LearningLevel
            switch currentLevel {
            case .beginner:
                learningLevel = .beginner
            case .intermediate:
                learningLevel = .intermediate
            case .advanced:
                learningLevel = .expert
            case .none:
                learningLevel = .beginner
            }
            
            // Generate course using real backend
            let generatedCourse = try await aiService.generateCourse(
                topic: currentTopic,
                level: learningLevel,
                outcomes: [],
                pedagogy: nil
            )
            
            // Convert to CourseJourney
            let journey = convertToJourney(from: generatedCourse)
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                generatedJourney = journey
            }
            
            // Track successful course generation
            analytics.trackCourseGenerationCompleted(
                topic: currentTopic,
                level: currentLevel?.rawValue ?? "beginner",
                moduleCount: journey.modules.count,
                duration: journey.duration,
                xpReward: journey.xpReward,
                usedBackend: true
            )
            
            // Track topic interest for personalization
            let category = extractCategory(from: currentTopic)
            analytics.trackTopicInterest(topic: currentTopic, category: category)
            
            let aiMessage = ChatMessage(
                content: "Here's your personalized learning journey:",
                isFromUser: false,
                timestamp: Date()
            )
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                messages.append(aiMessage)
            }
            
            // Start countdown
            startAutoLaunch()
            
        } catch {
            // Track failure
            analytics.trackCourseGenerationFailed(
                topic: currentTopic,
                level: currentLevel?.rawValue ?? "beginner",
                error: error.localizedDescription
            )
            
            // Fallback to simulated course if backend fails
            print("⚠️ Backend course generation failed: \(error.localizedDescription)")
            print("📦 Using fallback simulated course")
            
            let journey = CourseJourney(
                title: "\(currentTopic.capitalized) \(currentLevel?.rawValue.capitalized ?? "") Course",
                subtitle: currentFocus ?? "Comprehensive learning path",
                duration: currentLevel == .beginner ? "1.5 hours" : currentLevel == .intermediate ? "2.5 hours" : "4 hours",
                modules: generateModules(),
                environment: getEnvironment(for: currentTopic),
                xpReward: currentLevel == .beginner ? 300 : currentLevel == .intermediate ? 500 : 800
            )
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                generatedJourney = journey
            }
            
            // Track fallback course generation
            analytics.trackCourseGenerationCompleted(
                topic: currentTopic,
                level: currentLevel?.rawValue ?? "beginner",
                moduleCount: journey.modules.count,
                duration: journey.duration,
                xpReward: journey.xpReward,
                usedBackend: false
            )
            
            let aiMessage = ChatMessage(
                content: "Here's your personalized learning journey:",
                isFromUser: false,
                timestamp: Date()
            )
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                messages.append(aiMessage)
            }
            
            startAutoLaunch()
        }
    }
    
    // Convert GeneratedCourse to CourseJourney
    private func convertToJourney(from generatedCourse: GeneratedCourse) -> CourseJourney {
        // Map lessons to modules
        let modules: [CourseModule] = generatedCourse.lessons.enumerated().map { index, lesson in
            let icon = getIconForLesson(lesson.title, index: index)
            let type: ModuleType = index == 0 ? .intro :
                                   index == generatedCourse.lessons.count - 1 ? .project :
                                   index % 3 == 0 ? .quiz :
                                   index % 2 == 0 ? .lab : .lesson
            
            return CourseModule(
                title: lesson.title,
                icon: icon,
                type: type
            )
        }
        
        return CourseJourney(
            title: generatedCourse.title,
            subtitle: generatedCourse.description ?? "AI-generated learning path",
            duration: "\(generatedCourse.totalDuration) minutes",
            modules: modules,
            environment: generatedCourse.unitySceneName,
            xpReward: generatedCourse.totalXP
        )
    }
    
    // Get icon for lesson
    private func getIconForLesson(_ title: String, index: Int) -> String {
        let lowercased = title.lowercased()
        
        if lowercased.contains("intro") || index == 0 {
            return "🎯"
        } else if lowercased.contains("lab") || lowercased.contains("practice") {
            return "🔬"
        } else if lowercased.contains("quiz") || lowercased.contains("test") {
            return "✓"
        } else if lowercased.contains("project") || lowercased.contains("final") {
            return "🏆"
        } else {
            return "📚"
        }
    }
    
    // Generate course modules
    private func generateModules() -> [CourseModule] {
        return [
            CourseModule(title: "Start", icon: "🎯", type: .intro),
            CourseModule(title: "Core Concepts", icon: "📚", type: .lesson),
            CourseModule(title: "Lab 1", icon: "🔬", type: .lab),
            CourseModule(title: "Lab 2", icon: "⚗️", type: .lab),
            CourseModule(title: "Quiz", icon: "✓", type: .quiz),
            CourseModule(title: "Final Project", icon: "🏆", type: .project)
        ]
    }
    
    // Get environment based on topic
    private func getEnvironment(for topic: String) -> String {
        let lowercased = topic.lowercased()
        
        if lowercased.contains("chemistry") || lowercased.contains("science") {
            return "Virtual Chemistry Lab"
        } else if lowercased.contains("space") || lowercased.contains("mars") || lowercased.contains("astronomy") {
            return "Mars Surface Station"
        } else if lowercased.contains("history") || lowercased.contains("maya") || lowercased.contains("ancient") {
            return "Historical Environment"
        } else if lowercased.contains("code") || lowercased.contains("programming") || lowercased.contains("swift") {
            return "Interactive Code Lab"
        } else {
            return "Immersive Learning Space"
        }
    }
    
    // Start auto-launch countdown
    private func startAutoLaunch() {
        guard let journey = generatedJourney else { return }
        
        // Track countdown started
        analytics.trackCountdownStarted(courseTitle: journey.title)
        
        countdown = 3
        
        let generator = UINotificationFeedbackGenerator()
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                if let count = self.countdown, count > 0 {
                    self.countdown = count - 1
                    generator.notificationOccurred(.warning)
                } else {
                    timer.invalidate()
                    generator.notificationOccurred(.success)
                    self.launchCourse()
                }
            }
        }
    }
    
    // Launch Unity course
    func launchCourse() {
        guard let journey = generatedJourney else { return }
        
        // Calculate time to launch
        let timeToLaunch = conversationStartTime.map { Date().timeIntervalSince($0) } ?? 0
        
        // Track course launch
        analytics.trackCourseLaunched(
            courseTitle: journey.title,
            topic: currentTopic,
            level: currentLevel?.rawValue ?? "beginner",
            environment: journey.environment,
            timeToLaunch: timeToLaunch
        )
        
        // Convert journey to LearningResource
        let resource = LearningResource(
            id: UUID().uuidString,
            title: journey.title,
            description: journey.subtitle,
            category: extractCategory(from: currentTopic),
            difficulty: currentLevel?.rawValue.capitalized,
            duration: Int(journey.duration.split(separator: " ").first.flatMap { Double($0) } ?? 1 * 60),
            thumbnailUrl: nil,
            imageUrl: nil,
            url: nil,
            provider: "Lyo Academy",
            providerName: "Lyo Academy",
            providerUrl: nil,
            enrolledCount: 0,
            isEnrolled: true,
            reviews: nil,
            updatedAt: ISO8601DateFormatter().string(from: Date()),
            createdAt: ISO8601DateFormatter().string(from: Date()),
            authorCreator: "AI Tutor",
            estimatedDuration: journey.duration,
            rating: 5.0,
            difficultyLevel: currentLevel ?? .intermediate,
            contentType: .course,
            resourcePlatform: .lyo,
            tags: [currentTopic, currentLevel?.rawValue ?? "course"],
            isBookmarked: false,
            progress: 0,
            publishedDate: Date()
        )
        
        // Launch via LearningDataManager
        Task {
            await LearningDataManager.shared.launchCourse(resource)
        }
    }
    
    // Extract category from topic
    private func extractCategory(from topic: String) -> String? {
        let lowercased = topic.lowercased()
        
        if lowercased.contains("code") || lowercased.contains("programming") || lowercased.contains("swift") {
            return "Programming"
        } else if lowercased.contains("science") || lowercased.contains("physics") || lowercased.contains("chemistry") {
            return "Science"
        } else if lowercased.contains("history") || lowercased.contains("maya") || lowercased.contains("ancient") {
            return "History"
        } else if lowercased.contains("data") || lowercased.contains("machine learning") || lowercased.contains("ml") {
            return "Data Science"
        } else {
            return "General"
        }
    }
    
    // End conversation
    private func endConversation() async {
        let aiMessage = ChatMessage(
            content: "No problem! Feel free to ask me anything else you'd like to learn about. I'm here to help! 😊",
            isFromUser: false,
            timestamp: Date()
        )
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            messages.append(aiMessage)
        }
        
        conversationState = .waitingForTopic
    }
}

// MARK: - Supporting Types
enum ConversationState {
    case greeting
    case waitingForTopic
    case clarifyingTopic
    case selectingLevel
    case generatingCourse
}

enum LearningIntent {
    case quickExplanation
    case fullCourse
    case unclear
}

enum CourseLevel: String {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
}

// MARK: - Data Models
// Using canonical ChatMessage from Models/ChatMessage.swift
// typealias ChatMessage = AIMessage (already defined globally)

struct QuickAction: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String?
    let value: String
}

struct CourseJourney: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let duration: String
    let modules: [CourseModule]
    let environment: String
    let xpReward: Int
}

struct CourseModule: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let type: ModuleType
}

enum ModuleType {
    case intro
    case lesson
    case lab
    case quiz
    case project
}
