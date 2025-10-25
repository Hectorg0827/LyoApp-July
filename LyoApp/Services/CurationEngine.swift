import Foundation
import SwiftUI

// MARK: - Curation Engine

/// Responsible for fetching, ranking, and surfacing contextual content cards
@MainActor
final class CurationEngine: ObservableObject {
    static let shared = CurationEngine()
    
    @Published var availableCards: [ContentCard] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private init() {}
    
    // MARK: - Card Ranking Algorithm
    
    /// Rank and score a card based on objective, user signals, and quality
    func score(
        card: ContentCard,
        objective: LearningObjective,
        userSignals: UserSignals
    ) -> Double {
        var score: Double = 0.0
        
        // 1. Relevance to objective (40% weight)
        let relevance = calculateRelevance(card: card, objective: objective)
        score += relevance * 0.4
        
        // 2. User preference match (30% weight)
        let preferenceMatch = calculatePreferenceMatch(card: card, signals: userSignals)
        score += preferenceMatch * 0.3
        
        // 3. Quality & credibility (20% weight)
        score += card.relevanceScore * 0.2
        
        // 4. Duration match (10% weight)
        let durationMatch = calculateDurationMatch(card: card, signals: userSignals)
        score += durationMatch * 0.1
        
        // Bonuses
        if userSignals.struggling && card.estMinutes <= 15 {
            score += 0.15 // Boost shorter content when struggling
        }
        
        if userSignals.speedMultiplier > 1.2 && card.estMinutes >= 30 {
            score += 0.1 // Boost longer-form content for fast learners
        }
        
        return min(1.0, max(0.0, score))
    }
    
    private func calculateRelevance(card: ContentCard, objective: LearningObjective) -> Double {
        var score: Double = 0.0
        
        // Check if objective keyword appears in title
        if card.title.lowercased().contains(objective.keyword.lowercased()) {
            score += 0.5
        }
        
        // Check if objective keyword appears in summary
        if card.summary.lowercased().contains(objective.keyword.lowercased()) {
            score += 0.3
        }
        
        // Check tag overlap
        let objectiveTags = Set(objective.tags.map { $0.lowercased() })
        let cardTags = Set(card.tags.map { $0.lowercased() })
        let tagOverlap = objectiveTags.intersection(cardTags).count
        
        if !objectiveTags.isEmpty {
            score += Double(tagOverlap) / Double(objectiveTags.count) * 0.2
        }
        
        return min(1.0, score)
    }
    
    private func calculatePreferenceMatch(card: ContentCard, signals: UserSignals) -> Double {
        var score: Double = 0.5 // Baseline
        
        // Check if card kind is in user's saved/preferred kinds
        if signals.savedCardKinds.contains(card.kind) {
            score += 0.3
        }
        
        // Video preference
        if signals.prefersVideo && card.kind == .video {
            score += 0.2
        }
        
        // Text preference
        if signals.prefersText && (card.kind == .article || card.kind == .ebook) {
            score += 0.2
        }
        
        return min(1.0, score)
    }
    
    private func calculateDurationMatch(card: ContentCard, signals: UserSignals) -> Double {
        let preferredMax = signals.prefersShortMinutes
        
        if card.estMinutes <= preferredMax {
            return 1.0
        } else if card.estMinutes <= preferredMax * 2 {
            return 0.7
        } else if card.estMinutes <= preferredMax * 3 {
            return 0.4
        } else {
            return 0.2
        }
    }
    
    // MARK: - Card Generation (Mock)
    
