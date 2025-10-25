import SwiftUI
#if canImport(NukeUI)
import NukeUI
#endif

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
        // Initialize with immediate demo content to prevent blank screen if using mock data
        if DevelopmentConfig.useMockData {
            generateDemoContent()
            print("📱 FeedManager initialized with \(feedItems.count) demo items")
        } else {
            print("📱 FeedManager initialized - will load from backend")
        }
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
        
        // Check if we should use mock data
        if DevelopmentConfig.useMockData {
            generateDemoContent()
            print("📱 Feed: Using demo content. Total items: \(feedItems.count)")
            return
        }
        
        do {
            // First, check if backend is available
            let apiClient = APIClient.shared
            
            // Try to load real feed data from your backend
            let feedResponse: FeedResponse = try await apiClient.loadFeed()
            
            // The APIClient now returns canonical FeedItem models directly
            feedItems = feedResponse.posts
            
            print("✅ Feed: Successfully loaded \(feedItems.count) items from backend")
            
        } catch {
            print("❌ Feed: Failed to load from backend: \(error.localizedDescription)")
            print("📱 Feed: Falling back to demo content")
            
            // Fallback to demo content if backend fails
            generateDemoContent()
            errorMessage = "Could not connect to server. Showing demo content."
        }
    }
    
    // Helper function to map backend content to app content
    private func mapBackendContentType(_ backendItem: FeedItemResponse) -> FeedContentType {
        switch backendItem.type.lowercased() {
        case "video":
            return .video(VideoContent(
                url: URL(string: backendItem.mediaUrl ?? "") ?? URL(fileURLWithPath: ""),
                thumbnailURL: URL(string: backendItem.thumbnailUrl ?? "") ?? URL(fileURLWithPath: ""),
                title: backendItem.title,
                description: backendItem.content ?? "",
                quality: .hd,
                duration: 120 // Placeholder, consider adding to backend model
            ))
        case "article":
            return .article(ArticleContent(
                title: backendItem.title,
                excerpt: backendItem.content ?? "",
                content: backendItem.content ?? "",
                heroImageURL: URL(string: backendItem.thumbnailUrl ?? ""),
                readTime: 300 // Placeholder
            ))
        case "product":
            return .product(ProductContent(
                title: backendItem.title,
                price: "$0.00", // Placeholder
                images: [URL(string: backendItem.thumbnailUrl ?? "")].compactMap { $0 },
                model3DURL: nil,
                description: backendItem.content ?? ""
            ))
        default:
            // Fallback to article for any unknown type
            return .article(ArticleContent(
                title: backendItem.title,
                excerpt: backendItem.content ?? "Unsupported content type",
                content: backendItem.content ?? "",
                heroImageURL: URL(string: backendItem.thumbnailUrl ?? ""),
                readTime: 300 // Placeholder
            ))
        }
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
    #if canImport(NukeUI)
    LazyImage(url: videoContent.thumbnailURL) { state in
        if let image = state.image {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        } else {
            Rectangle()
                .fill(DesignTokens.Colors.subtleGradient)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "play.circle.fill")
                            .font(DesignTokens.font.largeTitle)
                            .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))
                            .shadow(radius: DesignTokens.Spacing.sm)

                        Text("Video Content")
                            .font(DesignTokens.Typography.titleMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                )
        }
    }
    #else
    AsyncImage(url: videoContent.thumbnailURL) { phase in
        switch phase {
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        default:
            Rectangle()
                .fill(DesignTokens.Colors.subtleGradient)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "play.circle.fill")
                            .font(DesignTokens.font.largeTitle)
                            .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))
                            .shadow(radius: DesignTokens.Spacing.sm)

                        Text("Video Content")
                            .font(DesignTokens.Typography.titleMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                )
        }
    }
    #endif
    .accessibilityLabel("Video content: \(videoContent.title)")
    .accessibilityHint("Double tap to play the video.")
}

private func tikTokStyleArticleView(articleContent: ArticleContent, geometry: GeometryProxy) -> some View {
    VStack(spacing: 0) {
        #if canImport(NukeUI)
        LazyImage(url: articleContent.heroImageURL) { state in
            if let image = state.image {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: geometry.size.height * 0.7)
                    .clipped()
            } else {
                Rectangle()
                    .fill(DesignTokens.Colors.cosmicGradient)
                    .frame(height: geometry.size.height * 0.7)
                    .overlay(
                        VStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "doc.text.fill")
                                .font(DesignTokens.font.largeTitle)
                                .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))

                            Text("Article Content")
                                .font(DesignTokens.Typography.titleMedium)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    )
            }
        }
        #else
        AsyncImage(url: articleContent.heroImageURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: geometry.size.height * 0.7)
                    .clipped()
            default:
                Rectangle()
                    .fill(DesignTokens.Colors.cosmicGradient)
                    .frame(height: geometry.size.height * 0.7)
                    .overlay(
                        VStack(spacing: DesignTokens.Spacing.md) {
                            Image(systemName: "doc.text.fill")
                                .font(DesignTokens.font.largeTitle)
                                .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))

                            Text("Article Content")
                                .font(DesignTokens.Typography.titleMedium)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    )
            }
        }
        #endif

        Rectangle()
            .fill(DesignTokens.Colors.backgroundPrimary.opacity(0.8))
            .frame(height: geometry.size.height * 0.3)
    }
    .accessibilityLabel("Article: \(articleContent.title)")
    .accessibilityHint("Swipe up to read the full article.")
}

