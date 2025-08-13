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
        
        // Convert common errors to app errors
        if error.localizedDescription.contains("network") || error.localizedDescription.contains("connection") {
            return .networkError(error.localizedDescription)
        }
        
        if error.localizedDescription.contains("authentication") || error.localizedDescription.contains("unauthorized") {
            return .authenticationError(error.localizedDescription)
        }
        
        return .genericError(error.localizedDescription)
    }
    
    // MARK: - Error Reporting
    private func reportError(_ error: AppError) {
        // In production, this would send to a crash reporting service
        print("🔴 Reporting error: \(error)")
    }
}

// MARK: - App Error Types
enum AppError: LocalizedError, Identifiable {
    case networkError(String)
    case authenticationError(String)
    case dataError(String)
    case validationError(String)
    case genericError(String)
    
    var id: String {
        return localizedDescription
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .authenticationError(let message):
            return "Authentication Error: \(message)"
        case .dataError(let message):
            return "Data Error: \(message)"
        case .validationError(let message):
            return "Validation Error: \(message)"
        case .genericError(let message):
            return "Error: \(message)"
        }
    }
    
    var userFriendlyMessage: String {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .authenticationError:
            return "Please log in again to continue."
        case .dataError:
            return "There was a problem loading your data. Please try again."
        case .validationError(let message):
            return message
        case .genericError:
            return "Something went wrong. Please try again later."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .networkError:
            return .medium
        case .authenticationError:
            return .high
        case .dataError:
            return .medium
        case .validationError:
            return .low
        case .genericError:
            return .medium
        }
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
                .foregroundColor(error.severity.color)
            
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
