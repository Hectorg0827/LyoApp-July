import SwiftUI
import AVKit
import AVFoundation

// MARK: - Enhanced Video Models

struct VideoPost: Identifiable, Codable, Hashable {
    let id: UUID
    var creator: User
    var videoURL: URL
    var thumbnailURL: URL?
    var title: String
    var description: String
    var hashtags: [String]
    var soundName: String?
    var soundURL: URL?
    var duration: TimeInterval
    var createdAt: Date
    var viewCount: Int
    var engagement: VideoEngagement
    var isSaved: Bool = false
    
    init(id: UUID = UUID(), creator: User, videoURL: URL, thumbnailURL: URL? = nil,
         title: String, description: String, hashtags: [String] = [],
         soundName: String? = nil, soundURL: URL? = nil, duration: TimeInterval = 0,
         createdAt: Date = Date(), viewCount: Int = 0,
         engagement: VideoEngagement = VideoEngagement(), isSaved: Bool = false) {
        self.id = id
        self.creator = creator
        self.videoURL = videoURL
        self.thumbnailURL = thumbnailURL
        self.title = title
        self.description = description
        self.hashtags = hashtags
        self.soundName = soundName
        self.soundURL = soundURL
        self.duration = duration
        self.createdAt = createdAt
        self.viewCount = viewCount
        self.engagement = engagement
        self.isSaved = isSaved
    }
}

struct VideoEngagement: Codable, Hashable {
    var likes: Int = 0
    var comments: Int = 0
    var shares: Int = 0
    var saves: Int = 0
    var isLiked: Bool = false
}

// MARK: - Video Feed Manager

@MainActor
class VideoFeedManager: ObservableObject {
    @Published var videos: [VideoPost] = []
    @Published var savedVideos: [VideoPost] = []
    @Published var isLoading = false
    @Published var currentUserProfile: User?
    
    init() {
        // Load saved videos from UserDefaults
        loadSavedVideos()
        // Generate mock content (replace with API call)
        generateMockVideos()
    }
    
    func generateMockVideos() {
        // Mock users
        let mockUsers = [
            User(username: "tech_guru", email: "tech@example.com", fullName: "Alex Tech", 
                 bio: "Teaching you code daily 💻", followers: 125_000, following: 89, posts: 234, isVerified: true),
            User(username: "data_science_pro", email: "data@example.com", fullName: "Sarah Data",
                 bio: "Data Science | AI | ML 🤖", followers: 98_500, following: 156, posts: 189, isVerified: true),
            User(username: "design_master", email: "design@example.com", fullName: "Mike Design",
                 bio: "UI/UX Design Tips 🎨", followers: 156_000, following: 234, posts: 312, isVerified: true),
            User(username: "code_ninja", email: "ninja@example.com", fullName: "Emma Code",
                 bio: "Swift & iOS Development 📱", followers: 87_300, following: 78, posts: 156),
            User(username: "web_wizard", email: "web@example.com", fullName: "Jake Web",
                 bio: "Full Stack Developer 🌐", followers: 67_800, following: 123, posts: 203)
        ]
        
        // Mock video content
        let videoTopics = [
            ("Master SwiftUI Animations", "Learn professional animations in 60 seconds", ["swiftui", "ios", "animation", "coding"]),
            ("Build a REST API", "Complete backend tutorial from scratch", ["api", "backend", "nodejs", "tutorial"]),
            ("Data Structures Explained", "Binary Trees made simple", ["algorithms", "coding", "datastructures", "tutorial"]),
            ("Design System Secrets", "How top apps maintain consistency", ["design", "ui", "ux", "figma"]),
            ("Python in 60 Seconds", "Quick Python tips you need to know", ["python", "programming", "tutorial", "coding"]),
            ("React Hooks Deep Dive", "Understanding useEffect and useState", ["react", "javascript", "webdev", "hooks"]),
            ("Machine Learning Basics", "Your first ML model explained", ["ml", "ai", "python", "datascience"]),
            ("CSS Grid Masterclass", "Layouts made easy with Grid", ["css", "webdev", "frontend", "tutorial"]),
            ("Git Like a Pro", "Advanced Git techniques", ["git", "programming", "tutorial", "devtools"]),
            ("Database Optimization", "Make your queries 10x faster", ["sql", "database", "performance", "backend"])
        ]
        
        // Generate videos
        videos = videoTopics.enumerated().map { index, topic in
            let user = mockUsers[index % mockUsers.count]
            return VideoPost(
                id: UUID(),
                creator: user,
                videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
                thumbnailURL: nil,
                title: topic.0,
                description: topic.1,
                hashtags: topic.2,
                soundName: "Original Sound - \(user.username)",
                soundURL: nil,
                duration: Double.random(in: 15...120),
                createdAt: Date().addingTimeInterval(-Double.random(in: 0...86400)),
                viewCount: Int.random(in: 1_000...500_000),
                engagement: VideoEngagement(
                    likes: Int.random(in: 100...50_000),
                    comments: Int.random(in: 10...5_000),
                    shares: Int.random(in: 5...2_000),
                    saves: Int.random(in: 10...3_000),
                    isLiked: false
                ),
                isSaved: false
            )
        }
    }
    
