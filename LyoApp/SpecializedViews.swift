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

// MARK: - Enhanced Story Viewer
struct EnhancedStoryViewer: View {
    let story: Story
    @Binding var isPresented: Bool
    let stories: [Story]
    @State private var currentIndex: Int = 0
    @State private var progress: Double = 0
    @State private var timer: Timer?
    @State private var isPlaying: Bool = true
    @State private var showReactionOptions: Bool = false
    @State private var selectedReaction: String?
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    
    private let storyDuration: Double = 5.0
    private let reactions = ["❤️", "😍", "😂", "😮", "😢", "🔥"]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            GeometryReader { geometry in
                ZStack {
                    // Story Content
                    if let currentStory = stories[safe: currentIndex] {
                        AsyncImage(url: URL(string: currentStory.mediaURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            DesignTokens.Colors.primaryBg,
                                            DesignTokens.Colors.secondaryBg
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                )
                        }
                        .onTapGesture { location in
                            let tapLocation = location.x
                            let screenWidth = geometry.size.width
                            
                            if tapLocation < screenWidth / 3 {
                                // Previous story
                                previousStory()
                            } else if tapLocation > (screenWidth * 2) / 3 {
                                // Next story
                                nextStory()
                            } else {
                                // Toggle play/pause
                                togglePlayPause()
                            }
                        }
                        .onLongPressGesture(minimumDuration: 0.1) {
                            pauseStory()
                        } onPressingChanged: { pressing in
                            if !pressing {
                                resumeStory()
                            }
                        }
                        
                        // Story Overlays
                        VStack {
                            // Top overlay with progress and controls
                            topOverlay(currentStory: currentStory)
                            
                            Spacer()
                            
                            // Bottom overlay with user info and actions
                            bottomOverlay(currentStory: currentStory)
                        }
                        .padding()
                    }
                    
                    // Reaction Options Overlay
                    if showReactionOptions {
                        reactionOptionsView
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Selected Reaction Animation
                    if let reaction = selectedReaction {
                        Text(reaction)
                            .font(.system(size: 60))
                            .scaleEffect(1.5)
                            .opacity(0.8)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedReaction)
                    }
                }
                .offset(x: dragOffset.width)
                .scaleEffect(isDragging ? 0.95 : 1.0)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation
                            isDragging = true
                            
                            if abs(value.translation.height) > 50 {
                                pauseStory()
                            }
                        }
                        .onEnded { value in
                            isDragging = false
                            
                            if value.translation.height > 150 {
                                // Swipe down to close
                                closeViewer()
                            } else if value.translation.width > 100 {
                                // Swipe right for previous
                                previousStory()
                            } else if value.translation.width < -100 {
                                // Swipe left for next
                                nextStory()
                            } else {
                                resumeStory()
                            }
                            
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        }
                )
            }
        }
        .onAppear {
            setupViewer()
        }
        .onDisappear {
            stopTimer()
        }
        .statusBarHidden()
    }
    
    private func topOverlay(currentStory: Story) -> some View {
        VStack(spacing: 12) {
            // Progress bars
            HStack(spacing: 4) {
                ForEach(0..<stories.count, id: \.self) { index in
                    ProgressBar(
                        progress: index < currentIndex ? 1.0 : 
                                 index == currentIndex ? progress : 0.0
                    )
                }
            }
            .frame(height: 3)
            
            // User info and controls
            HStack {
                AsyncImage(url: URL(string: currentStory.author.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentStory.author.username)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(timeAgo(from: currentStory.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Button(action: togglePlayPause) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Button(action: closeViewer) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private func bottomOverlay(currentStory: Story) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 12) {
                if currentStory.mediaType == .video {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(.white)
                        Text("Tap to view")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                }
                
                // Story content description (if any)
                Text("Learning moment captured 📚")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 16) {
                Button(action: {
                    withAnimation(.spring()) {
                        showReactionOptions.toggle()
                    }
                }) {
                    Image(systemName: "heart")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Button(action: {}) {
                    Image(systemName: "message")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                
                Button(action: {}) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
        }
    }
    
    private var reactionOptionsView: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 20) {
                ForEach(reactions, id: \.self) { reaction in
                    Button(action: {
                        selectReaction(reaction)
                    }) {
                        Text(reaction)
                            .font(.system(size: 32))
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 100)
        }
    }
    
    // MARK: - Story Control Functions
    private func setupViewer() {
        if let index = stories.firstIndex(where: { $0.id == story.id }) {
            currentIndex = index
        }
        startTimer()
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isPlaying {
                progress += 0.1 / storyDuration
                if progress >= 1.0 {
                    nextStory()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func nextStory() {
        if currentIndex < stories.count - 1 {
            currentIndex += 1
            progress = 0
            startTimer()
        } else {
            closeViewer()
        }
    }
    
    private func previousStory() {
        if currentIndex > 0 {
            currentIndex -= 1
            progress = 0
            startTimer()
        }
    }
    
    private func togglePlayPause() {
        isPlaying.toggle()
    }
    
    private func pauseStory() {
        isPlaying = false
    }
    
    private func resumeStory() {
        isPlaying = true
    }
    
    private func closeViewer() {
        withAnimation(.spring()) {
            isPresented = false
        }
    }
    
    private func selectReaction(_ reaction: String) {
        selectedReaction = reaction
        
        withAnimation(.spring()) {
            showReactionOptions = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            selectedReaction = nil
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Progress Bar Component
struct ProgressBar: View {
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * progress)
            }
        }
        .clipShape(Capsule())
    }
}
