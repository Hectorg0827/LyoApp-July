import SwiftUI

// MARK: - Enhanced Launch Screen with Quantum Lyo Branding
/// Professional launch screen for iOS submission
struct LaunchScreenView: View {
    @State private var animationPhase: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var ringScale: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color.black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Quantum energy rings
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8),
                                Color.cyan.opacity(0.3),
                                Color.cyan.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: CGFloat(80 + ring * 30), height: CGFloat(80 + ring * 30))
                    .rotationEffect(.degrees(animationPhase * Double(ring + 1) * 60.0))
                    .scaleEffect(ringScale)
                    .opacity(0.7)
            }
            
            // Central logo
            VStack(spacing: 16) {
                // "Lyo" text with quantum effect
                VStack(spacing: 8) {
                    Text("Lyo")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white,
                                    Color.cyan,
                                    Color.white
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .cyan, radius: 8, x: 0, y: 0)
                        .opacity(textOpacity)
                    
                    // Tagline
                    Text("AI-Powered Learning")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan.opacity(0.8))
                        .opacity(textOpacity * 0.8)
                }
                
                // Loading indicator
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { dot in
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 8, height: 8)
                            .scaleEffect(
                                sin(animationPhase * 2 + Double(dot) * 0.5) * 0.5 + 1.0
                            )
                            .opacity(0.8)
                    }
                }
                .opacity(textOpacity)
            }
            
            // Quantum particles
            ForEach(0..<12, id: \.self) { particle in
                Circle()
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(Double(particle) * .pi / 6 + animationPhase * 0.5) * 120,
                        y: sin(Double(particle) * .pi / 6 + animationPhase * 0.5) * 120
                    )
                    .opacity(0.6)
                    .scaleEffect(ringScale * 0.8)
            }
        }
        .onAppear {
            startLaunchAnimation()
        }
    }
    
    // MARK: - Launch Animation
    private func startLaunchAnimation() {
        // Phase 1: Rings appear
        withAnimation(.easeOut(duration: 0.8)) {
            ringScale = 1.0
        }
        
        // Phase 2: Text appears
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            textOpacity = 1.0
        }
        
        // Phase 3: Continuous rotation
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            animationPhase = 360
        }
    }
}

// MARK: - Alternative Minimal Launch Screen
struct MinimalLaunchScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Clean gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.1, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Simple logo
            VStack(spacing: 12) {
                // Quantum ring
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.cyan, Color.blue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 80, height: 80)
                    .overlay(
                        Text("Lyo")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                Text("Learning Hub")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.cyan.opacity(0.8))
                    .opacity(logoOpacity * 0.8)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}

// MARK: - Preview
#Preview("Launch Screen") {
    LaunchScreenView()
}

#Preview("Minimal Launch") {
    MinimalLaunchScreenView()
}
