import SwiftUI
import Foundation
import Combine

// MARK: - Optimized View Models

/// High-performance Feed Manager with efficient data loading and caching
@MainActor
class OptimizedFeedManager: OptimizedViewModel {
    @Published var feedContent: [FeedContentType] = []
    @Published var isLoading = false
    @Published var hasMoreContent = true
    
    private var cancellables = Set<AnyCancellable>()
    private var loadingTask: Task<Void, Never>?
    private var currentPage = 0
    private var preloadedContent: [FeedContentType] = []
    
    init() {
        setupMemoryWarningObserver()
        preloadInitialContent()
    }
    
    // MARK: - OptimizedViewModel Protocol
    
    func cleanup() {
        loadingTask?.cancel()
        cancellables.removeAll()
        preloadedContent.removeAll()
    }
    
    func preload() {
        Task {
            await preloadNextBatch()
        }
    }
    
    func handleMemoryWarning() {
        // Reduce memory footprint
        if feedContent.count > 20 {
            feedContent.removeFirst(feedContent.count - 20)
        }
        preloadedContent.removeAll()
        currentPage = max(0, currentPage - 2)
    }
    
    // MARK: - Feed Management
    
    func loadMoreContent() {
        guard !isLoading && hasMoreContent else { return }
        
        loadingTask?.cancel()
        loadingTask = Task {
            await loadContentBatch()
        }
    }
    
    func refreshContent() {
        loadingTask?.cancel()
        currentPage = 0
        hasMoreContent = true
        
        loadingTask = Task {
            feedContent.removeAll()
            await loadContentBatch()
            await preloadNextBatch()
        }
    }
    
    private func preloadInitialContent() {
        Task {
            await loadContentBatch()
            await preloadNextBatch()
        }
    }
    
    private func loadContentBatch() async {
        isLoading = true
        defer { isLoading = false }
        
        PerformanceOptimizer.PerformanceMetrics.shared.startTimer(for: "feed_load_batch")
        
        // Use preloaded content if available
        if !preloadedContent.isEmpty {
            let batchContent = Array(preloadedContent.prefix(pageSize))
            preloadedContent.removeFirst(min(pageSize, preloadedContent.count))
            
            feedContent.append(contentsOf: batchContent)
            currentPage += 1
            
            PerformanceOptimizer.PerformanceMetrics.shared.endTimer(for: "feed_load_batch")
            return
        }
        
        // Simulate network loading with optimized data
        let newContent = await generateOptimizedFeedContent(page: currentPage, pageSize: pageSize)
        
        feedContent.append(contentsOf: newContent)
        currentPage += 1
        
        if newContent.count < pageSize {
            hasMoreContent = false
        }
        
        PerformanceOptimizer.PerformanceMetrics.shared.endTimer(for: "feed_load_batch")
    }
    
    private func preloadNextBatch() async {
        guard preloadedContent.isEmpty else { return }
        
        BackgroundTaskManager.shared.schedule(id: "preload_feed") {
            let nextContent = await self.generateOptimizedFeedContent(
                page: self.currentPage,
                pageSize: self.pageSize
            )
            
            await MainActor.run {
                self.preloadedContent = nextContent
            }
        }
    }
    
    private func generateOptimizedFeedContent(page: Int, pageSize: Int) async -> [FeedContentType] {
        // Simulate async content generation with proper memory management
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let content = self.createFeedBatch(page: page, pageSize: pageSize)
                continuation.resume(returning: content)
            }
        }
    }
    
    private func createFeedBatch(page: Int, pageSize: Int) -> [FeedContentType] {
        var batch: [FeedContentType] = []
        
        for i in 0..<pageSize {
            let index = page * pageSize + i
            
            // Mix content types for variety
            switch index % 7 {
            case 0, 1, 2, 3:
                // Video content (70% of feed)
                batch.append(.video(createOptimizedFeedItem(index: index)))
            case 4, 5:
                // Course suggestions (20% of feed)
                batch.append(.courseSuggestions(createOptimizedCourses()))
            case 6:
                // User suggestions (10% of feed)
                batch.append(.userSuggestions(createOptimizedUsers()))
            default:
                break
            }
        }
        
        return batch
    }
    
    private func createOptimizedFeedItem(index: Int) -> FeedItem {
        // Create lightweight feed items with lazy image loading
        return FeedItem(
            user: FeedUser(
                username: "user\(index)",
                name: "User \(index)",
                avatarURL: "https://picsum.photos/100/100?random=\(index)",
                isVerified: index % 5 == 0,
                followerCount: Int.random(in: 100...10000)
            ),
            mediaURL: "https://picsum.photos/400/600?random=\(index + 1000)",
            description: "Optimized content \(index) with efficient loading",
            tags: ["tag\(index)", "performance"],
            timeAgo: "\(Int.random(in: 1...24))h",
            likesCount: Int.random(in: 10...1000),
            commentsCount: Int.random(in: 0...100),
            sharesCount: Int.random(in: 0...50),
            type: .shortVideo
        )
    }
    
    private func createOptimizedCourses() -> [Course] {
        return (1...5).map { index in
            Course(
                title: "Performance Course \(index)",
                instructor: "Expert \(index)",
                duration: "30 min",
                difficulty: "Intermediate",
                rating: Double.random(in: 4.0...5.0),
                imageURL: "https://picsum.photos/300/200?random=course\(index)",
                description: "Optimized course content"
            )
        }
    }
    
    private func createOptimizedUsers() -> [SuggestedUser] {
        return (1...4).map { index in
            SuggestedUser(
                username: "suggested\(index)",
                name: "Suggested User \(index)",
                avatarURL: "https://picsum.photos/80/80?random=user\(index)",
                isVerified: index % 3 == 0,
                followerCount: Int.random(in: 500...50000),
                specialty: "Performance Expert",
                mutualConnections: Int.random(in: 1...10)
            )
        }
    }
}

