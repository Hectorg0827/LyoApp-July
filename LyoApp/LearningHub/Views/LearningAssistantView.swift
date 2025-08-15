import SwiftUI
import Combine

// MARK: - AI Learning Assistant (Lio) Integration
/// Enhanced AI assistant specifically designed for learning support
/// Note: Use unique name to avoid conflicts.
struct LearningAssistantOverlayView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var assistantViewModel = LearningAssistantViewModel()
    
    @State private var isExpanded = false
    @State private var showingFullChat = false
    @State private var messageText = ""
    @FocusState private var isMessageFieldFocused: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                if isExpanded {
                    expandedAssistantView
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                } else {
                    minimizedAssistantView
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Account for tab bar
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isExpanded)
    }
    
    // MARK: - Minimized Assistant View
    private var minimizedAssistantView: some View {
        Button(action: {
            withAnimation {
                isExpanded = true
            }
            assistantViewModel.trackInteraction(.assistantOpened)
        }) {
            ZStack {
                // Background with quantum effect
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8),
                                Color.blue.opacity(0.6),
                                Color.purple.opacity(0.4)
                            ]),
                            center: .center,
                            startRadius: 10,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
                
                // Pulsing ring effect
                Circle()
                    .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                    .frame(width: 70, height: 70)
                    .scaleEffect(assistantViewModel.isPulsing ? 1.2 : 1.0)
                    .opacity(assistantViewModel.isPulsing ? 0.3 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: assistantViewModel.isPulsing)
                
                // Lio AI Icon
                VStack(spacing: 2) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Lio")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                // Notification badge
                if assistantViewModel.hasUnreadSuggestions {
                    VStack {
                        HStack {
                            Spacer()
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Text("\(assistantViewModel.unreadCount)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                        }
                        Spacer()
                    }
                    .frame(width: 60, height: 60)
                }
            }
        }
        .onAppear {
            assistantViewModel.startPulsing()
        }
        .onDisappear {
            assistantViewModel.stopPulsing()
        }
    }
    
    // MARK: - Expanded Assistant View
    private var expandedAssistantView: some View {
        VStack(spacing: 0) {
            // Header
            assistantHeaderView
            
            // Quick Suggestions or Recent Messages
            if assistantViewModel.messages.isEmpty {
                quickSuggestionsView
            } else {
                recentMessagesView
            }
            
            // Input Field
            messageInputView
        }
        .frame(width: 280, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                .shadow(color: Color.cyan.opacity(0.2), radius: 10, x: 0, y: 0)
        )
    }
    
    // MARK: - Assistant Header
    private var assistantHeaderView: some View {
        HStack {
            // Lio Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.cyan, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: "brain.head.profile")
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Lio AI")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(assistantViewModel.statusText)
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 8) {
                // Full Chat Button
                Button(action: {
                    showingFullChat = true
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.subheadline)
                        .foregroundColor(.cyan)
                }
                
                // Close Button
                Button(action: {
                    withAnimation {
                        isExpanded = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Quick Suggestions View
    private var quickSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How can I help you learn?")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.top, 12)
            
            LazyVStack(spacing: 8) {
                ForEach(assistantViewModel.quickSuggestions, id: \.self) { suggestion in
                    SuggestionButton(suggestion: suggestion) {
                        assistantViewModel.selectSuggestion(suggestion)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
    }
    
    // MARK: - Recent Messages View
    private var recentMessagesView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(assistantViewModel.messages.suffix(5)) { message in
                    AssistantMessageRow(message: message)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Message Input View
    private var messageInputView: some View {
        HStack(spacing: 8) {
            TextField("Ask Lio anything...", text: $messageText)
                .font(.subheadline)
                .foregroundColor(.white)
                .focused($isMessageFieldFocused)
                .onSubmit {
                    sendMessage()
                }
            
            Button(action: sendMessage) {
                Image(systemName: messageText.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.title3)
                    .foregroundColor(messageText.isEmpty ? .gray : .cyan)
            }
            .disabled(messageText.isEmpty && !assistantViewModel.isListening)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.1))
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - Methods
    private func sendMessage() {
        guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            // Start voice input
            assistantViewModel.startVoiceInput()
            return
        }
        
        assistantViewModel.sendMessage(messageText)
        messageText = ""
        isMessageFieldFocused = false
    }
}

// MARK: - Supporting Components

struct SuggestionButton: View {
    let suggestion: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct AssistantMessageRow: View {
    let message: LearningChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(16)
                    .frame(maxWidth: 250, alignment: .trailing)
            } else {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .frame(maxWidth: 250, alignment: .leading)
                Spacer()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        LearningAssistantOverlayView()
            .environmentObject(AppState())
    }
    .preferredColorScheme(.dark)
}
