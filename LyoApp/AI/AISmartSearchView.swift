import SwiftUI

// MARK: - AI-Powered Smart Search View
struct AISmartSearchView: View {
    @StateObject private var aiService = GemmaAIService.shared
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var searchSuggestions: [String] = []
    @State private var showingFilters = false
    
    // Search filters
    @State private var selectedDifficulty: DifficultyLevel?
    @State private var selectedContentTypes: Set<ContentType> = []
    @State private var selectedSources: Set<SourcePlatform> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                searchHeader
                
                // Search Results
                if isSearching {
                    searchingView
                } else if searchResults.isEmpty && !searchText.isEmpty {
                    emptyResultsView
                } else if !searchResults.isEmpty {
                    searchResultsView
                } else {
                    searchPlaceholderView
                }
            }
            .navigationTitle("Smart Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView(
                    selectedDifficulty: $selectedDifficulty,
                    selectedContentTypes: $selectedContentTypes,
                    selectedSources: $selectedSources
                )
            }
        }
    }
    
    // MARK: - Search Header
    private var searchHeader: some View {
        VStack(spacing: 12) {
            // Search Bar with AI indicator
            HStack {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(DesignTokens.accent)
                        .font(.title3)
                    
                    TextField("Ask AI anything...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }
                        .onChange(of: searchText) { _, newValue in
                            if newValue.isEmpty {
                                searchResults = []
                            } else {
                                generateSearchSuggestions(for: newValue)
                            }
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(DesignTokens.textSecondary)
                        }
                    }
                }
                .padding()
                .background(DesignTokens.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button(action: performSearch) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white)
                        .padding()
                        .background(DesignTokens.accent)
                        .clipShape(Circle())
                }
                .disabled(searchText.isEmpty)
            }
            
            // Search Suggestions
            if !searchSuggestions.isEmpty && !searchText.isEmpty {
                SearchSuggestionsView(
                    suggestions: searchSuggestions,
                    onSuggestionTap: { suggestion in
                        searchText = suggestion
                        performSearch()
                    }
                )
            }
            
            // Active Filters
            if hasActiveFilters {
                ActiveFiltersView(
                    difficulty: selectedDifficulty,
                    contentTypes: selectedContentTypes,
                    sources: selectedSources,
                    onClearFilter: clearFilter
                )
            }
        }
        .padding()
        .background(DesignTokens.backgroundPrimary)
    }
    
    // MARK: - Search States
    private var searchingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("AI is analyzing your query...")
                .font(.subheadline)
                .foregroundColor(DesignTokens.textSecondary)
            
            Text("Using semantic search to find the most relevant content")
                .font(.caption)
                .foregroundColor(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.textSecondary)
            
            Text("No Results Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.textPrimary)
            
            Text("Try adjusting your search terms or filters")
                .font(.body)
                .foregroundColor(DesignTokens.textSecondary)
                .multilineTextAlignment(.center)
            
            Button("Clear Filters") {
                clearAllFilters()
                performSearch()
            }
            .foregroundColor(DesignTokens.accent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(searchResults) { result in
                    SearchResultCard(result: result) {
                        // Handle result selection
                        handleResultSelection(result)
                    }
                }
            }
            .padding()
        }
    }
    
    private var searchPlaceholderView: some View {
        VStack(spacing: 24) {
            // AI Search Features
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 60))
                    .foregroundColor(DesignTokens.accent)
                
                Text("AI-Powered Search")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.textPrimary)
                
                Text("Ask questions in natural language and get intelligent results")
                    .font(.body)
                    .foregroundColor(DesignTokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // Search Examples
            VStack(alignment: .leading, spacing: 12) {
                Text("Try asking:")
                    .font(.headline)
                    .foregroundColor(DesignTokens.textPrimary)
                
                SearchExampleCard(
                    icon: "swift",
                    title: "\"How to learn SwiftUI?\"",
                    description: "Get personalized learning resources"
                ) {
                    searchText = "How to learn SwiftUI?"
                    performSearch()
                }
                
                SearchExampleCard(
                    icon: "book.fill",
                    title: "\"Beginner iOS development\"",
                    description: "Find content for your skill level"
                ) {
                    searchText = "Beginner iOS development"
                    performSearch()
                }
                
                SearchExampleCard(
                    icon: "lightbulb.fill",
                    title: "\"Advanced programming concepts\"",
                    description: "Discover challenging topics"
                ) {
                    searchText = "Advanced programming concepts"
                    performSearch()
                }
            }
            .padding()
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Properties
    private var hasActiveFilters: Bool {
        selectedDifficulty != nil || !selectedContentTypes.isEmpty || !selectedSources.isEmpty
    }
    
    // MARK: - Search Functions
    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSearching = true
        Task {
            let filtered = filterResources(appState.learningResources)
            let results = await aiService.performSmartSearch(searchText, in: filtered)
            
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
                self.searchSuggestions = []
            }
        }
    }
    
    private func generateSearchSuggestions(for query: String) {
        // Simple suggestion generation based on common search patterns
        let suggestions = [
            "How to learn \(query)",
            "\(query) for beginners",
            "Advanced \(query) concepts",
            "\(query) tutorial",
            "Best \(query) courses"
        ].filter { $0.lowercased() != query.lowercased() }
        
        searchSuggestions = Array(suggestions.prefix(3))
    }
    
    private func filterResources(_ resources: [LearningResource]) -> [LearningResource] {
        return resources.filter { resource in
            // Filter by difficulty
            if let difficulty = selectedDifficulty {
                guard resource.difficultyLevel == difficulty else { return false }
            }
            
            // Filter by content type
            if !selectedContentTypes.isEmpty {
                guard selectedContentTypes.contains(resource.contentType) else { return false }
            }
            
            // Filter by source
            if !selectedSources.isEmpty {
                guard selectedSources.contains(resource.sourcePlatform) else { return false }
            }
            
            return true
        }
    }
    
    private func clearFilter(_ filterType: FilterType) {
        switch filterType {
        case .difficulty:
            selectedDifficulty = nil
        case .contentType(let type):
            selectedContentTypes.remove(type)
        case .source(let source):
            selectedSources.remove(source)
        }
    }
    
    private func clearAllFilters() {
        selectedDifficulty = nil
        selectedContentTypes.removeAll()
        selectedSources.removeAll()
    }
    
    private func handleResultSelection(_ result: SearchResult) {
        // Navigate to resource detail or open content
        print("Selected resource: \(result.resource.title)")
    }
}

