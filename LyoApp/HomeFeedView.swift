import SwiftUI

// MARK: - Feed Models
struct FeedItem: Identifiable, Codable {
    var id = UUID()
    let user: FeedUser
    let mediaURL: String
    let description: String
    let tags: [String]
    let timeAgo: String
    let likesCount: Int
    let commentsCount: Int
    let sharesCount: Int
    let type: FeedItemType
    
    enum FeedItemType: String, Codable, CaseIterable {
        case shortVideo = "short_video"
        case image = "image"
        case educational = "educational"
        case tutorial = "tutorial"
    }
}

struct FeedUser: Identifiable, Codable {
    var id = UUID()
    let username: String
    let name: String
    let avatarURL: String
    let isVerified: Bool
    let followerCount: Int
}

// MARK: - Feed Content Types
enum FeedContentType {
    case video(FeedItem)
    case courseSuggestions([Course])
    case userSuggestions([SuggestedUser])
}

// Using Course model from Models.swift

struct SuggestedUser: Identifiable {
    var id = UUID()
    let username: String
    let name: String
    let avatarURL: String
    let isVerified: Bool
    let followerCount: Int
    let specialty: String
    let mutualConnections: Int
}

// MARK: - Feed Manager
@MainActor
class FeedManager: ObservableObject {
    @Published var feedContent: [FeedContentType] = []
    @Published var isLoading = false
    @Published var hasMoreContent = true
    @Published var feedItems: [FeedItem] = []
    @Published var loadTime: TimeInterval = 0.0
    
    private var videoCount = 0
    private let videosBeforeInterruption = 5
    private let videosAfterCourses = 2
    
