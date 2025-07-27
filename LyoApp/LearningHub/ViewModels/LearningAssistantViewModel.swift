import SwiftUI
import Combine

// MARK: - Learning Assistant View Model
/// Manages the state and logic for the AI Learning Assistant.
@MainActor
class LearningAssistantViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var messages: [LearningChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var quickActions: [QuickAction] = []
    
    // MARK: - Initialization
    init() {
        loadInitialState()
    }
    
    // MARK: - Public Methods
    func sendMessage(_ text: String) {
        let userMessage = LearningChatMessage(content: text, isUser: true)
        messages.append(userMessage)
        
        isTyping = true
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isTyping = false
            let aiResponse = self.generateAIResponse(for: text)
            self.messages.append(aiResponse)
        }
    }
    
    func performQuickAction(_ action: QuickAction) {
        let userMessage = LearningChatMessage(content: action.title, isUser: true)
        messages.append(userMessage)
        
        isTyping = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isTyping = false
            let aiResponse = self.generateAIResponse(for: action.prompt)
            self.messages.append(aiResponse)
        }
    }
    
    // MARK: - Private Methods
    private func loadInitialState() {
        messages = [
            LearningChatMessage(content: "Hello! I'm Lio, your AI learning assistant. How can I help you today?")
        ]
        
        quickActions = [
            QuickAction(title: "Recommend a course", prompt: "Recommend a course for me", icon: "books.vertical"),
            QuickAction(title: "Explain SwiftUI", prompt: "Explain what SwiftUI is", icon: "swift"),
            QuickAction(title: "Quiz me", prompt: "Give me a short quiz on iOS development", icon: "questionmark.diamond"),
            QuickAction(title: "Set a goal", prompt: "Help me set a learning goal", icon: "target")
        ]
    }
    
    private func generateAIResponse(for query: String) -> LearningChatMessage {
        let lowercasedQuery = query.lowercased()
        
        if lowercasedQuery.contains("recommend") || lowercasedQuery.contains("course") {
            return LearningChatMessage(content: "Of course! I recommend the 'Professional SwiftUI' course. It's great for advancing your skills.")
        } else if lowercasedQuery.contains("swiftui") {
            return LearningChatMessage(content: "SwiftUI is a modern way to declare user interfaces for any Apple platform. It allows you to build beautiful, dynamic apps faster than ever.")
        } else if lowercasedQuery.contains("quiz") {
            return LearningChatMessage(content: "Sure! Here's a question: What is the main difference between a 'State' and a 'Binding' in SwiftUI?")
        } else if lowercasedQuery.contains("goal") {
            return LearningChatMessage(content: "Let's do it! A great goal is to complete one new tutorial video each day for a week. Consistency is key!")
        } else {
            return LearningChatMessage(content: "That's a great question. Let me find the best information for you on that topic.")
        }
    }
}

// MARK: - Supporting Models
struct LearningChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(content: String, isUser: Bool = false, timestamp: Date = Date()) {
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let prompt: String
    let icon: String
}
