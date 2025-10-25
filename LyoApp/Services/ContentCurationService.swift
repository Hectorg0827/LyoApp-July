import Foundation
import SwiftUI

// MARK: - Content Curation Service
/// Real backend integration for content curation (replaces CurationEngine mock data)

@MainActor
final class ContentCurationService: ObservableObject {
    static let shared = ContentCurationService()
    
    @Published var isLoading = false
    @Published var error: String?
    @Published var cachedContent: [String: [ContentCard]] = [:] // topic -> cards cache
    
    private let apiService = ClassroomAPIService.shared
    private let cacheExpiration: TimeInterval = 3600 // 1 hour cache
    private var cacheTimestamps: [String: Date] = [:]
    
    private init() {}
    
    // MARK: - Public API
    
    /// Fetch curated content from backend with intelligent caching
    func fetchCuratedContent(
        topic: String,
        level: LearningLevel = .beginner,
        types: [CardKind] = CardKind.allCases,
        userSignals: UserSignals = UserSignals(),
        forceRefresh: Bool = false
    ) async throws -> [ContentCard] {
        
        let cacheKey = "\(topic)-\(level.rawValue)"
        
        // Check cache first (unless force refresh)
        if !forceRefresh, let cached = getCachedContent(for: cacheKey) {
            print("📦 [ContentCuration] Using cached content for '\(topic)'")
            return filterAndRank(cached, types: types, userSignals: userSignals)
        }
        
        isLoading = true
        error = nil
        
        do {
            print("🔄 [ContentCuration] Fetching curated content from backend...")
            
            // Call real backend API
            let cards = try await apiService.curateContent(
                topic: topic,
                level: level,
                preferences: .balanced, // Can be customized
                count: 20
            )
            
            // Cache the results
            cacheContent(cards, for: cacheKey)
            
            isLoading = false
            
            print("✅ [ContentCuration] Fetched \(cards.count) curated resources")
            
            // Filter and rank based on user signals
            return filterAndRank(cards, types: types, userSignals: userSignals)
            
        } catch {
            isLoading = false
            self.error = error.localizedDescription
            print("❌ [ContentCuration] Failed to fetch content: \(error.localizedDescription)")
            
            // Fallback to mock data if backend fails
            print("⚠️ [ContentCuration] Using fallback mock data")
            return generateFallbackContent(topic: topic, level: level, types: types)
        }
    }
    
    /// Refresh content for a topic (bypass cache)
    func refreshContent(
        topic: String,
        level: LearningLevel = .beginner,
        types: [CardKind] = CardKind.allCases,
        userSignals: UserSignals = UserSignals()
    ) async throws -> [ContentCard] {
        return try await fetchCuratedContent(
            topic: topic,
            level: level,
            types: types,
            userSignals: userSignals,
            forceRefresh: true
        )
    }
    
    /// Clear all cached content
    func clearCache() {
        cachedContent.removeAll()
        cacheTimestamps.removeAll()
        print("🗑️ [ContentCuration] Cache cleared")
    }
    