    func loadInitialContent() {
        guard !isLoading else { return }
        
        isLoading = true
        videoCount = 0
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // Simulate network delay
            
            let initialContent = generateInitialContent()
            
            await MainActor.run {
                feedContent = initialContent
                isLoading = false
            }
        }
    }
    
    func loadMoreContent() {
        guard !isLoading && hasMoreContent else { return }
        
        isLoading = true
        
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            let newContent = generateMoreContent()
            
            await MainActor.run {
                feedContent.append(contentsOf: newContent)
                isLoading = false
            }
        }
    }
    
    func preload() async {
        loadInitialContent()
    }
    
    func cleanup() {
        feedContent.removeAll()
        feedItems.removeAll()
    }
    
    private func generateInitialContent() -> [FeedContentType] {
        var content: [FeedContentType] = []
        
        // Start with 5 videos
        for _ in 0..<videosBeforeInterruption {
            content.append(.video(generateRandomFeedItem()))
            videoCount += 1
        }
        
        // Add course suggestions
        content.append(.courseSuggestions(generateCourses()))
        
        // Add 2 more videos
        for _ in 0..<videosAfterCourses {
            content.append(.video(generateRandomFeedItem()))
            videoCount += 1
        }
        
        // Add user suggestions
        content.append(.userSuggestions(generateSuggestedUsers()))
        
        // Continue with endless videos
        for _ in 0..<10 {
            content.append(.video(generateRandomFeedItem()))
            videoCount += 1
        }
        
        return content
    }
    
    private func generateMoreContent() -> [FeedContentType] {
        var content: [FeedContentType] = []
        
        // Add more videos with occasional interruptions
        for i in 0..<10 {
            content.append(.video(generateRandomFeedItem()))
            videoCount += 1
            
            // Every 7-10 videos, add some suggestions
            if i == 4 {
                content.append(.courseSuggestions(generateCourses()))
            } else if i == 8 {
                content.append(.userSuggestions(generateSuggestedUsers()))
            }
        }
        
        return content
    }
    
    private func generateCourses() -> [Course] {
        let courses = [
            "SwiftUI Masterclass", "iOS Development", "Machine Learning", "Data Science",
            "Web Development", "Python Programming", "JavaScript Fundamentals", "React Native"
        ]
        
        let instructors = [
            "Dr. Sarah Chen", "Prof. Michael Johnson", "Alex Rodriguez", "Emma Watson",
            "David Kim", "Lisa Thompson", "James Wilson", "Maria Garcia"
        ]
        
        return (0..<3).map { index in
            Course(
                id: UUID(),
                title: courses.randomElement() ?? "Programming Course",
                description: "A comprehensive course to master the fundamentals and advanced concepts.",
                instructor: instructors.randomElement() ?? "Expert Instructor",
                thumbnailURL: "course_\(index + 1)",
                duration: TimeInterval(Int.random(in: 2...12) * 3600), // Convert hours to seconds
                difficulty: Course.Difficulty.allCases.randomElement() ?? .beginner,
                category: "Programming",
                lessons: [], // Empty for now
                progress: 0.0,
                isEnrolled: false,
                rating: Double.random(in: 4.0...5.0),
                studentsCount: Int.random(in: 100...50000)
            )
        }
    }
    
    private func generateSuggestedUsers() -> [SuggestedUser] {
        let users = [
            "techguru_alex", "codemaster_sarah", "designpro_mike", "dataqueen_emma",
            "swiftdev_john", "uiux_designer", "ml_researcher", "frontend_ninja"
        ]
        
        let names = [
            "Alex Thompson", "Sarah Johnson", "Mike Chen", "Emma Rodriguez",
            "John Wilson", "Lisa Kim", "David Garcia", "Maria Lopez"
        ]
        
        let specialties = [
            "iOS Developer", "UI/UX Designer", "Data Scientist", "Full Stack Dev",
            "ML Engineer", "Product Designer", "Backend Developer", "Frontend Expert"
        ]
        
        return (0..<3).map { index in
            SuggestedUser(
                username: users.randomElement() ?? "user_\(index)",
                name: names.randomElement() ?? "User \(index)",
                avatarURL: "avatar_\(index + 1)",
                isVerified: Bool.random(),
                followerCount: Int.random(in: 1000...100000),
                specialty: specialties.randomElement() ?? "Developer",
                mutualConnections: Int.random(in: 0...15)
            )
        }
    }
    
    private func generateRandomFeedItem() -> FeedItem {
        let mockUsers = [
            FeedUser(username: "techguru", name: "Alex Chen", avatarURL: "https://picsum.photos/200/200?random=1", isVerified: true, followerCount: 125000),
            FeedUser(username: "designpro", name: "Sarah Kim", avatarURL: "https://picsum.photos/200/200?random=2", isVerified: true, followerCount: 98000),
            FeedUser(username: "codemaster", name: "Mike Johnson", avatarURL: "https://picsum.photos/200/200?random=3", isVerified: false, followerCount: 45000),
            FeedUser(username: "uxqueen", name: "Emma Davis", avatarURL: "https://picsum.photos/200/200?random=4", isVerified: true, followerCount: 78000),
            FeedUser(username: "swiftdev", name: "David Liu", avatarURL: "https://picsum.photos/200/200?random=5", isVerified: false, followerCount: 34000),
            FeedUser(username: "airesearcher", name: "Sophie Martinez", avatarURL: "https://picsum.photos/200/200?random=6", isVerified: true, followerCount: 89000),
            FeedUser(username: "datavis", name: "Ryan Taylor", avatarURL: "https://picsum.photos/200/200?random=7", isVerified: false, followerCount: 67000),
            FeedUser(username: "productguru", name: "Maya Patel", avatarURL: "https://picsum.photos/200/200?random=8", isVerified: true, followerCount: 112000)
        ]
        
        let descriptions = [
            "Building the future with cutting-edge technology 🚀\nSwipe up to see the magic happen!\n\n#TechInnovation #FutureIsNow",
            "Just shipped a new feature that's going to change everything 💥\nCan't wait for you to try it!\n\n#ProductLaunch #Innovation",
            "Here's how I solved this complex algorithm in 30 seconds ⚡\nThe secret is in the data structure choice\n\n#Coding #Algorithms",
            "UI/UX design trends that will dominate 2025 ✨\nMinimalism meets functionality\n\n#Design #UX #Trends",
            "Breaking down machine learning concepts for beginners 🧠\nMaking AI accessible to everyone\n\n#MachineLearning #AI #Education",
            "Quick tip that will save you hours of debugging 🔧\nAlways check your edge cases first!\n\n#CodingTips #Programming",
            "Behind the scenes of our latest app launch 📱\nFrom concept to 1M downloads\n\n#AppDevelopment #Startup",
            "Data visualization that tells a compelling story 📊\nNumbers never lie, but presentation matters\n\n#DataScience #Analytics"
        ]
        
        let tags = [
            ["Swift", "iOS", "Programming"],
            ["Design", "UI", "Figma"],
            ["React", "JavaScript", "WebDev"],
            ["AI", "MachineLearning", "Python"],
            ["Cloud", "AWS", "DevOps"],
            ["Mobile", "Flutter", "CrossPlatform"],
            ["Database", "SQL", "NoSQL"],
            ["Security", "Cybersecurity", "Encryption"]
        ]
        
        let timeAgoOptions = ["2m ago", "5m ago", "12m ago", "1h ago", "3h ago", "6h ago", "1d ago", "2d ago"]
        
        let user = mockUsers.randomElement() ?? mockUsers[0]
        let description = descriptions.randomElement() ?? descriptions[0]
        let itemTags = tags.randomElement() ?? tags[0]
        let timeAgo = timeAgoOptions.randomElement() ?? timeAgoOptions[0]
        
        return FeedItem(
            user: user,
            mediaURL: "https://picsum.photos/400/800?random=\(Int.random(in: 1...1000))",
            description: description,
            tags: itemTags,
            timeAgo: timeAgo,
            likesCount: Int.random(in: 100...50000),
            commentsCount: Int.random(in: 10...500),
            sharesCount: Int.random(in: 5...200),
            type: FeedItem.FeedItemType.allCases.randomElement() ?? .shortVideo
        )
    }
}

