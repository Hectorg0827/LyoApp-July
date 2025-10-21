import SwiftUI

// MARK: - Design System
struct DesignSystem {
    
    // MARK: - Button Styles
    struct ButtonStyles {
        
        struct PrimaryButtonStyle: ButtonStyle {
            let isLoading: Bool
            
            init(isLoading: Bool = false) {
                self.isLoading = isLoading
            }
            
            func makeBody(configuration: ButtonStyle.Configuration) -> some View {
                configuration.label
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .fill(DesignTokens.Colors.primaryGradient)
                            .opacity(configuration.isPressed ? 0.8 : 1.0)
                    )
                    .overlay(
                        Group {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                        }
                    )
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .animation(DesignTokens.Animations.quick, value: configuration.isPressed)
                    .disabled(isLoading)
            }
        }
        
        struct SecondaryButtonStyle: ButtonStyle {
            func makeBody(configuration: ButtonStyle.Configuration) -> some View {
                configuration.label
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .strokeBorder(DesignTokens.Colors.primary, lineWidth: 2)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .fill(DesignTokens.Colors.background)
                            )
                    )
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .animation(DesignTokens.Animations.quick, value: configuration.isPressed)
            }
        }
        
        struct FloatingActionButtonStyle: ButtonStyle {
            func makeBody(configuration: ButtonStyle.Configuration) -> some View {
                configuration.label
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(DesignTokens.Colors.primaryGradient)
                            .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                    .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
                    .animation(DesignTokens.Animations.bouncy, value: configuration.isPressed)
            }
        }
    }
    
    // MARK: - Card Styles
    struct CardView<Content: View>: View {
        let content: Content
        let padding: CGFloat
        let cornerRadius: CGFloat
        
        init(
            padding: CGFloat = DesignTokens.Spacing.md,
            cornerRadius: CGFloat = DesignTokens.Radius.card,
            @ViewBuilder content: () -> Content
        ) {
            self.content = content()
            self.padding = padding
            self.cornerRadius = cornerRadius
        }
        
        var body: some View {
            content
                .padding(padding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(DesignTokens.Colors.background)
                        .shadow(
                            color: DesignTokens.Shadows.elevation2.color,
                            radius: DesignTokens.Shadows.elevation2.radius,
                            x: DesignTokens.Shadows.elevation2.x,
                            y: DesignTokens.Shadows.elevation2.y
                        )
                )
        }
    }
    
    // MARK: - Text Field Styles
    struct ModernTextFieldStyle: TextFieldStyle {
        let isValid: Bool
        let isFocused: Bool
        
        init(isValid: Bool = true, isFocused: Bool = false) {
            self.isValid = isValid
            self.isFocused = isFocused
        }
        
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .font(DesignTokens.Typography.body)
                .padding(DesignTokens.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.secondaryBackground)
                        .strokeBorder(
                            borderColor,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
                .animation(DesignTokens.Animations.quick, value: isFocused)
        }
        
        private var borderColor: Color {
            if !isValid {
                return DesignTokens.Colors.error
            } else if isFocused {
                return DesignTokens.Colors.primary
            } else {
                return DesignTokens.Colors.gray300
            }
        }
    }
    
    // MARK: - Badge Component
    struct Badge: View {
        let text: String
        let style: BadgeStyle
        
        enum BadgeStyle {
            case primary, secondary, success, warning, error
            
            var backgroundColor: Color {
                switch self {
                case .primary: return DesignTokens.Colors.primary
                case .secondary: return DesignTokens.Colors.secondary
                case .success: return DesignTokens.Colors.success
                case .warning: return DesignTokens.Colors.warning
                case .error: return DesignTokens.Colors.error
                }
            }
        }
        
        var body: some View {
            Text(text)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, DesignTokens.Spacing.sm)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    Capsule()
                        .fill(style.backgroundColor)
                )
        }
    }
    
    // MARK: - User Avatar Component
    struct UserAvatarView: View {
        let imageURL: String?
        let name: String
        let size: CGFloat
        
        init(imageURL: String? = nil, name: String, size: CGFloat = 40) {
            self.imageURL = imageURL
            self.name = name
            self.size = size
        }
        
        var body: some View {
            Group {
                if let imageURL = imageURL, !imageURL.isEmpty {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        avatarPlaceholder
                    }
                } else {
                    avatarPlaceholder
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }
        
        private var avatarPlaceholder: some View {
            Text(String(name.prefix(1).uppercased()))
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                )
        }
    }
    
    // MARK: - Loading State View
    struct LoadingStateView: View {
        let message: String
        
        init(message: String) {
            self.message = message
        }
        
        var body: some View {
            VStack(spacing: DesignTokens.Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(DesignTokens.Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DesignTokens.Colors.background)
        }
    }
}

// MARK: - View Extensions
extension View {
    func primaryButton(isLoading: Bool = false) -> some View {
        self.buttonStyle(DesignSystem.ButtonStyles.PrimaryButtonStyle(isLoading: isLoading))
    }
    
    func secondaryButton() -> some View {
        self.buttonStyle(DesignSystem.ButtonStyles.SecondaryButtonStyle())
    }
    
    func floatingActionButton() -> some View {
        self.buttonStyle(DesignSystem.ButtonStyles.FloatingActionButtonStyle())
    }
    
    func modernTextField(isValid: Bool = true, isFocused: Bool = false) -> some View {
        self.textFieldStyle(DesignSystem.ModernTextFieldStyle(isValid: isValid, isFocused: isFocused))
    }
    
    func cardStyle(
        padding: CGFloat = DesignTokens.Spacing.md,
        cornerRadius: CGFloat = DesignTokens.Radius.card
    ) -> some View {
        DesignSystem.CardView(padding: padding, cornerRadius: cornerRadius) {
            self
        }
    }
}
