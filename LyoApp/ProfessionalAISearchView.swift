import SwiftUI
import Foundation

// MARK: - AI Search Models

// Represents rich metadata returned with a search result
struct SearchMetadata: Codable {
    var duration: String?
    var difficulty: String?
    var rating: Double?
    var author: String?
    var tags: [String]?
    var lastUpdated: String?
}

// Search content types for AI results
enum SearchContentType: String, Codable, CaseIterable, Identifiable {
    case course
    case video
    case article
    case project
    
    var id: String { rawValue }
    
    // Icon name to display alongside the content type
    var icon: String {
        switch self {
        case .course: return "book.closed"
        case .video: return "play.rectangle.fill"
        case .article: return "doc.text"
        case .project: return "hammer"
        }
    }
    
    // Accent color per content type
    var color: Color {
        switch self {
        case .course: return DesignTokens.Colors.primary
        case .video: return DesignTokens.Colors.accent
        case .article: return DesignTokens.Colors.textSecondary
        case .project: return DesignTokens.Colors.success
        }
    }
}

// Sorting options for AI search
enum SearchSortBy: String, Codable, CaseIterable, Identifiable {
    case relevance
    case newest
    case rating
    case popularity

    var id: String { rawValue }
}

// Local filters for AI search to avoid cross-file ambiguity
struct AISearchFilters: Equatable, Codable {
    var contentTypes: Set<SearchContentType> = Set(SearchContentType.allCases)
    var difficulty: String? = nil
    var duration: String? = nil
    var sortBy: SearchSortBy = .relevance
}

struct AISearchResult: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let contentType: SearchContentType
    let url: String?
    let thumbnailURL: String?
    let relevanceScore: Double
    let metadata: SearchMetadata?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, url, thumbnailURL, metadata
        case contentType = "type"
        case relevanceScore = "relevance"
    }
}

// MARK: - AI Search Service

@MainActor
class AISearchService: ObservableObject {
    private let baseURL = LyoConfiguration.backendURL
    
    func search(query: String, filters: AISearchFilters) async throws -> [AISearchResult] {
        guard let url = URL(string: "\(baseURL)/api/v1/search") else {
            throw URLError(.badURL)
        }
        
        let searchRequest = [
            "query": query,
            "filters": [
                "content_types": Array(filters.contentTypes.map { $0.rawValue }),
                "difficulty": filters.difficulty as Any,
                "duration": filters.duration as Any,
                "sort_by": filters.sortBy.rawValue
            ],
            "limit": 20
        ] as [String : Any]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: searchRequest)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: [AISearchResult]].self, from: data)
        return response["results"] ?? []
    }
    
    func getSuggestions(for query: String) async throws -> [String] {
        guard let url = URL(string: "\(baseURL)/api/v1/search/suggestions?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([String: [String]].self, from: data)
        return response["suggestions"] ?? []
    }
}

// MARK: - AI Search ViewModel

