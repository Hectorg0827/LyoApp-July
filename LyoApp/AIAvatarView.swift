import SwiftUI
import Foundation
import AVFoundation

// MARK: - Environment Themes
enum EnvironmentTheme: String, CaseIterable {
    case cosmic = "cosmic"
    case ocean = "ocean"
    case forest = "forest"
    case aurora = "aurora"
    case sunset = "sunset"
    
    var backgroundColors: [Color] {
        switch self {
        case .cosmic:
            return [.purple.opacity(0.8), .blue.opacity(0.6), .black.opacity(0.9)]
        case .ocean:
            return [.cyan.opacity(0.7), .blue.opacity(0.8), .teal.opacity(0.6)]
        case .forest:
            return [.green.opacity(0.6), .mint.opacity(0.5), .teal.opacity(0.7)]
        case .aurora:
            return [.green.opacity(0.6), .cyan.opacity(0.7), .purple.opacity(0.5)]
        case .sunset:
            return [.orange.opacity(0.7), .pink.opacity(0.6), .purple.opacity(0.5)]
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .cosmic: return .cyan
        case .ocean: return .blue
        case .forest: return .green
        case .aurora: return .mint
        case .sunset: return .orange
        }
    }
    
    var shapeCount: Int {
        switch self {
        case .cosmic: return 8
        case .ocean: return 6
        case .forest: return 5
        case .aurora: return 7
        case .sunset: return 6
        }
    }
}

// MARK: - Avatar Personalities
enum AvatarPersonality: String, CaseIterable {
    case mentor = "mentor"
    case friend = "friend"
    case sage = "sage"
    case explorer = "explorer"
    case innovator = "innovator"
    
    var iconName: String {
        switch self {
        case .mentor: return "graduationcap.fill"
        case .friend: return "heart.fill"
        case .sage: return "brain.head.profile"
        case .explorer: return "safari.fill"
        case .innovator: return "lightbulb.fill"
        }
    }
    
    var glowColors: [Color] {
        switch self {
        case .mentor: return [.blue.opacity(0.8), .cyan.opacity(0.6)]
        case .friend: return [.pink.opacity(0.7), .purple.opacity(0.5)]
        case .sage: return [.purple.opacity(0.8), .indigo.opacity(0.6)]
        case .explorer: return [.green.opacity(0.7), .teal.opacity(0.5)]
        case .innovator: return [.yellow.opacity(0.8), .orange.opacity(0.6)]
        }
    }
    
    var coreColors: [Color] {
        switch self {
        case .mentor: return [.blue, .cyan]
        case .friend: return [.pink, .purple]
        case .sage: return [.purple, .indigo]
        case .explorer: return [.green, .teal]
        case .innovator: return [.yellow, .orange]
        }
    }
}

// MARK: - Conversation Modes
enum ConversationMode: String, CaseIterable {
    case friendly = "friendly"
    case professional = "professional"
    case casual = "casual"
    case focused = "focused"
    
    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .professional: return "Professional"
        case .casual: return "Casual"
        case .focused: return "Focused"
        }
    }
}

// MARK: - Learning Context
struct LearningContext {
    let topic: String
    let difficulty: LearningDifficulty
    let objectives: [String]
    let duration: Int // in minutes
    let createdAt: Date
    
    enum LearningDifficulty: String, CaseIterable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
    }
}

// MARK: - Message Types
struct ImmersiveMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let mood: AvatarMood?
    let actions: [MessageAction]
    let suggestions: [String]
    let actionPerformed: ImmersiveQuickAction?
    
    init(id: UUID, content: String, isFromUser: Bool, timestamp: Date, mood: AvatarMood? = nil, actions: [MessageAction] = [], suggestions: [String] = [], actionPerformed: ImmersiveQuickAction? = nil) {
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
    case like, share, expand, clarify, practice, save
}

enum AvatarMood: String, Codable, CaseIterable {
    case friendly, excited, supportive, curious, empathetic, thoughtful, engaged, thinking
    
    var displayName: String {
        switch self {
        case .friendly: return "Friendly"
        case .excited: return "Excited"
        case .supportive: return "Supportive"
        case .curious: return "Curious"
        case .empathetic: return "Empathetic"
        case .thoughtful: return "Thoughtful"
        case .engaged: return "Engaged"
        case .thinking: return "Thinking"
        }
    }
}

struct ImmersiveQuickAction: Identifiable, Codable {
    let id: UUID
    let type: ImmersiveQuickActionType
    let title: String
    let description: String
    let iconName: String
}

enum ImmersiveQuickActionType: String, Codable {
    case generateCourse, quickHelp, practiceMode, explore
}

