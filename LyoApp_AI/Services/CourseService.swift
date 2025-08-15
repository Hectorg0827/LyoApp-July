import Foundation
import Combine

// MARK: - Course Service Protocol
protocol CourseServiceProtocol {
    func getFeaturedCourses() async throws -> [Course]
    func searchCourses(query: String, filters: CourseFilters?) async throws -> CourseSearchResponse
    func getCourseDetails(courseId: String) async throws -> CourseDetails
    func enrollInCourse(courseId: String) async throws -> EnrollmentResponse
    func getEnrolledCourses() async throws -> [Course]
    func updateProgress(courseId: String, lessonId: String, progress: Double) async throws
    func completeLession(courseId: String, lessonId: String) async throws -> CompletionResponse
    func rateCourse(courseId: String, rating: Int, review: String?) async throws
}

// MARK: - Course Models
struct CourseSearchResponse: Codable {
    let courses: [Course]
    let pagination: Pagination
    let filters: AppliedFilters
    
    private enum CodingKeys: String, CodingKey {
        case courses
        case pagination
        case filters = "applied_filters"
    }
}

struct CourseFilters: Codable {
    let categories: [String]?
    let difficultyLevels: [DifficultyLevel]?
    let duration: DurationRange?
    let price: PriceRange?
    let language: String?
    let rating: Double?
    
    private enum CodingKeys: String, CodingKey {
        case categories
        case difficultyLevels = "difficulty_levels"
        case duration
        case price
        case language
        case rating
    }
}

struct DurationRange: Codable {
    let min: Int // in hours
    let max: Int // in hours
}

struct PriceRange: Codable {
    let min: Double
    let max: Double
}

struct AppliedFilters: Codable {
    let categories: [String]
    let difficultyLevels: [DifficultyLevel]
    let totalResults: Int
    
    private enum CodingKeys: String, CodingKey {
        case categories
        case difficultyLevels = "difficulty_levels"
        case totalResults = "total_results"
    }
}

struct CourseDetails: Codable {
    let course: Course
    let lessons: [Lesson]
    let instructor: Instructor
    let enrollment: CourseEnrollment?
    let reviews: [CourseReview]
    let relatedCourses: [Course]
    
    private enum CodingKeys: String, CodingKey {
        case course
        case lessons
        case instructor
        case enrollment
        case reviews
        case relatedCourses = "related_courses"
    }
}

struct Lesson: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let type: LessonType
    let duration: Int // in seconds
    let order: Int
    let resources: [LessonResource]
    let isCompleted: Bool
    let progress: Double // 0.0 to 1.0
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case type
        case duration
        case order
        case resources
        case isCompleted = "is_completed"
        case progress
    }
}

enum LessonType: String, Codable {
    case video
    case text
    case interactive
    case quiz
    case assignment
}

struct LessonResource: Codable {
    let id: String
    let title: String
    let type: ResourceType
    let url: String
    let size: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case url
        case size
    }
}

enum ResourceType: String, Codable {
    case pdf
    case video
    case audio
    case link
    case download
}

struct Instructor: Codable {
    let id: String
    let name: String
    let bio: String
    let avatarURL: String?
    let expertise: [String]
    let rating: Double
    let totalCourses: Int
    let totalStudents: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case bio
        case avatarURL = "avatar_url"
        case expertise
        case rating
        case totalCourses = "total_courses"
        case totalStudents = "total_students"
    }
}

struct CourseEnrollment: Codable {
    let enrolledAt: Date
    let progress: Double
    let completedLessons: Int
    let totalLessons: Int
    let lastAccessedAt: Date?
    let certificateURL: String?
    
    private enum CodingKeys: String, CodingKey {
        case enrolledAt = "enrolled_at"
        case progress
        case completedLessons = "completed_lessons"
        case totalLessons = "total_lessons"
        case lastAccessedAt = "last_accessed_at"
        case certificateURL = "certificate_url"
    }
}

