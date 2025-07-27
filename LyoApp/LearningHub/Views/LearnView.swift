import SwiftUI
import Combine

// MARK: - Main Learn View
/// Primary learning hub interface with search, filtering, and content discovery
struct LearnView: View {
    @StateObject private var learningService = LearningAPIService()
    @StateObject private var searchViewModel = SearchViewModel()
    @State private var selectedContentType: LearningResource.ContentType? = nil
    @State private var selectedDifficulty: LearningResource.DifficultyLevel? = nil
    @State private var viewMode: ViewMode = .grid
    @State private var showFilters = false
    @State private var searchText = ""
    
    // Layout configuration
    private let gridColumns = [
        GridItem(.flexible(), spacing: DesignTokens.Spacing.md),
        GridItem(.flexible(), spacing: DesignTokens.Spacing.md)
    ]
    
    enum ViewMode: CaseIterable {
        case grid, list
        
        var icon: String {
            switch self {
            case .grid: return "rectangle.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filters
                headerSection
                
                // Content filters (when visible)
                if showFilters {
                    filtersSection
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Main content area
                contentSection
            }
            .background(DesignTokens.Colors.background)
            .navigationTitle("Learn")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    viewModeToggle
                }
            }
        }
        .task {
            await loadInitialContent()
        }
        .onReceive(searchViewModel.$searchText.debounce(for: .milliseconds(500), scheduler: RunLoop.main)) { text in
            Task {
                await performSearch(text)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Search bar
            HStack {
                searchBar
                filterToggleButton
            }
            
            // Quick access categories
            if searchText.isEmpty && !showFilters {
                quickCategoriesSection
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.bottom, DesignTokens.Spacing.sm)
        .background(
            Rectangle()
                .fill(DesignTokens.Colors.background)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .font(.system(size: 16))
            
            TextField("Search courses, videos, books...", text: $searchText)
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .submitLabel(.search)
                .onSubmit {
                    Task {
                        await performSearch(searchText)
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchViewModel.clearSearch()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
        .padding(.vertical, DesignTokens.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
    }
    
    private var filterToggleButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFilters.toggle()
            }
        }) {
            Image(systemName: showFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 20))
                .foregroundColor(showFilters ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
        }
        .padding(DesignTokens.Spacing.sm)
    }
    
    // MARK: - Quick Categories
    private var quickCategoriesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(LearningResource.ContentType.allCases, id: \.self) { contentType in
                    CategoryButton(
                        contentType: contentType,
                        isSelected: selectedContentType == contentType,
                        action: {
                            if selectedContentType == contentType {
                                selectedContentType = nil
                            } else {
                                selectedContentType = contentType
                            }
                            Task {
                                await applyFilters()
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }
    
    // MARK: - Filters Section
    private var filtersSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Content Type Filter
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Content Type")
                    .font(DesignTokens.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: DesignTokens.Spacing.sm) {
                    ForEach(LearningResource.ContentType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.displayName,
                            icon: type.icon,
                            isSelected: selectedContentType == type,
                            action: {
                                selectedContentType = selectedContentType == type ? nil : type
                                Task { await applyFilters() }
                            }
                        )
                    }
                }
            }
            
            // Difficulty Filter
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Difficulty Level")
                    .font(DesignTokens.Typography.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(LearningResource.DifficultyLevel.allCases, id: \.self) { level in
                        FilterChip(
                            title: level.displayName,
                            icon: nil,
                            isSelected: selectedDifficulty == level,
                            backgroundColor: level.color,
                            action: {
                                selectedDifficulty = selectedDifficulty == level ? nil : level
                                Task { await applyFilters() }
                            }
                        )
                    }
                    Spacer()
                }
            }
            
            // Clear Filters Button
            if selectedContentType != nil || selectedDifficulty != nil {
                HStack {
                    Spacer()
                    Button("Clear Filters") {
                        selectedContentType = nil
                        selectedDifficulty = nil
                        Task { await applyFilters() }
                    }
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
        .padding(DesignTokens.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .fill(DesignTokens.Colors.cardBg.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
        )
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.lg) {
                // Trending Section (only when not searching)
                if searchText.isEmpty && !showFilters {
                    trendingSection
                }
                
                // Main Content Grid/List
                mainContentSection
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.bottom, DesignTokens.Spacing.xxl)
        }
        .refreshable {
            await loadInitialContent()
        }
    }
    
    // MARK: - Trending Section
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Trending Now")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to trending view
                }
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.primary)
            }
            
            if learningService.isLoading && learningService.trendingResources.isEmpty {
                trendingLoadingView
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DesignTokens.Spacing.md) {
                        ForEach(learningService.trendingResources.prefix(5)) { resource in
                            LearningCardView(
                                resource: resource,
                                cardStyle: .standard,
                                onTap: {
                                    // Navigate to detail view
                                    print("📱 NAVIGATION: Opening resource \(resource.title)")
                                }
                            )
                        }
                    }
                    .padding(.horizontal, DesignTokens.Spacing.md)
                }
            }
        }
    }
    
    private var trendingLoadingView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md) {
                ForEach(0..<5, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.glassBg)
                        .frame(width: 160, height: 240)
                        .shimmer()
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
        }
    }
    
    // MARK: - Main Content Section
    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // Section header
            if !searchText.isEmpty {
                searchResultsHeader
            } else if showFilters || selectedContentType != nil || selectedDifficulty != nil {
                filteredResultsHeader
            } else {
                allContentHeader
            }
            
            // Content display
            if learningService.isLoading && learningService.resources.isEmpty {
                loadingView
            } else if learningService.resources.isEmpty {
                emptyStateView
            } else {
                contentGrid
            }
        }
    }
    
    private var searchResultsHeader: some View {
        HStack {
            Text("Search Results")
                .font(DesignTokens.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Text("\(learningService.resources.count) found")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
    
    private var filteredResultsHeader: some View {
        HStack {
            Text("Filtered Results")
                .font(DesignTokens.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            Text("\(learningService.resources.count) items")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
        }
    }
    
    private var allContentHeader: some View {
        HStack {
            Text("All Learning Resources")
                .font(DesignTokens.Typography.title2)
                .fontWeight(.bold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Spacer()
            
            viewModeToggle
        }
    }
    
    private var viewModeToggle: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ForEach(ViewMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = mode
                    }
                }) {
                    Image(systemName: mode.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(viewMode == mode ? DesignTokens.Colors.primary : DesignTokens.Colors.textSecondary)
                        .padding(DesignTokens.Spacing.xs)
                        .background(
                            Circle()
                                .fill(viewMode == mode ? DesignTokens.Colors.primary.opacity(0.1) : Color.clear)
                        )
                }
            }
        }
    }
    
    private var contentGrid: some View {
        Group {
            if viewMode == .grid {
                LazyVGrid(columns: gridColumns, spacing: DesignTokens.Spacing.md) {
                    ForEach(learningService.resources) { resource in
                        LearningCardView(
                            resource: resource,
                            cardStyle: .standard,
                            onTap: {
                                print("📱 NAVIGATION: Opening resource \(resource.title)")
                                // Navigate to detail view
                            }
                        )
                    }
                }
            } else {
                LazyVStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(learningService.resources) { resource in
                        LearningCardView(
                            resource: resource,
                            cardStyle: .wide,
                            onTap: {
                                print("📱 NAVIGATION: Opening resource \(resource.title)")
                                // Navigate to detail view
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var loadingView: some View {
        LazyVGrid(columns: gridColumns, spacing: DesignTokens.Spacing.md) {
            ForEach(0..<6, id: \.self) { _ in
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.glassBg)
                    .frame(height: viewMode == .grid ? 240 : 120)
                    .shimmer()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Text("No Resources Found")
                .font(DesignTokens.Typography.title2)
                .fontWeight(.semibold)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            Text("Try adjusting your search or filters to find more learning resources.")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignTokens.Spacing.xl)
            
            Button("Clear All Filters") {
                searchText = ""
                selectedContentType = nil
                selectedDifficulty = nil
                showFilters = false
                Task { await loadInitialContent() }
            }
            .font(DesignTokens.Typography.body)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                    .fill(DesignTokens.Colors.primary)
            )
        }
        .padding(.top, DesignTokens.Spacing.xxl)
    }
}

// MARK: - Data Loading
private extension LearnView {
    
    func loadInitialContent() async {
        print("🚀 LEARN VIEW: Loading initial content")
        
        async let trendingTask = learningService.fetchTrendingResources(limit: 10)
        async let resourcesTask = learningService.fetchResources(for: nil, limit: 20, offset: 0)
        
        await trendingTask
        await resourcesTask
        
        print("✅ LEARN VIEW: Initial content loaded - \(learningService.resources.count) resources, \(learningService.trendingResources.count) trending")
    }
    
    func performSearch(_ query: String) async {
        guard !query.isEmpty else {
            await loadInitialContent()
            return
        }
        
        print("🔍 SEARCH: Performing search for '\(query)'")
        
        let request = LearningResource.LearningSearchRequest(
            query: query,
            contentType: selectedContentType,
            difficultyLevel: selectedDifficulty,
            limit: 50,
            offset: 0
        )
        
        await learningService.searchResources(request)
        searchViewModel.updateSearchText(query)
        
        print("✅ SEARCH: Found \(learningService.resources.count) results for '\(query)'")
    }
    
    func applyFilters() async {
        if !searchText.isEmpty {
            await performSearch(searchText)
        } else {
            await learningService.fetchResources(
                for: selectedContentType,
                limit: 50,
                offset: 0
            )
        }
        
        print("🎯 FILTERS: Applied - ContentType: \(selectedContentType?.displayName ?? "All"), Difficulty: \(selectedDifficulty?.displayName ?? "All")")
    }
}

// MARK: - Supporting Views
struct CategoryButton: View {
    let contentType: LearningResource.ContentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: contentType.icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(contentType.displayName)
                    .font(DesignTokens.Typography.body)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? contentType.color : DesignTokens.Colors.cardBg)
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? contentType.color : DesignTokens.Colors.glassBorder,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let backgroundColor: Color?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isSelected: Bool, backgroundColor: Color? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.backgroundColor = backgroundColor
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .padding(.vertical, DesignTokens.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .fill(isSelected ? (backgroundColor ?? DesignTokens.Colors.primary) : DesignTokens.Colors.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                            .strokeBorder(
                                isSelected ? (backgroundColor ?? DesignTokens.Colors.primary) : DesignTokens.Colors.glassBorder,
                                lineWidth: 1
                            )
                    )
            )
            .foregroundColor(isSelected ? .white : DesignTokens.Colors.textPrimary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Shimmer Effect
extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var isAnimating = false
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: isAnimating ? 200 : -200)
                .animation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
                .clipped()
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Preview
#Preview {
    LearnView()
}
