import SwiftUI
import Combine

// MARK: - Enhanced Learning Hub View
/// Modern Netflix-style Learning Hub that replaces the basic learn tab
struct LearningHubView: View {
    
    // MARK: - Environment and State
    @EnvironmentObject var appState: AppState
    @StateObject private var userDataManager = UserDataManager.shared
    @StateObject private var searchViewModel = LearningSearchViewModel()
    
    private let apiService = LearningAPIService.shared
    
    // MARK: - State Properties
    @State private var selectedCategory: LearningCategory = .all
    @State private var viewMode: ViewMode = .grid
    @State private var isSearchActive = false
    @State private var showingFilters = false
    @State private var showingProfile = false
    
    // AI Conversation State
    @State private var showAIConversation = false
    @State private var courseToNavigate: Course? = nil
    @State private var navigateToCourseDetail = false
    
    // MARK: - Content State
    @State private var featuredContent: [LearningResource] = []
    @State private var trendingContent: [LearningResource] = []
    @State private var recommendedContent: [LearningResource] = []
    @State private var recentContent: [LearningResource] = []
    
    // MARK: - Loading States
    @State private var isLoadingFeatured = true
    @State private var isLoadingTrending = true
    @State private var isLoadingRecommended = true
    
    // MARK: - Error Handling
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Supporting Types
    enum LearningCategory: String, CaseIterable {
        case all = "All"
        case programming = "Programming"
        case design = "Design"
        case business = "Business"
        case datascience = "Data Science"
        case aiml = "AI/ML"
        case mobile = "Mobile Dev"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .programming: return "chevron.left.forwardslash.chevron.right"
            case .design: return "paintbrush"
            case .business: return "briefcase"
            case .datascience: return "chart.bar"
            case .aiml: return "brain.head.profile"
            case .mobile: return "iphone"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return .blue
            case .programming: return .green
            case .design: return .purple
            case .business: return .orange
            case .datascience: return .red
            case .aiml: return .pink
            case .mobile: return .cyan
            }
        }
    }
    
    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        case card = "Cards"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            case .card: return "rectangle.stack"
            }
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.1, blue: 0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isSearchActive {
                    // Search Interface
                    searchInterfaceView
                } else {
                    // Main Content Interface
                    mainContentView
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            loadInitialContent()
            trackScreenView()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showAIConversation) {
            NavigationView {
                AIConversationView(navigateToCourse: $courseToNavigate)
            }
        }
        .onChange(of: courseToNavigate) { newCourse in
            if newCourse != nil {
                showAIConversation = false
                navigateToCourseDetail = true
            }
        }
        .navigationDestination(isPresented: $navigateToCourseDetail) {
            if let course = courseToNavigate {
                CourseDetailView(course: course)
            }
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Header with search and profile
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                
                // Category Filter
                categoryFilterView
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Featured Content Hero Section
                if !featuredContent.isEmpty {
                    featuredContentSection
                        .padding(.top, 30)
                }
                
                // Content Sections
                contentSectionsView
                    .padding(.top, 30)
                
                // Bottom spacing for tab bar
                Spacer()
                    .frame(height: 100)
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            // Logo and Title
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Learning Hub")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Powered by AI")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
            }
            
            Spacer()
            
            // Search and Profile Buttons
            HStack(spacing: 16) {
                // AI Chat Button
                Button(action: { 
                    showAIConversation = true
                }) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title3)
                        .foregroundColor(.cyan)
                        .frame(width: 44, height: 44)
                        .background(Color.cyan.opacity(0.2))
                        .clipShape(Circle())
                }
                
                // Search Button
                Button(action: { 
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isSearchActive = true
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // View Mode Toggle
                Button(action: toggleViewMode) {
                    Image(systemName: viewMode.icon)
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Profile Button
                Button(action: { showingProfile = true }) {
                    Circle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [.cyan, .blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text("L")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        )
                }
            }
        }
    }
    
    // MARK: - Category Filter View
    private var categoryFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(LearningCategory.allCases, id: \.self) { category in
                    CategoryFilterChip(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                            filterContentByCategory()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Featured Content Section
    private var featuredContentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Featured")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full featured content
                }
                .font(.subheadline)
                .foregroundColor(.cyan)
            }
            .padding(.horizontal, 20)
            
            if isLoadingFeatured {
                FeaturedContentSkeleton()
            } else {
                FeaturedContentCarousel(content: featuredContent)
            }
        }
    }
    
    // MARK: - Content Sections View
    private var contentSectionsView: some View {
        VStack(spacing: 40) {
            // Trending Section
            ContentSection(
                title: "Trending Now",
                subtitle: "Popular this week",
                content: trendingContent,
                isLoading: isLoadingTrending,
                viewMode: viewMode
            )
            
            // Recommended Section
            ContentSection(
                title: "Recommended for You",
                subtitle: "Based on your interests",
                content: recommendedContent,
                isLoading: isLoadingRecommended,
                viewMode: viewMode
            )
            
            // Recent Section
            if !recentContent.isEmpty {
                ContentSection(
                    title: "Continue Learning",
                    subtitle: "Pick up where you left off",
                    content: recentContent,
                    isLoading: false,
                    viewMode: viewMode
                )
            }
        }
    }
    
    // MARK: - Search Interface View
    private var searchInterfaceView: some View {
        VStack(spacing: 0) {
            // Search Header
            SearchHeaderView(
                searchText: $searchViewModel.searchText,
                isActive: $isSearchActive,
                onTextChange: searchViewModel.updateSearchText
            )
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Search Content
            if searchViewModel.searchText.isEmpty {
                // Search Suggestions and Recent
                SearchSuggestionsView(
                    recentSearches: searchViewModel.recentSearches,
                    popularTopics: ["SwiftUI", "AI/ML", "Design Systems", "Concurrency"],
                    suggestions: ["SwiftUI Animation", "Combine Framework", "MVVM Architecture", "Async/Await in Swift"],
                    onSearchTap: { query in
                        searchViewModel.performImmediateSearch(query)
                    },
                    onRemoveRecent: { term in
                        // Remove term from search history
                        // TODO: Implement removeFromHistory method in searchViewModel
                    }
                )
            } else {
                // Search Results
                SearchResultsView(
                    results: searchViewModel.searchResults,
                    isSearching: searchViewModel.isSearching,
                    query: searchViewModel.searchText,
                    viewMode: viewMode
                )
            }
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
    }
    
    // MARK: - Methods
    
    private func loadInitialContent() {
        Task {
            await loadFeaturedContent()
            await loadTrendingContent() 
            await loadRecommendedContent()
            await loadRecentContent()
        }
    }
    
    private func loadFeaturedContent() async {
        await MainActor.run {
            isLoadingFeatured = true
        }
        
        do {
            // Fetch featured content from the API
            let resources = try await apiService.fetchResources(for: "featured", limit: 5)
            await MainActor.run {
                self.featuredContent = resources
                self.isLoadingFeatured = false
                print("✅ FEATURED: Loaded \(resources.count) featured resources from API")
            }
        } catch {
            await MainActor.run {
                handleError(error)
                self.isLoadingFeatured = false
            }
        }
    }
    
    private func loadTrendingContent() async {
        await MainActor.run {
            isLoadingTrending = true
        }
        
        do {
            // Fetch trending content from the API
            let topics = try await apiService.getTrendingTopics(limit: 10)
            // For now, we'll just fetch resources for the first topic as an example
            if let firstTopic = topics.first {
                let resources = try await apiService.fetchResources(for: firstTopic, limit: 10)
                await MainActor.run {
                    self.trendingContent = resources
                    self.isLoadingTrending = false
                    print("✅ TRENDING: Loaded \(resources.count) trending resources from API for topic '\(firstTopic)'")
                }
            } else {
                await MainActor.run {
                    self.trendingContent = []
                    self.isLoadingTrending = false
                    print("✅ TRENDING: No trending topics found.")
                }
            }
        } catch {
            await MainActor.run {
                handleError(error)
                self.isLoadingTrending = false
            }
        }
    }
    
    private func loadRecommendedContent() async {
        await MainActor.run {
            isLoadingRecommended = true
        }
        
        do {
            // Fetch recommended content from the API
            // Assuming a user ID is available, otherwise this will fail
            let userId = appState.currentUser?.id.uuidString ?? "default-user"
            let resources = try await apiService.getRecommendations(for: userId, limit: 10)
            await MainActor.run {
                self.recommendedContent = resources
                self.isLoadingRecommended = false
                print("✅ RECOMMENDED: Loaded \(resources.count) recommended resources from API for user '\(userId)'")
            }
        } catch {
            await MainActor.run {
                handleError(error)
                self.isLoadingRecommended = false
            }
        }
    }
    
    private func loadRecentContent() async {
        // This would typically be loaded from a local database or user defaults
        // For now, we'll leave it empty as the API doesn't provide this directly
        await MainActor.run {
            self.recentContent = []
            print("✅ RECENT: Cleared recent content. This should be loaded locally.")
        }
    }
    
    private func filterContentByCategory() {
        // Re-filter content based on selected category
        Task {
            loadInitialContent()
        }
    }
    
    private func toggleViewMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            switch viewMode {
            case .grid:
                viewMode = .list
            case .list:
                viewMode = .card
            case .card:
                viewMode = .grid
            }
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
        print("❌ LEARNING HUB ERROR: \(error.localizedDescription)")
    }
    
    private func trackScreenView() {
        // Analytics tracking
        print("📊 ANALYTICS: Learning Hub viewed")
    }
}

// MARK: - Category Filter Chip
struct CategoryFilterChip: View {
    let category: LearningHubView.LearningCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.subheadline)
                
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            gradient: Gradient(colors: [category.color, category.color.opacity(0.7)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(
                        isSelected ? category.color : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .foregroundColor(isSelected ? .white : .gray)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Helper Functions
private func convertDifficulty(_ courseDifficulty: Course.Difficulty) -> LearningResource.DifficultyLevel {
    switch courseDifficulty {
    case .beginner:
        return .beginner
    case .intermediate:
        return .intermediate
    case .advanced:
        return .advanced
    }
}

// MARK: - Preview
#Preview {
    LearningHubView()
        .environmentObject(AppState())
}
#Preview {
    LearningHubView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}

