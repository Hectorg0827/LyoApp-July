import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject var container: AppContainer
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var trendingContent: [SearchResult] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: DesignTokens.Spacing.lg) {
                    // Search Bar
                    searchBar
                    
                    // Trending Section
                    if !trendingContent.isEmpty {
                        trendingSection
                    }
                    
                    // Categories Section
                    categoriesSection
                    
                    // Featured Content
                    featuredSection
                }
                .padding(DesignTokens.Spacing.lg)
            }
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadTrendingContent()
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DesignTokens.Colors.textSecondary)
            
            TextField("Search topics, courses, people...", text: $searchText)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .padding(DesignTokens.Spacing.md)
        .background(DesignTokens.Colors.glassBg)
        .cornerRadius(DesignTokens.Radius.md)
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
        )
    }
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Text("Trending Now")
                    .font(DesignTokens.Typography.headlineSmall)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to trending
                }
                .font(DesignTokens.Typography.labelMedium)
                .foregroundColor(DesignTokens.Colors.primary)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignTokens.Spacing.md) {
                    ForEach(Array(trendingContent.prefix(5)), id: \.id) { item in
                        TrendingCard(item: item)
                    }
                }
                .padding(.horizontal, DesignTokens.Spacing.xs)
            }
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Explore Categories")
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: DesignTokens.Spacing.md) {
                CategoryCard(title: "Technology", icon: "laptopcomputer", color: DesignTokens.Colors.primary)
                CategoryCard(title: "Science", icon: "flask", color: DesignTokens.Colors.accent)
                CategoryCard(title: "Arts", icon: "paintbrush", color: DesignTokens.Colors.success)
                CategoryCard(title: "Business", icon: "briefcase", color: DesignTokens.Colors.warning)
            }
        }
    }
    
    private var featuredSection: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Text("Featured Content")
                .font(DesignTokens.Typography.headlineSmall)
                .foregroundColor(DesignTokens.Colors.textPrimary)
            
            VStack(spacing: DesignTokens.Spacing.sm) {
                FeaturedCard(
                    title: "AI Revolution in Education",
                    subtitle: "How machine learning is transforming how we learn",
                    imageSystemName: "brain.head.profile"
                )
                
                FeaturedCard(
                    title: "Master Data Science",
                    subtitle: "Complete bootcamp with real-world projects",
                    imageSystemName: "chart.bar"
                )
            }
        }
    }
    
    private func loadTrendingContent() {
        isLoading = true
        
        Task {
            do {
                let results = try await container.searchService.trending()
                await MainActor.run {
                    self.trendingContent = results.items
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Mock trending data for now
                    self.trendingContent = generateMockTrending()
                    self.isLoading = false
                }
            }
        }
    }
    
    private func generateMockTrending() -> [SearchResult] {
        return [
            SearchResult(
                id: UUID().uuidString,
                title: "Swift Programming",
                description: "Learn iOS development",
                type: .course,
                relevanceScore: 0.95,
                metadata: [:]
            ),
            SearchResult(
                id: UUID().uuidString,
                title: "Machine Learning Basics",
                description: "Introduction to AI",
                type: .course,
                relevanceScore: 0.92,
                metadata: [:]
            ),
            SearchResult(
                id: UUID().uuidString,
                title: "Web Development",
                description: "Full-stack development",
                type: .course,
                relevanceScore: 0.88,
                metadata: [:]
            )
        ]
    }
}

struct TrendingCard: View {
    let item: SearchResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 24))
                .foregroundColor(DesignTokens.Colors.primary)
            
            Text(item.title)
                .font(DesignTokens.Typography.labelLarge)
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .lineLimit(2)
            
            Text(item.description)
                .font(DesignTokens.Typography.labelSmall)
                .foregroundColor(DesignTokens.Colors.textSecondary)
                .lineLimit(2)
        }
        .frame(width: 120)
        .padding(DesignTokens.Spacing.md)
        .cardStyle()
    }
}

struct CategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(title)
                .font(DesignTokens.Typography.titleSmall)
                .foregroundColor(DesignTokens.Colors.textPrimary)
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .cardStyle()
    }
}

struct FeaturedCard: View {
    let title: String
    let subtitle: String
    let imageSystemName: String
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            Image(systemName: imageSystemName)
                .font(.system(size: 40))
                .foregroundColor(DesignTokens.Colors.primary)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(title)
                    .font(DesignTokens.Typography.titleMedium)
                    .foregroundColor(DesignTokens.Colors.textPrimary)
                    .lineLimit(2)
                
                Text(subtitle)
                    .font(DesignTokens.Typography.bodySmall)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
                    .lineLimit(3)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(DesignTokens.Colors.textTertiary)
        }
        .padding(DesignTokens.Spacing.md)
        .cardStyle()
    }
}

#Preview {
    DiscoverView()
        .environmentObject(AppContainer.development())
}
