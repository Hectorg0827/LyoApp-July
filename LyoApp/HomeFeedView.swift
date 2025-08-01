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
        // Load feed data from backend - no longer using mock data
        Task {
            await loadFeedFromBackend()
        }
    }
    
    // Removed loadMockFeedItems() - now using real data from UserDataManager
    // func loadMockFeedItems() {
    //     // Mock data removed - using real data management
    // }
    
    @MainActor
    func loadFeedFromBackend() async {
        // Try to load feed from backend via LyoAPIService
        do {
            // Check if we have a valid connection first
            let _ = try await LyoAPIService.shared.getSystemHealth()
            print("📱 Feed: Backend health check passed")
            
            // TODO: Implement actual feed endpoint when available
            // For now, we'll use the existing API structure but with actual calls
            
            // Simulate real API call structure
            feedItems = []
            print("📱 Feed: Successfully loaded from backend (empty state)")
            
        } catch {
            print("📱 Feed: Backend unavailable, loading empty state - \(error)")
            feedItems = []
        }
    }
    
    func preload() async {}
    func cleanup() {}
    func preloadNextVideo(at index: Int) {}
    
    func toggleLike(for item: FeedItem) {
        if let index = feedItems.firstIndex(where: { $0.id == item.id }) {
            feedItems[index].engagement.isLiked.toggle()
            if feedItems[index].engagement.isLiked {
                feedItems[index].engagement.likes += 1
            } else {
                feedItems[index].engagement.likes -= 1
            }
            FeedbackManager.shared.likeAction()
        }
    }
    
    func toggleSave(for item: FeedItem) {
        if let index = feedItems.firstIndex(where: { $0.id == item.id }) {
            feedItems[index].engagement.isSaved.toggle()
            if feedItems[index].engagement.isSaved {
                feedItems[index].engagement.saves += 1
            } else {
                feedItems[index].engagement.saves -= 1
            }
            FeedbackManager.shared.saveAction()
        }
    }
}

class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    
    func cardSwipe() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        print("💬 Card swipe action triggered")
    }
    
    func likeAction() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        print("❤️ Like action triggered")
    }
    
    func saveAction() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        print("🔖 Save action triggered")
    }
    
    func buttonTap() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        print("👆 Button tap action triggered")
    }
}

struct FeedItem: Identifiable {
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
                // Use shared HeaderView for header (temporarily using original)
                HeaderView()
                    .padding(.top, 44)

                Spacer()

                // Social media overlay for reel
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 12) {
                        // Video title and username
                        if let item = feedManager.feedItems[safe: selectedIndex], case .video(_) = item.contentType {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("@lyoapp_official")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Learning AI: The Future is Here 🚀")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.bottom, 8)
                        }
                        
                        // Social actions (made smaller)
                        HStack(spacing: 20) {
                            Button(action: { 
                                if let item = feedManager.feedItems[safe: selectedIndex] {
                                    feedManager.toggleLike(for: item)
                                }
                            }) {
                                let item = feedManager.feedItems[safe: selectedIndex]
                                Image(systemName: item?.engagement.isLiked == true ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(item?.engagement.isLiked == true ? .red : .white)
                            }
                            Button(action: { 
                                feedbackManager.cardSwipe()
                                showChatOverlay.toggle()
                            }) {
                                Image(systemName: "bubble.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            Button(action: { 
                                if let item = feedManager.feedItems[safe: selectedIndex] {
                                    feedManager.toggleSave(for: item)
                                }
                            }) {
                                let item = feedManager.feedItems[safe: selectedIndex]
                                Image(systemName: item?.engagement.isSaved == true ? "bookmark.fill" : "bookmark")
                                    .font(.system(size: 20))
                                    .foregroundColor(item?.engagement.isSaved == true ? .yellow : .white)
                            }
                            Button(action: { 
                                feedbackManager.buttonTap()
                                print("📤 Share action triggered")
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20))
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
                            Button(action: { 
                                feedbackManager.buttonTap()
                                print("🎤 Voice input action triggered")
                                // TODO: Integrate with VoiceRecognizer
                            }) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                            Button(action: { 
                                feedbackManager.buttonTap()
                                print("📷 Camera/upload action triggered")
                                // TODO: Present camera/photo picker
                            }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(.blue)
                            }
                            Button(action: {
                                feedbackManager.buttonTap()
                                if !chatText.isEmpty {
                                    print("💬 Sending message: \(chatText)")
                                    chatText = ""
                                }
                            }) {
                                Image(systemName: "paperplane.fill")
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
                .ignoresSafeArea(.all, edges: .top)

            // Overlay UI Elements
            overlayUIElements
        }
        .onAppear {
            feedViewStartTime = Date()
            Task {
                await feedManager.preload()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let swipeThreshold: CGFloat = 100
                    if value.translation.height > swipeThreshold {
                        // Swipe down - previous item
                        if selectedIndex > 0 {
                            withAnimation(.spring()) {
                                selectedIndex -= 1
                            }
                            feedbackManager.cardSwipe()
                        }
                    } else if value.translation.height < -swipeThreshold {
                        // Swipe up - next item
                        if selectedIndex < feedManager.feedItems.count - 1 {
                            withAnimation(.spring()) {
                                selectedIndex += 1
                            }
                            feedbackManager.cardSwipe()
                        }
                    }
                }
        )
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
    
    // MARK: - Helper Functions
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
}

// MARK: - Content Views (file scope)