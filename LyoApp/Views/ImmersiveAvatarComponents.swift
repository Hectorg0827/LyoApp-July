import SwiftUI
import Foundation

// MARK: - Particle System View
struct ParticleSystemView: View {
    @Binding var isActive: Bool
    let theme: EnvironmentTheme
    
    @State private var particles: [ParticleData] = []
    @State private var animationTimer: Timer?
    
    var body: some View {
        Canvas { context, size in
            for particle in particles {
                let rect = CGRect(
                    x: particle.position.x * size.width,
                    y: particle.position.y * size.height,
                    width: particle.size,
                    height: particle.size
                )
                
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(particle.color.opacity(particle.opacity))
                )
            }
        }
        .onAppear {
            initializeParticles()
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func initializeParticles() {
        particles = (0..<theme.shapeCount * 2).map { _ in
            ParticleData(
                position: CGPoint(
                    x: Double.random(in: 0...1),
                    y: Double.random(in: 0...1)
                ),
                velocity: CGPoint(
                    x: Double.random(in: -0.001...0.001),
                    y: Double.random(in: -0.002...0.002)
                ),
                size: Double.random(in: 1...4),
                opacity: Double.random(in: 0.1...0.6),
                color: theme.primaryColor,
                life: 1.0
            )
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].position.x += particles[i].velocity.x
            particles[i].position.y += particles[i].velocity.y
            particles[i].life -= 0.01
            
            // Reset particle if it's dead or out of bounds
            if particles[i].life <= 0 || particles[i].position.x < -0.1 || particles[i].position.x > 1.1 || particles[i].position.y < -0.1 || particles[i].position.y > 1.1 {
                particles[i] = ParticleData(
                    position: CGPoint(
                        x: Double.random(in: 0...1),
                        y: Double.random(in: 0...1)
                    ),
                    velocity: CGPoint(
                        x: Double.random(in: -0.001...0.001),
                        y: Double.random(in: -0.002...0.002)
                    ),
                    size: Double.random(in: 1...4),
                    opacity: Double.random(in: 0.1...0.6),
                    color: theme.primaryColor,
                    life: 1.0
                )
            }
        }
    }
}

struct ParticleData {
    var position: CGPoint
    var velocity: CGPoint
    var size: Double
    var opacity: Double
    var color: Color
    var life: Double
}

// MARK: - Neural Network View
struct NeuralNetworkView: View {
    let complexity: Double
    @State private var nodePositions: [CGPoint] = []
    @State private var connections: [(CGPoint, CGPoint)] = []
    @State private var animationPhase: Double = 0.0
    
    var body: some View {
        Canvas { context, size in
            // Draw connections
            for (start, end) in connections {
                let scaledStart = CGPoint(x: start.x * size.width, y: start.y * size.height)
                let scaledEnd = CGPoint(x: end.x * size.width, y: end.y * size.height)
                
                let path = Path { path in
                    path.move(to: scaledStart)
                    path.addLine(to: scaledEnd)
                }
                
                let opacity = 0.2 + 0.3 * sin(animationPhase + Double(connections.firstIndex { $0.0 == start && $0.1 == end } ?? 0))
                
                context.stroke(
                    path,
                    with: .color(.cyan.opacity(opacity)),
                    lineWidth: 1.0
                )
            }
            
            // Draw nodes
            for (index, position) in nodePositions.enumerated() {
                let scaledPosition = CGPoint(x: position.x * size.width, y: position.y * size.height)
                let nodeSize = 4.0 + 2.0 * complexity
                let pulsation = 1.0 + 0.3 * sin(animationPhase + Double(index) * 0.5)
                
                let rect = CGRect(
                    x: scaledPosition.x - nodeSize / 2,
                    y: scaledPosition.y - nodeSize / 2,
                    width: nodeSize * pulsation,
                    height: nodeSize * pulsation
                )
                
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(.white.opacity(0.7))
                )
            }
        }
        .onAppear {
            generateNetwork()
        }
        .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
            withAnimation(.linear(duration: 0.1)) {
                animationPhase += 0.2
            }
        }
    }
    
    private func generateNetwork() {
        let nodeCount = Int(10 + complexity * 20)
        
        nodePositions = (0..<nodeCount).map { _ in
            CGPoint(
                x: Double.random(in: 0.1...0.9),
                y: Double.random(in: 0.1...0.9)
            )
        }
        
        connections = []
        for i in nodePositions.indices {
            let connectionCount = Int.random(in: 1...min(4, nodePositions.count - 1))
            let nearbyNodes = nodePositions.indices.filter { j in
                j != i && distance(nodePositions[i], nodePositions[j]) < 0.3
            }
            
            for j in nearbyNodes.prefix(connectionCount) {
                connections.append((nodePositions[i], nodePositions[j]))
            }
        }
    }
    
    private func distance(_ p1: CGPoint, _ p2: CGPoint) -> Double {
        sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2))
    }
}