// MARK: - Main HomeFeedView
struct HomeFeedView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var feedManager = FeedManager()
    @State private var particles: [ParticleEffect] = []
    @State private var showingStoryDrawer = false
    
    // Analytics tracking
    @State private var feedViewStartTime: Date?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Cosmic Background
                CosmicBackground()

                // Floating Particles (optimized)
                ForEach(particles.indices, id: \ .self) { index in
                    ParticleView(particle: particles[index])
                }

                // Main Vertical Paging Feed (Reels/TikTok style)
                TabView(selection: .constant(0)) {
                    ForEach(feedManager.feedContent.indices, id: \ .self) { index in
                        OptimizedFeedContentView(
                            content: feedManager.feedContent[index],
                            geometry: geometry
                        )
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .tag(index)
                        .onAppear {
                            // Load more content when approaching the end
                            if index == feedManager.feedContent.count - 3 {
                                feedManager.loadMoreContent()
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea(.all, edges: .top)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 100)
                }

                // UI Controls Overlay (Status Bar and Header)
                VStack {
                    HeaderView(showingStoryDrawer: $showingStoryDrawer)
                        .padding(.top, 44)
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.all)
        .onAppear {
            feedViewStartTime = Date()
            generateParticles()
            Task {
                await feedManager.preload()
            }
        }
        .onDisappear {
            feedManager.cleanup()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
            handleMemoryWarning()
        }
        .trackScreenView("Feed")
    }
    
    @MainActor
    private func refreshFeed() async {
        feedManager.loadInitialContent()
    }
    
    private func handleMemoryWarning() {
        // Handle memory warning
        particles.removeAll()
    }
    
    private func generateParticles() {
        particles = (0..<15).map { _ in
            ParticleEffect(
                x: Double.random(in: 0...1),
                y: Double.random(in: 0...1),
                size: Double.random(in: 2...6),
                speed: Double.random(in: 0.5...2.0)
            )
        }
    }
}

// MARK: - Feed Content View
struct FeedContentView: View {
    let content: FeedContentType
    let geometry: GeometryProxy
    
    var body: some View {
        switch content {
        case .video(let item):
            FeedItemView(item: item, geometry: geometry)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Video post by \(item.user.name)")
                .accessibilityHint("Double tap to play video, swipe up or down to navigate between posts")
            
        case .courseSuggestions(let courses):
            HorizontalCourseSuggestions(courses: courses)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Course recommendations section")
                .accessibilityHint("Swipe left and right to explore recommended courses")
            
        case .userSuggestions(let users):
            BusinessCardUserSuggestions(users: users)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Suggested users to follow")
                .accessibilityHint("Swipe to explore user profiles you might be interested in")
        }
    }
}

// MARK: - Horizontal Course Suggestions
struct HorizontalCourseSuggestions: View {
    let courses: [Course]
    
    var body: some View {
        ZStack {
            // Background
            DesignTokens.Colors.primaryBg.ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Header
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("Recommended Courses")
                        .font(DesignTokens.Typography.title1)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Level up your skills")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding(.top, 60)
                
                // Horizontal Course Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.lg) {
                        ForEach(courses) { course in
                            CourseCard(course: course)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                
                Spacer()
                
                // Skip Button
                Button("Continue watching") {
                    // Skip action
                }
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(DesignTokens.Colors.primary)
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Course Card
struct CourseCard: View {
    let course: Course
    
    var body: some View {
        Button(action: {
            // Navigate to course detail
        }) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // Course Image
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.primaryGradient)
                    .frame(width: 280, height: 160)
                    .overlay(
                        VStack {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                                .accessibilityHidden(true)
                            
                            Text(course.title)
                                .font(DesignTokens.Typography.headline)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                        }
                    )
                    .accessibilityLabel("Course preview: \(course.title)")
                    .accessibilityHint("Double tap to start course preview")
                
                // Course Info
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(course.title)
                        .font(DesignTokens.Typography.cardTitle)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("by \(course.instructor)")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(DesignTokens.Colors.warning)
                                .accessibilityHidden(true)
                            Text(String(format: "%.1f", course.rating))
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Rating: \(String(format: "%.1f", course.rating)) stars")
                        
                        Spacer()
                        
                        Text(formatDuration(course.duration))
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .accessibilityLabel("Duration: \(formatDuration(course.duration))")
                    }
                }
                .frame(width: 280)
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                    )
            )
        }
    }
}

// MARK: - Business Card User Suggestions
struct BusinessCardUserSuggestions: View {
    let users: [SuggestedUser]
    
    var body: some View {
        ZStack {
            // Background
            DesignTokens.Colors.primaryBg.ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Header
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("People You Might Know")
                        .font(DesignTokens.Typography.title1)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("Connect with fellow learners")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding(.top, 60)
                
                // User Business Cards
                VStack(spacing: DesignTokens.Spacing.lg) {
                    ForEach(users) { user in
                        UserBusinessCard(user: user)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
                
                Spacer()
                
                // Skip Button
                Button("Continue watching") {
                    // Skip action
                }
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(DesignTokens.Colors.primary)
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - User Business Card
struct UserBusinessCard: View {
    let user: SuggestedUser
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // Avatar
            Circle()
                .fill(DesignTokens.Colors.primaryGradient)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(user.name.prefix(1)))
                        .font(DesignTokens.Typography.title2)
                        .foregroundColor(.white)
                )
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.name)
                        .font(DesignTokens.Typography.headline)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    if user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(DesignTokens.Colors.primary)
                            .font(.system(size: 14))
                    }
                }
                
