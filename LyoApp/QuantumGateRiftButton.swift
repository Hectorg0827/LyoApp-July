import SwiftUI

/// Quantum Learning Gate - Organic Energy Rift Button
struct QuantumGateRiftButton: View {
    @State private var expansion: CGFloat = 0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Rift border
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [Color.purple, Color.blue, Color.purple],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .scaleEffect(1 + expansion)
                .opacity(Double(1 - expansion))
            
            // Vortex swirl of knowledge symbols
            if expansion > 0.1 {
                VortexSwirl(progress: expansion)
            }
        }
        .frame(width: 50, height: 50)
        .onTapGesture { triggerRift() }
    }
    
    private func triggerRift() {
        withAnimation(.easeOut(duration: 0.6)) { expansion = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            appState.presentAvatar()
        }
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

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        QuantumGateRiftButton()
            .environmentObject(AppState())
    }
}