// MARK: - Floating Shape View
struct FloatingShapeView: View {
    let index: Int
    let theme: EnvironmentTheme
    let isActive: Bool
    
    @State private var position: CGPoint = .zero
    @State private var rotation: Double = 0.0
    @State private var scale: Double = 1.0
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Group {
            switch index % 4 {
            case 0:
                Circle()
                    .stroke(theme.primaryColor.opacity(opacity), lineWidth: 2)
                    .frame(width: 20, height: 20)
            case 1:
                RoundedRectangle(cornerRadius: 4)
                    .stroke(theme.primaryColor.opacity(opacity), lineWidth: 1.5)
                    .frame(width: 16, height: 16)
            case 2:
                Triangle()
                    .stroke(theme.primaryColor.opacity(opacity), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
            default:
                Diamond()
                    .stroke(theme.primaryColor.opacity(opacity), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
            }
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .position(position)
        .onAppear {
            initializeShape()
            startFloating()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                increaseActivity()
            } else {
                decreaseActivity()
            }
        }
    }
    
    private func initializeShape() {
        position = CGPoint(
            x: Double.random(in: 50...300),
            y: Double.random(in: 100...600)
        )
        
        opacity = Double.random(in: 0.1...0.4)
        scale = Double.random(in: 0.5...1.5)
    }
    
    private func startFloating() {
        withAnimation(
            .linear(duration: Double.random(in: 15...25))
            .repeatForever(autoreverses: false)
        ) {
            position.x += Double.random(in: -200...200)
            position.y += Double.random(in: -300...300)
        }
        
        withAnimation(
            .linear(duration: Double.random(in: 8...12))
            .repeatForever(autoreverses: true)
        ) {
            rotation = 360
        }
        
        withAnimation(
            .easeInOut(duration: Double.random(in: 3...6))
            .repeatForever(autoreverses: true)
        ) {
            scale *= Double.random(in: 0.8...1.2)
        }
    }
    
    private func increaseActivity() {
        withAnimation(.easeInOut(duration: 0.5)) {
            opacity = min(opacity * 2, 0.8)
            scale *= 1.2
        }
    }
    
    private func decreaseActivity() {
        withAnimation(.easeInOut(duration: 1.0)) {
            opacity *= 0.7
            scale *= 0.9
        }
    }
}

// MARK: - Custom Shapes
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Course Share View
struct CourseShareView: View {
    let course: ProgressiveCourse
    @Environment(\.dismiss) private var dismiss
    @StateObject private var courseManager = CourseProgressManager.shared
    
    @State private var recipientEmails: String = ""
    @State private var customMessage: String = ""
    @State private var sharePublicly = false
    @State private var allowModifications = false
    @State private var isSharing = false
    @State private var shareResult: ShareResult?
    @State private var publicShareLink: String?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Course info
                    CourseSharePreview(course: course)
                    
                    // Sharing options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Sharing Options")
                            .font(.headline)
                        
