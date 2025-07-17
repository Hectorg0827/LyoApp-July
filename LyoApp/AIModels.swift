import SwiftUI
import Foundation

// MARK: - AI Models
struct AIMessage: Identifiable, Codable, Equatable {
    var id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: MessageType
    let interactionId: Int?

    enum MessageType: String, Codable {
        case text, code, explanation, quiz, resource
    }
    
    init(id: UUID = UUID(), content: String, isFromUser: Bool, timestamp: Date = Date(), messageType: MessageType = .text, interactionId: Int? = nil) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.messageType = messageType
        self.interactionId = interactionId
    }
}

struct AIPersonality: Codable {
    let name: String
    let avatar: String
    let description: String
    let expertise: [String]
    let tone: String
    
    static let lyo = AIPersonality(
        name: "Lyo",
        avatar: "lightbulb.circle.fill",
        description: "Your personalized AI learning companion and Socratic tutor",
        expertise: ["Programming", "Design", "Technology", "Learning Strategies", "Critical Thinking", "Problem Solving"],
        tone: "Patient, inquisitive, encouraging, and Socratic"
    )
}

@MainActor
class AIConversationViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isTyping = false
    @Published var currentInput = ""
    @Published var personality = AIPersonality.lyo
    
    init() {
        // Add welcome message
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        let welcomeMessage = AIMessage(
            content: "Hello! I'm Lyo, your personalized AI learning companion. 💡✨ I'm not here to just give you answers – I want to guide you to discover them yourself. What would you like to explore and learn today? I'll ask thoughtful questions to help you understand deeply.",
            isFromUser: false
        )
        messages.append(welcomeMessage)
    }
    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = AIMessage(content: content, isFromUser: true)
        messages.append(userMessage)
        
        // Clear input
        currentInput = ""
        
        // Simulate AI response
        generateAIResponse(to: content)
    }
    
    private func generateAIResponse(to userMessage: String) {
        isTyping = true
        
        Task {
            // Simulate thinking delay
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            let response = await generateResponse(for: userMessage)
            
            await MainActor.run {
                isTyping = false
                let aiMessage = AIMessage(content: response, isFromUser: false)
                messages.append(aiMessage)
            }
        }
    }
    
    private func generateResponse(for input: String) async -> String {
        let lowerInput = input.lowercased()
        
        // Simple response logic (in a real app, this would call an AI API)
        if lowerInput.contains("swiftui") {
            return "SwiftUI is Apple's modern UI framework! 🎨 It uses declarative syntax which means you describe what your UI should look like, and SwiftUI handles the rest. Would you like me to explain any specific SwiftUI concepts like @State, @Binding, or view modifiers?"
        } else if lowerInput.contains("programming") || lowerInput.contains("code") {
            return "Programming is like giving instructions to a computer! 💻 The key to learning programming is practice and breaking down complex problems into smaller, manageable pieces. What programming language or concept would you like to explore?"
        } else if lowerInput.contains("learn") || lowerInput.contains("study") {
            return "Great question about learning! 📚 The most effective learning happens when you:\n\n• Break topics into smaller chunks\n• Practice regularly\n• Ask questions (like you're doing now!)\n• Apply what you learn to real projects\n\nWhat would you like to learn more about?"
        } else if lowerInput.contains("design") {
            return "Design is all about creating intuitive and beautiful experiences! 🎨 Good design follows principles like:\n\n• Simplicity and clarity\n• Consistency\n• User-centered thinking\n• Visual hierarchy\n\nAre you interested in UI design, UX design, or something else?"
        } else if lowerInput.contains("hello") || lowerInput.contains("hi") {
            return "Hello! 👋 I'm excited to help you learn today! What topic or question is on your mind? I love helping with programming, design, technology, or any learning challenge you might have!"
        } else {
            return "That's a great question! 🤔 I'm here to help you explore and understand any topic. Could you tell me a bit more about what you'd like to learn? The more specific you are, the better I can tailor my explanations to help you succeed!"
        }
    }
    
    func clearConversation() {
        messages.removeAll()
        addWelcomeMessage()
    }
}

// MARK: - AI Service
class AIService: ObservableObject {
    static let shared = AIService()
    
    @Published var isAvailable = true
    @Published var currentModel = "Lyo-v1"
    
    private init() {}
    
    func generateResponse(for prompt: String, context: [AIMessage] = []) async throws -> String {
        // Simulate API call to AI service
        try await Task.sleep(nanoseconds: 2_000_000_000)
        
        // In a real implementation, this would call OpenAI, Anthropic, or another AI API
        return "This is a simulated AI response to: \(prompt)"
    }
    
    func analyzeCode(_ code: String) async throws -> String {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        return "Code analysis: This code follows good practices and is well-structured."
    }
    
    func generateQuiz(for topic: String) async throws -> [QuizQuestion] {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return [
            QuizQuestion(
                question: "What is the main benefit of using SwiftUI?",
                type: .multipleChoice,
                options: [
                    QuizOption(text: "Declarative syntax", isCorrect: false),
                    QuizOption(text: "Better performance", isCorrect: false),
                    QuizOption(text: "Cross-platform", isCorrect: false),
                    QuizOption(text: "All of the above", isCorrect: true)
                ],
                correctAnswer: "All of the above",
                explanation: "SwiftUI offers declarative syntax, good performance, and works across Apple platforms."
            )
        ]
    }
}

// QuizQuestion is defined in LessonModels.swift
