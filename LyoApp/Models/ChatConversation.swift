import Foundation

/// Canonical chat conversation model (extracted from Models.swift to eliminate duplicate symbol issues)
public struct ChatConversation: Identifiable, Codable, Equatable {
    public let id: String
    public var title: String?
    public var participantIds: [String]
    public var lastMessage: ResponseChatMessage?
    public var unreadCount: Int?
    public var updatedAt: String

    public init(id: String, title: String? = nil, participantIds: [String] = [], lastMessage: ResponseChatMessage? = nil, unreadCount: Int? = nil, updatedAt: String) {
        self.id = id
        self.title = title
        self.participantIds = participantIds
        self.lastMessage = lastMessage
        self.unreadCount = unreadCount
        self.updatedAt = updatedAt
    }
}
