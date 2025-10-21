import SwiftUI

// MARK: - Particle System View
struct ParticleSystemView: View {
    @Binding var isActive: Bool
    let theme: EnvironmentTheme
    
    @State private var particles: [Particle] = []
    @State private var animationTimer: Timer?
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(theme.primaryColor.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
                    .scaleEffect(particle.scale)
                    .animation(.linear(duration: particle.duration), value: particle.x)
                    .animation(.linear(duration: particle.duration), value: particle.y)
                    .animation(.easeInOut(duration: 1.0), value: particle.opacity)
            }
        }
        .onAppear {
            generateParticles()
            startAnimation()
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                generateParticles()
            } else {
                particles.removeAll()
            }
        }
    }
    
    private func generateParticles() {
        particles = (0..<20).map { _ in
            Particle(
                id: UUID(),
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height),
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.3...0.8),
                scale: CGFloat.random(in: 0.5...1.5),
                duration: Double.random(in: 3...8),
                velocityX: CGFloat.random(in: -50...50),
                velocityY: CGFloat.random(in: -50...50)
            )
        }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            updateParticles()
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
    
    private func updateParticles() {
        for i in particles.indices {
            particles[i].x += particles[i].velocityX * 0.1
            particles[i].y += particles[i].velocityY * 0.1
            
            // Wrap around screen
            if particles[i].x > UIScreen.main.bounds.width {
                particles[i].x = 0
            } else if particles[i].x < 0 {
                particles[i].x = UIScreen.main.bounds.width
            }
            
            if particles[i].y > UIScreen.main.bounds.height {
                particles[i].y = 0
            } else if particles[i].y < 0 {
                particles[i].y = UIScreen.main.bounds.height
            }
        }
    }
}

struct Particle {
    let id: UUID
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let opacity: Double
    let scale: CGFloat
    let duration: Double
    let velocityX: CGFloat
    let velocityY: CGFloat
}

// MARK: - Neural Network View
struct NeuralNetworkView: View {
    let complexity: Double
    
    @State private var nodePositions: [CGPoint] = []
    @State private var connections: [(Int, Int)] = []
    @State private var animationOffset: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Draw connections
                ForEach(connections.indices, id: \.self) { index in
                    if index < connections.count {
                        let connection = connections[index]
                        if connection.0 < nodePositions.count && connection.1 < nodePositions.count {
                            Path { path in
                                path.move(to: nodePositions[connection.0])
                                path.addLine(to: nodePositions[connection.1])
                            }
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.3), .blue.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                            .opacity(0.5 + complexity * 0.5)
                        }
                    }
                }
                
                // Draw nodes
                ForEach(nodePositions.indices, id: \.self) { index in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.cyan.opacity(0.8), .blue.opacity(0.4)],
                                center: .center,
                                startRadius: 1,
                                endRadius: 8
                            )
                        )
                        .frame(width: 6, height: 6)
                        .position(nodePositions[index])
                        .scaleEffect(0.8 + complexity * 0.4)
                }
            }
        }
        .onAppear {
            generateNetwork()
            startAnimation()
        }
    }
    
    private func generateNetwork() {
        let nodeCount = Int(10 + complexity * 20)
        nodePositions = (0..<nodeCount).map { _ in
            CGPoint(
                x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 100)
            )
        }
        
        // Generate connections based on complexity
        connections = []
        for i in 0..<nodePositions.count {
            let connectionCount = Int(complexity * 3) + 1
            for _ in 0..<connectionCount {
                let target = Int.random(in: 0..<nodePositions.count)
                if i != target {
                    connections.append((i, target))
                }
            }
        }
    }
    
    private func startAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                animationOffset += 1
            }
        }
    }
}

// MARK: - Floating Shape View
struct FloatingShapeView: View {
    let index: Int
    let theme: EnvironmentTheme
    let isActive: Bool
    
    @State private var position: CGPoint = CGPoint(x: 100, y: 100)
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.5
    
