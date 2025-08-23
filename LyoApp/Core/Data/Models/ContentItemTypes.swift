import Foundation
import CoreData

// MARK: - Course Entity (Core Data stub)
@objc(CourseEntity)
public class CourseEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var desc: String?
    @NSManaged public var instructor: String?
    @NSManaged public var duration: String?
    @NSManaged public var enrollmentCount: Int32
    @NSManaged public var rating: Double
    @NSManaged public var createdAt: Date?
}

extension CourseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CourseEntity> {
        return NSFetchRequest<CourseEntity>(entityName: "CourseEntity")
    }
}

// MARK: - Content Item DTO (from API)
struct ContentItemDTO: Decodable {
    let id: String
    let type: String
    let title: String
    let sourceUrl: String?
    let durationSec: Int?
    let order: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title, order
        case sourceUrl = "source_url"
        case durationSec = "duration_sec"
    }
}

// MARK: - Content Item Entity (Core Data)
// Note: In a real app, this would be defined in a Core Data model file
// For now, we'll create a simple class to represent the entity structure
@objc(ContentItemEntity)
public class ContentItemEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var type: String?
    @NSManaged public var title: String?
    @NSManaged public var url: String?
    @NSManaged public var duration: TimeInterval
    @NSManaged public var order: Int32
}

// Extension to provide entity description for cases where Core Data model isn't available
extension ContentItemEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ContentItemEntity> {
        return NSFetchRequest<ContentItemEntity>(entityName: "ContentItemEntity")
    }
}