                Text("@\(user.username)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Text(user.specialty)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.primary)
                
                if user.mutualConnections > 0 {
                    Text("\(user.mutualConnections) mutual connections")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            // Follow Button
            Button("Follow") {
                // Follow action
            }
            .font(DesignTokens.Typography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.primaryGradient)
            )
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0) { isPressing in
            withAnimation(DesignTokens.Animations.quick) {
                isPressed = isPressing
            }
        } perform: {
            // Card tap action
        }
    }
}

// MARK: - Loading Indicator
struct LoadingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(DesignTokens.Colors.primary)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - UI Components

struct CosmicBackground: View {
    @State private var animateGradient = false
    
    var body: some View {
        DesignTokens.Colors.cosmicGradient
            .scaleEffect(animateGradient ? 1.2 : 1.0)
            .animation(DesignTokens.Animations.cosmic, value: animateGradient)
            .onAppear {
                animateGradient = true
            }
    }
}

struct ParticleEffect: Identifiable {
    let id = UUID()
    let x: Double
    let y: Double
    let size: Double
    let speed: Double
}

struct ParticleView: View {
    let particle: ParticleEffect
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        DesignTokens.Colors.primary.opacity(0.6),
                        DesignTokens.Colors.secondary.opacity(0.3),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: particle.size
                )
            )
            .frame(width: particle.size, height: particle.size)
            .opacity(opacity)
            .position(position)
            .onAppear {
                startFloating()
            }
    }
    
    private func startFloating() {
        position = CGPoint(
            x: UIScreen.main.bounds.width * particle.x,
            y: UIScreen.main.bounds.height + 20
        )
        
        withAnimation(DesignTokens.Animations.float) {
            opacity = 1
            position.y = -20
            position.x += Double.random(in: -50...50)
        }
    }
}

struct FeedItemView: View {
    let item: FeedItem
    let geometry: GeometryProxy
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showComments = false
    @State private var showProfile = false
    
    var body: some View {
        ZStack {
            // Video/Image Content with proper aspect ratio
            AsyncImage(url: URL(string: item.mediaURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center
                    )
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(DesignTokens.Colors.tertiaryBg)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height
                    )
                    .overlay(
                        VStack(spacing: DesignTokens.Spacing.md) {
                            ProgressView()
                                .tint(DesignTokens.Colors.primary)
                                .scaleEffect(1.2)
                            
                            Text("Loading...")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    )
            }
            
            // Improved Gradient Overlay for better content visibility
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content Overlay
            VStack {
                Spacer()
                
                HStack(alignment: .bottom) {
                    // Left Content
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        // User Info
                        Button(action: { showProfile = true }) {
                            HStack {
                                AsyncImage(url: URL(string: item.user.avatarURL)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle()
                                        .fill(DesignTokens.Colors.primaryGradient)
                                        .overlay(
                                            Text(item.user.name.prefix(1))
                                                .font(DesignTokens.Typography.headline)
                                                .foregroundColor(.white)
                                        )
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 2)
                                )
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("@\(item.user.username)")
                                        .font(DesignTokens.Typography.headline)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    
                                    Text(item.timeAgo)
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Description
                        Text(item.description)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                            .lineLimit(3)
                        
                        // Tags
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(item.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.primary)
                                        .padding(.horizontal, DesignTokens.Spacing.sm)
                                        .padding(.vertical, DesignTokens.Spacing.xs)
                                        .background(
                                            Capsule()
                                                .fill(DesignTokens.Colors.glassBg)
                                                .overlay(
                                                    Capsule()
                                                        .strokeBorder(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                            .padding(.horizontal, DesignTokens.Spacing.md)
                        }
                    }
                    
                    // Right Side Actions
                    VStack(spacing: DesignTokens.Spacing.md) {
                        // Like Button
                        ActionButton(
                            icon: isLiked ? "heart.fill" : "heart",
                            count: item.likesCount,
                            color: isLiked ? DesignTokens.Colors.error : DesignTokens.Colors.textPrimary
                        ) {
                            withAnimation(DesignTokens.Animations.bouncy) {
                                isLiked.toggle()
                            }
                        }
                        
                        // Comment Button
                        ActionButton(
                            icon: "message",
                            count: item.commentsCount,
                            color: DesignTokens.Colors.textPrimary
                        ) {
                            showComments = true
                        }
                        
                        // Share Button
                        ActionButton(
                            icon: "arrowshape.turn.up.right",
                            count: item.sharesCount,
                            color: DesignTokens.Colors.textPrimary
                        ) {
                            // Share action
                        }
                        
                        // Bookmark Button
                        ActionButton(
                            icon: isBookmarked ? "bookmark.fill" : "bookmark",
                            count: nil,
                            color: isBookmarked ? DesignTokens.Colors.warning : DesignTokens.Colors.textPrimary
                        ) {
                            withAnimation(DesignTokens.Animations.bouncy) {
                                isBookmarked.toggle()
                            }
                        }
                    }
                    .padding(.trailing, DesignTokens.Spacing.sm)
                    .opacity(0.85)
                }
                .padding(DesignTokens.Spacing.lg)
                .padding(.bottom, 60) // Lower description & icons closer to bottom nav
            }
        }
        .sheet(isPresented: $showComments) {
            CommentsView(item: item)
        }
        .sheet(isPresented: $showProfile) {
            UserProfileSheet(user: item.user)
        }
    }
}

struct ActionButton: View {
    let icon: String
    let count: Int?
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.xs) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.Colors.glassBg.opacity(0.6))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .strokeBorder(DesignTokens.Colors.glassBorder.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(
                            color: color.opacity(isPressed ? 0.4 : 0.1),
                            radius: isPressed ? 12 : 6,
                            x: 0,
                            y: 0
                        )
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color.opacity(0.9))
                }
            }
            .scaleEffect(isPressed ? 1.1 : 1.0)
            .onLongPressGesture(minimumDuration: 0) { isPressing in
                withAnimation(DesignTokens.Animations.quick) {
                    isPressed = isPressing
                }
            } perform: {
                action()
            }
            
            if let count = count, count > 0 {
                Text(formatCount(count))
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary.opacity(0.8))
            }
        }
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
}

