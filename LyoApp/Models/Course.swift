import Foundation

// MARK: - Canonical Course Model
struct Course: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let instructor: String
    let description: String
    let thumbnailURL: String
    let category: String
    let duration: String
    let rating: Double
    var lessons: [Lesson]
    var isCompleted: Bool
    var progress: Double

    // CodingKeys for custom key mapping
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case instructor
        case description
        case thumbnailURL = "thumbnail_url"
        case category
        case duration
        case rating
        case lessons
        case isCompleted = "is_completed"
        case progress
    }

    // Initializer with default values
    init(
        id: UUID = UUID(),
        title: String,
        instructor: String,
        description: String,
        thumbnailURL: String,
        category: String,
        duration: String,
        rating: Double,
        lessons: [Lesson] = [],
        isCompleted: Bool = false,
        progress: Double = 0.0
    ) {
        self.id = id
        self.title = title
        self.instructor = instructor
        self.description = description
        self.thumbnailURL = thumbnailURL
        self.category = category
        self.duration = duration
        self.rating = rating
        self.lessons = lessons
        self.isCompleted = isCompleted
        self.progress = progress
    }
}

// MARK: - Canonical Lesson Model
struct Lesson: Identifiable, Codable, Hashable {
    let id: UUID
    let title: String
    let duration: String
    var isCompleted: Bool

    // CodingKeys for custom key mapping
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case duration
        case isCompleted = "is_completed"
    }

    // Initializer with default values
    init(
        id: UUID = UUID(),
        title: String,
        duration: String,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.isCompleted = isCompleted
    }
}