struct CourseReview: Codable {
    let id: String
    let author: User
    let rating: Int
    let comment: String?
    let createdAt: Date
    let helpful: Int
    
    private enum CodingKeys: String, CodingKey {
        case id
        case author
        case rating
        case comment
        case createdAt = "created_at"
        case helpful
    }
}

struct EnrollmentResponse: Codable {
    let courseId: String
    let enrolledAt: Date
    let accessLevel: AccessLevel
    
    private enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case enrolledAt = "enrolled_at"
        case accessLevel = "access_level"
    }
}

enum AccessLevel: String, Codable {
    case free
    case premium
    case pro
}

struct CompletionResponse: Codable {
    let lessonId: String
    let completedAt: Date
    let pointsEarned: Int
    let badgeEarned: String?
    
    private enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case completedAt = "completed_at"
        case pointsEarned = "points_earned"
        case badgeEarned = "badge_earned"
    }
}

struct ProgressUpdateRequest: Codable {
    let progress: Double
    let timeSpent: Int
    
    private enum CodingKeys: String, CodingKey {
        case progress
        case timeSpent = "time_spent"
    }
}

struct CourseRatingRequest: Codable {
    let rating: Int
    let review: String?
}

// MARK: - Live Course Service
class LiveCourseService: CourseServiceProtocol {
    private let httpClient: HTTPClientProtocol
    private let baseURL: URL
    
    init(httpClient: HTTPClientProtocol, baseURL: String = "http://localhost:8002") {
        self.httpClient = httpClient
        guard let url = URL(string: baseURL) else {
            fatalError("Invalid base URL")
        }
        self.baseURL = url
    }
    
    func getFeaturedCourses() async throws -> [Course] {
        let url = baseURL.appendingPathComponent("/api/v1/courses/featured")
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.request(request, responseType: FeaturedCoursesResponse.self)
        return response.courses
    }
    
    func searchCourses(query: String, filters: CourseFilters?) async throws -> CourseSearchResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("/api/v1/courses/search"), resolvingAgainstBaseURL: true)!
        
        var queryItems = [URLQueryItem(name: "q", value: query)]
        
        if let filters = filters {
            if let categories = filters.categories {
                queryItems.append(contentsOf: categories.map { URLQueryItem(name: "categories", value: $0) })
            }
            if let difficultyLevels = filters.difficultyLevels {
                queryItems.append(contentsOf: difficultyLevels.map { URLQueryItem(name: "difficulty", value: $0.rawValue) })
            }
            if let language = filters.language {
                queryItems.append(URLQueryItem(name: "language", value: language))
            }
        }
        
        components.queryItems = queryItems
        
        let request = HTTPRequest.get(url: components.url!)
        return try await httpClient.request(request, responseType: CourseSearchResponse.self)
    }
    
    func getCourseDetails(courseId: String) async throws -> CourseDetails {
        let url = baseURL.appendingPathComponent("/api/v1/courses/\(courseId)")
        let request = HTTPRequest.get(url: url)
        
        return try await httpClient.request(request, responseType: CourseDetails.self)
    }
    
    func enrollInCourse(courseId: String) async throws -> EnrollmentResponse {
        let url = baseURL.appendingPathComponent("/api/v1/courses/\(courseId)/enroll")
        let request = HTTPRequest(method: .POST, url: url)
        
        return try await httpClient.request(request, responseType: EnrollmentResponse.self)
    }
    
    func getEnrolledCourses() async throws -> [Course] {
        let url = baseURL.appendingPathComponent("/api/v1/courses/enrolled")
        let request = HTTPRequest.get(url: url)
        
        let response = try await httpClient.request(request, responseType: EnrolledCoursesResponse.self)
        return response.courses
    }
    
    func updateProgress(courseId: String, lessonId: String, progress: Double) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/courses/\(courseId)/lessons/\(lessonId)/progress")
        let progressRequest = ProgressUpdateRequest(progress: progress, timeSpent: 0)
        let request = try HTTPRequest.put(url: url, body: progressRequest)
        
        try await httpClient.request(request)
    }
    
    func completeLession(courseId: String, lessonId: String) async throws -> CompletionResponse {
        let url = baseURL.appendingPathComponent("/api/v1/courses/\(courseId)/lessons/\(lessonId)/complete")
        let request = HTTPRequest(method: .POST, url: url)
        
        return try await httpClient.request(request, responseType: CompletionResponse.self)
    }
    
    func rateCourse(courseId: String, rating: Int, review: String?) async throws {
        let url = baseURL.appendingPathComponent("/api/v1/courses/\(courseId)/rate")
        let ratingRequest = CourseRatingRequest(rating: rating, review: review)
        let request = try HTTPRequest.post(url: url, body: ratingRequest)
        
        try await httpClient.request(request)
    }
}

