//
//  RealFeedService.swift
//  LyoApp
//
//  PRODUCTION-ONLY FEED SERVICE
//  This service loads REAL data from the backend API.
//  🚫 NO MOCK DATA - PRODUCTION ONLY
//

import Foundation
import SwiftUI
import Combine

@MainActor
class RealFeedService: ObservableObject {
    static let shared = RealFeedService()
    
    // MARK: - Published Properties
    @Published var feedItems: [RealFeedItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var hasMorePages = true
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private var currentPage = 1
    private let pageSize = 20
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        print("✅ RealFeedService initialized - PRODUCTION MODE ONLY")
        print("🌐 Backend: \(APIConfig.baseURL)")
        print("🚫 Mock data: DISABLED")
    }
    
    // MARK: - Load Feed from Backend
    func loadFeed(refresh: Bool = false) async {
        if refresh {
            currentPage = 1
            feedItems.removeAll()
            hasMorePages = true
        }
        
        guard !isLoading && hasMorePages else { return }
        
        isLoading = true
        error = nil
        
        print("📡 Loading real feed from backend: page=\(currentPage), limit=\(pageSize)")
        
        do {
            // ✅ CALL REAL BACKEND API
            let response = try await apiClient.loadFeed(page: currentPage, limit: pageSize)
            
            print("✅ Received \(response.posts.count) REAL posts from backend")
            
            // Convert backend posts to FeedItem
            let realFeedItems = response.posts.map { post -> RealFeedItem in
                return RealFeedItem(
                    id: post.id,
                    author: User(
                        id: post.user.id,
                        username: post.user.username,
                        email: post.user.email,
                        fullName: post.user.fullName,
                        avatar: post.user.avatar,
                        bio: nil,
                        followers: 0,
                        following: 0,
                        isVerified: post.user.isVerified,
                        xp: post.user.xp,
                        level: post.user.level,
                        streak: post.user.streak,
                        badges: post.user.badges
                    ),
                    content: post.content,
                    mediaUrl: post.mediaUrl,
                    mediaType: post.mediaType,
                    timestamp: post.timestamp,
                    likes: post.likes,
                    comments: post.comments,
                    shares: post.shares,
                    isLiked: post.isLiked,
                    tags: post.tags
                )
            }
            
            if refresh {
                self.feedItems = realFeedItems
            } else {
                self.feedItems.append(contentsOf: realFeedItems)
            }
            
            self.hasMorePages = response.posts.count >= pageSize
            self.currentPage += 1
            self.isLoading = false
            
            print("✅ Feed updated with \(realFeedItems.count) REAL items (total: \(self.feedItems.count))")
            
        } catch {
            print("❌ Failed to load feed from backend: \(error)")
            self.error = error
            self.isLoading = false
            
            // 🚫 DO NOT FALLBACK TO MOCK DATA!
            // Show error state instead
        }
    }
    
    // MARK: - Refresh Feed
    func refreshFeed() async {
        print("🔄 Refreshing feed from backend...")
        await loadFeed(refresh: true)
    }
    
    // MARK: - Load More (Pagination)
    func loadMore() async {
        guard !isLoading && hasMorePages else { return }
        await loadFeed(refresh: false)
    }
    
    // MARK: - Toggle Like
    func toggleLike(postId: String) async {
        print("❤️ Toggling like for post: \(postId)")
        
        do {
            try await apiClient.toggleLike(postId: postId)
            
            // Update local state
            if let index = feedItems.firstIndex(where: { $0.id == postId }) {
                feedItems[index].isLiked.toggle()
                feedItems[index].likes += feedItems[index].isLiked ? 1 : -1
            }
            
            print("✅ Like toggled successfully")
            
        } catch {
            print("❌ Failed to toggle like: \(error)")
            // Revert optimistic update
            if let index = feedItems.firstIndex(where: { $0.id == postId }) {
                feedItems[index].isLiked.toggle()
                feedItems[index].likes += feedItems[index].isLiked ? 1 : -1
            }
        }
    }
    
    // MARK: - Add Comment
    func addComment(postId: String, text: String) async {
        print("💬 Adding comment to post: \(postId)")
        
        do {
            let comment = try await apiClient.addComment(postId: postId, text: text)
            
            // Update local comment count
            if let index = feedItems.firstIndex(where: { $0.id == postId }) {
                feedItems[index].comments += 1
            }
            
            print("✅ Comment added successfully")
            
        } catch {
            print("❌ Failed to add comment: \(error)")
        }
    }
    
    // MARK: - Share Post
    func sharePost(postId: String) async {
        print("🔗 Sharing post: \(postId)")
        
        do {
            try await apiClient.sharePost(postId: postId)
            
            // Update local share count
            if let index = feedItems.firstIndex(where: { $0.id == postId }) {
                feedItems[index].shares += 1
            }
            
            print("✅ Post shared successfully")
            
        } catch {
            print("❌ Failed to share post: \(error)")
        }
    }
    
    // MARK: - Clear Cache
    func clearCache() {
        print("🗑️ Clearing feed cache")
        feedItems.removeAll()
        currentPage = 1
        hasMorePages = true
        error = nil
    }
}

// MARK: - RealFeedItem Model
struct RealFeedItem: Identifiable, Codable {
    let id: String
    var author: User
    let content: String
    let mediaUrl: String?
    let mediaType: String?
    let timestamp: String
    var likes: Int
    var comments: Int
    var shares: Int
    var isLiked: Bool
    let tags: [String]
}
