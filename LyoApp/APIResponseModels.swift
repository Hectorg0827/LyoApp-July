import Foundation

// MARK: - API Response Models

struct LoginResponse: Codable {
    let token: String
    let user: APIUser
    let expiresIn: Int?
    
    enum CodingKeys: String, CodingKey {
        case token, user
        case expiresIn = "expires_in"
    }
}

struct HealthResponse: Codable {
    let status: String
    let message: String
    let timestamp: String
    let features: [String]?
}

struct APIUser: Codable {
    let id: String
    let name: String
    let email: String
    let avatarUrl: String?
    let username: String?
    let bio: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, username, bio
        case avatarUrl = "avatar_url"
        case createdAt = "created_at"
    }
}

// MARK: - Source Platform for Search
enum SourcePlatform: String, CaseIterable, Codable {
    case youtube = "youtube"
    case coursera = "coursera"
    case edx = "edx"
    case udemy = "udemy"
    case khanAcademy = "khan_academy"
    case podcasts = "podcasts"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .youtube: return "YouTube"
        case .coursera: return "Coursera"
        case .edx: return "edX"
        case .udemy: return "Udemy"
        case .khanAcademy: return "Khan Academy"
        case .podcasts: return "Podcasts"
        case .all: return "All Sources"
        }
    }
}

// MARK: - Common Request/Response Models

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct ErrorResponse: Codable {
    let detail: String?
    // Some endpoints may return alternative fields; include a generic message fallback
    let message: String?
    
    init(detail: String? = nil, message: String? = nil) {
        self.detail = detail
        self.message = message
    }
}
