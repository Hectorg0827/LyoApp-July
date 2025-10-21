import SwiftUI
import AVFoundation

// MARK: - Data Models

/// Main conversation model for inbox list
struct MessengerConversation: Identifiable, Codable, Hashable {
    let id: String
    let participants: [User]
    var lastMessage: MessengerMessage?
    var unreadCount: Int
    var isGroup: Bool
    var groupName: String?
    var groupAvatar: String?
    var updatedAt: Date
    var isOnline: Bool
    var isTyping: Bool
    
    var displayName: String {
        if isGroup {
            return groupName ?? "Group Chat"
        } else {
            return participants.first?.fullName ?? "Unknown"
        }
    }
    
    var displayAvatar: String {
        if isGroup {
            return groupAvatar ?? ""
        } else {
            return participants.first?.profileImageURL?.absoluteString ?? ""
        }
    }
}

/// Individual message model with rich features
struct MessengerMessage: Identifiable, Codable, Hashable {
    let id: String
    let conversationId: String
    let senderId: String
    var content: String
    var messageType: MessageType
    var timestamp: Date
    var isRead: Bool
    var reactions: [MessageReaction]
    var replyTo: String? // ID of message being replied to
    var mediaUrl: String?
    var voiceDuration: TimeInterval?
    var isEdited: Bool
    var deletedAt: Date?
    
    var isDeleted: Bool {
        deletedAt != nil
    }
}

enum MessageType: String, Codable, Hashable {
    case text
    case image
    case video
    case voice
    case gif
    case sticker
}

/// Message reactions (like Instagram)
struct MessageReaction: Identifiable, Codable, Hashable {
    let id: String
    let userId: String
    let emoji: String
    let timestamp: Date
}

// MARK: - Messenger Manager

@MainActor
class MessengerManager: ObservableObject {
    @Published var conversations: [MessengerConversation] = []
    @Published var activeConversation: MessengerConversation?
    @Published var messages: [MessengerMessage] = []
    @Published var isTyping: Bool = false
    @Published var searchQuery: String = ""
    @Published var audioRecorder: AVAudioRecorder?
    @Published var audioPlayer: AVAudioPlayer?
    @Published var isRecording: Bool = false
    @Published var recordingTime: TimeInterval = 0
    
    // TODO: Real backend service - MessengerService not yet in Xcode target
    // private let messengerService = MessengerService.shared
    
    init() {
        print("📱 MessengerManager initialized - will use real backend once MessengerService is added to target")
        generateMockConversations()
        loadConversations()
        // TODO: Uncomment once MessengerService is in target
        // Task {
        //     await loadConversations()
        //     await startMessageListener()
        // }
    }
    
    // MARK: - Conversation Management
    
