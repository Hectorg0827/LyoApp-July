import SwiftUI

/// Floating, draggable "Lyo" avatar button that can be summoned from anywhere in the app
struct FloatingActionButton: View {
    @State private var position = CGPoint(x: UIScreen.main.bounds.width - 40, y: UIScreen.main.bounds.height - 200)
    @State private var isDragging = false
    @State private var showingLyoModal = false
    @State private var scale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0
    @State private var pulseAnimation = false
    
    @GestureState private var dragOffset = CGSize.zero
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Lyo Avatar Button
            Button(action: {
                appState.presentAvatar()
            }) {
                ZStack {
                    // Background glow effect
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .frame(width: 60, height: 60)
                        .blur(radius: pulseAnimation ? 8 : 4)
                        .opacity(pulseAnimation ? 0.8 : 0.6)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    // Main button circle
                    Circle()
                        .fill(DesignTokens.Colors.primaryGradient)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle()
                                .strokeBorder(DesignTokens.Colors.glassBorder, lineWidth: 2)
                        )
                        .shadow(color: DesignTokens.Colors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    // Lyo avatar/icon
                    VStack(spacing: 2) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Lyo")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .rotationEffect(.degrees(rotationAngle))
                }
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(scale)
            .position(
                x: position.x + dragOffset.width,
                y: position.y + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                        
                        if !isDragging {
                            isDragging = true
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                scale = 1.1
                                rotationAngle = 10
                            }
                        }
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        // Calculate new position with bounds checking
                        let newX = position.x + value.translation.width
                        let newY = position.y + value.translation.height
                        
                        // Keep button within screen bounds with padding
                        let padding: CGFloat = 30
                        let boundsX = max(padding, min(UIScreen.main.bounds.width - padding, newX))
                        let boundsY = max(padding + 44, min(UIScreen.main.bounds.height - padding - 100, newY))
                        
                        // Snap to edges if close
                        let snapDistance: CGFloat = 100
                        let finalX: CGFloat
                        
                        if boundsX < snapDistance {
                            finalX = padding
                        } else if boundsX > UIScreen.main.bounds.width - snapDistance {
                            finalX = UIScreen.main.bounds.width - padding
                        } else {
                            finalX = boundsX
                        }
                        
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            position = CGPoint(x: finalX, y: boundsY)
                            scale = 1.0
                            rotationAngle = 0
                        }
                    }
            )
            .onAppear {
                // Start pulse animation
                pulseAnimation = true
                
                // Add subtle floating animation
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    position.y -= 10
                }
            }
            .onChange(of: appState.isLyoAwake) { _, activated in
                if activated {
                    appState.presentAvatar()
                }
            }
            .accessibilityLabel("Lyo AI Assistant")
            .accessibilityHint("Tap to open Lyo AI chat, drag to move button")
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