struct FuturisticStatusBar: View {
    @State private var currentTime = Date()
    
    var body: some View {
        HStack {
            Text(DateFormatter.timeFormatter.string(from: currentTime))
                .font(DesignTokens.Typography.caption)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: DesignTokens.Spacing.xs) {
                // Signal strength
                HStack(spacing: 2) {
                    ForEach(0..<4) { index in
                        Rectangle()
                            .fill(DesignTokens.Colors.success)
                            .frame(width: 3, height: CGFloat(3 + index * 2))
                    }
                }
                
                // Battery
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(DesignTokens.Colors.success)
                        .frame(width: 18, height: 10)
                        .overlay(
                            Rectangle()
                                .fill(DesignTokens.Colors.primaryBg)
                                .frame(width: 14, height: 6)
                        )
                        .overlay(
                            Rectangle()
                                .fill(DesignTokens.Colors.success)
                                .frame(width: 2, height: 4)
                                .offset(x: 11)
                        )
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.top, DesignTokens.Spacing.sm)
        .background(
            Rectangle()
                .fill(DesignTokens.Colors.glassBg)
                .blur(radius: 20)
        )
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
    }
}

struct CourseSuggestionCard: View {
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("🚀 Level Up")
                        .font(DesignTokens.Typography.title3)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("New course recommendation")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Button("Skip") {
                    // Handle skip
                }
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            // Course Card
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Advanced SwiftUI Animations")
                    .font(DesignTokens.Typography.headline)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Master complex animations and transitions")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Text("4.9 ⭐")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.success)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.success.opacity(0.1))
                        )
                    
                    Text("2h 30m")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .padding(.horizontal, DesignTokens.Spacing.sm)
                        .padding(.vertical, DesignTokens.Spacing.xs)
                        .background(
                            Capsule()
                                .fill(DesignTokens.Colors.glassBg)
                        )
                    
                    Spacer()
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .strokeBorder(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Action Button
            Button("Start Learning") {
                // Handle course enrollment
            }
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(DesignTokens.Colors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .scaleEffect(animate ? 1.0 : 0.8)
        .opacity(animate ? 1.0 : 0.0)
        .onAppear {
            withAnimation(DesignTokens.Animations.bouncy) {
                animate = true
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
}

struct UserSuggestionCard: View {
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("👋 Connect & Learn")
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Follow creators you might like")
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            // Suggested Users
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.md) {
                ForEach(0..<3) { index in
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        Circle()
                            .fill(DesignTokens.Colors.primaryGradient)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text("U\(index + 1)")
                                    .font(DesignTokens.Typography.headline)
                                    .foregroundColor(.white)
                            )
                        
                        Text("@user\(index + 1)")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                    }
                }
            }
            
            Button("Follow All") {
                // Handle follow all
            }
            .font(DesignTokens.Typography.buttonLabel)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(DesignTokens.Colors.primaryGradient)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.xl)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .scaleEffect(animate ? 1.0 : 0.8)
        .opacity(animate ? 1.0 : 0.0)
        .onAppear {
            withAnimation(DesignTokens.Animations.bouncy) {
                animate = true
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }
}



// MARK: - Supporting Views
// (StoryCircle and StoryViewer moved to SpecializedViews.swift for shared use)
struct CommentsView: View {
    let item: FeedItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Comments for \(item.user.username)")
                    .font(DesignTokens.Typography.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("Comments feature coming soon!")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
            }
            .padding()
            .background(DesignTokens.Colors.primaryBg)
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
    }
}

