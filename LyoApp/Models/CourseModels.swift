import Foundation
import SwiftData

// MARK: - Course Data Models
@Model
class Course {
    @Attribute(.unique) var id: String
    var title: String
    var description: String
    var category: String
    var difficulty: CourseDifficulty
    var estimatedDuration: TimeInterval // in seconds
    var createdDate: Date
    var updatedDate: Date
    var isCompleted: Bool
    var progress: Double // 0.0 to 1.0
    var modules: [CourseModule]
    var userID: String?
    
    init(id: String = UUID().uuidString, 
         title: String, 
         description: String, 
         category: String, 
         difficulty: CourseDifficulty, 
         estimatedDuration: TimeInterval,
         userID: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.difficulty = difficulty
        self.estimatedDuration = estimatedDuration
        self.createdDate = Date()
        self.updatedDate = Date()
        self.isCompleted = false
        self.progress = 0.0
        self.modules = []
        self.userID = userID
    }
}

@Model
class CourseModule {
    @Attribute(.unique) var id: String
    var title: String
    var description: String
    var content: String
    var orderIndex: Int
    var estimatedDuration: TimeInterval
    var isCompleted: Bool
    var progress: Double
    var lessons: [Lesson]
    var exercises: [Exercise]
    var course: Course?
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         content: String,
         orderIndex: Int,
         estimatedDuration: TimeInterval) {
        self.id = id
        self.title = title
        self.description = description
        self.content = content
        self.orderIndex = orderIndex
        self.estimatedDuration = estimatedDuration
        self.isCompleted = false
        self.progress = 0.0
        self.lessons = []
        self.exercises = []
    }
}

@Model
class Lesson {
    @Attribute(.unique) var id: String
    var title: String
    var content: String
    var videoURL: String?
    var orderIndex: Int
    var estimatedDuration: TimeInterval
    var isCompleted: Bool
    var module: CourseModule?
    
    init(id: String = UUID().uuidString,
         title: String,
         content: String,
         videoURL: String? = nil,
         orderIndex: Int,
         estimatedDuration: TimeInterval) {
        self.id = id
        self.title = title
        self.content = content
        self.videoURL = videoURL
        self.orderIndex = orderIndex
        self.estimatedDuration = estimatedDuration
        self.isCompleted = false
    }
}

@Model
class Exercise {
    @Attribute(.unique) var id: String
    var title: String
    var description: String
    var instructions: String
    var sampleCode: String?
    var solution: String?
    var orderIndex: Int
    var isCompleted: Bool
    var userSubmission: String?
    var module: CourseModule?
    
    init(id: String = UUID().uuidString,
         title: String,
         description: String,
         instructions: String,
         sampleCode: String? = nil,
         solution: String? = nil,
         orderIndex: Int) {
        self.id = id
        self.title = title
        self.description = description
        self.instructions = instructions
        self.sampleCode = sampleCode
        self.solution = solution
        self.orderIndex = orderIndex
        self.isCompleted = false
    }
}

// MARK: - Course Progress Tracking
@Model
class CourseProgress {
    @Attribute(.unique) var id: String
    var userID: String
    var courseID: String
    var currentModuleID: String?
    var currentLessonID: String?
    var overallProgress: Double
    var timeSpent: TimeInterval
    var lastAccessedDate: Date
    var startDate: Date
    var completionDate: Date?
    
    init(userID: String, courseID: String) {
        self.id = UUID().uuidString
        self.userID = userID
        self.courseID = courseID
        self.overallProgress = 0.0
        self.timeSpent = 0.0
        self.lastAccessedDate = Date()
        self.startDate = Date()
    }
}

// MARK: - Enums
enum CourseDifficulty: String, CaseIterable, Codable {
    case beginner = "beginner"
    case intermediate = "intermediate" 
    case advanced = "advanced"
    case expert = "expert"
    
    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
    
    var color: String {
        switch self {
        case .beginner: return "green"
        case .intermediate: return "blue"
        case .advanced: return "orange"
        case .expert: return "red"
        }
    }
}

// MARK: - Course Manager
@MainActor
class CourseManager: ObservableObject {
    static let shared = CourseManager()
    
    @Published var courses: [Course] = []
    @Published var currentCourse: Course?
    @Published var isLoading = false
    
    private init() {
        loadCourses()
    }
    
    func createCourse(title: String, description: String, category: String, difficulty: CourseDifficulty, modules: [CourseModule], userID: String? = nil) -> Course {
        let course = Course(
            title: title,
            description: description,
            category: category,
            difficulty: difficulty,
            estimatedDuration: modules.reduce(0) { $0 + $1.estimatedDuration },
            userID: userID
        )
        
        course.modules = modules
        modules.forEach { $0.course = course }
        
        courses.append(course)
        saveCourses()
        
        return course
    }
    
