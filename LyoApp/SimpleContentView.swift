import SwiftUI

struct SimpleContentView: View {
    var body: some View {
        VStack {
            Text("🚀 LyoApp is working!")
                .font(.title)
                .foregroundColor(.blue)
                .padding()
            
            Text("This is a simple test view")
                .padding()
            
            Rectangle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 200, height: 100)
                .overlay(
                    Text("Red Rectangle")
                        .foregroundColor(.white)
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

#Preview {
    SimpleContentView()
}