private func tikTokStyleProductView(productContent: ProductContent, geometry: GeometryProxy) -> some View {
    #if canImport(NukeUI)
    LazyImage(url: productContent.images.first) { state in
        if let image = state.image {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        } else {
            Rectangle()
                .fill(DesignTokens.Colors.neonGradient)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "bag.fill")
                            .font(DesignTokens.font.largeTitle)
                            .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))

                        Text("Product For Sale")
                            .font(DesignTokens.Typography.titleMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                )
        }
    }
    #else
    AsyncImage(url: productContent.images.first) { phase in
        switch phase {
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        default:
            Rectangle()
                .fill(DesignTokens.Colors.neonGradient)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .overlay(
                    VStack(spacing: DesignTokens.Spacing.md) {
                        Image(systemName: "bag.fill")
                            .font(DesignTokens.font.largeTitle)
                            .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.8))

                        Text("Product For Sale")
                            .font(DesignTokens.Typography.titleMedium)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                )
        }
    }
    #endif
    .accessibilityLabel("Product: \(productContent.title)")
    .accessibilityHint("Double tap to view product details.")
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
        TabView(selection: $selectedIndex) {
            ForEach(Array(feedManager.feedItems.enumerated()), id: \.element.id) { index, item in
                LazyRenderView {
                    GeometryReader { geometry in
                        feedContent(for: item, geometry: geometry)
                    }
                }
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(Color.black)
        .ignoresSafeArea()
        .onChange(of: selectedIndex) { _ in
            feedbackManager.cardSwipe()
            feedManager.preloadNextVideo(at: selectedIndex)
        }
    }

    @ViewBuilder
    private func feedContent(for item: FeedItem, geometry: GeometryProxy) -> some View {
        switch item.contentType {
        case .video(let videoContent):
            tikTokStyleVideoView(videoContent: videoContent, geometry: geometry)
        case .article(let articleContent):
            tikTokStyleArticleView(articleContent: articleContent, geometry: geometry)
        case .product(let productContent):
            tikTokStyleProductView(productContent: productContent, geometry: geometry)
        }
    }

    // MARK: - Overlay UI Elements (Drawer, Nav, Actions)
    private var overlayUIElements: some View {
        ZStack {
            VStack(spacing: 0) {
                // Use shared HeaderView for header
                HeaderView()
                    .padding(.top, appState.isVisionPro ? 0 : 44)

                Spacer()

                // Social media overlay for reel
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        // Video title and username
                        if let item = feedManager.feedItems[safe: selectedIndex] {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                                Text("@\(item.creator.username)")
                                    .font(DesignTokens.Typography.labelLarge)
                                    .foregroundColor(DesignTokens.Colors.textPrimary.opacity(0.9))
                                    .textReadability()
                                
                                Text(contentDescription(for: item))
                                    .font(DesignTokens.Typography.bodyLarge)
                                    .foregroundColor(DesignTokens.Colors.textPrimary)
                                    .lineLimit(3)
                                    .multilineTextAlignment(.leading)
                                    .textReadability()
                            }
                            .padding(.bottom, DesignTokens.Spacing.sm)
                        }
                        
                        // Social actions
                        HStack(spacing: DesignTokens.Spacing.lg) {
                            Button(action: { 
                                if let item = feedManager.feedItems[safe: selectedIndex] {
                                    feedManager.toggleLike(for: item)
                                }
                            }) {
                                let item = feedManager.feedItems[safe: selectedIndex]
                                VStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: item?.engagement.isLiked == true ? "heart.fill" : "heart")
                                        .font(DesignTokens.font.title2)
                                        .foregroundColor(item?.engagement.isLiked == true ? DesignTokens.Colors.error : DesignTokens.Colors.textPrimary)
                                        .symbolEffect(.bounce, value: item?.engagement.isLiked)
                                    Text("\(item?.engagement.likes ?? 0)")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                            .accessibilityLabel(Text("Like button, \(feedManager.feedItems[safe: selectedIndex]?.engagement.likes ?? 0) likes"))
                            
                            Button(action: { 
                                feedbackManager.cardSwipe()
                                showChatOverlay.toggle()
                            }) {
                                VStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: "bubble.right")
                                        .font(DesignTokens.font.title2)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text("\(feedManager.feedItems[safe: selectedIndex]?.engagement.comments ?? 0)")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                            .accessibilityLabel(Text("Comments button, \(feedManager.feedItems[safe: selectedIndex]?.engagement.comments ?? 0) comments"))

                            Button(action: { 
                                if let item = feedManager.feedItems[safe: selectedIndex] {
                                    feedManager.toggleSave(for: item)
                                }
                            }) {
                                let item = feedManager.feedItems[safe: selectedIndex]
                                VStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: item?.engagement.isSaved == true ? "bookmark.fill" : "bookmark")
                                        .font(DesignTokens.font.title2)
                                        .foregroundColor(item?.engagement.isSaved == true ? DesignTokens.Colors.warning : DesignTokens.Colors.textPrimary)
                                        .symbolEffect(.bounce, value: item?.engagement.isSaved)
                                    Text("\(item?.engagement.saves ?? 0)")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                            .accessibilityLabel(Text("Save button, \(feedManager.feedItems[safe: selectedIndex]?.engagement.saves ?? 0) saves"))
                            
                            Button(action: { 
                                if let item = feedManager.feedItems[safe: selectedIndex] {
                                    feedManager.shareItem(item)
                                }
                            }) {
                                VStack(spacing: DesignTokens.Spacing.xs) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(DesignTokens.font.title2)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    Text("Share")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                            }
                            .accessibilityLabel(Text("Share button"))
                        }
                    }
                    .padding(.leading, DesignTokens.Spacing.md)
                    .padding(.bottom, appState.isVisionPro ? DesignTokens.Spacing.lg : 80)
                    Spacer()
                }
            }
            .ignoresSafeArea()

            // Chat overlay above nav bar
            if showChatOverlay {
                VStack {
                    Spacer()
                    VStack(spacing: DesignTokens.Spacing.md) {
                        HStack(spacing: DesignTokens.Spacing.sm) {
                            TextField("Type your message...", text: $chatText)
                                .padding(DesignTokens.Spacing.md)
                                .background(DesignTokens.Colors.neutral800)
                                .cornerRadius(DesignTokens.Radius.lg)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Button(action: { 
                                feedbackManager.buttonTap()
                                print("🎤 Voice input action triggered")
                                // TODO: Integrate with VoiceRecognizer
                            }) {
                                Image(systemName: "mic.fill")
                                    .font(DesignTokens.font.title2)
                                    .foregroundColor(DesignTokens.Colors.brand)
                            }
                            .accessibilityLabel(Text("Voice input"))

                            Button(action: { 
                                feedbackManager.buttonTap()
                                print("📷 Camera/upload action triggered")
                                // TODO: Present camera/photo picker
                            }) {
                                Image(systemName: "camera.fill")
                                    .font(DesignTokens.font.title2)
                                    .foregroundColor(DesignTokens.Colors.brand)
                            }
                            .accessibilityLabel(Text("Upload image or video"))

                            Button(action: {
                                feedbackManager.buttonTap()
                                if !chatText.isEmpty {
                                    print("💬 Sending message: \(chatText)")
                                    chatText = ""
                                }
                            }) {
                                Image(systemName: "paperplane.fill")
                                    .font(DesignTokens.font.title2)
                                    .foregroundColor(DesignTokens.Colors.brand)
                            }
                            .accessibilityLabel(Text("Send message"))
                        }
                        .padding(.horizontal)
                        .padding(.vertical, DesignTokens.Spacing.sm)
                        .background(BlurView(style: .systemMaterialDark))
                        .cornerRadius(DesignTokens.Radius.xl)
                        .shadow(radius: DesignTokens.Spacing.sm)
                    }
                    .padding(.bottom, appState.isVisionPro ? DesignTokens.Spacing.xl : 120) // Raised above nav bar
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
        .onDisappear {
            feedManager.cleanup()
            uiDelayTimer?.invalidate()
        }
        .trackScreenView("Feed")
        .preferredColorScheme(.dark)
    }

    // MARK: - Bottom Content Info (TikTok Style) - DEPRECATED
    // This view is no longer used in the main layout but kept for reference.
    private func bottomContentInfo(for item: FeedItem?) -> some View {
        return VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Creator info
            HStack(spacing: DesignTokens.Spacing.sm) {
                Text(item?.creator.fullName ?? "Creator")
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)

                if (item?.creator.level ?? 0) >= 3 { // Using level as a proxy for verification
                    Image(systemName: "checkmark.seal.fill")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.brand)
                }

                Button("Follow") {
                    feedbackManager.buttonTap()
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.xs)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .stroke(DesignTokens.Colors.textPrimary, lineWidth: 1)
                )
            }

            // Content description
            Text(contentDescription(for: item))
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, DesignTokens.Spacing.xs)
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