                        if !sharePublicly {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Send to specific people")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("Enter email addresses (comma separated)", text: $recipientEmails, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3...)
                            }
                        }
                        
                        Toggle("Share publicly with link", isOn: $sharePublicly)
                        Toggle("Allow modifications", isOn: $allowModifications)
                    }
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    
                    // Custom message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Custom Message (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextField("Add a personal message...", text: $customMessage, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...)
                    }
                    
                    // Share button
                    Button {
                        shareButtonTapped()
                    } label: {
                        HStack {
                            if isSharing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            Text(isSharing ? "Sharing..." : "Share Course")
                        }
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(isSharing || (!sharePublicly && recipientEmails.isEmpty))
                    
                    // Share result
                    if let result = shareResult {
                        ShareResultView(result: result)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Share Course")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func shareButtonTapped() {
        isSharing = true
        
        Task {
            if sharePublicly {
                let link = await courseManager.generatePublicShareLink(course)
                await MainActor.run {
                    if let link = link {
                        publicShareLink = link
                        shareResult = .success(shareLink: link)
                    } else {
                        shareResult = .failure(error: "Failed to generate public share link")
                    }
                    isSharing = false
                }
            } else {
                let emails = recipientEmails.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                let result = await courseManager.shareCourse(course, with: emails)
                await MainActor.run {
                    shareResult = result
                    isSharing = false
                }
            }
        }
    }
}

struct CourseSharePreview: View {
    let course: ProgressiveCourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(course.title)
                .font(.title2.weight(.semibold))
            
            Text(course.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Label(course.topic, systemImage: "tag")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Label("\(course.estimatedDuration / 60)h", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                if course.isCompleted {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ShareResultView: View {
    let result: ShareResult
    
    var body: some View {
        Group {
            switch result {
            case .success(let shareLink):
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Course shared successfully!")
                            .font(.subheadline.weight(.medium))
                    }
                    
                    HStack {
                        Text(shareLink)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        Button {
                            UIPasteboard.general.string = shareLink
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                
            case .failure(let error):
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
                .padding()
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Personal Library View
struct PersonalLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var courseManager = CourseProgressManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // Completed courses
                    if !courseManager.completedCourses.isEmpty {
                        Section("Completed Courses") {
                            ForEach(courseManager.completedCourses) { course in
                                CourseLibraryCard(course: course, isCompleted: true)
                            }
                        }
                    }
                    
                    // Saved courses in progress
                    let inProgressCourses = courseManager.savedCourses.filter { !$0.isCompleted }
                    if !inProgressCourses.isEmpty {
                        Section("In Progress") {
                            ForEach(inProgressCourses) { course in
                                CourseLibraryCard(course: course, isCompleted: false)
                            }
                        }
                    }
                    
                    // Empty state
                    if courseManager.savedCourses.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "books.vertical")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Your Library is Empty")
                                .font(.title2.weight(.semibold))
                            
                            Text("Start learning with Lyo to build your personal course library!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("My Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CourseLibraryCard: View {
    let course: ProgressiveCourse
    let isCompleted: Bool
    @StateObject private var courseManager = CourseProgressManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(course.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    CircularProgressView(progress: calculateProgress(course))
                }
            }
            
            HStack {
                Label(course.topic, systemImage: "tag")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Label("\(course.estimatedDuration / 60)h", systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Label(course.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Action buttons
            HStack {
                if !isCompleted {
                    Button("Continue") {
                        Task {
                            await courseManager.startCourse(course)
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                
                Spacer()
                
                Button("View Details") {
                    // Show course details
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func calculateProgress(_ course: ProgressiveCourse) -> Double {
        let completedSteps = course.steps.filter { $0.isCompleted }.count
        return Double(completedSteps) / Double(course.steps.count)
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(.gray.opacity(0.3), lineWidth: 3)
                .frame(width: 32, height: 32)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 32, height: 32)
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(progress * 100))%")
                .font(.caption2.weight(.semibold))
                .foregroundColor(.blue)
        }
    }
}