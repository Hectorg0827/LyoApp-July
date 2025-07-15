import SwiftUI

// MARK: - Enhanced Discover Manager
@MainActor
class DiscoverManager: ObservableObject {
    @Published var content: [DiscoverContent] = []
    @Published var isLoading = false
    @Published var isSearching = false
    @Published var feedPosts: [Post] = []
    @Published var refreshing = false
    
    func loadContent() {
        // Simulate loading discover content
        content = []
    }
    
    func preload() async {
        isLoading = true
        // Simulate loading
        try? await Task.sleep(nanoseconds: 500_000_000)
        feedPosts = Post.samplePosts.shuffled()
        isLoading = false
    }
    
    func search(query: String) async {
        guard !query.isEmpty else {
            isSearching = false
            return
        }
        
        isSearching = true
        // Simulate search
        try? await Task.sleep(nanoseconds: 300_000_000)
        // Filter content based on query
        content = DiscoverContent.sampleContent.filter { item in
            item.title.localizedCaseInsensitiveContains(query) ||
            item.description.localizedCaseInsensitiveContains(query)
        }
        isSearching = false
    }
    
    func filterByCategory(_ category: String) async {
        isLoading = true
        // Simulate category filtering
        try? await Task.sleep(nanoseconds: 300_000_000)
        if category == "All" {
            content = DiscoverContent.sampleContent
        } else {
            content = DiscoverContent.sampleContent.filter { item in
                item.title.contains(category)
            }
        }
        isLoading = false
    }
    
    func cleanup() {
        content.removeAll()
        feedPosts.removeAll()
    }
}

struct DiscoverContent: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    
    static let sampleContent = [
        DiscoverContent(title: "Programming Basics", description: "Learn the fundamentals of programming"),
        DiscoverContent(title: "Design Principles", description: "Master the art of visual design"),
        DiscoverContent(title: "Technology Trends", description: "Stay updated with latest tech trends"),
        DiscoverContent(title: "Business Strategy", description: "Build successful business strategies"),
        DiscoverContent(title: "Art & Creativity", description: "Explore your creative potential"),
        DiscoverContent(title: "Photography Skills", description: "Capture stunning photographs")
    ]
}

struct DiscoverView: View {
    @StateObject private var discoverManager = DiscoverManager()
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var isSearchFocused = false
    @FocusState private var searchFieldFocused: Bool
    @State private var showingStoryDrawer = false
    
    private let categories = ["All", "Programming", "Design", "Technology", "Business", "Art", "Photography"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HeaderView(showingStoryDrawer: $showingStoryDrawer)
                
                // Search and Categories (Fixed at top)
                VStack(spacing: DesignTokens.Spacing.md) {
                    // Search Section
                    searchSection
                    
                    // Category Filter
                    categorySection
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.primaryBg)
                
                // Content based on search state
                if discoverManager.isSearching {
                    searchLoadingView
                } else if !searchText.isEmpty {
                    searchResultsView
                } else if discoverManager.isLoading {
                    DesignSystem.LoadingStateView(message: "Loading content...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Main Discovery Feed
                    discoveryFeedView
                }
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Discover")
            .navigationBarHidden(true)
            .task {
                await discoverManager.preload()
            }
            .onDisappear {
                discoverManager.cleanup()
            }
            .onChange(of: searchText) { _, newValue in
                Task {
                    await discoverManager.search(query: newValue)
                }
            }
            .onChange(of: selectedCategory) { _, newCategory in
                Task {
                    await discoverManager.filterByCategory(newCategory)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Discover feed")
    }
    
    private var searchSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                TextField("Search posts, users, or topics...", text: $searchText)
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .focused($searchFieldFocused)
                    .onChange(of: searchFieldFocused) { _, focused in
                        withAnimation(DesignTokens.Animations.quick) {
                            isSearchFocused = focused
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchFieldFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            .padding(DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.glassBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .strokeBorder(
                                isSearchFocused ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                                lineWidth: isSearchFocused ? 2 : 1
                            )
                    )
            )
            
            // Search Suggestions
            if isSearchFocused && !searchText.isEmpty {
                searchSuggestions
            }
        }
    }
    
    private var searchSuggestions: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            ForEach(["SwiftUI tutorials", "iOS development", "Design principles", "Programming tips"], id: \.self) { suggestion in
                Button(suggestion) {
                    searchText = suggestion
                    searchFieldFocused = false
                }
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DesignTokens.Spacing.xs)
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
    }
    
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(DesignTokens.Animations.bouncy) {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }
    
    private var searchLoadingView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Searching...")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignTokens.Colors.primaryBg)
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(discoverManager.content) { content in
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text(content.title)
                            .font(DesignTokens.Typography.headline)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text(content.description)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    .padding(DesignTokens.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .fill(DesignTokens.Colors.glassBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                            )
                    )
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.primaryBg)
    }
    
    private var discoveryFeedView: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.lg) {
                ForEach(discoverManager.feedPosts) { post in
                    InstagramStylePostCard(post: post)
                }
                
                if discoverManager.feedPosts.count > 10 {
                    LoadMoreView()
                        .onTapGesture {
                            loadMorePosts()
                        }
                }
            }
            .padding(DesignTokens.Spacing.md)
        }
        .background(DesignTokens.Colors.primaryBg)
        .refreshable {
            await refreshFeed()
        }
    }
    
    private func loadMorePosts() {
        // Simulate loading more posts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let newPosts = Post.samplePosts.shuffled().prefix(3)
            discoverManager.feedPosts.append(contentsOf: newPosts)
        }
    }
    
    private func refreshFeed() async {
        discoverManager.refreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        discoverManager.feedPosts = Post.samplePosts.shuffled()
        discoverManager.refreshing = false
    }
}