// MARK: - Real AI Avatar Engine (Connected to Gemini AI)
@MainActor
class ImmersiveAvatarEngine: ObservableObject {
    @Published var conversationHistory: [ImmersiveMessage] = []
    @Published var currentMood: AvatarMood = .friendly
    @Published var isThinking: Bool = false
    @Published var isTyping: Bool = false
    @Published var quickActions: [ImmersiveQuickAction] = []
    @Published var networkComplexity: Double = 0.3
    @Published var statusMessage: String = "Ready to learn with you!"
    
    // Track questions asked - limit to 3 before delivering course
    @Published var questionsAsked: Int = 0
    @Published var detectedTopic: String = ""
    @Published var detectedLevel: String = "beginner"
    
    private let aiService = AIAvatarAPIClient.shared
    private let maxQuestions = 3 // Maximum questions before delivering course
    
    func startSession() async {
        print("🤖 [ImmersiveEngine] Starting AI session with backend")

        // Get time-based greeting and user name
        let timeGreeting = getTimeBasedGreeting()
        let userName = getUserName()

        let greeting = """
        \(timeGreeting), \(userName)! 👋

        I'm Lyo, your AI learning companion. What would you like to learn today?

        I can:
        • Give quick explanations for simple questions
        • Create comprehensive interactive courses
        • Help you master any subject at your own pace
        """

        let welcomeMessage = ImmersiveMessage(
            id: UUID(),
            content: greeting,
            isFromUser: false,
            timestamp: Date(),
            mood: .friendly,
            actions: []
        )

        conversationHistory.append(welcomeMessage)
        updateQuickActions()

        // Check Gemini AI availability
        if APIKeys.isGeminiAPIKeyConfigured {
            print("✅ [ImmersiveEngine] Gemini AI configured and ready")
            statusMessage = "AI Ready ✨"
            networkComplexity = 0.8
        } else {
            print("⚠️ [ImmersiveEngine] Gemini API key not configured")
            statusMessage = "AI Ready (limited mode)"
            networkComplexity = 0.3
        }
    }

