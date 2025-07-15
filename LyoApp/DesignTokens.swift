import SwiftUI
import Foundation

// MARK: - Design Tokens
struct DesignTokens {
    
    // MARK: - Colors
    struct Colors {
        // Futuristic Dark Theme Base
        static let primaryBg = Color(hex: "0A0A0F") // Deep space background
        static let secondaryBg = Color(hex: "151520") // Secondary dark
        static let tertiaryBg = Color(hex: "1E1E2E") // Tertiary dark
        
        // Vibrant Neon Accents
        static let primary = Color(hex: "6366F1") // Electric indigo
        static let secondary = Color(hex: "8B5CF6") // Vivid purple
        static let tertiary = Color(hex: "06B6D4") // Cyber cyan
        static let quaternary = Color(hex: "EC4899") // Neon pink
        
        // Glass Morphism Effects
        static let glassBg = Color.white.opacity(0.08)
        static let glassBorder = Color.white.opacity(0.12)
        static let glassOverlay = Color.black.opacity(0.2)
        static let glassHighlight = Color.white.opacity(0.2)
        
        // Text Colors
        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "A1A1AA")
        static let textTertiary = Color.white.opacity(0.5)
        static let textAccent = Color(hex: "C084FC")
        
        // Enhanced Neon Colors
        static let neonBlue = Color(hex: "00CCFF")
        static let neonPurple = Color(hex: "CC66FF")
        static let neonGreen = Color(hex: "00FF99")
        static let neonPink = Color(hex: "FF3399")
        static let neonYellow = Color(hex: "FFFF00")
        static let neonOrange = Color(hex: "FF6600")
        
        // Status Colors with Glow
        static let success = Color(hex: "00E664")
        static let warning = Color(hex: "FFB800")
        static let error = Color(hex: "FF4D4D")
        static let info = neonBlue
        
        // Legacy Support (mapped to new system)
        static let background = primaryBg
        static let secondaryBackground = secondaryBg
        static let tertiaryBackground = tertiaryBg
        static let label = textPrimary
        static let secondaryLabel = textSecondary
        static let tertiaryLabel = textTertiary
        
        // Neutral Colors (adapted for dark theme)
        static let black = Color(hex: "000000")
        static let white = Color(hex: "FFFFFF")
        static let gray50 = Color.white.opacity(0.95)
        static let gray100 = Color.white.opacity(0.9)
        static let gray200 = Color.white.opacity(0.8)
        static let gray300 = Color.white.opacity(0.6)
        static let gray400 = Color.white.opacity(0.4)
        static let gray500 = Color.white.opacity(0.3)
        static let gray600 = Color.white.opacity(0.2)
        static let gray700 = Color.white.opacity(0.15)
        static let gray800 = Color.white.opacity(0.1)
        static let gray900 = Color.white.opacity(0.05)
        
        // Enhanced Gradients
        static let primaryGradient = LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let heroGradient = LinearGradient(
            colors: [primary, secondary, tertiary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let cosmicGradient = LinearGradient(
            colors: [primaryBg, Color(hex: "0F0F1A"), Color(hex: "1A1A2E"), Color(hex: "2D1B69"), Color(hex: "4338CA")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let neonGradient = LinearGradient(
            colors: [neonBlue, neonPurple, neonPink],
            startPoint: .leading,
            endPoint: .trailing
        )
        
        static let glassGradient = LinearGradient(
            colors: [glassBg, glassBg.opacity(0.5)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Typography
    struct Typography {
        // Headers
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title1 = Font.title.weight(.bold)
        static let title2 = Font.title2.weight(.semibold)
        static let title3 = Font.title3.weight(.semibold)
        
        // Body Text
        static let body = Font.body
        static let bodyMedium = Font.body.weight(.medium)
        static let bodyBold = Font.body.weight(.bold)
        
        // Captions
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // Custom Fonts
        static let headline = Font.headline.weight(.semibold)
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        
        // Custom Sizes
        static let hero = Font.system(size: 32, weight: .bold, design: .rounded)
        static let buttonLabel = Font.system(size: 16, weight: .semibold)
        static let cardTitle = Font.system(size: 18, weight: .semibold)
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
    
    // MARK: - Shadows
    struct Shadows {
        // Basic Shadows
        static let small = Shadow(
            color: Color.black.opacity(0.2),
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.3),
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.4),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let card = Shadow(
            color: Color.black.opacity(0.3),
            radius: 6,
            x: 0,
            y: 3
        )
        
        // Futuristic Glow Effects
        static let neonGlow = Shadow(
            color: Colors.primary.opacity(0.5),
            radius: 20,
            x: 0,
            y: 0
        )
        
        static let primaryGlow = Shadow(
            color: Colors.primary.opacity(0.3),
            radius: 16,
            x: 0,
            y: 0
        )
        
        static let secondaryGlow = Shadow(
            color: Colors.secondary.opacity(0.3),
            radius: 16,
            x: 0,
            y: 0
        )
        
        static let cyberGlow = Shadow(
            color: Colors.tertiary.opacity(0.4),
            radius: 24,
            x: 0,
            y: 0
        )
        
        static let deepShadow = Shadow(
            color: Color.black.opacity(0.6),
            radius: 32,
            x: 0,
            y: 8
        )
    }
    
    // MARK: - Animations
    struct Animations {
        // Basic Animations
        static let quick = Animation.easeInOut(duration: 0.2)
        static let smooth = Animation.easeInOut(duration: 0.3)
        static let slow = Animation.easeInOut(duration: 0.5)
        
        // Spring Animations
        static let bouncy = Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let gentle = Animation.spring(response: 0.4, dampingFraction: 0.9)
        static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        // Futuristic Animations
        static let cosmic = Animation.easeInOut(duration: 20).repeatForever(autoreverses: false)
        static let pulse = Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)
        static let glow = Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
        static let float = Animation.easeInOut(duration: 15).repeatForever(autoreverses: false)
        static let shimmer = Animation.linear(duration: 4).repeatForever(autoreverses: false)
        
        // Interactive Animations
        static let buttonPress = Animation.spring(response: 0.2, dampingFraction: 0.6)
        static let cardHover = Animation.spring(response: 0.4, dampingFraction: 0.8)
        static let pageTransition = Animation.spring(response: 0.5, dampingFraction: 0.9)
    }
}

// MARK: - Supporting Types
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
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
}
