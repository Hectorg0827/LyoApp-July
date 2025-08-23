import Foundation

/// Generic cursor-based paginator with de-duplication support
final class Paginator<Item: Identifiable> {
    private(set) var items: [Item] = []
    private var nextCursor: String?
    private var loading = false
    private let fetch: (_ cursor: String?) async throws -> (page: [Item], next: String?)
    
    /// Initialize paginator with fetch function
    init(fetch: @escaping (_ cursor: String?) async throws -> (page: [Item], next: String?)) {
        self.fetch = fetch
    }
    
    /// Load more items if needed based on current scroll position
    func loadMoreIfNeeded(currentIndex: Int) async throws {
        // Only load if we're near the end and not already loading
        guard currentIndex >= items.count - 5, !loading, hasMore else { return }
        
        loading = true
        defer { loading = false }
        
        do {
            let (page, next) = try await fetch(nextCursor)
            
            // De-duplicate by id
            let existingIds = Set(items.map { String(describing: $0.id) })
            let newItems = page.filter { !existingIds.contains(String(describing: $0.id)) }
            
            items.append(contentsOf: newItems)
            nextCursor = next
            
        } catch {
            // Re-throw error for handling at view level
            throw error
        }
    }
    
    /// Whether more items can be loaded
    var hasMore: Bool {
        return nextCursor != nil
    }
    
    /// Whether currently loading
    var isLoading: Bool {
        return loading
    }
    
    /// Reset paginator to initial state
    func reset() {
        items.removeAll()
        nextCursor = nil
        loading = false
    }
    
    /// Load initial page
    func loadInitialPage() async throws {
        reset()
        try await loadMoreIfNeeded(currentIndex: 0)
    }
}

/// Feed item for pagination
struct FeedItem: Identifiable {
    let id: String
    let type: String
    let title: String?
    let content: String?
    let imageUrl: String?
    let author: UserDTO?
    let course: CourseDTO?
    let createdAt: Date
    
    init(from dto: FeedItemDTO) {
        self.id = dto.id
        self.type = dto.type
        self.title = dto.title
        self.content = dto.content
        self.imageUrl = dto.imageUrl
        self.author = dto.author
        self.course = dto.course
        self.createdAt = dto.createdAt
    }
}

/// Discussion item for community pagination
struct DiscussionItem: Identifiable {
    let id: String
    let title: String
    let content: String
    let author: UserDTO
    let tags: [String]
    let likes: Int
    let replies: Int
    let createdAt: Date
    
    init(from dto: DiscussionDTO) {
        self.id = dto.id
        self.title = dto.title
        self.content = dto.content
        self.author = dto.author
        self.tags = dto.tags
        self.likes = dto.likes
        self.replies = dto.replies
        self.createdAt = dto.createdAt
    }
}