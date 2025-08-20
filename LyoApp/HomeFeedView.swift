import SwiftUI

// MARK: - Core Data Models
struct FeedItem: Identifiable {
    let id: UUID
    let creator: User  // Changed from Creator to canonical User model
    let contentType: FeedContentType
    let timestamp: Date
    var engagement: EngagementMetrics
    let duration: TimeInterval?
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
    let thumbnailURL: URL
    let title: String
    let description: String
    let quality: VideoQuality
    let duration: TimeInterval
}

enum FeedContentType {
    case video(VideoContent)
    case article(ArticleContent)
    case product(ProductContent)
    
    // Access duration based on content type
    var duration: TimeInterval? {
        switch self {
        case .video(_):
            // Videos have fixed durations
            return 120.0 // Default 2 minutes if not specified
        case .article(let articleContent):
            // Articles have read times
            return articleContent.readTime
        case .product:
            // Products don't have durations
            return nil
        }
    }
}

enum VideoQuality: CaseIterable {
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

// MARK: - Safe Array Subscript Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Feed Protocol

@MainActor
protocol FeedDataProvider {
    var feedItems: [FeedItem] { get }
    func loadFeedFromBackend() async
    func generateSuggestedUsers() -> [User]
    func generateRandomFeedItem() -> FeedItem
}

@MainActor
class FeedManager: ObservableObject, FeedDataProvider {
    @Published var feedItems: [FeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        // Initialize with immediate demo content to prevent blank screen
        generateDemoContent()
        print("📱 FeedManager initialized with \(feedItems.count) demo items")
    }
    
    private func generateDemoContent() {
        // Create immediate demo content to prevent blank screen
        let demoUsers = [
            User(username: "lyoapp_official", email: "official@lyo.app", fullName: "LyoApp Official"),
            User(username: "tech_explorer", email: "tech@lyo.app", fullName: "Tech Explorer"),
            User(username: "design_guru", email: "design@lyo.app", fullName: "Design Guru"),
            User(username: "code_master", email: "code@lyo.app", fullName: "Code Master")
        ]
        
        // Create a variety of demo content types
        let demoItems: [FeedItem] = [
            // Demo video 1
            FeedItem(
                id: UUID(),
                creator: demoUsers[0],
                contentType: .video(VideoContent(
                    url: URL(string: "https://example.com/welcome-video.mp4")!,
                    thumbnailURL: URL(string: "https://picsum.photos/400/600?random=1")!,
                    title: "Welcome to LyoApp!",
                    description: "Discover the future of learning with AI-powered education",
                    quality: .hd,
                    duration: 180
                )),
                timestamp: Date(),
                engagement: EngagementMetrics(likes: 1240, comments: 89, shares: 34, saves: 156, isLiked: false, isSaved: false),
                duration: 180
            ),
            
            // Demo article 1
            FeedItem(
                id: UUID(),
                creator: demoUsers[1],
                contentType: .article(ArticleContent(
                    title: "The Future of iOS Development with SwiftUI",
                    excerpt: "Learn how SwiftUI is revolutionizing mobile app development with declarative syntax and powerful features.",
                    content: "SwiftUI represents a paradigm shift in iOS development, offering a declarative approach to building user interfaces...",
                    heroImageURL: URL(string: "https://picsum.photos/400/300?random=2"),
                    readTime: 420
                )),
                timestamp: Date().addingTimeInterval(-1800),
                engagement: EngagementMetrics(likes: 856, comments: 67, shares: 23, saves: 234, isLiked: false, isSaved: false),
                duration: 420
            ),
            
            // Demo video 2
            FeedItem(
                id: UUID(),
                creator: demoUsers[2],
                contentType: .video(VideoContent(
                    url: URL(string: "https://example.com/design-tips.mp4")!,
                    thumbnailURL: URL(string: "https://picsum.photos/400/600?random=3")!,
                    title: "UI Design Principles That Matter",
                    description: "Master the art of creating beautiful, user-friendly interfaces",
                    quality: .hd,
                    duration: 240
                )),
                timestamp: Date().addingTimeInterval(-3600),
                engagement: EngagementMetrics(likes: 2134, comments: 178, shares: 89, saves: 456, isLiked: false, isSaved: false),
                duration: 240
            ),
            
            // Demo product
            FeedItem(
                id: UUID(),
                creator: demoUsers[3],
                contentType: .product(ProductContent(
                    title: "Advanced SwiftUI Course",
                    price: "$49.99",
                    images: [URL(string: "https://picsum.photos/400/600?random=4")!],
                    model3DURL: nil,
                    description: "Master SwiftUI with hands-on projects and real-world examples"
                )),
                timestamp: Date().addingTimeInterval(-5400),
                engagement: EngagementMetrics(likes: 567, comments: 43, shares: 12, saves: 289, isLiked: false, isSaved: false),
                duration: nil
            ),
            
            // Demo article 2
            FeedItem(
                id: UUID(),
                creator: demoUsers[1],
                contentType: .article(ArticleContent(
                    title: "Building Your First AI-Powered iOS App",
                    excerpt: "Step-by-step guide to integrating machine learning into your iOS applications.",
                    content: "Artificial Intelligence is transforming mobile applications. Learn how to integrate CoreML and CreateML into your iOS projects...",
                    heroImageURL: URL(string: "https://picsum.photos/400/300?random=5"),
                    readTime: 600
                )),
                timestamp: Date().addingTimeInterval(-7200),
                engagement: EngagementMetrics(likes: 1456, comments: 234, shares: 67, saves: 789, isLiked: false, isSaved: false),
                duration: 600
            )
        ]
        
        feedItems = demoItems
        print("📱 Feed: Generated \(feedItems.count) demo items")
    }
    
