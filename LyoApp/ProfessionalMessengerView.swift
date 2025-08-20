import SwiftUI
import Foundation

// MARK: - Professional Messenger Models

struct MessengerUser {
    let id: String
    let name: String
    let email: String
    let avatarURL: String?
    let isOnline: Bool
    let lastSeen: Date?
}

struct ProfessionalMessengerMessage: Identifiable, Codable {
    let id: String
    let senderId: String
    let recipientId: String
    let content: String
    let messageType: MessageType
    let timestamp: Date
    let isRead: Bool
    
    enum MessageType: String, CaseIterable, Codable {
        case text, image, video, file
    }
    
    init(id: String = UUID().uuidString, senderId: String, recipientId: String, content: String, messageType: MessageType = .text, timestamp: Date = Date(), isRead: Bool = false) {
        self.id = id
        self.senderId = senderId
        self.recipientId = recipientId
        self.content = content
        self.messageType = messageType
        self.timestamp = timestamp
        self.isRead = isRead
    }
}

struct MessengerConversation: Identifiable, Codable {
    let id: String
    let participants: [String]
    let lastMessage: ProfessionalMessengerMessage?
    let updatedAt: Date
    let isGroup: Bool
    let name: String?
    let unreadCount: Int
    
    init(id: String = UUID().uuidString, participants: [String], lastMessage: ProfessionalMessengerMessage? = nil, updatedAt: Date = Date(), isGroup: Bool = false, name: String? = nil, unreadCount: Int = 0) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
        self.isGroup = isGroup
        self.name = name
        self.unreadCount = unreadCount
    }
}

// MARK: - Messenger API Service

@MainActor
class MessengerAPIService: ObservableObject {
    private let baseURL = LyoConfiguration.backendURL
    
    func getConversations() async throws -> [MessengerConversation] {
        guard let url = URL(string: "\(baseURL)/api/v1/messenger/conversations") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([String: [MessengerConversation]].self, from: data)
        return response["conversations"] ?? []
    }
    
    func getMessages(conversationId: String) async throws -> [ProfessionalMessengerMessage] {
        guard let url = URL(string: "\(baseURL)/api/v1/messenger/conversations/\(conversationId)/messages") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([String: [ProfessionalMessengerMessage]].self, from: data)
        return response["messages"] ?? []
    }
    
    func sendMessage(conversationId: String, content: String, recipientId: String) async throws -> ProfessionalMessengerMessage {
        guard let url = URL(string: "\(baseURL)/api/v1/messenger/conversations/\(conversationId)/messages") else {
            throw URLError(.badURL)
        }
        
        let message = [
            "sender_id": "1", // Current user ID
            "recipient_id": recipientId,
            "content": content,
            "message_type": "text"
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: message)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: ProfessionalMessengerMessage].self, from: data)
        return response["message"]!
    }
}

// MARK: - Professional Messenger ViewModel

@MainActor
class ProfessionalMessengerViewModel: ObservableObject {
    @Published var conversations: [MessengerConversation] = []
    @Published var currentMessages: [ProfessionalMessengerMessage] = []
    @Published var selectedConversation: MessengerConversation?
    @Published var currentInput = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isTyping = false
    @Published var searchText = ""
    
    private let apiService = MessengerAPIService()
    private var webSocketService: LyoWebSocketService?
    
    init() {
        setupWebSocket()
        Task {
            await loadConversations()
        }
    }
    
    func setupWebSocket() {
    webSocketService = LyoWebSocketService.shared
    // Connect with a real user id; TODO: wire from authenticated user context
    webSocketService?.connect(userId: 1)
    }
    
