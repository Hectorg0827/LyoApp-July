import SwiftUI

struct AISearchView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search courses, topics...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                performSearch()
                            }
                        
                        if !searchText.isEmpty {
                            Button("Clear") {
                                searchText = ""
                            }
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content
                    if isSearching {
                        VStack {
                            ProgressView()
                            Text("Searching...")
                                .foregroundColor(.white)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if searchText.isEmpty {
                        SearchSuggestionsViewSimple()
                    } else {
                        SearchResultsViewSimple()
                    }
                    
                    Spacer()
                }
                .navigationTitle("Search")
            }
        }
    }
    
    private func performSearch() {
        isSearching = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSearching = false
        }
    }
}

struct SearchSuggestionsViewSimple: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Popular Topics")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(["SwiftUI", "iOS Development", "Design", "Animation"], id: \.self) { topic in
                    Button(action: {
                        print("Selected topic: \(topic)")
                    }) {
                        Text(topic)
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.3))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

struct SearchResultsViewSimple: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<5) { index in
                    SearchResultCardSimple(title: "Result \(index + 1)")
                }
            }
            .padding()
        }
    }
}

struct SearchResultCardSimple: View {
    let title: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Course description here")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                print("View button tapped for \(title)")
            }) {
                Text("View")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
}

struct AISearchView_Previews: PreviewProvider {
    static var previews: some View {
        AISearchView()
            .preferredColorScheme(.dark)
    }
}
