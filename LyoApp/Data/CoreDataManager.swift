import CoreData
import Foundation

// MARK: - Core Data Manager
@MainActor
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "LyoApp")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data Error: \(error.localizedDescription)")
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    private init() {}
    
    // MARK: - Save Context
    func save() {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data saved successfully")
            } catch {
                print("❌ Failed to save Core Data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Background Context Operations
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        return await withCheckedContinuation { continuation in
            persistentContainer.performBackgroundTask { context in
                let result = block(context)
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - User Operations
    func createUser(
        username: String,
        email: String,
        fullName: String,
        bio: String? = nil,
        profileImageURL: String? = nil
    ) -> CoreDataUserEntity {
    let user = CoreDataUserEntity(context: context)
    user.id = UUID().uuidString
        user.username = username
        user.email = email
        user.fullName = fullName
        user.bio = bio ?? ""
    user.followers = Int32(0)
    user.following = Int32(0)
    user.posts = Int32(0)
    user.createdAt = Date()
        
        save()
        return user
    }
    
    func fetchUser(by id: String) -> CoreDataUserEntity? {
        let request: NSFetchRequest<CoreDataUserEntity> = NSFetchRequest<CoreDataUserEntity>(entityName: "CoreDataUserEntity")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("❌ Failed to fetch user: \(error)")
            return nil
        }
    }
    
    func fetchAllUsers() -> [CoreDataUserEntity] {
        let request: NSFetchRequest<CoreDataUserEntity> = NSFetchRequest<CoreDataUserEntity>(entityName: "CoreDataUserEntity")
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch users: \(error)")
            return []
        }
    }
    
    // MARK: - Post Operations
    func createPost(
        authorId: String,
        content: String,
        imageURLs: [String] = [],
        videoURL: String? = nil,
        tags: [String] = [],
        location: String? = nil
    ) -> PostEntity {
        let post = PostEntity(context: context)
        post.id = UUID().uuidString
        post.authorId = authorId
        post.content = content
        post.likes = 0
        post.comments = 0
        post.createdAt = Date()
        
        save()
        return post
    }
    
    func fetchPosts(limit: Int = 50) -> [PostEntity] {
        let request: NSFetchRequest<PostEntity> = NSFetchRequest<PostEntity>(entityName: "PostEntity")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PostEntity.createdAt, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch posts: \(error)")
            return []
        }
    }
    
    // MARK: - Course Operations
    func createCourse(
        title: String,
        description: String,
        instructor: String
    ) -> CourseEntity {
        let course = CourseEntity(context: context)
        course.id = UUID().uuidString
        course.title = title
        course.desc = description
        course.instructor = instructor
        course.duration = ""
        course.enrollmentCount = 0
        course.rating = 0.0
        course.createdAt = Date()
        
        save()
        return course
    }
    
    func fetchCourses() -> [CourseEntity] {
        let request: NSFetchRequest<CourseEntity> = NSFetchRequest<CourseEntity>(entityName: "CourseEntity")
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch courses: \(error)")
            return []
        }
    }
    
    func fetchCourses(category: String? = nil) -> [CourseEntity] {
        let request: NSFetchRequest<CourseEntity> = NSFetchRequest<CourseEntity>(entityName: "CourseEntity")
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CourseEntity.rating, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch courses: \(error)")
            return []
        }
    }
    
    // MARK: - Course Enrollment Operations
    func enrollUser(_ userId: String, in courseId: String) -> CourseEnrollmentEntity {
        let enrollment = CourseEnrollmentEntity(context: context)
        enrollment.id = UUID().uuidString
        enrollment.userId = userId
        enrollment.courseId = courseId
        enrollment.enrolledAt = Date()
        enrollment.progress = 0.0
        enrollment.completedAt = nil
        
        save()
        return enrollment
    }
    
    func fetchUserEnrollments(_ userId: String) -> [CourseEnrollmentEntity] {
        let request: NSFetchRequest<CourseEnrollmentEntity> = NSFetchRequest<CourseEnrollmentEntity>(entityName: "CourseEnrollmentEntity")
        request.predicate = NSPredicate(format: "userId == %@", userId)
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch enrollments: \(error)")
            return []
        }
    }
    
    // MARK: - Video Operations
    func createVideo(
        title: String,
        url: String,
        duration: Int32,
        courseId: String? = nil
    ) -> VideoEntity {
        let video = VideoEntity(context: context)
        video.id = UUID().uuidString
        video.title = title
        video.url = url
        video.duration = duration
        video.courseId = courseId
        video.createdAt = Date()
        
        save()
        return video
    }
    
    func fetchVideos(category: String? = nil) -> [VideoEntity] {
        let request: NSFetchRequest<VideoEntity> = NSFetchRequest<VideoEntity>(entityName: "VideoEntity")
        
        if let category = category {
            request.predicate = NSPredicate(format: "category == %@", category)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \VideoEntity.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch videos: \(error)")
            return []
        }
    }
    
    // MARK: - Story Operations
    func createStory(
        userId: String,
        mediaUrl: String,
        mediaType: String
    ) -> StoryEntity {
        let story = StoryEntity(context: context)
        story.id = UUID().uuidString
        story.userId = userId
        story.mediaUrl = mediaUrl
        story.mediaType = mediaType
        story.createdAt = Date()
        story.expiresAt = Date().addingTimeInterval(24 * 60 * 60) // 24 hours
        
        save()
        return story
    }
    
    func fetchActiveStories() -> [StoryEntity] {
        let request: NSFetchRequest<StoryEntity> = NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
        request.predicate = NSPredicate(format: "expiresAt > %@", Date() as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoryEntity.createdAt, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch stories: \(error)")
            return []
        }
    }
    
    // MARK: - Learning Progress Operations (Commented out - Entity not defined)
    /*
    func updateLearningProgress(
        userId: String,
        courseId: String,
        lessonId: String?,
        progress: Double,
        timeSpent: Double
    ) {
        // LearningProgressEntity not found in CoreDataEntities.swift
        // Uncomment when entity is properly defined
    }
    */
    
    // MARK: - Cleanup Methods
    func deleteAllData() async {
        await performBackgroundTask { context in
            let entities = ["CoreDataUserEntity", "PostEntity", "CourseEntity", 
                          "CourseEnrollmentEntity", "VideoEntity", "EbookEntity",
                          "CommunityEntity", "StoryEntity", "LearningProgressEntity"]
            
            for entityName in entities {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
                
                do {
                    try context.execute(deleteRequest)
                } catch {
                    print("❌ Failed to delete \(entityName): \(error)")
                }
            }
            
            try? context.save()
        }
    }
}

// MARK: - CoreDataUserEntity Extension for User Conversion
extension CoreDataUserEntity {
    func toUser() -> User {
        let uuid = UUID(uuidString: self.id) ?? UUID()
        return User(
            id: uuid,
            username: self.username,
            email: self.email,
            fullName: self.fullName,
            bio: self.bio,
            profileImageURL: nil,
            followers: Int(self.followers),
            following: Int(self.following),
            posts: Int(self.posts),
            badges: [],
            level: 1,
            experience: 0,
            joinDate: self.createdAt
        )
    }
}

// MARK: - User Extension for Core Data Conversion  
extension User {
    func toCoreDataEntity(context: NSManagedObjectContext) -> CoreDataUserEntity {
        let entity = CoreDataUserEntity(context: context)
    entity.id = self.id.uuidString // CoreData uses String for id
    entity.username = self.username
    entity.email = self.email
    entity.fullName = self.fullName
    entity.bio = self.bio ?? ""
    // Map to Core Data Int32 fields
    entity.followers = Int32(self.followers)
    entity.following = Int32(self.following)
    entity.posts = Int32(self.posts)
    entity.createdAt = self.joinDate
        return entity
    }
}
