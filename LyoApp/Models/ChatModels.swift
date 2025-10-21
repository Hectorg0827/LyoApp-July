// This file previously duplicated numerous chat & story models.
// All canonical definitions now live in `Models/Models.swift`.
// We keep lightweight typealiases to avoid breaking existing imports.
import Foundation

@available(*, deprecated, message: "Use AIMessage / ChatConversation / ResponseChatMessage from Models.swift")
typealias LegacyChatMessage = ChatMessage

@available(*, deprecated, message: "Use ChatConversation from Models.swift")
typealias LegacyChatConversation = ChatConversation

// Safe array access removed - use the one from HomeFeedView.swift