    func createSwiftCourse(userID: String? = nil) -> Course {
        let modules = [
            createSwiftFundamentalsModule(),
            createSwiftUIBasicsModule(),
            createAdvancedFeaturesModule(),
            createFinalProjectModule()
        ]
        
        return createCourse(
            title: "iOS Development with Swift",
            description: "Complete course covering Swift programming and iOS app development",
            category: "iOS Development",
            difficulty: .beginner,
            modules: modules,
            userID: userID
        )
    }
    
    private func createSwiftFundamentalsModule() -> CourseModule {
        let module = CourseModule(
            title: "Swift Fundamentals",
            description: "Learn the basics of Swift programming language",
            content: "Master Swift syntax, variables, functions, and object-oriented programming concepts.",
            orderIndex: 1,
            estimatedDuration: 7 * 24 * 3600 // 1 week
        )
        
        module.lessons = [
            Lesson(title: "Variables and Constants", content: "Learn about var, let, and data types", orderIndex: 1, estimatedDuration: 3600),
            Lesson(title: "Control Flow", content: "If statements, loops, and switch cases", orderIndex: 2, estimatedDuration: 3600),
            Lesson(title: "Functions", content: "Creating and using functions in Swift", orderIndex: 3, estimatedDuration: 3600),
            Lesson(title: "Classes and Structs", content: "Object-oriented programming in Swift", orderIndex: 4, estimatedDuration: 3600)
        ]
        
        module.exercises = [
            Exercise(title: "Variable Practice", description: "Create variables of different types", instructions: "Practice declaring variables and constants", orderIndex: 1),
            Exercise(title: "Function Challenge", description: "Build a calculator function", instructions: "Create functions for basic math operations", orderIndex: 2)
        ]
        
        return module
    }
    
    private func createSwiftUIBasicsModule() -> CourseModule {
        let module = CourseModule(
            title: "SwiftUI Basics",
            description: "Build user interfaces with SwiftUI",
            content: "Learn to create modern iOS apps using SwiftUI framework.",
            orderIndex: 2,
            estimatedDuration: 14 * 24 * 3600 // 2 weeks
        )
        
        module.lessons = [
            Lesson(title: "Views and Modifiers", content: "Basic SwiftUI components", orderIndex: 1, estimatedDuration: 7200),
            Lesson(title: "State Management", content: "Managing app state with @State", orderIndex: 2, estimatedDuration: 7200),
            Lesson(title: "Lists and Navigation", content: "Creating lists and navigation", orderIndex: 3, estimatedDuration: 7200)
        ]
        
        return module
    }
    
    private func createAdvancedFeaturesModule() -> CourseModule {
        let module = CourseModule(
            title: "Advanced iOS Features",
            description: "Implement advanced iOS functionality",
            content: "Learn Core Data, networking, camera integration, and more.",
            orderIndex: 3,
            estimatedDuration: 14 * 24 * 3600 // 2 weeks
        )
        
        module.lessons = [
            Lesson(title: "Core Data", content: "Data persistence with Core Data", orderIndex: 1, estimatedDuration: 10800),
            Lesson(title: "Networking", content: "API calls and data fetching", orderIndex: 2, estimatedDuration: 10800),
            Lesson(title: "Camera & Location", content: "Hardware integration", orderIndex: 3, estimatedDuration: 7200)
        ]
        
        return module
    }
    
    private func createFinalProjectModule() -> CourseModule {
        let module = CourseModule(
            title: "Final Project",
            description: "Build your own iOS app",
            content: "Apply everything you've learned to create a complete app.",
            orderIndex: 4,
            estimatedDuration: 14 * 24 * 3600 // 2 weeks
        )
        
        module.lessons = [
            Lesson(title: "Project Planning", content: "Plan your app architecture", orderIndex: 1, estimatedDuration: 7200),
            Lesson(title: "Development", content: "Build your app step by step", orderIndex: 2, estimatedDuration: 36000),
            Lesson(title: "Testing & Deployment", content: "Test and prepare for App Store", orderIndex: 3, estimatedDuration: 7200)
        ]
        
        return module
    }
    
    func updateProgress(for course: Course, progress: Double) {
        course.progress = progress
        course.updatedDate = Date()
        
        if progress >= 1.0 {
            course.isCompleted = true
        }
        
        saveCourses()
    }
    
    private func loadCourses() {
        // Load from UserDefaults for now (can be replaced with SwiftData later)
        if let data = UserDefaults.standard.data(forKey: "saved_courses") {
            // For now, create sample data
            courses = []
        }
    }
    
    private func saveCourses() {
        // Save to UserDefaults for now (can be replaced with SwiftData later)
        // UserDefaults.standard.set(encoded courses, forKey: "saved_courses")
    }
}