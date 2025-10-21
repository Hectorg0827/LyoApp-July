import SwiftData
import Foundation

// MARK: - SwiftData Entity for LearningResource
/// SwiftData persistence entity for LearningResource
@Model
final class LearningResourceEntityV2 {
    @Attribute(.unique) var id: String
    var title: String
    var resourceDescription: String
    var category: String?
    var difficulty: String?
    var duration: Int?
    var thumbnailUrl: String?
    var imageUrl: String?
    var url: String?
    var provider: String?
    var providerName: String?
    var providerUrl: String?
    var enrolledCount: Int?
    var isEnrolled: Bool?
    var reviews: Int?
    var updatedAt: String?
    var createdAt: String?
    var authorCreator: String?
    var estimatedDuration: String?
    var rating: Double?
    var difficultyLevelRaw: String?
    var contentTypeRaw: String
    var resourcePlatformRaw: String?
    var tagsData: Data?
    var isBookmarked: Bool
    var progress: Double?
    var publishedDate: Date?
    
    init(from resource: LearningResource) {
        self.id = resource.id
        self.title = resource.title
        self.resourceDescription = resource.description
        self.category = resource.category
        self.difficulty = resource.difficulty
        self.duration = resource.duration
        self.thumbnailUrl = resource.thumbnailUrl
        self.imageUrl = resource.imageUrl
        self.url = resource.url
        self.provider = resource.provider
        self.providerName = resource.providerName
        self.providerUrl = resource.providerUrl
        self.enrolledCount = resource.enrolledCount
        self.isEnrolled = resource.isEnrolled
        self.reviews = resource.reviews
        self.updatedAt = resource.updatedAt
        self.createdAt = resource.createdAt
        self.authorCreator = resource.authorCreator
        self.estimatedDuration = resource.estimatedDuration
        self.rating = resource.rating
        self.difficultyLevelRaw = resource.difficultyLevel?.rawValue
        self.contentTypeRaw = resource.contentType.rawValue
        self.resourcePlatformRaw = resource.resourcePlatform?.rawValue
        self.tagsData = try? JSONEncoder().encode(resource.tags)
        self.isBookmarked = resource.isBookmarked
        self.progress = resource.progress
        self.publishedDate = resource.publishedDate
    }
    
    func toDomain() -> LearningResource {
        let tags = try? JSONDecoder().decode([String]?.self, from: tagsData ?? Data())
        
        return LearningResource(
            id: id,
            title: title,
            description: resourceDescription,
            category: category,
            difficulty: difficulty,
            duration: duration,
            thumbnailUrl: thumbnailUrl,
            imageUrl: imageUrl,
            url: url,
            provider: provider,
            providerName: providerName,
            providerUrl: providerUrl,
            enrolledCount: enrolledCount,
            isEnrolled: isEnrolled,
            reviews: reviews,
            updatedAt: updatedAt,
            createdAt: createdAt,
            authorCreator: authorCreator,
            estimatedDuration: estimatedDuration,
            rating: rating,
            difficultyLevel: difficultyLevelRaw.flatMap(LearningResource.DifficultyLevel.init),
            contentType: LearningResource.ContentType(rawValue: contentTypeRaw) ?? .article,
            resourcePlatform: resourcePlatformRaw.flatMap(LearningResource.ResourcePlatform.init),
            tags: tags ?? nil,
            isBookmarked: isBookmarked,
            progress: progress,
            publishedDate: publishedDate
        )
    }
}