    /// Generate sample content cards for a given topic
    func generateSampleCards(for topic: String, count: Int = 15) -> [ContentCard] {
        var cards: [ContentCard] = []
        
        // Videos
        cards.append(ContentCard(
            kind: .video,
            title: "\(topic): Complete Beginner Tutorial",
            source: "YouTube - Khan Academy",
            url: URL(string: "https://youtube.com/example1")!,
            estMinutes: 12,
            tags: [topic.lowercased(), "tutorial", "beginner"],
            summary: "A comprehensive introduction to \(topic) covering fundamental concepts with clear examples and visual explanations.",
            citation: "Khan Academy. (2024). \(topic): Complete Beginner Tutorial. YouTube.",
            thumbnailURL: URL(string: "https://picsum.photos/320/180"),
            relevanceScore: 0.9
        ))
        
        cards.append(ContentCard(
            kind: .video,
            title: "Advanced \(topic) Techniques",
            source: "YouTube - MIT OpenCourseWare",
            url: URL(string: "https://youtube.com/example2")!,
            estMinutes: 45,
            tags: [topic.lowercased(), "advanced", "techniques"],
            summary: "Deep dive into advanced \(topic) concepts used in real-world applications. Requires prior knowledge.",
            citation: "MIT OpenCourseWare. (2024). Advanced \(topic) Techniques. YouTube.",
            thumbnailURL: URL(string: "https://picsum.photos/321/180"),
            relevanceScore: 0.75
        ))
        
        // eBooks
        cards.append(ContentCard(
            kind: .ebook,
            title: "The Essentials of \(topic)",
            source: "OpenStax",
            url: URL(string: "https://openstax.org/example")!,
            estMinutes: 180,
            tags: [topic.lowercased(), "textbook", "comprehensive"],
            summary: "Free, peer-reviewed textbook covering \(topic) from foundations to applications. Includes practice problems and solutions.",
            citation: "OpenStax. (2023). The Essentials of \(topic). Rice University.",
            thumbnailURL: URL(string: "https://picsum.photos/320/400"),
            relevanceScore: 0.85
        ))
        
        // Articles
        cards.append(ContentCard(
            kind: .article,
            title: "Understanding \(topic): A Visual Guide",
            source: "Better Explained",
            url: URL(string: "https://betterexplained.com/example")!,
            estMinutes: 8,
            tags: [topic.lowercased(), "visual", "intuition"],
            summary: "Build intuition for \(topic) through analogies, visuals, and real-world examples.",
            citation: "Better Explained. Understanding \(topic): A Visual Guide. betterexplained.com",
            thumbnailURL: URL(string: "https://picsum.photos/322/180"),
            relevanceScore: 0.8
        ))
        
        cards.append(ContentCard(
            kind: .article,
            title: "5-Minute Introduction to \(topic)",
            source: "Wikipedia",
            url: URL(string: "https://wikipedia.org/example")!,
            estMinutes: 5,
            tags: [topic.lowercased(), "quick", "overview"],
            summary: "Quick overview of \(topic) with key definitions and historical context. Great starting point.",
            citation: "Wikipedia contributors. (2024). \(topic). Wikipedia, The Free Encyclopedia.",
            thumbnailURL: URL(string: "https://picsum.photos/323/180"),
            relevanceScore: 0.7
        ))
        
        // Exercises
        cards.append(ContentCard(
            kind: .exercise,
            title: "\(topic) Practice Problems",
            source: "Brilliant.org",
            url: URL(string: "https://brilliant.org/example")!,
            estMinutes: 20,
            tags: [topic.lowercased(), "practice", "interactive"],
            summary: "Interactive practice problems with instant feedback. Work through real scenarios to solidify understanding.",
            citation: "Brilliant. (2024). \(topic) Practice Problems. brilliant.org",
            thumbnailURL: URL(string: "https://picsum.photos/324/180"),
            relevanceScore: 0.85
        ))
        
        cards.append(ContentCard(
            kind: .exercise,
            title: "Interactive \(topic) Simulator",
            source: "PhET Interactive Simulations",
            url: URL(string: "https://phet.colorado.edu/example")!,
            estMinutes: 15,
            tags: [topic.lowercased(), "interactive", "simulation"],
            summary: "Hands-on simulation to visualize and experiment with \(topic) concepts in real-time.",
            citation: "PhET Interactive Simulations. (2024). \(topic) Simulator. University of Colorado Boulder.",
            thumbnailURL: URL(string: "https://picsum.photos/328/180"),
            relevanceScore: 0.88
        ))
        
        // Infographics
        cards.append(ContentCard(
            kind: .infographic,
            title: "\(topic) Cheat Sheet",
            source: "Codecademy",
            url: URL(string: "https://codecademy.com/example")!,
            estMinutes: 3,
            tags: [topic.lowercased(), "cheatsheet", "reference"],
            summary: "One-page visual reference for all key \(topic) concepts. Perfect for quick review.",
            citation: "Codecademy. (2024). \(topic) Cheat Sheet. codecademy.com",
            thumbnailURL: URL(string: "https://picsum.photos/326/180"),
            relevanceScore: 0.65
        ))
        
        // Podcasts
        cards.append(ContentCard(
            kind: .podcast,
            title: "\(topic) Explained (Podcast)",
            source: "Spotify - RadioLab",
            url: URL(string: "https://spotify.com/example")!,
            estMinutes: 40,
            tags: [topic.lowercased(), "podcast", "audio"],
            summary: "Audio deep-dive into \(topic) with expert interviews and real-world stories.",
            citation: "RadioLab. (2024). \(topic) Explained. Spotify.",
            thumbnailURL: URL(string: "https://picsum.photos/327/180"),
            relevanceScore: 0.7
        ))
        
        // Datasets (for data-oriented topics)
        cards.append(ContentCard(
            kind: .dataset,
            title: "\(topic) Sample Dataset",
            source: "Kaggle",
            url: URL(string: "https://kaggle.com/example")!,
            estMinutes: 10,
            tags: [topic.lowercased(), "dataset", "data"],
            summary: "Real-world dataset for practicing \(topic) analysis. Includes documentation and starter notebooks.",
            citation: "Kaggle Community. (2024). \(topic) Sample Dataset. kaggle.com",
            thumbnailURL: URL(string: "https://picsum.photos/329/180"),
            relevanceScore: 0.6
        ))
        
        return Array(cards.prefix(count))
    }
    
