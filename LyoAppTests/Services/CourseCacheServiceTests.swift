import XCTest
import SwiftData
@testable import LyoApp

@MainActor
final class CourseCacheServiceTests: XCTestCase {
    
    var sut: CourseCacheService!
    
    override func setUp() async throws {
        sut = CourseCacheService.shared
        sut.clearAll()
    }
    
    override func tearDown() async throws {
        sut.clearAll()
        sut = nil
    }
    
    // MARK: - Helper Methods
    
    func createMockCourse(title: String = "Test Course") -> Course {
        Course(
            id: UUID(),
            title: title,
            subtitle: "Test Subtitle",
            description: "Test Description",
            thumbnailURL: nil,
            category: .technology,
            difficulty: .intermediate,
            duration: "2 hours",
            rating: 4.5,
            enrollmentCount: 100,
            instructor: "Test Instructor",
            lessons: [
                Lesson(
                    id: UUID(),
                    title: "Lesson 1",
                    duration: "30 min",
                    isCompleted: false,
                    content: "Test content",
                    videoURL: nil
                )
            ],
            progress: 0.0
        )
    }
    
    // MARK: - Cache Tests
    
    func testCacheCourse_StoresSuccessfully() {
        // Given
        let course = createMockCourse(title: "Swift Fundamentals")
        
        // When
        sut.cache(course)
        
        // Then
        let retrieved = sut.getCourse(id: course.id)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, "Swift Fundamentals")
        XCTAssertEqual(retrieved?.lessons.count, 1)
    }
    
    func testCacheCourse_UpdatesExisting() {
        // Given
        let courseId = UUID()
        let course1 = Course(
            id: courseId,
            title: "Original Title",
            subtitle: "Subtitle",
            description: "Description",
            thumbnailURL: nil,
            category: .technology,
            difficulty: .beginner,
            duration: "1 hour",
            rating: 4.0,
            enrollmentCount: 50,
            instructor: "Instructor",
            lessons: [],
            progress: 0.0
        )
        
        let course2 = Course(
            id: courseId,
            title: "Updated Title",
            subtitle: "Subtitle",
            description: "Description",
            thumbnailURL: nil,
            category: .technology,
            difficulty: .beginner,
            duration: "1 hour",
            rating: 4.0,
            enrollmentCount: 50,
            instructor: "Instructor",
            lessons: [],
            progress: 0.5
        )
        
        // When
        sut.cache(course1)
        sut.cache(course2)
        
        // Then
        let retrieved = sut.getCourse(id: courseId)
        XCTAssertEqual(retrieved?.title, "Updated Title")
        XCTAssertEqual(retrieved?.progress, 0.5)
    }
    
    // MARK: - Retrieve Tests
    
    func testGetCourse_ReturnsNilForNonExistent() {
        // Given
        let nonExistentId = UUID()
        
        // When
        let result = sut.getCourse(id: nonExistentId)
        
        // Then
        XCTAssertNil(result)
    }
    
    func testGetAllCourses_ReturnsAllCached() {
        // Given
        let course1 = createMockCourse(title: "Course 1")
        let course2 = createMockCourse(title: "Course 2")
        let course3 = createMockCourse(title: "Course 3")
        
        // When
        sut.cache(course1)
        sut.cache(course2)
        sut.cache(course3)
        
        let allCourses = sut.getAllCourses()
        
        // Then
        XCTAssertEqual(allCourses.count, 3)
    }
    
    func testGetAllCourses_OrderedByLastAccessed() async {
        // Given
        let course1 = createMockCourse(title: "Course 1")
        let course2 = createMockCourse(title: "Course 2")
        
        sut.cache(course1)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        sut.cache(course2)
        
        // When
        let allCourses = sut.getAllCourses()
        
        // Then
        XCTAssertEqual(allCourses.first?.title, "Course 2", "Most recently cached should be first")
    }
    
    // MARK: - Clear Tests
    
    func testClearAll_RemovesAllCourses() {
        // Given
        sut.cache(createMockCourse(title: "Course 1"))
        sut.cache(createMockCourse(title: "Course 2"))
        XCTAssertEqual(sut.getAllCourses().count, 2)
        
        // When
        sut.clearAll()
        
        // Then
        XCTAssertEqual(sut.getAllCourses().count, 0)
    }
    
    // MARK: - Data Integrity Tests
    
    func testCachedCourse_PreservesAllProperties() {
        // Given
        let originalCourse = Course(
            id: UUID(),
            title: "Complete Swift Course",
            subtitle: "From Beginner to Pro",
            description: "Learn Swift programming from scratch",
            thumbnailURL: "https://example.com/thumb.jpg",
            category: .programming,
            difficulty: .advanced,
            duration: "40 hours",
            rating: 4.9,
            enrollmentCount: 5000,
            instructor: "John Doe",
            lessons: [
                Lesson(id: UUID(), title: "Intro", duration: "10 min", isCompleted: true, content: "Welcome", videoURL: nil),
                Lesson(id: UUID(), title: "Variables", duration: "20 min", isCompleted: false, content: "Learn variables", videoURL: "https://example.com/video.mp4")
            ],
            progress: 0.25
        )
        
        // When
        sut.cache(originalCourse)
        let retrieved = sut.getCourse(id: originalCourse.id)
        
        // Then
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.title, originalCourse.title)
        XCTAssertEqual(retrieved?.subtitle, originalCourse.subtitle)
        XCTAssertEqual(retrieved?.description, originalCourse.description)
        XCTAssertEqual(retrieved?.thumbnailURL, originalCourse.thumbnailURL)
        XCTAssertEqual(retrieved?.category, originalCourse.category)
        XCTAssertEqual(retrieved?.difficulty, originalCourse.difficulty)
        XCTAssertEqual(retrieved?.duration, originalCourse.duration)
        XCTAssertEqual(retrieved?.rating, originalCourse.rating)
        XCTAssertEqual(retrieved?.enrollmentCount, originalCourse.enrollmentCount)
        XCTAssertEqual(retrieved?.instructor, originalCourse.instructor)
        XCTAssertEqual(retrieved?.lessons.count, originalCourse.lessons.count)
        XCTAssertEqual(retrieved?.progress, originalCourse.progress)
    }
    
    func testCachedLesson_PreservesAllProperties() {
        // Given
        let lesson = Lesson(
            id: UUID(),
            title: "Advanced Topics",
            duration: "45 min",
            isCompleted: true,
            content: "Deep dive into advanced concepts",
            videoURL: "https://example.com/advanced.mp4"
        )
        
        let course = Course(
            id: UUID(),
            title: "Test Course",
            subtitle: "",
            description: "",
            thumbnailURL: nil,
            category: .technology,
            difficulty: .intermediate,
            duration: "1 hour",
            rating: 0,
            enrollmentCount: 0,
            instructor: "Test",
            lessons: [lesson],
            progress: 0
        )
        
        // When
        sut.cache(course)
        let retrieved = sut.getCourse(id: course.id)
        let retrievedLesson = retrieved?.lessons.first
        
        // Then
        XCTAssertNotNil(retrievedLesson)
        XCTAssertEqual(retrievedLesson?.title, lesson.title)
        XCTAssertEqual(retrievedLesson?.duration, lesson.duration)
        XCTAssertEqual(retrievedLesson?.isCompleted, lesson.isCompleted)
        XCTAssertEqual(retrievedLesson?.content, lesson.content)
        XCTAssertEqual(retrievedLesson?.videoURL, lesson.videoURL)
    }
}
