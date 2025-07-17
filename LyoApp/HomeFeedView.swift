import SwiftUI
// MARK: - Safe Array Subscript Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
// MARK: - Core Models (Fixes missing type errors)
// MARK: - Missing Models and Managers (Restored)

enum VideoQuality {
    case sd, hd, uhd
}

struct ArticleContent {
    let title: String
    let excerpt: String
    let content: String
    let heroImageURL: URL?
    let readTime: TimeInterval
}

struct ProductContent {
    let title: String
    let price: String
    let images: [URL]
    let model3DURL: URL?
    let description: String
}

class FeedManager: ObservableObject {
    @Published var feedItems: [FeedItem] = []

    init() {
        // Generate mock feed items for demo
        feedItems = [
            FeedItem(
                id: UUID(),
                creator: Creator(
                    id: UUID(),
                    username: "lyo_official",
                    displayName: "Lyo",
                    avatarURL: nil,
                    isVerified: true
                ),
                contentType: .video(VideoContent(
                    url: URL(string: "https://lyo.app/video.mp4")!,
                    thumbnailURL: nil,
                    duration: 15,
                    quality: .hd
                )),
                timestamp: Date(),
                engagement: EngagementMetrics(likes: 120, comments: 12, shares: 5, saves: 8, isLiked: false, isSaved: false),
                duration: 15
            ),
            FeedItem(
                id: UUID(),
                creator: Creator(
                    id: UUID(),
                    username: "creator2",
                    displayName: "Jane Doe",
                    avatarURL: nil,
                    isVerified: false
                ),
                contentType: .article(ArticleContent(
                    title: "How to Use Lyo",
                    excerpt: "Learn how to get the most out of Lyo.",
                    content: "Full article content here...",
                    heroImageURL: nil,
                    readTime: 3
                )),
                timestamp: Date(),
                engagement: EngagementMetrics(likes: 45, comments: 3, shares: 2, saves: 1, isLiked: false, isSaved: false),
                duration: nil
            )
        ]
    }
    func preload() async {}
    func cleanup() {}
    func preloadNextVideo(at index: Int) {}
    func toggleLike(for item: FeedItem) {}
    func toggleSave(for item: FeedItem) {}
}

class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    func cardSwipe() {}
    func likeAction() {}
    func saveAction() {}
    func buttonTap() {}
}

struct FeedItem {
    let id: UUID
    let creator: Creator
    let contentType: FeedContentType
    let timestamp: Date
    var engagement: EngagementMetrics
    let duration: TimeInterval?
}

struct Creator {
    let id: UUID
    let username: String
    let displayName: String
    let avatarURL: URL?
    let isVerified: Bool
}

struct EngagementMetrics {
    var likes: Int
    var comments: Int
    var shares: Int
    var saves: Int
    var isLiked: Bool
    var isSaved: Bool
}


struct VideoContent {
    let url: URL
    let thumbnailURL: URL?
    let duration: TimeInterval
    let quality: VideoQuality
}

enum FeedContentType {
    case video(VideoContent)
    case article(ArticleContent)
    case product(ProductContent)
}
// ...existing code...

// MARK: - Minimal DiscoverHeaderView (Fixes missing symbol error)
// MARK: - Content Views (Moved above immersiveContentView for SwiftUI scoping)
private func tikTokStyleVideoView(videoContent: VideoContent, geometry: GeometryProxy) -> some View {
    AsyncImage(url: videoContent.thumbnailURL) { image in
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
    } placeholder: {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.gray.opacity(0.3), .black.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Video Content")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            )
    }
}

private func tikTokStyleArticleView(articleContent: ArticleContent, geometry: GeometryProxy) -> some View {
    VStack(spacing: 0) {
        AsyncImage(url: articleContent.heroImageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: geometry.size.height * 0.7)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.3), .purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: geometry.size.height * 0.7)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white.opacity(0.8))

                        Text("Article Content")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                )
        }

        Rectangle()
            .fill(Color.black.opacity(0.8))
            .frame(height: geometry.size.height * 0.3)
    }
}

