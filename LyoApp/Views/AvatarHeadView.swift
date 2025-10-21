import SwiftUI

// MARK: - Avatar Head View

/// Animated avatar head that displays mood, expression, and speaking state
struct AvatarHeadView: View {
    let mood: AvatarMood
    let expression: AvatarExpression
    let isSpeaking: Bool
    
    @State private var breathingScale: CGFloat = 1.0
    @State private var blinkAnimation = false
    @State private var speakAnimation = false
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Background glow based on mood
            Circle()
                .fill(
                    RadialGradient(
                        colors: [moodColor.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .frame(width: 250, height: 250)
                .blur(radius: 20)
            
            // Avatar head circle
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.85, blue: 0.70),
                            Color(red: 0.90, green: 0.75, blue: 0.60)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 160, height: 160)
                .overlay(
                    Circle()
                        .stroke(moodColor.opacity(0.5), lineWidth: 4)
                )
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
                .scaleEffect(breathingScale)
            
            // Facial features
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 30)
                
                // Eyes
                HStack(spacing: 40) {
                    EyeView(isBlinking: blinkAnimation, expression: expression)
                    EyeView(isBlinking: blinkAnimation, expression: expression)
                }
                
                Spacer()
                    .frame(height: 15)
                
                // Mouth
                MouthView(expression: expression, isSpeaking: isSpeaking, speakAnimation: speakAnimation)
            }
            .frame(width: 160, height: 160)
            
            // Gesture indicators
            if expression == .pointing {
                Image(systemName: "hand.point.right.fill")
                    .font(.title)
                    .foregroundColor(moodColor)
                    .offset(x: 100, y: 0)
                    .transition(.scale.combined(with: .opacity))
            }
            
            if expression == .waving {
                Image(systemName: "hand.wave.fill")
                    .font(.title)
                    .foregroundColor(moodColor)
                    .offset(x: -100, y: -50)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .offset(y: bounceOffset)
        .onAppear {
            startBreathingAnimation()
            startBlinkingAnimation()
            
            if mood == .excited || mood == .celebrating {
                startBouncingAnimation()
            }
        }
        .onChange(of: isSpeaking) { _, newValue in
            if newValue {
                startSpeakingAnimation()
            } else {
                stopSpeakingAnimation()
            }
        }
        .onChange(of: mood) { _, newMood in
            if newMood == .excited || newMood == .celebrating {
                startBouncingAnimation()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: expression)
        .animation(.easeInOut(duration: 0.3), value: mood)
    }
    
    // MARK: - Mood Color
    
    private var moodColor: Color {
        switch mood {
        case .friendly: return .blue
        case .excited: return .orange
        case .thinking: return .purple
        case .encouraging: return .green
        case .celebrating: return .pink
        case .curious: return .cyan
        }
    }
    
    // MARK: - Animations
    
    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            breathingScale = 1.03
        }
    }
    
    private func startBlinkingAnimation() {
        Timer.scheduledTimer(withTimeInterval: Double.random(in: 3.0...6.0), repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                blinkAnimation = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeInOut(duration: 0.15)) {
                    blinkAnimation = false
                }
            }
        }
    }
    
    private func startSpeakingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            if isSpeaking {
                withAnimation(.easeInOut(duration: 0.1)) {
                    speakAnimation.toggle()
                }
            } else {
                timer.invalidate()
                speakAnimation = false
            }
        }
    }
    
    private func stopSpeakingAnimation() {
        speakAnimation = false
    }
    
    private func startBouncingAnimation() {
        withAnimation(.easeInOut(duration: 0.5).repeatCount(3, autoreverses: true)) {
            bounceOffset = -10
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            bounceOffset = 0
        }
    }
}

// MARK: - Eye View

struct EyeView: View {
    let isBlinking: Bool
    let expression: AvatarExpression
    
    var body: some View {
        ZStack {
            // Eye white
            Ellipse()
                .fill(Color.white)
                .frame(width: 30, height: isBlinking ? 2 : 35)
                .shadow(color: .black.opacity(0.1), radius: 2)
            
            if !isBlinking {
                // Pupil
                Circle()
                    .fill(Color.black)
                    .frame(width: 12, height: 12)
                    .offset(x: pupilOffset.x, y: pupilOffset.y)
                
                // Highlight
                Circle()
                    .fill(Color.white)
                    .frame(width: 5, height: 5)
                    .offset(x: pupilOffset.x - 3, y: pupilOffset.y - 3)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isBlinking)
    }
    
    private var pupilOffset: CGPoint {
        switch expression {
        case .thinking:
            return CGPoint(x: 0, y: -5)
        case .confused:
            return CGPoint(x: -3, y: 0)
        default:
            return .zero
        }
    }
}

// MARK: - Mouth View

struct MouthView: View {
    let expression: AvatarExpression
    let isSpeaking: Bool
    let speakAnimation: Bool
    
    var body: some View {
        ZStack {
            if isSpeaking {
                // Speaking mouth (open/close animation)
                Ellipse()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 35, height: speakAnimation ? 20 : 10)
                    .offset(y: speakAnimation ? 2 : 0)
            } else {
                // Expression-based mouth
                switch expression {
                case .smiling, .excited, .celebrating:
                    // Big smile
                    Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                        .stroke(Color.black, lineWidth: 3)
                        .frame(width: 40, height: 20)
                    
                case .caring, .encouraging:
                    // Gentle smile
                    Arc(startAngle: .degrees(20), endAngle: .degrees(160), clockwise: false)
                        .stroke(Color.black, lineWidth: 3)
                        .frame(width: 35, height: 15)
                    
                case .confused:
                    // Wavy confused mouth
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: 5))
                        path.addCurve(
                            to: CGPoint(x: 30, y: 5),
                            control1: CGPoint(x: 10, y: 0),
                            control2: CGPoint(x: 20, y: 10)
                        )
                    }
                    .stroke(Color.black, lineWidth: 2)
                    .frame(width: 30, height: 10)
                    
                case .thinking:
                    // Side mouth
                    Capsule()
                        .fill(Color.black)
                        .frame(width: 20, height: 3)
                        .rotationEffect(.degrees(-10))
                    
                default:
                    // Neutral small smile
                    Arc(startAngle: .degrees(30), endAngle: .degrees(150), clockwise: false)
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 30, height: 12)
                }
            }
        }
        .animation(.easeInOut(duration: 0.15), value: speakAnimation)
        .animation(.easeInOut(duration: 0.3), value: expression)
    }
}

// MARK: - Arc Shape

struct Arc: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let clockwise: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: clockwise
        )
        return path
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        AvatarHeadView(mood: .friendly, expression: .smiling, isSpeaking: false)
        AvatarHeadView(mood: .excited, expression: .excited, isSpeaking: true)
        AvatarHeadView(mood: .thinking, expression: .thinking, isSpeaking: false)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
