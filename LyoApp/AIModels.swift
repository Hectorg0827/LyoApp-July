import SwiftUI
import Foundation

// This file holds ONLY view models & services. Data model structs like `AIMessage` live in Models/.

struct AIPersonality: Codable, Equatable {
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
final class AIConversationViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isTyping = false
    @Published var currentInput = ""
    @Published var personality: AIPersonality = .lyo
    init() { addWelcomeMessage() }
    private func addWelcomeMessage() {
    messages.append(AIMessage(content: "Hello! I'm Lyo – your AI learning companion. What would you like to explore today?", sender: "ai"))
    }
    func sendMessage(_ content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
    messages.append(AIMessage(content: trimmed, sender: "user"))
        currentInput = ""
        generateAIResponse(to: trimmed)
    }
    private func generateAIResponse(to userMessage: String) {
        isTyping = true
        
        Task { [weak self] in
            do {
                // Use real API for AI generation
                let response = try await APIClient.shared.generateAIContent(prompt: userMessage, maxTokens: 300)
                
                await MainActor.run {
                    self?.messages.append(AIMessage(content: response.generatedText, sender: "ai"))
                    self?.isTyping = false
                }
            } catch {
                await MainActor.run {
                    self?.messages.append(AIMessage(content: "I'm having trouble connecting to the AI service right now. Please try again later.", sender: "ai"))
                    self?.isTyping = false
                }
            }
        }
    }
    func clearConversation() { messages.removeAll(); addWelcomeMessage() }
}

final class AIService: ObservableObject {
    static let shared = AIService(); private init() {}
    @Published var isAvailable = true
    @Published var currentModel = "Lyo-v1"
    func generateResponse(for prompt: String, context: [AIMessage] = []) async throws -> String {
        try await Task.sleep(nanoseconds: 500_000_000)
        return "(Simulated) Response to: \(prompt)"
    }
}

extension AIMessage {
    enum MessageType: String, Codable { case text, code, explanation, quiz, resource }
    var messageTypeEnum: MessageType { MessageType(rawValue: messageType ?? "text") ?? .text }
}