@MainActor
class ProfessionalAISearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [AISearchResult] = []
    @Published var suggestions: [String] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filters = AISearchFilters()
    @Published var showingFilters = false
    @Published var searchHistory: [String] = []
    
    private let searchService = AISearchService()
    private var searchTask: Task<Void, Never>?
    
    init() {
        loadSearchHistory()
    }
    
    func performSearch() async {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            results = []
            return
        }
        
        searchTask?.cancel()
        
        searchTask = Task {
            isLoading = true
            errorMessage = nil
            
            do {
                if !LyoConfiguration.enableMockData {
                    results = try await searchService.search(query: query, filters: filters)
                } else {
                    results = generateMockResults(for: query)
                }
                
                // Add to search history
                addToSearchHistory(query)
            } catch {
                if !Task.isCancelled {
                    errorMessage = "Search failed: \(error.localizedDescription)"
                    results = generateMockResults(for: query) // Fallback
                }
            }
            
            isLoading = false
        }
    }
    
    func loadSuggestions() async {
        guard !query.isEmpty else {
            suggestions = []
            return
        }
        
        do {
            if !LyoConfiguration.enableMockData {
                suggestions = try await searchService.getSuggestions(for: query)
            } else {
                suggestions = generateMockSuggestions(for: query)
            }
        } catch {
            suggestions = generateMockSuggestions(for: query) // Fallback
        }
    }
    
    private func addToSearchHistory(_ searchQuery: String) {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Remove if already exists
        searchHistory.removeAll { $0 == trimmed }
        // Add to beginning
        searchHistory.insert(trimmed, at: 0)
        // Keep only last 20 searches
        if searchHistory.count > 20 {
            searchHistory = Array(searchHistory.prefix(20))
        }
        
        saveSearchHistory()
    }
    
    private func loadSearchHistory() {
        searchHistory = UserDefaults.standard.stringArray(forKey: "AISearchHistory") ?? []
    }
    
    private func saveSearchHistory() {
        UserDefaults.standard.set(searchHistory, forKey: "AISearchHistory")
    }
    
    func clearSearchHistory() {
        searchHistory = []
        saveSearchHistory()
    }
    
    private func generateMockResults(for query: String) -> [AISearchResult] {
        let queryLower = query.lowercased()
        
        return [
            AISearchResult(
                id: "course_\(UUID().uuidString)",
                title: "Advanced \(query.capitalized) Programming",
                description: "Master \(queryLower) with hands-on projects and real-world applications. Learn from industry experts.",
                contentType: .course,
                url: "/courses/advanced-\(queryLower)",
                thumbnailURL: nil,
                relevanceScore: 0.95,
                metadata: SearchMetadata(
                    duration: "6 hours",
                    difficulty: "Intermediate",
                    rating: 4.8,
                    author: "Dr. Sarah Johnson",
                    tags: [queryLower, "programming", "advanced"],
                    lastUpdated: "2024-01-15"
                )
            ),
            AISearchResult(
                id: "video_\(UUID().uuidString)",
                title: "\(query.capitalized) Fundamentals Explained",
                description: "A comprehensive video tutorial covering \(queryLower) basics and best practices.",
                contentType: .video,
                url: "/videos/\(queryLower)-fundamentals",
                thumbnailURL: nil,
                relevanceScore: 0.87,
                metadata: SearchMetadata(
                    duration: "45 minutes",
                    difficulty: "Beginner",
                    rating: 4.6,
                    author: "Alex Chen",
                    tags: [queryLower, "fundamentals", "tutorial"]
                )
            ),
            AISearchResult(
                id: "article_\(UUID().uuidString)",
                title: "Best Practices for \(query.capitalized)",
                description: "Industry-standard practices and tips for \(queryLower) development.",
                contentType: .article,
                url: "/articles/\(queryLower)-best-practices",
                thumbnailURL: nil,
                relevanceScore: 0.82,
                metadata: SearchMetadata(
                    duration: "8 min read",
                    rating: 4.4,
                    author: "Maria Rodriguez",
                    tags: [queryLower, "best-practices", "tips"]
                )
            ),
            AISearchResult(
                id: "project_\(UUID().uuidString)",
                title: "\(query.capitalized) Portfolio Project",
                description: "Build a professional \(queryLower) project for your portfolio.",
                contentType: .project,
                url: "/projects/\(queryLower)-portfolio",
                thumbnailURL: nil,
                relevanceScore: 0.79,
                metadata: SearchMetadata(
                    duration: "3 weeks",
                    difficulty: "Advanced",
                    rating: 4.7,
                    tags: [queryLower, "project", "portfolio"]
                )
            )
        ]
    }
    
    private func generateMockSuggestions(for query: String) -> [String] {
        return [
            "\(query) fundamentals",
            "\(query) advanced techniques",
            "\(query) best practices",
            "\(query) tutorial",
            "\(query) certification"
        ]
    }
}

// MARK: - Professional AI Search View

struct ProfessionalAISearchView: View {
    @StateObject private var viewModel = ProfessionalAISearchViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingResult: AISearchResult?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                searchBarView
                
