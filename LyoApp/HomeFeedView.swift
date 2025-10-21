import SwiftUI

// Import unified production-only configuration
struct FeedConfig {
    static let productionBackend = "https://lyo-backend-830162750094.us-central1.run.app"
    static let allowFallbackContent = false
    static let useMockData = false
}

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
    func loadMoreContent() async
    func refreshFeed() async
}

@MainActor
class FeedManager: ObservableObject, FeedDataProvider {
    @Published var feedItems: [FeedItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let backendService = BackendIntegrationService.shared
    private var currentPage = 1
    private var hasMoreContent = true

    init() {
        print("📱 FeedManager initialized - will load real feed data from backend")
        // Connect to backend and start loading real feed data
        Task {
            await backendService.connect()
            await loadFeedFromBackend()
        }
    }
    
    func loadFeedFromBackend() async {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            print("📱 Feed: Loading feed from backend - page \(currentPage)")
            
            let posts = try await backendService.loadFeedContent(page: currentPage, limit: 20)
            
            let newFeedItems = posts.map { post in
                convertToFeedItem(from: post)
            }
            
            if currentPage == 1 {
                feedItems = newFeedItems
            } else {
                feedItems.append(contentsOf: newFeedItems)
            }
            
            // Use real pagination from backend response
            hasMoreContent = newFeedItems.count >= 20 // Has more if we got a full page
            if hasMoreContent {
                currentPage += 1
            }
            
            errorMessage = nil
            print("📱 Feed: Successfully loaded \(newFeedItems.count) items. Total: \(feedItems.count)")
            
        } catch {
            print("📱 Feed: Error loading from backend - \(error)")
            errorMessage = "Unable to load feed. Please check your connection and try again."
            
            // NO FALLBACK TO MOCK DATA - Force real backend connectivity
            print("� Feed: No fallback data - real backend required")
        }
    }
    
    private func convertToFeedItem(from post: FeedPost) -> FeedItem {
        // Convert backend FeedPost to local FeedItem model
        let user = User(
            id: UUID(uuidString: post.userId) ?? UUID(),
            username: post.username,
            email: "\(post.username)@lyo.app",
            fullName: post.username.capitalized,
            bio: nil,
            profileImageURL: post.userAvatar
        )

        let engagement = EngagementMetrics(
            likes: post.likesCount,
            comments: post.commentsCount,
            shares: post.sharesCount,
            saves: 0,  // Not provided by API yet
            isLiked: post.isLiked,
            isSaved: post.isBookmarked
        )

        // Determine content type based on post data
        let contentType: FeedContentType
        if let imageURLs = post.imageURLs, !imageURLs.isEmpty, let _ = imageURLs.first {
            if let videoURL = post.videoURL {
                contentType = .video(VideoContent(
                    url: videoURL,
                    thumbnailURL: imageURLs.first ?? URL(string: "https://picsum.photos/400/600")!,
                    title: String(post.content.prefix(50)),
                    description: post.content,
                    quality: .hd,
                    duration: 180 // Default duration
                ))
            } else {
                contentType = .article(ArticleContent(
                    title: String(post.content.prefix(60)),
                    excerpt: String(post.content.prefix(150)),
                    content: post.content,
                    heroImageURL: imageURLs.first,
                    readTime: Double(post.content.count / 200 * 60) // Rough reading time calculation
                ))
            }
        } else {
            contentType = .article(ArticleContent(
                title: String(post.content.prefix(60)),
                excerpt: String(post.content.prefix(150)),
                content: post.content,
                heroImageURL: nil,
                readTime: Double(post.content.count / 200 * 60)
            ))
        }

        // Convert createdAt string to Date
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.date(from: post.createdAt) ?? Date()

        return FeedItem(
            id: UUID(uuidString: post.id) ?? UUID(),
            creator: user,
            contentType: contentType,
            timestamp: timestamp,
            engagement: engagement,
            duration: contentType.duration
        )
    }
    
    // REMOVED: loadFallbackContent() method
    // Production app does not use fallback content
    
