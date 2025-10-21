import Foundation
import SwiftUI
import SwiftData

// MARK: - User Data Manager
/// Centralized manager for user data, authentication, and API interactions
@MainActor
class UserDataManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var userPosts: [Post] = []
    @Published var followedUsers: [User] = []
    @Published var followers: [User] = []
    @Published var bookmarkedPosts: [Post] = []
    @Published var courses: [ClassroomCourse] = []
    @Published var studyPrograms: [StudyProgram] = []
    @Published var achievements: [Achievement] = []
    
    // MARK: - Private Properties
    private let apiClient = APIClient.shared
    private let keychain = KeychainHelper()
    
    // MARK: - Singleton
    static let shared = UserDataManager()
    
    private init() {
        loadUserData()
    }
    
    // MARK: - Authentication
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userResponse = try await apiClient.login(email: email, password: password)
            
            // Store auth token (APIClient handles token storage internally)
            // No need to manually store the token as APIClient manages it
            
            // Update user state
            if let user = convertToUser(from: userResponse.user) {
                currentUser = user
                isAuthenticated = true
                saveUserData()
                
                // Load additional user data
                await loadUserDataFromAPI()
            }
            
        } catch {
            print("❌ Sign in failed: \(error)")
            throw error
        }
    }
    
    func signUp(username: String, email: String, password: String, fullName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await apiClient.register(
                email: email,
                password: password,
                username: username,
                fullName: fullName
            )
            
            // Store auth token (handled by APIClient internally)
            // Response is LoginResponse with user property
            let apiUser = response.user
            
            // Update user state
            if let user = convertToUser(from: apiUser) {
                currentUser = user
                isAuthenticated = true
                saveUserData()
            }
            
        } catch {
            print("❌ Sign up failed: \(error)")
            throw error
        }
    }
    
    func signOut() {
        currentUser = nil
        isAuthenticated = false
        userPosts.removeAll()
        followedUsers.removeAll()
        followers.removeAll()
        bookmarkedPosts.removeAll()
        courses.removeAll()
        studyPrograms.removeAll()
        achievements.removeAll()
        
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: "currentUser")
        _ = keychain.delete(service: "LyoApp", account: "authToken")
    }
    
    // MARK: - Data Loading
    private func loadUserDataFromAPI() async {
        guard isAuthenticated, let _ = currentUser?.id.uuidString else {
            print("⚠️ Cannot load user data - not authenticated")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load user profile from API - using getCurrentUser instead
            let currentUserProfile = try await apiClient.getCurrentUser()
            await MainActor.run {
                // Convert UserProfile to User model
                if let updatedUser = self.convertProfileToUser(from: currentUserProfile) {
                    self.currentUser = updatedUser
                    self.saveUserData()
                }
            }
            
            // Note: getUserPosts method not available in APIClient
            // Using mock data for now
            await MainActor.run {
                self.userPosts = [] // TODO: Implement when API is available
            }
            
            // Load other user data concurrently
            async let followingTask: () = loadFollowingUsers()
            async let followersTask: () = loadFollowers()
            async let coursesTask: () = loadCourses()
            
            // Wait for all tasks to complete
            _ = await (followingTask, followersTask, coursesTask)
            
        } catch {
            print("❌ Failed to load user data: \(error)")
        }
    }
    
    // MARK: - Data Conversion
        private func convertToUser(from apiUser: APINamespace.APIUser) -> User? {
        guard let id = UUID(uuidString: apiUser.id) else { return nil }
        
        return User(
            id: id,
            username: apiUser.username ?? "",
            email: apiUser.email,
            fullName: apiUser.name,
            bio: apiUser.bio ?? "",
            profileImageURL: apiUser.avatarUrl != nil ? URL(string: apiUser.avatarUrl!) : nil,
            followers: 0, // Not available in the namespaced APIUser
            following: 0, // Not available in the namespaced APIUser
            isVerified: false, // Not available in the namespaced APIUser
            joinedAt: Date(), // Use current date as fallback
            lastActiveAt: Date()
        )
    }
    
    private func convertProfileToUser(from userProfile: UserProfile) -> User? {
        guard let id = UUID(uuidString: userProfile.id) else { return nil }
        
        return User(
            id: id,
            username: userProfile.username,
            email: userProfile.email,
            fullName: userProfile.fullName,
            bio: userProfile.bio,
            profileImageURL: userProfile.profileImageUrl != nil ? URL(string: userProfile.profileImageUrl!) : nil,
            followers: 0, // Not available in UserProfile
            following: 0, // Not available in UserProfile
            posts: 0, // Not available in UserProfile
            joinedAt: Date(), // Use current date as fallback
            experience: 0,
            level: 1
        )
    }
    
    private func convertToPost(from feedPost: FeedPost) -> Post? {
        // Create a basic author user from the post data
        let author = User(
            id: UUID(uuidString: feedPost.userId) ?? UUID(),
            username: feedPost.username,
            email: "", // Not available in FeedPost
            fullName: feedPost.username, // Use username as fallName
            bio: "",
            profileImageURL: feedPost.userAvatar
        )
        
        // Convert FeedPost to Post (fixed constructor call)
        return Post(
            id: UUID(uuidString: feedPost.id) ?? UUID(),
            author: author,
            content: feedPost.content,
            imageURLs: feedPost.imageURLs ?? [], // Use imageURLs instead of mediaURL
            videoURL: feedPost.videoURL, // Use videoURL instead of mediaURL
            likes: feedPost.likesCount,
            comments: feedPost.commentsCount,
            shares: feedPost.sharesCount,
            isLiked: feedPost.isLiked,
            isBookmarked: feedPost.isBookmarked,
            createdAt: ISO8601DateFormatter().date(from: feedPost.createdAt) ?? Date(),
            tags: feedPost.tags
        )
    }
    
    private func convertToCourse(from apiCourse: APICourse) -> ClassroomCourse? {
        guard let id = UUID(uuidString: apiCourse.id) else { return nil }

        let level: LearningLevel = {
            let raw = apiCourse.difficulty.lowercased()
            switch raw {
            case "beginner": return .beginner
            case "intermediate": return .intermediate
            case "advanced": return .advanced
            case "expert": return .expert
            default: return .beginner
            }
        }()

        let schedule: Schedule = {
            let minutes = max(apiCourse.duration, 60)
            let minutesPerDay = max(30, min(180, minutes / max(1, 5)))
            return Schedule(minutesPerDay: minutesPerDay, daysPerWeek: 5)
        }()

        let pedagogy = Pedagogy(
            style: .examplesFirst,
            preferVideo: true,
            preferText: !apiCourse.description.isEmpty,
            preferInteractive: true,
            pace: .moderate
        )

    let createdAt = ISO8601DateFormatter().date(from: apiCourse.createdAt) ?? Date()

        return ClassroomCourse(
            id: id,
            title: apiCourse.title,
            description: apiCourse.description,
            scope: apiCourse.description.isEmpty ? "Comprehensive learning path" : apiCourse.description,
            level: level,
            outcomes: apiCourse.tags ?? [],
            schedule: schedule,
            pedagogy: pedagogy,
            assessments: [AssessmentType.quiz],
            resourcesEnabled: true,
            modules: [],
            coverImageURL: apiCourse.thumbnailURL,
            estimatedDuration: apiCourse.duration,
            createdAt: createdAt
        )
    }
    
    // MARK: - Course Management
    func loadCourses() async {
        guard isAuthenticated else { return }
        
        // TODO: Implement getCourses API method
        // let response = try await apiClient.getCourses()
        // let converted: [Course] = response.courses.compactMap { convertToCourse(from: $0) }
        await MainActor.run { self.courses = [] }
    }
    
    func enrollInCourse(courseId: String) async throws {
        guard isAuthenticated else { throw APIError.unauthorized }
        
        // Note: enrollInCourse method not available in APIClient
        // Using mock enrollment for now
        await MainActor.run {
            print("✅ Mock enrollment in course: \(courseId)")
            // TODO: Implement when API is available
        }
    }
    
    // Note: getCourseProgress method doesn't exist in APIClient, so commenting it out
    /*
    func getCourseProgress(courseId: String) async throws -> CourseProgress? {
        guard isAuthenticated else { throw APIError.unauthorized }
        
        do {
            let response = try await apiClient.getCourseProgress(courseId)
            return response.progress
        } catch {
            print("❌ Failed to get course progress: \(error)")
            throw error
        }
    }
    */
    
    // MARK: - Study Programs
    func loadStudyPrograms() async {
        guard isAuthenticated else { return }
        
        // TODO: Implement getStudyPrograms API method
        // let response = try await apiClient.getStudyPrograms()
        await MainActor.run { self.studyPrograms = [] }
    }
    
    // TODO: implement convertToStudyProgram when APIStudyProgram model stabilized
    
    // MARK: - Posts Management
    func createPost(content: String, imageURLs: [String] = [], videoURL: String? = nil) async throws {
        guard isAuthenticated else { throw APIError.unauthorized }
        
        // Note: createPost method not available in APIClient
        // Using mock post creation for now
        await MainActor.run {
            print("✅ Mock post created with content: \(content)")
            // TODO: Implement when API is available
        }
    }
    
    // MARK: - Following Management
    func followUser(userId: String) async throws {
        guard isAuthenticated else { throw APIError.unauthorized }
        
        // Note: followUser method not available in APIClient
        // Using mock follow for now
        await MainActor.run {
            print("✅ Mock follow user: \(userId)")
            // TODO: Implement when API is available
        }
    }
    
    func unfollowUser(userId: String) async throws {
        guard isAuthenticated else { throw APIError.unauthorized }
        
        // Note: unfollowUser method not available in APIClient
        // Using mock unfollow for now
        await MainActor.run {
            print("✅ Mock unfollow user: \(userId)")
            // TODO: Implement when API is available
        }
    }
    
    private func loadFollowingUsers() async {
        // Implementation depends on available API endpoints
    }
    
    private func loadFollowers() async {
        // Implementation depends on available API endpoints
    }
    
    // MARK: - Data Persistence
    private func loadUserData() {
        if let userData = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isAuthenticated = true
        }
    }
    
    private func saveUserData() {
        if let user = currentUser,
           let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: "currentUser")
        }
    }
}

// MARK: - Helper Extensions
extension UserDataManager {
    var isCurrentUserVerified: Bool {
        currentUser?.isVerified ?? false
    }
    
    var currentUserFollowersCount: Int {
        currentUser?.followers ?? 0
    }
    
    var currentUserFollowingCount: Int {
        currentUser?.following ?? 0
    }
}