    func loadConversations() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if !LyoConfiguration.enableMockData {
                conversations = try await apiService.getConversations()
            } else {
                conversations = generateMockConversations()
            }
        } catch {
            errorMessage = "Failed to load conversations: \(error.localizedDescription)"
            conversations = generateMockConversations() // Fallback
        }
    }
    
    func selectConversation(_ conversation: MessengerConversation) async {
        selectedConversation = conversation
        await loadMessages(for: conversation.id)
    }
    
    func loadMessages(for conversationId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if !LyoConfiguration.enableMockData {
                currentMessages = try await apiService.getMessages(conversationId: conversationId)
            } else {
                currentMessages = generateMockMessages(for: conversationId)
            }
        } catch {
            errorMessage = "Failed to load messages: \(error.localizedDescription)"
            currentMessages = generateMockMessages(for: conversationId) // Fallback
        }
    }
    
    func sendMessage() async {
        guard !currentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let conversation = selectedConversation else { return }
        
        let messageContent = currentInput
        currentInput = ""
        
        // Optimistic UI update
        let tempMessage = ProfessionalMessengerMessage(
            id: UUID().uuidString,
            senderId: "1",
            recipientId: conversation.participants.first { $0 != "1" } ?? "",
            content: messageContent,
            messageType: .text,
            timestamp: Date(),
            isRead: false
        )
        currentMessages.append(tempMessage)
        
        do {
            if !LyoConfiguration.enableMockData {
                let sentMessage = try await apiService.sendMessage(
                    conversationId: conversation.id,
                    content: messageContent,
                    recipientId: tempMessage.recipientId
                )
                // Replace temp message with real one
                if let index = currentMessages.firstIndex(where: { $0.id == tempMessage.id }) {
                    currentMessages[index] = sentMessage
                }
            }
        } catch {
            errorMessage = "Failed to send message: \(error.localizedDescription)"
            // Remove temp message on failure
            currentMessages.removeAll { $0.id == tempMessage.id }
        }
    }
    
    private func handleRealtimeMessage(_ message: Any) async {
        // Handle real-time WebSocket messages
        // Implementation depends on your WebSocket message format
    }
    
    private func generateMockConversations() -> [MessengerConversation] {
        return [
            MessengerConversation(
                id: "conv_1",
                participants: ["1", "2"],
                lastMessage: ProfessionalMessengerMessage(
                    id: "msg_1",
                    senderId: "2",
                    recipientId: "1",
                    content: "Hey! How's your learning progress going?",
                    messageType: .text,
                    timestamp: Date().addingTimeInterval(-3600),
                    isRead: false
                ),
                updatedAt: Date().addingTimeInterval(-3600),
                isGroup: false,
                name: "Jane Smith",
                unreadCount: 2
            ),
            MessengerConversation(
                id: "conv_2",
                participants: ["1", "3"],
                lastMessage: ProfessionalMessengerMessage(
                    id: "msg_2",
                    senderId: "3",
                    recipientId: "1",
                    content: "Check out this amazing AI course!",
                    messageType: .text,
                    timestamp: Date().addingTimeInterval(-7200),
                    isRead: true
                ),
                updatedAt: Date().addingTimeInterval(-7200),
                isGroup: false,
                name: "Mike Johnson",
                unreadCount: 0
            )
        ]
    }
    
    private func generateMockMessages(for conversationId: String) -> [ProfessionalMessengerMessage] {
        return [
            ProfessionalMessengerMessage(
                id: "msg_1",
                senderId: "2",
                recipientId: "1",
                content: "Hey! How's your learning progress going?",
                messageType: .text,
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false
            ),
            ProfessionalMessengerMessage(
                id: "msg_2",
                senderId: "1",
                recipientId: "2",
                content: "Going great! Just finished the SwiftUI module.",
                messageType: .text,
                timestamp: Date().addingTimeInterval(-3300),
                isRead: true
            ),
            ProfessionalMessengerMessage(
                id: "msg_3",
                senderId: "2",
                recipientId: "1",
                content: "Awesome! Want to collaborate on a project?",
                messageType: .text,
                timestamp: Date().addingTimeInterval(-3000),
                isRead: false
            )
        ]
    }
    
    var filteredConversations: [MessengerConversation] {
        if searchText.isEmpty {
            return conversations
        }
        return conversations.filter { conversation in
            // Filter by participant names or last message content
            return conversation.name?.localizedCaseInsensitiveContains(searchText) == true ||
                   conversation.lastMessage?.content.localizedCaseInsensitiveContains(searchText) == true
        }
    }
}

// MARK: - Professional Messenger View

