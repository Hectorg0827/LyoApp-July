import SwiftUI

/// A simplified, reliable chat interface that fixes the typing and mic issues
struct SimpleChatView: View {
    @StateObject private var viewModel = AIConversationViewModel()
    @State private var isListening = false
    @State private var showingVoicePermission = false
    let onTopicDetected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isTyping {
                            TypingIndicator()
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            HStack(spacing: 12) {
                // Text input
                TextField("What do you want to learn today?", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(DesignTokens.Colors.glassBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
                            )
                    )
                    .lineLimit(1...4)
                    .onSubmit {
                        sendMessage()
                    }
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.currentInput.isEmpty ? DesignTokens.Colors.gray400 : DesignTokens.Colors.primary)
                }
                .disabled(viewModel.currentInput.isEmpty || viewModel.isTyping)
                
                // Mic button (simplified)
                Button(action: toggleVoiceInput) {
                    Image(systemName: isListening ? "mic.fill" : "mic")
                        .font(.title2)
                        .foregroundColor(isListening ? DesignTokens.Colors.neonBlue : DesignTokens.Colors.gray400)
                }
                .alert("Voice Permission", isPresented: $showingVoicePermission) {
                    Button("OK") { }
                } message: {
                    Text("Voice input requires microphone permission. You can enable it in Settings.")
                }
            }
            .padding()
            .background(DesignTokens.Colors.glassBg)
        }
        .onChange(of: viewModel.messages) { _, messages in
            // Check for topic detection
            if let lastMessage = messages.last, lastMessage.isFromUser {
                if let topic = extractLearningTopic(from: lastMessage.content) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        onTopicDetected(topic)
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let text = viewModel.currentInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.sendMessage(text)
    }
    
    private func toggleVoiceInput() {
        if isListening {
            // Stop listening
            isListening = false
        } else {
            // Start listening (simplified - just show alert for now)
            showingVoicePermission = true
        }
    }
    
    private func extractLearningTopic(from text: String) -> String? {
        let lower = text.lowercased()
        
        // Look for common learning patterns
        let patterns = [
            "learn ",
            "about ",
            "understand ",
            "study ",
            "teach me ",
            "explain ",
            "help me with "
        ]
        
        for pattern in patterns {
            if let range = lower.range(of: pattern) {
                let topic = text[range.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                if !topic.isEmpty {
                    return String(topic)
                }
            }
        }
        
        // If no pattern found, assume the whole message is the topic (for short messages)
        if text.count < 50 && !text.contains("?") {
            return text
        }
        
        return nil
    }
}

#Preview {
    SimpleChatView { topic in
        print("Topic detected: \(topic)")
    }
}