                if viewModel.query.isEmpty {
                    emptyStateView
                } else if viewModel.isLoading {
                    loadingView
                } else if viewModel.results.isEmpty && !viewModel.query.isEmpty {
                    noResultsView
                } else {
                    resultsView
                }
            }
            .background(DesignTokens.Colors.primaryBg)
            .navigationBarHidden(true)
        }
        .sheet(item: $showingResult) { result in
            SearchResultDetailView(result: result)
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                    Text("Back")
                        .font(DesignTokens.Typography.bodyMedium)
                }
                .foregroundColor(DesignTokens.Colors.primary)
            }
            
            Spacer()
            
            Text("AI Search")
                .font(DesignTokens.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Button(action: { viewModel.showingFilters.toggle() }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
                    .foregroundColor(DesignTokens.Colors.primary)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg)
    }
    
    // MARK: - Search Bar
    
    private var searchBarView: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignTokens.Colors.primary)
                    .font(.system(size: 18))
                
                TextField("Search topics, courses, or resources...", text: $viewModel.query)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(DesignTokens.Typography.body)
                    .onSubmit {
                        Task {
                            await viewModel.performSearch()
                        }
                    }
                    .onChange(of: viewModel.query) { oldValue, newValue in
                        if !newValue.isEmpty {
                            Task {
                                await viewModel.loadSuggestions()
                            }
                        }
                    }
                
                if !viewModel.query.isEmpty {
                    Button(action: { viewModel.query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                    .fill(DesignTokens.Colors.glassOverlay)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                            .stroke(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 2)
                    )
            )
            
            // AI-powered suggestions
            if !viewModel.suggestions.isEmpty && viewModel.results.isEmpty {
                suggestionsView
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.bottom, DesignTokens.Spacing.md)
    }
    
    private var suggestionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    Button(action: {
                        viewModel.query = suggestion
                        Task {
                            await viewModel.performSearch()
                        }
                    }) {
                        Text(suggestion)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.primary)
                            .padding(.horizontal, DesignTokens.Spacing.md)
                            .padding(.vertical, DesignTokens.Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                    .fill(DesignTokens.Colors.primary.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                            .stroke(DesignTokens.Colors.primary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
    
    // MARK: - Content Views
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.primary.opacity(0.6))
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("AI-Powered Search")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Search for courses, videos, articles, and more using natural language")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if !viewModel.searchHistory.isEmpty {
                recentSearchesView
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }
    
    private var recentSearchesView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Recent Searches")
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("Clear") {
                    viewModel.clearSearchHistory()
                }
                .font(DesignTokens.Typography.caption)
                .foregroundColor(DesignTokens.Colors.primary)
            }
            
            LazyVStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(Array(viewModel.searchHistory.prefix(5)), id: \.self) { search in
                    Button(action: {
                        viewModel.query = search
                        Task {
                            await viewModel.performSearch()
                        }
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                            
                            Text(search)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textPrimary)
                            
                            Spacer()
                        }
                        .padding(DesignTokens.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                .fill(DesignTokens.Colors.glassOverlay)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.top, DesignTokens.Spacing.lg)
    }
    
    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(DesignTokens.Colors.primary)
            
            Text("Searching with AI...")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    private var noResultsView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            
            Image(systemName: "questionmark.circle")
                .font(.system(size: 50))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("No Results Found")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("Try adjusting your search terms or filters")
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Spacer()
        }
    }
    
    private var resultsView: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(viewModel.results) { result in
                    SearchResultCardView(result: result) {
                        showingResult = result
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Search Result Card View

struct SearchResultCardView: View {
    let result: AISearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                HStack {
                    Image(systemName: result.contentType.icon)
                        .font(.system(size: 18))
                        .foregroundColor(result.contentType.color)
                    
                    Text(result.contentType.rawValue.capitalized)
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(result.contentType.color)
                    
                    Spacer()
                    
                    Text("\(Int(result.relevanceScore * 100))% match")
                        .font(DesignTokens.Typography.caption)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text(result.title)
                        .font(DesignTokens.Typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(result.description)
                        .font(DesignTokens.Typography.body)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    if let author = result.metadata?.author {
                        Label(author, systemImage: "person.fill")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    if let duration = result.metadata?.duration {
                        Label(duration, systemImage: "clock")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    if let rating = result.metadata?.rating {
                        Label(String(format: "%.1f", rating), systemImage: "star.fill")
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                }
            }
            .padding(DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.glassOverlay)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                            .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Result Detail View

struct SearchResultDetailView: View {
    let result: AISearchResult
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    // Header
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        HStack {
                            Image(systemName: result.contentType.icon)
                                .font(.system(size: 24))
                                .foregroundColor(result.contentType.color)
                            
                            Text(result.contentType.rawValue.capitalized)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(result.contentType.color)
                            
                            Spacer()
                        }
                        
                        Text(result.title)
                            .font(DesignTokens.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        Text(result.description)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
                    
                    // Metadata
                    metadataView
                    
                    // Action Buttons
                    actionButtonsView
                    
                    Spacer()
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.primaryBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var metadataView: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Details")
                .font(DesignTokens.Typography.title3)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignTokens.Spacing.md) {
                if let author = result.metadata?.author {
                    MetadataItem(icon: "person.fill", title: "Author", value: author)
                }
                
                if let duration = result.metadata?.duration {
                    MetadataItem(icon: "clock", title: "Duration", value: duration)
                }
                
                if let difficulty = result.metadata?.difficulty {
                    MetadataItem(icon: "chart.bar", title: "Difficulty", value: difficulty)
                }
                
                if let rating = result.metadata?.rating {
                    MetadataItem(icon: "star.fill", title: "Rating", value: String(format: "%.1f/5", rating))
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.glassOverlay)
        )
    }
    
    private var actionButtonsView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Button(action: {}) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Learning")
                }
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.primary)
                .cornerRadius(DesignTokens.Radius.button)
            }
            
            HStack(spacing: DesignTokens.Spacing.md) {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "bookmark")
                        Text("Save")
                    }
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .stroke(DesignTokens.Colors.primary, lineWidth: 1)
                    )
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding(DesignTokens.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                            .stroke(DesignTokens.Colors.primary, lineWidth: 1)
                    )
                }
            }
        }
    }
}

struct MetadataItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: icon)
                    .foregroundColor(DesignTokens.Colors.primary)
                Text(title)
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Text(value)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
    }
}
