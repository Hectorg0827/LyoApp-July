import SwiftUI

struct InstagramStyleDiscoverView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var voiceActivationService: VoiceActivationService
    @State private var showingStoryDrawer = false
    @StateObject private var feedViewModel = InstagramFeedViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI integration
            HeaderView(showingStoryDrawer: $showingStoryDrawer)
            
            // Main Feed Content
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.lg) {
                    // Story strip when drawer is open
                    if showingStoryDrawer {
                        StoryStrip()
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    
                    // Feed content
                    ForEach(feedViewModel.posts) { post in
                        InstagramPostCard(post: post)
                    }
                    
                    // Loading indicator
                    if feedViewModel.isLoading {
                        ProgressView()
                            .tint(DesignTokens.Colors.primary)
                            .padding()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .refreshable {
                await feedViewModel.refreshFeed()
            }
        }
        .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
        .onAppear {
            feedViewModel.loadPosts()
        }
    }
}

// MARK: - Instagram Post Card
struct InstagramPostCard: View {
    let post: InstagramPost
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showComments = false
    @State private var showFullCaption = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post header
            HStack {
                AsyncImage(url: URL(string: post.author.profileImageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .overlay(
                            Text(post.author.fullName.prefix(1))
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(post.author.fullName)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        if post.author.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption)
                                .foregroundColor(DesignTokens.Colors.primary)
                        }
                    }
                    
                    if let location = post.location {
                        Text(location)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
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
            
            // Post media
            if !post.imageURLs.isEmpty {
                TabView {
                    ForEach(post.imageURLs, id: \.self) { imageURL in
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(DesignTokens.Colors.secondaryBg)
                                .overlay(
                                    ProgressView()
                                        .tint(DesignTokens.Colors.primary)
                                )
                        }
                    }
                }
                .frame(height: 400)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            } else {
                // Text-only post with gradient background
                ZStack {
                    DesignTokens.Colors.primaryGradient
                    
                    VStack(spacing: DesignTokens.Spacing.sm) {
                        Text(post.content)
                            .font(DesignTokens.Typography.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(DesignTokens.Spacing.lg)
                        
                        // AI-generated insights
                        if let aiInsight = post.aiInsight {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(aiInsight)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(.white.opacity(0.9))
                                    .italic()
                            }
                            .padding(.horizontal, DesignTokens.Spacing.md)
                        }
                    }
                }
                .frame(height: 300)
            }
            
            // Action buttons
            HStack(spacing: DesignTokens.Spacing.md) {
                Button {
                    withAnimation(DesignTokens.Animations.bouncy) {
                        isLiked.toggle()
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isLiked ? DesignTokens.Colors.neonPink : DesignTokens.Colors.textSecondary)
                }
                
                Button {
                    showComments = true
                } label: {
                    Image(systemName: "message")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Button {
                    // Share action
                } label: {
                    Image(systemName: "paperplane")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(DesignTokens.Animations.bouncy) {
                        isBookmarked.toggle()
                    }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundColor(isBookmarked ? DesignTokens.Colors.warning : DesignTokens.Colors.textSecondary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.sm)
            
            // Likes count
            if post.likes > 0 {
                HStack {
                    Text("\(formatCount(post.likes)) likes")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.xs)
            }
            
            // Caption
            if !post.content.isEmpty && !post.imageURLs.isEmpty {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack(alignment: .top) {
                        Text(post.author.fullName)
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textPrimary) +
                        Text(" \(post.content)")
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Spacer()
                    }
                    .lineLimit(showFullCaption ? nil : 3)
                    
                    if post.content.count > 100 {
                        Button(showFullCaption ? "less" : "more") {
                            withAnimation(DesignTokens.Animations.quick) {
                                showFullCaption.toggle()
                            }
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    // Hashtags
                    if !post.hashtags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: DesignTokens.Spacing.xs) {
                                ForEach(post.hashtags, id: \.self) { hashtag in
                                    Text("#\(hashtag)")
                                        .font(DesignTokens.Typography.caption)
                                        .foregroundColor(DesignTokens.Colors.neonBlue)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.xs)
            }
            
            // Comments preview
            if post.comments > 0 {
                Button {
                    showComments = true
                } label: {
                    HStack {
                        Text("View all \(post.comments) comments")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.xs)
            }
            
            // Time ago
            HStack {
                Text(timeAgo(from: post.createdAt))
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.xs)
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
        .sheet(isPresented: $showComments) {
            CommentsView(post: post)
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
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

// MARK: - Instagram Feed View Model
class InstagramFeedViewModel: ObservableObject {
    @Published var posts: [InstagramPost] = []
    @Published var isLoading = false
    
    func loadPosts() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.posts = InstagramPost.samplePosts
            self.isLoading = false
        }
    }
    
    func refreshFeed() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        posts = InstagramPost.samplePosts.shuffled()
        isLoading = false
    }
}

// MARK: - Instagram Post Model
struct InstagramPost: Identifiable {
    let id = UUID()
    let author: User
    let content: String
    let imageURLs: [String]
    let likes: Int
    let comments: Int
    let shares: Int
    let hashtags: [String]
    let location: String?
    let createdAt: Date
    let aiInsight: String?
    
    static let samplePosts: [InstagramPost] = [
        InstagramPost(
            author: User(username: "techguru", email: "tech@example.com", fullName: "Tech Guru", isVerified: true),
            content: "Quick tip that will save you hours of debugging 🔧\nAlways check your edge cases and validate your inputs before processing!",
            imageURLs: [],
            likes: 33700,
            comments: 297,
            shares: 178,
            hashtags: ["AI", "MachineLearning", "Python", "Debugging"],
            location: nil,
            createdAt: Date().addingTimeInterval(-3600),
            aiInsight: "This debugging tip can reduce development time by up to 40%"
        ),
        InstagramPost(
            author: User(username: "designpro", email: "design@example.com", fullName: "Design Pro", isVerified: false),
            content: "New SwiftUI animation tutorial is live! 🎥 Check out these smooth transitions that will make your app feel premium.",
            imageURLs: ["https://picsum.photos/400/400?random=1", "https://picsum.photos/400/400?random=2"],
            likes: 28500,
            comments: 156,
            shares: 89,
            hashtags: ["SwiftUI", "iOS", "Animation", "Tutorial"],
            location: "San Francisco, CA",
            createdAt: Date().addingTimeInterval(-7200),
            aiInsight: nil
        ),
        InstagramPost(
            author: User(username: "codewiz", email: "code@example.com", fullName: "Code Wizard", isVerified: true),
            content: "Building neural networks from scratch might seem daunting, but breaking it down into these simple steps makes it accessible to everyone!",
            imageURLs: ["https://picsum.photos/400/400?random=3"],
            likes: 45200,
            comments: 432,
            shares: 267,
            hashtags: ["NeuralNetwork", "DeepLearning", "AI", "Education"],
            location: "New York, NY",
            createdAt: Date().addingTimeInterval(-10800),
            aiInsight: nil
        ),
        InstagramPost(
            author: User(username: "uxdesigner", email: "ux@example.com", fullName: "UX Designer", isVerified: false),
            content: "The future of design is here! AI-powered tools are revolutionizing how we create user experiences. What's your favorite AI design tool?",
            imageURLs: [],
            likes: 19800,
            comments: 123,
            shares: 67,
            hashtags: ["UX", "AI", "Design", "Future"],
            location: nil,
            createdAt: Date().addingTimeInterval(-14400),
            aiInsight: "AI tools can increase design productivity by 60% while maintaining quality"
        ),
        InstagramPost(
            author: User(username: "dataanalyst", email: "data@example.com", fullName: "Data Analyst", isVerified: true),
            content: "Visualization is key to understanding complex data patterns. Here's how I analyze user behavior using modern tools.",
            imageURLs: ["https://picsum.photos/400/400?random=4", "https://picsum.photos/400/400?random=5", "https://picsum.photos/400/400?random=6"],
            likes: 22100,
            comments: 89,
            shares: 134,
            hashtags: ["DataScience", "Analytics", "Visualization", "Python"],
            location: "Austin, TX",
            createdAt: Date().addingTimeInterval(-18000),
            aiInsight: nil
        )
    ]
}

// MARK: - Comments View
struct CommentsView: View {
    let post: InstagramPost
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(0..<post.comments, id: \.self) { _ in
                        CommentRow()
                    }
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
            Circle()
                .fill(DesignTokens.Colors.primaryGradient)
                .frame(width: 32, height: 32)
                .overlay(
                    Text("U")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                HStack {
                    Text("username")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text("2h")
                        .font(DesignTokens.Typography.caption2)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    
                    Spacer()
                    
                    Button {
                        // Like comment
                    } label: {
                        Image(systemName: "heart")
                            .font(.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Text("This is a sample comment that shows how the comments section would look.")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
            }
        }
    }
}

#Preview {
    InstagramStyleDiscoverView()
        .environmentObject(AppState())
        .environmentObject(VoiceActivationService.shared)
}