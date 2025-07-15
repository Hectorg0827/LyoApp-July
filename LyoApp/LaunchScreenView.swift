import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var showText = false
    
    var body: some View {
        ZStack {
            // Background gradient matching app theme
            DesignTokens.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                // Animated Lyo Logo
                ZStack {
                    // Outer glow effect
                    Circle()
                        .fill(DesignTokens.Colors.primary.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0.5 : 0.8)
                        .animation(
                            .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // Main logo circle
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .frame(width: 120, height: 120)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                            value: isAnimating
                        )
                    
                    // Lightbulb icon
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                }
                
                // App title and tagline
                VStack(spacing: DesignTokens.Spacing.md) {
                    Text("Lyo")
                        .font(.system(size: 42, weight: .light, design: .rounded))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .opacity(showText ? 1.0 : 0.0)
                        .offset(y: showText ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.8).delay(0.5),
                            value: showText
                        )
                    
                    Text("AI-Powered Learning Companion")
                        .font(DesignTokens.Typography.title3)
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                        .opacity(showText ? 1.0 : 0.0)
                        .offset(y: showText ? 0 : 20)
                        .animation(
                            .easeOut(duration: 0.8).delay(0.8),
                            value: showText
                        )
                }
            }
            
            // Loading indicator at bottom
            VStack {
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(DesignTokens.Colors.primary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(isAnimating ? 1.0 : 0.6)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 60)
                .opacity(showText ? 1.0 : 0.0)
                .animation(
                    .easeOut(duration: 0.8).delay(1.1),
                    value: showText
                )
            }
        }
        .onAppear {
            isAnimating = true
            
            // Show text elements with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showText = true
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