    // MARK: - Feed Interactions (Real API)
    func toggleLike(for item: FeedItem) {
        // Optimistic update
        if let index = feedItems.firstIndex(where: { $0.id == item.id }) {
            let wasLiked = feedItems[index].engagement.isLiked
            feedItems[index].engagement.isLiked.toggle()
            if feedItems[index].engagement.isLiked {
                feedItems[index].engagement.likes += 1
            } else {
                feedItems[index].engagement.likes -= 1
            }
            FeedbackManager.shared.likeAction()
            
            // Make API call in background
            Task {
                do {
                    let response = try await APIClient.shared.likePost(item.id.uuidString)
                    // Update with server response
                    DispatchQueue.main.async {
                        if let index = self.feedItems.firstIndex(where: { $0.id == item.id }) {
                            self.feedItems[index].engagement.isLiked = response.isLiked
                            self.feedItems[index].engagement.likes = response.likesCount
                        }
                    }
                } catch {
                    print("❌ Failed to like post: \(error)")
                    // Revert optimistic update
                    DispatchQueue.main.async {
                        if let index = self.feedItems.firstIndex(where: { $0.id == item.id }) {
                            self.feedItems[index].engagement.isLiked = wasLiked
                            if wasLiked {
                                self.feedItems[index].engagement.likes += 1
                            } else {
                                self.feedItems[index].engagement.likes -= 1
                            }
                        }
                    }
                }
            }
        }
    }
    
    func toggleSave(for item: FeedItem) {
        // Optimistic update
        if let index = feedItems.firstIndex(where: { $0.id == item.id }) {
            feedItems[index].engagement.isSaved.toggle()
            if feedItems[index].engagement.isSaved {
                feedItems[index].engagement.saves += 1
            } else {
                feedItems[index].engagement.saves -= 1
            }
            FeedbackManager.shared.saveAction()
            
            // TODO: Implement save API endpoint when available
            print("🔖 Save action for item: \(item.id) - API endpoint needed")
        }
    }
    
    func shareItem(_ item: FeedItem) {
        FeedbackManager.shared.shareAction()
        print("📤 Share action for item: \(item.id)")
        // TODO: Implement share tracking API when available
    }

    // MARK: - Required Protocol Methods (Real API)
    func generateSuggestedUsers() -> [User] {
        // This will be replaced with real API call in future update
        return []
    }
    
    // REMOVED: generateRandomFeedItem() - no mock data allowed
    
    func loadMoreContent() async {
        await loadFeedFromBackend()
    }
    
    func refreshFeed() async {
        currentPage = 1
        hasMoreContent = true
        await loadFeedFromBackend()
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
    @StateObject private var backendService = BackendIntegrationService.shared
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
                // Top overlay with backend status
                topOverlayWithStatus(backendService)
                    .padding(.top, 44)
                
                // Story Drawer (temporarily commented out - TODO: implement StoriesDrawerView)
                // StoriesDrawerView(isExpanded: $showingStoryDrawer)
                //     .padding(.top, 8)
                //     .transition(.move(edge: .top).combined(with: .opacity))

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
            
            // Debug button (bottom left)
            VStack {
                Spacer()
                HStack {
                    DebugDataSourceView()
                    Spacer()
                }
            }
            
            // Live data indicator (top right, below production badge)
            VStack {
                Spacer()
                    .frame(height: 100)
                HStack {
                    Spacer()
                    LiveDataIndicator(itemCount: feedManager.feedItems.count)
                        .padding(.trailing, 16)
                }
                Spacer()
            }
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
    // .trackScreenView("Feed") // Removed: not a standard SwiftUI modifier
    // .preferredColorScheme(.dark) // Remove or fix if not needed
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

    
    // MARK: - Top Overlay with Backend Status
    @MainActor
    private func topOverlayWithStatus(_ backend: BackendIntegrationService) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("LyoApp")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                // Backend connection status
                HStack(spacing: 8) {
                    Image(systemName: backend.connectionStatusIcon)
                        .font(.caption)
                        .foregroundColor(backend.connectionStatusColor)
                    Text("Backend: \(backend.connectionStatus.displayText)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 16) {
                // Backend status button
                NavigationLink(destination: BackendStatusView()) {
                    Image(systemName: "server.rack")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                        )
                }
                
                // Search button
                Button(action: {
                    // Add search action
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title2)
                        .foregroundColor(.white)
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 40, height: 40)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.6), Color.clear]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
        )
    }

