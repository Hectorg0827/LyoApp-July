import SwiftUI

/// Live Chat Overlay for real-time Q&A with AI during lessons
struct LiveChatOverlay: View {
    @ObservedObject var orchestrator: LiveLearningOrchestrator
    let onClose: () -> Void
    
    @State private var questionText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            
            // Connection Status
            if orchestrator.connectionStatus != .connected {
                connectionStatusBanner
            }
            
            // Messages Area (scrollable)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        // AI Response
                        if !orchestrator.aiResponse.isEmpty {
                            messageBubble(
                                content: orchestrator.aiResponse,
                                isFromUser: false
                            )
                        }
                        
                        // Thinking Indicator
                        if orchestrator.isAIThinking {
                            thinkingIndicator
                        }
                        
                        // Suggested Actions
                        if !orchestrator.suggestedActions.isEmpty {
                            suggestedActionsView
                        }
                    }
                    .padding()
                    .id("bottom")
                }
                .onChange(of: orchestrator.aiResponse) { _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: 300)
            
            Divider()
            
            // Input Area
            inputArea
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(DesignTokens.Colors.surfacePrimary)
                .shadow(color: .black.opacity(0.3), radius: 20, y: -5)
        )
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Live AI Help")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                HStack(spacing: 6) {
                    Circle()
                        .fill(orchestrator.connectionStatus == .connected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    
                    Text(orchestrator.connectionStatus.statusText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.textTertiary)
            }
        }
        .padding()
        .background(DesignTokens.Colors.surfaceSecondary)
    }
    
    private var connectionStatusBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14))
            
            Text("Connecting to live session...")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(.orange)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.orange.opacity(0.1))
    }
    
    private func messageBubble(content: String, isFromUser: Bool) -> some View {
        HStack {
            if isFromUser { Spacer() }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                Text(content)
                    .font(.system(size: 15))
                    .foregroundColor(isFromUser ? .white : DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(isFromUser ? Color.blue : DesignTokens.Colors.surfaceSecondary)
                    )
            }
            
            if !isFromUser { Spacer() }
        }
    }
    
    private var thinkingIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(DesignTokens.Colors.textSecondary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(thinking ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: thinking
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(DesignTokens.Colors.surfaceSecondary)
        )
        .onAppear {
            thinking = true
        }
    }
    
    @State private var thinking = false
    
    private var suggestedActionsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested Actions")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            ForEach(orchestrator.suggestedActions, id: \.self) { action in
                Button(action: {
                    questionText = action
                    askQuestion()
                }) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                        
                        Text(action)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.yellow.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
    
    private var inputArea: some View {
        HStack(spacing: 12) {
            // Text Input
            TextField("Ask a question...", text: $questionText)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(DesignTokens.Colors.surfaceSecondary)
                )
                .focused($isInputFocused)
                .onSubmit {
                    askQuestion()
                }
            
            // Send Button
            Button(action: askQuestion) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(questionText.isEmpty ? DesignTokens.Colors.textTertiary : .blue)
            }
            .disabled(questionText.isEmpty || orchestrator.connectionStatus != .connected)
        }
        .padding()
    }
    
    private func askQuestion() {
        guard !questionText.isEmpty, orchestrator.connectionStatus == .connected else { return }
        
        orchestrator.askQuestion(questionText)
        questionText = ""
        isInputFocused = false
        
        HapticManager.shared.light()
    }
}

// MARK: - Preview

#Preview("Live Chat Overlay - Connected") {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        LiveChatOverlay(
            orchestrator: {
                let orch = LiveLearningOrchestrator.shared
                orch.connectionStatus = .connected
                orch.aiResponse = "Great question! Let me explain how SwiftUI state management works..."
                orch.suggestedActions = ["Review state binding", "See code example", "Practice with exercise"]
                return orch
            }(),
            onClose: {}
        )
    }
}

#Preview("Live Chat Overlay - Thinking") {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        LiveChatOverlay(
            orchestrator: {
                let orch = LiveLearningOrchestrator.shared
                orch.connectionStatus = .connected
                orch.isAIThinking = true
                return orch
            }(),
            onClose: {}
        )
    }
}

#Preview("Live Chat Overlay - Disconnected") {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        LiveChatOverlay(
            orchestrator: {
                let orch = LiveLearningOrchestrator.shared
                orch.connectionStatus = .disconnected
                return orch
            }(),
            onClose: {}
        )
    }
}
