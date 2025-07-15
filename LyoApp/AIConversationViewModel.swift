import SwiftUI
import Combine

@MainActor
class AIConversationViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isTyping = false
    @Published var currentInput = ""
    @Published var personality = AIPersonality.lyo
    
    private let webSocketService: WebSocketService
    private var cancellables = Set<AnyCancellable>()
    
    init(webSocketService: WebSocketService = WebSocketService()) {
        self.webSocketService = webSocketService
        addWelcomeMessage()
        
        // Replace with a real user ID
        self.webSocketService.connect(userId: "12345")
        
        self.webSocketService.$receivedMessage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self = self, let message = message else { return }
                
                // Decode the message and add it to the messages array
                // This assumes the backend sends a JSON string that can be decoded into an AIMessage
                if let data = message.data(using: .utf8) {
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    do {
                        let aiMessage = try decoder.decode(AIMessage.self, from: data)
                        self.messages.append(aiMessage)
                    } catch {
                        print("Error decoding message: \(error)")
                    }
                }
            }
            .store(in: &cancellables)
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
        
        let userMessage = AIMessage(content: content, isFromUser: true)
        messages.append(userMessage)
        
        currentInput = ""
        
        webSocketService.sendMessage(message: content)
    }
    
    func clearConversation() {
        messages.removeAll()
        addWelcomeMessage()
    }
}
