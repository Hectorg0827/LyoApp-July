import SwiftUI
import AVKit

struct TikTokStyleHomeView: View {
    @StateObject private var viewModel = VideoFeedViewModel()
    @State private var currentIndex = 0
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                DesignTokens.Colors.primaryBg.ignoresSafeArea()
                
                // Video Feed
                TabView(selection: $currentIndex) {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.offset) { index, video in
                        VideoPlayerView(video: video)
                            .tag(index)
                            .ignoresSafeArea()
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .rotationEffect(.degrees(-90))
                .frame(
                    width: geometry.size.height,
                    height: geometry.size.width
                )
                .offset(x: (geometry.size.width - geometry.size.height) / 2, y: (geometry.size.height - geometry.size.width) / 2)
                
                // Right side controls
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        VStack(spacing: DesignTokens.Spacing.lg) {
                            // Profile picture
                            Button {
                                // Navigate to profile
                            } label: {
                                AsyncImage(url: URL(string: viewModel.videos[currentIndex].author.profileImageURL ?? "")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(DesignTokens.Colors.primaryGradient)
                                        .overlay(
                                            Text(viewModel.videos[currentIndex].author.fullName.prefix(1))
                                                .font(DesignTokens.Typography.caption)
                                                .foregroundColor(.white)
                                        )
                                }
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white, lineWidth: 2)
                                )
                            }
                            
                            // Like button
                            VideoActionButton(
                                icon: viewModel.videos[currentIndex].isLiked ? "heart.fill" : "heart",
                                count: viewModel.videos[currentIndex].likes,
                                isActive: viewModel.videos[currentIndex].isLiked,
                                activeColor: DesignTokens.Colors.neonPink
                            ) {
                                viewModel.toggleLike(at: currentIndex)
                            }
                            
                            // Comment button
                            VideoActionButton(
                                icon: "message",
                                count: viewModel.videos[currentIndex].comments,
                                isActive: false
                            ) {
                                // Show comments
                            }
                            
                            // Share button
                            VideoActionButton(
                                icon: "arrowshape.turn.up.right",
                                count: viewModel.videos[currentIndex].shares,
                                isActive: false
                            ) {
                                // Share video
                            }
                            
                            // AI Assistant button
                            Button {
                                // Show AI assistant for this video
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(DesignTokens.Colors.primaryGradient)
                                        .frame(width: 50, height: 50)
                                        .shadow(color: DesignTokens.Colors.primary.opacity(0.4), radius: 10, x: 0, y: 0)
                                    
                                    Image(systemName: "sparkles")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .padding(.trailing, DesignTokens.Spacing.md)
                    }
                    
                    Spacer()
                }
                
                // Bottom overlay with video info
                VStack {
                    Spacer()
                    
                    HStack {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            Text("@\(viewModel.videos[currentIndex].author.username)")
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(.white)
                            
                            Text(viewModel.videos[currentIndex].title)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(.white)
                                .lineLimit(2)
                            
                            // Hashtags
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DesignTokens.Spacing.xs) {
                                    ForEach(viewModel.videos[currentIndex].hashtags, id: \.self) { hashtag in
                                        Text("#\(hashtag)")
                                            .font(DesignTokens.Typography.caption)
                                            .foregroundColor(DesignTokens.Colors.neonBlue)
                                    }
                                }
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                    .padding(.bottom, DesignTokens.Spacing.xl)
                }
                
                // Top navigation
                VStack {
                    HStack {
                        Button {
                            // Following tab
                        } label: {
                            Text("Following")
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button {
                            // For You tab (active)
                        } label: {
                            Text("For You")
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(.white)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 2)
                                        .foregroundColor(.white)
                                        .offset(y: 15)
                                )
                        }
                        
                        Spacer()
                        
                        Button {
                            // AI Recommendations
                        } label: {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                Text("AI")
                                    .font(DesignTokens.Typography.bodyMedium)
                            }
                            .foregroundColor(DesignTokens.Colors.neonBlue)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.top, DesignTokens.Spacing.md)
                    
                    Spacer()
                }
                
                // Search button
                VStack {
                    HStack {
                        Spacer()
                        
                        Button {
                            // Open search
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.3))
                                        .blur(radius: 10)
                                )
                        }
                        .padding(.trailing, DesignTokens.Spacing.md)
                    }
                    .padding(.top, DesignTokens.Spacing.md)
                    
                    Spacer()
                }
            }
        }
        .onAppear {
            viewModel.loadVideos()
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    if value.translation.y < -50 && currentIndex < viewModel.videos.count - 1 {
                        currentIndex += 1
                    } else if value.translation.y > 50 && currentIndex > 0 {
                        currentIndex -= 1
                    }
                    dragOffset = .zero
                }
        )
    }
}

