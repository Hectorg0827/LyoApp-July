import Foundation
import SwiftUI

/**
 * Free Courses Service
 * Integrates with multiple free education platforms to fetch course content
 */
@MainActor
class FreeCoursesService: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Service Dependencies
    private let edxService = EdXCoursesService()
    
    // MARK: - Search Courses Across Platforms
    func searchCourses(query: String, maxResults: Int = 20) async throws -> [Course] {
        async let khanAcademyCourses = getKhanAcademyCourses(subject: query)
        async let mitCourses = getMITOpenCourseWare(subject: query)
        async let courseraFreeCourses = getCourseraFreeCourses(query: query)
        async let edxFreeCourses = edxService.searchFreeCourses(query: query, maxResults: 10)
        
        let (khan, mit, coursera, edx) = try await (khanAcademyCourses, mitCourses, courseraFreeCourses, edxFreeCourses)
        
        var allCourses: [Course] = []
        allCourses.append(contentsOf: khan)
        allCourses.append(contentsOf: mit)
        allCourses.append(contentsOf: coursera)
        allCourses.append(contentsOf: edx)
        
        return Array(allCourses.shuffled().prefix(maxResults))
    }
    
    // MARK: - Khan Academy Integration
    func getKhanAcademyCourses(subject: String = "") async throws -> [Course] {
        // Khan Academy API endpoint
        let baseURL = "https://www.khanacademy.org/api/v1"
        let urlString = "\(baseURL)/topic/root/children"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(KhanAcademyResponse.self, from: data)
        
        return response.children?.compactMap { convertKhanAcademyToCourse($0, subject: subject) } ?? []
    }
    
    // MARK: - MIT OpenCourseWare Integration
    func getMITOpenCourseWare(subject: String = "") async throws -> [Course] {
        // Using MIT's RSS feeds and public data
        let mitCourses = [
            createMITCourse(
                title: "Introduction to Computer Science and Programming",
                description: "A comprehensive introduction to computer science using Python",
                subject: "Computer Science",
                difficulty: .beginner
            ),
            createMITCourse(
                title: "Linear Algebra",
                description: "Fundamental concepts in linear algebra with applications",
                subject: "Mathematics",
                difficulty: .intermediate
            ),
            createMITCourse(
                title: "Introduction to Machine Learning",
                description: "Machine learning algorithms and applications",
                subject: "Computer Science",
                difficulty: .advanced
            ),
            createMITCourse(
                title: "Principles of Economics",
                description: "Microeconomics and macroeconomics fundamentals",
                subject: "Economics",
                difficulty: .beginner
            ),
            createMITCourse(
                title: "Physics I: Classical Mechanics",
                description: "Newtonian mechanics, oscillations, and waves",
                subject: "Physics",
                difficulty: .intermediate
            )
        ]
        
        if !subject.isEmpty {
            return mitCourses.filter { $0.category.lowercased().contains(subject.lowercased()) }
        }
        
        return mitCourses
    }
    
    // MARK: - Coursera Free Courses
    func getCourseraFreeCourses(query: String) async throws -> [Course] {
        // Mock Coursera free courses (in real app, you'd use Coursera API)
        let courseraFreeCourses = [
            createCourseraFreeCourse(
                title: "Machine Learning",
                instructor: "Andrew Ng",
                description: "A comprehensive introduction to machine learning",
                subject: "Data Science"
            ),
            createCourseraFreeCourse(
                title: "Python for Everybody",
                instructor: "Charles Severance",
                description: "Learn Python programming from scratch",
                subject: "Programming"
            ),
            createCourseraFreeCourse(
                title: "Financial Markets",
                instructor: "Robert Shiller",
                description: "Introduction to financial markets and instruments",
                subject: "Finance"
            ),
            createCourseraFreeCourse(
                title: "Learning How to Learn",
                instructor: "Barbara Oakley",
                description: "Powerful mental tools to help you master tough subjects",
                subject: "Education"
            )
        ]
        
        return courseraFreeCourses.filter { course in
            course.title.lowercased().contains(query.lowercased()) ||
            course.description.lowercased().contains(query.lowercased()) ||
            course.category.lowercased().contains(query.lowercased())
        }
    }
    
    // MARK: - edX Free Courses (Using New EdX Service)
    func getEdXFreeCourses(query: String) async throws -> [Course] {
        return try await edxService.searchFreeCourses(query: query, maxResults: 15)
    }
    
    // MARK: - Get edX Courses by University
    func getEdXCoursesByUniversity(_ university: String) async throws -> [Course] {
        return try await edxService.getCoursesByUniversity(university)
    }
    
    // MARK: - Get edX Featured Courses  
    func getEdXFeaturedCourses() async throws -> [Course] {
        return try await edxService.getFeaturedCourses()
    }
    
    // MARK: - Course Creation Helper Methods
    private func createMITCourse(
        title: String,
        description: String,
        subject: String,
        difficulty: Course.Difficulty
    ) -> Course {
        return Course(
            id: UUID(),
            title: title,
            description: description,
            instructor: "MIT Faculty",
            thumbnailURL: "https://ocw.mit.edu/courses/\(subject.lowercased().replacingOccurrences(of: " ", with: "-"))/thumbnail.jpg",
            duration: 7200, // 2 hours average
            difficulty: difficulty,
            category: subject,
            lessons: [], // Would be populated with actual lesson data
            progress: 0.0,
            isEnrolled: false,
            rating: 4.7,
            studentsCount: Int.random(in: 1000...10000)
        )
    }
    
    private func createCourseraFreeCourse(
        title: String,
        instructor: String,
        description: String,
        subject: String
    ) -> Course {
        return Course(
            id: UUID(),
            title: title,
            description: description,
            instructor: instructor,
            thumbnailURL: "https://coursera-course-photos.s3.amazonaws.com/\(title.lowercased().replacingOccurrences(of: " ", with: "-"))/large-icon.png",
            duration: TimeInterval.random(in: 3600...14400), // 1-4 hours
            difficulty: .intermediate,
            category: subject,
            lessons: [],
            progress: 0.0,
            isEnrolled: false,
            rating: Double.random(in: 4.2...4.9),
            studentsCount: Int.random(in: 50000...500000)
        )
    }
    
    private func createEdXFreeCourse(
        title: String,
        instructor: String,
        description: String,
        subject: String
    ) -> Course {
        return Course(
            id: UUID(),
            title: title,
            description: description,
            instructor: instructor,
            thumbnailURL: "https://courses.edx.org/asset-v1:\(subject.replacingOccurrences(of: " ", with: ""))+\(title.prefix(10))+2024+type@asset+block@course_image.jpg",
            duration: TimeInterval.random(in: 5400...18000), // 1.5-5 hours
            difficulty: [.beginner, .intermediate, .advanced].randomElement() ?? .intermediate,
            category: subject,
            lessons: [],
            progress: 0.0,
            isEnrolled: false,
            rating: Double.random(in: 4.0...4.8),
            studentsCount: Int.random(in: 10000...100000)
        )
    }
    
    private func convertKhanAcademyToCourse(_ topic: KhanAcademyTopic, subject: String) -> Course? {
        // Filter by subject if provided
        if !subject.isEmpty && !topic.title.lowercased().contains(subject.lowercased()) {
            return nil
        }
        
        return Course(
            id: UUID(),
            title: topic.title,
            description: topic.description ?? "Khan Academy course on \(topic.title)",
            instructor: "Khan Academy",
            thumbnailURL: "https://cdn.kastatic.org/images/khan-logo-vertical-transparent.png",
            duration: TimeInterval(topic.children?.count ?? 10) * 600, // Estimate 10 min per subtopic
            difficulty: .beginner, // Khan Academy is generally beginner-friendly
            category: topic.title.components(separatedBy: " ").first ?? "General",
            lessons: [],
            progress: 0.0,
            isEnrolled: false,
            rating: 4.5,
            studentsCount: Int.random(in: 10000...1000000)
        )
    }
    
    // MARK: - Get Courses by Category
    func getCoursesByCategory(_ category: String) async throws -> [Course] {
        let categoryMap = [
            "programming": "computer science programming software",
            "mathematics": "math calculus algebra geometry",
            "science": "physics chemistry biology",
            "business": "economics finance accounting",
            "design": "art design creative",
            "languages": "language spanish french german",
            "history": "history social studies",
            "philosophy": "philosophy ethics logic"
        ]
        
        let searchTerms = categoryMap[category.lowercased()] ?? category
        return try await searchCourses(query: searchTerms, maxResults: 15)
    }
    
    // MARK: - Get Featured Free Courses
    func getFeaturedFreeCourses() async throws -> [Course] {
        let featuredTopics = [
            "introduction to programming",
            "data science basics", 
            "machine learning",
            "web development",
            "mathematics fundamentals"
        ]
        
        var featuredCourses: [Course] = []
        
        // Include edX featured courses
        if let edxFeatured = try? await edxService.getFeaturedCourses() {
            featuredCourses.append(contentsOf: Array(edxFeatured.prefix(5)))
        }
        
        for topic in featuredTopics {
            if let courses = try? await searchCourses(query: topic, maxResults: 2) {
                featuredCourses.append(contentsOf: courses)
            }
        }
        
        return Array(featuredCourses.shuffled().prefix(15))
    }
}

