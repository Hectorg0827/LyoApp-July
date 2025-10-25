import Foundation
import SwiftData

/// SwiftData model for caching courses locally
/// This enables offline access and faster loading times
@Model
final class CachedCourse {
    @Attribute(.unique) var id: UUID
    var title: String
    var subtitle: String
    var courseDescription: String
    var category: String
    var difficulty: String
    var duration: String
    var instructor: String
    var rating: Double
    var enrollmentCount: Int
    var progress: Double
    var thumbnailURL: String?
    var createdAt: Date
    var lastAccessedAt: Date
    
    @Relationship(deleteRule: .cascade) var lessons: [CachedLesson]
    
    init(
        id: UUID,
        title: String,
        subtitle: String,
        courseDescription: String,
        category: String,
        difficulty: String,
        duration: String,
        instructor: String,
        rating: Double,
        enrollmentCount: Int,
        progress: Double,
        thumbnailURL: String?,
        lessons: [CachedLesson] = []
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.courseDescription = courseDescription
        self.category = category
        self.difficulty = difficulty
        self.duration = duration
        self.instructor = instructor
        self.rating = rating
        self.enrollmentCount = enrollmentCount
        self.progress = progress
        self.thumbnailURL = thumbnailURL
        self.createdAt = Date()
        self.lastAccessedAt = Date()
        self.lessons = lessons
    }
    
    /// Converts this cached course to the app's Course model
    func toCourse() -> Course {
        Course(
            id: id,
            title: title,
            subtitle: subtitle,
            description: courseDescription,
            thumbnailURL: thumbnailURL,
            category: CourseCategory(rawValue: category) ?? .technology,
            difficulty: CourseDifficulty(rawValue: difficulty) ?? .intermediate,
            duration: duration,
            rating: rating,
            enrollmentCount: enrollmentCount,
            instructor: instructor,
            lessons: lessons.map { $0.toLesson() },
            progress: progress
        )
    }
    
    /// Creates a CachedCourse from the app's Course model
    static func from(_ course: Course) -> CachedCourse {
        CachedCourse(
            id: course.id,
            title: course.title,
            subtitle: course.subtitle,
            courseDescription: course.description,
            category: course.category.rawValue,
            difficulty: course.difficulty.rawValue,
            duration: course.duration,
            instructor: course.instructor,
            rating: course.rating,
            enrollmentCount: course.enrollmentCount,
            progress: course.progress,
            thumbnailURL: course.thumbnailURL,
            lessons: course.lessons.map { CachedLesson.from($0) }
        )
    }
}

/// SwiftData model for caching lessons locally
@Model
final class CachedLesson {
    @Attribute(.unique) var id: UUID
    var title: String
    var duration: String
    var isCompleted: Bool
    var content: String
    var videoURL: String?
    var orderIndex: Int
    
    init(
        id: UUID,
        title: String,
        duration: String,
        isCompleted: Bool,
        content: String,
        videoURL: String?,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.duration = duration
        self.isCompleted = isCompleted
        self.content = content
        self.videoURL = videoURL
        self.orderIndex = orderIndex
    }
    
    /// Converts this cached lesson to the app's Lesson model
    func toLesson() -> Lesson {
        Lesson(
            id: id,
            title: title,
            duration: duration,
            isCompleted: isCompleted,
            content: content,
            videoURL: videoURL
        )
    }
    
    /// Creates a CachedLesson from the app's Lesson model
    static func from(_ lesson: Lesson) -> CachedLesson {
        CachedLesson(
            id: lesson.id,
            title: lesson.title,
            duration: lesson.duration,
            isCompleted: lesson.isCompleted,
            content: lesson.content,
            videoURL: lesson.videoURL
        )
    }
}

/// Service for managing course caching with SwiftData
@MainActor
class CourseCacheService {
    static let shared = CourseCacheService()
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    private init() {
        do {
            let schema = Schema([CachedCourse.self, CachedLesson.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = ModelContext(modelContainer)
            print("✅ CourseCacheService: SwiftData initialized successfully")
        } catch {
            fatalError("❌ CourseCacheService: Failed to initialize SwiftData: \(error)")
        }
    }
    
    // MARK: - Cache Operations
    
    /// Saves a course to the cache
    func cache(_ course: Course) {
        // Check if course already exists
        let fetchDescriptor = FetchDescriptor<CachedCourse>(predicate: #Predicate { $0.id == course.id })
        
        do {
            let existing = try modelContext.fetch(fetchDescriptor)
            
            // Delete existing if found
            for existingCourse in existing {
                modelContext.delete(existingCourse)
            }
            
            // Insert new cached course
            let cachedCourse = CachedCourse.from(course)
            modelContext.insert(cachedCourse)
            
            try modelContext.save()
            print("✅ CourseCacheService: Cached course '\(course.title)'")
        } catch {
            print("❌ CourseCacheService: Failed to cache course: \(error)")
        }
    }
    
    /// Retrieves a cached course by ID
    func getCourse(id: UUID) -> Course? {
        let fetchDescriptor = FetchDescriptor<CachedCourse>(predicate: #Predicate { $0.id == id })
        
        do {
            let courses = try modelContext.fetch(fetchDescriptor)
            if let cachedCourse = courses.first {
                // Update last accessed time
                cachedCourse.lastAccessedAt = Date()
                try modelContext.save()
                return cachedCourse.toCourse()
            }
        } catch {
            print("❌ CourseCacheService: Failed to fetch course: \(error)")
        }
        
        return nil
    }
    
    /// Retrieves all cached courses
    func getAllCourses() -> [Course] {
        let fetchDescriptor = FetchDescriptor<CachedCourse>(sortBy: [SortDescriptor(\.lastAccessedAt, order: .reverse)])
        
        do {
            let cachedCourses = try modelContext.fetch(fetchDescriptor)
            return cachedCourses.map { $0.toCourse() }
        } catch {
            print("❌ CourseCacheService: Failed to fetch all courses: \(error)")
            return []
        }
    }
    
    /// Clears all cached courses
    func clearAll() {
        do {
            try modelContext.delete(model: CachedCourse.self)
            try modelContext.save()
            print("✅ CourseCacheService: Cleared all cached courses")
        } catch {
            print("❌ CourseCacheService: Failed to clear cache: \(error)")
        }
    }
    
    /// Clears old cached courses (older than specified days)
    func clearOldCourses(olderThan days: Int = 30) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let fetchDescriptor = FetchDescriptor<CachedCourse>(predicate: #Predicate { $0.lastAccessedAt < cutoffDate })
        
        do {
            let oldCourses = try modelContext.fetch(fetchDescriptor)
            for course in oldCourses {
                modelContext.delete(course)
            }
            try modelContext.save()
            print("✅ CourseCacheService: Cleared \(oldCourses.count) old courses")
        } catch {
            print("❌ CourseCacheService: Failed to clear old courses: \(error)")
        }
    }
}
