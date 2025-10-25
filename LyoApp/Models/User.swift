import Foundation

// MARK: - Canonical User Model
struct User: Identifiable, Codable, Hashable {
    let id: UUID
    let username: String
    let email: String
    var fullName: String
    var profileImageURL: String?
    var bio: String?
    var level: Int?
    var xp: Int?
    var followersCount: Int?
    var followingCount: Int?
    var isVerified: Bool?

    // CodingKeys for custom key mapping
    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case fullName = "full_name"
        case profileImageURL = "profile_image_url"
        case bio
        case level
        case xp
        case followersCount = "followers_count"
        case followingCount = "following_count"
        case isVerified = "is_verified"
    }

    // Initializer with default values
    init(
        id: UUID = UUID(),
        username: String,
        email: String,
        fullName: String,
        profileImageURL: String? = nil,
        bio: String? = nil,
        level: Int? = 1,
        xp: Int? = 0,
        followersCount: Int? = 0,
        followingCount: Int? = 0,
        isVerified: Bool? = false
    ) {
        self.id = id
        self.username = username
        self.email = email
        self.fullName = fullName
        self.profileImageURL = profileImageURL
        self.bio = bio
        self.level = level
        self.xp = xp
        self.followersCount = followersCount
        self.followingCount = followingCount
        self.isVerified = isVerified
    }
}
