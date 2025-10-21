import Foundation
import SwiftUI

// MARK: - Error Handler
@MainActor
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showingError = false
    
    private init() {}
    
    // MARK: - Error Handling
    func handle(_ error: Error) {
        let appError = convertToAppError(error)
        currentError = appError
        showingError = true
        
        // Log error
        ConfigurationManager.shared.log("Error occurred: \(appError.localizedDescription)", level: .error)
        
        // Report to crash reporting service in production
        if ConfigurationManager.shared.enableCrashReporting {
            // TODO: Integrate with Crashlytics or Sentry
            reportError(appError)
        }
    }
    
    func dismissError() {
        currentError = nil
        showingError = false
    }
    
    // MARK: - Error Conversion
    private func convertToAppError(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }
        // Map APIError into AppError (defined in AppState.swift)
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                return .authenticationFailed
            case .invalidResponse, .decodingError, .noData, .invalidURL:
                return .invalidResponse
            case .serverError(_, let message):
                return .serverError(message: message ?? "Server error")
            case .networkError:
                return .networkError
            case .forbidden, .notFound, .rateLimitExceeded, .apiKeyMissing:
                return .serverError(message: apiError.localizedDescription)
            }
        }
        // Fallback mapping
        let message = error.localizedDescription
        if message.localizedCaseInsensitiveContains("network") || message.localizedCaseInsensitiveContains("connection") {
            return .networkError
        }
        if message.localizedCaseInsensitiveContains("authentication") || message.localizedCaseInsensitiveContains("unauthorized") {
            return .authenticationFailed
        }
        return .unknownError(message)
    }
    
    // MARK: - Error Reporting
    private func reportError(_ error: AppError) {
        // In production, this would send to a crash reporting service
        #if DEBUG
        print("🔴 Reporting error: \(error)")
        #endif
        // TODO: Integrate with Crashlytics or Sentry for production
    }
}

// MARK: - Error Severity
enum ErrorSeverity {
    case low
    case medium
    case high
    
    var color: Color {
        switch self {
        case .low:
            return .yellow
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - Error Alert View
struct ErrorAlert: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    init(error: AppError, onDismiss: @escaping () -> Void, onRetry: (() -> Void)? = nil) {
        self.error = error
        self.onDismiss = onDismiss
        self.onRetry = onRetry
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(error.severityColor)
            
            // Error title
            Text("Oops! Something went wrong")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Error message
            Text(error.userFriendlyMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(SecondaryButtonStyle())
                
                if let onRetry = onRetry {
                    Button("Retry") {
                        onDismiss()
                        onRetry()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 32)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - View Extension for Error Handling
extension View {
    func errorAlert(isPresented: Binding<Bool>, error: AppError?, onRetry: (() -> Void)? = nil) -> some View {
        overlay(
            Group {
                if isPresented.wrappedValue, let error = error {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            isPresented.wrappedValue = false
                        }
                    
                    ErrorAlert(
                        error: error,
                        onDismiss: {
                            isPresented.wrappedValue = false
                        },
                        onRetry: onRetry
                    )
                }
            }
        )
    }
}

// MARK: - AppError presentation helpers for UI (extending the AppError in AppState.swift)
extension AppError {
    var severityColor: Color {
        switch self {
        case .networkError:
            return ErrorSeverity.medium.color
        case .serverError:
            return ErrorSeverity.high.color
        case .authenticationFailed:
            return ErrorSeverity.high.color
        case .invalidResponse, .dataCorruption:
            return ErrorSeverity.medium.color
        case .microphonePermissionDenied, .cameraPermissionDenied, .photoLibraryPermissionDenied:
            return ErrorSeverity.low.color
        case .unknownError:
            return ErrorSeverity.low.color
        }
    }
    
    var userFriendlyMessage: String {
        // Reuse existing LocalizedError description
        return self.errorDescription ?? "An unexpected error occurred."
    }
}
