import SwiftUI

struct AISearchView: View {
    @State private var query = ""
    @State private var results: [AISearchResult] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(DesignTokens.Colors.neonBlue)
                TextField("Search topics, courses, or resources...", text: $query)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onSubmit { performSearch() }
            }
            .padding(DesignTokens.Spacing.sm)
            .background(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg).fill(DesignTokens.Colors.glassBg))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Radius.lg).stroke(DesignTokens.Colors.glassBorder))
            .padding(.horizontal)

            if isLoading {
                ProgressView().padding()
            } else if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
            } else if results.isEmpty && !query.isEmpty {
                Text("No results found.")
                    .foregroundColor(DesignTokens.Colors.gray400)
            } else {
                ScrollView {
                    LazyVStack(spacing: DesignTokens.Spacing.md) {
                        ForEach(results) { result in
                            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                                Text(result.title)
                                    .font(DesignTokens.Typography.body)
                                    .foregroundColor(DesignTokens.Colors.primary)
                                Text(result.summary)
                                    .font(DesignTokens.Typography.caption)
                                    .foregroundColor(DesignTokens.Colors.secondary)
                            }
                            .padding()
                            .background(DesignTokens.Colors.glassOverlay)
                            .cornerRadius(DesignTokens.Radius.md)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .background(DesignTokens.Colors.primaryBg)
        .onAppear { results = [] }
    }

    func performSearch() {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isLoading = true
        errorMessage = nil
        // Simulate async search
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // Replace with real API call
            if query.lowercased().contains("swift") {
                self.results = [AISearchResult(id: UUID(), title: "SwiftUI Basics", summary: "Learn to build modern iOS apps with SwiftUI.")]
            } else {
                self.results = []
            }
            self.isLoading = false
        }
    }
}

struct AISearchResult: Identifiable {
    let id: UUID
    let title: String
    let summary: String
}