    func loadFeedFromBackend() async {
        isLoading = true
        defer { isLoading = false }
        
        print("📱 Feed: Starting to load feed from backend...")
        
        // Keep existing demo content, just mark as loaded
        print("📱 Feed: Load complete. Using demo content. Total items: \(feedItems.count)")
    }
    
    // MARK: - Feed Interactions (Simplified)
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
    
    func shareItem(_ item: FeedItem) {
        FeedbackManager.shared.shareAction()
        print("📤 Share action for item: \(item.id)")
    }

    // MARK: - Required Protocol Methods (Simplified)
    func generateSuggestedUsers() -> [User] {
        return [
            User(username: "suggested_user1", email: "user1@lyo.app", fullName: "Suggested User 1"),
            User(username: "suggested_user2", email: "user2@lyo.app", fullName: "Suggested User 2")
        ]
    }
    
    func generateRandomFeedItem() -> FeedItem {
        let users = ["demo_user", "content_creator", "educator", "developer"]
        let randomUser = User(
            username: users.randomElement() ?? "demo_user",
            email: "demo@lyo.app",
            fullName: "Demo User"
        )
        
        let articleContent = ArticleContent(
            title: "Random Educational Content",
            excerpt: "Discover new learning opportunities",
            content: "This is sample educational content for demonstration purposes.",
            heroImageURL: URL(string: "https://picsum.photos/400/300?random=\(Int.random(in: 1...100))"),
            readTime: Double.random(in: 120...600)
        )
        
        return FeedItem(
            id: UUID(),
            creator: randomUser,
            contentType: .article(articleContent),
            timestamp: Date(),
            engagement: EngagementMetrics(
                likes: Int.random(in: 10...1000),
                comments: Int.random(in: 1...100),
                shares: Int.random(in: 1...50),
                saves: Int.random(in: 5...200),
                isLiked: false,
                isSaved: false
            ),
            duration: Double.random(in: 120...600)
        )
    }
    
    func preload() async {
        print("📱 Feed: Preloading content...")
        await loadFeedFromBackend()
    }
    
    func cleanup() {
        print("📱 Feed: Cleaning up resources...")
    }
    
    func preloadNextVideo(at index: Int) {
        guard index + 1 < feedItems.count else { return }
        print("📹 Preloading video at index \(index + 1)")
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
    
    func shareAction() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        print("📤 Share action triggered")
    }
    
    func buttonTap() {
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        print("👆 Button tap action triggered")
    }
}

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
            if feedManager.isLoading {
                // Loading state
                ZStack {
                    Color.black
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Loading content...")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            } else if feedManager.feedItems.isEmpty {
                // Empty state
                ZStack {
                    Color.black
                    VStack(spacing: 20) {
                        Image(systemName: "video.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text("No content available")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Check back later for new content")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                // Content state
                let item = feedManager.feedItems[safe: selectedIndex]
                switch item?.contentType {
                case .video(let videoContent):
                    tikTokStyleVideoView(videoContent: videoContent, geometry: geometry)
                case .article(let articleContent):
                    tikTokStyleArticleView(articleContent: articleContent, geometry: geometry)
                case .product(let productContent):
                    tikTokStyleProductView(productContent: productContent, geometry: geometry)
                case .none:
                    // Fallback for invalid index
                    ZStack {
                        Color.black
                        Text("Loading next content...")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
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
                        if let item = feedManager.feedItems[safe: selectedIndex] {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("@\(item.creator.username)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                
                                Text(contentDescription(for: item))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(3)
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
                                VStack(spacing: 4) {
                                    Image(systemName: item?.engagement.isLiked == true ? "heart.fill" : "heart")
                                        .font(.system(size: 24))
                                        .foregroundColor(item?.engagement.isLiked == true ? .red : .white)
                                    Text("\(item?.engagement.likes ?? 0)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Button(action: { 
                                feedbackManager.cardSwipe()
                                showChatOverlay.toggle()
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "bubble.right")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                    Text("\(feedManager.feedItems[safe: selectedIndex]?.engagement.comments ?? 0)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Button(action: { 
                                if let item = feedManager.feedItems[safe: selectedIndex] {
                                    feedManager.toggleSave(for: item)
                                }
                            }) {
                                let item = feedManager.feedItems[safe: selectedIndex]
                                VStack(spacing: 4) {
                                    Image(systemName: item?.engagement.isSaved == true ? "bookmark.fill" : "bookmark")
                                        .font(.system(size: 24))
                                        .foregroundColor(item?.engagement.isSaved == true ? .yellow : .white)
                                    Text("\(item?.engagement.saves ?? 0)")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Button(action: { 
                                if let item = feedManager.feedItems[safe: selectedIndex] {
                                    feedManager.shareItem(item)
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                    Text("Share")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                }
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
                Text(item?.creator.fullName ?? "Creator")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                if (item?.creator.level ?? 0) >= 3 { // Using level as a proxy for verification
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
        case .video(let videoContent):
            return videoContent.description
        case .article(let content):
            return content.excerpt
        case .product(let content):
            return content.description
        }
    }
}

// MARK: - Content Views (file scope)