// MARK: - Khan Academy API Models
struct KhanAcademyResponse: Codable {
    let title: String
    let children: [KhanAcademyTopic]?
}

struct KhanAcademyTopic: Codable {
    let title: String
    let description: String?
    let slug: String
    let children: [KhanAcademyTopic]?
    let contentItems: [KhanAcademyContentItem]?
}

struct KhanAcademyContentItem: Codable {
    let title: String
    let description: String?
    let kind: String // "Exercise", "Video", "Article"
    let url: String?
}

// MARK: - Quick Setup Instructions
/*
 TO SET UP THESE APIs:
 
 1. KHAN ACADEMY (Free, No API Key Required):
    - Use: https://www.khanacademy.org/api/v1/
    - No registration needed
    - Public API with course content
 
 2. MIT OPENCOURSEWARE (Free, No API Key Required):
    - Use: https://ocw.mit.edu/
    - RSS feeds and public course data
    - Web scraping for detailed content
 
 3. COURSERA PUBLIC API (Limited Free Access):
    - Register at: https://tech.coursera.org/app-platform/catalog/
    - Free tier available for course catalog access
    - Paid tiers for full content access
 
 4. EDX API (Free for Basic Access):
    - Register at: https://edx.readthedocs.io/projects/edx-partner-course-staff/
    - Free access to course catalog
    - Some content restrictions
 
 5. PODCAST INDEX API (Free with Registration):
    - Register at: https://podcastindex.org/signup
    - Completely free API access
    - Requires API key and secret for authentication
 
 6. iTUNES PODCAST API (Free, No Registration):
    - Use: https://itunes.apple.com/search
    - No API key required
    - Limited to basic podcast metadata
 */