struct UserProfileSheet: View {
    let user: FeedUser
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Profile Header
                VStack(spacing: DesignTokens.Spacing.md) {
                    AsyncImage(url: URL(string: user.avatarURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(DesignTokens.Colors.primaryGradient)
                            .overlay(
                                Text(user.name.prefix(1))
                                    .font(DesignTokens.Typography.title1)
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(spacing: DesignTokens.Spacing.xs) {
                        HStack {
                            Text(user.name)
                                .font(DesignTokens.Typography.title2)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            if user.isVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(DesignTokens.Colors.primary)
                            }
                        }
                        
                        Text("@\(user.username)")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Text("\(UserProfileSheet.formatFollowerCount(user.followerCount)) followers")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                // Action Buttons
                HStack(spacing: DesignTokens.Spacing.md) {
                    Button("Follow") {
                        // Handle follow
                    }
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(DesignTokens.Colors.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
                    
                    Button("Message") {
                        // Handle message
                    }
                    .font(DesignTokens.Typography.buttonLabel)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .strokeBorder(DesignTokens.Colors.primary, lineWidth: 2)
                    )
                }
                
                Spacer()
            }
            .padding()
            .background(DesignTokens.Colors.primaryBg)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
    }
    
    static func formatFollowerCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
}

struct ShareView: View {
    let item: FeedItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Share \(item.user.username)'s post")
                    .font(DesignTokens.Typography.title2)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Text("Sharing options coming soon!")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
            }
            .padding()
            .background(DesignTokens.Colors.primaryBg)
            .navigationTitle("Share")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Supporting Extensions
extension DateFormatter {
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Utility Components
struct LazyRenderView<Content: View>: View {
    let content: () -> Content
    @State private var shouldRender = false
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        Group {
            if shouldRender {
                content()
            } else {
                Color.clear
                    .onAppear {
                        DispatchQueue.main.async {
                            shouldRender = true
                        }
                    }
            }
        }
    }
}

struct AccessibleText: View {
    let text: String
    let font: Font
    let color: Color
    
    init(_ text: String, font: Font, color: Color) {
        self.text = text
        self.font = font
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .accessibilityElement(children: .combine)
    }
}

struct AccessibleButton: View {
    let title: String
    let style: ButtonStyle
    let accessibilityID: String
    let hint: String
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, tertiary
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.buttonLabel)
                .foregroundColor(foregroundColor)
                .padding()
                .frame(maxWidth: .infinity)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.button))
        }
        .accessibilityIdentifier(accessibilityID)
        .accessibilityHint(hint)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return DesignTokens.Colors.primary
        case .tertiary:
            return DesignTokens.Colors.textSecondary
        }
    }
    
    private var backgroundColor: AnyShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(DesignTokens.Colors.primaryGradient)
        case .secondary:
            return AnyShapeStyle(DesignTokens.Colors.glassBg)
        case .tertiary:
            return AnyShapeStyle(Color.clear)
        }
    }
}

struct AccessibleCard<Content: View>: View {
    let title: String
    let description: String
    let accessibilityID: String
    let action: () -> Void
    let content: () -> Content
    
    init(title: String, description: String, accessibilityID: String, action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.accessibilityID = accessibilityID
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: action) {
            content()
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(description)
        .accessibilityIdentifier(accessibilityID)
    }
}

// MARK: - Preview
#Preview {
    HomeFeedView()
        .environmentObject(AppState())
}

// MARK: - Optimized Feed Content View
struct OptimizedFeedContentView: View {
    let content: FeedContentType
    let geometry: GeometryProxy
    
    var body: some View {
        switch content {
        case .video(let item):
            OptimizedFeedItemView(item: item, geometry: geometry)
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .center
                )
                .clipped()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Video post by \(item.user.name)")
                .accessibilityHint("Double tap to play video, swipe up or down to navigate between posts")
            
        case .courseSuggestions(let courses):
            HorizontalCourseSuggestions(courses: courses)
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .center
                )
                .clipped()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Course recommendations section")
                .accessibilityHint("Swipe left and right to explore recommended courses")
            
        case .userSuggestions(let users):
            BusinessCardUserSuggestions(users: users)
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .center
                )
                .clipped()
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Suggested users to follow")
                .accessibilityHint("Swipe to explore user profiles you might be interested in")
        }
    }
}

// MARK: - Optimized Feed Item View
struct OptimizedFeedItemView: View {
    let item: FeedItem
    let geometry: GeometryProxy
    
    @State private var isVisible = false
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showComments = false
    @State private var showProfile = false
    
