import SwiftUI
import Foundation

// MARK: - Enhanced Design Tokens
public struct DesignTokens {

    // MARK: - Layered Glassmorphism System
    public struct Glass {
        // Base Layer - Furthest Back (Subtle, non-distracting)
        public static let baseLayer = GlassEffect(
            background: Color.white.opacity(0.03),
            border: Color.white.opacity(0.05),
            blur: 2.0,
            innerGlow: Color.white.opacity(0.02)
        )
        
        // Content Layer - Middle (Readable, content-focused)
        public static let contentLayer = GlassEffect(
            background: Color.white.opacity(0.08),
            border: Color.white.opacity(0.12),
            blur: 8.0,
            innerGlow: Color.white.opacity(0.06)
        )
        
        // Interactive Layer - Closest (High transparency, crisp borders)
        public static let interactiveLayer = GlassEffect(
            background: Color.white.opacity(0.12),
            border: Color.white.opacity(0.2),
            blur: 12.0,
            innerGlow: Color.white.opacity(0.1)
        )
        
        // Frosted Variant - For text-heavy content
        public static let frostedLayer = GlassEffect(
            background: Color.white.opacity(0.15),
            border: Color.white.opacity(0.25),
            blur: 6.0,
            innerGlow: Color.white.opacity(0.08)
        )
        
        // Active/Pressed State
        public static let activeLayer = GlassEffect(
            background: Colors.primary.opacity(0.15),
            border: Colors.primary.opacity(0.3),
            blur: 10.0,
            innerGlow: Colors.primary.opacity(0.1)
        )
    }
    
    // MARK: - Professional Color System
    public struct Colors {
        // === PRIMARY SYSTEM ===
        // Brand Color (Strategic use only)
        public static let brand = Color("6366F1") // Electric indigo - use sparingly for maximum impact
        
        // Accent Color (Secondary actions and highlights)
        public static let accent = Color("EC4899") // Neon pink - for secondary emphasis
        
        // === SEMANTIC COLORS ===
        public static let success = Color("00E664")   // Success green
        public static let warning = Color("FFB800")   // Warning amber
        public static let error = Color("FF4D4D")     // Error red
        public static let info = Color("00CCFF")      // Info cyan
        
        // === NEUTRAL PALETTE (Primary Interface Colors) ===
        public static let neutral50 = Color("F8FAFC")   // Near white
        public static let neutral100 = Color("F1F5F9")  // Very light gray
        public static let neutral200 = Color("E2E8F0")  // Light gray
        public static let neutral300 = Color("CBD5E1")  // Medium light gray
        public static let neutral400 = Color("94A3B8")  // Medium gray
        public static let neutral500 = Color("64748B")  // True gray
        public static let neutral600 = Color("475569")  // Medium dark gray
        public static let neutral700 = Color("334155")  // Dark gray
        public static let neutral800 = Color("1E293B")  // Very dark gray
        public static let neutral900 = Color("0F172A")  // Near black
        
        // === BACKGROUND SYSTEM ===
        public static let backgroundPrimary = Color("0A0A0F")    // Deep space background
        public static let backgroundSecondary = Color("151520")  // Secondary dark
        public static let backgroundTertiary = Color("1E1E2E")   // Tertiary dark
        public static let backgroundElevated = Color("252532")   // Elevated surfaces
        
        // === CARD SYSTEM ===
        public static let cardBg = backgroundElevated               // Card background
        
        // === TEXT SYSTEM ===
        public static let textPrimary = neutral50      // Primary text (highest contrast)
        public static let textSecondary = neutral300   // Secondary text
        public static let textTertiary = neutral500    // Tertiary text (subtle)
        public static let textDisabled = neutral600    // Disabled text
        public static let textInverse = neutral900     // Text on light backgrounds
        
        // === ENHANCED NEON ACCENTS (Used sparingly for special effects) ===
        public static let neonBlue = Color("00CCFF")
        public static let neonPurple = Color("CC66FF")
        public static let neonGreen = Color("00FF99")
        public static let neonPink = Color("FF3399")
        public static let neonYellow = Color("FFFF00")
        public static let neonOrange = Color("FF6600")
        