    private func getTimeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Hello"
        }
    }

    private func getUserName() -> String {
        // Try to get user name from AppState
        // For now, return a friendly default
        return "there"
    }
    
    func processMessage(_ content: String) async {
        print("🤖 [ImmersiveEngine] Processing user message: \(content)")

        let userMessage = ImmersiveMessage(
            id: UUID(),
            content: content,
            isFromUser: true,
            timestamp: Date()
        )

        conversationHistory.append(userMessage)

        isThinking = true
        isTyping = true
        networkComplexity = 0.9 // Show high network activity
        
        // Extract topic from user's message
        if detectedTopic.isEmpty {
            detectedTopic = extractTopicFromMessage(content)
        }
        
        // Extract experience level if mentioned
        detectExperienceLevel(content)

        do {
            // Check if we've reached question limit
            if questionsAsked >= maxQuestions {
                print("🎓 [ImmersiveEngine] Maximum questions reached. Delivering course now!")
                await deliverCourseDirectly()
                return
            }
            
            // Analyze learning intent
            let intent = analyzeLearningIntent(content)

            // Build conversation context for better responses
            let conversationContext = buildConversationContext()

            let fullPrompt: String

            switch intent {
            case .quickQuestion:
                // User wants a quick explanation - give direct answer and offer course
                fullPrompt = """
                You are Lyo, an expert AI learning companion.

                **Conversation History:**
                \(conversationContext)

                **User's Question:** \(content)

                **Your Task:**
                1. Provide a CLEAR, DIRECT answer to their question (2-3 sentences)
                2. Say: "Would you like me to create a full interactive course on this topic? Just say 'yes' or tap the Create Course button! 🎓"

                Keep it conversational and engaging. NO additional questions - offer the course directly!
                """
                // Don't increment question counter for quick questions
                questionsAsked = 0

            case .needsProbing:
                // Only ask essential questions, max 3 total
                let questionsRemaining = maxQuestions - questionsAsked
                
                if questionsAsked == 0 {
                    // First question: What specifically?
                    fullPrompt = """
                    You are Lyo, gathering essential information to create a perfect course.

                    **User's Interest:** \(content)

                    **Your Task:**
                    Ask ONE specific question: "What specific aspect of \(content) would you like to focus on?"
                    
                    Provide 2-3 example options to make it easy for them to choose.
                    
                    Keep it brief and actionable! (Questions left: \(questionsRemaining - 1))
                    """
                } else if questionsAsked == 1 {
                    // Second question: Experience level?
                    fullPrompt = """
                    You are Lyo, almost ready to create their course.

                    **Conversation History:**
                    \(conversationContext)

                    **Your Task:**
                    Ask ONE question: "What's your current experience level with \(detectedTopic)?" 
                    
                    Offer clear options: Beginner, Intermediate, or Advanced?
                    
                    Keep it brief! (Questions left: \(questionsRemaining - 1))
                    """
                } else {
                    // Third/final question: Quick explanation or full course?
                    fullPrompt = """
                    You are Lyo, ready to deliver content.

                    **Conversation History:**
                    \(conversationContext)

                    **Your Task:**
                    Ask THE FINAL question: "Would you like a quick 5-minute explanation or a comprehensive full course?"
                    
                    Make it clear these are the only two options. This is the last question!
                    
                    Keep it extremely brief!
                    """
                }
                questionsAsked += 1

            case .fullCourse:
                // User clearly wants a comprehensive course - deliver immediately!
                fullPrompt = """
                You are Lyo, confirming course creation.

                **User wants to learn:** \(content)

                **Your Task:**
                Say: "Perfect! I'm creating your interactive \(detectedTopic) course right now! 🎓✨"
                
                Keep it to 1 sentence - we're delivering the course immediately!
                """
                questionsAsked = maxQuestions // Force course delivery after this
            }

            print("🤖 [ImmersiveEngine] Calling Gemini AI with intent: \(intent)")
            let aiResponseText = try await aiService.generateWithGemini(fullPrompt)

            print("✅ [ImmersiveEngine] Received Gemini response")

            // Determine appropriate actions based on intent
            let actions = getActionsForIntent(intent, topic: content)

            let aiMessage = ImmersiveMessage(
                id: UUID(),
                content: aiResponseText,
                isFromUser: false,
                timestamp: Date(),
                mood: currentMood,
                actions: actions
            )

            conversationHistory.append(aiMessage)
            networkComplexity = 0.5 // Return to normal

        } catch {
            print("❌ [ImmersiveEngine] AI generation failed: \(error.localizedDescription)")

            // Fallback to helpful error message
            let errorMessage = ImmersiveMessage(
                id: UUID(),
                content: "I'm having trouble connecting right now. Could you tell me more about what you'd like to learn about \(content)?",
                isFromUser: false,
                timestamp: Date(),
                mood: .thinking,
                actions: []
            )

            conversationHistory.append(errorMessage)
            networkComplexity = 0.3
        }

        isThinking = false
        isTyping = false
    }

    private enum LearningIntent {
        case quickQuestion      // Quick explanation - stay in chat
        case needsProbing      // Need more info before deciding
        case fullCourse        // Ready for comprehensive course
    }

    private func analyzeLearningIntent(_ message: String) -> LearningIntent {
        let lowercased = message.lowercased()

        // Full course indicators
        let courseKeywords = ["teach me", "create a course", "create course", "full course",
                            "learn everything", "master", "comprehensive", "deep dive"]
        if courseKeywords.contains(where: { lowercased.contains($0) }) {
            return .fullCourse
        }

        // Quick question indicators
        let questionKeywords = ["what is", "what's", "explain", "how does", "why",
                              "can you tell me", "quick question", "briefly"]
        if questionKeywords.contains(where: { lowercased.contains($0) }) {
            return .quickQuestion
        }

        // Single-word or very short responses likely need probing
        if message.split(separator: " ").count <= 2 {
            return .needsProbing
        }

        // Default to probing to understand better
        return .needsProbing
    }

    private func getActionsForIntent(_ intent: LearningIntent, topic: String) -> [MessageAction] {
        switch intent {
        case .quickQuestion:
            return [
                MessageAction(id: UUID(), type: .expand, title: "Create Full Course", iconName: "graduationcap"),
                MessageAction(id: UUID(), type: .practice, title: "Practice This", iconName: "target"),
                MessageAction(id: UUID(), type: .save, title: "Save", iconName: "bookmark")
            ]

        case .needsProbing:
            return [
                MessageAction(id: UUID(), type: .expand, title: "Tell Me More", iconName: "bubble.left"),
                MessageAction(id: UUID(), type: .clarify, title: "Start Over", iconName: "arrow.counterclockwise")
            ]

        case .fullCourse:
            return [
                MessageAction(id: UUID(), type: .expand, title: "Create Course", iconName: "play.circle.fill"),
                MessageAction(id: UUID(), type: .clarify, title: "Change Topic", iconName: "arrow.counterclockwise")
            ]
        }
    }
    
    private func buildConversationContext() -> String {
        // Get last 3 messages for context (excluding current)
        let recentMessages = conversationHistory.suffix(6)
        var context = ""
        
        for message in recentMessages {
            let role = message.isFromUser ? "User" : "Lyo"
            context += "\(role): \(message.content)\n"
        }
        
        return context.isEmpty ? "This is the start of the conversation." : context
    }
    
    private func extractTopicFromMessage(_ message: String) -> String {
        // Simple extraction - look for key phrases
        let lowercased = message.lowercased()
        
        // Remove common phrases
        let cleaned = lowercased
            .replacingOccurrences(of: "i want to learn", with: "")
            .replacingOccurrences(of: "teach me", with: "")
            .replacingOccurrences(of: "about", with: "")
            .replacingOccurrences(of: "create a course on", with: "")
            .replacingOccurrences(of: "create course on", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return cleaned.isEmpty ? message : cleaned
    }
    
    private func detectExperienceLevel(_ message: String) {
        let lowercased = message.lowercased()
        
        if lowercased.contains("beginner") || lowercased.contains("new to") || lowercased.contains("never") {
            detectedLevel = "beginner"
        } else if lowercased.contains("intermediate") || lowercased.contains("some experience") {
            detectedLevel = "intermediate"
        } else if lowercased.contains("advanced") || lowercased.contains("expert") || lowercased.contains("experienced") {
            detectedLevel = "advanced"
        }
    }
    
    private func deliverCourseDirectly() async {
        print("🎓 [ImmersiveEngine] Delivering course for topic: \(detectedTopic), level: \(detectedLevel)")
        
        let deliveryMessage = ImmersiveMessage(
            id: UUID(),
            content: """
            Perfect! I've gathered enough information. 🎓✨
            
            I'm now creating your personalized **\(detectedTopic)** course at the **\(detectedLevel)** level!
            
            Your interactive classroom will include:
            • Structured lessons tailored to your level
            • Hands-on practice exercises
            • Real-world examples and projects
            • Progress tracking and quizzes
            
            Let's start your learning journey! 🚀
            """,
            isFromUser: false,
            timestamp: Date(),
            mood: .excited,
            actions: [
                MessageAction(id: UUID(), type: .expand, title: "Start Course Now", iconName: "play.circle.fill")
            ]
        )
        
        conversationHistory.append(deliveryMessage)
        isThinking = false
        isTyping = false
        networkComplexity = 0.5
        
        // Reset question counter for next conversation
        questionsAsked = 0
    }
    
    func performAction(_ action: ImmersiveQuickAction) async {
        print("🤖 [ImmersiveEngine] Performing quick action: \(action.title)")
        
        isThinking = true
        networkComplexity = 0.7
        
        do {
            let prompt: String
            
            switch action.type {
            case .generateCourse:
                prompt = """
                You are Lyo, an expert course creator. The user clicked "Create Course".
                
                Ask them what specific topic they want to learn about, then offer to create a comprehensive course with:
                • Course title and overview
                • 3-5 structured modules
                • Hands-on projects for each module
                • Learning objectives
                • Practice exercises and quizzes
                
                Be enthusiastic and specific about what the course will include!
                """
                
            case .quickHelp:
                prompt = """
                You are Lyo, a helpful AI assistant. The user clicked "Quick Help".
                
                Offer to help with:
                • Answering any learning questions
                • Creating custom courses
                • Finding study resources
                • Explaining difficult concepts
                • Practice exercises
                
                Ask what they need help with and be ready to provide immediate assistance!
                """
                
            case .practiceMode:
                prompt = """
                You are Lyo, a practice exercise creator. The user wants to practice.
                
                Ask what topic they want to practice, then create:
                • 3-5 interactive practice questions
                • Real-world scenarios to apply knowledge
                • Hands-on coding/writing exercises (if applicable)
                • Step-by-step solutions
                
                Make practice engaging and practical!
                """
                
            case .explore:
                prompt = """
                You are Lyo, a learning path explorer. The user wants to discover new topics.
                
                Suggest 3-4 exciting learning paths across different fields:
                • Technology (AI, web development, data science)
                • Science (physics, biology, chemistry)
                • Arts & Humanities (design, writing, history)
                • Business (entrepreneurship, marketing, finance)
                
                For each path, briefly explain what they'll learn and why it's valuable. Make it inspiring!
                """
            }
            
            print("🤖 [ImmersiveEngine] Calling Gemini for quick action...")
            let aiResponseText = try await aiService.generateWithGemini(prompt)
            
            print("✅ [ImmersiveEngine] Quick action response generated")
            
            let aiMessage = ImmersiveMessage(
                id: UUID(),
                content: aiResponseText,
                isFromUser: false,
                timestamp: Date(),
                mood: currentMood,
                actions: [
                    MessageAction(id: UUID(), type: .practice, title: "Let's Start", iconName: "play.circle"),
                    MessageAction(id: UUID(), type: .expand, title: "More Options", iconName: "ellipsis.circle")
                ]
            )
            
            conversationHistory.append(aiMessage)
            
        } catch {
            print("❌ [ImmersiveEngine] Quick action failed: \(error.localizedDescription)")
            
            let fallbackMessage = ImmersiveMessage(
                id: UUID(),
                content: "I'd love to help you with \(action.title)! Could you tell me more about what you're interested in learning?",
                isFromUser: false,
                timestamp: Date(),
                mood: currentMood,
                actions: []
            )
            
            conversationHistory.append(fallbackMessage)
        }
        
        isThinking = false
        networkComplexity = 0.4
    }
    
    func handleMessageAction(_ action: MessageAction, for message: ImmersiveMessage) async {
        print("🤖 [ImmersiveEngine] Handling message action: \(action.title)")
        
        // Check if this is a course creation action
        if action.title.contains("Course") || action.title.contains("Start") {
            print("🎓 [ImmersiveEngine] Triggering course creation flow")
            // Signal that course flow should be shown
            // This will be handled by the parent view
            return
        }
        
        isThinking = true
        
        do {
            let prompt: String
            
            switch action.type {
            case .practice:
                prompt = "Based on the previous message '\(message.content)', create a short interactive practice exercise or quiz to help the user practice this concept. Make it engaging and educational."
                
            case .expand:
                // Check if this is asking for a course
                if action.title.contains("Course") {
                    print("🎓 [ImmersiveEngine] User requested course via expand action")
                    prompt = "Confirm that you're creating a comprehensive interactive course for them. Be enthusiastic and brief!"
                    questionsAsked = maxQuestions // Trigger course delivery
                } else {
                    prompt = "Based on the previous message '\(message.content)', provide more detailed information, examples, or related concepts. Go deeper into the topic."
                }
                
            case .save:
                prompt = "Acknowledge that you've saved this information for the user. Briefly summarize what was saved and mention they can review it later in their library."
                
            case .clarify:
                // Start over - reset conversation
                questionsAsked = 0
                detectedTopic = ""
                detectedLevel = "beginner"
                prompt = "Great! Let's start fresh. What would you like to learn today?"
                
            default:
                prompt = "Continue the conversation naturally based on: \(message.content)"
            }
            
            print("🤖 [ImmersiveEngine] Calling Gemini for message action...")
            let aiResponseText = try await aiService.generateWithGemini(prompt)
            
            let aiMessage = ImmersiveMessage(
                id: UUID(),
                content: aiResponseText,
                isFromUser: false,
                timestamp: Date(),
                mood: currentMood,
                actions: []
            )
            
            conversationHistory.append(aiMessage)
            
        } catch {
            print("❌ [ImmersiveEngine] Message action failed: \(error.localizedDescription)")
        }
        
        isThinking = false
    }
    
    func startVoiceRecording() {
        // Mock voice recording
    }
    
    func stopVoiceRecording() {
        // Mock stop voice recording
    }
    
    private func updateQuickActions() {
        quickActions = [
            ImmersiveQuickAction(
                id: UUID(),
                type: .quickHelp,
                title: "Quick Help",
                description: "Get instant assistance",
                iconName: "questionmark.circle"
            ),
            ImmersiveQuickAction(
                id: UUID(),
                type: .generateCourse,
                title: "Create Course",
                description: "Generate a learning path",
                iconName: "graduationcap"
            ),
            ImmersiveQuickAction(
                id: UUID(),
                type: .explore,
                title: "Explore",
                description: "Discover new topics",
                iconName: "safari"
            )
        ]
    }
}