    func toggleLike(for video: VideoPost) {
        if let index = videos.firstIndex(where: { $0.id == video.id }) {
            videos[index].engagement.isLiked.toggle()
            if videos[index].engagement.isLiked {
                videos[index].engagement.likes += 1
            } else {
                videos[index].engagement.likes -= 1
            }
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    func toggleSave(for video: VideoPost) {
        if let index = videos.firstIndex(where: { $0.id == video.id }) {
            videos[index].isSaved.toggle()
            
            if videos[index].isSaved {
                // Add to saved videos
                if !savedVideos.contains(where: { $0.id == video.id }) {
                    savedVideos.append(videos[index])
                }
                videos[index].engagement.saves += 1
            } else {
                // Remove from saved videos
                savedVideos.removeAll { $0.id == video.id }
                videos[index].engagement.saves -= 1
            }
            
            // Save to UserDefaults
            saveSavedVideos()
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(videos[index].isSaved ? .success : .warning)
        }
    }
    
    func shareVideo(_ video: VideoPost) {
        if let index = videos.firstIndex(where: { $0.id == video.id }) {
            videos[index].engagement.shares += 1
        }
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func addComment(to video: VideoPost) {
        if let index = videos.firstIndex(where: { $0.id == video.id }) {
            videos[index].engagement.comments += 1
        }
    }
    
    // MARK: - Persistence
    private func saveSavedVideos() {
        if let encoded = try? JSONEncoder().encode(savedVideos) {
            UserDefaults.standard.set(encoded, forKey: "savedVideos")
        }
    }
    
    private func loadSavedVideos() {
        if let data = UserDefaults.standard.data(forKey: "savedVideos"),
           let decoded = try? JSONDecoder().decode([VideoPost].self, from: data) {
            savedVideos = decoded
        }
    }
    
    func incrementViewCount(for video: VideoPost) {
        if let index = videos.firstIndex(where: { $0.id == video.id }) {
            videos[index].viewCount += 1
        }
    }
}

// MARK: - Main TikTok Feed View

struct TikTokVideoFeedView: View {
    @StateObject private var feedManager = VideoFeedManager()
    @State private var currentIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showComments = false
    @State private var showShare = false
    @State private var showUserProfile = false
    @State private var selectedUser: User?
    @State private var showVideoCreation = false
    @State private var showingStoryDrawer: Bool = false
    @GestureState private var isDragging = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if feedManager.videos.isEmpty {
                loadingView
            } else {
                // Video pager
                videoPageView
                    .gesture(
                        DragGesture()
                            .updating($isDragging) { _, state, _ in
                                state = true
                            }
                            .onChanged { value in
                                // Only vertical swipes
                                if abs(value.translation.width) < abs(value.translation.height) {
                                    dragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 100
                                if value.translation.height < -threshold && currentIndex < feedManager.videos.count - 1 {
                                    // Swipe up - next video
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        currentIndex += 1
                                        dragOffset = 0
                                    }
                                } else if value.translation.height > threshold && currentIndex > 0 {
                                    // Swipe down - previous video
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        currentIndex -= 1
                                        dragOffset = 0
                                    }
                                } else {
                                    // Spring back
                                    withAnimation(.spring()) {
                                        dragOffset = 0
                                    }
                                }
                            }
                    )
            }
            
            // Story Drawer at the top
            VStack {
                StoriesDrawerView(isExpanded: $showingStoryDrawer)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
                Spacer()
            }
            
            // Overlays
            if showComments, let video = currentVideo {
                CommentsSheet(video: video, isPresented: $showComments, feedManager: feedManager)
                    .transition(.move(edge: .bottom))
            }
            
            if showShare, let video = currentVideo {
                ShareSheet(video: video, isPresented: $showShare, feedManager: feedManager)
                    .transition(.move(edge: .bottom))
            }
            
            if showUserProfile, let user = selectedUser {
                UserProfileSheet(user: user, isPresented: $showUserProfile, feedManager: feedManager)
                    .transition(.move(edge: .trailing))
            }
            
            // Video creation floating button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showVideoCreation = true }) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.pink, Color.purple]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 60, height: 60)
                                .shadow(color: Color.pink.opacity(0.4), radius: 10, x: 0, y: 4)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showComments)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showShare)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showUserProfile)
        .fullScreenCover(isPresented: $showVideoCreation) {
            VideoCreationFlowView { newVideo in
                // Add new video to the feed at the beginning
                feedManager.videos.insert(newVideo, at: 0)
                currentIndex = 0
            }
        }
    }
    
    private var currentVideo: VideoPost? {
        guard currentIndex < feedManager.videos.count else { return nil }
        return feedManager.videos[currentIndex]
    }
    
    private var videoPageView: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(feedManager.videos.enumerated()), id: \.element.id) { index, video in
                    if abs(index - currentIndex) <= 1 {
                        VideoPlayerView(
                            video: video,
                            isCurrentVideo: index == currentIndex,
                            feedManager: feedManager,
                            onUserTap: {
                                selectedUser = video.creator
                                showUserProfile = true
                            },
                            onCommentsTap: { showComments = true },
                            onShareTap: { showShare = true }
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(y: CGFloat(index - currentIndex) * geometry.size.height + (index == currentIndex ? dragOffset : 0))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            Text("Loading videos...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Video Player View

struct VideoPlayerView: View {
    let video: VideoPost
    let isCurrentVideo: Bool
    @ObservedObject var feedManager: VideoFeedManager
    let onUserTap: () -> Void
    let onCommentsTap: () -> Void
    let onShareTap: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPaused = false
    @State private var showDescription = false
    
    var body: some View {
        ZStack {
            // Video player
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .ignoresSafeArea()
                    .onTapGesture {
                        togglePlayPause()
                    }
            } else {
                Color.black
            }
            
            // Gradient overlays for readability
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.clear, Color.black.opacity(0.4)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                // Top bar
                topBar
                
                Spacer()
                
                // Bottom content
                HStack(alignment: .bottom) {
                    // Left side - Video info
                    VStack(alignment: .leading, spacing: 12) {
                        // Creator info
                        Button(action: onUserTap) {
                            HStack(spacing: 12) {
                                // Profile image
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Text(video.creator.username.prefix(1).uppercased())
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text("@\(video.creator.username)")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        if video.creator.isVerified {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    
                                    Text("\(formatNumber(video.creator.followers)) followers")
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Video title
                        Text(video.title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        // Description
                        Button(action: { showDescription.toggle() }) {
                            Text(video.description)
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.9))
                                .lineLimit(showDescription ? nil : 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Hashtags
                        if !video.hashtags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(video.hashtags, id: \.self) { hashtag in
                                        Text("#\(hashtag)")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.2))
                                            )
                                    }
                                }
                            }
                        }
                        
                        // Sound info
                        if let soundName = video.soundName {
                            HStack(spacing: 8) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 14))
                                Text(soundName)
                                    .font(.system(size: 14))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                        
                        // View count
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 12))
                            Text("\(formatNumber(video.viewCount)) views")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.leading, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 80)
                    
                    Spacer()
                    
                    // Right side - Action buttons
                    actionButtons
                        .padding(.trailing, 12)
                }
                .padding(.bottom, 100)
            }
            
            // Pause indicator
            if isPaused {
                Image(systemName: "pause.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.white.opacity(0.8))
                    .shadow(radius: 10)
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            cleanup()
        }
        .onChange(of: isCurrentVideo) { _, newValue in
            if newValue {
                player?.play()
                feedManager.incrementViewCount(for: video)
            } else {
                player?.pause()
            }
        }
    }
    
    private var topBar: some View {
        HStack {
            Spacer()
            
            // Following / For You toggle
            HStack(spacing: 20) {
                Text("Following")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("For You")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(.top, 60)
        .padding(.horizontal)
    }
    
    private var actionButtons: some View {
        VStack(spacing: 24) {
            // Like button
            Button(action: {
                feedManager.toggleLike(for: video)
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        if video.engagement.isLiked {
                            LottieHeartAnimation()
                        }
                        Image(systemName: video.engagement.isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 32, weight: .semibold))
                            .foregroundColor(video.engagement.isLiked ? .red : .white)
                    }
                    
                    Text(formatNumber(video.engagement.likes))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // Comments button
            Button(action: onCommentsTap) {
                VStack(spacing: 4) {
                    Image(systemName: "bubble.right.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    
                    Text(formatNumber(video.engagement.comments))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // Save button
            Button(action: {
                feedManager.toggleSave(for: video)
            }) {
                VStack(spacing: 4) {
                    Image(systemName: video.isSaved ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 30))
                        .foregroundColor(video.isSaved ? .yellow : .white)
                    
                    Text(formatNumber(video.engagement.saves))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // Share button
            Button(action: onShareTap) {
                VStack(spacing: 4) {
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    
                    Text(formatNumber(video.engagement.shares))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            
            // Creator profile (rotating disc)
            Button(action: onUserTap) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(video.creator.username.prefix(1).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .rotationEffect(isCurrentVideo ? .degrees(360) : .degrees(0))
                    .animation(
                        isCurrentVideo ? .linear(duration: 3).repeatForever(autoreverses: false) : .default,
                        value: isCurrentVideo
                    )
            }
        }
    }
    
    private func setupPlayer() {
        let playerItem = AVPlayerItem(url: video.videoURL)
        player = AVPlayer(playerItem: playerItem)
        player?.isMuted = false
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        if isCurrentVideo {
            player?.play()
            feedManager.incrementViewCount(for: video)
        }
    }
    
    private func cleanup() {
        player?.pause()
        player = nil
    }
    
    private func togglePlayPause() {
        isPaused.toggle()
        if isPaused {
            player?.pause()
        } else {
            player?.play()
        }
        
        // Hide pause indicator after delay
        if isPaused {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPaused = false
            }
        }
    }
}

// MARK: - Comments Sheet

struct CommentsSheet: View {
    let video: VideoPost
    @Binding var isPresented: Bool
    @ObservedObject var feedManager: VideoFeedManager
    @State private var commentText = ""
    @State private var comments: [VideoComment] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            // Header
            HStack {
                Text("\(formatNumber(video.engagement.comments)) Comments")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
            
            // Comments list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(comments) { comment in
                        CommentRow(comment: comment)
                    }
                    
                    if comments.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No comments yet")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            Text("Be the first to comment!")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Comment input
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("U")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                TextField("Add comment...", text: $commentText)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                
                Button(action: postComment) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(commentText.isEmpty ? .gray : .blue)
                }
                .disabled(commentText.isEmpty)
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        // Mock comments
        comments = [
            VideoComment(user: User(username: "user123", email: "", fullName: "User 123"),
                        text: "This is amazing! 🔥", timestamp: Date()),
            VideoComment(user: User(username: "learner_pro", email: "", fullName: "Pro Learner"),
                        text: "Thanks for sharing this!", timestamp: Date()),
        ]
    }
    
    private func postComment() {
        guard !commentText.isEmpty else { return }
        
        // Add comment (would call API here)
        feedManager.addComment(to: video)
        commentText = ""
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct CommentRow: View {
    let comment: VideoComment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Text(comment.user.username.prefix(1).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user.username)
                        .font(.system(size: 14, weight: .semibold))
                    
                    Text(timeAgo(comment.timestamp))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Text(comment.text)
                    .font(.system(size: 15))
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .font(.system(size: 12))
                            Text("\(comment.likes)")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.gray)
                    }
                    
                    Button(action: {}) {
                        Text("Reply")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
    }
}

struct VideoComment: Identifiable {
    let id = UUID()
    let user: User
    let text: String
    let timestamp: Date
    var likes: Int = 0
}

// MARK: - Share Sheet

struct ShareSheet: View {
    let video: VideoPost
    @Binding var isPresented: Bool
    @ObservedObject var feedManager: VideoFeedManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 12)
            
            // Header
            HStack {
                Text("Share")
                    .font(.system(size: 18, weight: .bold))
                
                Spacer()
                
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
            }
            .padding()
            
            Divider()
            
            // Share options
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 24) {
                ShareOption(icon: "message.fill", title: "Message", color: .blue)
                ShareOption(icon: "link", title: "Copy Link", color: .green)
                ShareOption(icon: "square.and.arrow.up", title: "More", color: .orange)
                ShareOption(icon: "square.and.arrow.down", title: "Save", color: .purple)
            }
            .padding()
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .frame(height: 300)
    }
}

struct ShareOption: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                )
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - User Profile Sheet

