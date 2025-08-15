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
        // === PRIMARY SYSTEM ===
        // Brand Color (Strategic use only)
        static let brand = Color(hex: "6366F1") // Electric indigo - use sparingly for maximum impact
        
        // Accent Color (Secondary actions and highlights)
        static let accent = Color(hex: "EC4899") // Neon pink - for secondary emphasis
        
        // === SEMANTIC COLORS ===
        static let success = Color(hex: "00E664")   // Success green
        static let warning = Color(hex: "FFB800")   // Warning amber
        static let error = Color(hex: "FF4D4D")     // Error red
        static let info = Color(hex: "00CCFF")      // Info cyan
        
        // === NEUTRAL PALETTE (Primary Interface Colors) ===
        static let neutral50 = Color(hex: "F8FAFC")   // Near white
        static let neutral100 = Color(hex: "F1F5F9")  // Very light gray
        static let neutral200 = Color(hex: "E2E8F0")  // Light gray
        static let neutral300 = Color(hex: "CBD5E1")  // Medium light gray
        static let neutral400 = Color(hex: "94A3B8")  // Medium gray
        static let neutral500 = Color(hex: "64748B")  // True gray
        static let neutral600 = Color(hex: "475569")  // Medium dark gray
        static let neutral700 = Color(hex: "334155")  // Dark gray
        static let neutral800 = Color(hex: "1E293B")  // Very dark gray
        static let neutral900 = Color(hex: "0F172A")  // Near black
        
        // === BACKGROUND SYSTEM ===
        static let backgroundPrimary = Color(hex: "0A0A0F")    // Deep space background
        static let backgroundSecondary = Color(hex: "151520")  // Secondary dark
        static let backgroundTertiary = Color(hex: "1E1E2E")   // Tertiary dark
        static let backgroundElevated = Color(hex: "252532")   // Elevated surfaces
        
        // === CARD SYSTEM ===
        static let cardBg = backgroundElevated               // Card background
        
        // === TEXT SYSTEM ===
        static let textPrimary = neutral50      // Primary text (highest contrast)
        static let textSecondary = neutral300   // Secondary text
        static let textTertiary = neutral500    // Tertiary text (subtle)
        static let textDisabled = neutral600    // Disabled text
        static let textInverse = neutral900     // Text on light backgrounds
        
        // === ENHANCED NEON ACCENTS (Used sparingly for special effects) ===
        static let neonBlue = Color(hex: "00CCFF")
        static let neonPurple = Color(hex: "CC66FF")
        static let neonGreen = Color(hex: "00FF99")
        static let neonPink = Color(hex: "FF3399")
        static let neonYellow = Color(hex: "FFFF00")
        static let neonOrange = Color(hex: "FF6600")
        
        // === LEGACY SUPPORT ===
        static let primary = brand
        static let secondary = Color(hex: "8B5CF6")
        static let tertiary = Color(hex: "06B6D4")
        static let quaternary = accent
        
        // Legacy glass colors
        static let glassBg = Glass.contentLayer.background
        static let glassBorder = Glass.contentLayer.border
        static let glassOverlay = Color.black.opacity(0.2)
        static let glassHighlight = Color.white.opacity(0.2)
        
        // Legacy mappings
        static let primaryBg = backgroundPrimary
        static let secondaryBg = backgroundSecondary
        static let tertiaryBg = backgroundTertiary
        static let background = backgroundPrimary
        static let secondaryBackground = backgroundSecondary
        static let tertiaryBackground = backgroundTertiary
        static let label = textPrimary
        static let secondaryLabel = textSecondary
        static let tertiaryLabel = textTertiary
        
        // Legacy neutral colors (for backward compatibility)
        static let black = Color(hex: "000000")
        static let white = Color(hex: "FFFFFF")
        static let gray50 = neutral50.opacity(0.95)
        static let gray100 = neutral50.opacity(0.9)
        static let gray200 = neutral50.opacity(0.8)
        static let gray300 = neutral50.opacity(0.6)
        static let gray400 = neutral50.opacity(0.4)
        static let gray500 = neutral50.opacity(0.3)
        static let gray600 = neutral50.opacity(0.2)
        static let gray700 = neutral50.opacity(0.15)
        static let gray800 = neutral50.opacity(0.1)
        static let gray900 = neutral50.opacity(0.05)
        
        // === ENHANCED GRADIENTS ===
        static let brandGradient = LinearGradient(
            colors: [brand, brand.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let heroGradient = LinearGradient(
            colors: [brand, secondary, tertiary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cosmicGradient = LinearGradient(
            colors: [backgroundPrimary, Color(hex: "0F0F1A"), Color(hex: "1A1A2E"), Color(hex: "2D1B69"), brand],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let neonGradient = LinearGradient(
            colors: [neonBlue, neonPurple, neonPink],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let subtleGradient = LinearGradient(
            colors: [neutral800, neutral700],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Legacy gradient support
        static let primaryGradient = brandGradient
        static let glassGradient = LinearGradient(
            colors: [Glass.contentLayer.background, Glass.contentLayer.background.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Professional Typography System
    struct Typography {
        // === DISPLAY TYPOGRAPHY ===
        static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)
        
        // === HEADLINE TYPOGRAPHY ===
        static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
        static let headlineMedium = Font.system(size: 28, weight: .bold, design: .default)
        static let headlineSmall = Font.system(size: 24, weight: .bold, design: .default)
        
        // === TITLE TYPOGRAPHY ===
        static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
        static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
        static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)
        
        // === LABEL TYPOGRAPHY ===
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        
        // === BODY TYPOGRAPHY ===
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // === FUTURISTIC VARIANTS ===
        static let heroDisplay = Font.system(size: 48, weight: .heavy, design: .rounded)
        static let quantumTitle = Font.system(size: 20, weight: .semibold, design: .monospaced)
        static let techLabel = Font.system(size: 13, weight: .medium, design: .monospaced)
        
        // === LEGACY SUPPORT ===
        static let largeTitle = displayMedium
        static let title1 = headlineLarge
        static let title2 = headlineMedium
        static let title3 = headlineSmall
        static let body = bodyMedium
        static let bodyMediumWeight = Font.system(size: 14, weight: .medium, design: .default)
        static let bodyBold = Font.system(size: 14, weight: .bold, design: .default)
        static let caption = bodySmall
        static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        static let headline = titleLarge
        static let subheadline = titleMedium
        static let footnote = labelSmall
        static let hero = heroDisplay
        static let buttonLabel = labelLarge
        static let cardTitle = titleMedium
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
        
        // Semantic Spacing
        static let padding = md
        static let margin = lg
        static let sectionSpacing = xl
    }
    
    // MARK: - Radius
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let round: CGFloat = 50
        
        // Semantic Radius
        static let button = md
        static let card = lg
        static let sheet = xl
    }
    
    // MARK: - Enhanced Shadow System
    struct Shadows {
        // === ELEVATION SHADOWS ===
        static let elevation0 = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
        static let elevation1 = ShadowStyle(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
        static let elevation2 = ShadowStyle(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 2)
        static let elevation3 = ShadowStyle(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
        static let elevation4 = ShadowStyle(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
        static let elevation5 = ShadowStyle(color: Color.black.opacity(0.30), radius: 16, x: 0, y: 8)
        
        // === GLOW EFFECTS ===
        static let brandGlow = ShadowStyle(color: Colors.brand.opacity(0.4), radius: 20, x: 0, y: 0)
        static let accentGlow = ShadowStyle(color: Colors.accent.opacity(0.4), radius: 16, x: 0, y: 0)
        static let successGlow = ShadowStyle(color: Colors.success.opacity(0.3), radius: 12, x: 0, y: 0)
        static let errorGlow = ShadowStyle(color: Colors.error.opacity(0.3), radius: 12, x: 0, y: 0)
        
        // === QUANTUM EFFECTS ===
        static let neonBlueGlow = ShadowStyle(color: Colors.neonBlue.opacity(0.5), radius: 24, x: 0, y: 0)
        static let neonPinkGlow = ShadowStyle(color: Colors.neonPink.opacity(0.5), radius: 24, x: 0, y: 0)
        static let quantumGlow = ShadowStyle(color: Colors.neonPurple.opacity(0.4), radius: 32, x: 0, y: 0)
        
        // === TEXT EFFECTS ===
        static let textGlow = ShadowStyle(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 1)
        static let textOutline = ShadowStyle(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 0)
        
        // === DRAMATIC SHADOWS ===
        static let dramatic = ShadowStyle(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
        static let floating = ShadowStyle(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        static let pressed = ShadowStyle(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        
        // === CYBERPUNK EFFECTS ===
        static let primaryGlow = ShadowStyle(color: Colors.primary.opacity(0.4), radius: 20, x: 0, y: 0)
        static let secondaryGlow = ShadowStyle(color: Colors.secondary.opacity(0.3), radius: 16, x: 0, y: 0)
        static let cyberGlow = ShadowStyle(color: Colors.tertiary.opacity(0.4), radius: 24, x: 0, y: 0)
        static let deepShadow = ShadowStyle(color: Color.black.opacity(0.6), radius: 32, x: 0, y: 8)
    }    // MARK: - Professional Animation System
    struct Animations {
        // === MICRO-INTERACTIONS ===
        static let instant = Animation.easeInOut(duration: 0.1)
        static let quick = Animation.easeInOut(duration: 0.2)
        static let smooth = Animation.easeInOut(duration: 0.3)
        static let gentle = Animation.easeInOut(duration: 0.4)
        static let slow = Animation.easeInOut(duration: 0.6)
        
        // === SPRING ANIMATIONS ===
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let fluid = Animation.spring(response: 0.4, dampingFraction: 0.9)
        static let elastic = Animation.spring(response: 0.5, dampingFraction: 0.6)
        
        // === BUTTON INTERACTIONS ===
        static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.6)
        static let buttonRelease = Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let hover = Animation.spring(response: 0.4, dampingFraction: 0.9)
        
        // === NAVIGATION ===
        static let pageTransition = Animation.spring(response: 0.5, dampingFraction: 0.9)
        static let modalPresent = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let slideIn = Animation.easeOut(duration: 0.4)
        static let fadeIn = Animation.easeInOut(duration: 0.3)
        
        // === LOADING STATES ===
        static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
        static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        static let breathe = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        
        // === FUTURISTIC EFFECTS ===
        static let quantum = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
        static let cosmic = Animation.linear(duration: 20.0).repeatForever(autoreverses: false)
        static let glow = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        static let float = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
        static let rotate = Animation.linear(duration: 8.0).repeatForever(autoreverses: false)
        
        // === HAPTIC FEEDBACK TIMING ===
        static let hapticLight = Duration.milliseconds(50)
        static let hapticMedium = Duration.milliseconds(100)
        static let hapticHeavy = Duration.milliseconds(150)
        
        // === LEGACY SUPPORT ===
        static let cardHover = hover
    }
}

// MARK: - Professional UI Components Support

// MARK: - Glass Effect System
struct GlassEffect {
    let background: Color
    let border: Color
    let blur: CGFloat
    let innerGlow: Color
    
    /// Apply this glass effect to a view
    func apply<Content: View>(to content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Base glass background
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .fill(background)
                        .background(.ultraThinMaterial)
                    
                    // Inner glow
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .strokeBorder(
                            LinearGradient(
                                colors: [innerGlow, Color.clear, innerGlow],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    
                    // Outer border
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .strokeBorder(border, lineWidth: 0.5)
                }
            )
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: DesignTokens.Radius.card))
    }
}

// MARK: - Enhanced Text Styles
struct TextStyle {
    let font: Font
    let color: Color
    let shadow: ShadowStyle?
    let tracking: CGFloat
    
    static let heroTitle = TextStyle(
        font: DesignTokens.Typography.heroDisplay,
        color: DesignTokens.Colors.textPrimary,
        shadow: DesignTokens.Shadows.textGlow,
        tracking: -0.5
    )
    
    static let cardTitle = TextStyle(
        font: DesignTokens.Typography.titleLarge,
        color: DesignTokens.Colors.textPrimary,
        shadow: DesignTokens.Shadows.textOutline,
        tracking: 0
    )
    
    static let bodyText = TextStyle(
        font: DesignTokens.Typography.bodyMedium,
        color: DesignTokens.Colors.textSecondary,
        shadow: nil,
        tracking: 0
    )
    
    static let caption = TextStyle(
        font: DesignTokens.Typography.labelSmall,
        color: DesignTokens.Colors.textTertiary,
        shadow: nil,
        tracking: 0.2
    )
}

// MARK: - Professional Button Styles
struct ButtonConfiguration {
    let background: Color
    let foreground: Color
    let border: Color?
    let shadow: ShadowStyle
    let pressedScale: CGFloat
    let animation: Animation
    
    static let primary = ButtonConfiguration(
        background: DesignTokens.Colors.brand,
        foreground: DesignTokens.Colors.white,
        border: nil,
        shadow: DesignTokens.Shadows.brandGlow,
        pressedScale: 0.95,
        animation: DesignTokens.Animations.buttonPress
    )
    
    static let secondary = ButtonConfiguration(
        background: DesignTokens.Glass.interactiveLayer.background,
        foreground: DesignTokens.Colors.textPrimary,
        border: DesignTokens.Glass.interactiveLayer.border,
        shadow: DesignTokens.Shadows.elevation2,
        pressedScale: 0.97,
        animation: DesignTokens.Animations.buttonPress
    )
    
    static let ghost = ButtonConfiguration(
        background: Color.clear,
        foreground: DesignTokens.Colors.brand,
        border: DesignTokens.Colors.brand,
        shadow: DesignTokens.Shadows.elevation0,
        pressedScale: 0.98,
        animation: DesignTokens.Animations.quick
    )
}

// MARK: - Loading States
struct LoadingStyle {
    static let shimmerColors = [
        DesignTokens.Colors.neutral800,
        DesignTokens.Colors.neutral600,
        DesignTokens.Colors.neutral800
    ]
    
    static let pulseOpacity: ClosedRange<Double> = 0.3...0.8
    static let shimmerAnimation = DesignTokens.Animations.shimmer
    static let pulseAnimation = DesignTokens.Animations.pulse
}

// MARK: - Supporting Types
// MARK: - Professional Shadow Effect
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    var viewModifier: some ViewModifier {
        ShadowModifier(shadow: self)
    }
}

struct ShadowModifier: ViewModifier {
    let shadow: ShadowStyle
    
    func body(content: Content) -> some View {
        content.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

// MARK: - Color Extension
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    /// Create a color with enhanced contrast for glassmorphic backgrounds
    func withReadabilityEnhancement() -> Color {
        // For glassmorphic backgrounds, we enhance the color itself rather than adding shadows
        return Color(
            red: min(1.0, self.rgba.red + 0.1),
            green: min(1.0, self.rgba.green + 0.1),
            blue: min(1.0, self.rgba.blue + 0.1),
            opacity: min(1.0, self.rgba.alpha + 0.2)
        )
    }
    
    /// Get RGBA components for color manipulation
    private var rgba: (red: Double, green: Double, blue: Double, alpha: Double) {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Double(red), Double(green), Double(blue), Double(alpha))
    }
}

// MARK: - View Extensions for Professional Polish
extension View {
    /// Apply a professional glass effect
    func glassEffect(_ style: GlassEffect = DesignTokens.Glass.contentLayer) -> some View {
        style.apply(to: self)
    }
    
    /// Apply professional text shadow for readability
    func textReadability() -> some View {
        self.shadow(color: .black.opacity(0.8), radius: 2, x: 0, y: 1)
    }
    
    /// Apply haptic feedback on tap
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.onTapGesture {
            HapticManager.shared.light()
        }
    }
    
    /// Apply professional button interaction
    func buttonInteraction(
        scale: CGFloat = 0.95,
        animation: Animation = DesignTokens.Animations.buttonPress
    ) -> some View {
        self.scaleEffect(1.0)
            .animation(animation, value: scale)
    }
    
    /// Apply skeleton loading state
    func skeletonLoading(_ isLoading: Bool) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(
                    LinearGradient(
                        colors: LoadingStyle.shimmerColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .opacity(isLoading ? 1 : 0)
                .animation(LoadingStyle.shimmerAnimation, value: isLoading)
        )
    }
}
