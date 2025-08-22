import Foundation

/// Error presenter that maps Problem Details to user-friendly messages
struct ErrorPresenter {
    
    /// Convert any error to a user-friendly message
    static func userMessage(for error: Error) -> String {
        if let problemDetails = error as? ProblemDetails {
            return userMessage(for: problemDetails)
        }
        
        // Handle common error types
        if let urlError = error as? URLError {
            return handleURLError(urlError)
        }
        
        // Default fallback
        return error.localizedDescription.isEmpty ? "Something went wrong." : error.localizedDescription
    }
    
    /// Convert Problem Details to user-friendly message
    static func userMessage(for problem: ProblemDetails) -> String {
        switch problem.status {
        case 401:
            return "Session expired. Please sign in again."
        case 403:
            return "You don't have access to this."
        case 404:
            return "Not found."
        case 409:
            return "Already exists. Try refreshing."
        case 422:
            return problem.detail ?? "Please check your input."
        case 429:
            return "Things are busy. We'll retry automatically."
        case 500...599:
            return "Temporary server issue. Try again shortly."
        default:
            return problem.detail ?? "Something went wrong."
        }
    }
    
    /// Handle URLError cases
    private static func handleURLError(_ error: URLError) -> String {
        switch error.code {
        case .notConnectedToInternet:
            return "No internet connection. Please check your network."
        case .timedOut:
            return "Request timed out. Please try again."
        case .networkConnectionLost:
            return "Network connection lost. Please try again."
        case .cannotConnectToHost:
            return "Can't connect to server. Please try again later."
        case .cancelled:
            return "Request was cancelled."
        default:
            return "Network error. Please check your connection."
        }
    }
    
    /// Get retry suggestion based on error type
    static func retrySuggestion(for error: Error) -> String? {
        if let problemDetails = error as? ProblemDetails {
            switch problemDetails.status {
            case 429:
                return "We'll retry automatically in a moment"
            case 500...599:
                return "Try again in a few seconds"
            case 408: // Request Timeout
                return "Try again now"
            default:
                return nil
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost:
                return "Try again now"
            case .notConnectedToInternet:
                return "Connect to internet and try again"
            default:
                return nil
            }
        }
        
        return nil
    }
    
    /// Determine if error is retryable
    static func isRetryable(_ error: Error) -> Bool {
        if let problemDetails = error as? ProblemDetails {
            switch problemDetails.status {
            case 408, 429, 500...599:
                return true
            case 401: // Can retry after auth refresh
                return true
            default:
                return false
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet, .cannotConnectToHost:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    /// Get appropriate delay for retry based on error type
    static func retryDelay(for error: Error, attempt: Int = 1) -> TimeInterval {
        if let problemDetails = error as? ProblemDetails {
            switch problemDetails.status {
            case 429:
                // Exponential backoff for rate limits, starting at 2 seconds
                return min(2.0 * pow(2.0, Double(attempt - 1)), 30.0)
            case 500...599:
                // Server errors: shorter delay with backoff
                return min(1.0 * pow(1.5, Double(attempt - 1)), 10.0)
            default:
                return 1.0
            }
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return 2.0
            case .networkConnectionLost, .notConnectedToInternet:
                return 5.0
            default:
                return 3.0
            }
        }
        
        return 1.0
    }
}

// MARK: - Problem Details Extension

extension ProblemDetails {
    /// Create problem details from HTTP response
    static func from(httpStatusCode: Int, detail: String? = nil) -> ProblemDetails {
        return ProblemDetails(
            type: "about:blank",
            title: HTTPURLResponse.localizedString(forStatusCode: httpStatusCode),
            status: httpStatusCode,
            detail: detail,
            instance: nil
        )
    }
    
    /// Whether this is a server error (5xx)
    var isServerError: Bool {
        return (500...599).contains(status)
    }
    
    /// Whether this is a client error (4xx)  
    var isClientError: Bool {
        return (400...499).contains(status)
    }
    
    /// Whether this is a rate limit error
    var isRateLimit: Bool {
        return status == 429
    }
    
    /// Whether this is an authentication error
    var isAuthError: Bool {
        return status == 401
    }
}

// MARK: - Error Toast/Banner UI Helpers

struct ErrorBanner: View {
    let message: String
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Error")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            if let onRetry = onRetry {
                Button("Retry") {
                    onRetry()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(radius: 4)
    }
}