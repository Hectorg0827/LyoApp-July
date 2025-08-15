import SwiftUI

// MARK: - Simple AI Smart Search View
struct AISmartSearchView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var aiService = GemmaService.shared
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Search Bar
                HStack {
                    TextField("Ask AI to search for learning resources...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("Search") {
                        performAISearch()
                    }
                    .disabled(searchText.isEmpty || isSearching)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                if isSearching {
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("AI is searching...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                // Results placeholder
                Text("AI-enhanced search results will appear here")
                    .foregroundColor(.secondary)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("AI Smart Search")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func performAISearch() {
        isSearching = true
        
        Task {
            // Simulate AI search
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                isSearching = false
            }
        }
    }
}

#Preview {
    AISmartSearchView()
        .environmentObject(AppState())
}
