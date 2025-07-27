import SwiftUI
import Foundation

// MARK: - Library Models

struct LibraryItem: Identifiable, Codable {
    let id: String
    let contentId: String
    let title: String
    let description: String?
    let contentType: ContentType
    let url: String?
    let tags: [String]
    let savedAt: Date
    let progress: Double // 0.0 to 1.0
    let metadata: LibraryMetadata
    var isFavorite: Bool
    
    enum ContentType: String, CaseIterable, Codable {
        case course, video, article, bookmark, lesson, project, podcast
        
        var icon: String {
            switch self {
            case .course: return "book.closed"
            case .video: return "play.rectangle"
            case .article: return "doc.text"
            case .bookmark: return "bookmark"
            case .lesson: return "graduationcap"
            case .project: return "folder"
            case .podcast: return "mic"
            }
        }
        
        var color: Color {
            switch self {
            case .course: return DesignTokens.Colors.primary
            case .video: return DesignTokens.Colors.neonBlue
            case .article: return DesignTokens.Colors.neonPink
            case .bookmark: return DesignTokens.Colors.neonGreen
            case .lesson: return .orange
            case .project: return .purple
            case .podcast: return .mint
            }
        }
    }
    
    init(id: String = UUID().uuidString, contentId: String, title: String, description: String? = nil, contentType: ContentType, url: String? = nil, tags: [String] = [], savedAt: Date = Date(), progress: Double = 0.0, metadata: LibraryMetadata = LibraryMetadata(), isFavorite: Bool = false) {
        self.id = id
        self.contentId = contentId
        self.title = title
        self.description = description
        self.contentType = contentType
        self.url = url
        self.tags = tags
        self.savedAt = savedAt
        self.progress = progress
        self.metadata = metadata
        self.isFavorite = isFavorite
    }
}

struct LibraryMetadata: Codable {
    let duration: String?
    let difficulty: String?
    let rating: Double?
    let author: String?
    let dateCompleted: Date?
    let notes: String?
    let thumbnailURL: String?
    
    init(duration: String? = nil, difficulty: String? = nil, rating: Double? = nil, author: String? = nil, dateCompleted: Date? = nil, notes: String? = nil, thumbnailURL: String? = nil) {
        self.duration = duration
        self.difficulty = difficulty
        self.rating = rating
        self.author = author
        self.dateCompleted = dateCompleted
        self.notes = notes
        self.thumbnailURL = thumbnailURL
    }
}

struct LibraryCollection {
    let id: String
    let name: String
    let description: String
    let items: [LibraryItem]
    let createdAt: Date
    var isDefault: Bool
    
    init(id: String = UUID().uuidString, name: String, description: String, items: [LibraryItem] = [], createdAt: Date = Date(), isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.items = items
        self.createdAt = createdAt
        self.isDefault = isDefault
    }
}

// MARK: - Library API Service

@MainActor
class LibraryAPIService: ObservableObject {
    private let baseURL = LyoConfiguration.backendURL
    
    func getLibrary(category: String? = nil) async throws -> [LibraryItem] {
        var urlString = "\(baseURL)/api/v1/library"
        if let category = category {
            urlString += "?category=\(category)"
        }
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode([String: [LibraryItem]].self, from: data)
        return response["library"] ?? []
    }
    
    func saveToLibrary(contentId: String, title: String, description: String?, contentType: LibraryItem.ContentType, url: String?) async throws -> LibraryItem {
        guard let requestURL = URL(string: "\(baseURL)/api/v1/library/save") else {
            throw URLError(.badURL)
        }
        
        let saveRequest = [
            "content_id": contentId,
            "title": title,
            "description": description as Any,
            "content_type": contentType.rawValue,
            "url": url as Any
        ] as [String : Any]
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: saveRequest)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: LibraryItem].self, from: data)
        return response["item"]!
    }
    
    func removeFromLibrary(itemId: String) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/library/\(itemId)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        _ = try await URLSession.shared.data(for: request)
    }
    
    func updateProgress(itemId: String, progress: Double) async throws {
        guard let url = URL(string: "\(baseURL)/api/v1/library/\(itemId)/progress") else {
            throw URLError(.badURL)
        }
        
        let progressUpdate = ["progress": progress]
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: progressUpdate)
        
        _ = try await URLSession.shared.data(for: request)
    }
}

