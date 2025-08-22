import Foundation

/// Cursor-based pagination manager for feeds and community content
@MainActor
class PaginationManager<T: Decodable>: ObservableObject {
    
    @Published var items: [T] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMorePages = true
    @Published var error: Error?
    
    private var nextCursor: String?
    private let apiClient: APIClient
    private let endpoint: String
    private let pageSize: Int
    private let normalizer: DataNormalizer?
    
    // Deduplication
    private var seenIds = Set<String>()
    private let getItemId: (T) -> String
    
    init(
        apiClient: APIClient,
        endpoint: String,
        pageSize: Int = 20,
        normalizer: DataNormalizer? = nil,
        getItemId: @escaping (T) -> String
    ) {
        self.apiClient = apiClient
        self.endpoint = endpoint
        self.pageSize = pageSize
        self.normalizer = normalizer
        self.getItemId = getItemId
    }
    
    // MARK: - Loading Methods
    
    /// Load first page of items
    func loadInitialPage() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            let response = try await fetchPage(cursor: nil)
            
            items = deduplicateItems(response.items)
            nextCursor = response.nextCursor
            hasMorePages = response.nextCursor != nil
            seenIds = Set(items.map(getItemId))
            
            print("✅ Loaded initial page: \(items.count) items")
            
        } catch {
            print("❌ Failed to load initial page: \(error)")
            self.error = error
        }
        
        isLoading = false
    }
    
    /// Load next page of items
    func loadNextPage() async {
        guard !isLoadingMore,
              !isLoading,
              hasMorePages,
              let cursor = nextCursor else {
            return
        }
        
        isLoadingMore = true
        
        do {
            let response = try await fetchPage(cursor: cursor)
            
            let newItems = deduplicateItems(response.items, againstExisting: true)
            items.append(contentsOf: newItems)
            
            // Update cursor and pagination state
            nextCursor = response.nextCursor
            hasMorePages = response.nextCursor != nil
            
            // Update seen IDs
            for item in newItems {
                seenIds.insert(getItemId(item))
            }
            
            print("✅ Loaded next page: \(newItems.count) new items (total: \(items.count))")
            
        } catch {
            print("❌ Failed to load next page: \(error)")
            self.error = error
        }
        
        isLoadingMore = false
    }
    
    /// Refresh all content (pull to refresh)
    func refresh() async {
        nextCursor = nil
        hasMorePages = true
        seenIds.removeAll()
        items.removeAll()
        
        await loadInitialPage()
    }
    
    // MARK: - Private Methods
    
    private func fetchPage(cursor: String?) async throws -> PaginationResponse<T> {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(pageSize))
        ]
        
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }
        
        var components = URLComponents(string: endpoint)
        components?.queryItems = queryItems
        
        let fullPath = components?.string?.replacingOccurrences(of: endpoint, with: "") ?? ""
        let response: PaginationResponse<T> = try await apiClient.get(endpoint + fullPath)
        
        return response
    }
    
    private func deduplicateItems(_ items: [T], againstExisting: Bool = false) -> [T] {
        return items.filter { item in
            let id = getItemId(item)
            
            if againstExisting {
                return !seenIds.contains(id)
            } else {
                // For initial load, just dedupe within this batch
                let wasSeen = seenIds.contains(id)
                seenIds.insert(id)
                return !wasSeen
            }
        }
    }
    
    // MARK: - Prefetch Support
    
    /// Check if we should prefetch next page (when user scrolls near end)
    func shouldPrefetchNextPage(currentIndex: Int) -> Bool {
        let prefetchThreshold = max(5, pageSize / 4) // Prefetch when within last 5 items or 25% of page size
        return currentIndex >= items.count - prefetchThreshold
    }
    
    /// Automatically load next page if needed
    func prefetchIfNeeded(for index: Int) {
        if shouldPrefetchNextPage(currentIndex: index) && !isLoadingMore && hasMorePages {
            Task {
                await loadNextPage()
            }
        }
    }
}

// MARK: - Pagination Response Structure
struct PaginationResponse<T: Decodable>: Decodable {
    let items: [T]
    let nextCursor: String?
    
    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}

// MARK: - Feed Pagination Manager
class FeedPaginationManager: PaginationManager<FeedItemDTO> {
    
    init(apiClient: APIClient) {
        super.init(
            apiClient: apiClient,
            endpoint: "feeds",
            pageSize: 20,
            normalizer: DataNormalizer(),
            getItemId: { $0.id }
        )
    }
    
    /// Normalize feed data after loading
    override func loadInitialPage() async {
        await super.loadInitialPage()
        await normalizeFeedData()
    }
    
    override func loadNextPage() async {
        await super.loadNextPage()
        await normalizeFeedData()
    }
    
    private func normalizeFeedData() async {
        guard let normalizer = normalizer else { return }
        
        // Extract and normalize course data from feed
        let courseDTOs = items.compactMap { $0.course }
        if !courseDTOs.isEmpty {
            try? normalizer.normalizeCourses(courseDTOs)
        }
        
        // Extract and normalize user data from feed
        let userDTOs = items.compactMap { $0.author }
        for userDTO in userDTOs {
            try? normalizer.normalizeUser(userDTO)
        }
    }
}

// MARK: - Community Pagination Manager
class CommunityPaginationManager: PaginationManager<DiscussionDTO> {
    
    init(apiClient: APIClient) {
        super.init(
            apiClient: apiClient,
            endpoint: "community/discussions",
            pageSize: 15,
            normalizer: DataNormalizer(),
            getItemId: { $0.id }
        )
    }
    
    /// Filter discussions by tag
    func loadDiscussions(withTag tag: String) async {
        // Update endpoint with tag filter
        let taggedEndpoint = "community/discussions?tag=\(tag)"
        
        // Create new pagination manager with filtered endpoint
        let filteredManager = PaginationManager<DiscussionDTO>(
            apiClient: apiClient,
            endpoint: taggedEndpoint,
            pageSize: pageSize,
            normalizer: normalizer,
            getItemId: getItemId
        )
        
        await filteredManager.loadInitialPage()
        
        // Copy results to this manager
        self.items = filteredManager.items
        self.nextCursor = filteredManager.nextCursor
        self.hasMorePages = filteredManager.hasMorePages
        self.error = filteredManager.error
        self.isLoading = filteredManager.isLoading
    }
    
    /// Search discussions
    func searchDiscussions(query: String) async {
        let searchEndpoint = "community/discussions/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        let searchManager = PaginationManager<DiscussionDTO>(
            apiClient: apiClient,
            endpoint: searchEndpoint,
            pageSize: pageSize,
            normalizer: normalizer,
            getItemId: getItemId
        )
        
        await searchManager.loadInitialPage()
        
        // Copy results
        self.items = searchManager.items
        self.nextCursor = searchManager.nextCursor
        self.hasMorePages = searchManager.hasMorePages
        self.error = searchManager.error
        self.isLoading = searchManager.isLoading
    }
}

// MARK: - Pagination State Helpers
extension PaginationManager {
    
    var isEmpty: Bool {
        return items.isEmpty && !isLoading
    }
    
    var shouldShowLoadingIndicator: Bool {
        return isLoading && items.isEmpty
    }
    
    var shouldShowLoadMoreIndicator: Bool {
        return isLoadingMore && hasMorePages
    }
    
    var canLoadMore: Bool {
        return hasMorePages && !isLoadingMore && !isLoading
    }
}