import SwiftUI

struct ContentView: View {
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🚀 LyoApp Content View")
                .font(.title)
                .foregroundColor(.blue)
                .padding()
            
            Text("Debug: ContentView loaded successfully")
                .foregroundColor(.red)
                .font(.caption)
            
            if isLoading {
                ProgressView("Loading...")
            } else {
                VStack {
                    Text("Welcome to LyoApp!")
                        .font(.headline)
                    
                    Rectangle()
                        .fill(Color.green.opacity(0.3))
                        .frame(width: 200, height: 100)
                        .overlay(
                            Text("Test Content")
                                .foregroundColor(.white)
                        )
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .onAppear {
            print("🔍 ContentView appeared")
        }
    }
}

#Preview {
    ContentView()
}