// MARK: - Supporting Views

struct PersonalLibraryView: View {
    var body: some View {
        VStack {
            Text("Personal Library")
                .font(.title)
            Text("Your saved courses would be shown here")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// AIAvatarService is defined elsewhere

// MARK: - Visual Effect Stubs
struct ParticleSystemView: View {
    @Binding var isActive: Bool
    let theme: EnvironmentTheme
    
    var body: some View {
        // Simplified particle effect
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(theme.primaryColor.opacity(0.3))
                    .frame(width: 4, height: 4)
                    .offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -100...100))
                    .opacity(isActive ? 0.8 : 0.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(), value: isActive)
            }
        }
    }
}

struct NeuralNetworkView: View {
    let complexity: Double
    
    var body: some View {
        // Simplified neural network visualization
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<Int(complexity * 20), id: \.self) { _ in
                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: 2, height: 2)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
    }
}

struct FloatingShapeView: View {
    let index: Int
    let theme: EnvironmentTheme
    let isActive: Bool
    
    var body: some View {
        GeometryReader { geometry in
            Circle()
                .fill(theme.primaryColor.opacity(0.1))
                .frame(width: 20 + CGFloat(index * 5), height: 20 + CGFloat(index * 5))
                .position(
                    x: CGFloat.random(in: 50...max(100, geometry.size.width - 50)),
                    y: CGFloat.random(in: 100...max(150, geometry.size.height - 100))
                )
                .opacity(isActive ? 0.8 : 0.3)
                .animation(.easeInOut(duration: 3.0), value: isActive)
        }
    }
}