    // MARK: - Context-Aware Card Surfacing
    
    /// Surface cards based on user state (struggling, speeding, etc.)
    func surfaceCards(
        for objective: LearningObjective,
        signals: UserSignals,
        availableCards: [ContentCard],
        context: CardContext
    ) -> [ContextualCard] {
        // Score all cards
        let scoredCards = availableCards.map { card -> (ContentCard, Double) in
            var score = self.score(card: card, objective: objective, userSignals: signals)
            
            // Adjust score based on context
            switch context {
            case .remedial:
                if card.estMinutes <= 15 {
                    score += 0.2
                }
                if card.kind == .video || card.kind == .exercise {
                    score += 0.15
                }
            case .deepDive:
                if card.estMinutes >= 30 {
                    score += 0.2
                }
                if card.kind == .ebook || card.kind == .article {
                    score += 0.1
                }
            case .practice:
                if card.kind == .exercise {
                    score += 0.3
                }
            case .introduction:
                if card.estMinutes < 15 || card.tags.contains(where: { $0.contains("beginner") }) {
                    score += 0.15
                }
            case .alternative, .assessment:
                break
            }
            
            return (card, min(1.0, max(0.0, score)))
        }
        
        // Sort by score
        let sortedCards = scoredCards.sorted { $0.1 > $1.1 }
        
        // Take top cards
        let topCards = sortedCards.prefix(5)
        
        // Create contextual cards
        return topCards.map { card, score in
            ContextualCard(
                card: card,
                context: context,
                reasonShown: generateReason(for: card, context: context, score: score)
            )
        }
    }
    
    private func generateReason(for card: ContentCard, context: CardContext, score: Double) -> String {
        switch context {
        case .introduction:
            return "Good starting point for learning the basics"
        case .remedial:
            return "Extra practice to reinforce this concept"
        case .deepDive:
            return "Ready to go deeper? This explores advanced topics"
        case .alternative:
            return "Another perspective that might click better"
        case .practice:
            return "Apply what you've learned with hands-on work"
        case .assessment:
            return "Check your understanding before moving forward"
        }
    }
    
    // MARK: - Live API Integration (Future)
    
    /// Fetch real cards from YouTube, Google Books, etc.
    func fetchRealCards(for topic: String) async throws -> [ContentCard] {
        isLoading = true
        defer { isLoading = false }
        
        // For now, return mock cards
        return generateSampleCards(for: topic)
        
        /*
        // Example integration (to be completed when services are ready)
        var cards: [ContentCard] = []
        
        // YouTube videos
        do {
            let videos = try await YouTubeEducationService.shared.searchEducational(query: topic, maxResults: 5)
            cards += videos.map { video in
                ContentCard(
                    kind: .video,
                    title: video.title,
                    source: "YouTube - \(video.channelTitle)",
                    url: URL(string: "https://youtube.com/watch?v=\(video.videoID)")!,
                    estMinutes: 15,
                    tags: [topic.lowercased(), "video"],
                    summary: video.description,
                    citation: "\(video.channelTitle). (\(video.publishedAt)). \(video.title). YouTube.",
                    thumbnailURL: URL(string: video.thumbnailURL),
                    relevanceScore: 0.7
                )
            }
        } catch {
            print("❌ [CurationEngine] YouTube fetch failed: \(error)")
        }
        
        // Google Books
        do {
            let books = try await GoogleBooksService.shared.search(query: topic, maxResults: 3)
            cards += books.map { book in
                ContentCard(
                    kind: .ebook,
                    title: book.title,
                    source: book.publisher,
                    url: URL(string: book.infoLink)!,
                    estMinutes: 120,
                    tags: [topic.lowercased(), "book"],
                    summary: book.description,
                    citation: "\(book.authors.joined(separator: ", ")). (\(book.publishedDate)). \(book.title). \(book.publisher).",
                    thumbnailURL: book.thumbnail.flatMap { URL(string: $0) },
                    relevanceScore: 0.8
                )
            }
        } catch {
            print("❌ [CurationEngine] Google Books fetch failed: \(error)")
        }
        
        return cards
        */
    }
}
