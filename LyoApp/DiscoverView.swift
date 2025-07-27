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
        // TODO: Replace with real data from UserDataManager
        feedPosts = [] // Post.samplePosts.shuffled() - using empty array until real data integration
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
        // TODO: Integrate with UserDataManager.shared.searchDiscoverContent(query)
        content = [] // Empty array until real data integration
        isSearching = false
    }
    
    func filterByCategory(_ category: String) async {
        isLoading = true
        // Simulate category filtering
        try? await Task.sleep(nanoseconds: 300_000_000)
        // TODO: Integrate with UserDataManager.shared.getDiscoverContentByCategory(category)
        content = [] // Empty array until real data integration
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
    
    // MARK: - Sample Data Removed
    // All sample content moved to UserDataManager for real data management
    // static let sampleContent = [] // Use UserDataManager.shared.getDiscoverContent()
}

struct DiscoverView: View {
    @StateObject private var discoverManager = DiscoverManager()
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var isSearchFocused = false
    @FocusState private var searchFieldFocused: Bool
    @State private var showingStoryDrawer = false
    @State private var scrollOffset: CGFloat = 0
    
    private let categories = ["All", "Programming", "Design", "Technology", "Business", "Art", "Photography"]
    
    var body: some View {
        NavigationView {
            ZStack {
                DesignTokens.Colors.primaryBg.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with integrated search
                    ZStack {
                        // Header with drawer button
                        HeaderView()
                        
                        // Inline search bar positioned next to drawer button
                        HStack {
                            // Compact search bar
                            compactSearchBar
                                .opacity(showingStoryDrawer ? 0 : 1)
                                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingStoryDrawer)
                            
                            Spacer()
                        }
                        .padding(.horizontal, DesignTokens.Spacing.lg)
                        .padding(.top, 8)
                    }
                    
                    // Scrollable content
                    GeometryReader { geometry in
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(alignment: .center, spacing: 0) {
                                // Search suggestions and categories (hide on scroll)
                                VStack(spacing: DesignTokens.Spacing.md) {
                                    // AI-powered Search Suggestions
                                    if isSearchFocused && !searchText.isEmpty {
                                        aiSearchSuggestions
                                            .padding(.horizontal, DesignTokens.Spacing.md)
                                    }
                                    
                                    // Category Filter
                                    categorySection
                                }
                                .padding(.top, DesignTokens.Spacing.md)
                                .offset(y: min(0, scrollOffset))
                                .opacity(1.0 - min(1.0, max(0.0, scrollOffset / 100.0)))
                                
                                // Content based on search state
                                if discoverManager.isSearching {
                                    searchLoadingView
                                        .padding(.top, 50)
                                } else if !searchText.isEmpty {
                                    searchResultsView
                                        .padding(.top, 50)
                                } else if discoverManager.isLoading {
                                    DesignSystem.LoadingStateView(message: "Loading content...")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .padding(.top, 50)
                                } else {
                                    // Main Discovery Feed
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
                                    .padding(.top, 20)
                                }
                            }
                            .background(
                                GeometryReader { scrollGeometry in
                                    Color.clear
                                        .preference(key: ScrollOffsetPreferenceKey.self, value: scrollGeometry.frame(in: .named("scroll")).minY)
                                }
                            )
                        }
                        .coordinateSpace(name: "scroll")
                        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                            scrollOffset = value
                        }
                        .refreshable {
                            await refreshFeed()
                        }
                    }
                }
            }
            .navigationTitle("Discover")
            .navigationBarHidden(true)
            .task {
                await discoverManager.preload()
            }
            .onDisappear {
                discoverManager.cleanup()
            }
            .task(id: searchText) {
                await discoverManager.search(query: searchText)
            }
            .task(id: selectedCategory) {
                await discoverManager.filterByCategory(selectedCategory)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Discover feed")
    }
    
    // MARK: - Compact Search Bar
    private var compactSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .font(.system(size: 14, weight: .medium))
            
            TextField("Search...", text: $searchText)
                .font(.system(size: 14, weight: .medium))
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
                        .font(.system(size: 12))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: 200) // Limit width to fit inline
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(DesignTokens.Colors.glassBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isSearchFocused ? DesignTokens.Colors.primary : DesignTokens.Colors.glassBorder,
                            lineWidth: isSearchFocused ? 1.5 : 1
                        )
                )
        )
    }
    
    private var searchSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                TextField("Ask Lyo AI to search for anything...", text: $searchText)
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
            
            // AI-powered Search Suggestions
            if isSearchFocused && !searchText.isEmpty {
                aiSearchSuggestions
            }
        }
    }
    
    private var aiSearchSuggestions: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(DesignTokens.Colors.primary)
                    .font(.caption)
                
                Text("AI Suggestions")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.primary)
                
                Spacer()
            }
            .padding(.bottom, DesignTokens.Spacing.xs)
            
            ForEach(["Learn SwiftUI with AI guidance", "AI-powered iOS development", "Machine learning fundamentals", "Python programming basics"], id: \.self) { suggestion in
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
                        .strokeBorder(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
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
            .background(DesignTokens.Colors.primaryBg)
        }
    }
    
    private func loadMorePosts() {
        // TODO: Implement real data loading from UserDataManager
        // Simulate loading more posts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // let newPosts = Post.samplePosts.shuffled().prefix(3)
            // discoverManager.feedPosts.append(contentsOf: newPosts)
            // Using empty array until real data integration
        }
    }
    
    private func refreshFeed() async {
        discoverManager.refreshing = true
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // TODO: Replace with real data from UserDataManager
        discoverManager.feedPosts = [] // Post.samplePosts.shuffled() - using empty array
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

// MARK: - Instagram Style Discover View
struct InstagramStyleDiscoverView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingStoryDrawer = false
    @StateObject private var feedViewModel = InstagramFeedViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with AI integration
            HeaderView()
            
            // Main Feed Content
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.lg) {
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
                Circle()
                    .fill(DesignTokens.Colors.primaryGradient)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(post.author.fullName.prefix(1))
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.white)
                    )
                
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
            
            // Post content
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
    
    // static let samplePosts: [InstagramPost] = [
    //     // Sample posts moved to UserDataManager for real data management
    // ]
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

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    DiscoverView()
        .environmentObject(AppState())
}
