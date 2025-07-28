import SwiftUI

// MARK: - Search Header View
/// A dedicated header for the search interface.
struct SearchHeaderView: View {
    
    // MARK: - Bindings
    @Binding var searchText: String
    @Binding var isActive: Bool
    
    // MARK: - Actions
    var onTextChange: (String) -> Void
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search courses, topics, etc.", text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
                        onTextChange(newValue)
                    }
                    .foregroundColor(.white)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.1))
            .cornerRadius(25)
            
            // Cancel Button
            Button("Cancel") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isActive = false
                    searchText = ""
                }
            }
            .foregroundColor(.cyan)
        }
    }
}

// MARK: - Preview
#Preview {
    SearchHeaderView(
        searchText: .constant("SwiftUI"),
        isActive: .constant(true),
        onTextChange: { _ in }
    )
    .preferredColorScheme(.dark)
    .background(Color.black)
}
