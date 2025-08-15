import SwiftUI

// MARK: - Button Component
struct LyoButton: View {
    let title: String
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, tertiary, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return Tokens.Colors.brand
            case .secondary: return Tokens.Colors.secondaryBg
            case .tertiary: return Color.clear
            case .destructive: return Tokens.Colors.error
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return Tokens.Colors.textPrimary
            case .tertiary: return Tokens.Colors.brand
            case .destructive: return .white
            }
        }
        
        var borderColor: Color? {
            switch self {
            case .primary, .destructive: return nil
            case .secondary: return Tokens.Colors.border
            case .tertiary: return Tokens.Colors.brand
            }
        }
    }
    
    enum ButtonSize {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            case .medium: return EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return Typography.labelSmall
            case .medium: return Typography.label
            case .large: return Typography.labelLarge
            }
        }
    }
    
    init(_ title: String, style: ButtonStyle = .primary, size: ButtonSize = .medium, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(size.font)
                .foregroundColor(style.foregroundColor)
                .padding(size.padding)
                .frame(maxWidth: .infinity)
                .background(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: Tokens.Radius.md)
                        .stroke(style.borderColor ?? Color.clear, lineWidth: 1)
                )
                .cornerRadius(Tokens.Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Card Component
struct LyoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(Tokens.Spacing.md)
            .background(Tokens.Colors.secondaryBg)
            .cornerRadius(Tokens.Radius.md)
            .lyoShadow(Tokens.Shadows.light)
    }
}

// MARK: - Avatar Component
struct Avatar: View {
    let url: String?
    let size: AvatarSize
    let initials: String
    
    enum AvatarSize {
        case small, medium, large, xlarge
        
        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            case .large: return 56
            case .xlarge: return 80
            }
        }
        
        var font: Font {
            switch self {
            case .small: return Typography.captionSmall
            case .medium: return Typography.caption
            case .large: return Typography.body
            case .xlarge: return Typography.h6
            }
        }
    }
    
    init(url: String?, size: AvatarSize = .medium, initials: String = "?") {
        self.url = url
        self.size = size
        self.initials = initials
    }
    
    var body: some View {
        Group {
            if let url = url, let imageURL = URL(string: url) {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    initialsView
                }
            } else {
                initialsView
            }
        }
        .frame(width: size.dimension, height: size.dimension)
        .clipShape(Circle())
    }
    
    private var initialsView: some View {
        Circle()
            .fill(Tokens.Colors.brand.opacity(0.1))
            .overlay(
                Text(initials.prefix(2).uppercased())
                    .font(size.font)
                    .foregroundColor(Tokens.Colors.brand)
            )
    }
}

// MARK: - Progress Ring
struct ProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    let lineWidth: CGFloat
    
    init(progress: Double, size: CGFloat = 40, lineWidth: CGFloat = 4) {
        self.progress = max(0, min(1, progress))
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Tokens.Colors.border, lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Tokens.Colors.brand,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            
            // Progress text
            Text("\(Int(progress * 100))%")
                .font(Typography.captionSmall)
                .foregroundColor(Tokens.Colors.textSecondary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Chip Component
struct Chip: View {
    let text: String
    let isSelected: Bool
    let action: (() -> Void)?
    
    init(_ text: String, isSelected: Bool = false, action: (() -> Void)? = nil) {
        self.text = text
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    chipContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                chipContent
            }
        }
    }
    
    private var chipContent: some View {
        Text(text)
            .font(Typography.labelSmall)
            .foregroundColor(isSelected ? .white : Tokens.Colors.textSecondary)
            .padding(.horizontal, Tokens.Spacing.sm)
            .padding(.vertical, Tokens.Spacing.xs)
            .background(isSelected ? Tokens.Colors.brand : Tokens.Colors.tertiaryBg)
            .cornerRadius(Tokens.Radius.full)
    }
}

// MARK: - Badge Component
struct Badge: View {
    let text: String
    let style: BadgeStyle
    
    enum BadgeStyle {
        case info, success, warning, error
        
        var backgroundColor: Color {
            switch self {
            case .info: return Tokens.Colors.info
            case .success: return Tokens.Colors.success
            case .warning: return Tokens.Colors.warning
            case .error: return Tokens.Colors.error
            }
        }
    }
    
    init(_ text: String, style: BadgeStyle = .info) {
        self.text = text
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(Typography.captionSmall)
            .foregroundColor(.white)
            .padding(.horizontal, Tokens.Spacing.sm)
            .padding(.vertical, Tokens.Spacing.xs)
            .background(style.backgroundColor)
            .cornerRadius(Tokens.Radius.sm)
    }
}

// MARK: - Empty State Component
struct EmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Tokens.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Tokens.Colors.textTertiary)
            
            VStack(spacing: Tokens.Spacing.sm) {
                Text(title)
                    .font(Typography.h5)
                    .foregroundColor(Tokens.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Typography.body)
                        .foregroundColor(Tokens.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            if let actionTitle = actionTitle, let action = action {
                LyoButton(actionTitle, style: .primary, size: .medium, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .padding(Tokens.Spacing.xl)
    }
}

// MARK: - Loading Skeleton
struct LoadingSkeleton: View {
    @State private var isAnimating = false
    
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Tokens.Colors.border)
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: Tokens.Spacing.lg) {
            LyoButton("Primary Button", style: .primary) {}
            LyoButton("Secondary Button", style: .secondary) {}
            LyoButton("Tertiary Button", style: .tertiary) {}
            
            HStack {
                Avatar(url: nil, size: .small, initials: "JD")
                Avatar(url: nil, size: .medium, initials: "JD")
                Avatar(url: nil, size: .large, initials: "JD")
                Avatar(url: nil, size: .xlarge, initials: "JD")
            }
            
            ProgressRing(progress: 0.7)
            
            HStack {
                Chip("SwiftUI", isSelected: true)
                Chip("iOS Development")
                Chip("Machine Learning")
            }
            
            HStack {
                Badge("New", style: .info)
                Badge("Completed", style: .success)
                Badge("Due Soon", style: .warning)
                Badge("Overdue", style: .error)
            }
            
            EmptyState(
                icon: "graduationcap",
                title: "No courses yet",
                subtitle: "Start your learning journey by creating your first course plan",
                actionTitle: "Create Course",
                action: {}
            )
            
            VStack(spacing: 8) {
                LoadingSkeleton(width: 200)
                LoadingSkeleton(width: 150)
                LoadingSkeleton(width: 100)
            }
        }
        .padding()
    }
    .background(Tokens.Colors.primaryBg)
}
