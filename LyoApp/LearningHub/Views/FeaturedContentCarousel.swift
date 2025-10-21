import SwiftUI

// MARK: - Featured Content Carousel
/// A horizontally scrolling carousel for featured learning content.
struct FeaturedContentCarousel: View {
    
    // MARK: - Properties
    let content: [LearningResource]
    
    // MARK: - Body
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(content) { resource in
                    LearningResourceFeaturedCard(resource: resource)
                        .frame(width: 320)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Featured Content Skeleton
/// A skeleton loader for the featured content section.
struct FeaturedContentSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 320, height: 180)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Preview
#Preview {
    FeaturedContentCarousel(content: LearningResource.sampleResources())
        .preferredColorScheme(.dark)
        .background(Color.black)
}
