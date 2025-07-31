import SwiftUI
import Foundation
import CoreData

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
    @Published var educationalVideos: [EducationalVideo] = []
    @Published var ebooks: [Ebook] = []
    @Published var stories: [Story] = []
    @Published var communities: [Community] = []
    @Published var discoverContent: [DiscoverContent] = []
    
    // MARK: - Data Manager Integration
    private let dataManager = DataManager.shared
    
    // MARK: - Core Data Manager
    private let coreDataManager = CoreDataManager.shared
    private var context: NSManagedObjectContext {
        coreDataManager.context
    }
    
    private init() {
        loadPersistedData()
    }
    
    
    // MARK: - User Management
    
    /// Save user to Core Data and update app state
    func saveUser(_ user: User) {
        // Save to Core Data
        let userEntity = UserEntity(context: context)
        userEntity.id = user.id
        userEntity.username = user.username
        userEntity.email = user.email
        userEntity.fullName = user.fullName
        userEntity.profileImageURL = user.profileImageURL
        userEntity.bio = user.bio
        userEntity.isVerified = user.isVerified
        userEntity.followerCount = Int32(user.followerCount)
        userEntity.followingCount = Int32(user.followingCount)
        userEntity.level = Int32(user.level)
        userEntity.experience = Int32(user.experience)
        userEntity.joinDate = user.joinDate
        userEntity.lastLoginDate = Date()
        
        coreDataManager.save()
        
        // Update published properties
        self.currentUser = user
        self.isAuthenticated = true
        
        // Analytics tracking
        AnalyticsManager.shared.trackUserAction("user_saved", parameters: [
            "user_id": user.id.uuidString,
            "username": user.username
        ])
        
        // Load associated data
        Task {
            await loadUserContent()
        }
    }
    
    /// Load user from Core Data
    func loadUser() -> User? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(key: "lastLoginDate", ascending: false)]
        
        do {
            let userEntities = try context.fetch(request)
            if let userEntity = userEntities.first {
                let user = convertToUser(userEntity)
                self.currentUser = user
                self.isAuthenticated = true
                return user
            }
        } catch {
            print("Error loading user: \(error)")
        }
        
        return nil
    }
    
    /// Get current user or load from storage
    func getCurrentUser() -> User? {
        if let currentUser = currentUser {
            return currentUser
        }
        return loadUser()
    }
    
    /// Logout and clear all data
    func logout() {
        currentUser = nil
        isAuthenticated = false
        clearAllData()
        
        // Clear Core Data
        do {
            try coreDataManager.batchDelete(for: "UserEntity")
            try coreDataManager.batchDelete(for: "PostEntity")
            try coreDataManager.batchDelete(for: "CourseEntity")
            try coreDataManager.batchDelete(for: "CourseEnrollmentEntity")
            try coreDataManager.batchDelete(for: "VideoEntity")
            try coreDataManager.batchDelete(for: "EbookEntity")
            try coreDataManager.batchDelete(for: "CommunityEntity")
            try coreDataManager.batchDelete(for: "StoryEntity")
            try coreDataManager.batchDelete(for: "LearningProgressEntity")
        } catch {
            print("Error clearing Core Data: \(error)")
        }
        
        AnalyticsManager.shared.trackUserAction("user_logout", parameters: [:])
    }
    
    // MARK: - Posts Management
    
    /// Get user posts from Core Data
    func getUserPosts() -> [Post] {
        guard let currentUser = currentUser else { return [] }
        
        let request: NSFetchRequest<PostEntity> = PostEntity.fetchRequest()
        request.predicate = NSPredicate(format: "authorId == %@", currentUser.id.uuidString)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        
        do {
            let postEntities = try context.fetch(request)
            let posts = postEntities.compactMap { convertToPost($0) }
            self.posts = posts
            return posts
        } catch {
            print("Error fetching posts: \(error)")
            return []
        }
    }
    
    /// Save post to Core Data
    func savePost(_ post: Post) {
        let postEntity = PostEntity(context: context)
        postEntity.id = post.id.uuidString
        postEntity.authorId = post.author.id.uuidString
        postEntity.content = post.content
        postEntity.timestamp = post.timestamp
        postEntity.imageURLs = post.imageURLs.joined(separator: ",")
        postEntity.likeCount = Int32(post.likeCount)
        postEntity.commentCount = Int32(post.commentCount)
        postEntity.shareCount = Int32(post.shareCount ?? 0)
        postEntity.isLiked = post.isLiked ?? false
        postEntity.location = post.location
        
        coreDataManager.save()
        
        // Update published array
        posts.insert(post, at: 0)
        
        AnalyticsManager.shared.trackUserAction("post_saved", parameters: [
            "post_id": post.id.uuidString,
            "content_length": post.content.count
        ])
    }
    
    // MARK: - Courses Management
    
    /// Get courses from Core Data
    func getCourses() -> [Course] {
        let request: NSFetchRequest<CourseEntity> = CourseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            let courseEntities = try context.fetch(request)
            let courses = courseEntities.compactMap { convertToCourse($0) }
            self.courses = courses
            return courses
        } catch {
            print("Error fetching courses: \(error)")
            return []
        }
    }
    
    /// Save course to Core Data
    func saveCourse(_ course: Course) {
        let courseEntity = CourseEntity(context: context)
        courseEntity.id = course.id.uuidString
        courseEntity.title = course.title
        courseEntity.courseDescription = course.description
        courseEntity.instructor = course.instructor
        courseEntity.imageURL = course.imageURL
        courseEntity.category = course.category
        courseEntity.difficulty = course.difficulty.rawValue
        courseEntity.duration = Int32(course.duration)
        courseEntity.price = course.price ?? 0.0
        courseEntity.rating = course.rating ?? 0.0
        courseEntity.createdDate = Date()
        courseEntity.updatedDate = Date()
        
        coreDataManager.save()
        
        courses.append(course)
        
        AnalyticsManager.shared.trackUserAction("course_saved", parameters: [
            "course_id": course.id.uuidString,
            "course_title": course.title
        ])
    }
    
    /// Enroll in a course
    func enrollInCourse(_ course: Course) {
        guard let currentUser = currentUser else { return }
        
        // Check if already enrolled
        let request: NSFetchRequest<CourseEnrollmentEntity> = CourseEnrollmentEntity.fetchRequest()
        request.predicate = NSPredicate(format: "courseId == %@ AND userId == %@", 
                                      course.id.uuidString, 
                                      currentUser.id.uuidString)
        
        do {
            let existingEnrollments = try context.fetch(request)
            if existingEnrollments.isEmpty {
                let enrollment = CourseEnrollmentEntity(context: context)
                enrollment.courseId = course.id.uuidString
                enrollment.userId = currentUser.id.uuidString
                enrollment.enrollmentDate = Date()
                enrollment.progress = 0.0
                enrollment.isCompleted = false
                
                coreDataManager.save()
                
                AnalyticsManager.shared.trackUserAction("course_enrolled", parameters: [
                    "course_id": course.id.uuidString,
                    "course_title": course.title
                ])
            }
        } catch {
            print("Error enrolling in course: \(error)")
        }
    }
    
    // MARK: - Educational Content Management
    
    /// Get educational videos from Core Data
    func getEducationalVideos() -> [EducationalVideo] {
        let request: NSFetchRequest<VideoEntity> = VideoEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            let videoEntities = try context.fetch(request)
            let videos = videoEntities.compactMap { convertToEducationalVideo($0) }
            self.videos = videos
            return videos
        } catch {
            print("Error fetching videos: \(error)")
            return []
        }
    }
    
    /// Get ebooks from Core Data
    func getEbooks() -> [Ebook] {
        let request: NSFetchRequest<EbookEntity> = EbookEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        do {
            let ebookEntities = try context.fetch(request)
            let ebooks = ebookEntities.compactMap { convertToEbook($0) }
            self.ebooks = ebooks
            return ebooks
        } catch {
            print("Error fetching ebooks: \(error)")
            return []
        }
    }
    
    /// Get communities from Core Data
    func getCommunities() -> [Community] {
        let request: NSFetchRequest<CommunityEntity> = CommunityEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "memberCount", ascending: false)]
        
        do {
            let communityEntities = try context.fetch(request)
            let communities = communityEntities.compactMap { convertToCommunity($0) }
            self.communities = communities
            return communities
        } catch {
            print("Error fetching communities: \(error)")
            return []
        }
    }
    
    /// Get user stories from Core Data
    func getUserStories() -> [Story] {
        let request: NSFetchRequest<StoryEntity> = StoryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        request.predicate = NSPredicate(format: "expiryDate > %@", Date() as NSDate)
        
        do {
            let storyEntities = try context.fetch(request)
            let stories = storyEntities.compactMap { convertToStory($0) }
            self.stories = stories
            return stories
        } catch {
            print("Error fetching stories: \(error)")
            return []
        }
    }
    
    // MARK: - Discovery Content
    
    /// Get discover content (curated for now, would be personalized in production)
    func getDiscoverContent() -> [DiscoverContent] {
        if discoverContent.isEmpty {
            loadCuratedDiscoverContent()
        }
        return discoverContent
    }
    
    // MARK: - Private Helper Methods
    
    /// Load persisted data on initialization
    private func loadPersistedData() {
        // Load user data on initialization
        _ = loadUser()
        
        // Load other data if user is authenticated
        if isAuthenticated {
            _ = getUserPosts()
            _ = getCourses()
            _ = getCommunities()
            _ = getEducationalVideos()
            _ = getEbooks()
            _ = getUserStories()
        }
    }
    
    /// Clear all published arrays
    private func clearAllData() {
        posts.removeAll()
        courses.removeAll()
        communities.removeAll()
        videos.removeAll()
        ebooks.removeAll()
        stories.removeAll()
        discoverContent.removeAll()
        userBadges.removeAll()
        followers.removeAll()
        following.removeAll()
    }
    
    /// Load curated content for discovery
    private func loadCuratedDiscoverContent() {
        discoverContent = [
            DiscoverContent(
                id: UUID(),
                title: "Trending in iOS Development",
                description: "Latest SwiftUI techniques and best practices",
                imageURL: "https://example.com/ios-trending.jpg",
                contentType: .course,
                category: "iOS Development"
            ),
            DiscoverContent(
                id: UUID(),
                title: "Machine Learning Fundamentals",
                description: "Start your journey into AI and ML",
                imageURL: "https://example.com/ml-fundamentals.jpg",
                contentType: .course,
                category: "Machine Learning"
            ),
            DiscoverContent(
                id: UUID(),
                title: "SwiftUI Advanced Patterns",
                description: "Master complex UI patterns in SwiftUI",
                imageURL: "https://example.com/swiftui-advanced.jpg",
                contentType: .video,
                category: "iOS Development"
            )
        ]
    }
    
    /// Load user content after authentication
    private func loadUserContent() async {
        await MainActor.run {
            _ = getUserPosts()
            _ = getCourses()
            _ = getCommunities()
            _ = getEducationalVideos()
            _ = getEbooks()
            _ = getUserStories()
        }
    }
    
    // MARK: - Core Data Conversion Methods
    
    /// Convert UserEntity to User model
    private func convertToUser(_ entity: UserEntity) -> User {
        return User(
            id: entity.id ?? UUID(),
            username: entity.username ?? "",
            email: entity.email ?? "",
            fullName: entity.fullName ?? "",
            profileImageURL: entity.profileImageURL,
            bio: entity.bio,
            isVerified: entity.isVerified,
            followerCount: Int(entity.followerCount),
            followingCount: Int(entity.followingCount),
            level: Int(entity.level),
            experience: Int(entity.experience),
            joinDate: entity.joinDate ?? Date()
        )
    }
    
    /// Convert PostEntity to Post model
    private func convertToPost(_ entity: PostEntity) -> Post? {
        guard let id = UUID(uuidString: entity.id ?? ""),
              let authorId = UUID(uuidString: entity.authorId ?? ""),
              let content = entity.content,
              let timestamp = entity.timestamp else {
            return nil
        }
        
        // Create a basic author - in a real app, you'd fetch the full user data
        let author = User(
            id: authorId, 
            username: "User", 
            email: "", 
            fullName: "User"
        )
        
        return Post(
            id: id,
            author: author,
            content: content,
            timestamp: timestamp,
            imageURLs: entity.imageURLs?.components(separatedBy: ",") ?? [],
            likeCount: Int(entity.likeCount),
            commentCount: Int(entity.commentCount),
            shareCount: Int(entity.shareCount),
            isLiked: entity.isLiked,
            location: entity.location
        )
    }
    
    /// Convert CourseEntity to Course model
    private func convertToCourse(_ entity: CourseEntity) -> Course? {
        guard let id = UUID(uuidString: entity.id ?? ""),
              let title = entity.title,
              let description = entity.courseDescription else {
            return nil
        }
        
        return Course(
            id: id,
            title: title,
            description: description,
            instructor: entity.instructor ?? "Unknown",
            imageURL: entity.imageURL,
            category: entity.category ?? "General",
            difficulty: DifficultyLevel(rawValue: entity.difficulty ?? "beginner") ?? .beginner,
            duration: Int(entity.duration),
            price: entity.price > 0 ? entity.price : nil,
            rating: entity.rating > 0 ? entity.rating : nil,
            isEnrolled: false // This would be calculated based on enrollment data
        )
    }
    
    /// Convert VideoEntity to EducationalVideo model
    private func convertToEducationalVideo(_ entity: VideoEntity) -> EducationalVideo? {
        guard let id = UUID(uuidString: entity.id ?? ""),
              let title = entity.title,
              let url = entity.url else {
            return nil
        }
        
        return EducationalVideo(
            id: id,
            title: title,
            description: entity.videoDescription ?? "",
            thumbnailURL: entity.thumbnailURL,
            videoURL: url,
            duration: Int(entity.duration),
            category: entity.category ?? "General",
            difficulty: DifficultyLevel(rawValue: entity.difficulty ?? "beginner") ?? .beginner,
            instructor: entity.instructor
        )
    }
    
    /// Convert EbookEntity to Ebook model
    private func convertToEbook(_ entity: EbookEntity) -> Ebook? {
        guard let id = UUID(uuidString: entity.id ?? ""),
              let title = entity.title,
              let author = entity.author else {
            return nil
        }
        
        return Ebook(
            id: id,
            title: title,
            author: author,
            description: entity.ebookDescription ?? "",
            coverImageURL: entity.coverImageURL,
            fileURL: entity.fileURL,
            category: entity.category ?? "General",
            pageCount: Int(entity.pageCount),
            language: entity.language ?? "en"
        )
    }
    
    /// Convert CommunityEntity to Community model
    private func convertToCommunity(_ entity: CommunityEntity) -> Community? {
        guard let id = UUID(uuidString: entity.id ?? ""),
              let name = entity.name,
              let description = entity.communityDescription else {
            return nil
        }
        
        return Community(
            id: id,
            name: name,
            description: description,
            imageURL: entity.imageURL,
            memberCount: Int(entity.memberCount),
            category: entity.category ?? "General",
            isJoined: false // This would be calculated based on membership data
        )
    }
    
    /// Convert StoryEntity to Story model
    private func convertToStory(_ entity: StoryEntity) -> Story? {
        guard let id = UUID(uuidString: entity.id ?? ""),
              let userId = UUID(uuidString: entity.userId ?? ""),
              let mediaURL = entity.mediaURL,
              let timestamp = entity.timestamp else {
            return nil
        }
        
        let user = User(id: userId, username: "User", email: "", fullName: "User")
        
        return Story(
            id: id,
            user: user,
            mediaURL: mediaURL,
            timestamp: timestamp,
            isViewed: entity.isViewed
        )
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
        if educationalVideos.isEmpty {
            loadEducationalVideos()
        }
        return educationalVideos
    }
    
    func getEbooks() -> [Ebook] {
        if ebooks.isEmpty {
            loadEbooks()
        }
        return ebooks
    }
    
    func getUserStories() -> [Story] {
        if stories.isEmpty {
            loadStories()
        }
        return stories
    }
    
    func getCommunities() -> [Community] {
        if communities.isEmpty {
            loadCommunities()
        }
        return communities
    }
    
    func getDiscoverContent() -> [DiscoverContent] {
        if discoverContent.isEmpty {
            loadDiscoverContent()
        }
        return discoverContent
    }
    
    private func loadEducationalVideos() {
        // Load from SwiftData and convert to EducationalVideo
        let resources = dataManager.fetchLearningResources()
        self.educationalVideos = resources.compactMap { resource in
            guard resource.contentType == .video else { return nil }
            return EducationalVideo(
                id: resource.id,
                title: resource.title,
                description: resource.description,
                thumbnailURL: resource.thumbnailURL?.absoluteString,
                videoURL: resource.contentURL?.absoluteString ?? "",
                duration: Int(resource.estimatedDuration?.components(separatedBy: " ").first?.replacingOccurrences(of: "min", with: "") ?? "0") ?? 0,
                category: resource.category ?? "General",
                difficulty: resource.difficultyLevel ?? .beginner
            )
        }
        
        // If no data, seed with sample data
        if educationalVideos.isEmpty {
            seedEducationalVideos()
        }
    }
    
    private func loadEbooks() {
        // Load from SwiftData and convert to Ebook
        let resources = dataManager.fetchLearningResources()
        self.ebooks = resources.compactMap { resource in
            guard resource.contentType.rawValue == "ebook" else { return nil }
            return Ebook(
                id: resource.id,
                title: resource.title,
                author: resource.authorCreator ?? "Unknown Author",
                description: resource.description,
                coverImageURL: resource.thumbnailURL?.absoluteString,
                fileURL: resource.contentURL?.absoluteString,
                category: resource.category ?? "General",
                pageCount: 100 // Default page count
            )
        }
        
        // If no data, seed with sample data
        if ebooks.isEmpty {
            seedEbooks()
        }
    }
    
    private func loadStories() {
        // Create sample stories data
        let sampleStories = [
            Story(
                id: UUID(),
                user: currentUser ?? User(username: "user", email: "user@example.com", fullName: "User"),
                mediaURL: "https://example.com/story1.jpg",
                timestamp: Date(),
                isViewed: false
            ),
            Story(
                id: UUID(),
                user: currentUser ?? User(username: "user", email: "user@example.com", fullName: "User"),
                mediaURL: "https://example.com/story2.jpg",
                timestamp: Date().addingTimeInterval(-3600),
                isViewed: true
            )
        ]
        
        self.stories = sampleStories
    }
    
    private func loadCommunities() {
        // Create sample communities data
        let sampleCommunities = [
            Community(
                name: "iOS Developers",
                description: "Community for iOS app developers",
                icon: "📱",
                memberCount: 1250,
                isPrivate: false,
                category: "Technology"
            ),
            Community(
                name: "SwiftUI Masters",
                description: "Advanced SwiftUI techniques and tips",
                icon: "🎨",
                memberCount: 890,
                isPrivate: false,
                category: "Development"
            ),
            Community(
                name: "Machine Learning Hub",
                description: "AI and ML discussions and projects",
                icon: "🤖",
                memberCount: 2100,
                isPrivate: false,
                category: "AI/ML"
            )
        ]
        
        self.communities = sampleCommunities
    }
    
    private func loadDiscoverContent() {
        // Create sample discover content
        let sampleDiscoverContent = [
            DiscoverContent(
                id: UUID(),
                title: "Trending in iOS Development",
                description: "Latest SwiftUI techniques and best practices",
                imageURL: "https://example.com/ios-trending.jpg",
                contentType: .course,
                category: "iOS Development"
            ),
            DiscoverContent(
                id: UUID(),
                title: "Machine Learning Fundamentals",
                description: "Start your journey into AI and ML",
                imageURL: "https://example.com/ml-fundamentals.jpg",
                contentType: .course,
                category: "Machine Learning"
            ),
            DiscoverContent(
                id: UUID(),
                title: "SwiftUI Advanced Patterns",
                description: "Master complex UI patterns in SwiftUI",
                imageURL: "https://example.com/swiftui-advanced.jpg",
                contentType: .video,
                category: "iOS Development"
            )
        ]
        
        self.discoverContent = sampleDiscoverContent
    }
    
    private func seedEducationalVideos() {
        let sampleVideos = [
            EducationalVideo(
                id: UUID(),
                title: "Introduction to SwiftUI",
                description: "Learn the basics of SwiftUI development",
                thumbnailURL: "https://example.com/swift-thumb.jpg",
                videoURL: "https://example.com/swift-video.mp4",
                duration: 30,
                category: "iOS Development",
                difficulty: .beginner
            ),
            EducationalVideo(
                id: UUID(),
                title: "Advanced iOS Architecture",
                description: "Master MVVM and clean architecture patterns",
                thumbnailURL: "https://example.com/architecture-thumb.jpg",
                videoURL: "https://example.com/architecture-video.mp4",
                duration: 45,
                category: "iOS Development",
                difficulty: .advanced
            ),
            EducationalVideo(
                id: UUID(),
                title: "Machine Learning Fundamentals",
                description: "Introduction to ML concepts and Core ML",
                thumbnailURL: "https://example.com/ml-thumb.jpg",
                videoURL: "https://example.com/ml-video.mp4",
                duration: 60,
                category: "Machine Learning",
                difficulty: .intermediate
            )
        ]
        
        self.educationalVideos = sampleVideos
        
        // Save to SwiftData for persistence
        for video in sampleVideos {
            let resource = LearningResource(
                id: video.id,
                title: video.title,
                description: video.description,
                contentType: .video,
                sourcePlatform: .curated,
                thumbnailURL: URL(string: video.thumbnailURL ?? "") ?? URL(string: "https://example.com/default.jpg")!,
                contentURL: URL(string: video.videoURL) ?? URL(string: "https://example.com/default.mp4")!,
                difficultyLevel: video.difficulty,
                estimatedDuration: "\(video.duration) min",
                category: video.category
            )
            
            try? dataManager.saveLearningResource(resource)
        }
    }
    
    private func seedEbooks() {
        let sampleEbooks = [
            Ebook(
                id: UUID(),
                title: "Swift Programming Guide",
                author: "Apple Inc.",
                description: "Complete guide to Swift programming language",
                coverImageURL: "https://example.com/swift-book.jpg",
                fileURL: "https://example.com/swift-guide.pdf",
                category: "Programming",
                pageCount: 320
            ),
            Ebook(
                id: UUID(),
                title: "iOS Human Interface Guidelines",
                author: "Apple Design Team",
                description: "Design principles for iOS applications",
                coverImageURL: "https://example.com/hig-book.jpg",
                fileURL: "https://example.com/hig.pdf",
                category: "Design",
                pageCount: 180
            ),
            Ebook(
                id: UUID(),
                title: "Data Structures and Algorithms",
                author: "CS Experts",
                description: "Fundamental computer science concepts",
                coverImageURL: "https://example.com/dsa-book.jpg",
                fileURL: "https://example.com/dsa.pdf",
                category: "Computer Science",
                pageCount: 450
            )
        ]
        
        self.ebooks = sampleEbooks
    }
    
    // MARK: - Library Data Management
    
    /// Get AI recommended courses for the library
    func getRecommendedCourses() -> [LibraryCourse] {
        // Convert educational content to library courses
        let videos = getEducationalVideos()
        return videos.prefix(8).map { video in
            LibraryCourse(
                title: video.title,
                instructor: video.instructor ?? "Expert Instructor",
                thumbnailURL: video.imageURL ?? "",
                rating: Double.random(in: 4.2...4.9),
                duration: "\(Int.random(in: 15...120)) min",
                progress: 0.0,
                completedDate: nil
            )
        }
    }
    
    /// Get courses currently in progress
    func getInProgressCourses() -> [LibraryCourse] {
        // Return courses with progress > 0 and < 1
        let videos = getEducationalVideos()
        return videos.prefix(5).map { video in
            LibraryCourse(
                title: video.title,
                instructor: video.instructor ?? "Expert Instructor", 
                thumbnailURL: video.imageURL ?? "",
                rating: Double.random(in: 4.2...4.9),
                duration: "\(Int.random(in: 15...120)) min",
                progress: Double.random(in: 0.1...0.8),
                completedDate: nil
            )
        }
    }
    
    /// Get completed courses
    func getCompletedCourses() -> [LibraryCourse] {
        // Return courses with progress = 1
        let videos = getEducationalVideos()
        return videos.suffix(3).map { video in
            LibraryCourse(
                title: video.title,
                instructor: video.instructor ?? "Expert Instructor",
                thumbnailURL: video.imageURL ?? "",
                rating: Double.random(in: 4.2...4.9),
                duration: "\(Int.random(in: 15...120)) min",
                progress: 1.0,
                completedDate: "Dec 15, 2024"
            )
        }
    }
    
    /// Get saved items (videos, articles, posts)
    func getSavedItems() -> [SavedItem] {
        let videos = getEducationalVideos()
        let ebooks = getEbooks()
        
        var savedItems: [SavedItem] = []
        
        // Add some videos as saved items
        for video in videos.prefix(3) {
            savedItems.append(SavedItem(
                title: video.title,
                author: video.instructor ?? "Expert",
                thumbnailURL: video.imageURL,
                type: .video,
                savedDate: "Dec 20, 2024"
            ))
        }
        
        // Add some ebooks as saved articles
        for ebook in ebooks.prefix(2) {
            savedItems.append(SavedItem(
                title: ebook.title,
                author: ebook.author,
                thumbnailURL: ebook.imageURL,
                type: .article,
                savedDate: "Dec 18, 2024"
            ))
        }
        
        return savedItems
    }
    
    /// Get user achievements from the profile
    func getUserAchievements() -> [Achievement] {
        return [
            Achievement(
                title: "First Course",
                description: "Completed your first course",
                icon: "star.fill",
                isUnlocked: true,
                unlockedDate: Date()
            ),
            Achievement(
                title: "Study Streak",
                description: "7 days in a row",
                icon: "flame.fill",
                isUnlocked: true,
                unlockedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
            ),
            Achievement(
                title: "Video Master",
                description: "Watched 10 educational videos",
                icon: "play.circle.fill",
                isUnlocked: true,
                unlockedDate: Calendar.current.date(byAdding: .week, value: -1, to: Date())
            ),
            Achievement(
                title: "Knowledge Seeker",
                description: "Read 5 ebooks",
                icon: "book.fill",
                isUnlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                title: "Community Leader",
                description: "Help 20 community members",
                icon: "person.3.fill",
                isUnlocked: false,
                unlockedDate: nil
            ),
            Achievement(
                title: "Perfect Score",
                description: "Ace a quiz with 100%",
                icon: "checkmark.seal.fill",
                isUnlocked: true,
                unlockedDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())
            )
        ]
    }
    
    /// Get user videos for the main feed (convert EducationalVideo to VideoPost)
    func getUserVideos() -> [VideoPost] {
        let educationalVideos = getEducationalVideos()
        
        return educationalVideos.map { video in
            VideoPost(
                author: User(
                    id: UUID(),
                    username: video.instructor ?? "Expert",
                    email: "\(video.instructor?.lowercased() ?? "expert")@lyoapp.com",
                    fullName: video.instructor ?? "Expert Instructor",
                    bio: "Educational Content Creator",
                    profileImageURL: "",
                    followers: Int.random(in: 1000...50000),
                    following: Int.random(in: 100...2000),
                    posts: Int.random(in: 10...200)
                ),
                title: video.title,
                videoURL: video.url ?? "",
                thumbnailURL: video.imageURL ?? "",
                likes: Int.random(in: 100...10000),
                comments: Int.random(in: 10...500),
                shares: Int.random(in: 5...200),
                isLiked: false,
                hashtags: [video.category ?? "Education"],
                createdAt: Date()
            )
        }
    }
    
    /// Search discover content by query
    func searchDiscoverContent(_ query: String) -> [DiscoverContent] {
        let allContent = getDiscoverContent()
        if query.isEmpty {
            return allContent
        }
        
        return allContent.filter { content in
            content.title.localizedCaseInsensitiveContains(query) ||
            content.description.localizedCaseInsensitiveContains(query) ||
            content.category.localizedCaseInsensitiveContains(query) ||
            content.author.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// Get discover content filtered by category
    func getDiscoverContentByCategory(_ category: String) -> [DiscoverContent] {
        let allContent = getDiscoverContent()
        if category == "All" {
            return allContent
        }
        
        return allContent.filter { content in
            content.category.localizedCaseInsensitiveContains(category)
        }
    }
    
    /// Get all discover content
    func getDiscoverContent() -> [DiscoverContent] {
        return [
            DiscoverContent(
                title: "SwiftUI Advanced Animations",
                description: "Learn how to create stunning animations in SwiftUI with advanced techniques and best practices.",
                category: "Programming",
                imageURL: "https://example.com/swiftui-animations.jpg",
                author: "Apple Developer",
                createdAt: Date()
            ),
            DiscoverContent(
                title: "Design Systems 2024",
                description: "Modern design systems and how to implement them in your applications.",
                category: "Design",
                imageURL: "https://example.com/design-systems.jpg",
                author: "Design Expert",
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            DiscoverContent(
                title: "AI & Machine Learning Fundamentals",
                description: "Get started with artificial intelligence and machine learning concepts.",
                category: "Technology",
                imageURL: "https://example.com/ai-ml.jpg",
                author: "Tech Guru",
                createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            DiscoverContent(
                title: "Business Strategy for Startups",
                description: "Essential strategies every startup founder should know.",
                category: "Business",
                imageURL: "https://example.com/business-strategy.jpg",
                author: "Business Coach",
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
            DiscoverContent(
                title: "Digital Art Techniques",
                description: "Master digital art with these professional techniques and tools.",
                category: "Art",
                imageURL: "https://example.com/digital-art.jpg",
                author: "Digital Artist",
                createdAt: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()
            ),
            DiscoverContent(
                title: "Portrait Photography Mastery",
                description: "Professional portrait photography tips and lighting techniques.",
                category: "Photography",
                imageURL: "https://example.com/portrait-photography.jpg",
                author: "Pro Photographer",
                createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
            )
        ]
    }
    
    // MARK: - User Authentication Management
    
    /// Set the current authenticated user
    func setCurrentUser(_ user: User) {
        currentUser = user
        // Save to persistent storage if needed
        saveUserData()
    }
    
    /// Clear user data and log out
    func clearUserData() {
        currentUser = nil
        // Clear any cached data if needed
        saveUserData()
    }
    
    /// Save user data to persistent storage
    private func saveUserData() {
        // Implementation for saving user data
        // This could save to UserDefaults, Keychain, or Core Data
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let userDidEarnBadge = Notification.Name("userDidEarnBadge")
    static let userDidCompleteLesson = Notification.Name("userDidCompleteLesson")
}

// MARK: - Supporting Models for UserDataManager
struct UserStats {
    let coursesCompleted: Int
    let totalWatchTime: Int // in minutes
    let streakDays: Int
    let badgesEarned: Int
}
