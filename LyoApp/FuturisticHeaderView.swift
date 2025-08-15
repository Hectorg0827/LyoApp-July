import SwiftUI

// MARK: - Simple Futuristic Header
struct FuturisticHeaderView: View {
    @State private var showContent = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Lyo")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button(action: {}) {
                        Image(systemName: "plus.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "heart")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal)
            
            if showContent {
                Text("Stories loading...")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.body)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.black, Color.purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

#Preview {
    FuturisticHeaderView()
}