    func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: "savedMessengerConversations"),
           let decoded = try? JSONDecoder().decode([MessengerConversation].self, from: data) {
            self.conversations = decoded
        }
        // TODO: Uncomment once MessengerService is added to Xcode target
        // Task {
        //     do {
        //         let backendConversations = try await messengerService.loadConversations()
        //         print("📱 Messenger: Loaded \(backendConversations.count) conversations from backend")
        //     } catch {
        //         print("❌ Messenger: Failed to load conversations - \(error)")
        //     }
        // }
    }
    
    private func startMessageListener() async {
        // TODO: Uncomment once MessengerService is added to Xcode target
        // guard let conversationId = activeConversation?.id else { return }
        // for await message in messengerService.streamMessages(conversationId: conversationId) {
        //     await MainActor.run {
        //         print("📱 Messenger: Received real-time message: \(message.id)")
        //     }
        // }
    }
    
    func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: "savedMessengerConversations")
        }
    }
    
    func openConversation(_ conversation: MessengerConversation) {
        activeConversation = conversation
        loadMessages(for: conversation.id)
        markAsRead(conversation.id)
    }
    
    func loadMessages(for conversationId: String) {
        // Load from persistence
        if let data = UserDefaults.standard.data(forKey: "messengerMessages_\(conversationId)"),
           let decoded = try? JSONDecoder().decode([MessengerMessage].self, from: data) {
            self.messages = decoded.sorted { $0.timestamp < $1.timestamp }
        } else {
            // Generate mock messages for demo
            generateMockMessages(for: conversationId)
        }
    }
    
    func saveMessages(for conversationId: String) {
        if let encoded = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(encoded, forKey: "messengerMessages_\(conversationId)")
        }
    }
    
    // MARK: - Message Actions
    
    func sendMessage(_ content: String, type: MessageType = .text, mediaUrl: String? = nil) {
        guard let conversation = activeConversation else { return }
        
        // Optimistic update - add message to UI immediately
        let tempMessage = MessengerMessage(
            id: UUID().uuidString,
            conversationId: conversation.id,
            senderId: "current_user",
            content: content,
            messageType: type,
            timestamp: Date(),
            isRead: false,
            reactions: [],
            replyTo: nil,
            mediaUrl: mediaUrl,
            voiceDuration: nil,
            isEdited: false,
            deletedAt: nil
        )
        
        messages.append(tempMessage)
        updateConversationLastMessage(tempMessage)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Send to real backend
        // TODO: Uncomment once MessengerService is added to Xcode target
        // Task {
        //     do {
        //         let recipientId = conversation.participants.first?.id.uuidString ?? ""
        //         let sentMessage = try await messengerService.sendMessage(
        //             conversationId: conversation.id,
        //             content: content,
        //             recipientId: recipientId
        //         )
        //         print("✅ Message sent to backend: \(sentMessage.id)")
        //     } catch {
        //         print("❌ Failed to send message to backend: \(error)")
        //     }
        // }
    }
    
    func simulateResponse(to userMessage: String) {
        guard let conversation = activeConversation else { return }
        
        let responses = [
            "That's a great point! 😊",
            "I totally agree with you!",
            "Thanks for sharing that! 🙌",
            "Interesting perspective!",
            "Let me think about that...",
            "Absolutely! I was thinking the same thing.",
            "That sounds amazing! Tell me more.",
            "I appreciate you reaching out! 💙"
        ]
        
        let response = MessengerMessage(
            id: UUID().uuidString,
            conversationId: conversation.id,
            senderId: conversation.participants.first?.id.uuidString ?? "",
            content: responses.randomElement() ?? "Thanks!",
            messageType: .text,
            timestamp: Date(),
            isRead: false,
            reactions: [],
            replyTo: nil,
            mediaUrl: nil,
            voiceDuration: nil,
            isEdited: false,
            deletedAt: nil
        )
        
        messages.append(response)
        updateConversationLastMessage(response)
        saveMessages(for: conversation.id)
    }
    
    func deleteMessage(_ messageId: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            messages[index].deletedAt = Date()
            saveMessages(for: activeConversation?.id ?? "")
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    func addReaction(to messageId: String, emoji: String) {
        if let index = messages.firstIndex(where: { $0.id == messageId }) {
            let reaction = MessageReaction(
                id: UUID().uuidString,
                userId: "current_user",
                emoji: emoji,
                timestamp: Date()
            )
            
            // Remove previous reaction from same user if exists
            messages[index].reactions.removeAll { $0.userId == "current_user" }
            messages[index].reactions.append(reaction)
            
            saveMessages(for: activeConversation?.id ?? "")
            
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }
    
    func markAsRead(_ conversationId: String) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            conversations[index].unreadCount = 0
            saveConversations()
        }
        
        // Mark all messages as read
        for i in messages.indices {
            messages[i].isRead = true
        }
        saveMessages(for: conversationId)
    }
    
    func updateConversationLastMessage(_ message: MessengerMessage) {
        if let index = conversations.firstIndex(where: { $0.id == message.conversationId }) {
            conversations[index].lastMessage = message
            conversations[index].updatedAt = Date()
            
            // Move to top of list
            let conversation = conversations.remove(at: index)
            conversations.insert(conversation, at: 0)
            
            saveConversations()
        }
    }
    
    // MARK: - Voice Recording
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .default)
            try audioSession.setActive(true)
            
            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            isRecording = true
            
            // Start timer on main actor to update UI-bound state
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
                guard let self else { timer.invalidate(); return }
                if self.isRecording {
                    self.recordingTime = self.audioRecorder?.currentTime ?? 0
                } else {
                    timer.invalidate()
                }
            }
            
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        
        if let url = audioRecorder?.url {
            sendMessage("Voice message (\(Int(recordingTime))s)", type: .voice, mediaUrl: url.absoluteString)
        }
        
        recordingTime = 0
    }
    
    // MARK: - Search
    
    var filteredConversations: [MessengerConversation] {
        if searchQuery.isEmpty {
            return conversations
        } else {
            return conversations.filter { conversation in
                conversation.displayName.localizedCaseInsensitiveContains(searchQuery) ||
                (conversation.lastMessage?.content.localizedCaseInsensitiveContains(searchQuery) ?? false)
            }
        }
    }
    
    // MARK: - Mock Data Generation
    
    func generateMockConversations() {
        let mockUsers = [
            User(id: UUID(), username: "sarahj", email: "sarah@example.com", fullName: "Sarah Johnson", bio: "Designer", profileImageURL: URL(string: "https://i.pravatar.cc/150?img=1")),
            User(id: UUID(), username: "mikechen", email: "mike@example.com", fullName: "Mike Chen", bio: "Developer", profileImageURL: URL(string: "https://i.pravatar.cc/150?img=2")),
            User(id: UUID(), username: "emmaw", email: "emma@example.com", fullName: "Emma Wilson", bio: "Marketer", profileImageURL: URL(string: "https://i.pravatar.cc/150?img=3")),
            User(id: UUID(), username: "alexr", email: "alex@example.com", fullName: "Alex Rodriguez", bio: "Product Manager", profileImageURL: URL(string: "https://i.pravatar.cc/150?img=4")),
            User(id: UUID(), username: "oliviat", email: "olivia@example.com", fullName: "Olivia Taylor", bio: "Data Scientist", profileImageURL: URL(string: "https://i.pravatar.cc/150?img=5"))
        ]
        
        let lastMessages = [
            "Hey! How's your day going? 😊",
            "Did you see the new course on SwiftUI?",
            "Thanks for the help earlier!",
            "Let's catch up soon! ☕️",
            "That video you shared was amazing! 🎥"
        ]
        
        conversations = mockUsers.enumerated().map { index, user in
            let message = MessengerMessage(
                id: UUID().uuidString,
                conversationId: UUID().uuidString,
                senderId: user.id.uuidString,
                content: lastMessages[index % lastMessages.count],
                messageType: .text,
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                isRead: index > 1,
                reactions: [],
                replyTo: nil,
                mediaUrl: nil,
                voiceDuration: nil,
                isEdited: false,
                deletedAt: nil
            )
            
            return MessengerConversation(
                id: UUID().uuidString,
                participants: [user],
                lastMessage: message,
                unreadCount: index < 2 ? index + 1 : 0,
                isGroup: false,
                groupName: nil,
                groupAvatar: nil,
                updatedAt: message.timestamp,
                isOnline: index % 2 == 0,
                isTyping: false
            )
        }
        
        // Add a group chat
        let groupConversation = MessengerConversation(
            id: UUID().uuidString,
            participants: Array(mockUsers.prefix(3)),
            lastMessage: MessengerMessage(
                id: UUID().uuidString,
                conversationId: UUID().uuidString,
                senderId: mockUsers[0].id.uuidString,
                content: "Who's up for studying together? 📚",
                messageType: .text,
                timestamp: Date().addingTimeInterval(-1800),
                isRead: false,
                reactions: [],
                replyTo: nil,
                mediaUrl: nil,
                voiceDuration: nil,
                isEdited: false,
                deletedAt: nil
            ),
            unreadCount: 3,
            isGroup: true,
            groupName: "Study Group 📖",
            groupAvatar: nil,
            updatedAt: Date().addingTimeInterval(-1800),
            isOnline: false,
            isTyping: false
        )
        
        conversations.insert(groupConversation, at: 0)
        saveConversations()
    }
    
    func generateMockMessages(for conversationId: String) {
        guard let conversation = conversations.first(where: { $0.id == conversationId }) else { return }
        
        let sampleMessages = [
            "Hey! How are you doing? 😊",
            "I'm great! Just finished that course on SwiftUI.",
            "That's awesome! How was it?",
            "Really helpful! The animations section was my favorite. ✨",
            "I should check it out too!",
            "Definitely! Let me know if you need any help.",
            "Thanks! I appreciate it. 🙏",
            "No problem! That's what friends are for. 💙"
        ]
        
        messages = sampleMessages.enumerated().map { index, content in
            let isFromUser = index % 2 == 1
            
            return MessengerMessage(
                id: UUID().uuidString,
                conversationId: conversationId,
                senderId: isFromUser ? "current_user" : conversation.participants.first?.id.uuidString ?? "",
                content: content,
                messageType: .text,
                timestamp: Date().addingTimeInterval(TimeInterval(-Double(sampleMessages.count - index) * 300)),
                isRead: true,
                reactions: index == 3 ? [
                    MessageReaction(id: UUID().uuidString, userId: "current_user", emoji: "❤️", timestamp: Date())
                ] : [],
                replyTo: nil,
                mediaUrl: nil,
                voiceDuration: nil,
                isEdited: false,
                deletedAt: nil
            )
        }
        
        saveMessages(for: conversationId)
    }
}

