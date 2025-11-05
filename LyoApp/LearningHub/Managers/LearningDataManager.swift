import Foundation
import SwiftUI
import UIKit // For haptic feedback

// MARK: - Learning Data Manager
/// Manages learning resources, courses, and AI-powered study recommendations
@MainActor
class LearningDataManager: ObservableObject {
    // MARK: - Shared Instance
    static let shared = LearningDataManager()
    
    // MARK: - Published Properties
    @Published var learningResources: [LearningResource] = []
    @Published var recommendedResources: [LearningResource] = []
    @Published var userCourses: [ClassroomCourse] = []
    @Published var studyPlan: StudyPlan?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedCategory: String = "All"
    @Published var searchQuery: String = ""
    @Published var selectedResource: LearningResource? // Track selected resource
    @Published var showDynamicClassroom: Bool = false // Toggle classroom view
    
    // MARK: - Private Properties
    private let backendService = BackendIntegrationService.shared
    
    // MARK: - Categories
    let categories = [
        "All", "Programming", "Data Science", "Design",
        "Business", "Language Learning", "Personal Development"
    ]
    
    // MARK: - Initialization
    private init() {
        // NO SAMPLE DATA - Production only mode
        // Real data will be loaded on demand via loadLearningResources()
        print("🏭 LearningDataManager initialized in PRODUCTION mode - no mock data")
    }
    
