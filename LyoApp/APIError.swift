import Foundation

// MARK: - API Error Types (canonical across the app)
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case forbidden
    case notFound
    case serverError(Int, String?)
    case rateLimitExceeded
    case apiKeyMissing

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized access"
        case .forbidden:
            return "Forbidden access"
        case .notFound:
            return "Resource not found"
        case .serverError(let code, let message):
            if let message = message, !message.isEmpty {
                return "Server error (\(code)): \(message)"
            }
            return "Server error: \(code)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .apiKeyMissing:
            return "API key is missing"
        }
    }
}