// MARK: - Main Messenger View

struct MessengerView: View {
    @StateObject private var manager = MessengerManager()
    @State private var showNewMessage = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("0A0E27"),
                        Color("1A1F3A")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    searchBar
                    
                    // Conversations list
                    if manager.filteredConversations.isEmpty {
                        emptyState
                    } else {
                        conversationsList
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewMessage = true }) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color("00D4FF"))
                    }
                }
            }
            .sheet(isPresented: $showNewMessage) {
                NewMessageView()
            }
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.system(size: 16))
                
                TextField("Search messages", text: $manager.searchQuery)
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                if !manager.searchQuery.isEmpty {
                    Button(action: { manager.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var conversationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(manager.filteredConversations) { conversation in
                    NavigationLink(destination: MessengerChatView(conversation: conversation, manager: manager)) {
                        MessengerConversationRow(conversation: conversation)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 64))
                .foregroundColor(Color("00D4FF").opacity(0.5))
            
            Text("No conversations yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            
            Text("Start a new conversation to connect with others")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Conversation Row

struct MessengerConversationRow: View {
    let conversation: MessengerConversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack(alignment: .bottomTrailing) {
                if conversation.isGroup {
                    // Group avatar (stack of avatars)
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color("00D4FF"),
                                    Color("667EEA")
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                } else {
                    AsyncImage(url: URL(string: conversation.displayAvatar)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color("667EEA"))
                            .overlay(
                                Text(String(conversation.displayName.prefix(1)))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                }
                
                // Online indicator
                if conversation.isOnline && !conversation.isGroup {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle()
                                .stroke(Color("0A0E27"), lineWidth: 2)
                        )
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(timeAgo(lastMessage.timestamp))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                HStack(spacing: 4) {
                    if conversation.isTyping {
                        Text("Typing")
                            .font(.system(size: 14))
                            .foregroundColor(Color("00D4FF"))
                        
                        TypingIndicator()
                    } else if let lastMessage = conversation.lastMessage {
                        if lastMessage.senderId == "current_user" {
                            Image(systemName: lastMessage.isRead ? "checkmark.circle.fill" : "checkmark.circle")
                                .font(.system(size: 14))
                                .foregroundColor(lastMessage.isRead ? Color("00D4FF") : .gray)
                        }
                        
                        Text(lastMessage.content)
                            .font(.system(size: 14))
                            .foregroundColor(conversation.unreadCount > 0 ? .white : .gray)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .padding(.horizontal, 6)
                            .background(
                                Capsule()
                                    .fill(Color("00D4FF"))
                            )
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(
            Color.white.opacity(conversation.unreadCount > 0 ? 0.05 : 0)
        )
    }
}

// MARK: - Chat View

struct MessengerChatView: View {
    let conversation: MessengerConversation
    @ObservedObject var manager: MessengerManager
    @State private var messageText = ""
    @State private var showReactions = false
    @State private var selectedMessageId: String?
    @State private var showImagePicker = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("0A0E27"),
                    Color("1A1F3A")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(manager.messages) { message in
                                MessengerMessageBubbleView(
                                    message: message,
                                    isFromCurrentUser: message.senderId == "current_user",
                                    onReact: { emoji in
                                        manager.addReaction(to: message.id, emoji: emoji)
                                    },
                                    onDelete: {
                                        manager.deleteMessage(message.id)
                                    }
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                    }
                    .onChange(of: manager.messages.count) { _, _ in
                        if let lastMessage = manager.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onAppear {
                        if let lastMessage = manager.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                
                // Input bar
                messageInputBar
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    AsyncImage(url: URL(string: conversation.displayAvatar)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Color("667EEA"))
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(conversation.displayName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if conversation.isOnline && !conversation.isGroup {
                            Text("Active now")
                                .font(.system(size: 11))
                                .foregroundColor(Color("00D4FF"))
                        }
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color("00D4FF"))
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 18))
                            .foregroundColor(Color("00D4FF"))
                    }
                }
            }
        }
        .onAppear {
            manager.openConversation(conversation)
        }
    }
    
    private var messageInputBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.1))
            
            HStack(spacing: 12) {
                // Media buttons
                Button(action: { showImagePicker = true }) {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("00D4FF"))
                }
                
                Button(action: {
                    if manager.isRecording {
                        manager.stopRecording()
                    } else {
                        manager.startRecording()
                    }
                }) {
                    Image(systemName: manager.isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.system(size: 20))
                        .foregroundColor(manager.isRecording ? .red : Color("00D4FF"))
                }
                
                // Text input
                HStack(spacing: 8) {
                    TextField("Message...", text: $messageText, axis: .vertical)
                        .foregroundColor(.white)
                        .font(.system(size: 16))
                        .lineLimit(1...5)
                    
                    Button(action: {}) {
                        Image(systemName: "face.smiling")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.1))
                )
                
                // Send button
                Button(action: {
                    guard !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    manager.sendMessage(messageText)
                    messageText = ""
                }) {
                    Image(systemName: messageText.isEmpty ? "heart.fill" : "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Color("00D4FF"))
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color("0A0E27"))
    }
}

