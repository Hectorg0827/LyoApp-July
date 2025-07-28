import SwiftUI

// MARK: - Search Header View (Alternative)
/// Alternative implementation - consider consolidating with SearchHeaderView.swift
struct SearchHeaderViewAlt: View {
    @Binding var searchText: String
    @Binding var isActive: Bool
    let onTextChange: (String) -> Void
    
    @State private var isVoiceRecording = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button when active
            if isActive {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isActive = false
                        isSearchFocused = false
                        searchText = ""
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            }
            
            // Search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                TextField("Search courses, tutorials, books...", text: $searchText)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .focused($isSearchFocused)
                    .onChange(of: searchText) { oldValue, newValue in
                        onTextChange(newValue)
                    }
                    .onSubmit {
                        // Handle search submission
                        print("🔍 SEARCH SUBMITTED: '\(searchText)'")
                    }
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        onTextChange("")
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Voice search button
                Button(action: toggleVoiceRecording) {
                    Image(systemName: isVoiceRecording ? "waveform" : "mic")
                        .font(.subheadline)
                        .foregroundColor(isVoiceRecording ? .red : .cyan)
                        .scaleEffect(isVoiceRecording ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isVoiceRecording)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
        .onAppear {
            if isActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
        }
    }
    
    private func toggleVoiceRecording() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isVoiceRecording.toggle()
        }
        
        if isVoiceRecording {
            // Start voice recording
            print("🎙️ VOICE: Starting voice recording")
            // TODO: Implement voice recognition
        } else {
            // Stop voice recording
            print("🎙️ VOICE: Stopping voice recording")
        }
    }
}

// MARK: - Recent Search Row
struct RecentSearchRow: View {
    let searchText: String
    let onTap: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onTap) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(searchText)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(width: 20, height: 20)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Popular Topic Chip
struct PopularTopicChip: View {
    let topic: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(topic)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange.opacity(0.3), Color.red.opacity(0.2)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - AI Suggestion Row
struct AISuggestionRow: View {
    let suggestion: SearchSuggestion
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                // Category Icon
                categoryIcon
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.text)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text(suggestion.category)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Popularity indicator
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            
                            Text("\(suggestion.popularity)%")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cyan.opacity(0.1))
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var categoryIcon: some View {
        Group {
            switch suggestion.category {
            case "Programming":
                Image(systemName: "chevron.left.forwardslash.chevron.right")
            case "AI/ML":
                Image(systemName: "brain.head.profile")
            case "Data Science":
                Image(systemName: "chart.bar")
            case "Design":
                Image(systemName: "paintbrush")
            case "Business":
                Image(systemName: "briefcase")
            default:
                Image(systemName: "book")
            }
        }
        .font(.subheadline)
        .foregroundColor(.cyan)
        .frame(width: 24, height: 24)
    }
}

// MARK: - Search Suggestion Model
struct SearchSuggestion: Identifiable {
    let id = UUID()
    let text: String
    let category: String
    let popularity: Int
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Search Results View (Alternative)
/// Alternative implementation - consider consolidating with SearchResultsView.swift
struct SearchResultsViewAlt: View {
    let results: [LearningResource]
    let isSearching: Bool
    let query: String
    let viewMode: LearningHubView.ViewMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Results Header
            if !isSearching && !results.isEmpty {
                resultsHeaderView
            }
            
            // Results Content
            if isSearching {
                searchingIndicatorView
            } else if results.isEmpty && !query.isEmpty {
                noResultsView
            } else {
                resultsContentView
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Results Header
    private var resultsHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(results.count) Results")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("for '\(query)'")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Filter button
            Button(action: {
                // Show filters
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.subheadline)
                    
                    Text("Filter")
                        .font(.subheadline)
                }
                .foregroundColor(.cyan)
            }
        }
    }
    
    // MARK: - Searching Indicator
    private var searchingIndicatorView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
            
            Text("Searching...")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: 200)
    }
    
    // MARK: - No Results View
    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No results found")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("Try different keywords or browse our categories")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            
            Button("Browse All Content") {
                // Navigate to browse
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cyan.opacity(0.2))
                    .stroke(Color.cyan, lineWidth: 1)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
    }
    
    // MARK: - Results Content
    private var resultsContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            switch viewMode {
            case .grid:
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(results) { resource in
                        LearningCardView(
                            resource: resource,
                            cardStyle: .compact,
                            onTap: {
                                // Handle resource selection
                                print("📱 SEARCH: Selected resource \(resource.title)")
                            }
                        )
                    }
                }
                
            case .list:
                LazyVStack(spacing: 12) {
                    ForEach(results) { resource in
                        LearningCardView(
                            resource: resource,
                            cardStyle: .wide,
                            onTap: {
                                // Handle resource selection
                                print("📱 SEARCH: Selected resource \(resource.title)")
                            }
                        )
                    }
                }
                
            case .card:
                LazyVStack(spacing: 16) {
                    ForEach(results) { resource in
                        LearningCardView(
                            resource: resource,
                            cardStyle: .standard,
                            onTap: {
                                // Handle resource selection
                                print("📱 SEARCH: Selected resource \(resource.title)")
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        SearchHeaderViewAlt(
            searchText: .constant("SwiftUI"),
            isActive: .constant(true),
            onTextChange: { _ in }
        )
        .padding()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