    var body: some View {
        ZStack {
            // Background Media with Proper Alignment
            AsyncImage(url: URL(string: item.mediaURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center
                    )
                    .clipped()
            } placeholder: {
                // Optimized placeholder
                Rectangle()
                    .fill(DesignTokens.Colors.glassBg)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center
                    )
                    .overlay(
                        VStack(spacing: DesignTokens.Spacing.md) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                                .scaleEffect(1.2)
                            
                            Text("Loading...")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                    )
            }
            
            // Gradient Overlay
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Content Overlay (only render when visible)
            if isVisible {
                VStack {
                    Spacer()
                        
                    // User Info and Actions
                    HStack(alignment: .bottom) {
                        // Left Content
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                            // User Info
                            Button(action: { showProfile = true }) {
                                HStack {
                                    AsyncImage(url: URL(string: item.user.avatarURL)) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Circle()
                                            .fill(DesignTokens.Colors.primaryGradient)
                                            .overlay(
                                                Text(item.user.name.prefix(1))
                                                    .font(DesignTokens.Typography.headline)
                                                    .foregroundColor(.white)
                                            )
                                    }
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 2)
                                    )
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("@\(item.user.username)")
                                            .font(DesignTokens.Typography.headline)
                                            .foregroundColor(DesignTokens.Colors.textPrimary)
                                        
                                        Text(item.timeAgo)
                                            .font(DesignTokens.Typography.caption)
                                            .foregroundColor(DesignTokens.Colors.textSecondary)
                                    }
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Description
                            Text(item.description)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .lineLimit(3)
                            
                            // Tags
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(item.tags, id: \.self) { tag in
                                        Text("#\(tag)")
                                            .font(DesignTokens.Typography.caption)
                                            .foregroundColor(DesignTokens.Colors.primary)
                                            .padding(.horizontal, DesignTokens.Spacing.sm)
                                            .padding(.vertical, DesignTokens.Spacing.xs)
                                            .background(
                                                Capsule()
                                                    .fill(DesignTokens.Colors.glassBg)
                                                    .overlay(
                                                        Capsule()
                                                            .strokeBorder(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
                                                    )
                                            )
                                    }
                                }
                                .padding(.horizontal, DesignTokens.Spacing.md)
                            }
                        }
                        
                        // Right Side Actions
                        VStack(spacing: DesignTokens.Spacing.md) {
                            // Like Button
                            ActionButton(
                                icon: isLiked ? "heart.fill" : "heart",
                                count: item.likesCount,
                                color: isLiked ? DesignTokens.Colors.error : DesignTokens.Colors.textPrimary
                            ) {
                                withAnimation(DesignTokens.Animations.bouncy) {
                                    isLiked.toggle()
                                }
                            }
                            
                            // Comment Button
                            ActionButton(
                                icon: "message",
                                count: item.commentsCount,
                                color: DesignTokens.Colors.textPrimary
                            ) {
                                showComments = true
                            }
                            
                            // Share Button
                            ActionButton(
                                icon: "arrowshape.turn.up.right",
                                count: item.sharesCount,
                                color: DesignTokens.Colors.textPrimary
                            ) {
                                // Share action
                            }
                            
                            // Bookmark Button
                            ActionButton(
                                icon: isBookmarked ? "bookmark.fill" : "bookmark",
                                count: nil,
                                color: isBookmarked ? DesignTokens.Colors.warning : DesignTokens.Colors.textPrimary
                            ) {
                                withAnimation(DesignTokens.Animations.bouncy) {
                                    isBookmarked.toggle()
                                }
                            }
                        }
                        .padding(.trailing, DesignTokens.Spacing.sm)
                        .opacity(0.85)
                    }
                    .padding(DesignTokens.Spacing.lg)
                    .padding(.bottom, 140) // Extra bottom padding to clear tab bar
                }
            }
        }
        .onAppear {
            isVisible = true
        }
        .onDisappear {
            isVisible = false
        }
        .sheet(isPresented: $showComments) {
            CommentsView(item: item)
        }
        .sheet(isPresented: $showProfile) {
            UserProfileSheet(user: item.user)
        }
    }
}

// MARK: - Optimized Action Button
struct OptimizedActionButton: View {
    let icon: String
    let count: Int
    let accessibilityLabel: String
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Handle action with haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }) {
            VStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)
                
                if count > 0 {
                    Text(formatCount(count))
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(.white)
                }
            }
        }
        .onLongPressGesture(minimumDuration: 0) {
            isPressed = true
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(count > 0 ? "\(count)" : "")
    }
    
    private func formatCount(_ count: Int) -> String {
        if count >= 1000000 {
            return String(format: "%.1fM", Double(count) / 1000000)
        } else if count >= 1000 {
            return String(format: "%.1fK", Double(count) / 1000)
        } else {
            return "\(count)"
        }
    }
}

// MARK: - Optimized Course Suggestions
struct OptimizedHorizontalCourseSuggestions: View {
    let courses: [Course]
    