// MARK: - Supporting Components

// Simple Section Header Component
struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(title)
                .font(DesignTokens.Typography.title3)
                .foregroundColor(DesignTokens.Colors.label)
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}

// MARK: - Supporting Components

// Instagram-style Post Card
struct InstagramStylePostCard: View {
    let post: Post
    @State private var isLiked = false
    @State private var isBookmarked = false
    @State private var showComments = false
    @State private var showFullCaption = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Post Header
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
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 32, height: 32)
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
                        Text(location.name)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                
                Spacer()
                
                Button {
                    // More options
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
            }
            .padding(DesignTokens.Spacing.md)
            
            // Post Media
            if !post.imageURLs.isEmpty {
                TabView {
                    ForEach(post.imageURLs, id: \.self) { imageURL in
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(DesignTokens.Colors.tertiaryBg)
                                .overlay(
                                    ProgressView()
                                        .tint(DesignTokens.Colors.primary)
                                )
                        }
                    }
                }
                .frame(height: 300)
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            } else {
                // Text-only post with gradient background
                ZStack {
                    DesignTokens.Colors.primaryGradient
                    
                    Text(post.content)
                        .font(DesignTokens.Typography.title3)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(DesignTokens.Spacing.lg)
                }
                .frame(height: 200)
            }
            
            // Action Buttons
            HStack(spacing: DesignTokens.Spacing.md) {
                Button {
                    withAnimation(DesignTokens.Animations.bouncy) {
                        isLiked.toggle()
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.title2)
                        .foregroundColor(isLiked ? DesignTokens.Colors.error : DesignTokens.Colors.textPrimary)
                }
                
                Button {
                    showComments = true
                } label: {
                    Image(systemName: "message")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Button {
                    // Share action
                } label: {
                    Image(systemName: "paperplane")
                        .font(.title2)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                }
                
                Spacer()
                
                Button {
                    withAnimation(DesignTokens.Animations.bouncy) {
                        isBookmarked.toggle()
                    }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.title2)
                        .foregroundColor(isBookmarked ? DesignTokens.Colors.warning : DesignTokens.Colors.textPrimary)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.top, DesignTokens.Spacing.sm)
            
            // Likes Count
            if post.likes > 0 {
                HStack {
                    Text("\(post.likes) likes")
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Spacer()
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.xs)
            }
            
            // Caption and Comments
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
                    .lineLimit(showFullCaption ? nil : 2)
                    
                    if post.content.count > 100 {
                        Button(showFullCaption ? "less" : "more") {
                            withAnimation(DesignTokens.Animations.quick) {
                                showFullCaption.toggle()
                            }
                        }
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.top, DesignTokens.Spacing.xs)
            }
            
            // Comments Preview
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
            
            // Time Ago
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
        .sheet(isPresented: $showComments) {
            // Comments view would go here
            Text("Comments View")
                .navigationTitle("Comments")
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Load More View
struct LoadMoreView: View {
    @State private var isLoading = false
    
    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .tint(DesignTokens.Colors.primary)
                
                Text("Loading more posts...")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            } else {
                Text("Load more posts")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .frame(height: 50)
        .onAppear {
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                isLoading = false
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignTokens.Typography.caption)
                .foregroundColor(isSelected ? .white : DesignTokens.Colors.primary)
                .padding(.horizontal, DesignTokens.Spacing.md)
                .padding(.vertical, DesignTokens.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                        .fill(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                .strokeBorder(DesignTokens.Colors.primary, lineWidth: 1)
                        )
                )
        }
        .animation(DesignTokens.Animations.quick, value: isSelected)
    }
}

// Trending Post Card Component
struct TrendingPostCard: View {
    let post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            AsyncImage(url: URL(string: post.imageURLs.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(DesignTokens.Colors.glassBg)
            }
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(post.content)
                    .font(DesignTokens.Typography.caption)
                    .lineLimit(2)
                    .foregroundColor(DesignTokens.Colors.label)
                
                Text("\(post.likes) likes")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
        }
        .frame(width: 120)
        .cardStyle()
    }
}

// Suggested User Row Component
struct SuggestedUserRow: View {
    let user: User
    @State private var isFollowing = false
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            AsyncImage(url: URL(string: user.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(DesignTokens.Colors.glassBg)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.label)
                
                Text("@\(user.username)")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            Button(isFollowing ? "Following" : "Follow") {
                withAnimation(DesignTokens.Animations.bouncy) {
                    isFollowing.toggle()
                }
            }
            .font(DesignTokens.Typography.caption)
            .foregroundColor(isFollowing ? DesignTokens.Colors.primary : .white)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(isFollowing ? DesignTokens.Colors.glassBg : DesignTokens.Colors.primary)
                    .strokeBorder(DesignTokens.Colors.primary, lineWidth: isFollowing ? 1 : 0)
            )
        }
        .padding(DesignTokens.Spacing.md)
    }
}

// Topic Chip Component
struct TopicChip: View {
    let title: String
    @Binding var isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(DesignTokens.Typography.caption)
            .foregroundColor(isSelected ? .white : DesignTokens.Colors.textSecondary)
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(isSelected ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBg)
                    .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
            )
            .onTapGesture {
                withAnimation(DesignTokens.Animations.bouncy) {
                    isSelected.toggle()
                }
            }
    }
}

#Preview {
    DiscoverView()
        .environmentObject(AppState())
}