        // === LEGACY SUPPORT ===
        public static let primary = brand
        public static let secondary = Color("8B5CF6")
        public static let tertiary = Color("06B6D4")
        public static let quaternary = accent
        
        // Legacy glass colors
        public static let glassBg = Glass.contentLayer.background
        public static let glassBorder = Glass.contentLayer.border
        public static let glassOverlay = Color.black.opacity(0.2)
        public static let glassHighlight = Color.white.opacity(0.2)
        
        // Legacy mappings
        public static let primaryBg = backgroundPrimary
        public static let secondaryBg = backgroundSecondary
        public static let tertiaryBg = backgroundTertiary
        public static let background = backgroundPrimary
        public static let secondaryBackground = backgroundSecondary
        public static let tertiaryBackground = backgroundTertiary
        public static let label = textPrimary
        public static let secondaryLabel = textSecondary
        public static let tertiaryLabel = textTertiary
        
        // Legacy neutral colors (for backward compatibility)
        public static let black = Color("000000")
        public static let white = Color("FFFFFF")
        public static let gray50 = neutral50.opacity(0.95)
        public static let gray100 = neutral50.opacity(0.9)
        public static let gray200 = neutral50.opacity(0.8)
        public static let gray300 = neutral50.opacity(0.6)
        public static let gray400 = neutral50.opacity(0.4)
        public static let gray500 = neutral50.opacity(0.3)
        public static let gray600 = neutral50.opacity(0.2)
        public static let gray700 = neutral50.opacity(0.15)
        public static let gray800 = neutral50.opacity(0.1)
        public static let gray900 = neutral50.opacity(0.05)
        
