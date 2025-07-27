import SwiftUI

// MARK: - App Icon Generator for LyoApp
/// Generates the quantum "Lyo" branding app icon for iOS submission
struct AppIconGenerator: View {
    
    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.cyan.opacity(0.9),
                    Color.blue.opacity(0.7),
                    Color.purple.opacity(0.5),
                    Color.black
                ]),
                center: .center,
                startRadius: 20,
                endRadius: 120
            )
            
            // Quantum energy rings
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.8),
                                Color.cyan.opacity(0.2),
                                Color.cyan.opacity(0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(60 + ring * 20), height: CGFloat(60 + ring * 20))
                    .rotationEffect(.degrees(Double(ring * 120)))
                    .opacity(0.7)
            }
            
            // Central "Lyo" text with quantum effect
            VStack(spacing: 2) {
                Text("Lyo")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white,
                                Color.cyan.opacity(0.9),
                                Color.white
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan, radius: 4, x: 0, y: 0)
                
                // Knowledge symbol
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.cyan.opacity(0.8))
            }
            
            // Quantum particles/dots
            ForEach(0..<8, id: \.self) { particle in
                Circle()
                    .fill(Color.cyan.opacity(0.6))
                    .frame(width: 3, height: 3)
                    .offset(
                        x: cos(Double(particle) * .pi / 4) * 45,
                        y: sin(Double(particle) * .pi / 4) * 45
                    )
                    .opacity(0.8)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(
            RoundedRectangle(cornerRadius: 26)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .cyan.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - App Icon Preview and Export
struct AppIconPreview: View {
    
    var body: some View {
        VStack(spacing: 30) {
            Text("LyoApp Icon Preview")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 50)
            
            // Different sizes for iOS
            HStack(spacing: 20) {
                VStack {
                    AppIconGenerator()
                        .scaleEffect(1.0)
                    Text("120x120")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    AppIconGenerator()
                        .scaleEffect(0.75)
                    Text("90x90")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    AppIconGenerator()
                        .scaleEffect(0.5)
                    Text("60x60")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            // App Store size (1024x1024 - scaled down)
            VStack {
                AppIconGenerator()
                    .scaleEffect(2.0)
                Text("App Store (1024x1024)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 30)
            
            // Instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("📱 Icon Implementation Steps:")
                    .font(.headline)
                    .foregroundColor(.cyan)
                    .padding(.top, 30)
                
                Text("1. Open LyoApp.xcodeproj in Xcode")
                Text("2. Navigate to Assets.xcassets > AppIcon")
                Text("3. Replace placeholder icons with quantum Lyo design")
                Text("4. Generate all required sizes (20pt to 1024pt)")
                Text("5. Ensure all icons follow iOS design guidelines")
            }
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
    }
}

// MARK: - Preview
#Preview {
    AppIconPreview()
        .preferredColorScheme(.dark)
}