// MARK: - Response Wrappers
struct FeaturedCoursesResponse: Codable {
    let courses: [Course]
}

struct EnrolledCoursesResponse: Codable {
    let courses: [Course]
}

// MARK: - Mock Course Service
class MockCourseService: CourseServiceProtocol {
    var shouldFail = false
    var loadDelay: Double = 1.0
    
    private var mockCourses: [Course] = []
    
    init() {
        generateMockCourses()
    }
    
    func getFeaturedCourses() async throws -> [Course] {
        try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))
        
        if shouldFail {
            throw NSError(domain: "CourseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load featured courses"])
        }
        
        return Array(mockCourses.prefix(6))
    }
    
    func searchCourses(query: String, filters: CourseFilters?) async throws -> CourseSearchResponse {
        try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))
        
        if shouldFail {
            throw NSError(domain: "CourseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Search failed"])
        }
        
        let filteredCourses = mockCourses.filter { course in
            course.title.localizedCaseInsensitiveContains(query) ||
            course.description.localizedCaseInsensitiveContains(query)
        }
        
        return CourseSearchResponse(
            courses: filteredCourses,
            pagination: Pagination(
                currentPage: 1,
                totalPages: 1,
                totalItems: filteredCourses.count,
                itemsPerPage: filteredCourses.count
            ),
            filters: AppliedFilters(
                categories: [],
                difficultyLevels: [],
                totalResults: filteredCourses.count
            )
        )
    }
    
    func getCourseDetails(courseId: String) async throws -> CourseDetails {
        try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))
        
        guard let course = mockCourses.first(where: { $0.id == courseId }) else {
            throw NSError(domain: "CourseError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Course not found"])
        }
        
        return CourseDetails(
            course: course,
            lessons: generateMockLessons(),
            instructor: generateMockInstructor(),
            enrollment: nil,
            reviews: generateMockReviews(),
            relatedCourses: Array(mockCourses.prefix(3))
        )
    }
    
    func enrollInCourse(courseId: String) async throws -> EnrollmentResponse {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if shouldFail {
            throw NSError(domain: "CourseError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Enrollment failed"])
        }
        
        return EnrollmentResponse(
            courseId: courseId,
            enrolledAt: Date(),
            accessLevel: .free
        )
    }
    
    func getEnrolledCourses() async throws -> [Course] {
        try await Task.sleep(nanoseconds: UInt64(loadDelay * 1_000_000_000))
        
        if shouldFail {
            throw NSError(domain: "CourseError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to load enrolled courses"])
        }
        
        return Array(mockCourses.prefix(3))
    }
    
    func updateProgress(courseId: String, lessonId: String, progress: Double) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("Mock updated progress: \(progress) for lesson \(lessonId) in course \(courseId)")
    }
    
    func completeLession(courseId: String, lessonId: String) async throws -> CompletionResponse {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        if shouldFail {
            throw NSError(domain: "CourseError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to complete lesson"])
        }
        
        return CompletionResponse(
            lessonId: lessonId,
            completedAt: Date(),
            pointsEarned: 50,
            badgeEarned: nil
        )
    }
    
    func rateCourse(courseId: String, rating: Int, review: String?) async throws {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        print("Mock rated course \(courseId): \(rating) stars")
    }
    
    private func generateMockCourses() {
        let courseData = [
            ("SwiftUI Fundamentals", "Learn the basics of SwiftUI and iOS app development", "iOS Development", .beginner),
            ("Advanced Swift Patterns", "Master advanced Swift programming patterns and architectures", "iOS Development", .advanced),
            ("Python for Data Science", "Complete guide to Python programming for data analysis", "Data Science", .intermediate),
            ("Machine Learning Basics", "Introduction to machine learning concepts and algorithms", "Machine Learning", .beginner),
            ("React Native Development", "Build mobile apps with React Native framework", "Mobile Development", .intermediate),
            ("UI/UX Design Principles", "Essential principles of user interface and experience design", "Design", .beginner),
        ]
        
        mockCourses = courseData.enumerated().map { index, data in
            Course(
                id: "course_\(index + 1)",
                title: data.0,
                description: data.1,
                thumbnailURL: "https://example.com/course\(index + 1).jpg",
                category: data.2,
                difficulty: data.3,
                rating: Double.random(in: 4.0...5.0),
                totalRatings: Int.random(in: 100...1000),
                duration: Int.random(in: 3600...14400), // 1-4 hours
                totalLessons: Int.random(in: 8...20),
                price: Double.random(in: 0...99.99),
                language: "en",
                tags: ["mobile", "programming", "development"],
                createdAt: Date().addingTimeInterval(-TimeInterval.random(in: 0...(30 * 24 * 3600))),
                updatedAt: Date()
            )
        }
    }
    
    private func generateMockLessons() -> [Lesson] {
        return (1...10).map { i in
            Lesson(
                id: "lesson_\(i)",
                title: "Lesson \(i): Introduction to Topic \(i)",
                description: "This lesson covers the fundamental concepts of topic \(i).",
                type: LessonType.allCases.randomElement()!,
                duration: Int.random(in: 300...1800), // 5-30 minutes
                order: i,
                resources: generateMockResources(),
                isCompleted: Bool.random(),
                progress: Double.random(in: 0...1)
            )
        }
    }
    
    private func generateMockResources() -> [LessonResource] {
        return (1...3).map { i in
            LessonResource(
                id: "resource_\(i)",
                title: "Resource \(i)",
                type: ResourceType.allCases.randomElement()!,
                url: "https://example.com/resource\(i)",
                size: Int.random(in: 1024...1024*1024) // 1KB - 1MB
            )
        }
    }
    
    private func generateMockInstructor() -> Instructor {
        return Instructor(
            id: "instructor_1",
            name: "John Smith",
            bio: "Experienced software developer with 10+ years in mobile app development.",
            avatarURL: "https://example.com/instructor.jpg",
            expertise: ["iOS Development", "Swift", "SwiftUI"],
            rating: 4.8,
            totalCourses: 15,
            totalStudents: 50000
        )
    }
    
    private func generateMockReviews() -> [CourseReview] {
        return (1...5).map { i in
            CourseReview(
                id: "review_\(i)",
                author: User(
                    id: "reviewer_\(i)",
                    email: "reviewer\(i)@example.com",
                    displayName: "Reviewer \(i)",
                    profilePictureURL: nil,
                    isEmailVerified: true,
                    preferences: UserPreferences(
                        learningGoals: ["iOS Development"],
                        difficultyLevel: .beginner,
                        studyReminders: true,
                        contentLanguage: "en"
                    ),
                    stats: UserStats(totalPoints: i * 50, streak: i, completedCourses: i),
                    createdAt: Date(),
                    lastActiveAt: Date()
                ),
                rating: Int.random(in: 3...5),
                comment: "This is a great course! I learned a lot from it.",
                createdAt: Date().addingTimeInterval(-TimeInterval(i * 24 * 3600)),
                helpful: Int.random(in: 0...20)
            )
        }
    }
}

// MARK: - Extensions
extension LessonType: CaseIterable {}
extension ResourceType: CaseIterable {}