/// Optimized Course Manager for efficient learning content delivery
@MainActor
class OptimizedCourseManager: OptimizedViewModel {
    @Published var chapters: [LyoCourseChapter] = []
    @Published var currentChapterIndex = 0
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    private var preloadedChapters: [LyoCourseChapter] = []
    
    init() {
        setupMemoryWarningObserver()
    }
    
    // MARK: - OptimizedViewModel Protocol
    
    func cleanup() {
        cancellables.removeAll()
        preloadedChapters.removeAll()
    }
    
    func preload() {
        Task {
            await preloadAdjacentChapters()
        }
    }
    
    func handleMemoryWarning() {
        // Keep only current chapter and adjacent chapters
        let currentIndex = currentChapterIndex
        let range = max(0, currentIndex - 1)...min(chapters.count - 1, currentIndex + 1)
        
        let essentialChapters = Array(chapters[range])
        chapters = essentialChapters
        currentChapterIndex = min(currentChapterIndex, essentialChapters.count - 1)
        
        preloadedChapters.removeAll()
    }
    
    // MARK: - Course Management
    
    func loadCourse(topic: String) async {
        isLoading = true
        defer { isLoading = false }
        
        PerformanceOptimizer.PerformanceMetrics.shared.startTimer(for: "course_load")
        
        // Generate optimized course content
        chapters = await generateOptimizedCourseContent(for: topic)
        currentChapterIndex = 0
        
        PerformanceOptimizer.PerformanceMetrics.shared.endTimer(for: "course_load")
        
        // Preload adjacent chapters
        await preloadAdjacentChapters()
    }
    
    func moveToChapter(_ index: Int) {
        guard index >= 0 && index < chapters.count else { return }
        currentChapterIndex = index
        
        Task {
            await preloadAdjacentChapters()
        }
    }
    
    func nextChapter() {
        guard currentChapterIndex < chapters.count - 1 else { return }
        currentChapterIndex += 1
        
        Task {
            await preloadAdjacentChapters()
        }
    }
    
    func previousChapter() {
        guard currentChapterIndex > 0 else { return }
        currentChapterIndex -= 1
        
        Task {
            await preloadAdjacentChapters()
        }
    }
    
    var currentChapter: LyoCourseChapter? {
        guard currentChapterIndex < chapters.count else { return nil }
        return chapters[currentChapterIndex]
    }
    
    var progress: Double {
        guard !chapters.isEmpty else { return 0 }
        return Double(currentChapterIndex + 1) / Double(chapters.count)
    }
    
    private func preloadAdjacentChapters() async {
        BackgroundTaskManager.shared.schedule(id: "preload_chapters") {
            // Preload next and previous chapters for smooth navigation
            let indices = [
                self.currentChapterIndex - 1,
                self.currentChapterIndex + 1
            ].filter { $0 >= 0 && $0 < self.chapters.count }
            
            for index in indices {
                // Preload chapter resources if needed
                await self.preloadChapterResources(at: index)
            }
        }
    }
    
    private func preloadChapterResources(at index: Int) async {
        guard index < chapters.count else { return }
        
        let chapter = chapters[index]
        
        // Preload any images or resources in the chapter content
        // This is where you'd preload chapter-specific resources
        
        #if DEBUG
        print("📚 Preloaded resources for chapter: \(chapter.title)")
        #endif
    }
    
    private func generateOptimizedCourseContent(for topic: String) async -> [LyoCourseChapter] {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let chapters = generateCourseContent(for: topic)
                continuation.resume(returning: chapters)
            }
        }
    }
}

