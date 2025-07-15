import SwiftUI

struct TypingIndicator: View {
    @State private var animate = false
    var body: some View {
        HStack(spacing: 6) {
            if true {
                Circle()
                    .fill(DesignTokens.Colors.neonBlue)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animate ? 1.2 : 1)
                Circle()
                    .fill(DesignTokens.Colors.neonPurple)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animate ? 1.2 : 1)
                Circle()
                    .fill(DesignTokens.Colors.neonPink)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animate ? 1.2 : 1)
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 16).fill(DesignTokens.Colors.glassBg.opacity(0.7)))
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                animate = true
            }
        }
    }
}
