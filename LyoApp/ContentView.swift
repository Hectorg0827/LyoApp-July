import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var voiceActivationService: VoiceActivationService
    @EnvironmentObject var userDataManager: UserDataManager
    @State private var showingAIFlow = false
    @State private var showingStoryDrawer = false
    @State private var videos: [VideoPost] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack {
                // Debug information
                Text("Debug: ContentView loaded")
                    .foregroundColor(.red)
                    .font(.caption)
                
                if isLoading {
                    ProgressView("Loading content...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if videos.isEmpty {
                    EmptyStateView(
                        icon: "video.circle",
                        title: "No Videos Yet",
                        description: "Start exploring and saving videos to see them here"
                    )
                } else {
                    VideoFeedView(videos: videos)
                }
            }
            .onAppear {
                print("🔍 ContentView appeared, loading content...")
                loadContent()
            }
            .refreshable {
                print("🔄 Refreshing content...")
                await refreshContent()
            }
        }
    }
    
    private func loadContent() {
        print("🔍 loadContent() called")
        Task {
            print("🔍 Starting Task for loadContent")
            // For now, create some sample videos until UserDataManager is fully integrated
            await MainActor.run {
                print("🔍 MainActor.run - creating sample videos")
                self.videos = createSampleVideos()
                print("🔍 Created \(self.videos.count) sample videos")
                self.isLoading = false
                print("🔍 Set isLoading = false")
            }
            
            // Track analytics
            print("📊 ANALYTICS: Content view loaded")
        }
    }
    
    private func refreshContent() async {
        await MainActor.run {
            isLoading = true
            loadContent()
        }
    }
    
    private func createSampleVideos() -> [VideoPost] {
        let sampleUser = User(
            username: "lyolearner",
            email: "learner@lyo.app",
            fullName: "Lyo Learner"
        )
        
        return [
            VideoPost(
                author: sampleUser,
                title: "Swift Programming Basics",
                videoURL: "https://example.com/video1.mp4",
                thumbnailURL: "https://picsum.photos/400/600?random=1",
                likes: 125,
                comments: 23,
                shares: 8,
                hashtags: ["#Swift", "#iOS", "#Programming"],
                createdAt: Date()
            ),
            VideoPost(
                author: sampleUser,
                title: "AI and Machine Learning Introduction",
                videoURL: "https://example.com/video2.mp4",
                thumbnailURL: "https://picsum.photos/400/600?random=2",
                likes: 89,
                comments: 15,
                shares: 4,
                hashtags: ["#AI", "#MachineLearning", "#Tech"],
                createdAt: Date().addingTimeInterval(-3600)
            )
        ]
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            VStack(spacing: DesignTokens.Spacing.md) {
                Text(title)
                    .font(DesignTokens.Typography.headlineMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(description)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Video Feed View
struct VideoFeedView: View {
    let videos: [VideoPost]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(videos) { video in
                    VideoFeedItemView(video: video)
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
    }
}

// MARK: - Video Feed Item View
struct VideoFeedItemView: View {
    let video: VideoPost
    @State private var isLiked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Author info
            HStack {
                Circle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(video.author.username.prefix(1)).uppercased())
                            .font(DesignTokens.Typography.labelMedium)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("@\(video.author.username)")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("2m ago")
                        .font(DesignTokens.Typography.bodySmall)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
            }
            
            // Video content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                Text(video.title)
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                // Video thumbnail
                AsyncImage(url: URL(string: video.thumbnailURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(DesignTokens.Colors.backgroundSecondary)
                        .aspectRatio(16/9, contentMode: .fill)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
                .frame(maxHeight: 200)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                
                // Hashtags
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(video.hashtags, id: \.self) { tag in
                        Text(tag)
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.primary)
                    }
                    Spacer()
                }
            }
            
            // Actions
            HStack {
                Button {
                    withAnimation {
                        isLiked.toggle()
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : DesignTokens.Colors.textSecondary)
                        Text("\(video.likes)")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button {
                    // Comments
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "message")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("\(video.comments)")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button {
                    // Share
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("\(video.shares)")
                            .font(DesignTokens.Typography.bodySmall)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
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
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.backgroundElevated)
                .stroke(DesignTokens.Colors.neutral300, lineWidth: 1)
        )
        .shadow(color: DesignTokens.Colors.primary.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(VoiceActivationService.shared)
        .environmentObject(UserDataManager.shared)
}