// MARK: - Content Views (file scope)

// MARK: - Live Data Indicator (For Feed Views)
struct LiveDataIndicator: View {
    let itemCount: Int
    @State private var isPulsing = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.green)
                .frame(width: 6, height: 6)
                .scaleEffect(isPulsing ? 1.2 : 1.0)
                .animation(Animation.easeInOut(duration: 1).repeatForever(), value: isPulsing)
            
            Text("LIVE DATA")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.green)
            
            Text("(\(itemCount))")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .cornerRadius(10)
        .onAppear { isPulsing = true }
    }
}

// MARK: - Debug Data Source View
struct DebugDataSourceView: View {
    @State private var showDebug = false
    @State private var healthStatus: String = "Not Tested"
    @State private var feedStatus: String = "Not Tested"
    @State private var feedCount: Int = 0
    
    var body: some View {
        Button(action: { showDebug.toggle() }) {
            Image(systemName: "ladybug.fill")
                .foregroundColor(.white)
                .padding(10)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding()
        .sheet(isPresented: $showDebug) {
            NavigationView {
                List {
                    Section("🌐 Backend Status") {
                        StatusRow(title: "Backend URL", value: APIConfig.baseURL, color: .blue)
                        StatusRow(title: "Environment", value: "Production", color: .green)
                        StatusRow(title: "Mock Data", value: "DISABLED ✅", color: .green)
                    }
                    
                    Section("🔍 Real-Time Tests") {
                        VStack(spacing: 12) {
                            TestButton(
                                title: "Test Health Endpoint",
                                icon: "heart.fill",
                                color: .green
                            ) {
                                await testHealthEndpoint()
                            }
                            
                            ResultRow(title: "Health Status", value: healthStatus)
                            
                            Divider()
                            
                            TestButton(
                                title: "Test Feed Endpoint",
                                icon: "square.stack.fill",
                                color: .blue
                            ) {
                                await testFeedEndpoint()
                            }
                            
                            ResultRow(title: "Feed Status", value: feedStatus)
                            ResultRow(title: "Posts Loaded", value: "\(feedCount)")
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("📊 Configuration") {
                        ConfigRow(title: "API Base URL", value: APIConfig.baseURL)
                        ConfigRow(title: "WebSocket URL", value: APIConfig.webSocketURL)
                        ConfigRow(title: "Use Local Backend", value: APIConfig.useLocalBackend ? "YES ⚠️" : "NO ✅")
                    }
                }
                .navigationTitle("🐛 Debug Dashboard")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            showDebug = false
                        }
                    }
                }
            }
        }
    }
    
    private func testHealthEndpoint() async {
        healthStatus = "Testing..."
        do {
            let response: SystemHealthResponse = try await APIClient.shared.getSystemHealth()
            let serviceLabel = response.service ?? "Backend"
            let versionLabel = response.version ?? "unknown"
            let environmentLabel = response.environment ?? "production"
            healthStatus = "✅ \(response.status.uppercased()) - \(serviceLabel) v\(versionLabel) [\(environmentLabel)]"
        } catch {
            healthStatus = "❌ Failed: \(error.localizedDescription)"
        }
    }
    
    private func testFeedEndpoint() async {
        feedStatus = "Loading..."
        feedCount = 0
        do {
            let response = try await APIClient.shared.loadFeed(page: 1, limit: 10)
            feedCount = response.posts.count
            feedStatus = "✅ SUCCESS - \(feedCount) posts loaded"
        } catch {
            feedStatus = "❌ Failed: \(error.localizedDescription)"
        }
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(color)
                .fontWeight(.medium)
        }
        .padding(.vertical, 2)
    }
}

struct TestButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () async -> Void
    
    @State private var isTesting = false
    
    var body: some View {
        Button(action: {
            Task {
                isTesting = true
                await action()
                isTesting = false
            }
        }) {
            HStack {
                Image(systemName: icon)
                Text(title)
                Spacer()
                if isTesting {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(10)
        }
        .disabled(isTesting)
    }
}

struct ResultRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct ConfigRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
    }
}
