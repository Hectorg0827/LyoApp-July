import SwiftUI

// MARK: - Search Results View
/// Displays the results of a learning content search.
struct SearchResultsView: View {
    
    // MARK: - Properties
    let results: [LearningResource]
    let isSearching: Bool
    let query: String
    let viewMode: LearningHubView.ViewMode
    
    // MARK: - Body
    var body: some View {
        VStack {
            if isSearching {
                // Loading state
                ProgressView("Searching for \"\(query)\"...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                    .foregroundColor(.white)
                    .padding(.top, 50)
                
                Spacer()
            } else if results.isEmpty {
                // No results state
                noResultsView
            } else {
                // Results content
                resultsListView
            }
        }
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Results for \"\(query)\"")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Try searching for something else or check your spelling.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 50)
    }
    
    // MARK: - Results List View
    private var resultsListView: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Header
                Text("\(results.count) results found")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding(.top)
                
                // Content based on view mode
                switch viewMode {
                case .grid:
                    gridLayout
                case .list:
                    listLayout
                case .card:
                    cardLayout
                }
            }
            .padding()
        }
    }
    
    // MARK: - Layouts
    
    private var gridLayout: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            ForEach(results) { resource in
                LearningResourceCard(resource: resource)
            }
        }
    }
    
    private var listLayout: some View {
        ForEach(results) { resource in
            LearningResourceRow(resource: resource)
        }
    }
    
    private var cardLayout: some View {
        ForEach(results) { resource in
            LearningResourceFeaturedCard(resource: resource)
        }
    }
}

// MARK: - Preview
#Preview {
    SearchResultsView(
        results: LearningResource.sampleResources,
        isSearching: false,
        query: "SwiftUI",
        viewMode: .grid
    )
    .preferredColorScheme(.dark)
    .background(Color.black)
}