        // === ENHANCED GRADIENTS ===
        public static let brandGradient = LinearGradient(
            colors: [brand, brand.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let heroGradient = LinearGradient(
            colors: [brand, secondary, tertiary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let cosmicGradient = LinearGradient(
            colors: [backgroundPrimary, Color("0F0F1A"), Color("1A1A2E"), Color("2D1B69"), brand],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        public static let neonGradient = LinearGradient(
            colors: [neonBlue, neonPurple, neonPink],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        public static let subtleGradient = LinearGradient(
            colors: [neutral800, neutral700],
            startPoint: .top,
            endPoint: .bottom
        )
        
        // Legacy gradient support
        public static let primaryGradient = brandGradient
        public static let glassGradient = LinearGradient(
            colors: [Glass.contentLayer.background, Glass.contentLayer.background.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Professional Typography System
    public struct Typography {
        // === DISPLAY TYPOGRAPHY ===
        public static let displayLarge = Font.system(size: 57, weight: .bold, design: .rounded)
        public static let displayMedium = Font.system(size: 45, weight: .bold, design: .rounded)
        public static let displaySmall = Font.system(size: 36, weight: .bold, design: .rounded)
        
        // === HEADLINE TYPOGRAPHY ===
        public static let headlineLarge = Font.system(size: 32, weight: .bold, design: .default)
        public static let headlineMedium = Font.system(size: 28, weight: .bold, design: .default)
        public static let headlineSmall = Font.system(size: 24, weight: .bold, design: .default)
        
        // === TITLE TYPOGRAPHY ===
        public static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
        public static let titleMedium = Font.system(size: 16, weight: .medium, design: .default)
        public static let titleSmall = Font.system(size: 14, weight: .medium, design: .default)
        
        // === LABEL TYPOGRAPHY ===
        public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        public static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        
        // === BODY TYPOGRAPHY ===
        public static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        public static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        public static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // === FUTURISTIC VARIANTS ===
        public static let heroDisplay = Font.system(size: 48, weight: .heavy, design: .rounded)
        public static let quantumTitle = Font.system(size: 20, weight: .semibold, design: .monospaced)
        public static let techLabel = Font.system(size: 13, weight: .medium, design: .monospaced)
        
        // === LEGACY SUPPORT ===
        public static let largeTitle = displayMedium
        public static let title1 = headlineLarge
        public static let title2 = headlineMedium
        public static let title3 = headlineSmall
        public static let body = bodyMedium
        public static let bodyMediumWeight = Font.system(size: 14, weight: .medium, design: .default)
        public static let bodyBold = Font.system(size: 14, weight: .bold, design: .default)
        public static let caption = bodySmall
        public static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
        public static let headline = titleLarge
        public static let subheadline = titleMedium
        public static let footnote = labelSmall
        public static let hero = heroDisplay
        public static let buttonLabel = labelLarge
        public static let cardTitle = titleMedium
    }
    
    // MARK: - Spacing
    public struct Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
        public static let xxxl: CGFloat = 64
        
        // Semantic Spacing
        public static let padding = md
        public static let margin = lg
        public static let sectionSpacing = xl
    }
    
    // MARK: - Radius
    public struct Radius {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let round: CGFloat = 50
        
        // Semantic Radius
        public static let button = md
        public static let card = lg
        public static let sheet = xl
    }
    
    // MARK: - Enhanced Shadow System
    public struct Shadows {
        // === ELEVATION SHADOWS ===
        public static let elevation0 = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
        public static let elevation1 = ShadowStyle(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
        public static let elevation2 = ShadowStyle(color: Color.black.opacity(0.16), radius: 4, x: 0, y: 2)
        public static let elevation3 = ShadowStyle(color: Color.black.opacity(0.20), radius: 8, x: 0, y: 4)
        public static let elevation4 = ShadowStyle(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
        public static let elevation5 = ShadowStyle(color: Color.black.opacity(0.30), radius: 16, x: 0, y: 8)
        
        // === GLOW EFFECTS ===
        public static let brandGlow = ShadowStyle(color: Colors.brand.opacity(0.4), radius: 20, x: 0, y: 0)
        public static let accentGlow = ShadowStyle(color: Colors.accent.opacity(0.4), radius: 16, x: 0, y: 0)
        public static let successGlow = ShadowStyle(color: Colors.success.opacity(0.3), radius: 12, x: 0, y: 0)
        public static let errorGlow = ShadowStyle(color: Colors.error.opacity(0.3), radius: 12, x: 0, y: 0)
        
        // === QUANTUM EFFECTS ===
        public static let neonBlueGlow = ShadowStyle(color: Colors.neonBlue.opacity(0.5), radius: 24, x: 0, y: 0)
        public static let neonPinkGlow = ShadowStyle(color: Colors.neonPink.opacity(0.5), radius: 24, x: 0, y: 0)
        public static let quantumGlow = ShadowStyle(color: Colors.neonPurple.opacity(0.4), radius: 32, x: 0, y: 0)
        
        // === TEXT EFFECTS ===
        public static let textGlow = ShadowStyle(color: Color.black.opacity(0.8), radius: 2, x: 0, y: 1)
        public static let textOutline = ShadowStyle(color: Color.black.opacity(0.6), radius: 1, x: 0, y: 0)
        
        // === DRAMATIC SHADOWS ===
        public static let dramatic = ShadowStyle(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 12)
        public static let floating = ShadowStyle(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        public static let pressed = ShadowStyle(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        
        // === CYBERPUNK EFFECTS ===
        public static let primaryGlow = ShadowStyle(color: Colors.primary.opacity(0.4), radius: 20, x: 0, y: 0)
        public static let secondaryGlow = ShadowStyle(color: Colors.secondary.opacity(0.3), radius: 16, x: 0, y: 0)
        public static let cyberGlow = ShadowStyle(color: Colors.tertiary.opacity(0.4), radius: 24, x: 0, y: 0)
        public static let deepShadow = ShadowStyle(color: Color.black.opacity(0.6), radius: 32, x: 0, y: 8)
    }    // MARK: - Professional Animation System
    public struct Animations {
        // === MICRO-INTERACTIONS ===
        public static let instant = Animation.easeInOut(duration: 0.1)
        public static let quick = Animation.easeInOut(duration: 0.2)
        public static let smooth = Animation.easeInOut(duration: 0.3)
        public static let gentle = Animation.easeInOut(duration: 0.4)
        public static let slow = Animation.easeInOut(duration: 0.6)
        
        // === SPRING ANIMATIONS ===
        public static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
        public static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.8)
        public static let fluid = Animation.spring(response: 0.4, dampingFraction: 0.9)
        public static let elastic = Animation.spring(response: 0.5, dampingFraction: 0.6)
        
        // === BUTTON INTERACTIONS ===
        public static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.6)
        public static let buttonRelease = Animation.spring(response: 0.3, dampingFraction: 0.8)
        public static let hover = Animation.spring(response: 0.4, dampingFraction: 0.9)
        
        // === NAVIGATION ===
        public static let pageTransition = Animation.spring(response: 0.5, dampingFraction: 0.9)
        public static let modalPresent = Animation.spring(response: 0.6, dampingFraction: 0.8)
        public static let slideIn = Animation.easeOut(duration: 0.4)
        public static let fadeIn = Animation.easeInOut(duration: 0.3)
        
        // === LOADING STATES ===
        public static let shimmer = Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
        public static let pulse = Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)
        public static let breathe = Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true)
        
        // === FUTURISTIC EFFECTS ===
        public static let quantum = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
        public static let cosmic = Animation.linear(duration: 20.0).repeatForever(autoreverses: false)
        public static let glow = Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)
        public static let float = Animation.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
        public static let rotate = Animation.linear(duration: 8.0).repeatForever(autoreverses: false)
        
        // === HAPTIC FEEDBACK TIMING ===
        public static let hapticLight = Duration.milliseconds(50)
        public static let hapticMedium = Duration.milliseconds(100)
        public static let hapticHeavy = Duration.milliseconds(150)
        
        // === LEGACY SUPPORT ===
        public static let cardHover = hover
    }
}

// MARK: - Professional UI Components Support

// MARK: - Glass Effect System
public struct GlassEffect {
    public let background: Color
    public let border: Color
    public let blur: CGFloat
    public let innerGlow: Color

    public init(background: Color, border: Color, blur: CGFloat, innerGlow: Color) {
        self.background = background
        self.border = border
        self.blur = blur
        self.innerGlow = innerGlow
    }
    
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
public struct ShadowStyle {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }

    public var viewModifier: some ViewModifier {
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
    init(_ hex: String) {
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

// MARK: - Avatar Design System
extension DesignTokens {
    enum AvatarDesign {
        // Sizes
        public static let previewSize: CGFloat = 220
        public static let thumbnailSize: CGFloat = 60
        public static let largeSize: CGFloat = 280
        public static let smallSize: CGFloat = 44
        
        // Animation
        public static let animationDuration: Double = 0.6
        public static let animationDamping: Double = 0.7
        public static let springResponse: Double = 0.6
        
        // Mood Colors
        public static let excitedColor = DesignTokens.Colors.neonYellow
        public static let encouragingColor = DesignTokens.Colors.success
        public static let thoughtfulColor = DesignTokens.Colors.info
        public static let celebratingColor = DesignTokens.Colors.neonPurple
        public static let tiredColor = DesignTokens.Colors.neutral500
        public static let curiousColor = DesignTokens.Colors.neonOrange
        public static let neutralColor = DesignTokens.Colors.brand
        
        // Voice
        public static let sampleText = "Hi! I'm excited to learn with you today."
        public static let previewDuration: TimeInterval = 3.0
        
        // Layout
        public static let cardPadding: CGFloat = 16
        public static let cardSpacing: CGFloat = 12
        public static let cornerRadius: CGFloat = 16
        
        // Personality Gradients
        public static let friendlyGradient = [DesignTokens.Colors.brand, DesignTokens.Colors.info]
        public static let wiseGradient = [DesignTokens.Colors.neonPurple, Color("4A148C")]
        public static let energeticGradient = [DesignTokens.Colors.neonOrange, DesignTokens.Colors.neonYellow]
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
