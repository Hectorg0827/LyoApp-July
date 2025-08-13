import SwiftUI

struct InstagramStyleDiscoverView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var voiceActivationService: VoiceActivationService
    @State private var showingStoryDrawer = false
    @StateObject private var feedViewModel = InstagramFeedViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI integration
            HeaderView()
            
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
        
        // TODO: Implement real data loading from UserDataManager
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.posts = [] // InstagramPost.samplePosts - using empty array until real data integration
            self.isLoading = false
        }
    }
    
    func refreshFeed() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        // TODO: Replace with real data from UserDataManager
        posts = [] // InstagramPost.samplePosts.shuffled() - using empty array
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
    
    // MARK: - Sample Data Removed
    // All sample posts moved to UserDataManager for real data management
    // static let samplePosts = [] // Use UserDataManager.shared.getUserPosts()
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