// MARK: - Message Bubble View

struct MessengerMessageBubbleView: View {
    let message: MessengerMessage
    let isFromCurrentUser: Bool
    let onReact: (String) -> Void
    let onDelete: () -> Void
    
    @State private var showReactions = false
    @State private var showActions = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isFromCurrentUser {
                Spacer(minLength: 60)
            }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                // Message content
                if message.isDeleted {
                    deletedMessageView
                } else {
                    switch message.messageType {
                    case .text:
                        textMessageView
                    case .image:
                        imageMessageView
                    case .video:
                        videoMessageView
                    case .voice:
                        voiceMessageView
                    case .gif, .sticker:
                        textMessageView
                    }
                }
                
                // Reactions
                if !message.reactions.isEmpty {
                    reactionsView
                }
                
                // Timestamp
                Text(formatTime(message.timestamp))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            .contextMenu {
                Button(action: { showReactions = true }) {
                    Label("React", systemImage: "heart")
                }
                
                Button(action: {}) {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }
                
                Button(action: {}) {
                    Label("Forward", systemImage: "arrowshape.turn.up.right")
                }
                
                if isFromCurrentUser {
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
            
            if !isFromCurrentUser {
                Spacer(minLength: 60)
            }
        }
        .sheet(isPresented: $showReactions) {
            ReactionPickerSheet(onSelect: { emoji in
                onReact(emoji)
                showReactions = false
            })
        }
    }
    