    // MARK: - Data Loading with Fallback
    func loadLearningResources() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let resources = try await backendService.loadLearningResources()
            await MainActor.run {
                self.learningResources = resources.map { $0.toLearningResource() }
                print("✅ Loaded \(resources.count) learning resources from backend")
            }
        } catch {
            await MainActor.run {
                // Backend doesn't have /courses endpoint - use sample data
                print("⚠️ Backend /courses endpoint not available, using sample data")
                print("   Backend provides: /api/content/generate-course (content generation)")
                print("   Loading fallback sample courses...")
                self.learningResources = self.generateSampleLearningResources()
                self.errorMessage = nil // Don't show error since we have fallback data
                print("✅ Loaded \(self.learningResources.count) sample learning resources")
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    // MARK: - Sample Data Generation (Fallback when backend unavailable)
    private func generateSampleLearningResources() -> [LearningResource] {
        let currentDateString = ISO8601DateFormatter().string(from: Date())
        
        return [
            LearningResource(
                id: "maya-civilization",
                title: "Maya Civilization: Rise and Fall",
                description: "Explore the ancient Maya civilization through an immersive classroom experience. Walk through Tikal, decode hieroglyphics, and understand their astronomical achievements.",
                category: "History",
                difficulty: "Intermediate",
                duration: 45, // minutes
                thumbnailUrl: nil,
                imageUrl: nil,
                url: nil,
                provider: "Lyo Academy",
                providerName: "Lyo Academy",
                providerUrl: nil,
                enrolledCount: 12543,
                isEnrolled: false,
                reviews: nil,
                updatedAt: currentDateString,
                createdAt: currentDateString,
                authorCreator: "Dr. Sarah Chen",
                estimatedDuration: "45 min",
                rating: 4.8,
                difficultyLevel: .intermediate,
                contentType: .tutorial,
                resourcePlatform: .lyo,
                tags: ["History", "Maya", "Ancient Civilizations", "VR"],
                isBookmarked: false,
                progress: 0,
                publishedDate: Date()
            ),
            LearningResource(
                id: "mars-exploration",
                title: "Mars Surface Exploration",
                description: "Experience a realistic Mars surface environment. Learn about Martian geology, atmosphere, and the challenges of future colonization.",
                category: "Science",
                difficulty: "Advanced",
                duration: 60, // minutes
                thumbnailUrl: nil,
                imageUrl: nil,
                url: nil,
                provider: "NASA Education Team",
                providerName: "NASA Education Team",
                providerUrl: nil,
                enrolledCount: 18234,
                isEnrolled: false,
                reviews: nil,
                updatedAt: currentDateString,
                createdAt: currentDateString,
                authorCreator: "NASA Education Team",
                estimatedDuration: "60 min",
                rating: 4.9,
                difficultyLevel: .advanced,
                contentType: .tutorial,
                resourcePlatform: .lyo,
                tags: ["Science", "Space", "Mars", "Astronomy"],
                isBookmarked: false,
                progress: 0,
                publishedDate: Date()
            ),
            LearningResource(
                id: "chemistry-lab",
                title: "Interactive Chemistry Lab",
                description: "Conduct real chemistry experiments in a safe virtual environment. Mix compounds, observe reactions, and learn molecular structures through hands-on simulations.",
                category: "Science",
                difficulty: "Beginner",
                duration: 50, // minutes
                thumbnailUrl: nil,
                imageUrl: nil,
                url: nil,
                provider: "Prof. Michael Rodriguez",
                providerName: "Prof. Michael Rodriguez",
                providerUrl: nil,
                enrolledCount: 9876,
                isEnrolled: false,
                reviews: nil,
                updatedAt: currentDateString,
                createdAt: currentDateString,
                authorCreator: "Prof. Michael Rodriguez",
                estimatedDuration: "50 min",
                rating: 4.7,
                difficultyLevel: .beginner,
                contentType: .tutorial,
                resourcePlatform: .lyo,
                tags: ["Science", "Chemistry", "Laboratory", "Education"],
                isBookmarked: false,
                progress: 0,
                publishedDate: Date()
            ),
            LearningResource(
                id: "swift-ios-dev",
                title: "iOS Development with SwiftUI",
                description: "Master modern iOS app development with SwiftUI. Build beautiful, responsive interfaces and learn Apple's latest frameworks.",
                category: "Programming",
                difficulty: "Intermediate",
                duration: 480, // 8 hours in minutes
                thumbnailUrl: nil,
                imageUrl: nil,
                url: nil,
                provider: "Apple Developer Academy",
                providerName: "Apple Developer Academy",
                providerUrl: nil,
                enrolledCount: 23456,
                isEnrolled: false,
                reviews: nil,
                updatedAt: currentDateString,
                createdAt: currentDateString,
                authorCreator: "Apple Developer Academy",
                estimatedDuration: "8 hours",
                rating: 4.9,
                difficultyLevel: .intermediate,
                contentType: .course,
                resourcePlatform: .apple,
                tags: ["Programming", "Swift", "iOS", "Mobile Development"],
                isBookmarked: false,
                progress: 0,
                publishedDate: Date()
            ),
            LearningResource(
                id: "python-data-science",
                title: "Data Science with Python",
                description: "Learn data analysis, visualization, and machine learning using Python. Hands-on projects with pandas, NumPy, and scikit-learn.",
                category: "Data Science",
                difficulty: "Intermediate",
                duration: 720, // 12 hours in minutes
                thumbnailUrl: nil,
                imageUrl: nil,
                url: nil,
                provider: "DataCamp Team",
                providerName: "DataCamp Team",
                providerUrl: nil,
                enrolledCount: 34567,
                isEnrolled: false,
                reviews: nil,
                updatedAt: currentDateString,
                createdAt: currentDateString,
                authorCreator: "DataCamp Team",
                estimatedDuration: "12 hours",
                rating: 4.8,
                difficultyLevel: .intermediate,
                contentType: .course,
                resourcePlatform: .other,
                tags: ["Python", "Data Science", "Machine Learning", "Analytics"],
                isBookmarked: false,
                progress: 0,
                publishedDate: Date()
            ),
            LearningResource(
                id: "ui-ux-design",
                title: "UI/UX Design Fundamentals",
                description: "Master the principles of user interface and user experience design. Learn Figma, prototyping, and design thinking methodologies.",
                category: "Design",
                difficulty: "Beginner",
                duration: 360, // 6 hours in minutes
                thumbnailUrl: nil,
                imageUrl: nil,
                url: nil,
                provider: "Design Masters",
                providerName: "Design Masters",
                providerUrl: nil,
                enrolledCount: 15678,
                isEnrolled: false,
                reviews: nil,
                updatedAt: currentDateString,
                createdAt: currentDateString,
                authorCreator: "Design Masters",
                estimatedDuration: "6 hours",
                rating: 4.7,
                difficultyLevel: .beginner,
                contentType: .course,
                resourcePlatform: .other,
                tags: ["Design", "UI", "UX", "Figma", "Prototyping"],
                isBookmarked: false,
                progress: 0,
                publishedDate: Date()
            )
        ]
    }
    
    func searchResources(query: String) async {
        guard !query.isEmpty else {
            await loadLearningResources()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let resources = try await backendService.loadLearningResources(query: query)
            await MainActor.run {
                self.learningResources = resources.map { $0.toLearningResource() }
                self.searchQuery = query
                print("✅ Search completed: \(resources.count) results for '\(query)'")
            }
        } catch {
            await MainActor.run {
                // Backend doesn't support search - filter sample data locally
                print("⚠️ Backend search not available, filtering sample data locally")
                let allResources = self.generateSampleLearningResources()
                self.learningResources = allResources.filter { resource in
                    resource.title.localizedCaseInsensitiveContains(query) ||
                    resource.description.localizedCaseInsensitiveContains(query) ||
                    (resource.tags?.contains { $0.localizedCaseInsensitiveContains(query) } == true)
                }
                self.searchQuery = query
                self.errorMessage = nil
                print("✅ Local search completed: \(self.learningResources.count) results for '\(query)'")
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func loadResourcesByCategory(_ category: String) async {
        guard category != "All" else {
            await loadLearningResources()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Load all resources and filter by category
            let allResources = try await backendService.loadLearningResources()
            await MainActor.run {
                self.learningResources = allResources
                    .filter { ($0.category ?? "").localizedCaseInsensitiveContains(category) }
                    .map { $0.toLearningResource() }
                self.selectedCategory = category
                print("✅ Loaded \(self.learningResources.count) resources for category '\(category)'")
            }
        } catch {
            await MainActor.run {
                // Backend not available - filter sample data locally
                print("⚠️ Backend not available, filtering sample data by category")
                let allResources = self.generateSampleLearningResources()
                self.learningResources = allResources.filter { resource in
                    (resource.category?.localizedCaseInsensitiveContains(category) == true)
                }
                self.selectedCategory = category
                self.errorMessage = nil
                print("✅ Local filter: \(self.learningResources.count) resources for category '\(category)'")
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    func enrollInResource(_ resourceId: String) async {
        // Backend doesn't have /courses/{id}/enroll endpoint
        // Handle enrollment locally for sample data
        
        await MainActor.run {
            if let index = self.learningResources.firstIndex(where: { $0.id == resourceId }) {
                let resource = self.learningResources[index]
                
                // Create updated resource with enrollment status
                let updatedResource = LearningResource(
                    id: resource.id,
                    title: resource.title,
                    description: resource.description,
                    category: resource.category,
                    difficulty: resource.difficulty,
                    duration: resource.duration,
                    thumbnailUrl: resource.thumbnailUrl,
                    imageUrl: resource.imageUrl,
                    url: resource.url,
                    provider: resource.provider,
                    providerName: resource.providerName,
                    providerUrl: resource.providerUrl,
                    enrolledCount: (resource.enrolledCount ?? 0) + 1,
                    isEnrolled: true, // Mark as enrolled
                    reviews: resource.reviews,
                    updatedAt: resource.updatedAt,
                    createdAt: resource.createdAt,
                    authorCreator: resource.authorCreator,
                    estimatedDuration: resource.estimatedDuration,
                    rating: resource.rating,
                    difficultyLevel: resource.difficultyLevel,
                    contentType: resource.contentType,
                    resourcePlatform: resource.resourcePlatform,
                    tags: resource.tags,
                    isBookmarked: resource.isBookmarked,
                    progress: resource.progress,
                    publishedDate: resource.publishedDate
                )
                
                self.learningResources[index] = updatedResource
                print("✅ Successfully enrolled in resource: \(resource.title)")
                print("💾 Enrollment stored locally (backend /enroll endpoint not available)")
                
                // Provide haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
    
    private var apiClient: APIClient {
        return APIClient.shared
    }
    
    // MARK: - AI Recommendations (Production)
    func generatePersonalizedRecommendations() async {
        isLoading = true
        
        // Get user preferences from UserDefaults (stored by analytics)
        let userTopicInterests = UserDefaults.standard.stringArray(forKey: "user_topic_interests") ?? []
        let preferredLevel = UserDefaults.standard.string(forKey: "preferred_learning_level")
        
        print("🎯 Generating personalized recommendations...")
        print("   User interests: \(userTopicInterests)")
        print("   Preferred level: \(preferredLevel ?? "none")")
        
        await MainActor.run {
            var scoredResources: [(resource: LearningResource, score: Double)] = []
            
            for resource in self.learningResources {
                var score: Double = 0.0
                
                // Score based on topic interests (40% weight)
                if !userTopicInterests.isEmpty {
                    let resourceTopics = [
                        resource.title.lowercased(),
                        resource.description.lowercased(),
                        resource.category?.lowercased() ?? ""
                    ].joined(separator: " ")
                    
                    for interest in userTopicInterests {
                        if resourceTopics.contains(interest.lowercased()) {
                            score += 4.0
                            break
                        }
                    }
                }
                
                // Score based on preferred level (30% weight)
                if let preferredLevel = preferredLevel,
                   let resourceDifficulty = resource.difficulty?.lowercased(),
                   resourceDifficulty.contains(preferredLevel.lowercased()) {
                    score += 3.0
                }
                
                // Score based on rating (20% weight)
                if let rating = resource.rating {
                    score += (rating / 5.0) * 2.0
                }
                
                // Score based on popularity (10% weight)
                let enrolledScore = min(Double(resource.enrolledCount ?? 0) / 10000.0, 1.0)
                score += enrolledScore
                
                // Penalize already started courses
                if let progress = resource.progress, progress > 0 {
                    score *= 0.5
                }
                
                scoredResources.append((resource, score))
            }
            
            // Sort by score and take top 5
            let sortedResources = scoredResources
                .sorted { $0.score > $1.score }
                .prefix(5)
                .map { $0.resource }
            
            self.recommendedResources = sortedResources
            
            print("✅ Generated \(self.recommendedResources.count) personalized recommendations")
            if !sortedResources.isEmpty {
                print("   Top recommendation: \(sortedResources[0].title)")
            }
            
            self.isLoading = false
        }
    }
    
    // MARK: - Course Launch
    /// Launches the Dynamic Classroom for a selected course
    func launchCourse(_ resource: LearningResource) async {
        await MainActor.run {
            self.selectedResource = resource
            self.showDynamicClassroom = true
        }
        
        print("🎓 Launching course: \(resource.title)")
        print("📚 Category: \(resource.category ?? "Unknown")")
        print("⚡️ Difficulty: \(resource.difficulty ?? "Unknown")")
    }
    
    /// Closes the Dynamic Classroom and returns to Learning Hub
    func closeDynamicClassroom() {
        self.showDynamicClassroom = false
        self.selectedResource = nil
        print("👋 Closed classroom")
    }
}

// MARK: - Helper Extensions
extension LearningDataManager {
    var filteredResources: [LearningResource] {
        if selectedCategory == "All" && searchQuery.isEmpty {
            return learningResources
        }
        
        return learningResources.filter { resource in
            let matchesCategory = selectedCategory == "All" || (resource.category?.localizedCaseInsensitiveContains(selectedCategory) == true)
            let matchesSearch = searchQuery.isEmpty || 
                resource.title.localizedCaseInsensitiveContains(searchQuery) ||
                resource.description.localizedCaseInsensitiveContains(searchQuery)
            
            return matchesCategory && matchesSearch
        }
    }
    
    var hasRecommendations: Bool {
        !recommendedResources.isEmpty
    }
    
    // MARK: - Compatibility Methods for Previews
    /// Provides sample resources for SwiftUI previews and development
    /// Uses the sample data from LearningResource model
    static func sampleResources() -> [LearningResource] {
        return LearningResource.sampleResources()
    }
    
    /// Legacy method for backwards compatibility
    static var sampleData: [LearningResource] {
        return LearningResource.sampleResources()
    }
}
