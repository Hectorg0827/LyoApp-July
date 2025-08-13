import SwiftUI
import SwiftData

// MARK: - Production Learning API Service

@MainActor
class ProductionLearningAPIService: ObservableObject {
    @Published var isLoading = false
    @Published var resources: [LearningResource] = []
    @Published var errorMessage: String?
    
    func loadResources() async {
        isLoading = true
        defer { isLoading = false }
        
        // Mock implementation for production
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        resources = generateMockResources()
    }
    
    private func generateMockResources() -> [LearningResource] {
        return [
            LearningResource(
                id: UUID().uuidString,
                title: "Swift Programming Basics",
                description: "Learn the fundamentals of Swift programming language",
                contentType: "video",
                difficulty: "beginner",
                thumbnailURL: nil
            ),
            LearningResource(
                id: UUID().uuidString,
                title: "SwiftUI Advanced Techniques",
                description: "Master advanced SwiftUI concepts and patterns",
                contentType: "article",
                difficulty: "advanced",
                thumbnailURL: nil
            )
        ]
    }
}

// MARK: - Production Learning Hub View

struct ProductionLearningHubView: View {
    @StateObject private var apiService = ProductionLearningAPIService()
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var gemmaService = GemmaService.shared
    @StateObject private var playerService = ContentPlayerService.shared
    @StateObject private var downloadService = DownloadManagerService.shared
    @StateObject private var dataService = LearningDataService.shared
    
    @State private var selectedResource: LearningResource?
    @State private var showingResourceDetail = false
    @State private var showingDownloads = false
    @State private var showingSearch = false
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var isOfflineMode = false
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // AI-Powered Search
                    SearchBarView(
                        text: $searchText,
                        isAIEnabled: gemmaService.isModelLoaded,
                        onSearch: performSearch
                    )
                    
                    // Quick Stats & AI Insights
                    if gemmaService.isModelLoaded {
                        PersonalizedInsightsCard()
                    }
                    
                    // Category Filter
                    CategoryFilterView(selectedCategory: $selectedCategory)
                    
                    // Downloads Status (if any active)
                    if downloadService.activeDownloads > 0 {
                        DownloadStatusCard()
                    }
                    
                    // Offline Mode Toggle
                    OfflineModeToggle(isOfflineMode: $isOfflineMode)
                    
                    // Learning Resources
                    LearningResourcesSection(
                        isOfflineMode: isOfflineMode,
                        selectedCategory: selectedCategory,
                        searchText: searchText
                    )
                }
                .padding()
            }
            .navigationTitle("Learning Hub")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        // Downloads button
                        Button(action: { showingDownloads = true }) {
                            Image(systemName: "arrow.down.circle")
                                .overlay(
                                    downloadService.activeDownloads > 0 ?
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 8, y: -8)
                                    : nil
                                )
                        }
                        
                        // Search button
                        Button(action: { showingSearch = true }) {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingDownloads) {
                DownloadsView()
            }
            .sheet(isPresented: $showingSearch) {
                AISearchView()
            }
            .sheet(item: $selectedResource) { resource in
                LearningResourceDetailView(resource: resource)
            }
            .alert("Offline Mode", isPresented: .constant(isOfflineMode && !dataService.isInitialized)) {
                Button("OK") { }
            } message: {
                Text("You can only access downloaded content in offline mode.")
            }
        }
        .requiresAuthentication()
        .onAppear {
            initializeServices()
        }
    }
    
    private func initializeServices() {
        Task {
            await apiService.initialize()
            
            // Initialize data service if needed
            if !dataService.isInitialized {
                // This would be handled by SwiftData setup in the main app
                print("📊 Initializing data service...")
            }
        }
    }
    
    private func performSearch() {
        Task {
            let enhancedQuery = await gemmaService.enhanceSearchQuery(searchText)
            await apiService.searchResources(query: enhancedQuery)
        }
    }
}

// MARK: - Search Bar View

struct SearchBarView: View {
    @Binding var text: String
    let isAIEnabled: Bool
    let onSearch: () -> Void
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search learning resources...", text: $text)
                    .onSubmit(onSearch)
                
