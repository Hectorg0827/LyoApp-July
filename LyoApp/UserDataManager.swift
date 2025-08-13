import SwiftUI
import Foundation
import CoreData

/// Centralized user data management with simplified UserDefaults persistence
@MainActor
class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var userPosts: [Post] = []
    @Published var userCourses: [Course] = []
    @Published var userBadges: [UserBadge] = []
    @Published var followers: [User] = []
    @Published var following: [User] = []
    @Published var isLoading = false
    @Published var educationalVideos: [EducationalVideo] = []
    @Published var ebooks: [Ebook] = []
    @Published var stories: [Story] = []
    @Published var communities: [Community] = []
    @Published var discoverContent: [DiscoverContent] = []
    
    // MARK: - Storage Keys
    private struct StorageKeys {
        static let currentUser = "currentUser"
        static let userPosts = "userPosts"
        static let userCourses = "userCourses"
        static let userBadges = "userBadges"
        static let lastSyncDate = "lastSyncDate"
    }
    
    private init() {
        loadUserData()
        generateSampleData()
        
        // Integrate real content for market readiness
        integrateRealContent()
    }
    
    // MARK: - Real Content Integration
    
    /// Integrate real educational content for market readiness
    private func integrateRealContent() {
        let realContentService = RealContentService.shared
        realContentService.integrateWithUserDataManager()
        
        // Update with real content
        if realContentService.validateContentIntegrity() {
            self.userCourses = Array(realContentService.realCourses.prefix(3))
            self.educationalVideos = realContentService.realEducationalVideos
            self.ebooks = realContentService.realEbooks
            
            print("✅ Real content integrated successfully")
            print("📊 Content stats: \(realContentService.contentStatistics)")
        }
    }
    
    // MARK: - User Management
    
    /// Save user and update authentication state
    func saveUser(_ user: User) {
        self.currentUser = user
        self.isAuthenticated = true
        saveUserData()
        AnalyticsManager.shared.trackUserAction("login")
    }
    
    /// Load user from persistent storage
    private func loadUser() -> User? {
        guard let userData = UserDefaults.standard.data(forKey: StorageKeys.currentUser),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            return nil
        }
        return user
    }
    
    /// Logout user and clear data
    func logout() {
        currentUser = nil
        isAuthenticated = false
        userPosts = []
        userCourses = []
        userBadges = []
        followers = []
        following = []
        
        // Clear stored data
        UserDefaults.standard.removeObject(forKey: StorageKeys.currentUser)
        UserDefaults.standard.removeObject(forKey: StorageKeys.userPosts)
        UserDefaults.standard.removeObject(forKey: StorageKeys.userCourses)
        UserDefaults.standard.removeObject(forKey: StorageKeys.userBadges)
        
        AnalyticsManager.shared.trackUserAction("logout")
    }
    
    // MARK: - Course Management
    
    /// Get all available courses
    func getCourses() -> [Course] {
        if userCourses.isEmpty {
            loadCourses()
        }
        return userCourses
    }
    
    /// Enroll user in a course
    func enrollInCourse(_ course: Course) {
        if !userCourses.contains(where: { $0.id == course.id }) {
            userCourses.append(course)
            saveUserData()
            AnalyticsManager.shared.trackUserAction("courseEnrollment")
        }
    }
    
    /// Get user progress for a specific course
    func getUserProgress(for courseId: UUID) -> Double {
        // Return mock progress for now
        return Double.random(in: 0...1)
    }
    
    // MARK: - Social Features
    
    /// Get user posts
    func getUserPosts() -> [Post] {
        // TODO: Implement real user posts loading from persistent storage
        // For now, return empty array until real data management is implemented
        return userPosts
    }
    
    /// Add a new post
    func addPost(_ post: Post) {
        userPosts.insert(post, at: 0)
        saveUserData()
        AnalyticsManager.shared.trackUserAction("postCreated")
    }
    
    /// Follow a user
    func followUser(_ user: User) {
        if !following.contains(where: { $0.id == user.id }) {
            following.append(user)
            saveUserData()
            AnalyticsManager.shared.trackUserAction("userFollowed")
        }
    }
    
    /// Unfollow a user
    func unfollowUser(_ user: User) {
        following.removeAll { $0.id == user.id }
        saveUserData()
        AnalyticsManager.shared.trackUserAction("userUnfollowed")
    }
    
    // MARK: - Educational Content
    
    /// Get educational videos
    func getEducationalVideos() -> [EducationalVideo] {
        if educationalVideos.isEmpty {
            loadEducationalVideos()
        }
        return educationalVideos
    }
    
    /// Get ebooks
    func getEbooks() -> [Ebook] {
        if ebooks.isEmpty {
            loadEbooks()
        }
        return ebooks
    }
    
    /// Get user stories
    func getUserStories() -> [Story] {
        // TODO: Implement real user stories loading from persistent storage
        // For now, return empty array until real data management is implemented
        return stories
    }
    
    /// Get communities
    func getCommunities() -> [Community] {
        // TODO: Implement real communities loading from persistent storage
        // For now, return empty array until real data management is implemented
        return communities
    }
    
    /// Get discover content
    func getDiscoverContent() -> [DiscoverContent] {
        // TODO: Implement real discover content loading from persistent storage
        // For now, return empty array until real data management is implemented
        return discoverContent
    }
    
    // MARK: - User Stats and Achievements
    
    /// Get user statistics
    func getUserStats() -> UserStats {
        return UserStats(
            coursesCompleted: userCourses.filter { getUserProgress(for: $0.id) >= 1.0 }.count,
            totalWatchTime: Int.random(in: 60...500),
            streakDays: Int.random(in: 1...30),
            badgesEarned: userBadges.count
        )
    }
    
    /// Get user badges
    func getUserBadges() -> [UserBadge] {
        if userBadges.isEmpty {
            loadUserBadges()
        }
        return userBadges
    }
    
    /// Award badge to user
    func awardBadge(_ badge: UserBadge) {
        if !userBadges.contains(where: { $0.id == badge.id }) {
            userBadges.append(badge)
            saveUserData()
            AnalyticsManager.shared.trackUserAction("badgeEarned")
        }
    }
    
    // MARK: - Authentication Management
    
    /// Set the current authenticated user
    func setCurrentUser(_ user: User) {
        currentUser = user
        isAuthenticated = true
        saveUserData()
    }
    
    /// Clear user data and log out
    func clearUserData() {
        logout()
    }
    
    // MARK: - Data Persistence
    
    private func loadUserData() {
        let userDefaults = UserDefaults.standard
        
        // Load current user
        if let userData = userDefaults.data(forKey: StorageKeys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
            isAuthenticated = true
        }
        
        // Load user posts
        if let postsData = userDefaults.data(forKey: StorageKeys.userPosts),
           let posts = try? JSONDecoder().decode([Post].self, from: postsData) {
            userPosts = posts
        }
        
        // Load user courses
        if let coursesData = userDefaults.data(forKey: StorageKeys.userCourses),
           let courses = try? JSONDecoder().decode([Course].self, from: coursesData) {
            userCourses = courses
        }
        
        // Load user badges
        if let badgesData = userDefaults.data(forKey: StorageKeys.userBadges),
           let badges = try? JSONDecoder().decode([UserBadge].self, from: badgesData) {
            userBadges = badges
        }
    }
    
    private func saveUserData() {
        let userDefaults = UserDefaults.standard
        
        // Save current user
        if let currentUser = currentUser,
           let userData = try? JSONEncoder().encode(currentUser) {
            userDefaults.set(userData, forKey: StorageKeys.currentUser)
        }
        
        // Save user posts
        if let postsData = try? JSONEncoder().encode(userPosts) {
            userDefaults.set(postsData, forKey: StorageKeys.userPosts)
        }
        
        // Save user courses
        if let coursesData = try? JSONEncoder().encode(userCourses) {
            userDefaults.set(coursesData, forKey: StorageKeys.userCourses)
        }
        
        // Save user badges
        if let badgesData = try? JSONEncoder().encode(userBadges) {
            userDefaults.set(badgesData, forKey: StorageKeys.userBadges)
        }
        
        userDefaults.set(Date(), forKey: StorageKeys.lastSyncDate)
    }
    
    // MARK: - Sample Data Generation
    
    private func generateSampleData() {
        // Temporarily disabled to fix compilation issues
        // TODO: Re-implement with correct model signatures
        /*
        if educationalVideos.isEmpty {
            loadEducationalVideos()
        }
        if ebooks.isEmpty {
            loadEbooks()
        }
        if stories.isEmpty {
            loadUserStories()
        }
        if communities.isEmpty {
            loadCommunities()
        }
        if discoverContent.isEmpty {
            loadDiscoverContent()
        }
        if userCourses.isEmpty {
            loadCourses()
        }
        if userBadges.isEmpty {
            loadUserBadges()
        }
        */
    }
    
    private func loadCourses() {
        userCourses = [
            Course(
                id: UUID(),
                title: "SwiftUI Fundamentals",
                description: "Learn the basics of SwiftUI",
                instructor: "John Doe",
                thumbnailURL: "course1",
                duration: 120,
                difficulty: .beginner,
                category: "Programming",
                lessons: [],
                progress: 0.0,
                isEnrolled: true,
                rating: 4.8,
                studentsCount: 1500
            ),
            Course(
                id: UUID(),
                title: "Advanced iOS Development",
                description: "Master advanced iOS concepts",
                instructor: "Jane Smith",
                thumbnailURL: "course2",
                duration: 180,
                difficulty: .advanced,
                category: "Programming",
                lessons: [],
                progress: 0.0,
                isEnrolled: false,
                rating: 4.9,
                studentsCount: 800
            )
        ]
    }
    
    private func loadEducationalVideos() {
        educationalVideos = [
            EducationalVideo(
                id: UUID(),
                title: "Introduction to SwiftUI",
                description: "Basic SwiftUI concepts",
                thumbnailURL: "video1_thumb",
                videoURL: "video1.mp4",
                duration: 900,
                instructor: "John Doe",
                category: "Programming",
                difficulty: .beginner,
                tags: ["SwiftUI", "iOS"],
                rating: 4.5,
                viewCount: 1500,
                isBookmarked: false,
                watchProgress: 0.0,
                publishedDate: Date()
            ),
            EducationalVideo(
                id: UUID(),
                title: "Core Data in SwiftUI",
                description: "Data persistence with Core Data",
                thumbnailURL: "video2_thumb",
                videoURL: "video2.mp4",
                duration: 1200,
                instructor: "Jane Smith",
                category: "Programming",
                difficulty: .intermediate,
                tags: ["Core Data", "SwiftUI"],
                rating: 4.7,
                viewCount: 1200,
                isBookmarked: false,
                watchProgress: 0.0,
                publishedDate: Date()
            )
        ]
    }
    
    private func loadEbooks() {
        ebooks = [
            Ebook(
                id: UUID(),
                title: "Swift Programming Guide",
                author: "Apple Inc.",
                description: "Complete guide to Swift programming",
                coverImageURL: "book1_cover",
                pdfURL: "book1.pdf",
                category: "Programming",
                pages: 250,
                fileSize: "15.2 MB",
                rating: 4.6,
                downloadCount: 500,
                isBookmarked: false,
                readProgress: 0.0,
                publishedDate: Date()
            ),
            Ebook(
                id: UUID(),
                title: "iOS App Development",
                author: "Ray Wenderlich",
                description: "Comprehensive iOS development guide",
                coverImageURL: "book2_cover",
                pdfURL: "book2.pdf",
                category: "Programming",
                pages: 400,
                fileSize: "22.8 MB",
                rating: 4.8,
                downloadCount: 750,
                isBookmarked: false,
                readProgress: 0.0,
                publishedDate: Date()
            )
        ]
    }
    
    /*
    private func loadUserStories() {
        stories = [
            Story(
                id: "story1",
                userId: "user1",
                content: "Just completed my first SwiftUI course!",
                mediaURL: "story1_image",
                timestamp: Date(),
                expiresAt: Date().addingTimeInterval(86400)
            ),
            Story(
                id: "story2",
                userId: "user2",
                content: "Working on a new iOS app project",
                mediaURL: "story2_image",
                timestamp: Date().addingTimeInterval(-3600),
                expiresAt: Date().addingTimeInterval(82800)
            )
        ]
    }
    */
    
    /*
    private func loadCommunities() {
        communities = [
            Community(
                id: "community1",
                name: "iOS Developers",
                description: "Community for iOS developers",
                imageURL: "ios_community",
                memberCount: 15000,
                isJoined: true,
                category: "Programming"
            ),
            Community(
                id: "community2",
                name: "SwiftUI Enthusiasts",
                description: "Share SwiftUI tips and tricks",
                imageURL: "swiftui_community",
                memberCount: 8500,
                isJoined: false,
                category: "Programming"
            )
        ]
    }
    */
    
    /*
    private func loadDiscoverContent() {
        discoverContent = [
            DiscoverContent(
                id: "discover1",
                title: "Trending iOS Libraries",
                description: "Popular Swift libraries this month",
                imageURL: "trending_libs",
                contentType: .article,
                category: "Programming"
            ),
            DiscoverContent(
                id: "discover2",
                title: "WWDC 2024 Highlights",
                description: "Key announcements from WWDC",
                imageURL: "wwdc_highlights",
                contentType: .video,
                category: "News"
            )
        ]
    }
    */
    
    /*
    private func loadUserPosts() {
        userPosts = [
            Post(
                id: "post1",
                userId: "user1",
                content: "Just finished an amazing SwiftUI course!",
                imageURL: "post1_image",
                timestamp: Date(),
                likes: 45,
                comments: 12,
                shares: 5
            ),
            Post(
                id: "post2",
                userId: "user2",
                content: "Building my first iOS app with Core Data",
                imageURL: "post2_image",
                timestamp: Date().addingTimeInterval(-7200),
                likes: 32,
                comments: 8,
                shares: 3
            )
        ]
    }
    */
    
    private func loadUserBadges() {
        userBadges = [
            UserBadge(
                id: UUID(),
                name: "First Course Completed",
                description: "Completed your first course",
                iconName: "star.fill",
                color: "gray",
                rarity: .common,
                earnedAt: Date().addingTimeInterval(-86400)
            ),
            UserBadge(
                id: UUID(),
                name: "Quick Learner",
                description: "Completed 3 courses in a week",
                iconName: "bolt.fill",
                color: "blue",
                rarity: .rare,
                earnedAt: Date().addingTimeInterval(-172800)
            )
        ]
    }
}

// MARK: - Supporting Models for UserDataManager
struct UserStats {
    let coursesCompleted: Int
    let totalWatchTime: Int // in minutes
    let streakDays: Int
    let badgesEarned: Int
}
