import SwiftUI
import Foundation

/// Real user data management with local persistence and backend sync
@MainActor
class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    // MARK: - Published Properties
    @Published var currentUser: User?
    @Published var userPosts: [Post] = []
    @Published var userCourses: [Course] = []
    @Published var userBadges: [Badge] = []
    @Published var followers: [User] = []
    @Published var following: [User] = []
    @Published var isLoading = false
    
    // MARK: - Storage Keys
    private enum StorageKeys {
        static let currentUser = "lyo_current_user"
        static let userPosts = "lyo_user_posts"
        static let userCourses = "lyo_user_courses"
        static let userBadges = "lyo_user_badges"
        static let lastSyncDate = "lyo_last_sync_date"
    }
    
    private init() {
        loadUserData()
    }
    
    // MARK: - User Management
    
    /// Set the current authenticated user
    func setCurrentUser(_ user: User) {
        currentUser = user
        saveUserData()
        
        // Load associated user data
        Task {
            await loadUserContent()
        }
    }
    
    /// Clear all user data (for logout)
    func clearUserData() {
        currentUser = nil
        userPosts = []
        userCourses = []
        userBadges = []
        followers = []
        following = []
        
        // Clear from local storage
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: StorageKeys.currentUser)
        userDefaults.removeObject(forKey: StorageKeys.userPosts)
        userDefaults.removeObject(forKey: StorageKeys.userCourses)
        userDefaults.removeObject(forKey: StorageKeys.userBadges)
        userDefaults.removeObject(forKey: StorageKeys.lastSyncDate)
    }
    
    /// Update user profile
    func updateUserProfile(fullName: String? = nil, bio: String? = nil, profileImageURL: String? = nil) {
        guard var user = currentUser else { return }
        
        if let fullName = fullName {
            user.fullName = fullName
        }
        if let bio = bio {
            user.bio = bio
        }
        if let profileImageURL = profileImageURL {
            user.profileImageURL = profileImageURL
        }
        
        currentUser = user
        saveUserData()
        
        // Sync with backend if available
        Task {
            await syncUserProfile(user)
        }
    }
    
    // MARK: - Content Management
    
    /// Add a new post for the current user
    func addPost(_ content: String, imageURLs: [String] = [], tags: [String] = []) {
        guard let user = currentUser else { return }
        
        let post = Post(
            author: user,
            content: content,
            imageURLs: imageURLs,
            likes: 0,
            comments: 0,
            shares: 0,
            tags: tags
        )
        
        userPosts.insert(post, at: 0) // Add to beginning
        
        // Update user's post count
        var updatedUser = user
        updatedUser.posts = userPosts.count
        currentUser = updatedUser
        
        saveUserData()
        
        // Sync with backend if available
        Task {
            await syncPost(post)
        }
    }
    
    /// Enroll in a course
    func enrollInCourse(_ course: Course) {
        var enrolledCourse = course
        enrolledCourse.isEnrolled = true
        enrolledCourse.progress = 0.0
        
        if !userCourses.contains(where: { $0.id == course.id }) {
            userCourses.append(enrolledCourse)
            saveUserData()
            
            // Award badge for first course enrollment
            if userCourses.count == 1 {
                awardBadge(name: "First Steps", description: "Enrolled in your first course", iconName: "graduationcap.fill")
            }
        }
    }
    
    /// Update course progress
    func updateCourseProgress(_ courseId: UUID, progress: Double) {
        if let index = userCourses.firstIndex(where: { $0.id == courseId }) {
            userCourses[index].progress = progress
            saveUserData()
            
            // Award completion badge
            if progress >= 1.0 {
                awardBadge(name: "Course Complete", description: "Completed a full course", iconName: "star.fill")
                
                // Update user experience
                var user = currentUser!
                user.experience += 500
                user.level = calculateLevel(experience: user.experience)
                currentUser = user
                saveUserData()
            }
        }
    }
    
    /// Award a badge to the user
    func awardBadge(name: String, description: String, iconName: String, rarity: Badge.Rarity = .common) {
        // Don't award duplicate badges
        guard !userBadges.contains(where: { $0.name == name }) else { return }
        
        let badge = Badge(
            id: UUID(),
            name: name,
            description: description,
            iconName: iconName,
            color: rarity.color.description,
            rarity: rarity,
            earnedAt: Date()
        )
        
        userBadges.append(badge)
        
        // Update user's badge count
        if var user = currentUser {
            user.badges = userBadges
            currentUser = user
        }
        
        saveUserData()
        
        // Show badge notification (could be implemented later)
        print("🏆 Badge earned: \(name)")
    }
    
    // MARK: - Social Features
    
    /// Follow another user
    func followUser(_ user: User) {
        if !following.contains(where: { $0.id == user.id }) {
            following.append(user)
            
            // Update current user's following count
            if var currentUser = currentUser {
                currentUser.following = following.count
                self.currentUser = currentUser
            }
            
            saveUserData()
            
            Task {
                await syncFollowAction(user, isFollowing: true)
            }
        }
    }
    
    /// Unfollow a user
    func unfollowUser(_ user: User) {
        following.removeAll { $0.id == user.id }
        
        // Update current user's following count
        if var currentUser = currentUser {
            currentUser.following = following.count
            self.currentUser = currentUser
        }
        
        saveUserData()
        
        Task {
            await syncFollowAction(user, isFollowing: false)
        }
    }
    
    // MARK: - Data Persistence
    
    private func loadUserData() {
        let userDefaults = UserDefaults.standard
        
        // Load current user
        if let userData = userDefaults.data(forKey: StorageKeys.currentUser),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            currentUser = user
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
           let badges = try? JSONDecoder().decode([Badge].self, from: badgesData) {
            userBadges = badges
        }
    }
    
    private func saveUserData() {
        let userDefaults = UserDefaults.standard
        
        // Save current user
        if let user = currentUser,
           let userData = try? JSONEncoder().encode(user) {
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
        
        // Update last sync date
        userDefaults.set(Date(), forKey: StorageKeys.lastSyncDate)
    }
    
    // MARK: - Backend Sync
    
    private func loadUserContent() async {
        isLoading = true
        defer { isLoading = false }
        
        // Try to load from backend, fall back to local data
        do {
            if LyoAPIService.shared.isConnected {
                // Load posts from backend
                // let posts = try await LyoAPIService.shared.getUserPosts()
                // userPosts = posts
                
                // Load courses from backend
                // let courses = try await LyoAPIService.shared.getUserCourses()
                // userCourses = courses
            }
        } catch {
            print("⚠️ Failed to sync with backend: \(error)")
            // Continue with local data
        }
    }
    
    private func syncUserProfile(_ user: User) async {
        // Implementation for backend sync
        do {
            if LyoAPIService.shared.isConnected {
                // await LyoAPIService.shared.updateUserProfile(user)
            }
        } catch {
            print("⚠️ Failed to sync user profile: \(error)")
        }
    }
    
    private func syncPost(_ post: Post) async {
        // Implementation for backend sync
        do {
            if LyoAPIService.shared.isConnected {
                // await LyoAPIService.shared.createPost(post)
            }
        } catch {
            print("⚠️ Failed to sync post: \(error)")
        }
    }
    
    private func syncFollowAction(_ user: User, isFollowing: Bool) async {
        // Implementation for backend sync
        do {
            if LyoAPIService.shared.isConnected {
                // await LyoAPIService.shared.updateFollowStatus(user.id, isFollowing: isFollowing)
            }
        } catch {
            print("⚠️ Failed to sync follow action: \(error)")
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateLevel(experience: Int) -> Int {
        // Simple level calculation: every 1000 XP = 1 level
        return max(1, experience / 1000 + 1)
    }
    
    /// Get user's progress statistics
    func getUserStats() -> (totalCourses: Int, completedCourses: Int, totalBadges: Int, currentLevel: Int) {
        let totalCourses = userCourses.count
        let completedCourses = userCourses.filter { $0.progress >= 1.0 }.count
        let totalBadges = userBadges.count
        let currentLevel = currentUser?.level ?? 1
        
        return (totalCourses, completedCourses, totalBadges, currentLevel)
    }
    
    // MARK: - Video Management
    func getUserVideos() -> [VideoPost] {
        // TODO: Implement video loading from Core Data
        // For now, return empty array
        return []
    }
    
    func saveVideo(_ video: VideoPost) {
        // TODO: Implement video saving to Core Data
    }
    
    // MARK: - Stories Management
    func getUserStories() -> [MockStory] {
        // TODO: Implement stories loading from Core Data
        // For now, return empty array
        return []
    }
    
    func saveStory(_ story: MockStory) {
        // TODO: Implement story saving to Core Data
    }
    
    // MARK: - Educational Content Management
    func getEducationalVideos() -> [EducationalVideo] {
        // TODO: Implement educational videos loading from Core Data
        // For now, return empty array
        return []
    }
    
    func getEbooks() -> [Ebook] {
        // TODO: Implement ebooks loading from Core Data
        // For now, return empty array
        return []
    }
    
    func getDiscoverContent() -> [DiscoverContent] {
        // TODO: Implement discover content loading from Core Data
        // For now, return empty array
        return []
    }
    
    // MARK: - Achievements Management
    func getUserAchievements() -> [Achievement] {
        // TODO: Implement achievements loading from Core Data
        // For now, return empty array
        return []
    }
    
    func unlockAchievement(_ achievement: Achievement) {
        // TODO: Implement achievement unlocking in Core Data
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let userDidEarnBadge = Notification.Name("userDidEarnBadge")
    static let userDidCompleteLesson = Notification.Name("userDidCompleteLesson")
}
