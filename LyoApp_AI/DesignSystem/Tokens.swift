import SwiftUI

// MARK: - Design Tokens
struct Tokens {
    
    // MARK: - Colors
    struct Colors {
        // Brand Colors (matching existing Lyo design)
        static let brand = Color("Brand/Primary")
        static let brandSecondary = Color("Brand/Secondary")
        static let accent = Color("Brand/Accent")
        
        // Background Colors
        static let primaryBg = Color("Background/Primary")
        static let secondaryBg = Color("Background/Secondary")
        static let tertiaryBg = Color("Background/Tertiary")
        
        // Text Colors
        static let textPrimary = Color("Text/Primary")
        static let textSecondary = Color("Text/Secondary")
        static let textTertiary = Color("Text/Tertiary")
        
        // Semantic Colors
        static let success = Color("Semantic/Success")
        static let warning = Color("Semantic/Warning")
        static let error = Color("Semantic/Error")
        static let info = Color("Semantic/Info")
        
        // Interactive Colors
        static let buttonPrimary = Color("Interactive/Primary")
        static let buttonSecondary = Color("Interactive/Secondary")
        static let border = Color("Interactive/Border")
        static let divider = Color("Interactive/Divider")
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let light = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let heavy = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Typography
struct Typography {
    
    // Display
    static let display1 = Font.system(size: 57, weight: .regular, design: .default)
    static let display2 = Font.system(size: 45, weight: .regular, design: .default)
    static let display3 = Font.system(size: 36, weight: .regular, design: .default)
    
    // Headlines
    static let h1 = Font.system(size: 32, weight: .bold, design: .default)
    static let h2 = Font.system(size: 28, weight: .bold, design: .default)
    static let h3 = Font.system(size: 24, weight: .bold, design: .default)
    static let h4 = Font.system(size: 20, weight: .semibold, design: .default)
    static let h5 = Font.system(size: 18, weight: .semibold, design: .default)
    static let h6 = Font.system(size: 16, weight: .semibold, design: .default)
    
    // Body
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
    static let body = Font.system(size: 14, weight: .regular, design: .default)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // Labels
    static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
    static let label = Font.system(size: 12, weight: .medium, design: .default)
    static let labelSmall = Font.system(size: 10, weight: .medium, design: .default)
    
    // Caption
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionSmall = Font.system(size: 10, weight: .regular, design: .default)
}

// MARK: - View Extensions
extension View {
    func lyoShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func lyoCard() -> some View {
        self
            .background(Tokens.Colors.secondaryBg)
            .cornerRadius(Tokens.Radius.md)
            .lyoShadow(Tokens.Shadows.light)
    }
}

#Preview {
    VStack(spacing: Tokens.Spacing.md) {
        Text("Display 1")
            .font(Typography.display1)
        Text("Headline 1")
            .font(Typography.h1)
        Text("Body text")
            .font(Typography.body)
        Text("Caption")
            .font(Typography.caption)
    }
    .padding()
    .background(Tokens.Colors.primaryBg)
}
