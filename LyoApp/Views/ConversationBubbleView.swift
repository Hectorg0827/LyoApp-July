import SwiftUI

/// Chat interface for the diagnostic dialogue
/// Uses REAL ConversationMessage and SuggestedResponse data - no mocks
struct ConversationBubbleView: View {
    @Binding var messages: [ConversationMessage]
    @Binding var suggestedResponses: [SuggestedResponse]
    let onResponseTap: (String) -> Void
    let onSendMessage: (String) -> Void
    
    @State private var messageText: String = ""
    @State private var isShowingTyping: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages scroll view
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        // Typing indicator
                        if isShowingTyping {
                            TypingIndicatorView()
                                .padding(.leading, 12)
                                .id("typing")
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _, _ in
                    // Auto-scroll to latest message
                    if let lastMessage = messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isShowingTyping) { _, showing in
                    if showing {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("typing", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Suggested responses (if any)
            if !suggestedResponses.isEmpty {
                SuggestedResponsesView(
                    responses: suggestedResponses,
                    onTap: { response in
                        onResponseTap(response.text)
                        // Clear suggestions after selection
                        suggestedResponses = []
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Input bar
            InputBar(
                messageText: $messageText,
                isInputFocused: $isInputFocused,
                onSend: {
                    guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    onSendMessage(messageText)
                    messageText = ""
                }
            )
        }
    }
    
    /// Show typing indicator for AI thinking
    func showTyping() {
        withAnimation(.easeIn(duration: 0.2)) {
            isShowingTyping = true
        }
    }
    
    /// Hide typing indicator
    func hideTyping() {
        withAnimation(.easeOut(duration: 0.2)) {
            isShowingTyping = false
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ConversationMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.isFromUser ? Color.blue : Color(.systemGray5))
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            
            if !message.isFromUser {
                Spacer(minLength: 60)
            }
        }
        .transition(.scale(scale: 0.8, anchor: message.isFromUser ? .bottomTrailing : .bottomLeading).combined(with: .opacity))
    }
}

// MARK: - Typing Indicator

struct TypingIndicatorView: View {
    @State private var animationPhase: Int = 0
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 8, height: 8)
                    .offset(y: animationPhase == index ? -6 : 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.systemGray5))
        )
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: false)) {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
    }
}

// MARK: - Suggested Responses

struct SuggestedResponsesView: View {
    let responses: [SuggestedResponse]
    let onTap: (SuggestedResponse) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(responses) { response in
                    SuggestedResponseChip(response: response) {
                        onTap(response)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
}

struct SuggestedResponseChip: View {
    let response: SuggestedResponse
    let onTap: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onTap()
                isPressed = false
            }
        }) {
            HStack(spacing: 6) {
                if !response.icon.isEmpty {
                    Text(response.icon)
                        .font(.system(size: 16))
                }
                
                Text(response.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Input Bar

struct InputBar: View {
    @Binding var messageText: String
    var isInputFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Text input
            TextField("Type your answer...", text: $messageText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .regular))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(1...5)
                .focused(isInputFocused)
                .onSubmit {
                    onSend()
                }
            
            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(
                        messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                        Color(.systemGray3) : Color.blue
                    )
            }
            .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: -2)
    }
}

// MARK: - Previews

#Preview("Empty Conversation") {
    ConversationBubbleView(
        messages: .constant([]),
        suggestedResponses: .constant([]),
        onResponseTap: { _ in },
        onSendMessage: { _ in }
    )
}

#Preview("With Messages") {
    var messages = [
        ConversationMessage(
            text: "Hi! I'm here to help you design your perfect learning path. Let's start with what you're curious about - what would you love to learn?",
            isFromUser: false,
            timestamp: Date()
        ),
        ConversationMessage(
            text: "I want to learn Swift programming and build iOS apps",
            isFromUser: true,
            timestamp: Date().addingTimeInterval(60)
        ),
        ConversationMessage(
            text: "That's awesome! Swift is a powerful language. What's your main goal with learning Swift?",
            isFromUser: false,
            timestamp: Date().addingTimeInterval(120)
        )
    ]
    
    var suggestedResponses = [
        SuggestedResponse(text: "Build my first app", icon: "📱"),
        SuggestedResponse(text: "Get a job as iOS developer", icon: "💼"),
        SuggestedResponse(text: "Create a startup", icon: "🚀")
    ]
    
    return ConversationBubbleView(
        messages: .constant(messages),
        suggestedResponses: .constant(suggestedResponses),
        onResponseTap: { response in
            print("Tapped: \(response)")
        },
        onSendMessage: { message in
            print("Sent: \(message)")
        }
    )
}

// MARK: - Additional Models (Inline for compilation)

/// Message in the conversation history
struct ConversationMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
}

/// Suggested quick response for user to tap
struct SuggestedResponse: Identifiable {
    let id = UUID()
    let text: String
    let icon: String
}
