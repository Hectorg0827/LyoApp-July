import Foundation
import SwiftUI

// MARK: - Educational Content Models
struct EducationalContentItem: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: ContentType
    let url: String
    let thumbnailURL: String?
    let duration: TimeInterval?
    let rating: Double?
    let provider: ContentProvider
    let tags: [String]
    let difficulty: ContentDifficulty
    let createdAt: Date
    
    enum ContentType: String, CaseIterable, Codable {
        case video = "video"
        case article = "article"
        case podcast = "podcast"
        case course = "course"
        case ebook = "ebook"
        case interactive = "interactive"
    }
    
    enum ContentProvider: String, CaseIterable, Codable {
        case youtube = "youtube"
        case coursera = "coursera"
        case edx = "edx"
        case khanAcademy = "khan_academy"
        case udemy = "udemy"
        case mit = "mit"
        case harvard = "harvard"
        case stanford = "stanford"
        case googleBooks = "google_books"
        case podcast = "podcast"
        case custom = "custom"
    }
    
    enum ContentDifficulty: String, CaseIterable, Codable {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case expert = "expert"
    }
}

// MARK: - Educational Content Manager
@MainActor
class EducationalContentManager: ObservableObject {
    @Published var isLoading = false
    @Published var error: Error?
    @Published var content: [EducationalContentItem] = []
    @Published var categories: [String] = []
    
    private let networkManager = NetworkManager.shared
    
    init() {
        loadMockContent()
    }
    
    // MARK: - Public Methods
    func loadContent(for category: String? = nil) {
        isLoading = true
        error = nil
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isLoading = false
            if category != nil {
                self?.content = self?.content.filter { $0.tags.contains(category!) } ?? []
            }
        }
    }
    
    func searchContent(_ query: String) -> [EducationalContentItem] {
        return content.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            item.description.localizedCaseInsensitiveContains(query) ||
            item.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func getContentByType(_ type: EducationalContentItem.ContentType) -> [EducationalContentItem] {
        return content.filter { $0.type == type }
    }
    
    func getContentByProvider(_ provider: EducationalContentItem.ContentProvider) -> [EducationalContentItem] {
        return content.filter { $0.provider == provider }
    }
    
    func getContentByDifficulty(_ difficulty: EducationalContentItem.ContentDifficulty) -> [EducationalContentItem] {
        return content.filter { $0.difficulty == difficulty }
    }
    
    // MARK: - Private Methods
    private func loadMockContent() {
        content = [
            EducationalContentItem(
                id: "1",
                title: "Introduction to SwiftUI",
                description: "Learn the basics of SwiftUI with this comprehensive tutorial",
                type: .video,
                url: "https://example.com/swiftui-intro",
                thumbnailURL: "https://example.com/thumb1.jpg",
                duration: 3600,
                rating: 4.8,
                provider: .youtube,
                tags: ["SwiftUI", "iOS", "Programming"],
                difficulty: .beginner,
                createdAt: Date()
            ),
            EducationalContentItem(
                id: "2",
                title: "Advanced iOS Architecture",
                description: "Deep dive into iOS app architecture patterns",
                type: .course,
                url: "https://example.com/ios-architecture",
                thumbnailURL: "https://example.com/thumb2.jpg",
                duration: 7200,
                rating: 4.9,
                provider: .coursera,
                tags: ["iOS", "Architecture", "Advanced"],
                difficulty: .advanced,
                createdAt: Date()
            ),
            EducationalContentItem(
                id: "3",
                title: "Machine Learning Fundamentals",
                description: "Introduction to machine learning concepts",
                type: .article,
                url: "https://example.com/ml-fundamentals",
                thumbnailURL: "https://example.com/thumb3.jpg",
                duration: nil,
                rating: 4.7,
                provider: .mit,
                tags: ["Machine Learning", "AI", "Programming"],
                difficulty: .intermediate,
                createdAt: Date()
            )
        ]
        
        categories = Array(Set(content.flatMap { $0.tags })).sorted()
    }
}