// MARK: - Video Action Button
struct VideoActionButton: View {
    let icon: String
    let count: Int
    let isActive: Bool
    let activeColor: Color
    let action: () -> Void
    
    init(icon: String, count: Int, isActive: Bool, activeColor: Color = DesignTokens.Colors.textPrimary, action: @escaping () -> Void) {
        self.icon = icon
        self.count = count
        self.isActive = isActive
        self.activeColor = activeColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isActive ? activeColor : .white)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.3))
                            .blur(radius: 10)
                    )
                
                if count > 0 {
                    Text(formatCount(count))
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return "\(count / 1000000)M"
        } else if count >= 1000 {
            return "\(count / 1000)K"
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Video Player View
struct VideoPlayerView: View {
    let video: VideoPost
    @State private var player: AVPlayer?
    @State private var isPlaying = true
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                // Placeholder while loading
                Rectangle()
                    .fill(DesignTokens.Colors.secondaryBg)
                    .overlay(
                        ProgressView()
                            .tint(DesignTokens.Colors.primary)
                    )
            }
            
            // Play/Pause overlay
            if !isPlaying {
                Button {
                    player?.play()
                    isPlaying = true
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 80, height: 80)
                        )
                }
            }
        }
        .onTapGesture {
            if isPlaying {
                player?.pause()
                isPlaying = false
            } else {
                player?.play()
                isPlaying = true
            }
        }
        .onAppear {
            setupPlayer()
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: video.videoURL) else { return }
        player = AVPlayer(url: url)
        player?.actionAtItemEnd = .none
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }
}

// MARK: - Video Feed View Model
class VideoFeedViewModel: ObservableObject {
    @Published var videos: [VideoPost] = []
    @Published var isLoading = false
    
    func loadVideos() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.videos = VideoPost.sampleVideos
            self.isLoading = false
        }
    }
    
    func toggleLike(at index: Int) {
        videos[index].isLiked.toggle()
        if videos[index].isLiked {
            videos[index].likes += 1
        } else {
            videos[index].likes -= 1
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
    
    static let sampleVideos: [VideoPost] = [
        VideoPost(
            author: User(username: "techguru", email: "tech@example.com", fullName: "Tech Guru"),
            title: "Quick tip that will save you hours of debugging 🔧",
            videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            thumbnailURL: "https://picsum.photos/300/400?random=1",
            likes: 33700,
            comments: 297,
            shares: 178,
            hashtags: ["AI", "MachineLearning", "Python"],
            createdAt: Date().addingTimeInterval(-3600)
        ),
        VideoPost(
            author: User(username: "designpro", email: "design@example.com", fullName: "Design Pro"),
            title: "SwiftUI animation tricks that will blow your mind ✨",
            videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4",
            thumbnailURL: "https://picsum.photos/300/400?random=2",
            likes: 28500,
            comments: 156,
            shares: 89,
            hashtags: ["SwiftUI", "iOS", "Animation"],
            createdAt: Date().addingTimeInterval(-7200)
        ),
        VideoPost(
            author: User(username: "codewiz", email: "code@example.com", fullName: "Code Wizard"),
            title: "Building a neural network from scratch in 60 seconds 🧠",
            videoURL: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
            thumbnailURL: "https://picsum.photos/300/400?random=3",
            likes: 45200,
            comments: 432,
            shares: 267,
            hashtags: ["NeuralNetwork", "DeepLearning", "AI"],
            createdAt: Date().addingTimeInterval(-10800)
        )
    ]
}

#Preview {
    TikTokStyleHomeView()
}