/// Optimized AI Chat Manager for efficient conversation handling
@MainActor
class OptimizedAIChatManager: OptimizedViewModel {
    @Published var messages: [ChatMessage] = []
    @Published var isThinking = false
    @Published var currentResponse = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var responseTask: Task<Void, Never>?
    private let maxMessages = 50 // Limit chat history for memory efficiency
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp: Date
    }
    
    init() {
        setupMemoryWarningObserver()
    }
    
    // MARK: - OptimizedViewModel Protocol
    
    func cleanup() {
        responseTask?.cancel()
        cancellables.removeAll()
    }
    
    func preload() {
        // Preload AI response templates or models if needed
    }
    
    func handleMemoryWarning() {
        // Keep only recent messages
        if messages.count > 20 {
            messages.removeFirst(messages.count - 20)
        }
    }
    
    // MARK: - Chat Management
    
    func sendMessage(_ content: String, chapter: LyoCourseChapter) {
        let userMessage = ChatMessage(
            content: content,
            isUser: true,
            timestamp: Date()
        )
        
        messages.append(userMessage)
        
        // Trim messages if needed
        if messages.count > maxMessages {
            messages.removeFirst(messages.count - maxMessages)
        }
        
        generateAIResponse(for: content, chapter: chapter)
    }
    
    private func generateAIResponse(for userMessage: String, chapter: LyoCourseChapter) {
        responseTask?.cancel()
        
        isThinking = true
        currentResponse = ""
        
        responseTask = Task {
            await simulateAIThinking()
            
            let response = await generateContextualResponse(
                userMessage: userMessage,
                chapter: chapter
            )
            
            await MainActor.run {
                isThinking = false
                
                let aiMessage = ChatMessage(
                    content: response,
                    isUser: false,
                    timestamp: Date()
                )
                
                messages.append(aiMessage)
                
                // Trim messages if needed
                if messages.count > maxMessages {
                    messages.removeFirst(messages.count - maxMessages)
                }
            }
        }
    }
    
    private func simulateAIThinking() async {
        // Simulate realistic AI thinking time
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))
    }
    
    private func generateContextualResponse(userMessage: String, chapter: LyoCourseChapter) async -> String {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let responses = [
                    "Great question about \(chapter.title)! Let me explain the key concepts...",
                    "In the context of \(chapter.title), this relates to the core principles we're exploring.",
                    "That's an insightful observation! Here's how it connects to what we're learning...",
                    "Perfect timing for this question! Let me break down the fundamentals for you..."
                ]
                
                let response = responses.randomElement() ?? "I'm here to help you understand this concept better!"
                continuation.resume(returning: response)
            }
        }
    }
}

// MARK: - Optimized Profile Manager
@MainActor
class OptimizedProfileManager: ObservableObject, OptimizedViewModelProtocol {
    @Published var userProfile: User?
    @Published var userPosts: [Post] = []
    @Published var userStats: UserStats?
    @Published var isLoading = false
    @Published var error: Error?
    
    private var isPreloaded = false
    private let backgroundTaskManager = BackgroundTaskManager.shared
    private let imageLoader = AsyncImageLoader.shared
    
    // Performance tracking
    var loadTime: TimeInterval = 0
    var memoryUsage: UInt64 = 0
    
    func preload() async {
        guard !isPreloaded else { return }
        
        let startTime = Date()
        defer { loadTime = Date().timeIntervalSince(startTime) }
        
        await backgroundTaskManager.performBackgroundTask { [weak self] in
            await self?.loadProfileData()
        }
        
        isPreloaded = true
    }
    
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadProfileData()
    }
    
    func cleanup() {
        userPosts.removeAll()
        userStats = nil
        error = nil
        isPreloaded = false
    }
    
    private func loadProfileData() async {
        do {
            // Simulate API calls with proper error handling
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                self.userProfile = User.sampleUsers.first
                self.userPosts = Array(Post.samplePosts.prefix(10))
                self.userStats = UserStats(
                    postsCount: 24,
                    followersCount: 1250,
                    followingCount: 340,
                    likesCount: 5680
                )
            }
            
            // Preload post images
            await preloadImages()
            
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    private func preloadImages() async {
        let imageUrls = userPosts.compactMap { URL(string: $0.imageURL ?? "") }
        await withTaskGroup(of: Void.self) { group in
            for url in imageUrls.prefix(5) { // Limit concurrent loads
                group.addTask {
                    _ = await self.imageLoader.loadImage(from: url)
                }
            }
        }
    }
    
    func loadMorePosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await backgroundTaskManager.performBackgroundTask { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            await MainActor.run {
                let newPosts = Array(Post.samplePosts.suffix(5))
                self?.userPosts.append(contentsOf: newPosts)
            }
        }
    }
}

// MARK: - Optimized Discover Manager
@MainActor
class OptimizedDiscoverManager: ObservableObject, OptimizedViewModelProtocol {
    @Published var discoveryPosts: [Post] = []
    @Published var trendingPosts: [Post] = []
    @Published var suggestedUsers: [User] = []
    @Published var searchResults: [Post] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var error: Error?
    
