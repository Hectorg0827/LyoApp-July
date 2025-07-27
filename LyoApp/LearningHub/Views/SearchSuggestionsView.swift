import SwiftUI
import Combine

// MARK: - Search Suggestions View Model
/// Manages the state for search suggestions.
class SearchSuggestionsViewModel: ObservableObject {
    @Published var suggestions: [String] = []
    
    init() {
        // In a real app, this would fetch suggestions from an API
        self.suggestions = [
            "SwiftUI Animation",
            "Combine Framework",
            "MVVM Architecture",
            "Async/Await in Swift"
        ]
    }
}

// MARK: - Search Suggestions View
/// Displays suggestions, recent searches, and popular topics.
struct SearchSuggestionsView: View {
    
    // MARK: - Properties
    let recentSearches: [String]
    let popularTopics: [String]
    let suggestions: [String]
    
    // MARK: - Actions
    let onSearchTap: (String) -> Void
    let onRemoveRecent: (String) -> Void
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 30) {
                // Recent Searches
                if !recentSearches.isEmpty {
                    suggestionSection(
                        title: "Recent Searches",
                        items: recentSearches,
                        icon: "clock.arrow.circlepath",
                        onRemove: onRemoveRecent
                    )
                }
                
                // Popular Topics
                suggestionSection(
                    title: "Popular Topics",
                    items: popularTopics,
                    icon: "flame.fill"
                )
                
                // AI Suggestions
                suggestionSection(
                    title: "AI Suggestions",
                    items: suggestions,
                    icon: "brain.head.profile"
                )
            }
            .padding()
        }
    }
    
    // MARK: - Suggestion Section
    private func suggestionSection(
        title: String,
        items: [String],
        icon: String,
        onRemove: ((String) -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Items
            ForEach(items, id: \.self) { item in
                HStack {
                    Text(item)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if let onRemove = onRemove {
                        Button(action: { onRemove(item) }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.vertical, 8)
                .onTapGesture {
                    onSearchTap(item)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SearchSuggestionsView(
        recentSearches: ["SwiftUI", "Core Data"],
        popularTopics: ["AI", "Machine Learning"],
        suggestions: ["Build a weather app", "Swift concurrency"],
        onSearchTap: { _ in },
        onRemoveRecent: { _ in }
    )
    .preferredColorScheme(.dark)
    .background(Color.black)
}
