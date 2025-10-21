import SwiftUI

/// Course Journey Preview Card - Shows the learning path before launching Unity classroom
struct CourseJourneyPreviewCard: View {
    let journey: CourseJourney
    let countdown: Int?
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            Text("Here's your personalized learning journey:")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Journey Card
            VStack(spacing: 20) {
                // Title
                VStack(spacing: 8) {
                    Text(journey.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(journey.subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                
                // Visual Journey Map
                CourseJourneyDiagram(modules: journey.modules)
                    .frame(height: 200)
                
                // Stats
                HStack(spacing: 24) {
                    JourneyStatItem(
                        icon: "clock.fill",
                        label: journey.duration,
                        color: .orange
                    )
                    
                    JourneyStatItem(
                        icon: "books.vertical.fill",
                        label: "\(journey.modules.count) modules",
                        color: .cyan
                    )
                    
                    JourneyStatItem(
                        icon: "sparkles",
                        label: "\(journey.xpReward) XP",
                        color: .yellow
                    )
                }
                
                // Environment Badge
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    Text("Environment: \(journey.environment)")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                // Start Button or Countdown
                if let countdown = countdown, countdown > 0 {
                    // Countdown animation
                    VStack(spacing: 8) {
                        Text("\(countdown)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.cyan)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdown)
                        
                        Text("Launching...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(12)
                } else if countdown == 0 {
                    // Launching state
                    HStack(spacing: 12) {
                        ProgressView()
                            .tint(.cyan)
                        Text("Launching Unity Classroom...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.cyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Color.cyan.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    // Start button
                    Button(action: onStart) {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text("Start Course")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(16)
                        .background(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "2C2C2E"))
                    .shadow(color: Color.cyan.opacity(0.2), radius: 15, x: 0, y: 5)
            )
        }
    }
}

// MARK: - Course Journey Diagram
struct CourseJourneyDiagram: View {
    let modules: [CourseModule]
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Connection lines
                Path { path in
                    let spacing: CGFloat = 50
                    let startY: CGFloat = 30
                    
                    for i in 0..<(modules.count - 1) {
                        let currentY = startY + CGFloat(i) * spacing
                        let nextY = startY + CGFloat(i + 1) * spacing
                        
                        let currentX = i % 2 == 0 ? geo.size.width / 2 : geo.size.width / 2 - 30
                        let nextX = (i + 1) % 2 == 0 ? geo.size.width / 2 : geo.size.width / 2 - 30
                        
                        path.move(to: CGPoint(x: currentX, y: currentY))
                        path.addLine(to: CGPoint(x: nextX, y: nextY))
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.5), Color.blue.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                )
                
                // Module nodes
                VStack(spacing: 20) {
                    ForEach(Array(modules.enumerated()), id: \.offset) { index, module in
                        HStack {
                            if index % 2 == 0 {
                                Spacer()
                            }
                            
                            // Module node
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(moduleColor(for: module.type))
                                        .frame(width: 50, height: 50)
                                        .shadow(color: moduleColor(for: module.type).opacity(0.5), radius: 8)
                                    
                                    Text(module.icon)
                                        .font(.system(size: 22))
                                }
                                
                                Text(module.title)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .frame(width: 70)
                            }
                            
                            if index % 2 != 0 {
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.top, 10)
            }
        }
    }
    
    func moduleColor(for type: ModuleType) -> Color {
        switch type {
        case .intro: return Color.green
        case .lesson: return Color.cyan
        case .lab: return Color.purple
        case .quiz: return Color.orange
        case .project: return Color.pink
        }
    }
}

// MARK: - Journey Stat Item
struct JourneyStatItem: View {
    let icon: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        CourseJourneyPreviewCard(
            journey: CourseJourney(
                title: "Quantum Physics 101",
                subtitle: "Understanding the fundamentals",
                duration: "2.5 hours",
                modules: [
                    CourseModule(title: "Start", icon: "🎯", type: .intro),
                    CourseModule(title: "Core", icon: "📚", type: .lesson),
                    CourseModule(title: "Lab 1", icon: "🔬", type: .lab),
                    CourseModule(title: "Lab 2", icon: "⚗️", type: .lab),
                    CourseModule(title: "Quiz", icon: "✓", type: .quiz),
                    CourseModule(title: "Project", icon: "🏆", type: .project)
                ],
                environment: "Virtual Lab",
                xpReward: 500
            ),
            countdown: nil,
            onStart: {}
        )
        .padding()
    }
}
