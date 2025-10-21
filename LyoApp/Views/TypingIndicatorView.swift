import SwiftUI

struct TypingIndicatorView: View {
    @State private var animateScale = false
    @State private var animateOpacity = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(DesignTokens.Colors.primary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animateScale ? 1.2 : 0.8)
                            .opacity(animateOpacity ? 1.0 : 0.4)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: animateScale
                            )
                    }
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.glassBg)
                .cornerRadius(DesignTokens.Radius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.lg)
                        .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
                
                Text("Lyo is thinking...")
                    .font(DesignTokens.Typography.caption2)
                    .foregroundColor(DesignTokens.Colors.textSecondary)
            }
            
            Spacer()
        }
        .onAppear {
            animateScale = true
            animateOpacity = true
        }
    }
}

#Preview {
    TypingIndicatorView()
        .padding()
        .background(DesignTokens.Colors.primaryBg)
}