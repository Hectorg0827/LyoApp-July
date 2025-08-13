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
            instructor: instructor,
            imageURL: imageURL,
            category: category,
            difficulty: difficulty.rawValue,
            duration: Int32(duration),
            price: price
        )
        
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
        guard let id = coreDataCourse.id,
              let title = coreDataCourse.title,
              let description = coreDataCourse.courseDescription,
              let instructor = coreDataCourse.instructor,
              let imageURL = coreDataCourse.imageURL,
              let category = coreDataCourse.category,
              let difficultyString = coreDataCourse.difficulty,
              let difficulty = Course.Difficulty(rawValue: difficultyString) else {
            return nil
        }
        
        return Course(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            description: description,
            instructor: instructor,
            thumbnailURL: imageURL,
            duration: TimeInterval(coreDataCourse.duration * 60), // Convert minutes to seconds
            difficulty: difficulty,
            category: category,
            lessons: [], // TODO: Load lessons from relationship
            progress: 0.0, // TODO: Calculate from enrollments
            isEnrolled: false, // TODO: Check enrollment status
            rating: coreDataCourse.rating,
            studentsCount: Int(coreDataCourse.enrollments?.count ?? 0)
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