struct AIAvatarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var courseManager = CourseProgressManager.shared
    @StateObject private var immersiveEngine = ImmersiveAvatarEngine()
    @StateObject private var avatarManager = AvatarCustomizationManager()
    
    // Error handling
    @State private var initializationError: String?
    
    // Animation States
    @State private var avatarScale: CGFloat = 1.0
    @State private var energyPulse: CGFloat = 0.0
    @State private var particleAnimation = false
    @State private var hologramEffect = false
    @State private var backgroundGradient = 0.0
    
    // Interaction States
    @State private var messageText = ""
    @State private var isRecording = false
    @State private var showingCourseProgress = false
    @State private var showingLibrary = false
    @State private var showingCourseFlow = false
    @State private var showingAvatarPicker = false
    // @State private var currentCourseStep: CourseStep? // Removed - CourseStep type doesn't exist
    
    // Immersive Features
    @State private var conversationMode: ConversationMode = .friendly
    @State private var environmentTheme: EnvironmentTheme = .cosmic
    @State private var avatarPersonality: AvatarPersonality = .mentor
    @State private var learningContext: LearningContext?
    
    var body: some View {
        Group {
            if let error = initializationError {
                // Show error state
                errorView(error)
            } else {
                // Show normal view
                mainContentView
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("🤖 AIAvatarView onAppear called")
            initializeImmersiveSession()
            checkAvatarSelection()
        }
        .sheet(isPresented: $showingCourseProgress) {
            CourseProgressDetailView()
        }
        .sheet(isPresented: $showingLibrary) {
            LibraryView()
        }
        .fullScreenCover(isPresented: $showingAvatarPicker) {
            QuickAvatarPickerView(
                onComplete: { preset, name in
                    avatarManager.selectPreset(preset)
                    avatarManager.setName(name)
                    showingAvatarPicker = false
                },
                onSkip: {
                    showingAvatarPicker = false
                }
            )
        }
        .fullScreenCover(isPresented: $showingCourseFlow) {
            CourseBuilderView()
                .environmentObject(appState)
        }
    }
    
    private func checkAvatarSelection() {
        // ⚠️ FORCE SHOW FOR TESTING - Remove this line after testing
        // Uncomment the line below to always show avatar picker:
        // showingAvatarPicker = true
        
        // Check if this is first launch (no avatar selected)
        let hasSelectedAvatar = UserDefaults.standard.data(forKey: "userSelectedAvatar") != nil
        
        if !hasSelectedAvatar {
            // Show avatar picker on first launch
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingAvatarPicker = true
            }
        }
    }
    
    private var mainContentView: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Background Environment
                immersiveBackground
                
                // Particle Effects
                ParticleSystemView(isActive: $particleAnimation, theme: environmentTheme)
                
                // Main Content
                VStack(spacing: 0) {
                    // Immersive Header with Avatar
                    immersiveAvatarHeader
                    
                    // Dynamic Content Area
                    dynamicContentArea
                    
                    // Course Progress Indicator (if active)
                    if courseManager.hasActiveCourse {
                        courseProgressBar
                    }
                    
                    // Enhanced Input System
                    immersiveInputArea
                }
            }
        }
    }
    
    private func errorView(_ error: String) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("AI Avatar Error")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Text(error)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Button {
                    initializationError = nil
                    initializeImmersiveSession()
                } label: {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Go Back")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding()
        }
    }
    
    private var contentWithErrorHandling: some View {
        GeometryReader { geometry in
            ZStack {
                // Dynamic Background Environment
                immersiveBackground
                
                // Particle Effects
                ParticleSystemView(isActive: $particleAnimation, theme: environmentTheme)
                
                // Main Content
                VStack(spacing: 0) {
                    // Immersive Header with Avatar
                    immersiveAvatarHeader
                    
                    // Dynamic Content Area
                    dynamicContentArea
                    
                    // Course Progress Indicator (if active)
                    if courseManager.hasActiveCourse {
                        courseProgressBar
                    }
                    
                    // Enhanced Input System
                    immersiveInputArea
                }
            }
        }
    }
    
    // MARK: - Immersive Background (Enhanced Modern Design)
    private var immersiveBackground: some View {
        ZStack {
            // Deep slate-black base for modern tech aesthetic
            Color(red: 0.02, green: 0.05, blue: 0.13)
                .ignoresSafeArea()

            // Animated gradient orbs - top right
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.blue.opacity(0.25),
                            Color.blue.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: 150, y: -150)
                .scaleEffect(1.0 + sin(backgroundGradient * .pi / 180) * 0.1)
                .animation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true), value: backgroundGradient)

            // Animated gradient orbs - bottom left
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.purple.opacity(0.25),
                            Color.purple.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .blur(radius: 60)
                .offset(x: -150, y: 200)
                .scaleEffect(1.0 + cos(backgroundGradient * .pi / 180) * 0.1)
                .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true).delay(1.0), value: backgroundGradient)

            // Subtle neural network pattern
            NeuralNetworkView(complexity: immersiveEngine.networkComplexity)
                .opacity(0.15)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Immersive Avatar Header (Enhanced Modern Design)
    private var immersiveAvatarHeader: some View {
        VStack(spacing: 16) {
            // Status bar style top
            HStack {
                Text("Lyo AI")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                HStack(spacing: 8) {
                    // Active status indicator
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .opacity(0.3)
                                .scaleEffect(energyPulse)
                        )

                    Text("READY")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            // Floating Orb Avatar
            ZStack {
                // Outer glow ring - subtle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.4),
                                Color.purple.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                    .scaleEffect(1.0 + energyPulse * 0.15)

                // Main gradient orb with border
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue,
                                Color(red: 0.5, green: 0.3, blue: 0.8), // Purple
                                Color(red: 0.9, green: 0.3, blue: 0.6)  // Pink
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 88, height: 88)
                    .scaleEffect(avatarScale)

                // Inner dark circle for contrast
                Circle()
                    .fill(Color(red: 0.02, green: 0.05, blue: 0.13))
                    .frame(width: 80, height: 80)
                    .scaleEffect(avatarScale)

                // Sparkle icon
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color.blue.opacity(0.9))
                    .scaleEffect(0.9 + energyPulse * 0.1)

                // Active pulse indicator - bottom right
                if immersiveEngine.isThinking {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 24, height: 24)
                                .opacity(0.4)
                                .scaleEffect(energyPulse)
                        )
                        .offset(x: 36, y: 36)
                } else {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.02, green: 0.05, blue: 0.13), lineWidth: 3)
                        )
                        .offset(x: 36, y: 36)
                }
            }
            .onTapGesture {
                triggerAvatarInteraction()
            }

            // Title with gradient text
            VStack(spacing: 4) {
                Text("Lyo")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                // Status badge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .fill(Color.green)
                                .frame(width: 10, height: 10)
                                .opacity(0.3)
                        )

                    Text(immersiveEngine.statusMessage.uppercased())
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .tracking(1.5)
                }
            }
        }
        .padding(.bottom, 12)
    }
    
    // MARK: - Dynamic Content Area
    private var dynamicContentArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(immersiveEngine.conversationHistory) { message in
                        ImmersiveMessageBubble(
                            message: message,
                            theme: environmentTheme,
                            onActionTapped: { action in
                                handleMessageAction(action, for: message)
                            }
                        )
                        .id(message.id)
                    }
                    
                    // Typing indicator with enhanced animation
                    if immersiveEngine.isTyping {
                        ImmersiveTypingIndicator(theme: environmentTheme)
                            .id("typing")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: immersiveEngine.conversationHistory.count) { _, _ in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    if let lastMessage = immersiveEngine.conversationHistory.last {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Course Progress Bar
    private var courseProgressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text(courseManager.currentCourse?.title ?? "Current Course")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(courseManager.overallProgress * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            // Enhanced progress bar with milestones
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .frame(height: 8)
                    
                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * courseManager.overallProgress, height: 8)
                    
                    // Milestone markers
                    ForEach(courseManager.milestones, id: \.id) { milestone in
                        Circle()
                            .fill(milestone.isCompleted ? .white : .white.opacity(0.5))
                            .frame(width: 12, height: 12)
                            .offset(x: geometry.size.width * milestone.progressPercentage - 6)
                    }
                }
            }
            .frame(height: 12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Immersive Input Area (Enhanced Modern Design)
    private var immersiveInputArea: some View {
        VStack(spacing: 12) {
            // Quick Actions with floating pill style
            if immersiveEngine.quickActions.count > 0 {
                HStack(spacing: 8) {
                    ForEach(immersiveEngine.quickActions) { action in
                        Button(action: { performQuickAction(action) }) {
                            Text(action.title)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                        .background(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }

            // Main input area
            HStack(spacing: 12) {
                // Voice button with modern styling
                Button {
                    toggleVoiceInput()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                isRecording
                                    ? LinearGradient(
                                        colors: [Color.red, Color.pink],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.white.opacity(0.15), Color.white.opacity(0.08)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 48, height: 48)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )

                        // Microphone icon
                        Circle()
                            .fill(isRecording ? Color.white : Color.white.opacity(0.7))
                            .frame(width: 16, height: 16)

                        if isRecording {
                            // Pulsing outer ring
                            Circle()
                                .stroke(Color.red.opacity(0.6), lineWidth: 2)
                                .frame(width: 64, height: 64)
                                .scaleEffect(energyPulse)
                        }
                    }
                }
                .scaleEffect(isRecording ? 1.05 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isRecording)

                // Text input with glassmorphism
                HStack(spacing: 8) {
                    TextField("Ask Lyo anything...", text: $messageText)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .font(.system(size: 15))
                        .placeholder(when: messageText.isEmpty) {
                            Text("Ask Lyo anything...")
                                .foregroundColor(.white.opacity(0.4))
                                .font(.system(size: 15))
                        }

                    if !messageText.isEmpty {
                        Button {
                            sendMessage()
                        } label: {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                )
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .background(
                            Capsule()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Methods
    
    private func initializeImmersiveSession() {
        print("🤖 [AIAvatar] Starting initialization...")
        
        // Wrap everything in a safe block
        guard initializationError == nil else {
            print("⚠️ [AIAvatar] Skipping initialization - error already present")
            return
        }
        
        print("🤖 [AIAvatar] Setting up animations...")
        
        // Start animations safely
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            energyPulse = 1.0
        }
        
        withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: false)) {
            backgroundGradient = 360.0
        }
        
        hologramEffect = true
        particleAnimation = true
        
        print("✅ [AIAvatar] Animations started successfully")
        
        // Initialize avatar service
        Task { @MainActor in
            print("🤖 [AIAvatar] Starting immersive engine session...")
            await immersiveEngine.startSession()
            print("✅ [AIAvatar] Engine session started successfully")
        }
    }
    
    private func triggerAvatarInteraction() {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Scale animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            avatarScale = 1.2
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.1)) {
            avatarScale = 1.0
        }
        
        // Change avatar personality randomly
        avatarPersonality = AvatarPersonality.allCases.randomElement() ?? .mentor
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        // Check if user is requesting a course
        let courseKeywords = ["create a course", "create course", "make a course", "teach me", "learn about", "course on"]
        let lowercasedMessage = message.lowercased()
        let isCourseRequest = courseKeywords.contains(where: { lowercasedMessage.contains($0) })
        
        if isCourseRequest {
            // Transition to course creation flow
            showingCourseFlow = true
        } else {
            Task {
                await immersiveEngine.processMessage(message)
                
                // Auto-save course progress if in learning mode
                if let course = courseManager.currentCourse {
                    await courseManager.updateProgress(for: course.id, with: message)
                }
            }
        }
    }
    
    private func toggleVoiceInput() {
        isRecording.toggle()
        
        if isRecording {
            // Start voice recording
            immersiveEngine.startVoiceRecording()
        } else {
            // Stop and process voice
            immersiveEngine.stopVoiceRecording()
        }
    }
    
    private func performQuickAction(_ action: ImmersiveQuickAction) {
        Task {
            // If creating a course, transition to classroom flow
            if action.type == .generateCourse {
                // Transition to AIOnboardingFlowView which handles:
                // 1. Ask user for topic (TopicGatheringView)
                // 2. Generate course (GenesisScreenView)
                // 3. Show interactive classroom (AIClassroomView)
                await MainActor.run {
                    showingCourseFlow = true
                }
            } else {
                await immersiveEngine.performAction(action)
            }
        }
    }
    
    private func handleMessageAction(_ action: MessageAction, for message: ImmersiveMessage) {
        // Check if this is a course creation action
        if action.title.contains("Course") || action.title.contains("Start") {
            print("🎓 [AIAvatarView] Triggering course creation flow")
            showingCourseFlow = true
            return
        }
        
        Task {
            await immersiveEngine.handleMessageAction(action, for: message)
        }
    }
}

// MARK: - Supporting Views

struct ImmersiveMessageBubble: View {
    let message: ImmersiveMessage
    let theme: EnvironmentTheme
    let onActionTapped: (MessageAction) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer(minLength: 40)

                VStack(alignment: .trailing, spacing: 8) {
                    // User message bubble with gradient
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.blue.opacity(0.9),
                                            Color.purple.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    if !message.actions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(message.actions) { action in
                                ActionButton(action: action) {
                                    onActionTapped(action)
                                }
                            }
                        }
                    }
                }
            } else {
                // AI avatar icon
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    // AI message with glassmorphism
                    Text(message.content)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                                .background(
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )

                    if !message.actions.isEmpty {
                        HStack(spacing: 8) {
                            ForEach(message.actions) { action in
                                ActionButton(action: action) {
                                    onActionTapped(action)
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: 40)
            }
        }
    }
}

struct ActionButton: View {
    let action: MessageAction
    let onTapped: () -> Void

    var body: some View {
        Button(action: onTapped) {
            HStack(spacing: 6) {
                Image(systemName: action.iconName)
                    .font(.system(size: 11, weight: .medium))

                Text(action.title)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
                    .background(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Scale button style for better feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct QuickActionButton: View {
    let action: ImmersiveQuickAction
    let theme: EnvironmentTheme
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: 6) {
                Image(systemName: action.iconName)
                    .font(.title2)
                    .foregroundColor(theme.primaryColor)
                
                Text(action.title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(theme.primaryColor.opacity(0.5), lineWidth: 1)
                    )
            )
        }
    }
}

struct ImmersiveTypingIndicator: View {
    let theme: EnvironmentTheme
    @State private var animateScale = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // AI avatar icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                )

            // Typing dots with glassmorphism
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateScale ? 1.2 : 0.6)
                        .opacity(animateScale ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.15),
                            value: animateScale
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )

            Spacer(minLength: 40)
        }
        .onAppear {
            animateScale = true
        }
    }
}

// MARK: - TextField Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    AIAvatarView()
        .environmentObject(AppState())
}