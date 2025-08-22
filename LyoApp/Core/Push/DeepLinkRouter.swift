import Foundation
import SwiftUI

/// Deep link router for handling navigation from push notifications and URL schemes
@MainActor
class DeepLinkRouter: ObservableObject {
    
    @Published var activeRoute: DeepLinkRoute?
    @Published var isProcessing = false
    
    private let apiClient: APIClient
    private let coreDataStack: CoreDataStack
    
    init(apiClient: APIClient, coreDataStack: CoreDataStack = .shared) {
        self.apiClient = apiClient
        self.coreDataStack = coreDataStack
        
        // Listen for deep link notifications
        NotificationCenter.default.addObserver(
            forName: .deepLinkToCourse,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let courseId = notification.userInfo?["courseId"] as? String {
                Task {
                    await self?.routeToCourse(courseId: courseId)
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Route Handling
    
    /// Route to course, fetching if not cached
    func routeToCourse(courseId: String) async {
        guard !isProcessing else { return }
        
        isProcessing = true
        defer { isProcessing = false }
        
        print("🧭 Routing to course: \(courseId)")
        
        do {
            // First check if course exists in cache
            if let cachedCourse = coreDataStack.fetchCourse(by: courseId) {
                print("📚 Course found in cache")
                activeRoute = .course(cachedCourse)
                return
            }
            
            // Course not in cache, fetch from API
            print("🌐 Fetching course from API")
            let courseDTO: CourseDTO = try await apiClient.get("courses/\(courseId)")
            
            // Normalize and cache the course
            let normalizer = DataNormalizer(coreDataStack: coreDataStack)
            try normalizer.normalizeCourse(courseDTO)
            
            // Get the cached course and navigate
            if let course = coreDataStack.fetchCourse(by: courseId) {
                print("✅ Course fetched and cached")
                activeRoute = .course(course)
            } else {
                throw DeepLinkError.courseNotFound
            }
            
        } catch {
            print("❌ Failed to route to course: \(error)")
            activeRoute = .error(DeepLinkError.failedToLoadCourse(error))
        }
    }
    
    /// Route to lesson within a course
    func routeToLesson(courseId: String, lessonId: String) async {
        await routeToCourse(courseId: courseId)
        
        // After course is loaded, navigate to specific lesson
        if case .course(let course) = activeRoute {
            if let lesson = course.orderedLessons.first(where: { $0.id == lessonId }) {
                activeRoute = .lesson(course, lesson)
            }
        }
    }
    
    /// Clear active route
    func clearRoute() {
        activeRoute = nil
    }
    
    // MARK: - URL Handling
    
    /// Handle incoming URL from app delegate
    func handleURL(_ url: URL) async {
        print("🔗 Handling URL: \(url)")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Invalid URL format")
            return
        }
        
        // Parse lyo:// scheme
        guard components.scheme == "lyo" else {
            print("❌ Unsupported URL scheme: \(components.scheme ?? "nil")")
            return
        }
        
        switch components.host {
        case "course":
            let pathComponents = components.path.components(separatedBy: "/")
            if let courseId = pathComponents.last, !courseId.isEmpty {
                await routeToCourse(courseId: courseId)
            }
            
        case "lesson":
            // Format: lyo://lesson/courseId/lessonId
            let pathComponents = components.path.components(separatedBy: "/")
            if pathComponents.count >= 3 {
                let courseId = pathComponents[1]
                let lessonId = pathComponents[2]
                await routeToLesson(courseId: courseId, lessonId: lessonId)
            }
            
        default:
            print("❌ Unsupported URL host: \(components.host ?? "nil")")
        }
    }
}

// MARK: - Deep Link Routes
enum DeepLinkRoute: Equatable {
    case course(Course)
    case lesson(Course, Lesson)
    case error(DeepLinkError)
    
    static func == (lhs: DeepLinkRoute, rhs: DeepLinkRoute) -> Bool {
        switch (lhs, rhs) {
        case (.course(let course1), .course(let course2)):
            return course1.id == course2.id
        case (.lesson(let course1, let lesson1), .lesson(let course2, let lesson2)):
            return course1.id == course2.id && lesson1.id == lesson2.id
        case (.error(let error1), .error(let error2)):
            return error1.localizedDescription == error2.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Deep Link Errors
enum DeepLinkError: LocalizedError {
    case courseNotFound
    case lessonNotFound
    case failedToLoadCourse(Error)
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .courseNotFound:
            return "Course not found"
        case .lessonNotFound:
            return "Lesson not found"
        case .failedToLoadCourse(let error):
            return "Failed to load course: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL format"
        }
    }
}

// MARK: - SwiftUI View Helpers
extension DeepLinkRouter {
    
    /// Create a SwiftUI view for the active route
    @ViewBuilder
    func routeView() -> some View {
        if isProcessing {
            ProgressView("Loading...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            switch activeRoute {
            case .course(let course):
                CourseDetailView(course: course)
                
            case .lesson(let course, let lesson):
                LessonDetailView(course: course, lesson: lesson)
                
            case .error(let error):
                ErrorView(error: error)
                
            case nil:
                EmptyView()
            }
        }
    }
}

// MARK: - Placeholder Views (to be implemented)
private struct CourseDetailView: View {
    let course: Course
    
    var body: some View {
        VStack {
            Text("Course: \(course.title)")
                .font(.largeTitle)
            Text("Status: \(course.status)")
            Text("Progress: \(Int(course.progress * 100))%")
        }
        .padding()
    }
}

private struct LessonDetailView: View {
    let course: Course
    let lesson: Lesson
    
    var body: some View {
        VStack {
            Text("Course: \(course.title)")
                .font(.title)
            Text("Lesson: \(lesson.title)")
                .font(.title2)
            Text("Order: \(lesson.order)")
        }
        .padding()
    }
}

private struct ErrorView: View {
    let error: DeepLinkError
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Error")
                .font(.title)
                .fontWeight(.bold)
            
            Text(error.localizedDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}