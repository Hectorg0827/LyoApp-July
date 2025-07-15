import SwiftUI
import Foundation

// MARK: - Loading States
enum LoadingState: Equatable {
    case idle
    case loading(message: String? = nil)
    case success
    case failure(AppError)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var error: AppError? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

// MARK: - Error Banner View
struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Error icon
            Image(systemName: iconName)
                .font(.title3)
                .foregroundColor(iconColor)
            
            // Error content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Error")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(error.localizedDescription)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Action buttons
            VStack(spacing: DesignTokens.Spacing.xs) {
                if let onRetry = onRetry, error.isRecoverable {
                    Button(error.recoveryAction) {
                        onRetry()
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.primary)
                }
                
                Button("Dismiss") {
                    withAnimation(.spring()) {
                        isVisible = false
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDismiss()
                    }
                }
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textTertiary)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .offset(y: isVisible ? 0 : -20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
    
    private var iconName: String {
        switch error {
        case .networkConnection:
            return "wifi.exclamationmark"
        case .serverError:
            return "server.rack"
        case .authenticationFailed:
            return "person.badge.shield.checkmark.fill"
        case .dataCorruption:
            return "externaldrive.badge.exclamationmark"
        case .microphonePermissionDenied:
            return "mic.slash.fill"
        case .cameraPermissionDenied:
            return "camera.fill"
        case .photoLibraryPermissionDenied:
            return "photo.fill"
        default:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch error {
        case .networkConnection, .serverError, .invalidResponse:
            return .orange
        case .authenticationFailed, .dataCorruption:
            return .red
        case .microphonePermissionDenied, .cameraPermissionDenied, .photoLibraryPermissionDenied:
            return .blue
        default:
            return .yellow
        }
    }
    
    private var borderColor: Color {
        iconColor.opacity(0.3)
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String?
    let showProgress: Bool
    
    @State private var animationOffset: CGFloat = 0
    @State private var rotationAngle: Double = 0
    
    init(message: String? = nil, showProgress: Bool = false) {
        self.message = message
        self.showProgress = showProgress
    }
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // Loading animation
            ZStack {
                // Outer ring
                Circle()
                    .stroke(DesignTokens.Colors.glassBorder, lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                // Inner animated ring
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        DesignTokens.Colors.primaryGradient,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotationAngle))
                    .animation(
                        .linear(duration: 1.0).repeatForever(autoreverses: false),
                        value: rotationAngle
                    )
                
                // Center dot
                Circle()
                    .fill(DesignTokens.Colors.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(1.0 + sin(animationOffset) * 0.3)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: animationOffset
                    )
            }
            
            // Loading message
            if let message = message {
                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Progress dots
            if showProgress {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(DesignTokens.Colors.primary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(1.0 + sin(animationOffset + Double(index) * 0.5) * 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: animationOffset
                            )
                    }
                }
            }
        }
        .onAppear {
            rotationAngle = 360
            animationOffset = .pi * 2
        }
    }
}