private func tikTokStyleProductView(productContent: ProductContent, geometry: GeometryProxy) -> some View {
    AsyncImage(url: productContent.images.first) { image in
        image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
    } placeholder: {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.green.opacity(0.3), .teal.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: geometry.size.width, height: geometry.size.height)
            .overlay(
                VStack(spacing: 8) {
                    Image(systemName: "bag.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.8))

                    Text("Product Content")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            )
    }
}
struct DiscoverHeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Text("Discover")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
        }
        .padding()
    }
}
struct HomeFeedView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var feedManager: FeedManager = FeedManager()
    @StateObject private var feedbackManager = FeedbackManager.shared
    @State private var selectedIndex: Int = 0
    @State private var feedViewStartTime: Date?
    @State private var showingStoryDrawer: Bool = false
    @State private var showingUI: Bool = true
    @State private var uiDelayTimer: Timer?
    @State private var showChatOverlay: Bool = false
    @State private var chatText: String = ""

    // MARK: - Immersive Content View (Main Feed)
    private var immersiveContentView: some View {
        GeometryReader { geometry in
            let item = feedManager.feedItems[safe: selectedIndex]
            switch item?.contentType {
            case .video(let videoContent):
                tikTokStyleVideoView(videoContent: videoContent, geometry: geometry)
            case .article(let articleContent):
                tikTokStyleArticleView(articleContent: articleContent, geometry: geometry)
            case .product(let productContent):
                tikTokStyleProductView(productContent: productContent, geometry: geometry)
            case .none:
                Color.black
            }
        }
    }

    // MARK: - Overlay UI Elements (Drawer, Nav, Actions)
    private var overlayUIElements: some View {
        ZStack {
            VStack(spacing: 0) {
                // Use shared DiscoverHeaderView for header
                DiscoverHeaderView()
                    .padding(.top, 44)
                    .padding(.horizontal)

                Spacer()

                // Social media overlay for reel
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Video title
                        if let item = feedManager.feedItems[safe: selectedIndex], case .video(_) = item.contentType {
                            Text("Lyo Official Reel")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.bottom, 4)
                        }
                        // Social actions
                        HStack(spacing: 24) {
                            Button(action: { feedbackManager.likeAction() }) {
                                Image(systemName: "heart")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            Button(action: { feedbackManager.cardSwipe() }) {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            Button(action: { feedbackManager.saveAction() }) {
                                Image(systemName: "bookmark")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                            Button(action: { /* Share */ }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 24))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 80)
                    Spacer()
                }
            }
            .ignoresSafeArea()

            // Chat overlay above nav bar
            if showChatOverlay {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            TextField("Type your message...", text: $chatText)
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                .font(.system(size: 16))
                            Button(action: { /* Voice input */ }) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                            Button(action: { /* Camera/upload */ }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(BlurView(style: .systemMaterialDark))
                        .cornerRadius(20)
                        .shadow(radius: 8)
                    }
                    .padding(.bottom, 120) // Raised above nav bar
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: showChatOverlay)
            }
        }
    }
    var body: some View {
        ZStack {
            // Full-screen content - TikTok style
            immersiveContentView
                .ignoresSafeArea(.all)

            // Overlay UI Elements
            overlayUIElements
        }
        .onAppear {
            feedViewStartTime = Date()
            Task {
                await feedManager.preload()
            }
        }
        .onDisappear {
            feedManager.cleanup()
            uiDelayTimer?.invalidate()
        }
        .trackScreenView("Feed")
        .preferredColorScheme(.dark)
    }

    // MARK: - Bottom Content Info (TikTok Style)
    private func bottomContentInfo(for item: FeedItem?) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            // Creator info
            HStack(spacing: 8) {
                Text(item?.creator.displayName ?? "Creator")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                if item?.creator.isVerified ?? false {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }

                Button("Follow") {
                    feedbackManager.buttonTap()
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: 1)
                )
            }

            // Content description
            Text(contentDescription(for: item))
                .font(.system(size: 14))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 4)

}

}

// MARK: - Content Views (file scope)

// MARK: - Helper Functions (file scope)
private func contentDescription(for item: FeedItem?) -> String {
    guard let item = item else { return "Sample content description" }

    switch item.contentType {
    case .video:
        return "Amazing video content that will blow your mind! 🔥 #trending #viral"
    case .article(let content):
        return content.title
    case .product(let content):
        return "\(content.title) - \(content.price)"
    }
}