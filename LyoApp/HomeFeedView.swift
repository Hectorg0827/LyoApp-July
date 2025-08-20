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

    private let postRepository = PostRepository()
    private let userRepository = UserRepository()
    private let courseRepository = CourseRepository()

    init() {
        // Load feed data from repositories
        Task {
            await loadFeedFromBackend()
        }
    }
    
    func loadFeedFromBackend() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Try to load feed from backend via LyoAPIService
            let _ = try await LyoAPIService.shared.getSystemHealth()
            print("📱 Feed: Backend health check passed")
            
            // Load real data from repositories
            await loadRealFeedData()
            
        } catch {
            print("⚠️ Feed: Error connecting to backend - \(error.localizedDescription)")
            
            // If we have no data, create some sample data for first-time users
            if feedItems.isEmpty {
                await createInitialSampleData()
            }
        }
    }
    
    private func loadRealFeedData() async {
        // Load posts from PostRepository
        await postRepository.loadPosts(limit: 50)
        
        // Convert Core Data posts to FeedItems
        feedItems = postRepository.posts.compactMap { post in
            postRepository.convertToFeedItem(post)
        }
        
        print("📱 Feed: Loaded \(feedItems.count) real feed items")
    }
    
    private func createInitialSampleData() async {
        // Only create sample data if no real data exists
        let existingPosts = postRepository.posts
        if existingPosts.isEmpty {
            // Create a few sample users and posts for first-time experience
            await createSampleUsersAndPosts()
            await loadRealFeedData()
        }
    }
    
    private func createSampleUsersAndPosts() async {
        let sampleUsers = [
            ("tech_explorer", "tech@example.com", "Alex Chen", "Tech enthusiast and AI researcher"),
            ("design_maven", "design@example.com", "Jamie Rodriguez", "UI/UX Designer passionate about beautiful interfaces"),
            ("code_ninja", "code@example.com", "Jordan Smith", "Full-stack developer and open source contributor")
        ]
        
        for (username, email, fullName, bio) in sampleUsers {
            let result = await userRepository.createUser(
                username: username,
                email: email,
                fullName: fullName,
                bio: bio,
                profileImageURL: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d"
            )
            
            if case .success(let user) = result {
                // Create sample posts for this user
                await createSamplePostsForUser(user)
            }
        }
    }
    
    private func createSamplePostsForUser(_ user: User) async {
        let samplePosts = [
            "Just discovered an amazing new SwiftUI feature! The declarative syntax makes everything so much cleaner.",
            "Working on a new iOS app that uses Core Data and SwiftUI together. The integration is seamless!",
            "Learning about advanced iOS animation techniques. The possibilities are endless!"
        ]
        
        for content in samplePosts {
            _ = await postRepository.createPost(
                authorId: user.id.uuidString,
                content: content,
                tags: ["ios", "swift", "development"]
            )
        }
    }

    // MARK: - Feed Interactions
    func toggleLike(for item: FeedItem) {
        if let index = feedItems.firstIndex(where: { $0.id == item.id }) {
            feedItems[index].engagement.isLiked.toggle()
            if feedItems[index].engagement.isLiked {
                feedItems[index].engagement.likes += 1
            } else {
                feedItems[index].engagement.likes -= 1
            }
            
            // Update in repository
            Task {
                await postRepository.likePost(item.id.uuidString, by: "current_user_id")
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
        Task {
            await postRepository.sharePost(item.id.uuidString, by: "current_user_id")
        }
        FeedbackManager.shared.shareAction()
    }

    // MARK: - Required Protocol Methods (No longer generate mock data)
    func generateSuggestedUsers() -> [User] {
        // Return real users from repository
        return userRepository.users
    }
    
    func generateRandomFeedItem() -> FeedItem {
        // This should not be called anymore, but return a placeholder if needed
        let placeholderUser = User(username: "placeholder", email: "placeholder@example.com", fullName: "Placeholder User")
        let placeholderContent = ArticleContent(
            title: "Loading...",
            excerpt: "Content is being loaded",
            content: "Please wait while we load your feed",
            heroImageURL: nil,
            readTime: 60
        )
        
        return FeedItem(
            id: UUID(),
            creator: placeholderUser,
            contentType: .article(placeholderContent),
            timestamp: Date(),
            engagement: EngagementMetrics(likes: 0, comments: 0, shares: 0, saves: 0, isLiked: false, isSaved: false),
            duration: 60
        )
    }
    
    func preload() async {
        await loadFeedFromBackend()
    }
    
    func cleanup() {
        // Clean up resources when view disappears
    }
    
    func preloadNextVideo(at index: Int) {
        // Preload next video for better performance
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
