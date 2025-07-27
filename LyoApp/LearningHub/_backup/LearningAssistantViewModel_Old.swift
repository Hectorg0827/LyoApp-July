import SwiftUI
import Combine

// MARK: - Learning Assistant View Model
/// Manages the state and logic for the AI Learning Assistant.
class LearningAssistantViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var messages: [ChatMessage] = []
    @Published var isTyping: Bool = false
    @Published var quickActions: [QuickAction] = []
    
    // MARK: - Initialization
    init() {
        loadInitialState()
    }
    
    // MARK: - Public Methods
    func sendMessage(_ text: String) {
        let userMessage = ChatMessage(text: text, isUser: true)
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
        let userMessage = ChatMessage(text: action.title, isUser: true)
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
            ChatMessage(text: "Hello! I'm Lio, your AI learning assistant. How can I help you today?")
        ]
        
        quickActions = [
            QuickAction(title: "Recommend a course", prompt: "Recommend a course for me", icon: "books.vertical"),
            QuickAction(title: "Explain SwiftUI", prompt: "Explain what SwiftUI is", icon: "swift"),
            QuickAction(title: "Quiz me", prompt: "Give me a short quiz on iOS development", icon: "questionmark.diamond"),
            QuickAction(title: "Set a goal", prompt: "Help me set a learning goal", icon: "target")
        ]
    }
    
    private func generateAIResponse(for query: String) -> ChatMessage {
        let lowercasedQuery = query.lowercased()
        
        if lowercasedQuery.contains("recommend") || lowercasedQuery.contains("course") {
            return ChatMessage(text: "Of course! I recommend the 'Professional SwiftUI' course. It's great for advancing your skills.")
        } else if lowercasedQuery.contains("swiftui") {
            return ChatMessage(text: "SwiftUI is a modern way to declare user interfaces for any Apple platform. It allows you to build beautiful, dynamic apps faster than ever.")
        } else if lowercasedQuery.contains("quiz") {
            return ChatMessage(text: "Sure! Here's a question: What is the main difference between a 'State' and a 'Binding' in SwiftUI?")
        } else if lowercasedQuery.contains("goal") {
            return ChatMessage(text: "Let's do it! A great goal is to complete one new tutorial video each day for a week. Consistency is key!")
        } else {
            return ChatMessage(text: "That's a great question. Let me find the best information for you on that topic.")
        }
    }
}

// MARK: - Supporting Models
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    
    init(text: String, isUser: Bool = false) {
        self.text = text
        self.isUser = isUser
    }
}

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let prompt: String
    let icon: String
}
