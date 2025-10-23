import SwiftUI
import Combine

// MARK: - Learn View (Learning Interface)
struct LearnView: View {
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var selectedContentType: LearningResource.ContentType? = nil
    @State private var selectedDifficulty: LearningResource.DifficultyLevel? = nil
    @State private var viewMode: ViewMode = .grid
    @State private var showFilters = false
    @State private var searchText = ""
    @State private var resources: [LearningResource] = []
    @State private var trendingResources: [LearningResource] = []
    @State private var isLoading = false
    
    private let learningService = LearningAPIService.shared
    
    // Layout configuration
    private let gridColumns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.md)
    ]
    
    enum ViewMode: CaseIterable {
        case grid, list
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    headerSection
                    
                    if showFilters {
                        filtersSection
                    }
                    
                    if isLoading {
                        loadingSection
                    } else {
                        contentSection
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
            .navigationTitle("Learn")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    viewModeToggle
                }
            }
        }
        .task {
            await loadInitialContent()
        }
        .onChange(of: searchText) { oldSearchText, newSearchText in
            Task {
                await performSearch(newSearchText)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                searchBar
                filterToggleButton
            }
            
            if searchText.isEmpty && !showFilters {
                quickCategoriesSection
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.sm)
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search courses, videos, articles...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.horizontal, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - Filter Toggle Button
    private var filterToggleButton: some View {
        Button(action: { showFilters.toggle() }) {
            Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Quick Categories Section
    private var quickCategoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(LearningResource.ContentType.allCases, id: \.self) { type in
                    quickCategoryButton(for: type)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }
    
    private func quickCategoryButton(for type: LearningResource.ContentType) -> some View {
        Button(action: {
            selectedContentType = selectedContentType == type ? nil : type
            Task {
                await applyFilters()
            }
        }) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: type.icon)
                Text(type.displayName)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(selectedContentType == type ? Color.accentColor : Color(.systemGray5))
            )
            .foregroundColor(selectedContentType == type ? .white : .primary)
        }
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Filters")
                    .font(.headline)
                Spacer()
                Button("Clear") {
                    selectedContentType = nil
                    selectedDifficulty = nil
                    Task {
                        await applyFilters()
                    }
                }
            }
            
            // Content Type Filter
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Content Type")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.sm) {
                    ForEach(LearningResource.ContentType.allCases, id: \.self) { type in
                        Button(type.displayName) {
                            selectedContentType = selectedContentType == type ? nil : type
                            Task {
                                await applyFilters()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .background(selectedContentType == type ? Color.accentColor : Color.clear)
                    }
                }
            }
            
            // Difficulty Filter
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Difficulty")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack {
                    ForEach(LearningResource.DifficultyLevel.allCases, id: \.self) { difficulty in
                        Button(difficulty.displayName) {
                            selectedDifficulty = selectedDifficulty == difficulty ? nil : difficulty
                            Task {
                                await applyFilters()
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .background(selectedDifficulty == difficulty ? Color.accentColor : Color.clear)
                    }
                    Spacer()
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                .fill(Color(.systemGray6))
        )
    }
    
    // MARK: - View Mode Toggle
    private var viewModeToggle: some View {
        Button(action: { viewMode = viewMode == .grid ? .list : .grid }) {
            Image(systemName: viewMode.icon)
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            if !trendingResources.isEmpty && searchText.isEmpty {
                trendingSection
            }
            
            mainContentSection
        }
    }
    
    // MARK: - Trending Section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Label("Trending Now", systemImage: "flame")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(trendingResources.prefix(5)) { resource in
                        TrendingResourceCard(resource: resource)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.md)
            }
        }
    }
    
    // MARK: - Main Content Section
    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            if !resources.isEmpty {
                HStack {
                    Text("\(resources.count) Resources")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                if viewMode == .grid {
                    LazyVGrid(columns: gridColumns, spacing: DesignTokens.Spacing.md) {
                        ForEach(resources) { resource in
                            ResourceCard(resource: resource)
                        }
                    }
                } else {
                    LazyVStack(spacing: DesignTokens.Spacing.sm) {
                        ForEach(resources) { resource in
                            ResourceListItem(resource: resource)
                        }
                    }
                }
            } else if !isLoading {
                emptyStateView
            }
        }
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading resources...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, DesignTokens.Spacing.xl)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: "books.vertical")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Resources Found")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, DesignTokens.Spacing.xl)
    }
    
    // MARK: - Methods
    private func loadInitialContent() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            // Load initial resources for trending and general content
            let allResources = try await learningService.fetchResources(for: "trending", limit: 30)
            
            await MainActor.run {
                self.trendingResources = Array(allResources.prefix(10))
                self.resources = Array(allResources.suffix(20))
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("Error loading content: \(error)")
            }
        }
    }
    
    private func performSearch(_ query: String) async {
        guard !query.isEmpty else {
            await loadInitialContent()
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let searchRequest = LearningSearchRequest(
                query: query,
                limit: 30
            )
            let searchResponse = try await learningService.searchResources(searchRequest)
            
            await MainActor.run {
                self.resources = searchResponse.resources
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("Search error: \(error)")
            }
        }
    }
    
    private func applyFilters() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let searchRequest = LearningSearchRequest(
                contentTypes: selectedContentType != nil ? [selectedContentType!] : [],
                difficultyLevels: selectedDifficulty != nil ? [selectedDifficulty!] : [],
                limit: 30
            )
            
            let searchResponse = try await learningService.searchResources(searchRequest)
            
            await MainActor.run {
                self.resources = searchResponse.resources
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                print("Filter error: \(error)")
            }
        }
    }
}

// MARK: - Supporting Views
struct TrendingResourceCard: View {
    let resource: LearningResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            AsyncImage(url: resource.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray4))
            }
            .frame(width: 200, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(resource.title)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(resource.instructor ?? "Unknown Instructor")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: resource.contentType.icon)
                    Text(resource.contentType.displayName)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .frame(width: 200, alignment: .leading)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        .shadow(radius: 2)
    }
}

struct ResourceCard: View {
    let resource: LearningResource
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            AsyncImage(url: resource.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray4))
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(resource.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(resource.instructor ?? "Unknown Instructor")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: resource.contentType.icon)
                        .font(.caption)
                    Text(resource.contentType.displayName)
                        .font(.caption)
                    Spacer()
                    if let difficulty = resource.difficultyLevel {
                        Text(difficulty.displayName)
                            .font(.caption)
                            .padding(.horizontal, DesignTokens.Spacing.xs)
                            .background(difficulty.color.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.bottom, DesignTokens.Spacing.sm)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg))
        .shadow(radius: 2)
    }
}

struct ResourceListItem: View {
    let resource: LearningResource
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            AsyncImage(url: resource.thumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray4))
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(resource.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                Text(resource.instructor ?? "Unknown Instructor")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: resource.contentType.icon)
                        .font(.caption)
                    Text(resource.contentType.displayName)
                        .font(.caption)
                    Spacer()
                    if let difficulty = resource.difficultyLevel {
                        Text(difficulty.displayName)
                            .font(.caption)
                            .padding(.horizontal, DesignTokens.Spacing.xs)
                            .background(difficulty.color.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
        .shadow(radius: 1)
    }
}



// MARK: - Preview
#Preview {
    LearnView()
}
