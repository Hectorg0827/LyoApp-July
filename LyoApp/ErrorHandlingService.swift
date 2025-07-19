import Foundation
import SwiftUI

/// Service for handling errors and implementing retry logic across the Lyo system
@MainActor
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    // MARK: - Published State
    @Published var currentError: LyoError?
    @Published var isShowingErrorAlert = false
    @Published var errorHistory: [LyoError] = []
    
    // MARK: - Retry Configuration
    private let maxRetries = 3
    private let baseRetryDelay: TimeInterval = 2.0
    private var retryAttempts: [String: Int] = [:]
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error, context: ErrorContext? = nil) {
        let lyoError = LyoError.from(error, context: context)
        
        // Add to history
        errorHistory.append(lyoError)
        
        // Keep only last 50 errors
        if errorHistory.count > 50 {
            errorHistory.removeFirst()
        }
        
        // Set current error
        currentError = lyoError
        
        // Show alert for user-facing errors
        if lyoError.shouldShowToUser {
            isShowingErrorAlert = true
        }
        
        // Log error
        logError(lyoError)
        
        // Send to analytics if needed
        sendErrorAnalytics(lyoError)
    }
    
    func clearError() {
        currentError = nil
        isShowingErrorAlert = false
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    // MARK: - Retry Logic
    
    func shouldRetry(for identifier: String) -> Bool {
        let attempts = retryAttempts[identifier] ?? 0
        return attempts < maxRetries
    }
    
    func incrementRetryAttempt(for identifier: String) {
        retryAttempts[identifier] = (retryAttempts[identifier] ?? 0) + 1
    }
    
    func clearRetryAttempts(for identifier: String) {
        retryAttempts.removeValue(forKey: identifier)
    }
    
    func retryWithBackoff<T>(
        identifier: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        let attempts = retryAttempts[identifier] ?? 0
        
        if attempts >= maxRetries {
            throw LyoError.maxRetriesExceeded
        }
        
        do {
            let result = try await operation()
            clearRetryAttempts(for: identifier)
            return result
        } catch {
            incrementRetryAttempt(for: identifier)
            
            if shouldRetry(for: identifier) {
                let delay = baseRetryDelay * pow(2.0, Double(attempts)) // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await retryWithBackoff(identifier: identifier, operation: operation)
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Specific Error Handlers
    
    func handleAPIError(_ error: APIError, endpoint: String) {
        let context = ErrorContext(
            operation: "API Call",
            endpoint: endpoint,
            userAction: "Using Lyo AI features"
        )
        
        handleError(error, context: context)
    }
    
    func handleAvatarCompanionError(_ error: Error) {
        let context = ErrorContext(
            operation: "Avatar Companion",
            endpoint: "System Integration",
            userAction: "Interacting with AI Avatar"
        )
        
        handleError(error, context: context)
    }
    
    func handleWebSocketError(_ error: WebSocketError) {
        let context = ErrorContext(
            operation: "WebSocket Connection",
            endpoint: "Real-time chat",
            userAction: "Chatting with Lyo"
        )
        
        handleError(error, context: context)
    }
    
    func handleVoiceRecognitionError(_ error: Error) {
        let context = ErrorContext(
            operation: "Voice Recognition",
            endpoint: "Hey Lyo activation",
            userAction: "Using voice commands"
        )
        
        handleError(error, context: context)
    }
    
    // MARK: - Recovery Suggestions
    
    func getRecoverySuggestions(for error: LyoError) -> [RecoveryAction] {
        switch error.type {
        case .networkError:
            return [
                RecoveryAction(title: "Check Connection", action: { await self.checkNetworkConnection() }),
                RecoveryAction(title: "Retry", action: { await self.retryLastOperation() }),
                RecoveryAction(title: "Use Offline Mode", action: { await self.enableOfflineMode() })
            ]
            
        case .apiError(let apiError):
            switch apiError {
            case .unauthorized:
                return [
                    RecoveryAction(title: "Sign In Again", action: { await self.reauthenticate() }),
                    RecoveryAction(title: "Contact Support", action: { await self.contactSupport() })
                ]
            case .serverError:
                return [
                    RecoveryAction(title: "Retry", action: { await self.retryLastOperation() }),
                    RecoveryAction(title: "Check Status", action: { await self.checkServerStatus() })
                ]
            default:
                return [
                    RecoveryAction(title: "Retry", action: { await self.retryLastOperation() })
                ]
            }
            
        case .webSocketError:
            return [
                RecoveryAction(title: "Reconnect", action: { await self.reconnectWebSocket() }),
                RecoveryAction(title: "Use Standard Chat", action: { await self.fallbackToRestAPI() })
            ]
            
        case .voiceRecognitionError:
            return [
                RecoveryAction(title: "Check Microphone", action: { await self.checkMicrophonePermission() }),
                RecoveryAction(title: "Use Manual Input", action: { await self.switchToManualInput() })
            ]
            
        case .courseGenerationError:
            return [
                RecoveryAction(title: "Try Again", action: { await self.retryLastOperation() }),
                RecoveryAction(title: "Simplify Topic", action: { await self.suggestSimplifiedTopic() })
            ]
            
        case .lessonContentError:
            return [
                RecoveryAction(title: "Retry", action: { await self.retryLastOperation() }),
                RecoveryAction(title: "Use Sample Content", action: { await self.useSampleContent() })
            ]
            
        case .authenticationError:
            return [
                RecoveryAction(title: "Sign In", action: { await self.reauthenticate() })
            ]
            
        case .maxRetriesExceeded:
            return [
                RecoveryAction(title: "Contact Support", action: { await self.contactSupport() }),
                RecoveryAction(title: "Try Later", action: { await self.scheduleRetryLater() })
            ]
            
        case .avatarCompanionError:
            return [
                RecoveryAction(title: "Retry Connection", action: { await self.retryAvatarConnection() }),
                RecoveryAction(title: "Use Basic Chat", action: { await self.fallbackToBasicChat() }),
                RecoveryAction(title: "Restart System", action: { await self.restartAvatarSystem() })
            ]
        }
    }
    
    // MARK: - Private Methods
    
    private func logError(_ error: LyoError) {
        print("🚨 [LyoError] \(error.title): \(error.message)")
        if let context = error.context {
            print("   Context: \(context.operation) - \(context.endpoint)")
        }
    }
    
    private func sendErrorAnalytics(_ error: LyoError) {
        // TODO: Implement analytics sending
        // This would typically send to your analytics service
    }
    
    // MARK: - Recovery Actions
    
    private func checkNetworkConnection() async {
        // Implement network connectivity check
        LyoAPIService.shared.checkConnection()
    }
    
    func retryLastOperation() async {
        // Implement retry logic for last failed operation
        clearError()
    }
    
    private func enableOfflineMode() async {
        // Implement offline mode
        print("Enabling offline mode...")
    }
    
    private func reauthenticate() async {
        // Implement reauthentication
        print("Reauthenticating...")
    }
    
    private func contactSupport() async {
        // Implement support contact
        print("Contacting support...")
    }
    
    private func checkServerStatus() async {
        // Check server status
        do {
            let _ = try await LyoAPIService.shared.getSystemHealth()
            print("Server is operational")
        } catch {
            print("Server issues detected")
        }
    }
    
    private func reconnectWebSocket() async {
        // Reconnect WebSocket
        LyoWebSocketService.shared.connect(userId: 1) // TODO: Use real user ID
    }
    
    private func fallbackToRestAPI() async {
        // Implement fallback to REST API
        print("Falling back to REST API...")
    }
    
    private func checkMicrophonePermission() async {
        // Check microphone permission
        print("Checking microphone permissions...")
    }
    
    private func switchToManualInput() async {
        // Switch to manual input mode
        print("Switching to manual input...")
    }
    
    private func suggestSimplifiedTopic() async {
        // Suggest simplified topic
        print("Suggesting simplified topic...")
    }
    
    private func useSampleContent() async {
        // Use sample content
        print("Using sample content...")
    }
    
    private func scheduleRetryLater() async {
        // Schedule retry for later
        print("Scheduling retry for later...")
    }
    
    // MARK: - Avatar Companion Recovery Actions
    
    private func retryAvatarConnection() async {
        // Retry avatar companion connection
        print("Retrying avatar companion connection...")
    }
    
    private func fallbackToBasicChat() async {
        // Fallback to basic chat mode
        print("Falling back to basic chat mode...")
    }
    
    private func restartAvatarSystem() async {
        // Restart the avatar companion system
        print("Restarting avatar companion system...")
    }
    
    private func checkPermissions() async {
        // Check and request necessary permissions
        print("Checking permissions...")
    }
    
    private func waitAndRetry() async {
        // Wait for system to be ready and retry
        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        await retryAvatarConnection()
    }
    
    private func forceInitializeSystem() async {
        // Force initialize the system
        print("Force initializing avatar companion system...")
    }
}

// MARK: - Error Types

struct LyoError: Error, Identifiable {
    let id = UUID()
    let type: ErrorType
    let title: String
    let message: String
    let context: ErrorContext?
    let timestamp: Date
    let shouldShowToUser: Bool
    let canRetry: Bool
    
    static func from(_ error: Error, context: ErrorContext? = nil) -> LyoError {
        switch error {
        case let apiError as APIError:
            return LyoError(
                type: .apiError(apiError),
                title: "API Error",
                message: apiError.localizedDescription,
                context: context,
                timestamp: Date(),
                shouldShowToUser: true,
                canRetry: !LyoError.isUnauthorizedError(apiError)
            )
            
        case let wsError as WebSocketError:
            return LyoError(
                type: .webSocketError(wsError),
                title: "Connection Error",
                message: wsError.localizedDescription,
                context: context,
                timestamp: Date(),
                shouldShowToUser: false,
                canRetry: true
            )
            
        case let coordinatorError where coordinatorError.localizedDescription.contains("Avatar"):
            return LyoError(
                type: .avatarCompanionError,
                title: "Avatar Companion Error",
                message: coordinatorError.localizedDescription,
                context: context,
                timestamp: Date(),
                shouldShowToUser: false,
                canRetry: true
            )
            
        default:
            return LyoError(
                type: .networkError,
                title: "Network Error",
                message: error.localizedDescription,
                context: context,
                timestamp: Date(),
                shouldShowToUser: true,
                canRetry: true
            )
        }
    }
    
    static let maxRetriesExceeded = LyoError(
        type: .maxRetriesExceeded,
        title: "Max Retries Exceeded",
        message: "Unable to complete the operation after multiple attempts",
        context: nil,
        timestamp: Date(),
        shouldShowToUser: true,
        canRetry: false
    )
    
    static func isUnauthorizedError(_ error: APIError) -> Bool {
        switch error {
        case .unauthorized:
            return true
        default:
            return false
        }
    }
}

enum ErrorType {
    case networkError
    case apiError(APIError)
    case webSocketError(WebSocketError)
    case voiceRecognitionError
    case courseGenerationError
    case lessonContentError
    case authenticationError
    case maxRetriesExceeded
    case avatarCompanionError
}


struct ErrorContext {
    let operation: String
    let endpoint: String
    let userAction: String
}

struct RecoveryAction {
    let title: String
    let action: () async -> Void
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    @ObservedObject var errorService: ErrorHandlingService
    @State private var showingRecoveryOptions = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content here
        }
        .alert("Error", isPresented: $errorService.isShowingErrorAlert) {
            if let error = errorService.currentError {
                if error.canRetry {
                    Button("Retry") {
                        Task {
                            await errorService.retryLastOperation()
                        }
                    }
                }
                
                Button("More Options") {
                    showingRecoveryOptions = true
                }
                
                Button("Dismiss") {
                    errorService.clearError()
                }
            }
        } message: {
            Text(errorService.currentError?.message ?? "An unknown error occurred")
        }
        .sheet(isPresented: $showingRecoveryOptions) {
            if let error = errorService.currentError {
                RecoveryOptionsView(error: error)
            }
        }
    }
}

struct RecoveryOptionsView: View {
    let error: LyoError
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Error details
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(error.title)
                        .font(DesignTokens.Typography.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(error.message)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    if let context = error.context {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Context:")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Text("Operation: \(context.operation)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Text("Endpoint: \(context.endpoint)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.glassBg)
                )
                
                // Recovery actions
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("Recovery Options")
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    let recoveryActions = ErrorHandlingService.shared.getRecoverySuggestions(for: error)
                    
                    ForEach(recoveryActions.indices, id: \.self) { index in
                        Button(recoveryActions[index].title) {
                            Task {
                                await recoveryActions[index].action()
                                dismiss()
                            }
                        }
                        .font(DesignTokens.Typography.buttonLabel)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(DesignTokens.Colors.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Error Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions

extension ErrorHandlingService {
    /// Convenience method for API calls with error handling
    func performAPICall<T>(
        identifier: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await retryWithBackoff(identifier: identifier) {
            do {
                return try await operation()
            } catch let error as APIError {
                self.handleAPIError(error, endpoint: identifier)
                throw error
            } catch {
                self.handleError(error)
                throw error
            }
        }
    }
    
    /// Convenience method for WebSocket operations
    func performWebSocketOperation<T>(
        identifier: String,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        do {
            return try await operation()
        } catch let error as WebSocketError {
            handleWebSocketError(error)
            throw error
        } catch {
            handleError(error)
            throw error
        }
    }
}