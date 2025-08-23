import CoreData
import Foundation

/// Core Data entity for User storage - simplified to match our User model
@objc(CoreDataUserEntity)
public class CoreDataUserEntity: NSManagedObject {
    
    @NSManaged public var id: String
    @NSManaged public var username: String
    @NSManaged public var email: String
    @NSManaged public var fullName: String
    @NSManaged public var bio: String?
    @NSManaged public var profileImageURL: String?
    @NSManaged public var followers: Int32
    @NSManaged public var following: Int32
    @NSManaged public var posts: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    
    // MARK: - User Conversion
    func toUser() -> User {
        return User(
            id: UUID(uuidString: self.id) ?? UUID(),
            username: self.username,
            email: self.email,
            fullName: self.fullName,
            bio: self.bio,
            profileImageURL: self.profileImageURL,
            followers: Int(self.followers),
            following: Int(self.following),
            posts: Int(self.posts),
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
        entity.id = self.id.uuidString
        entity.username = self.username
        entity.email = self.email
        entity.fullName = self.fullName
        entity.bio = self.bio
        entity.profileImageURL = self.profileImageURL
        entity.followers = Int32(self.followers)
        entity.following = Int32(self.following)
        entity.posts = Int32(self.posts)
        entity.createdAt = self.joinDate
        entity.updatedAt = Date()
        return entity
    }
}
