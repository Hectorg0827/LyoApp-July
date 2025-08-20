import SwiftUI
import Foundation

// MARK: - Enhanced Design Tokens
struct DesignTokens {
    
    // MARK: - Layered Glassmorphism System
    struct Glass {
        // Base Layer - Furthest Back (Subtle, non-distracting)
        static let baseLayer = GlassEffect(
            background: Color.white.opacity(0.03),
            border: Color.white.opacity(0.05),
            blur: 2.0,
            innerGlow: Color.white.opacity(0.02)
        )
        
        // Content Layer - Middle (Readable, content-focused)
        static let contentLayer = GlassEffect(
            background: Color.white.opacity(0.08),
            border: Color.white.opacity(0.12),
            blur: 8.0,
            innerGlow: Color.white.opacity(0.06)
        )
        
        // Interactive Layer - Closest (High transparency, crisp borders)
        static let interactiveLayer = GlassEffect(
            background: Color.white.opacity(0.12),
            border: Color.white.opacity(0.2),
            blur: 12.0,
            innerGlow: Color.white.opacity(0.1)
        )
        
        // Frosted Variant - For text-heavy content
        static let frostedLayer = GlassEffect(
            background: Color.white.opacity(0.15),
            border: Color.white.opacity(0.25),
            blur: 6.0,
            innerGlow: Color.white.opacity(0.08)
        )
        
        // Active/Pressed State
        static let activeLayer = GlassEffect(
            background: Colors.primary.opacity(0.15),
            border: Colors.primary.opacity(0.3),
            blur: 10.0,
            innerGlow: Colors.primary.opacity(0.1)
        )
    }
    
    // MARK: - Professional Color System
    struct Colors {
        // Core Brand Identity
        static let primary = Color(hex: "6366F1") // Indigo-500
        static let primaryDark = Color(hex: "4F46E5") // Indigo-600
        static let primaryLight = Color(hex: "A5B4FC") // Indigo-300
        
        // Accent & Support Colors
        static let accent = Color(hex: "EC4899") // Pink-500
        static let accentLight = Color(hex: "F9A8D4") // Pink-300
        static let success = Color(hex: "10B981") // Emerald-500
        static let warning = Color(hex: "F59E0B") // Amber-500
        static let error = Color(hex: "EF4444") // Red-500
        