    var body: some View {
        Group {
            switch index % 4 {
            case 0:
                Circle()
            case 1:
                Rectangle()
            case 2:
                RoundedRectangle(cornerRadius: 8)
            default:
                Ellipse()
            }
        }
        .fill(
            LinearGradient(
                colors: [theme.primaryColor.opacity(0.3), theme.primaryColor.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .frame(width: 20 + CGFloat(index * 5), height: 20 + CGFloat(index * 5))
        .position(position)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            generateRandomPosition()
            startAnimation()
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                animateActive()
            } else {
                animateInactive()
            }
        }
    }
    
    private func generateRandomPosition() {
        position = CGPoint(
            x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
            y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 100)
        )
    }
    
    private func startAnimation() {
        withAnimation(
            .linear(duration: Double.random(in: 10...20))
            .repeatForever(autoreverses: false)
        ) {
            rotation = 360
        }
        
        withAnimation(
            .easeInOut(duration: Double.random(in: 3...6))
            .repeatForever(autoreverses: true)
        ) {
            scale = CGFloat.random(in: 0.5...1.5)
            position = CGPoint(
                x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                y: CGFloat.random(in: 100...UIScreen.main.bounds.height - 100)
            )
        }
    }
    
    private func animateActive() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scale = 1.2
            opacity = 0.8
        }
    }
    
    private func animateInactive() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            scale = 1.0
            opacity = 0.5
        }
    }
}

// MARK: - Supporting Views for Course System
struct CourseShareView: View {
    let course: ProgressiveCourse
    @StateObject private var courseManager = CourseProgressManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var shareEmails: [String] = [""]
    @State private var customMessage = ""
    @State private var isSharing = false
    @State private var shareResult: ShareResult?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Course Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Share Course")
                        .font(.title2.weight(.bold))
                    
                    Text(course.title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(course.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Email Input
                VStack(alignment: .leading, spacing: 12) {
                    Text("Share with:")
                        .font(.headline)
                    
                    ForEach(shareEmails.indices, id: \.self) { index in
                        HStack {
                            TextField("Email address", text: $shareEmails[index])
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                            
                            if shareEmails.count > 1 {
                                Button {
                                    shareEmails.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    
                    Button {
                        shareEmails.append("")
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add another email")
                        }
                        .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                // Custom Message
                VStack(alignment: .leading, spacing: 12) {
                    Text("Custom message (optional):")
                        .font(.headline)
                    
                    TextEditor(text: $customMessage)
                        .frame(minHeight: 80)
                        .padding(8)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                
                Spacer()
                
                // Share Button
                Button {
                    shareTheCourse()
                } label: {
                    HStack {
                        if isSharing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isSharing ? "Sharing..." : "Share Course")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSharing || shareEmails.allSatisfy { $0.isEmpty })
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Share Result", isPresented: .constant(shareResult != nil)) {
            Button("OK") {
                shareResult = nil
                if case .success = shareResult {
                    dismiss()
                }
            }
        } message: {
            if let result = shareResult {
                switch result {
                case .success(let link):
                    Text("Course shared successfully! Share link: \(link)")
                case .failure(let error):
                    Text("Failed to share course: \(error)")
                }
            }
        }
    }
    
    private func shareTheCourse() {
        isSharing = true
        
        Task {
            let validEmails = shareEmails.filter { !$0.isEmpty }
            let result = await courseManager.shareCourse(course, with: validEmails)
            
            await MainActor.run {
                shareResult = result
                isSharing = false
            }
        }
    }
}

struct PersonalLibraryView: View {
    @StateObject private var courseManager = CourseProgressManager.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 16) {
                    if courseManager.savedCourses.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "books.vertical")
                                .font(.system(size: 64))
                                .foregroundColor(.gray.opacity(0.5))
                            
                            Text("Your Library is Empty")
                                .font(.title2.weight(.semibold))
                            
                            Text("Complete courses or create new ones to build your personal learning library.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(40)
                    } else {
                        ForEach(courseManager.savedCourses) { course in
                            LibraryCourseCard(course: course)
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Your Library")
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

struct LibraryCourseCard: View {
    let course: ProgressiveCourse
    @StateObject private var courseManager = CourseProgressManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.title)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)
                    
                    Text(course.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                Spacer()
                
                if course.isCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                }
            }
            
            HStack {
                Label(course.topic, systemImage: "tag")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if let completedAt = course.completedAt {
                    Text("Completed \(completedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("In Progress")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            Task {
                await courseManager.startCourse(course)
            }
        }
    }
}

#Preview {
    ParticleSystemView(isActive: .constant(true), theme: .cosmic)
}