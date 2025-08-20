import SwiftUI

// MARK: - Content Section View (Alternative)
/// Alternative implementation of content section - consider consolidating with ContentSection.swift
struct ContentSectionAlt: View {
    let title: String
    let subtitle: String
    let content: [LearningResource]
    let isLoading: Bool
    let viewMode: LearningHubView.ViewMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full content view
                    print("📱 NAVIGATION: See all \(title)")
                }
                .font(.subheadline)
                .foregroundColor(.cyan)
            }
            .padding(.horizontal, 20)
            
            // Content
            if isLoading {
                ContentSectionSkeleton(viewMode: viewMode)
            } else {
                contentView
            }
        }
    }
    
    // MARK: - Content View
    private var contentView: some View {
        Group {
            switch viewMode {
            case .grid:
                gridContentView
            case .list:
                listContentView
            case .card:
                cardContentView
            }
        }
    }
    
    // MARK: - Grid Content View
    private var gridContentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(content) { resource in
                    LearningCardView(
                        resource: resource,
                        cardStyle: .compact,
                        onTap: {
                            print("📱 NAVIGATION: Opening resource \(resource.title)")
                        }
                    )
                    .frame(width: 180)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - List Content View
    private var listContentView: some View {
        LazyVStack(spacing: 12) {
            ForEach(content.prefix(5)) { resource in
                LearningCardView(
                    resource: resource,
                    cardStyle: .wide,
                    onTap: {
                        print("📱 NAVIGATION: Opening resource \(resource.title)")
                    }
                )
                .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Card Content View
    private var cardContentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(content) { resource in
                    LearningCardView(
                        resource: resource,
                        cardStyle: .standard,
                        onTap: {
                            print("📱 NAVIGATION: Opening resource \(resource.title)")
                        }
                    )
                    .frame(width: 300)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Featured Content Carousel (Alternative)
/// Alternative implementation - consider consolidating with FeaturedContentCarousel.swift
struct FeaturedContentCarouselAlt: View {
    let content: [LearningResource]
    
    @State private var currentIndex = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            // Carousel
            TabView(selection: $currentIndex) {
                ForEach(Array(content.enumerated()), id: \.element.id) { index, resource in
                    FeaturedContentCard(resource: resource)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 220)
            .onAppear {
                startAutoScroll()
            }
            .onDisappear {
                stopAutoScroll()
            }
            
            // Custom Page Indicator
            HStack(spacing: 8) {
                ForEach(0..<content.count, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.cyan : Color.white.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .scaleEffect(currentIndex == index ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                }
            }
        }
    }
    
    // MARK: - Auto Scroll Methods
    private func startAutoScroll() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentIndex = (currentIndex + 1) % content.count
            }
        }
    }
    
    private func stopAutoScroll() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Featured Content Card
struct FeaturedContentCard: View {
    let resource: LearningResource
    
    var body: some View {
        Button(action: {
            // Navigate to resource detail
            print("📱 NAVIGATION: Featured resource tapped - \(resource.title)")
        }) {
            ZStack {
                // Background Image/Gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                resource.contentType.color.opacity(0.8),
                                resource.contentType.color.opacity(0.4),
                                Color.black.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Content Overlay
                VStack(alignment: .leading, spacing: 12) {
                    // Top badges
                    HStack {
                        Badge(text: "FEATURED", color: .yellow)
                        
                        Spacer()
                        
                        Badge(text: resource.contentType.displayName, color: resource.contentType.color)
                    }
                    
                    Spacer()
                    
                    // Bottom content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(resource.title)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(resource.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                        
                        HStack {
                            // Duration
                            if let duration = resource.estimatedDuration {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                    
                                    Text(duration)
                                        .font(.caption)
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            // Rating
                            if let rating = resource.rating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.yellow)
                                    
                                    Text(String(format: "%.1f", rating))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .buttonStyle(PressedButtonStyle())
        .padding(.horizontal, 20)
    }
    
    private func formatDuration(_ duration: Int) -> String {
        if duration < 60 {
            return "\(duration)m"
        } else {
            let hours = duration / 60
            let minutes = duration % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

// MARK: - Enhanced Learning Card View (Alternative)
/// Alternative implementation - use LearningCardView.swift for the main component
struct LearningCardViewAlt: View {
    let resource: LearningResource
    let style: CardStyle
    
    enum CardStyle {
        case compact
        case list
        case detailed
        case featured
    }
    
    var body: some View {
        Button(action: {
            print("📱 CARD TAPPED: \(resource.title)")
        }) {
            Group {
                switch style {
                case .compact:
                    compactCardView
                case .list:
                    listCardView
                case .detailed:
                    detailedCardView
                case .featured:
                    featuredCardView
                }
            }
        }
        .buttonStyle(PressedButtonStyle())
    }
    
    // MARK: - Compact Card View
    private var compactCardView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail/Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                resource.contentType.color.opacity(0.3),
                                resource.contentType.color.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                
                Image(systemName: resource.contentType.icon)
                    .font(.title2)
                    .foregroundColor(resource.contentType.color)
            }
            
            // Content info
            VStack(alignment: .leading, spacing: 6) {
                Text(resource.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(resource.authorCreator ?? "Unknown Author")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    // Rating
                    if let rating = resource.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Difficulty
                    if let difficultyLevel = resource.difficultyLevel {
                        DifficultyIndicator(level: difficultyLevel)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - List Card View
    private var listCardView: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                resource.contentType.color.opacity(0.3),
                                resource.contentType.color.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                Image(systemName: resource.contentType.icon)
                    .font(.title3)
                    .foregroundColor(resource.contentType.color)
            }
            
            // Content info
            VStack(alignment: .leading, spacing: 4) {
                Text(resource.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(resource.authorCreator ?? "Unknown Author")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    // Rating
                    if let rating = resource.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    // Duration
                    if let duration = resource.estimatedDuration {
                        Text(duration)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
            
            // Action button
            Button(action: {
                print("📚 BOOKMARK: \(resource.title)")
            }) {
                Image(systemName: "bookmark")
                    .font(.subheadline)
                    .foregroundColor(.cyan)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Detailed Card View
    private var detailedCardView: some View {
        let gradientColors = [
            resource.contentType.color.opacity(0.4),
            resource.contentType.color.opacity(0.2),
            Color.black.opacity(0.3)
        ]
        
        let backgroundGradient = LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        return VStack(alignment: .leading, spacing: 16) {
            // Header with thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundGradient)
                    .frame(height: 140)
                
                VStack {
                    Image(systemName: resource.contentType.icon)
                        .font(.largeTitle)
                        .foregroundColor(resource.contentType.color)
                    
                    Badge(text: resource.contentType.displayName, color: resource.contentType.color)
                }
            }
            
            // Content details
            VStack(alignment: .leading, spacing: 8) {
                Text(resource.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(resource.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                
                // Author and meta info
                HStack {
                    Text(resource.authorCreator ?? "Unknown Author")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    if let duration = resource.estimatedDuration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            
                            Text(duration)
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                }
                
                // Rating and difficulty
                HStack {
                    // Rating
                    if let rating = resource.rating {
                        HStack(spacing: 4) {
                            ForEach(0..<5) { star in
                                Image(systemName: star < Int(rating) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                            
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                    
                    if let difficultyLevel = resource.difficultyLevel {
                        DifficultyIndicator(level: difficultyLevel)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // MARK: - Featured Card View
    private var featuredCardView: some View {
        // Same as FeaturedContentCard but as part of the unified system
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            resource.contentType.color.opacity(0.8),
                            resource.contentType.color.opacity(0.4),
                            Color.black.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Badge(text: "FEATURED", color: .yellow)
                    Spacer()
                    Badge(text: resource.contentType.displayName, color: resource.contentType.color)
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(resource.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(resource.description)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            .padding(16)
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: Int) -> String {
        if duration < 60 {
            return "\(duration)m"
        } else {
            let hours = duration / 60
            let minutes = duration % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
}

// MARK: - Supporting Components

// Badge Component
struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text.uppercased())
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
            )
    }
}

// Difficulty Indicator Component
struct DifficultyIndicator: View {
    let level: LearningResource.DifficultyLevel
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < level.numericValue ? level.color : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// Pressed Button Style
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Skeleton Views

struct ContentSectionSkeleton: View {
    let viewMode: LearningHubView.ViewMode
    
    var body: some View {
        Group {
            switch viewMode {
            case .grid:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(0..<5, id: \.self) { _ in
                            SkeletonCard()
                                .frame(width: 180, height: 180)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            case .list:
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonListItem()
                    }
                }
                .padding(.horizontal, 20)
            case .card:
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonCard()
                                .frame(width: 300, height: 240)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

struct FeaturedContentSkeletonAlt: View {
    var body: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .frame(height: 220)
                .padding(.horizontal, 20)
            
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .opacity(0.6)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
    }
}

struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .frame(height: 100)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity * 0.7)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.02))
        )
        .opacity(0.6)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
    }
}

struct SkeletonListItem: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.1))
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity * 0.6)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.02))
        )
        .opacity(0.6)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
    }
}

// Note: Shimmer effect is defined in LearnView.swift

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ContentSectionAlt(
                title: "Featured Content",
                subtitle: "Hand-picked for you",
                content: Array(LearningResource.sampleResources.prefix(5)),
                isLoading: false,
                viewMode: .grid
            )
            
            FeaturedContentCarousel(
                content: Array(LearningResource.sampleResources.prefix(3))
            )
        }
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
