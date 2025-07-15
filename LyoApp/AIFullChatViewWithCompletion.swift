



import SwiftUI
import Foundation



/// A wrapper for AIFullChatView that asks the user what they want to learn, then calls onComplete with the topic.
struct AIFullChatViewWithCompletion: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AIConversationViewModel()
    var onComplete: (String) -> Void
    @State private var detectedTopic: String? = nil
    @StateObject private var voiceRecognizer = VoiceRecognizer()
    @State private var isListening = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                messagesSection
                inputSection
            }
            .background(DesignTokens.Colors.background.ignoresSafeArea())
            .navigationTitle("Lyo AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .accessibilityIdentifier("closeButton")
                }
            }
        }
        .onChange(of: viewModel.messages) { _, messages in
            if let last = messages.last, last.isFromUser {
                if let topic = extractLearningTopic(from: last.content) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        onComplete(topic)
                        dismiss()
                    }
                }
            }
        }
    }

    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                    if viewModel.isTyping {
                        TypingIndicator()
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField("What do you want to learn today?", text: $viewModel.currentInput, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(DesignTokens.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.glassBg)
                            .shadow(color: DesignTokens.Colors.neonBlue.opacity(0.10), radius: DesignTokens.Shadows.sm, x: 0, y: 2)
                    )
                    .lineLimit(1...4)
                    .onSubmit {
                        sendUserMessage()
                    }
                    .accessibilityIdentifier("inputTextField")

                Button {
                    sendUserMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.currentInput.isEmpty ? DesignTokens.Colors.gray400 : DesignTokens.Colors.primary)
                }
                .disabled(viewModel.currentInput.isEmpty || viewModel.isTyping)
                .accessibilityIdentifier("sendButton")

                Button {
                    if !voiceRecognizer.isListening {
                        voiceRecognizer.startListening()
                        isListening = true
                    } else {
                        voiceRecognizer.stopListening()
                        isListening = false
                    }
                } label: {
                    Image(systemName: (isListening || voiceRecognizer.isListening) ? "mic.fill" : "mic")
                        .font(.title2)
                        .foregroundColor((isListening || voiceRecognizer.isListening) ? DesignTokens.Colors.neonBlue : DesignTokens.Colors.gray400)
                }
                .accessibilityLabel("Voice input")
                .accessibilityIdentifier("voiceButton")
            }
            .onChange(of: voiceRecognizer.hotwordDetected) { _, detected in
                if detected {
                    voiceRecognizer.hotwordDetected = false
                }
            }
            .onChange(of: voiceRecognizer.transcript) { _, transcript in
                if isListening || voiceRecognizer.isListening {
                    viewModel.currentInput = transcript
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.xl))
        .shadow(color: DesignTokens.Colors.neonBlue.opacity(0.08), radius: DesignTokens.Shadows.sm, x: 0, y: -2)
    }

    private func sendUserMessage() {
        let text = viewModel.currentInput.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        viewModel.sendMessage(text)
    }

    private func extractLearningTopic(from text: String) -> String? {
        // Very basic: look for "learn <topic>" or "about <topic>"
        let lower = text.lowercased()
        if let range = lower.range(of: "learn ") {
            let topic = text[range.upperBound...].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !topic.isEmpty { return topic }
        }
        if let range = lower.range(of: "about ") {
            let topic = text[range.upperBound...].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if !topic.isEmpty { return topic }
        }
        // Fallback: if user says "I want to learn X" or "teach me X"
        if lower.contains("teach me") {
            if let range = lower.range(of: "teach me") {
                let topic = text[range.upperBound...].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                if !topic.isEmpty { return topic }
            }
        }
        // If user says "SwiftUI" or "React" etc, just return the word if it's not a greeting
        let greetings = ["hello", "hi", "hey", "lio", "lyo"]
        if !greetings.contains(lower) && text.count > 2 {
            return text
        }
        return nil
    }
}
