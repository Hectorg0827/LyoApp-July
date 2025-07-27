import SwiftUI

// MARK: - Content Section View
/// Reusable section for displaying different types of learning content
struct ContentSection: View {
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
                    LearningCardView(resource: resource, style: .compact)
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
                LearningCardView(resource: resource, style: .list)
                    .padding(.horizontal, 20)
            }
        }
    }
    
    // MARK: - Card Content View
    private var cardContentView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(content) { resource in
                    LearningCardView(resource: resource, style: .detailed)
                        .frame(width: 300)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Featured Content Carousel
/// Hero carousel for featured content with auto-scroll
struct FeaturedContentCarousel: View {
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
                            if let duration = resource.duration {
                                HStack(spacing: 4) {
                                    Image(systemName: "clock")
                                        .font(.caption)
                                    
                                    Text(formatDuration(duration))
                                        .font(.caption)
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            // Rating
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                
                                Text(String(format: "%.1f", resource.rating))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
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

// MARK: - Enhanced Learning Card View
/// Unified card component for all learning content with multiple styles
struct LearningCardView: View {
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
                
                Text(resource.author)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", resource.rating))
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Difficulty
                    DifficultyIndicator(level: resource.difficultyLevel)
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
                
                Text(resource.author)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    // Rating
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                        
                        Text(String(format: "%.1f", resource.rating))
                            .font(.caption2)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Duration
                    if let duration = resource.duration {
                        Text(formatDuration(duration))
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
        VStack(alignment: .leading, spacing: 16) {
            // Header with thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                resource.contentType.color.opacity(0.4),
                                resource.contentType.color.opacity(0.2),
                                Color.black.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
                    Text(resource.author)
                        .font(.caption)
                        .foregroundColor(.cyan)
                    
                    Spacer()
                    
                    if let duration = resource.duration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            
                            Text(formatDuration(duration))
                                .font(.caption)
                        }
                        .foregroundColor(.gray)
                    }
                }
                
                // Rating and difficulty
                HStack {
                    // Rating
                    HStack(spacing: 4) {
                        ForEach(0..<5) { star in
                            Image(systemName: star < Int(resource.rating) ? "star.fill" : "star")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                        
                        Text(String(format: "%.1f", resource.rating))
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    DifficultyIndicator(level: resource.difficultyLevel)
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
                    .fill(index < level.rawValue ? level.color : Color.gray.opacity(0.3))
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

struct FeaturedContentSkeleton: View {
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
        .shimmer()
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
        .shimmer()
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
        .shimmer()
    }
}

// Shimmer Effect
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.1),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .onAppear {
                    withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 400
                    }
                }
            )
            .clipped()
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ContentSection(
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