struct ProfessionalMessengerView: View {
    @StateObject private var viewModel = ProfessionalMessengerViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                if viewModel.selectedConversation == nil {
                    conversationsListView
                } else {
                    chatView
                }
            }
            .background(DesignTokens.Colors.primaryBg)
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadConversations()
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: { 
                    if viewModel.selectedConversation != nil {
                        viewModel.selectedConversation = nil
                    } else {
                        dismiss()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                        if viewModel.selectedConversation != nil {
                            Text("Messages")
                                .font(DesignTokens.Typography.bodyMedium)
                        }
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
                
                Spacer()
                
                Text(viewModel.selectedConversation?.name ?? "Messages")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                if viewModel.selectedConversation == nil {
                    Button(action: {}) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.md)
            
            if viewModel.selectedConversation == nil {
                searchBarView
            }
        }
        .background(DesignTokens.Colors.glassBg)
    }
    
    private var searchBarView: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            TextField("Search conversations...", text: $viewModel.searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(DesignTokens.Typography.body)
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassOverlay)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.bottom, DesignTokens.Spacing.md)
    }
    
    // MARK: - Conversations List
    
    private var conversationsListView: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(viewModel.filteredConversations, id: \.id) { conversation in
                    ConversationRowView(conversation: conversation) {
                        Task {
                            await viewModel.selectConversation(conversation)
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
    
    // MARK: - Chat View
    
    private var chatView: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(viewModel.currentMessages, id: \.id) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isTyping {
                            TypingIndicatorView()
                        }
                    }
                    .padding(DesignTokens.Spacing.md)
                }
                .onChange(of: viewModel.currentMessages.count) { _, _ in
                    if let lastMessage = viewModel.currentMessages.last {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            messageInputView
        }
    }
    
    private var messageInputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                // Attachment button
                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                // Message input
                HStack(spacing: DesignTokens.Spacing.sm) {
                    TextField("Type a message...", text: $viewModel.currentInput, axis: .vertical)
                        .textFieldStyle(PlainTextFieldStyle())
                        .lineLimit(1...4)
                        .font(DesignTokens.Typography.body)
                    
                    if viewModel.currentInput.isEmpty {
                        Button(action: {}) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 18))
                                .foregroundColor(DesignTokens.Colors.primary)
                        }
                    }
                }
                .padding(DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.glassOverlay)
                )
                
                // Send button
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(viewModel.currentInput.isEmpty ? DesignTokens.Colors.textSecondary : DesignTokens.Colors.primary)
                }
                .disabled(viewModel.currentInput.isEmpty)
            }
            .padding(DesignTokens.Spacing.md)
            .background(DesignTokens.Colors.glassBg)
        }
    }
}

// MARK: - Conversation Row View

struct ConversationRowView: View {
    let conversation: MessengerConversation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Avatar
                AsyncImage(url: URL(string: "https://i.pravatar.cc/150?img=\(conversation.participants.first ?? "1")")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(DesignTokens.Colors.primary.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(DesignTokens.Colors.primary)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(conversation.name ?? "User \(conversation.participants.first ?? "")")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                        
                        Text(timeString(from: conversation.updatedAt))
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    HStack {
                        Text(conversation.lastMessage?.content ?? "No messages yet")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if conversation.unreadCount > 0 {
                            Circle()
                                .fill(DesignTokens.Colors.primary)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Text("\(conversation.unreadCount)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.glassOverlay)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
    if Calendar.current.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEE"
        } else {
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ProfessionalMessengerMessage
    
    private var isFromCurrentUser: Bool {
        message.senderId == "1" // Current user ID
    }
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 50) }
            
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(isFromCurrentUser ? .white : DesignTokens.Colors.textPrimary)
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(isFromCurrentUser ? DesignTokens.Colors.primary : DesignTokens.Colors.glassOverlay)
                    )
                
                Text(timeString(from: message.timestamp))
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            if !isFromCurrentUser { Spacer(minLength: 50) }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Typing Indicator View

struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(DesignTokens.Colors.textSecondary)
                        .frame(width: 6, height: 6)
                        .scaleEffect(animationPhase == index ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.2), value: animationPhase)
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassOverlay)
            )
            
            Spacer(minLength: 50)
        }
        .onAppear {
            animationPhase = 0
        }
    }
}
