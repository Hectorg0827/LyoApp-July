import SwiftUI

/// Quantum Learning Gate - Organic Energy Rift Button
struct FloatingActionButton: View {
    @State private var expansion: CGFloat = 0
    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 75, y: UIScreen.main.bounds.height - 250)
    @State private var isDragging = false
    @GestureState private var dragOffset = CGSize.zero
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            backgroundGlow
            riftBorder
            centralContent
            
            // Vortex swirl of knowledge symbols (appears during expansion)
            if expansion > 0.1 {
                VortexSwirl(progress: expansion)
            }
        }
        .frame(width: 60, height: 60)
        .position(
            x: position.x + dragOffset.width,
            y: position.y + dragOffset.height
        )
        .gesture(dragGesture)
        .onTapGesture { 
            if !isDragging {
                triggerRift() 
            }
        }
        .onAppear {
            startIdleAnimation()
        }
        .accessibilityLabel("Open AI learning portal")
        .accessibilityHint("Tap to open learning gateway with electrifying effect")
    }
    
    // MARK: - UI Components
    private var backgroundGlow: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.blue.opacity(0.2),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 25,
                    endRadius: 50
                )
            )
            .scaleEffect(1.2 + expansion * 0.5)
            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: expansion)
    }
    
    private var riftBorder: some View {
        Circle()
            .strokeBorder(
                AngularGradient(
                    colors: [
                        Color.purple, 
                        Color.cyan, 
                        Color.pink, 
                        Color.blue, 
                        Color.purple
                    ],
                    center: .center
                ),
                lineWidth: 4
            )
            .scaleEffect(1 + expansion * 0.3)
            .opacity(Double(1 - expansion * 0.3))
            .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: expansion)
    }
    
    private var centralContent: some View {
        ZStack {
            // Electricity radiating only when opening
            QuantumElectricity(progress: expansion, isActive: expansion > 0.1)

            // "Lyo" text
            Text("Lyo")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.cyan, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .cyan, radius: 3)
                .scaleEffect(1 + expansion * 0.2)
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                state = value.translation
                if !isDragging {
                    isDragging = true
                }
            }
            .onEnded { value in
                isDragging = false
                
                // Calculate new position with bounds checking
                let newX = position.x + value.translation.width
                let newY = position.y + value.translation.height
                
                // Keep button within screen bounds with padding
                let padding: CGFloat = 50
                let boundsX = max(padding, min(UIScreen.main.bounds.width - padding, newX))
                let boundsY = max(padding + 100, min(UIScreen.main.bounds.height - padding - 120, newY))
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    position = CGPoint(x: boundsX, y: boundsY)
                }
            }
    }
    
    // MARK: - Trigger Rift Action
    private func triggerRift() {
        // Add haptic feedback
        HapticManager.shared.medium()
        
        // Start rift animation
        withAnimation(.easeOut(duration: 0.6)) { expansion = 1 }
        
        // Present avatar after brief animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.presentAvatar()
            HapticManager.shared.success()
        }
        
        // Reset rift after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeIn(duration: 0.3)) {
                expansion = 0
            }
        }
    }
   
    /// Idle pulse so it feels alive even when not tapped
    private func startIdleAnimation() {
        expansion = 0
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            expansion = 0.15
        }
    }
    
    // MARK: - Supporting Views
    /// Quantum electricity radiating from the center
    struct QuantumElectricity: View {
        let progress: CGFloat
        let isActive: Bool
        @State private var electricityAnimation: CGFloat = 0
        
        var body: some View {
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    ElectricBolt(
                        angle: Double(index) * 45,
                        intensity: isActive ? electricityAnimation : 0,
                        progress: progress
                    )
                }
            }
            .opacity(isActive ? 1 : 0)
            .onAppear {
                withAnimation(.linear(duration: 0.5).repeatForever(autoreverses: true)) {
                    electricityAnimation = 1.0
                }
            }
        }
    }

    /// Individual electric bolt radiating from center
    struct ElectricBolt: View {
        let angle: Double
        let intensity: CGFloat
        let progress: CGFloat
        
        var body: some View {
            Path { path in
                let centerX: CGFloat = 25
                let centerY: CGFloat = 25
                let startRadius: CGFloat = 8
                let endRadius: CGFloat = 20 + progress * 10
                
                // Starting point near center
                let startX = centerX + cos(angle * .pi / 180) * startRadius
                let startY = centerY + sin(angle * .pi / 180) * startRadius
                
                // End point on circle edge
                let endX = centerX + cos(angle * .pi / 180) * endRadius
                let endY = centerY + sin(angle * .pi / 180) * endRadius
                
                // Create zigzag lightning bolt
                path.move(to: CGPoint(x: startX, y: startY))
                
                let segments = 3
                for i in 1...segments {
                    let t = CGFloat(i) / CGFloat(segments)
                    let midX = startX + (endX - startX) * t
                    let midY = startY + (endY - startY) * t
                    
                    // Add random zigzag offset
                    let zigzagOffset = sin(t * .pi * 4) * 3 * intensity
                    let offsetX = midX + cos((angle + 90) * .pi / 180) * zigzagOffset
                    let offsetY = midY + sin((angle + 90) * .pi / 180) * zigzagOffset
                    
                    path.addLine(to: CGPoint(x: offsetX, y: offsetY))
                }
                
                path.addLine(to: CGPoint(x: endX, y: endY))
            }
            .stroke(
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.8),
                        Color.white,
                        Color.purple.opacity(0.6)
                    ],
                    startPoint: .center,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5 * intensity, lineCap: .round)
            )
            .opacity(Double(intensity * (0.7 + progress * 0.3)))
            .shadow(color: .cyan, radius: 2 * intensity)
        }
    }

    /// Swirling knowledge symbols along a vortex path
    struct VortexSwirl: View {
        let progress: CGFloat
        private let symbols = ["📚", "⚛️", "🧠", "💡", "🔍", "📈", "🧪", "🤖"]
        
        var body: some View {
            ZStack {
                ForEach(Array(symbols.enumerated()), id: \.offset) { idx, symbol in
                    let angle = Double(idx) / Double(symbols.count) * 360 + Double(progress) * 360
                    let radius = 30 * progress
                    let x = cos(angle * .pi / 180) * radius
                    let y = sin(angle * .pi / 180) * radius
                    Text(symbol)
                        .font(.system(size: 16))
                        .opacity(Double(min(1, progress * 2)))
                        .position(x: 25 + x, y: 25 + y)
                }
            }
            .frame(width: 50, height: 50)
        }
    }
}
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        FloatingActionButton()
            .environmentObject(AppState())
    }
}