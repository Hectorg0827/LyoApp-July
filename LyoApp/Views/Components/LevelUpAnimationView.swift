import SwiftUI

/// Level up celebration animation overlay
struct LevelUpAnimationView: View {
    let newLevel: Int
    @Binding var isPresented: Bool
    
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -15
    @State private var confettiOpacity: Double = 0
    
    private var levelName: String {
        switch newLevel {
        case 1: return "Novice"
        case 2: return "Learner"
        case 3: return "Explorer"
        case 4: return "Achiever"
        case 5: return "Expert"
        case 6: return "Master"
        case 7: return "Virtuoso"
        case 8: return "Champion"
        case 9: return "Hero"
        case 10: return "Legend"
        default: return "Level \(newLevel)"
        }
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissAnimation()
                }
            
            // Confetti background
            ConfettiView()
                .opacity(confettiOpacity)
            
            // Main card
            VStack(spacing: 24) {
                // Level badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .purple.opacity(0.5), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 4) {
                        Text("LEVEL")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("\(newLevel)")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                
                // Level name
                VStack(spacing: 8) {
                    Text("Level Up!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                    
                    Text(levelName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(DesignTokens.Colors.textSecondary)
                }
                
                // Continue button
                Button {
                    dismissAnimation()
                } label: {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(DesignTokens.Colors.surfacePrimary)
                    .shadow(color: .black.opacity(0.3), radius: 30, y: 15)
            )
            .padding(.horizontal, 40)
            .opacity(opacity)
        }
        .onAppear {
            animateIn()
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismissAnimation()
            }
        }
    }
    
    private func animateIn() {
        // Stagger animations
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            rotation = 0
            opacity = 1.0
        }
        
        withAnimation(.easeIn(duration: 0.3).delay(0.2)) {
            confettiOpacity = 1.0
        }
    }
    
    private func dismissAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
            scale = 0.8
            confettiOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

// MARK: - Confetti View

struct ConfettiView: View {
    @State private var animate = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<30) { index in
                    ConfettiPiece(
                        color: [.purple, .blue, .yellow, .pink, .green, .orange].randomElement() ?? .purple,
                        size: CGFloat.random(in: 8...16),
                        x: CGFloat.random(in: 0...geometry.size.width),
                        delay: Double.random(in: 0...0.5)
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

struct ConfettiPiece: View {
    let color: Color
    let size: CGFloat
    let x: CGFloat
    let delay: Double
    
    @State private var yOffset: CGFloat = -100
    @State private var rotation: Double = 0
    @State private var opacity: Double = 1
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(x: x, y: yOffset)
            .onAppear {
                withAnimation(.linear(duration: Double.random(in: 2...4)).delay(delay)) {
                    yOffset = UIScreen.main.bounds.height + 100
                    rotation = Double.random(in: 0...720)
                    opacity = 0
                }
            }
    }
}

// MARK: - Preview

#Preview("Level Up Animation") {
    @Previewable @State var isPresented = true
    
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        if isPresented {
            LevelUpAnimationView(newLevel: 5, isPresented: $isPresented)
        }
    }
}