    /// Clear expired cache entries
    func clearExpiredCache() {
        let now = Date()
        var expiredKeys: [String] = []
        
        for (key, timestamp) in cacheTimestamps {
            if now.timeIntervalSince(timestamp) > cacheExpiration {
                expiredKeys.append(key)
            }
        }
        
        for key in expiredKeys {
            cachedContent.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
        
        if !expiredKeys.isEmpty {
            print("🗑️ [ContentCuration] Cleared \(expiredKeys.count) expired cache entries")
        }
    }
    
    // MARK: - Cache Management
    
    private func getCachedContent(for key: String) -> [ContentCard]? {
        guard let cards = cachedContent[key],
              let timestamp = cacheTimestamps[key] else {
            return nil
        }
        
        // Check if cache is still valid
        let age = Date().timeIntervalSince(timestamp)
        if age > cacheExpiration {
            // Cache expired
            cachedContent.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
            return nil
        }
        
        return cards
    }
    
    private func cacheContent(_ cards: [ContentCard], for key: String) {
        cachedContent[key] = cards
        cacheTimestamps[key] = Date()
    }
    
    // MARK: - Content Ranking & Filtering
    
    private func filterAndRank(
        _ cards: [ContentCard],
        types: [CardKind],
        userSignals: UserSignals
    ) -> [ContentCard] {
        
        // Filter by requested types
        let filtered = cards.filter { types.contains($0.kind) }
        
        // Score and rank each card
        let scored = filtered.map { card -> (card: ContentCard, score: Double) in
            let score = calculateScore(for: card, signals: userSignals)
            return (card, score)
        }
        
        // Sort by score (highest first)
        let sorted = scored.sorted { $0.score > $1.score }
        
        // Return just the cards
        return sorted.map { $0.card }
    }
    
    private func calculateScore(for card: ContentCard, signals: UserSignals) -> Double {
        var score: Double = card.relevanceScore // Start with backend relevance
        
        // User preference bonuses
        if signals.savedCardKinds.contains(card.kind) {
            score += 0.2 // Boost saved types
        }
        
        if signals.prefersVideo && card.kind == .video {
            score += 0.15
        }
        
        if signals.prefersText && (card.kind == .article || card.kind == .ebook) {
            score += 0.15
        }
        
        // Duration matching
        if card.estMinutes <= signals.prefersShortMinutes {
            score += 0.1 // Perfect duration match
        } else if card.estMinutes > signals.prefersShortMinutes * 2 {
            score -= 0.1 // Too long
        }
        
        // Struggling user gets shorter content
        if signals.struggling && card.estMinutes <= 15 {
            score += 0.15
        }
        
        // Fast learner gets longer content
        if signals.speedMultiplier > 1.2 && card.estMinutes >= 30 {
            score += 0.1
        }
        
        return min(1.0, max(0.0, score))
    }
    
    // MARK: - Fallback Content Generation
    
    private func generateFallbackContent(
        topic: String,
        level: LearningLevel,
        types: [CardKind]
    ) -> [ContentCard] {
        
        var cards: [ContentCard] = []
        
        // Generate video content
        if types.contains(.video) {
            cards.append(ContentCard(
                kind: .video,
                title: "\(topic): Complete \(level.displayName) Tutorial",
                source: "YouTube - Khan Academy",
                url: URL(string: "https://youtube.com")!,
                estMinutes: level == .beginner ? 12 : 20,
                tags: [topic.lowercased(), "tutorial", level.rawValue],
                summary: "Comprehensive \(level.displayName)-level introduction to \(topic) with clear examples.",
                citation: "Khan Academy. (2024). \(topic) Tutorial. YouTube.",
                thumbnailURL: URL(string: "https://picsum.photos/320/180"),
                relevanceScore: 0.9
            ))
        }
        
        // Generate article content
        if types.contains(.article) {
            cards.append(ContentCard(
                kind: .article,
                title: "Understanding \(topic): A Visual Guide",
                source: "Better Explained",
                url: URL(string: "https://betterexplained.com")!,
                estMinutes: 8,
                tags: [topic.lowercased(), "visual", "guide"],
                summary: "Build intuition for \(topic) through visuals and real-world examples.",
                citation: "Better Explained. Understanding \(topic). betterexplained.com",
                thumbnailURL: URL(string: "https://picsum.photos/321/180"),
                relevanceScore: 0.8
            ))
        }
        
        // Generate exercise content
        if types.contains(.exercise) {
            cards.append(ContentCard(
                kind: .exercise,
                title: "\(topic) Practice Problems",
                source: "Brilliant.org",
                url: URL(string: "https://brilliant.org")!,
                estMinutes: 20,
                tags: [topic.lowercased(), "practice", "interactive"],
                summary: "Interactive practice with instant feedback to solidify understanding.",
                citation: "Brilliant. (2024). \(topic) Practice. brilliant.org",
                thumbnailURL: URL(string: "https://picsum.photos/322/180"),
                relevanceScore: 0.85
            ))
        }
        
        // Generate ebook content
        if types.contains(.ebook) {
            cards.append(ContentCard(
                kind: .ebook,
                title: "The Essentials of \(topic)",
                source: "OpenStax",
                url: URL(string: "https://openstax.org")!,
                estMinutes: level == .beginner ? 120 : 180,
                tags: [topic.lowercased(), "textbook", "comprehensive"],
                summary: "Free textbook covering \(topic) from foundations to applications.",
                citation: "OpenStax. (2024). The Essentials of \(topic). Rice University.",
                thumbnailURL: URL(string: "https://picsum.photos/323/400"),
                relevanceScore: 0.85
            ))
        }
        
        print("⚠️ [ContentCuration] Generated \(cards.count) fallback cards")
        return cards
    }
}

// MARK: - User Signals Model (for personalization)

struct UserSignals {
    var savedCardKinds: Set<CardKind> = []
    var prefersVideo: Bool = false
    var prefersText: Bool = false
    var prefersShortMinutes: Int = 20
    var struggling: Bool = false
    var speedMultiplier: Double = 1.0
    var completedTopics: Set<String> = []
    var currentLevel: LearningLevel = .beginner
}

// MARK: - Learning Level Extension

extension LearningLevel {
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        }
    }
}

// MARK: - CardKind Extension

extension CardKind: CaseIterable {
    public static var allCases: [CardKind] {
        return [.video, .ebook, .article, .exercise, .infographic, .dataset, .podcast]
    }
}