// MARK: - Search Suggestions View
struct SearchSuggestionsView: View {
    let suggestions: [String]
    let onSuggestionTap: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        onSuggestionTap(suggestion)
                    }) {
                        Text(suggestion)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(DesignTokens.cardBackground)
                            .foregroundColor(DesignTokens.textPrimary)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(DesignTokens.borderColor, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Active Filters View
struct ActiveFiltersView: View {
    let difficulty: DifficultyLevel?
    let contentTypes: Set<ContentType>
    let sources: Set<SourcePlatform>
    let onClearFilter: (FilterType) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let difficulty = difficulty {
                    FilterChip(
                        text: difficulty.displayName,
                        color: .orange
                    ) {
                        onClearFilter(.difficulty)
                    }
                }
                
                ForEach(Array(contentTypes), id: \.self) { type in
                    FilterChip(
                        text: type.displayName,
                        color: .blue
                    ) {
                        onClearFilter(.contentType(type))
                    }
                }
                
                ForEach(Array(sources), id: \.self) { source in
                    FilterChip(
                        text: source.displayName,
                        color: .green
                    ) {
                        onClearFilter(.source(source))
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let text: String
    let color: Color
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}

// MARK: - Search Example Card
struct SearchExampleCard: View {
    let icon: String
    let title: String
    let description: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(DesignTokens.accent)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.textPrimary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(DesignTokens.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(DesignTokens.textSecondary)
            }
            .padding(12)
            .background(DesignTokens.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Search Result Card
struct SearchResultCard: View {
    let result: SearchResult
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.resource.title)
                            .font(.headline)
                            .foregroundColor(DesignTokens.textPrimary)
                            .lineLimit(2)
                        
                        Text(result.resource.description)
                            .font(.body)
                            .foregroundColor(DesignTokens.textSecondary)
                            .lineLimit(3)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        RelevanceScore(score: result.relevanceScore)
                        
                        if let difficulty = result.resource.difficultyLevel {
                            DifficultyBadge(level: difficulty)
                        }
                    }
                }
                
                // AI Explanation
                Text(result.explanation)
                    .font(.caption)
                    .foregroundColor(DesignTokens.accent)
                    .padding(8)
                    .background(DesignTokens.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Matched Terms
                if !result.matchedTerms.isEmpty {
                    HStack {
                        Text("Matches:")
                            .font(.caption)
                            .foregroundColor(DesignTokens.textSecondary)
                        
                        ForEach(result.matchedTerms.prefix(3), id: \.self) { term in
                            Text(term)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignTokens.accent.opacity(0.1))
                                .foregroundColor(DesignTokens.accent)
                                .clipShape(Capsule())
                        }
                        
                        if result.matchedTerms.count > 3 {
                            Text("+\(result.matchedTerms.count - 3)")
                                .font(.caption)
                                .foregroundColor(DesignTokens.textSecondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // Resource Metadata
                HStack {
                    if let category = result.resource.category {
                        Text(category)
                            .font(.caption)
                            .foregroundColor(DesignTokens.textSecondary)
                    }
                    
                    Spacer()
                    
                    if let rating = result.resource.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .foregroundColor(DesignTokens.textSecondary)
                        }
                    }
                }
            }
            .padding()
            .background(DesignTokens.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(DesignTokens.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Relevance Score
struct RelevanceScore: View {
    let score: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Int(score * 100))%")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(scoreColor)
            
            Text("relevance")
                .font(.caption2)
                .foregroundColor(DesignTokens.textSecondary)
        }
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
}

// MARK: - Search Filters Sheet
struct SearchFiltersView: View {
    @Binding var selectedDifficulty: DifficultyLevel?
    @Binding var selectedContentTypes: Set<ContentType>
    @Binding var selectedSources: Set<SourcePlatform>
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Difficulty Level") {
                    ForEach(DifficultyLevel.allCases, id: \.self) { difficulty in
                        Button(action: {
                            if selectedDifficulty == difficulty {
                                selectedDifficulty = nil
                            } else {
                                selectedDifficulty = difficulty
                            }
                        }) {
                            HStack {
                                Text(difficulty.displayName)
                                    .foregroundColor(DesignTokens.textPrimary)
                                
                                Spacer()
                                
                                if selectedDifficulty == difficulty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignTokens.accent)
                                }
                            }
                        }
                    }
                }
                
                Section("Content Type") {
                    ForEach(ContentType.allCases, id: \.self) { type in
                        Button(action: {
                            if selectedContentTypes.contains(type) {
                                selectedContentTypes.remove(type)
                            } else {
                                selectedContentTypes.insert(type)
                            }
                        }) {
                            HStack {
                                Image(systemName: type.icon)
                                    .foregroundColor(type.color)
                                
                                Text(type.displayName)
                                    .foregroundColor(DesignTokens.textPrimary)
                                
                                Spacer()
                                
                                if selectedContentTypes.contains(type) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignTokens.accent)
                                }
                            }
                        }
                    }
                }
                
                Section("Source Platform") {
                    ForEach(SourcePlatform.allCases, id: \.self) { source in
                        Button(action: {
                            if selectedSources.contains(source) {
                                selectedSources.remove(source)
                            } else {
                                selectedSources.insert(source)
                            }
                        }) {
                            HStack {
                                Text(source.displayName)
                                    .foregroundColor(DesignTokens.textPrimary)
                                
                                Spacer()
                                
                                if selectedSources.contains(source) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(DesignTokens.accent)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedDifficulty = nil
                        selectedContentTypes.removeAll()
                        selectedSources.removeAll()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Filter Type Enum
enum FilterType {
    case difficulty
    case contentType(ContentType)
    case source(SourcePlatform)
}