// MARK: - Library ViewModel

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var libraryItems: [LibraryItem] = []
    @Published var collections: [LibraryCollection] = []
    @Published var selectedCategory = "All"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    @Published var sortBy: SortOption = .recent
    @Published var showingAddCollection = false
    @Published var selectedItem: LibraryItem?
    
    private let apiService = LibraryAPIService()
    
    enum SortOption: String, CaseIterable {
        case recent = "Recent"
        case alphabetical = "A-Z"
        case progress = "Progress"
        case type = "Type"
        case rating = "Rating"
    }
    
    private let categories = ["All", "Courses", "Videos", "Articles", "Bookmarks", "Projects", "Lessons", "Podcasts"]
    
    init() {
        Task {
            await loadLibrary()
        }
        setupDefaultCollections()
    }
    
    func loadLibrary() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if !LyoConfiguration.enableMockData {
                let category = selectedCategory == "All" ? nil : selectedCategory.lowercased()
                libraryItems = try await apiService.getLibrary(category: category)
            } else {
                libraryItems = generateMockLibraryItems()
            }
        } catch {
            errorMessage = "Failed to load library: \(error.localizedDescription)"
            libraryItems = generateMockLibraryItems() // Fallback
        }
    }
    
    func saveItem(contentId: String, title: String, description: String?, contentType: LibraryItem.ContentType, url: String?) async {
        do {
            if !LyoConfiguration.enableMockData {
                let savedItem = try await apiService.saveToLibrary(
                    contentId: contentId,
                    title: title,
                    description: description,
                    contentType: contentType,
                    url: url
                )
                libraryItems.insert(savedItem, at: 0)
            } else {
                // Mock save
                let mockItem = LibraryItem(
                    contentId: contentId,
                    title: title,
                    description: description,
                    contentType: contentType,
                    url: url
                )
                libraryItems.insert(mockItem, at: 0)
            }
        } catch {
            errorMessage = "Failed to save item: \(error.localizedDescription)"
        }
    }
    
    func removeItem(_ item: LibraryItem) async {
        do {
            if !LyoConfiguration.enableMockData {
                try await apiService.removeFromLibrary(itemId: item.id)
            }
            libraryItems.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to remove item: \(error.localizedDescription)"
        }
    }
    
    func updateProgress(for item: LibraryItem, progress: Double) async {
        do {
            if !LyoConfiguration.enableMockData {
                try await apiService.updateProgress(itemId: item.id, progress: progress)
            }
            
            if let index = libraryItems.firstIndex(where: { $0.id == item.id }) {
                libraryItems[index] = LibraryItem(
                    id: item.id,
                    contentId: item.contentId,
                    title: item.title,
                    description: item.description,
                    contentType: item.contentType,
                    url: item.url,
                    tags: item.tags,
                    savedAt: item.savedAt,
                    progress: progress,
                    metadata: item.metadata,
                    isFavorite: item.isFavorite
                )
            }
        } catch {
            errorMessage = "Failed to update progress: \(error.localizedDescription)"
        }
    }
    
    func toggleFavorite(for item: LibraryItem) {
        if let index = libraryItems.firstIndex(where: { $0.id == item.id }) {
            libraryItems[index] = LibraryItem(
                id: item.id,
                contentId: item.contentId,
                title: item.title,
                description: item.description,
                contentType: item.contentType,
                url: item.url,
                tags: item.tags,
                savedAt: item.savedAt,
                progress: item.progress,
                metadata: item.metadata,
                isFavorite: !item.isFavorite
            )
        }
    }
    
    private func setupDefaultCollections() {
        collections = [
            LibraryCollection(name: "Favorites", description: "Your favorite content", isDefault: true),
            LibraryCollection(name: "In Progress", description: "Content you're currently learning", isDefault: true),
            LibraryCollection(name: "Completed", description: "Content you've finished", isDefault: true),
            LibraryCollection(name: "Watch Later", description: "Content to review later", isDefault: true)
        ]
    }
    
    var filteredItems: [LibraryItem] {
        var filtered = libraryItems
        
        // Filter by category
        if selectedCategory != "All" {
            let categoryType = LibraryItem.ContentType(rawValue: selectedCategory.lowercased().dropLast()) // Remove 's' from plural
            filtered = filtered.filter { $0.contentType == categoryType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.description?.localizedCaseInsensitiveContains(searchText) == true ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort
        switch sortBy {
        case .recent:
            filtered.sort { $0.savedAt > $1.savedAt }
        case .alphabetical:
            filtered.sort { $0.title < $1.title }
        case .progress:
            filtered.sort { $0.progress > $1.progress }
        case .type:
            filtered.sort { $0.contentType.rawValue < $1.contentType.rawValue }
        case .rating:
            filtered.sort { ($0.metadata.rating ?? 0) > ($1.metadata.rating ?? 0) }
        }
        
        return filtered
    }
    
    private func generateMockLibraryItems() -> [LibraryItem] {
        return [
            LibraryItem(
                contentId: "course_1",
                title: "SwiftUI Mastery Course",
                description: "Complete guide to building iOS apps with SwiftUI",
                contentType: .course,
                url: "/courses/swiftui-mastery",
                tags: ["swiftui", "ios", "programming"],
                savedAt: Date().addingTimeInterval(-86400),
                progress: 0.65,
                metadata: LibraryMetadata(
                    duration: "8 hours",
                    difficulty: "Intermediate",
                    rating: 4.8,
                    author: "John Smith",
                    thumbnailURL: "https://picsum.photos/300/200?random=1"
                )
            ),
            LibraryItem(
                contentId: "video_1",
                title: "Introduction to Machine Learning",
                description: "Basics of ML algorithms and applications",
                contentType: .video,
                url: "/videos/ml-intro",
                tags: ["machine learning", "ai", "python"],
                savedAt: Date().addingTimeInterval(-172800),
                progress: 0.0,
                metadata: LibraryMetadata(
                    duration: "45 minutes",
                    difficulty: "Beginner",
                    rating: 4.6,
                    author: "Dr. Sarah Johnson",
                    thumbnailURL: "https://picsum.photos/300/200?random=2"
                )
            ),
            LibraryItem(
                contentId: "article_1",
                title: "Best Practices for Clean Code",
                description: "How to write maintainable and readable code",
                contentType: .article,
                url: "/articles/clean-code",
                tags: ["clean code", "programming", "best practices"],
                savedAt: Date().addingTimeInterval(-259200),
                progress: 1.0,
                metadata: LibraryMetadata(
                    duration: "10 min read",
                    rating: 4.9,
                    author: "Robert Martin",
                    dateCompleted: Date().addingTimeInterval(-172800),
                    thumbnailURL: "https://picsum.photos/300/200?random=3"
                ),
                isFavorite: true
            ),
            LibraryItem(
                contentId: "project_1",
                title: "Build a Weather App",
                description: "Step-by-step project to create a weather application",
                contentType: .project,
                url: "/projects/weather-app",
                tags: ["project", "ios", "api"],
                savedAt: Date().addingTimeInterval(-345600),
                progress: 0.3,
                metadata: LibraryMetadata(
                    duration: "2 weeks",
                    difficulty: "Advanced",
                    rating: 4.7,
                    author: "Alex Chen",
                    thumbnailURL: "https://picsum.photos/300/200?random=4"
                )
            )
        ]
    }
}

// MARK: - Professional Library View

struct ProfessionalLibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingItemDetail = false
    @State private var showingSort = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                searchAndFilterView
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.filteredItems.isEmpty {
                    emptyStateView
                } else {
                    libraryContentView
                }
            }
            .background(DesignTokens.Colors.primaryBg)
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadLibrary()
        }
        .sheet(item: $viewModel.selectedItem) { item in
            LibraryItemDetailView(item: item, viewModel: viewModel)
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
            
            VStack(spacing: 4) {
                Text("Your Library")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text("\(viewModel.filteredItems.count) items")
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Spacer()
            
            HStack(spacing: DesignTokens.Spacing.sm) {
                Button(action: { showingSort.toggle() }) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 18))
                        .foregroundColor(DesignTokens.Colors.primary)
                }
                
                Menu {
                    Button("Add Collection") { viewModel.showingAddCollection = true }
                    Button("Import from URL") { }
                    Button("Export Library") { }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 18))
                        .foregroundColor(DesignTokens.Colors.primary)
                }
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.top, DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg)
    }
    
    // MARK: - Search and Filter View
    
    private var searchAndFilterView: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                
                TextField("Search your library...", text: $viewModel.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(DesignTokens.Typography.body)
                
                if !viewModel.searchText.isEmpty {
                    Button(action: { viewModel.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                    }
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
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    ForEach(["All", "Courses", "Videos", "Articles", "Bookmarks", "Projects"], id: \.self) { category in
                        Button(action: {
                            viewModel.selectedCategory = category
                            Task {
                                await viewModel.loadLibrary()
                            }
                        }) {
                            Text(category)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(viewModel.selectedCategory == category ? .white : DesignTokens.Colors.textSecondary)
                                .padding(.horizontal, DesignTokens.Spacing.md)
                                .padding(.vertical, DesignTokens.Spacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                        .fill(viewModel.selectedCategory == category ? DesignTokens.Colors.primary : Color.clear)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                                                .stroke(viewModel.selectedCategory == category ? Color.clear : DesignTokens.Colors.glassBorder, lineWidth: 1)
                                        )
                                )
                        }
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.lg)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.lg)
        .padding(.bottom, DesignTokens.Spacing.md)
    }
    
    // MARK: - Content Views
    
    private var loadingView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(DesignTokens.Colors.primary)
            
            Text("Loading your library...")
                .font(DesignTokens.Typography.body)
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Spacer()
            
            Image(systemName: "books.vertical")
                .font(.system(size: 60))
                .foregroundColor(DesignTokens.Colors.primary.opacity(0.6))
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text(viewModel.searchText.isEmpty ? "Your Library is Empty" : "No Results Found")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Text(viewModel.searchText.isEmpty ? 
                     "Start saving courses, videos, and articles to build your personal learning hub" :
                     "Try adjusting your search terms or category filter"
                )
                    .font(DesignTokens.Typography.body)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if viewModel.searchText.isEmpty {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Explore Content")
                    }
                    .font(DesignTokens.Typography.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignTokens.Spacing.lg)
                    .padding(.vertical, DesignTokens.Spacing.md)
                    .background(DesignTokens.Colors.primary)
                    .cornerRadius(DesignTokens.Radius.button)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignTokens.Spacing.xl)
    }
    
    private var libraryContentView: some View {
        ScrollView {
            LazyVStack(spacing: DesignTokens.Spacing.md) {
                ForEach(viewModel.filteredItems) { item in
                    LibraryItemCardView(item: item, viewModel: viewModel) {
                        viewModel.selectedItem = item
                    }
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
        }
    }
}

// MARK: - Library Item Card View

struct LibraryItemCardView: View {
    let item: LibraryItem
    @ObservedObject var viewModel: LibraryViewModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.md) {
                // Thumbnail or icon
                AsyncImage(url: URL(string: item.metadata.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                        .fill(item.contentType.color.opacity(0.2))
                        .overlay(
                            Image(systemName: item.contentType.icon)
                                .font(.system(size: 24))
                                .foregroundColor(item.contentType.color)
                        )
                }
                .frame(width: 80, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.sm))
                
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    HStack {
                        Text(item.contentType.rawValue.capitalized)
                            .font(DesignTokens.Typography.caption)
                            .foregroundColor(item.contentType.color)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            if item.isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                            
                            if item.progress > 0 {
                                Image(systemName: item.progress >= 1.0 ? "checkmark.circle.fill" : "clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(item.progress >= 1.0 ? .green : .orange)
                            }
                        }
                    }
                    
                    Text(item.title)
                        .font(DesignTokens.Typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    if let description = item.description {
                        Text(description)
                            .font(DesignTokens.Typography.body)
                            .foregroundColor(DesignTokens.Colors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    
                    HStack {
                        if let author = item.metadata.author {
                            Text(author)
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        if let duration = item.metadata.duration {
                            Text("• \(duration)")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        if item.progress > 0 && item.progress < 1.0 {
                            Text("\(Int(item.progress * 100))%")
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.primary)
                        }
                    }
                    
                    // Progress bar
                    if item.progress > 0 && item.progress < 1.0 {
                        ProgressView(value: item.progress)
                            .tint(DesignTokens.Colors.primary)
                            .scaleEffect(x: 1, y: 0.8)
                    }
                }
                
                Button(action: { viewModel.toggleFavorite(for: item) }) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 18))
                        .foregroundColor(item.isFavorite ? .red : DesignTokens.Colors.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
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

// MARK: - Library Item Detail View

struct LibraryItemDetailView: View {
    let item: LibraryItem
    @ObservedObject var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingProgressUpdate = false
    @State private var newProgress: Double = 0.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                    // Header image
                    AsyncImage(url: URL(string: item.metadata.thumbnailURL ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(item.contentType.color.opacity(0.2))
                            .overlay(
                                Image(systemName: item.contentType.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(item.contentType.color)
                            )
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Radius.md))
                    
                    // Content details
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                        HStack {
                            Label(item.contentType.rawValue.capitalized, systemImage: item.contentType.icon)
                                .font(DesignTokens.Typography.bodyMedium)
                                .foregroundColor(item.contentType.color)
                            
                            Spacer()
                            
                            Button(action: { viewModel.toggleFavorite(for: item) }) {
                                Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 20))
                                    .foregroundColor(item.isFavorite ? .red : DesignTokens.Colors.textSecondary)
                            }
                        }
                        
                        Text(item.title)
                            .font(DesignTokens.Typography.title1)
                            .fontWeight(.bold)
                            .foregroundColor(DesignTokens.Colors.textPrimary)
                        
                        if let description = item.description {
                            Text(description)
                                .font(DesignTokens.Typography.body)
                                .foregroundColor(DesignTokens.Colors.textSecondary)
                        }
                        
                        // Progress section
                        if item.progress > 0 {
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                HStack {
                                    Text("Progress")
                                        .font(DesignTokens.Typography.bodyMedium)
                                        .foregroundColor(DesignTokens.Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(item.progress * 100))%")
                                        .font(DesignTokens.Typography.bodyMedium)
                                        .foregroundColor(DesignTokens.Colors.primary)
                                }
                                
                                ProgressView(value: item.progress)
                                    .tint(DesignTokens.Colors.primary)
                                
                                Button("Update Progress") {
                                    newProgress = item.progress
                                    showingProgressUpdate = true
                                }
                                .font(DesignTokens.Typography.caption)
                                .foregroundColor(DesignTokens.Colors.primary)
                            }
                            .padding(DesignTokens.Spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                                    .fill(DesignTokens.Colors.glassOverlay)
                            )
                        }
                        
                        // Metadata
                        metadataView
                        
                        // Action buttons
                        actionButtonsView
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.primaryBg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Share") { }
                        Button("Export") { }
                        Button("Remove from Library", role: .destructive) {
                            Task {
                                await viewModel.removeItem(item)
                                dismiss()
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingProgressUpdate) {
            ProgressUpdateView(progress: $newProgress) {
                Task {
                    await viewModel.updateProgress(for: item, progress: newProgress)
                }
                showingProgressUpdate = false
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
                if let author = item.metadata.author {
                    MetadataItemView(icon: "person.fill", title: "Author", value: author)
                }
                
                if let duration = item.metadata.duration {
                    MetadataItemView(icon: "clock", title: "Duration", value: duration)
                }
                
                if let difficulty = item.metadata.difficulty {
                    MetadataItemView(icon: "chart.bar", title: "Difficulty", value: difficulty)
                }
                
                if let rating = item.metadata.rating {
                    MetadataItemView(icon: "star.fill", title: "Rating", value: String(format: "%.1f/5", rating))
                }
                
                MetadataItemView(icon: "calendar", title: "Saved", value: DateFormatter.localizedString(from: item.savedAt, dateStyle: .medium, timeStyle: .none))
                
                if let completed = item.metadata.dateCompleted {
                    MetadataItemView(icon: "checkmark.circle", title: "Completed", value: DateFormatter.localizedString(from: completed, dateStyle: .medium, timeStyle: .none))
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
                    Image(systemName: item.progress >= 1.0 ? "arrow.clockwise" : "play.fill")
                    Text(item.progress >= 1.0 ? "Review" : "Continue Learning")
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
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "note.text")
                        Text("Notes")
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

struct MetadataItemView: View {
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

struct ProgressUpdateView: View {
    @Binding var progress: Double
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                Text("Update Progress")
                    .font(DesignTokens.Typography.title2)
                    .fontWeight(.bold)
                
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("\(Int(progress * 100))%")
                        .font(DesignTokens.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(DesignTokens.Colors.primary)
                    
                    Slider(value: $progress, in: 0...1, step: 0.05)
                        .tint(DesignTokens.Colors.primary)
                    
                    HStack {
                        Text("0%")
                        Spacer()
                        Text("100%")
                    }
                    .font(DesignTokens.Typography.caption)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                .padding(DesignTokens.Spacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .fill(DesignTokens.Colors.glassOverlay)
                )
                
                Spacer()
                
                Button("Save Progress") {
                    onSave()
                }
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.primary)
                .cornerRadius(DesignTokens.Radius.button)
            }
            .padding(DesignTokens.Spacing.lg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Backwards Compatibility (for existing header usage)

struct LibraryView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ProfessionalLibraryView()
    }
}