    private var isPreloaded = false
    private let backgroundTaskManager = BackgroundTaskManager.shared
    private let imageLoader = AsyncImageLoader.shared
    private var searchTask: Task<Void, Never>?
    
    // Performance tracking
    var loadTime: TimeInterval = 0
    var memoryUsage: UInt64 = 0
    
    func preload() async {
        guard !isPreloaded else { return }
        
        let startTime = Date()
        defer { loadTime = Date().timeIntervalSince(startTime) }
        
        await backgroundTaskManager.performBackgroundTask { [weak self] in
            await self?.loadDiscoveryContent()
        }
        
        isPreloaded = true
    }
    
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        await loadDiscoveryContent()
    }
    
    func cleanup() {
        discoveryPosts.removeAll()
        trendingPosts.removeAll()
        suggestedUsers.removeAll()
        searchResults.removeAll()
        searchTask?.cancel()
        error = nil
        isPreloaded = false
    }
    
    private func loadDiscoveryContent() async {
        do {
            // Simulate API calls
            try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            
            await MainActor.run {
                self.discoveryPosts = Array(Post.samplePosts.shuffled().prefix(20))
                self.trendingPosts = Array(Post.samplePosts.prefix(5))
                self.suggestedUsers = Array(User.sampleUsers.prefix(4))
            }
            
            // Preload trending content images
            await preloadTrendingImages()
            
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    private func preloadTrendingImages() async {
        let imageUrls = trendingPosts.compactMap { URL(string: $0.imageURL ?? "") }
        await withTaskGroup(of: Void.self) { group in
            for url in imageUrls {
                group.addTask {
                    _ = await self.imageLoader.loadImage(from: url)
                }
            }
        }
    }
    
    func search(query: String) async {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.isEmpty else {
            await MainActor.run {
                self.searchResults.removeAll()
                self.isSearching = false
            }
            return
        }
        
        searchTask = Task { [weak self] in
            await MainActor.run {
                self?.isSearching = true
            }
            
            // Debounce search
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            guard !Task.isCancelled else { return }
            
            await self?.performSearch(query: query)
        }
        
        await searchTask?.value
    }
    
    private func performSearch(query: String) async {
        do {
            let searchStartTime = Date()
            // Simulate search API call
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                // Filter posts based on query
                self.searchResults = Post.samplePosts.filter { post in
                    post.content.localizedCaseInsensitiveContains(query) ||
                    post.author.fullName.localizedCaseInsensitiveContains(query)
                }
                self.isSearching = false
                
                // Analytics: Track search performance
                let searchTime = Date().timeIntervalSince(searchStartTime)
                AnalyticsManager.shared.trackEvent(.search(
                    query: query,
                    resultCount: self.searchResults.count,
                    searchTime: searchTime
                ))
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                self.isSearching = false
            }
        }
    }
    
    func loadMoreDiscoveryPosts() async {
        guard !isLoading else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        await backgroundTaskManager.performBackgroundTask { [weak self] in
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            await MainActor.run {
                let newPosts = Array(Post.samplePosts.shuffled().prefix(10))
                self?.discoveryPosts.append(contentsOf: newPosts)
            }
        }
    }
    
    func filterByCategory(_ category: String) async {
        await backgroundTaskManager.performBackgroundTask { [weak self] in
            await MainActor.run {
                if category == "All" {
                    self?.discoveryPosts = Array(Post.samplePosts.shuffled().prefix(20))
                } else {
                    // Filter by category (simplified for demo)
                    self?.discoveryPosts = Array(Post.samplePosts.shuffled().prefix(15))
                }
                
                // Analytics: Track category filter
                AnalyticsManager.shared.trackEvent(.categoryFilter(
                    category: category,
                    resultCount: self?.discoveryPosts.count ?? 0
                ))
            }
        }
    }
}

// MARK: - User Stats Model
struct UserStats {
    let postsCount: Int
    let followersCount: Int
    let followingCount: Int
    let likesCount: Int
}

// MARK: - Memory-Efficient Extensions

extension Array {
    /// Safely removes elements from the beginning while maintaining performance
    mutating func removeFirstEfficiently(_ count: Int) {
        guard count > 0 && count < self.count else { return }
        
        let newArray = Array(self.dropFirst(count))
        self = newArray
    }
    
    /// Get elements in a range safely
    func safeElements(in range: Range<Int>) -> ArraySlice<Element> {
        let safeStart = max(0, range.lowerBound)
        let safeEnd = min(self.count, range.upperBound)
        guard safeStart < safeEnd else { return ArraySlice([]) }
        
        return self[safeStart..<safeEnd]
    }
}