        // Gradients
        static let primaryGradient = LinearGradient(
            gradient: Gradient(colors: [primary, primaryDark]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let accentGradient = LinearGradient(
            gradient: Gradient(colors: [accent, accentLight]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let heroGradient = LinearGradient(
            gradient: Gradient(colors: [
                primary.opacity(0.8),
                accent.opacity(0.6),
                primaryLight.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // Background System
        static let primaryBg = Color(hex: "0F0F23") // Deep space blue
        static let secondaryBg = Color(hex: "1A1B3A") // Midnight purple
        static let tertiaryBg = Color(hex: "252749") // Slate purple
        static let surfaceBg = Color(hex: "2D2F5F") // Surface purple
        
        // Glassmorphism Backgrounds
        static let glassBg = Color.white.opacity(0.08)
        static let glassBgStrong = Color.white.opacity(0.15)
        static let glassBorder = Color.white.opacity(0.2)
        
        // Text Colors (Accessible)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        static let textAccent = accent
        
        // Interactive States
        static let interactive = Color.white.opacity(0.1)
        static let interactiveHover = Color.white.opacity(0.15)
        static let interactivePressed = Color.white.opacity(0.05)
        
        // Status Colors
        static let online = Color(hex: "10B981")
        static let offline = Color(hex: "6B7280")
        static let away = Color(hex: "F59E0B")
        static let busy = Color(hex: "EF4444")
    }
    
    // MARK: - Spacing System
    struct Spacing {
        static let xs: CGFloat = 4   // 4pt
        static let sm: CGFloat = 8   // 8pt
        static let md: CGFloat = 12  // 12pt
        static let lg: CGFloat = 16  // 16pt
        static let xl: CGFloat = 24  // 24pt
        static let xxl: CGFloat = 32 // 32pt
        static let xxxl: CGFloat = 48 // 48pt
        
        // Semantic spacing
        static let cardPadding = lg
        static let sectionPadding = xl
        static let screenPadding = lg
    }
    
    // MARK: - Border Radius
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let full: CGFloat = 9999
        
        // Semantic radius
        static let button = md
        static let card = lg
        static let modal = xl
    }
    
    // MARK: - Shadows & Effects
    struct Shadows {
        static let subtle = (
            color: Color.black.opacity(0.05),
            radius: CGFloat(2),
            x: CGFloat(0),
            y: CGFloat(1)
        )
        
        static let soft = (
            color: Color.black.opacity(0.1),
            radius: CGFloat(4),
            x: CGFloat(0),
            y: CGFloat(2)
        )
        
        static let medium = (
            color: Color.black.opacity(0.15),
            radius: CGFloat(8),
            x: CGFloat(0),
            y: CGFloat(4)
        )
        
        static let strong = (
            color: Color.black.opacity(0.2),
            radius: CGFloat(16),
            x: CGFloat(0),
            y: CGFloat(8)
        )
        
        static let glow = (
            color: Colors.primary.opacity(0.3),
            radius: CGFloat(20),
            x: CGFloat(0),
            y: CGFloat(8)
        )
    }
    
    // MARK: - Typography System
    struct Typography {
        // Display Text
        static let displayLarge = Font.system(size: 57, weight: .regular, design: .default)
        static let displayMedium = Font.system(size: 45, weight: .regular, design: .default)
        static let displaySmall = Font.system(size: 36, weight: .regular, design: .default)
        
        // Headlines
        static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
        static let headlineMedium = Font.system(size: 28, weight: .bold, design: .default)
        static let headlineSmall = Font.system(size: 24, weight: .bold, design: .default)
        
        // Titles
        static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
        static let titleMedium = Font.system(size: 16, weight: .semibold, design: .default)
        static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)
        
        // Body Text
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Labels
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
    }
    
    // MARK: - Animation Presets
    struct Animations {
        static let instant = Animation.easeInOut(duration: 0.1)
        static let quick = Animation.easeInOut(duration: 0.2)
        static let smooth = Animation.easeInOut(duration: 0.3)
        static let gentle = Animation.easeInOut(duration: 0.5)
        static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let bounce = Animation.interpolatingSpring(stiffness: 300, damping: 30)
    }
    
    // MARK: - Layout Constants
    struct Layout {
        static let minTouchTarget: CGFloat = 44
        static let maxContentWidth: CGFloat = 428
        static let tabBarHeight: CGFloat = 83
        static let navigationBarHeight: CGFloat = 44
        static let statusBarHeight: CGFloat = 47
    }
}

// MARK: - Glass Effect Structure
struct GlassEffect {
    let background: Color
    let border: Color
    let blur: CGFloat
    let innerGlow: Color
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extensions for Design System
extension View {
    // Apply glass effect
    func glassEffect(_ effect: GlassEffect) -> some View {
        self
            .background(
                ZStack {
                    effect.background
                    effect.innerGlow
                        .blendMode(.softLight)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(effect.border, lineWidth: 1)
            )
            .blur(radius: effect.blur)
    }
    
    // Apply shadows
    func designShadow(_ shadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat)) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    // Standard card styling
    func cardStyle() -> some View {
        self
            .background(DesignTokens.Colors.glassBg)
            .cornerRadius(DesignTokens.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                    .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
            )
            .designShadow(DesignTokens.Shadows.soft)
    }
    
    // Interactive button styling
    func buttonStyle(isPressed: Bool = false) -> some View {
        self
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .brightness(isPressed ? -0.05 : 0)
            .animation(DesignTokens.Animations.quick, value: isPressed)
    }
}

// MARK: - Compatibility alias for existing code
typealias Tokens = DesignTokens

#Preview {
    VStack(spacing: DesignTokens.Spacing.md) {
        Text("Display Large")
            .font(DesignTokens.Typography.displayLarge)
            .foregroundColor(DesignTokens.Colors.textPrimary)
        Text("Headline Large")
            .font(DesignTokens.Typography.headlineLarge)
            .foregroundColor(DesignTokens.Colors.textSecondary)
        Text("Body text")
            .font(DesignTokens.Typography.bodyMedium)
            .foregroundColor(DesignTokens.Colors.textTertiary)
        Text("Label text")
            .font(DesignTokens.Typography.labelMedium)
            .foregroundColor(DesignTokens.Colors.textAccent)
        
        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
            .fill(DesignTokens.Colors.glassBg)
            .frame(height: 100)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
            )
            .designShadow(DesignTokens.Shadows.medium)
    }
    .padding()
    .background(DesignTokens.Colors.primaryBg)
}
