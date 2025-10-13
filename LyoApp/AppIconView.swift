import SwiftUI

/// Programmatic App Icon generator for consistent branding
struct AppIconView: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                    Color(red: 0.05, green: 0.05, blue: 0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .frame(width: size * 0.8, height: size * 0.8)
                
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: size * 0.6, height: size * 0.6)
            }
            
            // Main lightbulb icon
            Image(systemName: "lightbulb.fill")
                .font(.system(size: size * 0.35, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.8, blue: 1.0),
                            Color(red: 0.0, green: 0.6, blue: 0.8)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0.0, green: 0.6, blue: 0.8).opacity(0.5), radius: size * 0.02, x: 0, y: size * 0.01)
            
            // Glow effect
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.0, green: 0.7, blue: 0.9).opacity(0.3),
                            Color.clear
                        ]),
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.4
                    )
                )
                .frame(width: size * 0.8, height: size * 0.8)
                .blendMode(.overlay)
        }
        .frame(width: size, height: size)
        .cornerRadius(size * 0.2237) // iOS app icon corner radius ratio
    }
}

#Preview {
    Group {
        AppIconView(size: 1024)
            .frame(width: 200, height: 200)
        
        AppIconView(size: 1024)
            .frame(width: 100, height: 100)
        
        AppIconView(size: 1024)
            .frame(width: 60, height: 60)
    }
    .padding()
}
