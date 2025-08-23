import Foundation
import SwiftUI

/// Feeds View Model with cursor pagination
final class FeedsViewModel: ObservableObject {
    @Published var feed: [FeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    private lazy var paginator = Paginator<FeedItem> { cursor in
        let queryParams = cursor.map { "cursor=\($0)&" } ?? ""
        let res: FeedResponse = try await self.apiClient.get("feeds?\(queryParams)limit=20")
        return (res.items.map(FeedItem.init), res.nextCursor)
    }
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    /// Load initial page of feed items
    func loadInitialPage() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await paginator.loadInitialPage()
            await MainActor.run {
                self.feed = paginator.items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorPresenter.userMessage(for: error)
                self.isLoading = false
            }
        }
    }
    
    /// Handle item appearance for prefetching
    func onAppearItem(at index: Int) {
        Task {
            do {
                try await paginator.loadMoreIfNeeded(currentIndex: index)
                await MainActor.run {
                    self.feed = paginator.items
                }
            } catch {
                await MainActor.run {
                    // Don't overwrite existing content on prefetch errors
                    if self.feed.isEmpty {
                        self.errorMessage = ErrorPresenter.userMessage(for: error)
                    }
                }
            }
        }
    }
    
    /// Refresh feed from beginning
    func refresh() async {
        await loadInitialPage()
    }
    
    /// Whether more items can be loaded
    var hasMore: Bool {
        return paginator.hasMore
    }
}

/// Community View Model with cursor pagination
final class CommunityViewModel: ObservableObject {
    @Published var discussions: [DiscussionItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClient
    private lazy var paginator = Paginator<DiscussionItem> { cursor in
        let queryParams = cursor.map { "cursor=\($0)&" } ?? ""
        let res: CommunityResponse = try await self.apiClient.get("community/discussions?\(queryParams)limit=20")
        return (res.discussions.map(DiscussionItem.init), res.nextCursor)
    }
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    /// Load initial page of discussions
    func loadInitialPage() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            try await paginator.loadInitialPage()
            await MainActor.run {
                self.discussions = paginator.items
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = ErrorPresenter.userMessage(for: error)
                self.isLoading = false
            }
        }
    }
    
    /// Handle item appearance for prefetching
    func onAppearItem(at index: Int) {
        Task {
            do {
                try await paginator.loadMoreIfNeeded(currentIndex: index)
                await MainActor.run {
                    self.discussions = paginator.items
                }
            } catch {
                await MainActor.run {
                    // Don't overwrite existing content on prefetch errors
                    if self.discussions.isEmpty {
                        self.errorMessage = ErrorPresenter.userMessage(for: error)
                    }
                }
            }
        }
    }
    
    /// Refresh discussions from beginning
    func refresh() async {
        await loadInitialPage()
    }
    
    /// Whether more items can be loaded
    var hasMore: Bool {
        return paginator.hasMore
    }
}