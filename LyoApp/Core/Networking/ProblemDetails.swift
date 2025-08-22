import Foundation

/// Problem Details error format (RFC 7807)
/// Used for structured error responses from the API
struct ProblemDetails: Decodable, Error, LocalizedError {
    let type: URL?
    let title: String
    let status: Int
    let detail: String?
    let instance: URL?
    
    /// Additional custom properties from the server
    private let additionalProperties: [String: Any]?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields
        self.title = try container.decode(String.self, forKey: .title)
        self.status = try container.decode(Int.self, forKey: .status)
        
        // Optional fields
        self.type = try container.decodeIfPresent(URL.self, forKey: .type)
        self.detail = try container.decodeIfPresent(String.self, forKey: .detail)
        self.instance = try container.decodeIfPresent(URL.self, forKey: .instance)
        
        // Capture any additional properties
        var additionalProps: [String: Any] = [:]
        for key in container.allKeys {
            if !CodingKeys.allCases.contains(key) {
                // Try to decode as common types
                if let stringValue = try? container.decode(String.self, forKey: key) {
                    additionalProps[key.stringValue] = stringValue
                } else if let intValue = try? container.decode(Int.self, forKey: key) {
                    additionalProps[key.stringValue] = intValue
                } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                    additionalProps[key.stringValue] = doubleValue
                } else if let boolValue = try? container.decode(Bool.self, forKey: key) {
                    additionalProps[key.stringValue] = boolValue
                }
            }
        }
        self.additionalProperties = additionalProps.isEmpty ? nil : additionalProps
    }
    
    /// Custom initializer for creating Problem Details locally
    init(title: String, status: Int, detail: String? = nil, type: URL? = nil, instance: URL? = nil) {
        self.title = title
        self.status = status
        self.detail = detail
        self.type = type
        self.instance = instance
        self.additionalProperties = nil
    }
    
    // MARK: - LocalizedError
    var errorDescription: String? {
        return detail ?? title
    }
    
    var failureReason: String? {
        return title
    }
    
    var recoverySuggestion: String? {
        switch status {
        case 400...499:
            return "Please check your request and try again."
        case 500...599:
            return "This appears to be a server issue. Please try again later."
        default:
            return nil
        }
    }
    
    // MARK: - Convenience properties
    
    /// Whether this is a client error (4xx)
    var isClientError: Bool {
        return (400...499).contains(status)
    }
    
    /// Whether this is a server error (5xx)
    var isServerError: Bool {
        return (500...599).contains(status)
    }
    
    /// Whether this is an authentication error
    var isAuthError: Bool {
        return status == 401 || status == 403
    }
    
    /// Whether this is a validation error
    var isValidationError: Bool {
        return status == 400 || status == 422
    }
    
    /// Whether this is a rate limit error
    var isRateLimitError: Bool {
        return status == 429
    }
    
    /// Additional property access
    func additionalProperty<T>(key: String, as type: T.Type) -> T? {
        return additionalProperties?[key] as? T
    }
}

// MARK: - Coding Keys
extension ProblemDetails {
    enum CodingKeys: String, CodingKey, CaseIterable {
        case type
        case title
        case status
        case detail
        case instance
    }
}

// MARK: - Predefined Problem Types
extension ProblemDetails {
    /// Common problem types for the Lyo API
    static func invalidRequest(detail: String? = nil) -> ProblemDetails {
        return ProblemDetails(
            title: "Invalid Request", 
            status: 400, 
            detail: detail ?? "The request is malformed or missing required parameters."
        )
    }
    
    static func unauthorized(detail: String? = nil) -> ProblemDetails {
        return ProblemDetails(
            title: "Unauthorized", 
            status: 401, 
            detail: detail ?? "Authentication is required to access this resource."
        )
    }
    
    static func forbidden(detail: String? = nil) -> ProblemDetails {
        return ProblemDetails(
            title: "Forbidden", 
            status: 403, 
            detail: detail ?? "You don't have permission to access this resource."
        )
    }
    
    static func notFound(detail: String? = nil) -> ProblemDetails {
        return ProblemDetails(
            title: "Not Found", 
            status: 404, 
            detail: detail ?? "The requested resource was not found."
        )
    }
    
    static func rateLimited(detail: String? = nil) -> ProblemDetails {
        return ProblemDetails(
            title: "Too Many Requests", 
            status: 429, 
            detail: detail ?? "Rate limit exceeded. Please try again later."
        )
    }
    
    static func internalServerError(detail: String? = nil) -> ProblemDetails {
        return ProblemDetails(
            title: "Internal Server Error", 
            status: 500, 
            detail: detail ?? "An unexpected error occurred on the server."
        )
    }
    
    static func serviceUnavailable(detail: String? = nil) -> ProblemDetails {
        return ProblemDetails(
            title: "Service Unavailable", 
            status: 503, 
            detail: detail ?? "The service is temporarily unavailable."
        )
    }
}