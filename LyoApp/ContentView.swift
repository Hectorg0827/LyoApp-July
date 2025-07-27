import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var voiceActivationService: VoiceActivationService
    @State private var showingAIFlow = false
    @State private var showingStoryDrawer = false
    
    var body: some View {
        TikTokStyleHomeView()
            .onAppear {
                // Initialize app without mock data
                // User authentication should happen through proper login flow
                print("📱 LyoApp initialized - waiting for user authentication")
            }
    }
}

// MARK: - Feed Item View
struct FeedItemView: View {
    let index: Int
    @State private var isLiked = false
    @State private var showComments = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            // User header
            HStack {
                AsyncImage(url: URL(string: "https://picsum.photos/40/40?random=\(index)")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Text("U")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("@techguru")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("2m ago")
                        .font(DesignTokens.Typography.caption)
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
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.md)
            
            // Content
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Quick tip that will save you hours of debugging 🔧\nAlways check your edge case...")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .padding(.horizontal, DesignTokens.Spacing.md)
                
                // Tags
                HStack(spacing: DesignTokens.Spacing.xs) {
                    ForEach(["#AI", "#MachineLearning", "#Python"], id: \.self) { tag in
                        Text(tag)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.primary)
                            .padding(.horizontal, DesignTokens.Spacing.sm)
                            .padding(.vertical, DesignTokens.Spacing.xs)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                            )
                    }
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            
            // Actions
            HStack {
                Button {
                    withAnimation(DesignTokens.Animations.bouncy) {
                        isLiked.toggle()
                    }
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? DesignTokens.Colors.neonPink : DesignTokens.Colors.textSecondary)
                        Text("33.7K")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button {
                    showComments = true
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "message")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("297")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button {
                    // Share
                } label: {
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        Image(systemName: "arrowshape.turn.up.right")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        Text("178")
                            .font(DesignTokens.Typography.caption)
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
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.md)
        }
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .shadow(color: DesignTokens.Colors.primary.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - TikTok Style Home View
struct TikTokStyleHomeView: View {
    @StateObject private var viewModel = VideoFeedViewModel()
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            // Background
            DesignTokens.Colors.primaryBg.ignoresSafeArea(.container, edges: .horizontal)
            
            // Video Feed Content
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.offset) { index, video in
                        VideoFeedItemView(video: video, index: index)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .containerRelativeFrame(.vertical)
                    }
                }
                .scrollTargetBehavior(.paging)
            }
            .scrollIndicators(.hidden)
            
            // Overlay UI
            VStack {
                // Top UI
                HStack {
                    Spacer()
                    
                    Button {
                        // Search
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                }
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            viewModel.loadVideos()
        }
    }
}

// MARK: - Video Feed Item View
struct VideoFeedItemView: View {
    let video: VideoPost
    let index: Int
    @State private var isLiked = false
    
    var body: some View {
        ZStack {
            // Background gradient
            DesignTokens.Colors.primaryGradient
            
            // Content
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Author info
                HStack {
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Text(video.author.fullName.prefix(1))
                                .font(.title2)
                                .foregroundColor(.white)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("@\(video.author.username)")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(.white)
                        
                        Text("2m ago")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                
                // Video content
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text(video.title)
                        .font(DesignTokens.Typography.title2)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                    
                    // Hashtags
                    HStack(spacing: DesignTokens.Spacing.xs) {
                        ForEach(video.hashtags, id: \.self) { hashtag in
                            Text("#\(hashtag)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.neonBlue)
                        }
                    }
                }
                
                Spacer()
                
                // Actions
                HStack {
                    Button {
                        isLiked.toggle()
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundColor(isLiked ? DesignTokens.Colors.neonPink : .white)
                            Text("\(video.likes)")
                                .foregroundColor(.white)
                        }
                        .font(DesignTokens.Typography.caption)
                    }
                    
                    Spacer()
                    
                    Button {
                        // Comments
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "message")
                                .foregroundColor(.white)
                            Text("\(video.comments)")
                                .foregroundColor(.white)
                        }
                        .font(DesignTokens.Typography.caption)
                    }
                    
                    Spacer()
                    
                    Button {
                        // Share
                    } label: {
                        HStack(spacing: DesignTokens.Spacing.xs) {
                            Image(systemName: "arrowshape.turn.up.right")
                                .foregroundColor(.white)
                            Text("\(video.shares)")
                                .foregroundColor(.white)
                        }
                        .font(DesignTokens.Typography.caption)
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - Video Feed View Model
class VideoFeedViewModel: ObservableObject {
    @Published var videos: [VideoPost] = []
    @Published var isLoading = false
    
    func loadVideos() {
        isLoading = true
        
        // Load real data using UserDataManager
        Task {
            await MainActor.run {
                // TODO: Implement getUserVideos() in UserDataManager
                // self.videos = UserDataManager.shared.getUserVideos()
                self.videos = [] // Empty until real data loading is implemented
                self.isLoading = false
            }
        }
    }
}

// MARK: - Video Post Model
struct VideoPost: Identifiable {
    let id = UUID()
    let author: User
    let title: String
    let videoURL: String
    let thumbnailURL: String
    var likes: Int
    var comments: Int
    var shares: Int
    var isLiked: Bool = false
    let hashtags: [String]
    let createdAt: Date
    
    // MARK: - Sample Data Removed
    // All sample videos moved to UserDataManager for real data management
    // static let sampleVideos = [] // Use UserDataManager.shared.getUserVideos()
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(VoiceActivationService.shared)
}