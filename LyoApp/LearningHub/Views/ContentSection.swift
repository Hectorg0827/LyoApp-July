import SwiftUI

// MARK: - Content Section
/// A generic section for displaying a collection of learning resources.
struct ContentSection: View {
    
    // MARK: - Properties
    let title: String
    let subtitle: String
    let content: [LearningResource]
    let isLoading: Bool
    let viewMode: LearningHubView.ViewMode
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            headerView
                .padding(.horizontal, 20)
            
            // Content or Skeleton
            if isLoading {
                skeletonView
            } else {
                contentView
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
    
    // MARK: - Content View
    @ViewBuilder
    private var contentView: some View {
        switch viewMode {
        case .grid:
            horizontalScrollView(layout: .grid)
        case .list:
            horizontalScrollView(layout: .list)
        case .card:
            horizontalScrollView(layout: .card)
        }
    }
    
    // MARK: - Skeleton View
    private var skeletonView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(0..<5) { _ in
                    switch viewMode {
                    case .grid:
                        LearningResourceCard.skeleton
                    case .list:
                        LearningResourceRow.skeleton
                    case .card:
                        LearningResourceFeaturedCard.skeleton
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Horizontal Scroll View
    private func horizontalScrollView(layout: LayoutType) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(content) { resource in
                    switch layout {
                    case .grid:
                        LearningResourceCard(resource: resource)
                    case .list:
                        LearningResourceRow(resource: resource)
                            .frame(width: 300)
                    case .card:
                        LearningResourceFeaturedCard(resource: resource)
                            .frame(width: 320)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    enum LayoutType {
        case grid, list, card
    }
}

// MARK: - Preview
#Preview {
    ContentSection(
        title: "Trending Now",
        subtitle: "Popular this week",
        content: LearningResource.sampleResources,
        isLoading: false,
        viewMode: .grid
    )
    .preferredColorScheme(.dark)
    .background(Color.black)
}