                if isAIEnabled {
                    Image(systemName: "brain")
                        .foregroundColor(.blue)
                        .help("AI-enhanced search enabled")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            if !text.isEmpty {
                Button("Search") {
                    onSearch()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Personalized Insights Card

struct PersonalizedInsightsCard: View {
    @StateObject private var gemmaService = GemmaService.shared
    @State private var insights: String = ""
    @State private var isLoadingInsights = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                Text("AI Insights")
                    .font(.headline)
                Spacer()
                
                if isLoadingInsights {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if !insights.isEmpty {
                Text(insights)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            } else {
                Text("Generating personalized insights...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onAppear {
            loadInsights()
        }
    }
    
    private func loadInsights() {
        guard insights.isEmpty else { return }
        
        isLoadingInsights = true
        
        Task {
            // Mock learning history for now
            let mockHistory = [LearningResource.mockVideo, LearningResource.mockCourse]
            let generatedInsights = await gemmaService.generatePersonalizedInsights(learningHistory: mockHistory)
            
            await MainActor.run {
                insights = generatedInsights
                isLoadingInsights = false
            }
        }
    }
}

// MARK: - Category Filter View

struct CategoryFilterView: View {
    @Binding var selectedCategory: String?
    
    private let categories = ["All", "Technology", "Business", "Design", "Science", "Arts"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == (category == "All" ? nil : category)
                    ) {
                        selectedCategory = category == "All" ? nil : category
                    }
                }
            }
            .padding(.horizontal)
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
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Download Status Card

struct DownloadStatusCard: View {
    @StateObject private var downloadService = DownloadManagerService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.down.circle")
                    .foregroundColor(.blue)
                Text("Downloads")
                    .font(.headline)
                Spacer()
                Text("\(downloadService.activeDownloads) active")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let activeDownload = downloadService.downloads.first(where: { $0.status == .downloading }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activeDownload.title)
                        .font(.subheadline)
                        .lineLimit(1)
                    
                    ProgressView(value: activeDownload.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    HStack {
                        Text("\(Int(activeDownload.progress * 100))%")
                            .font(.caption)
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: activeDownload.downloadedBytes, countStyle: .file))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Offline Mode Toggle

struct OfflineModeToggle: View {
    @Binding var isOfflineMode: Bool
    
    var body: some View {
        HStack {
            Image(systemName: isOfflineMode ? "wifi.slash" : "wifi")
                .foregroundColor(isOfflineMode ? .orange : .green)
            
            Text(isOfflineMode ? "Offline Mode" : "Online Mode")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Toggle("", isOn: $isOfflineMode)
                .labelsHidden()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Learning Resources Section

struct LearningResourcesSection: View {
    let isOfflineMode: Bool
    let selectedCategory: String?
    let searchText: String
    
    @StateObject private var apiService = ProductionLearningAPIService()
    @StateObject private var dataService = LearningDataService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Learning Resources")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                
                if apiService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if isOfflineMode {
                OfflineResourcesGrid()
            } else {
                OnlineResourcesGrid(
                    category: selectedCategory,
                    searchText: searchText
                )
            }
        }
    }
}

// MARK: - Resource Grids

struct OnlineResourcesGrid: View {
    let category: String?
    let searchText: String
    
    @StateObject private var apiService = ProductionLearningAPIService()
    
    var filteredResources: [LearningResource] {
        var resources = apiService.resources
        
        if let category = category {
            resources = resources.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            resources = resources.filter { 
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return resources
    }
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filteredResources) { resource in
                ProductionLearningResourceCard(resource: resource)
            }
        }
        .onAppear {
            Task {
                if category != nil || !searchText.isEmpty {
                    await apiService.loadResources()
                } else {
                    await apiService.loadResources()
                }
            }
        }
    }
}

struct OfflineResourcesGrid: View {
    @StateObject private var dataService = LearningDataService.shared
    @State private var offlineResources: [LearningResourceEntity] = []
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(offlineResources, id: \.id) { resourceEntity in
                // Convert entity to LearningResource for display
                let resource = LearningResource(
                    id: resourceEntity.id,
                    title: resourceEntity.title,
                    description: resourceEntity.description,
                    contentType: ContentType(rawValue: resourceEntity.contentType) ?? .article,
                    category: resourceEntity.category,
                    difficulty: LearningResource.Difficulty(rawValue: resourceEntity.difficulty) ?? .beginner,
                    estimatedDuration: resourceEntity.estimatedDuration,
                    rating: resourceEntity.rating,
                    thumbnailURL: resourceEntity.thumbnailURL,
                    contentURL: resourceEntity.localFilePath // Use local path for offline
                )
                
                ProductionLearningResourceCard(resource: resource, isOffline: true)
            }
        }
        .onAppear {
            loadOfflineResources()
        }
    }
    
    private func loadOfflineResources() {
        Task {
            do {
                let resources = try await dataService.fetchLearningResources()
                let downloadedResources = resources.filter { $0.isDownloaded }
                await MainActor.run {
                    offlineResources = downloadedResources
                }
            } catch {
                print("⚠️ Failed to load offline resources: \(error)")
            }
        }
    }
}

// MARK: - Production Learning Resource Card

struct ProductionLearningResourceCard: View {
    let resource: LearningResource
    let isOffline: Bool
    
    @StateObject private var gemmaService = GemmaService.shared
    @StateObject private var downloadService = DownloadManagerService.shared
    @State private var showingDetail = false
    @State private var aiSummary: String?
    @State private var isGeneratingSummary = false
    
    init(resource: LearningResource, isOffline: Bool = false) {
        self.resource = resource
        self.isOffline = isOffline
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Thumbnail and status
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: resource.thumbnailURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .overlay(
                            Image(systemName: resource.contentType.iconName)
                                .font(.title)
                                .foregroundColor(.secondary)
                        )
                }
                .frame(height: 120)
                .clipped()
                
                VStack(spacing: 4) {
                    // Download status
                    if isOffline {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else if let download = downloadService.downloads.first(where: { $0.resourceId == resource.id }) {
                        DownloadStatusIcon(status: download.status, progress: download.progress)
                    }
                    
                    // Content type
                    Image(systemName: resource.contentType.iconName)
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                // Title
                Text(resource.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                
                // AI Summary or Description
                if let summary = aiSummary {
                    Text(summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                } else {
                    Text(resource.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Metadata
                HStack {
                    if let duration = resource.estimatedDuration {
                        Label(duration, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let rating = resource.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text(String(format: "%.1f", rating))
                        }
                        .font(.caption2)
                    }
                }
                
                // Action Buttons
                HStack {
                    // Play/View Button
                    Button(action: { showingDetail = true }) {
                        HStack {
                            Image(systemName: resource.contentType == .video || resource.contentType == .podcast ? "play.fill" : "eye.fill")
                            Text(resource.contentType == .video || resource.contentType == .podcast ? "Play" : "View")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    Spacer()
                    
                    // Download Button (if online)
                    if !isOffline {
                        Button(action: downloadResource) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // AI Summary Button
                    if gemmaService.isModelLoaded {
                        Button(action: generateAISummary) {
                            Image(systemName: isGeneratingSummary ? "brain" : "sparkles")
                                .foregroundColor(aiSummary != nil ? .purple : .gray)
                        }
                        .disabled(isGeneratingSummary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onTapGesture {
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            LearningResourceDetailView(resource: resource)
        }
    }
    
    private func downloadResource() {
        Task {
            await downloadService.startDownload(for: resource)
        }
    }
    
    private func generateAISummary() {
        guard !isGeneratingSummary else { return }
        
        isGeneratingSummary = true
        
        Task {
            let summary = await resource.generateAISummary()
            await MainActor.run {
                aiSummary = summary
                isGeneratingSummary = false
            }
        }
    }
}

// MARK: - Download Status Icon

struct DownloadStatusIcon: View {
    let status: DownloadStatus
    let progress: Double
    
    var body: some View {
        ZStack {
            switch status {
            case .pending:
                Image(systemName: "clock")
                    .foregroundColor(.orange)
            case .downloading:
                CircularProgressView(progress: progress)
            case .paused:
                Image(systemName: "pause.circle")
                    .foregroundColor(.yellow)
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding(4)
        .background(Color.black.opacity(0.6))
        .clipShape(Circle())
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundColor(.white)
        }
        .frame(width: 24, height: 24)
    }
}

// MARK: - Extensions

extension ContentType {
    var iconName: String {
        switch self {
        case .video: return "play.rectangle"
        case .article: return "doc.text"
        case .podcast: return "waveform"
        case .document: return "doc"
        }
    }
}

#Preview {
    ProductionLearningHubView()
}