    var body: some View {
        ZStack {
            // Background
            DesignTokens.Colors.primaryBg.ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Header
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("Recommended Courses")
                        .font(DesignTokens.Typography.title1)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Level up your skills")
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding(.top, 60)
                
                // Horizontal Course Cards with Lazy Loading
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: DesignTokens.Spacing.lg) {
                        ForEach(courses) { course in
                            OptimizedCourseCard(course: course)
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                }
                
                Spacer()
                
                // Skip Button
                AccessibleButton(
                    title: "Continue watching",
                    style: .tertiary,
                    accessibilityID: "continue_watching_button",
                    hint: "Skip course recommendations and continue browsing",
                    action: {
                        // Skip action
                    }
                )
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Optimized Course Card
struct OptimizedCourseCard: View {
    let course: Course
    
    @State private var isVisible = false
    
    var body: some View {
        Button(action: {
            // Navigate to course detail
        }) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    // Course Image with Lazy Loading
                    AsyncImage(url: URL(string: course.thumbnailURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .fill(DesignTokens.Colors.primaryGradient)
                            .frame(width: 280, height: 160)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    }
                    .frame(width: 280, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
                    
                    // Course Info (lazy loaded)
                    if isVisible {
                        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                            Text(course.title)
                                .font(DesignTokens.Typography.cardTitle)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                                .lineLimit(2)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text("by \(course.instructor)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(DesignTokens.Colors.warning)
                                        .accessibilityHidden(true)
                                    Text(String(format: "%.1f", course.rating))
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.textSecondary)
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("Rating: \(String(format: "%.1f", course.rating)) stars")
                                
                                Spacer()
                                
                                Text(formatDuration(course.duration))
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.textSecondary)
                                    .accessibilityLabel("Duration: \(formatDuration(course.duration))")
                            }
                        }
                        .frame(width: 280)
                    }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                    )
            )
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Optimized User Suggestions
struct OptimizedBusinessCardUserSuggestions: View {
    let users: [SuggestedUser]
    
    var body: some View {
        ZStack {
            // Background
            DesignTokens.Colors.primaryBg.ignoresSafeArea()
            
            LazyRenderView {
                VStack(spacing: DesignTokens.Spacing.xl) {
                    // Header
                    VStack(spacing: DesignTokens.Spacing.md) {
                        AccessibleText(
                            "People You Might Know",
                            font: DesignTokens.Typography.title1,
                            color: DesignTokens.Colors.textPrimary
                        )
                        .accessibilityAddTraits(.isHeader)
                        
                        AccessibleText(
                            "Connect with fellow learners",
                            font: DesignTokens.Typography.body,
                            color: DesignTokens.Colors.textSecondary
                        )
                    }
                    .padding(.top, 60)
                    
                    // User Cards with Lazy Loading
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: DesignTokens.Spacing.lg) {
                            ForEach(users) { user in
                                OptimizedUserCard(user: user)
                            }
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                    }
                    
                    Spacer()
                    
                    // Skip Button
                    AccessibleButton(
                        title: "Maybe later",
                        style: .tertiary,
                        accessibilityID: "skip_user_suggestions_button",
                        hint: "Skip user suggestions and continue browsing",
                        action: {
                            // Skip action
                        }
                    )
                    .padding(.bottom, 100)
                }
            }
        }
    }
}

// MARK: - Optimized User Card
struct OptimizedUserCard: View {
    let user: SuggestedUser
    
    @State private var isVisible = false
    
    var body: some View {
        LazyRenderView {
            AccessibleCard(
                title: user.name,
                description: "Suggested user: \(user.name), \(user.followerCount) followers",
                accessibilityID: "user_card_\(user.id)",
                action: {
                    // Navigate to user profile
                }
            ) {
                VStack(spacing: DesignTokens.Spacing.md) {
                    // User Avatar with Lazy Loading
                    AsyncImage(url: URL(string: user.avatarURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(DesignTokens.Colors.glassBg)
                            .frame(width: 80, height: 80)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                            )
                    }
                    .clipShape(Circle())
                    .frame(width: 80, height: 80)
                    
                    // User Info (lazy loaded)
                    if isVisible {
                        VStack(spacing: DesignTokens.Spacing.sm) {
                            HStack {
                                AccessibleText(
                                    user.name,
                                    font: DesignTokens.Typography.headline,
                                    color: DesignTokens.Colors.textPrimary
                                )
                                
                                if user.isVerified {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(DesignTokens.Colors.primary)
                                        .font(.caption)
                                        .accessibilityLabel("Verified user")
                                }
                            }
                            
                            AccessibleText(
                                user.specialty,
                                font: DesignTokens.Typography.caption,
                                color: DesignTokens.Colors.textSecondary
                            )
                            
                            AccessibleText(
                                "\(UserProfileSheet.formatFollowerCount(user.followerCount)) followers",
                                font: DesignTokens.Typography.caption,
                                color: DesignTokens.Colors.textSecondary
                            )
                            
                            // Follow Button
                            AccessibleButton(
                                title: "Follow",
                                style: .primary,
                                accessibilityID: "follow_user_\(user.id)",
                                hint: "Follow \(user.name)",
                                action: {
                                    // Follow user action
                                }
                            )
                        }
                    }
                }
                .frame(width: 200)
                .padding(DesignTokens.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                        .fill(DesignTokens.Colors.glassBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.card)
                                .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                        )
                )
            }
        }
        .onAppear {
            isVisible = true
        }
    }
}
