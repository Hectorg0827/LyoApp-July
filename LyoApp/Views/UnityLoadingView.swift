import SwiftUI

// MARK: - Unity Loading View
/// Beautiful loading screen shown while Unity initializes and loads environment
/// Displays progress, tips, and environment info
struct UnityLoadingView: View {
    let environmentName: String
    let courseName: String
    @Binding var isLoading: Bool
    @State private var progress: Double = 0.0
    @State private var currentTipIndex = 0
    @State private var loadingPhase: LoadingPhase = .initializing
    
    enum LoadingPhase: String {
        case initializing = "Initializing Unity..."
        case loadingEnvironment = "Loading Environment..."
        case preparingContent = "Preparing Course Content..."
        case ready = "Ready!"
    }
    
    private let tips = [
        "💡 Interact with objects to discover hidden lessons",
        "🎯 Complete challenges to earn bonus XP",
        "📚 Explore the environment for extra context",
        "🎨 Pay attention to cultural details",
        "⭐ Perfect scores unlock special achievements",
        "🔍 Look for interactive elements everywhere",
        "🎓 Ask your AI tutor for help anytime",
        "🌟 Immersive learning is more effective!"
    ]
    
    var body: some View {
        ZStack {
            // Background gradient matching environment
            LinearGradient(
                colors: environmentGradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .blur(radius: 20)
            
            // Overlay dark tint
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Environment Icon with pulse animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 160, height: 160)
                        .scaleEffect(progress * 0.2 + 1.0)
                    
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 200, height: 200)
                        .scaleEffect(progress * 0.3 + 1.0)
                    
                    Image(systemName: environmentIcon)
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(progress * 360))
                }
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: progress)
                
                // Environment name
                Text(environmentDisplayName)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(courseName)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Progress section
                VStack(spacing: 16) {
                    // Progress bar
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 8)
                        
                        // Progress fill
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: CGFloat(progress) * (UIScreen.main.bounds.width - 80), height: 8)
                            .animation(.linear(duration: 0.3), value: progress)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)
                    
                    // Loading phase
                    Text(loadingPhase.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    // Percentage
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.spring(), value: progress)
                }
                
                Spacer()
                
                // Rotating tip
                VStack(spacing: 8) {
                    Text("Did you know?")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(tips[currentTipIndex])
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(currentTipIndex) // Force view recreation
                }
                .frame(height: 80)
                
                Spacer()
            }
        }
        .onAppear {
            startLoadingSimulation()
        }
    }
    
    // MARK: - Helper Properties
    
    private var environmentDisplayName: String {
        switch environmentName.lowercased() {
        case let name where name.contains("maya"):
            return "Maya Ceremonial Center"
        case let name where name.contains("egypt"):
            return "Egyptian Temple"
        case let name where name.contains("mars"):
            return "Mars Exploration Base"
        case let name where name.contains("chemistry"):
            return "Advanced Chemistry Lab"
        case let name where name.contains("math"):
            return "Mathematics Studio"
        case let name where name.contains("rome"):
            return "Roman Forum"
        case let name where name.contains("greece"):
            return "Greek Agora"
        case let name where name.contains("viking"):
            return "Viking Longhouse"
        default:
            return "Modern Classroom"
        }
    }
    
    private var environmentIcon: String {
        switch environmentName.lowercased() {
        case let name where name.contains("maya"):
            return "building.columns.fill"
        case let name where name.contains("egypt"):
            return "pyramid.fill"
        case let name where name.contains("mars"):
            return "moon.stars.fill"
        case let name where name.contains("chemistry"):
            return "flask.fill"
        case let name where name.contains("math"):
            return "function"
        case let name where name.contains("rome"):
            return "building.columns"
        case let name where name.contains("greece"):
            return "laurel.leading"
        default:
            return "book.fill"
        }
    }
    
    private var environmentGradient: [Color] {
        switch environmentName.lowercased() {
        case let name where name.contains("maya"):
            return [Color(hex: "1B5E20"), Color(hex: "388E3C"), Color(hex: "4CAF50")]
        case let name where name.contains("egypt"):
            return [Color(hex: "FF6F00"), Color(hex: "FFA000"), Color(hex: "FFD54F")]
        case let name where name.contains("mars"):
            return [Color(hex: "B71C1C"), Color(hex: "D32F2F"), Color(hex: "F57C00")]
        case let name where name.contains("chemistry"):
            return [Color(hex: "0D47A1"), Color(hex: "1565C0"), Color(hex: "42A5F5")]
        case let name where name.contains("math"):
            return [Color(hex: "4A148C"), Color(hex: "6A1B9A"), Color(hex: "AB47BC")]
        case let name where name.contains("rome"):
            return [Color(hex: "D32F2F"), Color(hex: "C62828"), Color(hex: "B71C1C")]
        default:
            return [Color(hex: "1A237E"), Color(hex: "283593"), Color(hex: "3F51B5")]
        }
    }
    
    // MARK: - Loading Simulation
    
    private func startLoadingSimulation() {
        // Phase 1: Initializing (0-25%)
        loadingPhase = .initializing
        animateProgress(to: 0.25, duration: 1.0) {
            // Phase 2: Loading Environment (25-60%)
            loadingPhase = .loadingEnvironment
            animateProgress(to: 0.60, duration: 1.5) {
                // Phase 3: Preparing Content (60-95%)
                loadingPhase = .preparingContent
                animateProgress(to: 0.95, duration: 1.0) {
                    // Phase 4: Ready (95-100%)
                    loadingPhase = .ready
                    animateProgress(to: 1.0, duration: 0.5) {
                        // Complete
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isLoading = false
                        }
                    }
                }
            }
        }
        
        // Rotate tips every 3 seconds
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            if progress >= 1.0 {
                timer.invalidate()
            } else {
                withAnimation {
                    currentTipIndex = (currentTipIndex + 1) % tips.count
                }
            }
        }
    }
    
    private func animateProgress(to target: Double, duration: Double, completion: @escaping () -> Void) {
        let startProgress = progress
        let delta = target - startProgress
        let steps = Int(duration * 30) // 30 fps
        let increment = delta / Double(steps)
        
        var currentStep = 0
        Timer.scheduledTimer(withTimeInterval: duration / Double(steps), repeats: true) { timer in
            currentStep += 1
            progress = startProgress + (increment * Double(currentStep))
            
            if currentStep >= steps {
                timer.invalidate()
                progress = target
                completion()
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
#Preview("Maya Environment") {
    UnityLoadingView(
        environmentName: "MayaCivilization",
        courseName: "Ancient Maya History & Culture",
        isLoading: .constant(true)
    )
}

#Preview("Mars Environment") {
    UnityLoadingView(
        environmentName: "MarsExploration",
        courseName: "Journey to Mars: Space Exploration",
        isLoading: .constant(true)
    )
}

#Preview("Chemistry Lab") {
    UnityLoadingView(
        environmentName: "ChemistryLab",
        courseName: "Introduction to Organic Chemistry",
        isLoading: .constant(true)
    )
}
#endif
