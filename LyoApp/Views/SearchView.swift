import SwiftUI

struct SearchView: View {
    @ObservedObject private var apiClient = APIClient.shared
    @State private var searchText = ""
    @State private var selectedScope = SearchScope.all
    @State private var searchResults: SearchResults = SearchResults()
    @State private var isSearching = false
    @State private var recentSearches: [String] = []
    @State private var showingFilters = false
    
    enum SearchScope: String, CaseIterable {
        case all = "All"
        case users = "Users"
        case posts = "Posts"
        case courses = "Courses"
        case content = "Content"
        
        var icon: String {
            switch self {
            case .all: return "magnifyingglass"
            case .users: return "person.2"
            case .posts: return "text.bubble"
            case .courses: return "book"
            case .content: return "doc.text"
            }
        }
    }
    
    struct SearchResults {
        var users: [UserProfile] = []
        var posts: [FeedPost] = []
        var courses: [APILearningResource] = []
        var isEmpty: Bool {
            users.isEmpty && posts.isEmpty && courses.isEmpty
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(
                    text: $searchText,
                    isSearching: $isSearching,
                    onSearchButtonClicked: performSearch,
                    onCancelButtonClicked: clearSearch
                )
                
                // Search Scope Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SearchScope.allCases, id: \.rawValue) { scope in
                            ScopeButton(
                                scope: scope,
                                isSelected: selectedScope == scope,
                                action: { selectedScope = scope }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                Divider()
                
                // Content
                if searchText.isEmpty {
                    EmptySearchView(
                        recentSearches: recentSearches,
                        onRecentSearchTapped: { search in
                            searchText = search
                            performSearch()
                        },
                        onClearRecentSearches: clearRecentSearches
                    )
                } else if isSearching {
                    SearchingView()
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    NoResultsView(searchText: searchText)
                } else {
                    SearchResultsContentView(
                        results: searchResults,
                        selectedScope: selectedScope
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView()
            }
            .onAppear {
                loadRecentSearches()
            }
        }
    }
    
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isSearching = true
        
        // Add to recent searches
        addToRecentSearches(searchText)
        
        Task {
            do {
                // Perform different searches based on scope
                switch selectedScope {
                case .all:
                    await searchAll()
                case .users:
                    await searchUsers()
                case .posts:
                    await searchPosts()
                case .courses, .content:
                    await searchContent()
                }
                
            } catch {
                print("Search failed: \(error)")
            }
            
            isSearching = false
        }
    }
    
    private func searchAll() async {
        async let usersSearch = apiClient.searchUsers(searchText, limit: 5)
        async let contentSearch = apiClient.searchContent(searchText, limit: 10)
        
        do {
            let usersResult = try await usersSearch
            let contentResult = try await contentSearch
            
            searchResults = SearchResults(
                users: usersResult.users,
                posts: contentResult.posts,
                courses: contentResult.resources
            )
        } catch {
            print("❌ Search all failed: \(error)")
            // DO NOT FALLBACK TO MOCK DATA - Show empty results with error
            searchResults = SearchResults()
            // TODO: Show error alert to user
        }
    }
    
    private func searchUsers() async {
        do {
            let result = try await apiClient.searchUsers(searchText, limit: 20)
            searchResults = SearchResults(
                users: result.users,
                posts: [],
                courses: []
            )
        } catch {
            print("❌ User search failed: \(error)")
            // DO NOT FALLBACK TO MOCK DATA - Show empty results
            searchResults = SearchResults()
        }
    }
    
    private func searchPosts() async {
        do {
            let result = try await apiClient.searchContent(searchText, limit: 20)
            searchResults = SearchResults(
                users: [],
                posts: result.posts,
                courses: []
            )
        } catch {
            print("❌ Post search failed: \(error)")
            // DO NOT FALLBACK TO MOCK DATA - Show empty results
            searchResults = SearchResults()
        }
    }
    
    private func searchContent() async {
        do {
            let result = try await apiClient.searchContent(searchText, limit: 20)
            searchResults = SearchResults(
                users: [],
                posts: [],
                courses: result.resources
            )
        } catch {
            print("❌ Content search failed: \(error)")
            // DO NOT FALLBACK TO MOCK DATA - Show empty results
            searchResults = SearchResults()
        }
    }
    
    private func clearSearch() {
        searchText = ""
        searchResults = SearchResults()
        isSearching = false
    }
    
    private func addToRecentSearches(_ search: String) {
        let trimmedSearch = search.trimmingCharacters(in: .whitespacesAndNewlines)
        recentSearches.removeAll { $0 == trimmedSearch }
        recentSearches.insert(trimmedSearch, at: 0)
        
        // Keep only last 10 searches
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recent_searches") ?? []
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recent_searches")
    }
    
    private func clearRecentSearches() {
        recentSearches.removeAll()
        UserDefaults.standard.removeObject(forKey: "recent_searches")
    }
    
