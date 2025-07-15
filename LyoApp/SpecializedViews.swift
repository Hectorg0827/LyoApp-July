import SwiftUI
// MARK: - StoryCircle Component
struct StoryCircle: View {
    let story: Story
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [DesignTokens.Colors.neonPink, DesignTokens.Colors.neonBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 70, height: 70)
                    AsyncImage(url: URL(string: story.author.profileImageURL ?? "https://picsum.photos/60/60")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(DesignTokens.Colors.glassBg)
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                }
                Text(story.author.username)
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 80)
    }
}

// MARK: - Chat View
struct ChatView: View {
    let conversation: ChatConversation
    @Environment(\.dismiss) var dismiss
    @State private var messages: [ChatMessage] = []
    @State private var newMessage = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages
                messagesSection
                
                // Input
                inputSection
            }
            .navigationTitle(conversationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Handle call or video call
                    } label: {
                        Image(systemName: "phone.fill")
                    }
                }
            }
        }
        .onAppear {
            loadMessages()
        }
    }
    
    private var conversationTitle: String {
        if conversation.participants.count == 2 {
            return conversation.participants.first(where: { $0.id != UUID() })?.fullName ?? "Chat"
        } else {
            return "Group Chat"
        }
    }
    
    private var messagesSection: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(messages) { message in
                        ChatMessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(DesignTokens.Spacing.md)
            }
            .onAppear {
                if let lastMessage = messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: messages.count) { _, _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var inputSection: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            Button {
                // Handle attachment
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
            
            TextField("Type a message...", text: $newMessage)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .fill(DesignTokens.Colors.gray100)
                )
                .onSubmit {
                    sendMessage()
                }
            
            Button {
                sendMessage()
            } label: {
                Image(systemName: newMessage.isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(DesignTokens.Colors.primary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.background)
    }
    
    private func loadMessages() {
        // Simulate loading messages
        messages = [
            ChatMessage(
                id: UUID(),
                senderId: UUID(),
                content: "Hey! How's your learning going?",
                timestamp: Date().addingTimeInterval(-3600),
                messageType: .text,
                isRead: true
            ),
            ChatMessage(
                id: UUID(),
                senderId: UUID(),
                content: "I just finished the SwiftUI course. It was amazing!",
                timestamp: Date().addingTimeInterval(-3500),
                messageType: .text,
                isRead: true
            ),
            ChatMessage(
                id: UUID(),
                senderId: UUID(),
                content: "That's great! Want to work on a project together?",
                timestamp: Date().addingTimeInterval(-3400),
                messageType: .text,
                isRead: true
            )
        ]
    }
    
    private func sendMessage() {
        guard !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let message = ChatMessage(
            id: UUID(),
            senderId: UUID(), // Current user ID
            content: newMessage,
            timestamp: Date(),
            messageType: .text,
            isRead: false
        )
        
        messages.append(message)
        newMessage = ""
    }
}

// MARK: - Chat Message Bubble
struct ChatMessageBubble: View {
    let message: ChatMessage
    private let isFromCurrentUser = Bool.random() // Simulate current user
    
    var body: some View {
        HStack {
            if isFromCurrentUser {
                Spacer(minLength: 50)
                
                VStack(alignment: .trailing, spacing: DesignTokens.Spacing.xs) {
                    Text(message.content)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(.white)
                        .padding(DesignTokens.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(DesignTokens.Colors.primary)
                        )
                    
                    Text(message.timestamp, style: .time)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                }
            } else {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(message.content)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.label)
                        .padding(DesignTokens.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(DesignTokens.Colors.secondaryBackground)
                        )
                    
                    Text(message.timestamp, style: .time)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.tertiaryLabel)
                }
                
                Spacer(minLength: 50)
            }
        }
    }
}


// MARK: - Story Viewer (Full Screen)
struct StoryViewer: View {
    let story: Story
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [DesignTokens.Colors.primaryBg, DesignTokens.Colors.secondaryBg],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: DesignTokens.Spacing.lg) {
                HStack {
                    Spacer()
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(DesignTokens.Colors.neonPink)
                            .shadow(color: DesignTokens.Colors.neonPink.opacity(0.4), radius: 8)
                    }
                    .padding()
                }
                Spacer()
                StoryViewerView(story: story)
                Spacer()
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

// MARK: - Story Viewer View (Display Only)
struct StoryViewerView: View {
    let story: Story

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                    .fill(DesignTokens.Colors.glassBg)
                    .shadow(color: DesignTokens.Colors.neonBlue.opacity(0.18), radius: 16, x: 0, y: 8)
                    .frame(height: 400)

                if story.mediaType == .image {
                    AsyncImage(url: URL(string: story.mediaURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 380)
                            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
                    } placeholder: {
                        ProgressView()
                    }
                } else if story.mediaType == .video {
                    // Placeholder for video (implement AVKit if needed)
                    VStack {
                        Image(systemName: "play.rectangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 60)
                            .foregroundColor(DesignTokens.Colors.neonBlue)
                        Text("Video playback not implemented")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }

            HStack(spacing: DesignTokens.Spacing.sm) {
                AsyncImage(url: URL(string: story.author.profileImageURL ?? "https://picsum.photos/40/40")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle().fill(DesignTokens.Colors.glassBg)
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(story.author.username)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    Text(story.createdAt, style: .relative)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
        .padding(.vertical, DesignTokens.Spacing.lg)
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
}