struct UserProfileSheet: View {
    let user: User
    @Binding var isPresented: Bool
    @ObservedObject var feedManager: VideoFeedManager
    @State private var isFollowing = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    VStack(spacing: 16) {
                        // Profile image
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Text(user.username.prefix(1).uppercased())
                                    .font(.system(size: 40, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                            .shadow(radius: 10)
                        
                        // Username
                        HStack(spacing: 6) {
                            Text("@\(user.username)")
                                .font(.system(size: 24, weight: .bold))
                            
                            if user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        // Bio
                        if let bio = user.bio {
                            Text(bio)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Stats
                        HStack(spacing: 40) {
                            StatView(number: user.following, label: "Following")
                            StatView(number: user.followers, label: "Followers")
                            StatView(number: user.posts, label: "Videos")
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                isFollowing.toggle()
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }) {
                                Text(isFollowing ? "Following" : "Follow")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        isFollowing ?
                                        Color.gray.opacity(0.3) :
                                        LinearGradient(
                                            colors: [.pink, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {}) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.primary)
                                    .frame(width: 44, height: 44)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 20)
                    
                    // Saved videos section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Saved Videos")
                            .font(.system(size: 20, weight: .bold))
                            .padding(.horizontal)
                        
                        if feedManager.savedVideos.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "bookmark")
                                    .font(.system(size: 48))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text("No saved videos yet")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 2) {
                                ForEach(feedManager.savedVideos) { video in
                                    SavedVideoThumbnail(video: video)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

struct StatView: View {
    let number: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(formatNumber(number))
                .font(.system(size: 20, weight: .bold))
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
}

struct SavedVideoThumbnail: View {
    let video: VideoPost
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .aspectRatio(9/16, contentMode: .fit)
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text(formatNumber(video.viewCount))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(4)
                }
            )
    }
}

// MARK: - Helper Views

struct LottieHeartAnimation: View {
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 32))
            .foregroundColor(.red)
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
            }
    }
}

// MARK: - Helper Functions

func formatNumber(_ number: Int) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    
    if number >= 1_000_000 {
        return String(format: "%.1fM", Double(number) / 1_000_000.0)
    } else if number >= 1_000 {
        return String(format: "%.1fK", Double(number) / 1_000.0)
    } else {
        return "\(number)"
    }
}

func timeAgo(_ date: Date) -> String {
    let interval = Date().timeIntervalSince(date)
    
    if interval < 60 {
        return "Just now"
    } else if interval < 3600 {
        let minutes = Int(interval / 60)
        return "\(minutes)m ago"
    } else if interval < 86400 {
        let hours = Int(interval / 3600)
        return "\(hours)h ago"
    } else {
        let days = Int(interval / 86400)
        return "\(days)d ago"
    }
}

// MARK: - Custom Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview

#Preview {
    TikTokVideoFeedView()
}