    private var textMessageView: some View {
        Text(message.content)
            .font(.system(size: 16))
            .foregroundColor(isFromCurrentUser ? .white : .white)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(isFromCurrentUser ?
                          LinearGradient(
                            gradient: Gradient(colors: [
                                Color("00D4FF"),
                                Color("667EEA")
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) :
                          LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
            )
    }
    
    private var imageMessageView: some View {
        AsyncImage(url: URL(string: message.mediaUrl ?? "")) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .overlay(
                    ProgressView()
                        .tint(.white)
                )
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private var videoMessageView: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            
            Image(systemName: "play.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.white)
        }
    }
    
    private var voiceMessageView: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
            }
            
            // Waveform
            HStack(spacing: 2) {
                ForEach(0..<20, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.5))
                        .frame(width: 2, height: CGFloat.random(in: 10...30))
                }
            }
            
            Text("\(Int(message.voiceDuration ?? 0))s")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(isFromCurrentUser ?
                      LinearGradient(
                        gradient: Gradient(colors: [
                            Color("00D4FF"),
                            Color("667EEA")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ) :
                      LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      )
                )
        )
    }
    
    private var deletedMessageView: some View {
        HStack(spacing: 6) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 12))
            
            Text("This message was deleted")
                .font(.system(size: 14))
                .italic()
        }
        .foregroundColor(.gray)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    private var reactionsView: some View {
        HStack(spacing: 4) {
            ForEach(message.reactions) { reaction in
                Text(reaction.emoji)
                    .font(.system(size: 16))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                    )
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: date)
    }
}

// MARK: - Reaction Picker Sheet

struct ReactionPickerSheet: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    let reactions = ["❤️", "😂", "😮", "😢", "😡", "👍", "👏", "🔥"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            Text("React")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(reactions, id: \.self) { emoji in
                    Button(action: {
                        onSelect(emoji)
                        dismiss()
                    }) {
                        Text(emoji)
                            .font(.system(size: 40))
                            .frame(width: 70, height: 70)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 400)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color("0A0E27"),
                    Color("1A1F3A")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .presentationDetents([.height(400)])
    }
}

// MARK: - New Message View

struct NewMessageView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color("0A0E27"),
                        Color("1A1F3A")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    Text("New Message")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Color("00D4FF"))
                }
            }
        }
    }
}

// MARK: - Helper Views
// Note: TypingIndicator moved to TypingIndicator.swift to avoid duplication
// Note: Color(hex:) extension moved to DesignTokens.swift to avoid duplication

private func timeAgo(_ date: Date) -> String {
    let seconds = Date().timeIntervalSince(date)
    
    if seconds < 60 {
        return "Just now"
    } else if seconds < 3600 {
        let minutes = Int(seconds / 60)
        return "\(minutes)m"
    } else if seconds < 86400 {
        let hours = Int(seconds / 3600)
        return "\(hours)h"
    } else if seconds < 604800 {
        let days = Int(seconds / 86400)
        return "\(days)d"
    } else {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
