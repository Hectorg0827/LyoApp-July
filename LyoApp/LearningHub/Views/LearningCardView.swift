import SwiftUI

// MARK: - Learning Card View
/// Reusable SwiftUI view for displaying learning resources in grids and lists
struct LearningCardView: View {
    let resource: LearningResource
    let cardStyle: CardStyle
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var imageLoaded = false
    
    enum CardStyle {
        case standard    // 160x240 for grid
        case wide       // Full width for lists
        case compact    // 120x180 for small grids
        case hero       // 320x180 for featured content
    }
    
    var body: some View {
        Button(action: onTap) {
            cardContent
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0) { pressing in
            isPressed = pressing
        } perform: {
            // Long press action - could show context menu
        }
    }
    
    @ViewBuilder
    private var cardContent: some View {
        switch cardStyle {
        case .standard:
            standardCard
        case .wide:
            wideCard
        case .compact:
            compactCard
        case .hero:
            heroCard
        }
    }
    
    // MARK: - Standard Card (Grid View)
    private var standardCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // Thumbnail with overlay info
            ZStack(alignment: .topTrailing) {
                thumbnailImage(height: 120)
                
                // Content type badge
                contentTypeBadge
                
                // Difficulty indicator
                if let difficulty = resource.difficultyLevel {
                    VStack {
                        Spacer()
                        HStack {
                            difficultyBadge(difficulty)
                            Spacer()
                        }
                    }
                    .padding(DesignTokens.Spacing.xs)
                }
            }
            .frame(height: 120)
            .clipped()
            
            // Content info
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(resource.title)
                    .font(DesignTokens.Typography.body)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let author = resource.authorCreator {
                    Text(author)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: DesignTokens.Spacing.xs) {
                    // Platform badge
                    platformBadge
                    
                    Spacer()
                    
                    // Rating if available
                    if let rating = resource.rating {
                        ratingView(rating)
                    }
                }
                
                // Duration and additional info
                if let duration = resource.estimatedDuration {
                    Text(duration)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.bottom, DesignTokens.Spacing.sm)
        }
        .frame(width: 160)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.cardBg)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Wide Card (List View)
    private var wideCard: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                thumbnailImage(height: 80)
                contentTypeBadge
                    .scaleEffect(0.8)
            }
            .frame(width: 120, height: 80)
            .clipped()
            
            // Content info
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(resource.title)
                    .font(DesignTokens.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                if let author = resource.authorCreator {
                    Text(author)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Text(resource.description)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    platformBadge
                    
                    if let duration = resource.estimatedDuration {
                        Label(duration, systemImage: "clock")
                            .font(DesignTokens.Typography.caption2)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    if let rating = resource.rating {
                        ratingView(rating)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.cardBg)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Compact Card
    private var compactCard: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            ZStack(alignment: .topTrailing) {
                thumbnailImage(height: 90)
                contentTypeBadge
                    .scaleEffect(0.8)
            }
            .frame(height: 90)
            .clipped()
            
            VStack(alignment: .leading, spacing: 2) {
                Text(resource.title)
                    .font(DesignTokens.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                if let author = resource.authorCreator {
                    Text(author)
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.bottom, DesignTokens.Spacing.xs)
        }
        .frame(width: 120)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                .fill(DesignTokens.Colors.cardBg)
                .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
        )
    }
    
    // MARK: - Hero Card (Featured)
    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Full background image
            thumbnailImage(height: 180)
                .frame(height: 180)
                .clipped()
            
            // Gradient overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content overlay
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    contentTypeBadge
                    Spacer()
                    if let rating = resource.rating {
                        ratingView(rating, textColor: .white)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(resource.title)
                        .font(DesignTokens.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    if let author = resource.authorCreator {
                        Text(author)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(1)
                    }
                    
                    HStack {
                        platformBadge
                        
                        if let duration = resource.estimatedDuration {
                            Label(duration, systemImage: "clock")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .frame(height: 180)
        .background(Color.gray.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Supporting Views
private extension LearningCardView {
    
    @ViewBuilder
    func thumbnailImage(height: CGFloat) -> some View {
        AsyncImage(url: resource.thumbnailURL) { image in
            image
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .onAppear {
                    imageLoaded = true
                }
        } placeholder: {
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        DesignTokens.Colors.glassBg,
                        DesignTokens.Colors.glassBg.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    Image(systemName: resource.contentType.icon)
                        .font(.system(size: height * 0.3))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                )
        }
        .frame(height: height)
        .background(DesignTokens.Colors.glassBg)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
    }
    
    var contentTypeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: resource.contentType.icon)
                .font(.system(size: 10, weight: .semibold))
            Text(resource.contentType.displayName)
                .font(.system(size: 10, weight: .semibold))
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(resource.contentType.color)
        )
        .foregroundColor(.white)
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
    
    func difficultyBadge(_ difficulty: LearningResource.DifficultyLevel) -> some View {
        Text(difficulty.displayName)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(difficulty.color.opacity(0.9))
            )
            .foregroundColor(.white)
    }
    
    var platformBadge: some View {
        Text(resource.sourcePlatform.displayName)
            .font(.system(size: 9, weight: .medium))
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        Capsule()
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 0.5)
                    )
            )
            .foregroundColor(DesignTokens.Colors.textSecondary)
    }
    
    func ratingView(_ rating: Double, textColor: Color = DesignTokens.Colors.textSecondary) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: 10))
                .foregroundColor(.yellow)
            Text(String(format: "%.1f", rating))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(textColor)
        }
    }
}

// MARK: - Preview
#Preview("Standard Card") {
    LearningCardView(
        resource: LearningResource.sampleResources[0],
        cardStyle: .standard,
        onTap: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Wide Card") {
    LearningCardView(
        resource: LearningResource.sampleResources[1],
        cardStyle: .wide,
        onTap: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

#Preview("Hero Card") {
    LearningCardView(
        resource: LearningResource.sampleResources[2],
        cardStyle: .hero,
        onTap: {}
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}
