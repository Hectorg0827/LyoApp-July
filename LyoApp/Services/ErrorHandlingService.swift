import SwiftUI
import Combine

// MARK: - Error Types

/// User-friendly error messages for common app errors
enum UserFacingError: Error {
    case networkUnavailable
    case serverError
    case authenticationFailed
    case invalidInput(String)
    case courseNotFound
    case lessonNotAvailable
    case aiServiceUnavailable
    case unknown(String)
    
    var title: String {
        switch self {
        case .networkUnavailable:
            return "No Internet Connection"
        case .serverError:
            return "Server Error"
        case .authenticationFailed:
            return "Authentication Failed"
        case .invalidInput:
            return "Invalid Input"
        case .courseNotFound:
            return "Course Not Found"
        case .lessonNotAvailable:
            return "Lesson Unavailable"
        case .aiServiceUnavailable:
            return "AI Service Unavailable"
        case .unknown:
            return "Something Went Wrong"
        }
    }
    
    var message: String {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection and try again."
        case .serverError:
            return "We're having trouble connecting to our servers. Please try again in a moment."
        case .authenticationFailed:
            return "Please log in again to continue."
        case .invalidInput(let details):
            return details
        case .courseNotFound:
            return "The course you're looking for is no longer available."
        case .lessonNotAvailable:
            return "This lesson is not available right now. Please try again later."
        case .aiServiceUnavailable:
            return "Our AI assistant is temporarily unavailable. Please try again shortly."
        case .unknown(let details):
            return details.isEmpty ? "An unexpected error occurred. Please try again." : details
        }
    }
    
    var icon: String {
        switch self {
        case .networkUnavailable:
            return "wifi.slash"
        case .serverError:
            return "server.rack"
        case .authenticationFailed:
            return "lock.shield"
        case .invalidInput:
            return "exclamationmark.triangle"
        case .courseNotFound, .lessonNotAvailable:
            return "book.closed"
        case .aiServiceUnavailable:
            return "brain.head.profile"
        case .unknown:
            return "exclamationmark.circle"
        }
    }
    
    /// Converts API errors to user-friendly errors
    static func from(_ apiError: APIError) -> UserFacingError {
        switch apiError {
        case .networkError:
            return .networkUnavailable
        case .unauthorized:
            return .authenticationFailed
        case .serverError:
            return .serverError
        case .rateLimitExceeded:
            return .serverError
        case .invalidResponse, .decodingError:
            return .unknown("We received an unexpected response from the server.")
        case .invalidURL:
            return .unknown("An internal error occurred.")
        }
    }
}

// MARK: - Error Banner Model

struct ErrorBanner: Identifiable, Equatable {
    let id = UUID()
    let error: UserFacingError
    let timestamp = Date()
    
    static func == (lhs: ErrorBanner, rhs: ErrorBanner) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Error Handling Service

@MainActor
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: ErrorBanner? = nil
    @Published var errorHistory: [ErrorBanner] = []
    
    private var autoDismissTask: Task<Void, Never>?
    
    private init() {}
    
    /// Shows an error to the user
    /// - Parameters:
    ///   - error: The user-facing error to display
    ///   - autoDismiss: Whether to auto-dismiss after 5 seconds (default: true)
    func show(_ error: UserFacingError, autoDismiss: Bool = true) {
        let banner = ErrorBanner(error: error)
        currentError = banner
        errorHistory.append(banner)
        
        // Limit history to last 10 errors
        if errorHistory.count > 10 {
            errorHistory.removeFirst()
        }
        
        print("🔴 UserFacingError: \(error.title) - \(error.message)")
        
        if autoDismiss {
            autoDismissTask?.cancel()
            autoDismissTask = Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                if !Task.isCancelled {
                    dismiss()
                }
            }
        }
    }
    
    /// Shows an API error converted to a user-friendly error
    func show(_ apiError: APIError, autoDismiss: Bool = true) {
        show(UserFacingError.from(apiError), autoDismiss: autoDismiss)
    }
    
    /// Dismisses the current error
    func dismiss() {
        withAnimation {
            currentError = nil
        }
        autoDismissTask?.cancel()
    }
}

// MARK: - Error Banner View

struct ErrorBannerView: View {
    let error: UserFacingError
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.icon)
                .font(.title2)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(error.message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.gradient)
                .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - View Modifier

struct ErrorHandlingModifier: ViewModifier {
    @ObservedObject var errorService = ErrorHandlingService.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let banner = errorService.currentError {
                ErrorBannerView(error: banner.error) {
                    errorService.dismiss()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(999)
                .padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: errorService.currentError)
    }
}

// MARK: - View Extension

extension View {
    /// Adds automatic error handling to a view
    /// Displays a banner at the top when errors occur
    func withErrorHandling() -> some View {
        modifier(ErrorHandlingModifier())
    }
}

// MARK: - Convenience Methods for Common Errors

extension ErrorHandlingService {
    func showNetworkError() {
        show(.networkUnavailable)
    }
    
    func showAuthError() {
        show(.authenticationFailed, autoDismiss: false)
    }
    
    func showServerError() {
        show(.serverError)
    }
    
    func showAIError() {
        show(.aiServiceUnavailable)
    }
}
