import SwiftUI

struct FeedView: View {
    @EnvironmentObject var container: AppContainer
    @StateObject private var viewModel = FeedViewModel()
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    if viewModel.isLoading && viewModel.feedItems.isEmpty {
                        // Loading skeleton
                        ForEach(0..<5) { _ in
                            FeedItemSkeleton()
                        }
                    } else {
                        ForEach(viewModel.feedItems) { item in
                            FeedItemCard(item: item) {
                                // Handle like action
                                Task {
                                    await viewModel.toggleLike(for: item)
                                }
                            } commentAction: {
                                // Handle comment action
                                print("Comment on \(item.id)")
                            } shareAction: {
                                // Handle share action
                                print("Share \(item.id)")
                            }
                        }
                    }
                    
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(DesignTokens.Spacing.lg)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                .padding(.vertical, DesignTokens.Spacing.md)
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .refreshable {
                await viewModel.refreshFeed()
            }
            .navigationTitle("Feed")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await viewModel.loadFeed()
                }
            }
            .onScrolledToBottom {
                Task {
                    await viewModel.loadMoreFeed()
                }
            }
        }
    }
}

struct FeedItemCard: View {
    let item: FeedItem
    let likeAction: () -> Void
    let commentAction: () -> Void
    let shareAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header with user info
            HStack(spacing: DesignTokens.Spacing.sm) {
                OptimizedAsyncImage(url: URL(string: item.author?.avatarUrl ?? ""))
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(item.author?.displayName ?? "Anonymous")
                        .font(DesignTokens.Typography.titleSmall)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(formatTimeAgo(item.createdAt))
                        .font(DesignTokens.Typography.labelSmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    // More options
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
            
            // Content
            if let text = item.text, !text.isEmpty {
                Text(text)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(nil)
            }
            
            // Media (if any)
            if let mediaUrl = item.mediaUrl {
                OptimizedAsyncImage(url: URL(string: mediaUrl))
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(DesignTokens.Radius.md)
                    .frame(height: 200)
            }
            
            // Engagement buttons
            HStack(spacing: DesignTokens.Spacing.xl) {
                Button(action: likeAction) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: item.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(item.isLiked ? .red : DesignTokens.Colors.textSecondary)
                        Text("\(item.likesCount)")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Button(action: commentAction) {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "message")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("\(item.commentsCount)")
                            .font(DesignTokens.Typography.labelSmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Button(action: shareAction) {
                    Image(systemName: "paperplane")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    // Bookmark
                } label: {
                    Image(systemName: "bookmark")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .cardStyle()
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct FeedItemSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Header skeleton
            HStack(spacing: DesignTokens.Spacing.sm) {
                Circle()
                    .fill(DesignTokens.Colors.glassBg)
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.glassBg)
                        .frame(width: 120, height: 12)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.glassBg)
                        .frame(width: 80, height: 10)
                }
                
                Spacer()
            }
            
            // Content skeleton
            VStack(alignment: .leading, spacing: 6) {
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DesignTokens.Colors.glassBg)
                        .frame(width: index == 2 ? 180 : .infinity, height: 14)
                }
            }
            
            // Engagement skeleton
            HStack(spacing: DesignTokens.Spacing.xl) {
                ForEach(0..<3) { _ in
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Circle()
                            .fill(DesignTokens.Colors.glassBg)
                            .frame(width: 16, height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DesignTokens.Colors.glassBg)
                            .frame(width: 20, height: 10)
                    }
                }
                
                Spacer()
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .cardStyle()
        .opacity(isAnimating ? 0.5 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

@MainActor
class FeedViewModel: ObservableObject {
    @Published var feedItems: [FeedItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    
    private var currentPage = 1
    private let pageSize = 20
    
    func loadFeed() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            // This should use the container's feedService
            let mockItems = generateMockFeedItems()
            self.feedItems = mockItems
            self.currentPage = 1
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func refreshFeed() async {
        currentPage = 1
        await loadFeed()
    }
    
    func loadMoreFeed() async {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        // Simulate loading more content
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let moreItems = generateMockFeedItems()
        self.feedItems.append(contentsOf: moreItems)
        self.currentPage += 1
        
        isLoadingMore = false
    }
    
    func toggleLike(for item: FeedItem) async {
        if let index = feedItems.firstIndex(where: { $0.id == item.id }) {
            feedItems[index].isLiked.toggle()
            feedItems[index].likesCount += feedItems[index].isLiked ? 1 : -1
        }
    }
    
    private func generateMockFeedItems() -> [FeedItem] {
        return [
            FeedItem(
                id: UUID().uuidString,
                text: "Just completed my first AI course! The future of learning is incredible 🚀",
                mediaUrl: nil,
                author: Profile(
                    id: UUID().uuidString,
                    displayName: "Alex Chen",
                    email: "alex@example.com",
                    avatarUrl: nil,
                    bio: "AI enthusiast",
                    stats: UserStats(
                        totalPoints: 1250,
                        streak: 7,
                        completedCourses: 3,
                        level: 5
                    )
                ),
                createdAt: Date().addingTimeInterval(-3600),
                likesCount: 24,
                commentsCount: 8,
                isLiked: false
            ),
            FeedItem(
                id: UUID().uuidString,
                text: "Sharing my latest project from the SwiftUI bootcamp 💻",
                mediaUrl: nil,
                author: Profile(
                    id: UUID().uuidString,
                    displayName: "Sarah Martinez",
                    email: "sarah@example.com",
                    avatarUrl: nil,
                    bio: "iOS Developer",
                    stats: UserStats(
                        totalPoints: 2100,
                        streak: 14,
                        completedCourses: 8,
                        level: 12
                    )
                ),
                createdAt: Date().addingTimeInterval(-7200),
                likesCount: 42,
                commentsCount: 15,
                isLiked: true
            )
        ]
    }
}

// MARK: - View Extensions
extension View {
    func onScrolledToBottom(perform action: @escaping () -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .global).maxY
                )
            }
        )
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { offset in
            if offset < 100 {
                action()
            }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    FeedView()
        .environmentObject(AppContainer.development())
}
