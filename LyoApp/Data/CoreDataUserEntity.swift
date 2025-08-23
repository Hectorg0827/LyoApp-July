import CoreData
import Foundation

/// Core Data entity for User storage
@objc(CoreDataUserEntity)
public class CoreDataUserEntity: NSManagedObject {
    
    @NSManaged public var id: String
    @NSManaged public var username: String
    @NSManaged public var displayName: String?
    @NSManaged public var email: String?
    @NSManaged public var isVerified: Bool
    @NSManaged public var followerCount: Int32
    @NSManaged public var followingCount: Int32
    @NSManaged public var postCount: Int32
    @NSManaged public var avatarURL: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // MARK: - User Conversion
    func toUser() -> User {
        return User(
            id: UUID(uuidString: self.id) ?? UUID(),  // Convert String back to UUID
            username: self.username,
            email: self.email ?? "",
            fullName: self.displayName ?? self.username,
            bio: nil,
            profileImageURL: self.avatarURL,
            followers: Int(self.followerCount),
            following: Int(self.followingCount),
            posts: Int(self.postCount),
            badges: [],
            level: 1,
            experience: 0,
            joinDate: self.createdAt ?? Date()
        )
    }
}

extension User {
    func toCoreDataEntity(context: NSManagedObjectContext) -> CoreDataUserEntity {
        let entity = CoreDataUserEntity(context: context)
        entity.id = self.id.uuidString  // Convert UUID to String
        entity.username = self.username
        entity.displayName = self.fullName  // Map fullName to displayName
        entity.email = self.email
        entity.isVerified = false  // Default value since User doesn't have isVerified
        entity.followerCount = Int32(self.followers)
        entity.followingCount = Int32(self.following)
        entity.postCount = Int32(self.posts)
        entity.avatarURL = self.profileImageURL
        entity.createdAt = self.joinDate
        entity.updatedAt = Date()
        return entity
    }
}

/// Fetch Request Helper
extension CoreDataUserEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDataUserEntity> {
        return NSFetchRequest<CoreDataUserEntity>(entityName: "CoreDataUserEntity")
    }
}