    // ✅ MOCK DATA REMOVED - All searches now use real backend APIs
    // SearchView now only displays data from:
    // - apiClient.searchAll()
    // - apiClient.searchUsers()
    // - apiClient.searchContent()
    // NO FALLBACKS TO MOCK DATA
}

// MARK: - Supporting Views

struct SearchBar: UIViewRepresentable {
    @Binding var text: String
    @Binding var isSearching: Bool
    let onSearchButtonClicked: () -> Void
    let onCancelButtonClicked: () -> Void
    
    func makeUIView(context: Context) -> UISearchBar {
        let searchBar = UISearchBar()
        searchBar.delegate = context.coordinator
        searchBar.placeholder = "Search users, posts, courses..."
        searchBar.searchBarStyle = .minimal
        searchBar.showsCancelButton = true
        return searchBar
    }
    
    func updateUIView(_ uiView: UISearchBar, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UISearchBarDelegate {
        let parent: SearchBar
        
        init(_ parent: SearchBar) {
            self.parent = parent
        }
        
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            parent.text = searchText
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            parent.onSearchButtonClicked()
            searchBar.resignFirstResponder()
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            parent.onCancelButtonClicked()
            searchBar.resignFirstResponder()
        }
        
        func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
            parent.isSearching = true
        }
        
        func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
            parent.isSearching = false
        }
    }
}

struct ScopeButton: View {
    let scope: SearchView.SearchScope
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: scope.icon)
                    .font(.caption)
                Text(scope.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(16)
        }
    }
}

struct EmptySearchView: View {
    let recentSearches: [String]
    let onRecentSearchTapped: (String) -> Void
    let onClearRecentSearches: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Searches")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Clear", action: onClearRecentSearches)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                            ForEach(recentSearches, id: \.self) { search in
                                Button(action: { onRecentSearchTapped(search) }) {
                                    Text(search)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color(.systemGray5))
                                        .cornerRadius(16)
                                }
                                .foregroundColor(.primary)
                            }
                        }
                    }
                }
                
                // Trending Topics (Mock)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Trending")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        TrendingItem(topic: "SwiftUI", posts: "1.2K posts")
                        TrendingItem(topic: "iOS Development", posts: "890 posts") 
                        TrendingItem(topic: "Machine Learning", posts: "645 posts")
                        TrendingItem(topic: "Design Systems", posts: "423 posts")
                    }
                }
            }
            .padding()
        }
    }
}

struct TrendingItem: View {
    let topic: String
    let posts: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(topic)
                .font(.body)
                .fontWeight(.medium)
            
            Text(posts)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}

struct SearchingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Searching...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}

struct NoResultsView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No results for '\(searchText)'")
                .font(.headline)
            
            Text("Try adjusting your search or browse trending topics")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}

struct SearchResultsContentView: View {
    let results: SearchView.SearchResults
    let selectedScope: SearchView.SearchScope
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Users Section
                if !results.users.isEmpty && (selectedScope == .all || selectedScope == .users) {
                    SearchSection(title: "Users", icon: "person.2") {
                        ForEach(results.users, id: \.id) { user in
                            UserSearchResultView(user: user)
                        }
                    }
                }
                
                // Posts Section  
                if !results.posts.isEmpty && (selectedScope == .all || selectedScope == .posts) {
                    SearchSection(title: "Posts", icon: "text.bubble") {
                        ForEach(results.posts, id: \.id) { post in
                            PostSearchResultView(post: post)
                        }
                    }
                }
                
                // Courses Section
                if !results.courses.isEmpty && (selectedScope == .all || selectedScope == .courses || selectedScope == .content) {
                    SearchSection(title: "Courses", icon: "book") {
                        ForEach(results.courses, id: \.id) { course in
                            CourseSearchResultView(course: course)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct SearchSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct UserSearchResultView: View {
    let user: UserProfile
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.profileImageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .font(.title)
                    .foregroundColor(.gray)
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.fullName)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let bio = user.bio {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Button(user.isFollowing == true ? "Following" : "Follow") {
                // Handle follow action
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(user.isFollowing == true ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .padding(.vertical, 4)
    }
}

struct PostSearchResultView: View {
    let post: FeedPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("@\(post.username)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Text(RelativeDateTimeFormatter().localizedString(for: ISO8601DateFormatter().date(from: post.createdAt) ?? Date(), relativeTo: Date()))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(post.content)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                    Text("\(post.likesCount)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "message")
                    Text("\(post.commentsCount)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct CourseSearchResultView: View {
    let course: APILearningResource
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: course.thumbnailUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .overlay(
                        Image(systemName: "book")
                            .foregroundColor(.blue)
                    )
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(course.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Text(course.provider)
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("• \(course.duration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text(String(format: "%.1f", course.rating))
                    }
                    .font(.caption)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SearchFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Content Type") {
                    // Filter options would go here
                    Text("Filter options coming soon...")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Search Filters")
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

#Preview {
    SearchView()
}