import SwiftUI
import Foundation

struct AIAvatarView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @StateObject private var avatarService = AIAvatarService.shared
    @State private var messageText = ""
    @State private var showingSettings = false
    @State private var isConnecting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Chat Messages
                chatView
                
                // Input Area
                inputView
            }
            .navigationTitle("Lyo Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        avatarService.endSession()
                        appState.dismissAvatar()
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                }
            }
        }
        .onAppear {
            initializeAvatarSession()
        }
        .sheet(isPresented: $showingSettings) {
            AvatarSettingsView()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Avatar Status
            HStack {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: connectionStatusColor, radius: 4)
                
                Text(connectionStatusText)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
                
                if avatarService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(DesignTokens.Colors.textPrimary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            
            // AI Avatar Display
            avatarDisplayView
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg)
        .overlay(
            Rectangle()
                .fill(DesignTokens.Colors.glassBorder)
                .frame(height: 1),
            alignment: .bottom
        )
    }
    
    // MARK: - Avatar Display
    private var avatarDisplayView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Avatar Circle
            ZStack {
                Circle()
                    .fill(DesignTokens.Gradients.primary)
                    .frame(width: 120, height: 120)
                    .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 0)
                
                // Avatar State Animation
                Group {
                    if appState.avatarState == .listening {
                        // Listening animation
                        Circle()
                            .stroke(DesignTokens.Colors.neonBlue, lineWidth: 3)
                            .frame(width: 130, height: 130)
                            .scaleEffect(avatarService.isTyping ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: avatarService.isTyping)
                    } else if appState.avatarState == .speaking || avatarService.isTyping {
                        // Speaking animation
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(DesignTokens.Colors.neonPink.opacity(0.3))
                                .frame(width: 140 + CGFloat(index) * 10, height: 140 + CGFloat(index) * 10)
                                .scaleEffect(avatarService.isTyping ? 1.0 + CGFloat(index) * 0.1 : 1.0)
                                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: avatarService.isTyping)
                        }
                    }
                }
                
                // Avatar Icon
                Image(systemName: "sparkles")
                    .font(DesignTokens.font.largeTitle)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .shadow(color: DesignTokens.Colors.neonBlue.opacity(0.5), radius: 10)
            }
            
            // Avatar Name and Status
            VStack(spacing: 4) {
                Text("Lyo")
                    .font(DesignTokens.font.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(avatarStateText)
                    .font(DesignTokens.font.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Chat View
    private var chatView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(avatarService.messages) { message in
                        ChatBubbleView(message: message)
                            .id(message.id)
                    }
                    
                    // Typing indicator
                    if avatarService.isTyping {
                        TypingIndicatorView()
                            .id("typing")
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.primaryBg)
            .onChange(of: avatarService.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(avatarService.messages.last?.id ?? "typing", anchor: .bottom)
                }
            }
            .onChange(of: avatarService.isTyping) { _, _ in
                withAnimation {
                    proxy.scrollTo("typing", anchor: .bottom)
                }
            }
        }
    }
    
    // MARK: - Input View
    private var inputView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            // Quick Actions
            if avatarService.messages.isEmpty {
                quickActionsView
            }
            
            // Message Input
            HStack(spacing: DesignTokens.Spacing.sm) {
                TextField("Ask Lyo anything...", text: $messageText)
                    .font(DesignTokens.font.body)
                    .padding()
                    .background(DesignTokens.Colors.backgroundSecondary)
                    .cornerRadius(DesignTokens.Radius.lg)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .disabled(avatarService.isLoading || !avatarService.isConnected)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(DesignTokens.font.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(messageText.isEmpty ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.primary)
                        .clipShape(Circle())
                }
                .disabled(messageText.isEmpty || avatarService.isLoading || !avatarService.isConnected)
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.lg)
        }
        .background(DesignTokens.Colors.glassBg)
        .overlay(
            Rectangle()
                .fill(DesignTokens.Colors.glassBorder)
                .frame(height: 1),
            alignment: .top
        )
    }
    
    // MARK: - Quick Actions
    private var quickActionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Dynamic quick actions based on user context and history
                if let context = avatarService.currentContext {
                    // Show context-aware quick actions
                    if context.topicsCovered.contains("Programming") {
                        AIQuickActionButton(title: "Code Review", icon: "doc.text.magnifyingglass") {
                            messageText = "Help me review my Swift code for best practices"
                        }
                    }
                    
                    if context.topicsCovered.contains("Design") {
                        AIQuickActionButton(title: "UI Feedback", icon: "paintbrush.pointed") {
                            messageText = "Give me feedback on my app's user interface design"
                        }
                    }
                    
                    // Always available actions
                    AIQuickActionButton(title: "Continue Learning", icon: "book.fill") {
                        if let currentModule = context.currentModule {
                            messageText = "Continue with \(currentModule)"
                        } else {
                            messageText = "What should I learn next?"
                        }
                    }
                    
                    AIQuickActionButton(title: "Quiz Me", icon: "questionmark.circle.fill") {
                        let topics = context.topicsCovered.joined(separator: ", ")
                        messageText = "Create a quiz about \(topics)"
                    }
                } else {
                    // Default quick actions for new users
                    AIQuickActionButton(title: "Start Learning", icon: "book.fill") {
                        messageText = "I'm new to programming. Where should I start?"
                    }
                    
                    AIQuickActionButton(title: "Explore Topics", icon: "lightbulb.fill") {
                        messageText = "What programming topics can you help me with?"
                    }
                    
                    AIQuickActionButton(title: "Learning Goals", icon: "target") {
                        messageText = "Help me set up my learning goals"
                    }
                    
                    AIQuickActionButton(title: "Study Plan", icon: "calendar.circle.fill") {
                        messageText = "Create a personalized study plan for me"
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
    }
    
    // MARK: - Helper Methods
    
    private func initializeAvatarSession() {
        avatarService.startNewSession()
        appState.updateAvatarState(.idle)
        
        // Check connection and load context if authenticated
        if !avatarService.isConnected {
            isConnecting = true
            Task {
                let healthCheck = await avatarService.checkBackendHealth()
                
                if healthCheck {
                    // If user is already authenticated, load context
                    if avatarService.hasValidAuthToken() {
                        await avatarService.loadAvatarContext()
                    } else {
                        // If no authentication and backend is available, 
                        // try to authenticate with stored credentials or prompt for login
                        if appState.isAuthenticated, let user = appState.currentUser {
                            // Use actual user credentials for authentication
                            let success = await avatarService.authenticateWithUserCredentials(
                                email: user.email,
                                // In a real app, this would come from secure storage
                                password: "user_password" // TODO: Implement secure credential storage
                            )
                            
                            if success {
                                await avatarService.loadAvatarContext()
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    isConnecting = false
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        appState.updateAvatarState(.thinking)
        
        Task {
            _ = await avatarService.sendMessage(message)
            await MainActor.run {
                appState.updateAvatarState(.idle)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionStatusColor: Color {
        if isConnecting {
            return DesignTokens.Colors.warning
        } else if avatarService.isConnected {
            return DesignTokens.Colors.success
        } else {
            return DesignTokens.Colors.error
        }
    }
    
    private var connectionStatusText: String {
        if isConnecting {
            return "Connecting..."
        } else if avatarService.isConnected {
            return "Connected"
        } else {
            return "Disconnected"
        }
    }
    
    private var avatarStateText: String {
        if avatarService.isTyping {
            return "Typing..."
        } else {
            return appState.avatarState.description
        }
    }
}

// MARK: - Chat Bubble View
struct ChatBubbleView: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.text)
                        .font(DesignTokens.font.body)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .padding(DesignTokens.Spacing.md)
                        .background(DesignTokens.Colors.primary)
                        .cornerRadius(DesignTokens.Radius.lg)
                    
                    Text(message.timestamp, style: .time)
                        .font(DesignTokens.font.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.text)
                        .font(DesignTokens.font.body)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .padding(DesignTokens.Spacing.md)
                        .background(DesignTokens.Colors.backgroundSecondary)
                        .cornerRadius(DesignTokens.Radius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                                .stroke(DesignTokens.Colors.backgroundSecondary, lineWidth: 1)
                        )
                    
                    HStack {
                        Text(message.timestamp, style: .time)
                            .font(DesignTokens.font.caption2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        // Show detected topics if available
                        if let topics = message.detectedTopics, !topics.isEmpty {
                            ForEach(topics.prefix(2), id: \.self) { topic in
                                Text(topic)
                                    .font(DesignTokens.font.caption2)
                                    .foregroundColor(DesignTokens.Colors.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(DesignTokens.Colors.primary.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - AI Quick Action Button
struct AIQuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(DesignTokens.font.body)
                
                Text(title)
                    .font(DesignTokens.font.caption)
            }
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(DesignTokens.Colors.primary.opacity(0.1))
            .cornerRadius(DesignTokens.Radius.button)
        }
    }
}

// MARK: - Avatar Settings View
struct AvatarSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var avatarService = AIAvatarService.shared
    @State private var selectedPersona: AvatarPersona = .friendly
    @State private var selectedLearningStyle: LearningStyle = .multimodal
    
    var body: some View {
        NavigationView {
            Form {
                Section("Avatar Persona") {
                    Picker("Persona", selection: $selectedPersona) {
                        ForEach(AvatarPersona.allCases, id: \.self) { persona in
                            VStack(alignment: .leading) {
                                Text(persona.displayName)
                                    .font(DesignTokens.font.body)
                                Text(persona.description)
                                    .font(DesignTokens.font.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                            .tag(persona)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("Learning Style") {
                    Picker("Learning Style", selection: $selectedLearningStyle) {
                        ForEach(LearningStyle.allCases, id: \.self) { style in
                            VStack(alignment: .leading) {
                                Text(style.displayName)
                                    .font(DesignTokens.font.body)
                                Text(style.description)
                                    .font(DesignTokens.font.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                            }
                            .tag(style)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("Connection Info") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(avatarService.isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(avatarService.isConnected ? DesignTokens.Colors.success : DesignTokens.Colors.error)
                    }
                    
                    if let context = avatarService.currentContext {
                        HStack {
                            Text("Topics Covered")
                            Spacer()
                            Text("\(context.topicsCovered.count)")
                        }
                        
                        HStack {
                            Text("Engagement Level")
                            Spacer()
                            Text("\(Int(context.engagementLevel * 100))%")
                        }
                    }
                }
            }
            .navigationTitle("Avatar Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        applySettings()
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func applySettings() {
        let request = AvatarContextRequest(
            topics: nil,
            learningGoals: nil,
            currentModule: nil,
            persona: selectedPersona.rawValue,
            learningStyle: selectedLearningStyle.rawValue,
            learningPace: nil,
            strengths: nil,
            areasForImprovement: nil,
            preferredResources: nil
        )
        
        Task {
            await avatarService.updateAvatarContext(request: request)
        }
    }
}

extension AvatarState: CustomStringConvertible {
    var description: String {
        switch self {
        case .idle: return "Idle"
        case .listening: return "Listening"
        case .thinking: return "Thinking"
        case .speaking: return "Speaking"
        }
    }
}

#Preview {
    AIAvatarView()
        .environmentObject(AppState())
}
