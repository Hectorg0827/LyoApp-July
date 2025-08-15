import Foundation
import CoreData

// MARK: - Course Repository
@MainActor
class CourseRepository: ObservableObject {
    private let coreDataManager = CoreDataManager.shared
    
    @Published var courses: [Course] = []
    @Published var userEnrollments: [CourseEnrollmentEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Course Operations
    func loadCourses(category: String? = nil) async {
        isLoading = true
        defer { isLoading = false }
        
        let coreDataCourses = coreDataManager.fetchCourses(category: category)
        courses = coreDataCourses.compactMap { convertToSwiftUICourse($0) }
    }
    
    func createCourse(
        title: String,
        description: String,
        instructor: String,
        imageURL: String,
        category: String,
        difficulty: Course.Difficulty,
        duration: TimeInterval,
        price: Double
    ) async -> Result<Course, Error> {
        isLoading = true
        defer { isLoading = false }
        
        let coreDataCourse = coreDataManager.createCourse(
            title: title,
            description: description,
            instructor: instructor
        )
        // Best-effort set additional fields available on CourseEntity
        coreDataCourse.duration = String(Int(duration / 60))
        coreDataCourse.rating = 0.0
        
        guard let course = convertToSwiftUICourse(coreDataCourse) else {
            let error = CourseRepositoryError.conversionFailed
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        await loadCourses()
        return .success(course)
    }
    
    // MARK: - Enrollment Operations
    func enrollUser(_ userId: String, in courseId: String) async -> Result<CourseEnrollmentEntity, Error> {
        isLoading = true
        defer { isLoading = false }
        
        // Check if already enrolled
        let existingEnrollments = coreDataManager.fetchUserEnrollments(userId)
        if existingEnrollments.contains(where: { $0.courseId == courseId }) {
            let error = CourseRepositoryError.alreadyEnrolled
            errorMessage = error.localizedDescription
            return .failure(error)
        }
        
        let enrollment = coreDataManager.enrollUser(userId, in: courseId)
        await loadUserEnrollments(for: userId)
        
        return .success(enrollment)
    }
    
    func loadUserEnrollments(for userId: String) async {
        userEnrollments = coreDataManager.fetchUserEnrollments(userId)
    }
    
    func getEnrolledCourses(for userId: String) async -> [Course] {
        let enrollments = coreDataManager.fetchUserEnrollments(userId)
        let enrolledCourseIds = enrollments.compactMap { $0.courseId }
        
        return courses.filter { course in
            enrolledCourseIds.contains(course.id.uuidString)
        }
    }
    
    // MARK: - Helper Methods
    private func convertToSwiftUICourse(_ coreDataCourse: CourseEntity) -> Course? {
        // Map using available Core Data fields in CoreDataEntities.swift
        let idString = coreDataCourse.id
        let title = coreDataCourse.title
        let description = coreDataCourse.desc
        let instructor = coreDataCourse.instructor
        let durationString = coreDataCourse.duration // Stored as String in CoreData
        let rating = coreDataCourse.rating
        let enrollmentCount = Int(coreDataCourse.enrollmentCount)
        
        // Convert duration string (e.g., "120" or "2h 30m") to seconds best-effort
        let duration: TimeInterval = {
            // Try plain number of minutes
            if let minutes = Int(durationString.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return TimeInterval(minutes * 60)
            }
            // Try formats like "2h 30m"
            let pattern = #"(?:(\d+)h)?\s*(?:(\d+)m)?"#
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(durationString.startIndex..., in: durationString)
                if let match = regex.firstMatch(in: durationString, range: range) {
                    var total: Int = 0
                    if let hrRange = Range(match.range(at: 1), in: durationString) {
                        total += (Int(durationString[hrRange]) ?? 0) * 60
                    }
                    if let minRange = Range(match.range(at: 2), in: durationString) {
                        total += Int(durationString[minRange]) ?? 0
                    }
                    return TimeInterval(total * 60)
                }
            }
            return 0
        }()
        
        // Default fields not present in Core Data
        let thumbnailURL = ""
        let category = "General"
        let difficulty: Course.Difficulty = .beginner
        
        // Build Course
        let uuid = UUID(uuidString: idString) ?? UUID()
        return Course(
            id: uuid,
            title: title,
            description: description,
            instructor: instructor,
            thumbnailURL: thumbnailURL,
            duration: duration,
            difficulty: difficulty,
            category: category,
            lessons: [],
            progress: 0.0,
            isEnrolled: false,
            rating: rating,
            studentsCount: enrollmentCount
        )
    }
}

// MARK: - Course Repository Errors
enum CourseRepositoryError: LocalizedError {
    case courseNotFound
    case alreadyEnrolled
    case conversionFailed
    case enrollmentFailed
    
    var errorDescription: String? {
        switch self {
        case .courseNotFound:
            return "Course not found"
        case .alreadyEnrolled:
            return "User is already enrolled in this course"
        case .conversionFailed:
            return "Failed to convert course data"
        case .enrollmentFailed:
            return "Failed to enroll in course"
        }
    }
}
