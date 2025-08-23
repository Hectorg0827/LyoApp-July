import Foundation

/// User-friendly error presentation utility
struct ErrorPresenter {
    
    /// Convert technical errors into user-friendly messages
    static func userMessage(for error: Error) -> String {
        if let problemDetails = error as? ProblemDetails {
            return userMessage(for: problemDetails)
        }
        
        if let apiError = error as? APIError {
            return userMessage(for: apiError)
        }
        
        if let appError = error as? AppError {
            return userMessage(for: appError)
        }
        
        // Generic error messages based on error description
        let description = error.localizedDescription.lowercased()
        
        if description.contains("network") || description.contains("connection") {
            return "No internet connection. Please check your network."
        }
        
        if description.contains("timeout") {
            return "Request timed out. Please try again."
        }
        
        if description.contains("unauthorized") || description.contains("authentication") {
            return "Session expired. Please sign in again."
        }
        
        return "Something went wrong. Please try again."
    }
    
    /// Get retry suggestion for specific errors
    static func retrySuggestion(for error: Error) -> String? {
        if let problemDetails = error as? ProblemDetails {
            if problemDetails.isRateLimitError {
                return "Please wait a moment before trying again."
            }
            
            if problemDetails.isServerError {
                return "Our servers are busy. We'll retry automatically."
            }
        }
        
        if let apiError = error as? APIError {
            switch apiError {
            case .rateLimitExceeded:
                return "Please wait a moment before trying again."
            case .serverError:
                return "Our servers are busy. Please try again shortly."
            case .networkError:
                return "Check your connection and try again."
            case .unauthorized:
                return "Please sign in again."
            default:
                return "Try again in a moment."
            }
        }
        
        let description = error.localizedDescription.lowercased()
        
        if description.contains("network") || description.contains("connection") {
            return "Check your connection and try again."
        }
        
        if description.contains("server") {
            return "Our servers are busy. Please try again shortly."
        }
        
        return "Try again in a moment."
    }
    
    // MARK: - Private Helpers
    
    private static func userMessage(for problemDetails: ProblemDetails) -> String {
        switch problemDetails.status {
        case 400:
            return "Please check your input."
        case 401:
            return "Session expired. Please sign in again."
        case 403:
            return "You don't have access to this."
        case 404:
            return "Not found."
        case 422:
            return "Please check your input."
        case 429:
            return "Things are busy. We'll retry automatically."
        case 500...599:
            return "Temporary server issue. Try again shortly."
        default:
            return problemDetails.detail ?? "Something went wrong. Please try again."
        }
    }
    
    private static func userMessage(for apiError: APIError) -> String {
        switch apiError {
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .forbidden:
            return "You don't have access to this."
        case .notFound:
            return "Not found."
        case .rateLimitExceeded:
            return "Things are busy. We'll retry automatically."
        case .serverError(_, let message):
            return message ?? "Temporary server issue. Try again shortly."
        case .networkError:
            return "No internet connection. Please check your network."
        case .invalidResponse, .decodingError, .noData:
            return "Something went wrong. Please try again."
        case .invalidURL, .apiKeyMissing:
            return "Configuration error. Please contact support."
        }
    }
    
    private static func userMessage(for appError: AppError) -> String {
        switch appError {
        case .networkError:
            return "No internet connection. Please check your network."
        case .authenticationFailed:
            return "Session expired. Please sign in again."
        case .invalidResponse:
            return "Something went wrong. Please try again."
        case .serverError(let message):
            return message
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - Error Types (if not already defined)

/// App-specific error types
enum AppError: Error, LocalizedError {
    case networkError
    case authenticationFailed
    case invalidResponse
    case serverError(message: String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network connection error"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidResponse:
            return "Invalid server response"
        case .serverError(let message):
            return message
        case .unknownError(let message):
            return message
        }
    }
}

/// API-specific error types
enum APIError: Error, LocalizedError {
    case unauthorized
    case forbidden
    case notFound
    case rateLimitExceeded
    case serverError(Int, String?)
    case networkError
    case invalidResponse
    case decodingError
    case noData
    case invalidURL
    case apiKeyMissing
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Access forbidden"
        case .notFound:
            return "Resource not found"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .serverError(let code, let message):
            return "Server error \(code): \(message ?? "Unknown error")"
        case .networkError:
            return "Network error"
        case .invalidResponse:
            return "Invalid response"
        case .decodingError:
            return "Failed to decode response"
        case .noData:
            return "No data received"
        case .invalidURL:
            return "Invalid URL"
        case .apiKeyMissing:
            return "API key missing"
        }
    }
}