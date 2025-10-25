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
    @Published var feedItems: [FeedItem] = []
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
        // APIConfig is not defined, using APIEnvironment instead
        print("🌐 Backend: \(APIEnvironment.current.base.absoluteString)")
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
            
            // The APIClient now returns the canonical `FeedItem` model directly.
            let newFeedItems = response.posts
            
            if refresh {
                self.feedItems = newFeedItems
            } else {
                self.feedItems.append(contentsOf: newFeedItems)
            }
            
            self.hasMorePages = newFeedItems.count >= pageSize
            self.currentPage += 1
            self.isLoading = false
            
            print("✅ Feed updated with \(newFeedItems.count) REAL items (total: \(self.feedItems.count))")
            
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
    func toggleLike(postId: UUID) async {
        print("❤️ Toggling like for post: \(postId)")
        
        // Optimistic update
        guard let index = feedItems.firstIndex(where: { $0.id == postId }) else { return }
        let originalIsLiked = feedItems[index].engagement.isLiked
        let originalLikes = feedItems[index].engagement.likes
        
        feedItems[index].engagement.isLiked.toggle()
        feedItems[index].engagement.likes += feedItems[index].engagement.isLiked ? 1 : -1
        
        do {
            _ = try await apiClient.likePost(postId.uuidString)
            print("✅ Like toggled successfully via backend")
        } catch {
            print("❌ Failed to toggle like: \(error)")
            // Revert optimistic update on failure
            feedItems[index].engagement.isLiked = originalIsLiked
            feedItems[index].engagement.likes = originalLikes
        }
    }
    
    // MARK: - Add Comment
    func addComment(postId: UUID, text: String) async {
        print("💬 Adding comment to post: \(postId)")
        
        do {
            _ = try await apiClient.commentOnPost(postId.uuidString, comment: text)
            
            // Update local comment count
            if let index = feedItems.firstIndex(where: { $0.id == postId }) {
                feedItems[index].engagement.comments += 1
            }
            
            print("✅ Comment added successfully")
            
        } catch {
            print("❌ Failed to add comment: \(error)")
        }
    }
    
    // MARK: - Share Post
    func sharePost(postId: UUID) async {
        print("🔗 Sharing post: \(postId)")
        
        do {
            let response = try await apiClient.sharePost(postId.uuidString)
            
            // Update local share count
            if let index = feedItems.firstIndex(where: { $0.id == postId }) {
                feedItems[index].engagement.shares = response.sharesCount
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
