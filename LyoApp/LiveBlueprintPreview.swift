import SwiftUI

/// Live visualization of the learning blueprint as it's being built
/// Uses REAL data from LearningBlueprint - no mocks, no demos
struct LiveBlueprintPreview: View {
    @Binding var blueprint: LearningBlueprint
    let containerSize: CGSize
    
    // Animation states
    @State private var nodeAnimations: [UUID: Bool] = [:]
    @State private var pulsingNodes: Set<UUID> = []
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            // Connection lines (drawn first, below nodes)
            ForEach(blueprint.nodes) { node in
                ForEach(node.connections, id: \.self) { targetId in
                    if let targetNode = blueprint.nodes.first(where: { $0.id == targetId }) {
                        ConnectionLine(
                            from: node.position,
                            to: targetNode.position,
                            isActive: nodeAnimations[node.id] ?? false && nodeAnimations[targetId] ?? false
                        )
                    }
                }
            }
            
            // Blueprint nodes
            ForEach(blueprint.nodes) { node in
                BlueprintNodeView(
                    node: node,
                    isAnimating: nodeAnimations[node.id] ?? false,
                    isPulsing: pulsingNodes.contains(node.id)
                )
                .position(node.position)
                .onAppear {
                    animateNodeAppearance(node.id)
                }
            }
            
            // Center indicator when empty
            if blueprint.nodes.isEmpty {
                EmptyBlueprintView()
            }
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .onChange(of: blueprint.nodes.count) { _, _ in
            // Pulse the most recently added node
            if let lastNode = blueprint.nodes.last {
                pulseNode(lastNode.id)
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.blue.opacity(0.05),
                Color.purple.opacity(0.05),
                Color.cyan.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Animations
    
    private func animateNodeAppearance(_ nodeId: UUID) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            nodeAnimations[nodeId] = true
        }
    }
    
    private func pulseNode(_ nodeId: UUID) {
        pulsingNodes.insert(nodeId)
        
        // Stop pulsing after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            pulsingNodes.remove(nodeId)
        }
    }
}

// MARK: - Blueprint Node View

/// Visual representation of a single blueprint node
struct BlueprintNodeView: View {
    let node: BlueprintNode
    let isAnimating: Bool
    let isPulsing: Bool
    
    @State private var scale: CGFloat = 0.3
    
    var body: some View {
        VStack(spacing: 4) {
            // Node circle
            Circle()
                .fill(nodeColor)
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: nodeIcon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                )
                .overlay(
                    Circle()
                        .stroke(nodeColor.opacity(0.5), lineWidth: 2)
                        .scaleEffect(isPulsing ? 1.4 : 1.0)
                        .opacity(isPulsing ? 0.0 : 1.0)
                        .animation(
                            isPulsing ?
                            .easeOut(duration: 1.0).repeatCount(3, autoreverses: false) :
                            .default,
                            value: isPulsing
                        )
                )
                .shadow(color: nodeColor.opacity(0.4), radius: 8, x: 0, y: 4)
            
            // Node label
            Text(node.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
        }
        .scaleEffect(isAnimating ? scale : 0.3)
        .opacity(isAnimating ? 1 : 0)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
    }
    
    // MARK: - Node Styling
    
    private var nodeColor: Color {
        switch node.type {
        case .topic:
            return Color.blue
        case .goal:
            return Color.green
        case .module:
            return Color.orange
        case .skill:
            return Color.purple
        case .milestone:
            return Color.pink
        }
    }
    
    private var nodeIcon: String {
        switch node.type {
        case .topic:
            return "lightbulb.fill"
        case .goal:
            return "target"
        case .module:
            return "book.fill"
        case .skill:
            return "star.fill"
        case .milestone:
            return "flag.fill"
        }
    }
}

// MARK: - Connection Line

/// Draws a connection line between two blueprint nodes
struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    let isActive: Bool
    
    @State private var animationProgress: CGFloat = 0.0
    
    var body: some View {
        Path { path in
            path.move(to: from)
            
            // Calculate control points for curved line
            let midX = (from.x + to.x) / 2
            let midY = (from.y + to.y) / 2
            let controlPoint1 = CGPoint(x: midX, y: from.y)
            let controlPoint2 = CGPoint(x: midX, y: to.y)
            
            path.addCurve(to: to, control1: controlPoint1, control2: controlPoint2)
        }
        .trim(from: 0, to: isActive ? animationProgress : 0)
        .stroke(
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
        .shadow(color: .blue.opacity(0.3), radius: 2, x: 0, y: 0)
        .onChange(of: isActive) { _, active in
            if active {
                withAnimation(.easeInOut(duration: 0.8)) {
                    animationProgress = 1.0
                }
            }
        }
    }
}

// MARK: - Empty State

/// Shows when blueprint has no nodes yet
struct EmptyBlueprintView: View {
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .frame(width: 100, height: 100)
                .scaleEffect(pulseScale)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            Text("Your Learning Blueprint")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
            
            Text("Answer questions to build your path")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary.opacity(0.7))
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
        }
    }
}

// MARK: - Layout Calculator

/// Calculates node positions based on blueprint structure
extension LearningBlueprint {
    /// Calculate positions for all nodes using a radial layout
    mutating func calculateNodePositions(containerSize: CGSize) {
        guard !nodes.isEmpty else { return }
        
        let centerX = containerSize.width / 2
        let centerY = containerSize.height / 2
        
        // Find root node (topic)
        if let topicIndex = nodes.firstIndex(where: { $0.type == .topic }) {
            nodes[topicIndex].position = CGPoint(x: centerX, y: centerY)
            
            // Position connected nodes around the topic in a circle
            let connectedNodes = nodes.filter { node in
                node.id != nodes[topicIndex].id
            }
            
            let radius: CGFloat = 120
            let angleStep = (2 * .pi) / CGFloat(max(connectedNodes.count, 1))
            
            for (index, node) in connectedNodes.enumerated() {
                let angle = angleStep * CGFloat(index) - .pi / 2 // Start from top
                let x = centerX + radius * cos(angle)
                let y = centerY + radius * sin(angle)
                
                if let nodeIndex = nodes.firstIndex(where: { $0.id == node.id }) {
                    nodes[nodeIndex].position = CGPoint(x: x, y: y)
                }
            }
        } else {
            // Fallback: distribute nodes evenly
            let radius: CGFloat = 100
            let angleStep = (2 * .pi) / CGFloat(nodes.count)
            
            for (index, node) in nodes.enumerated() {
                let angle = angleStep * CGFloat(index) - .pi / 2
                let x = centerX + radius * cos(angle)
                let y = centerY + radius * sin(angle)
                
                nodes[index].position = CGPoint(x: x, y: y)
            }
        }
    }
}

// MARK: - Previews

#Preview("Empty Blueprint") {
    LiveBlueprintPreview(
        blueprint: .constant(LearningBlueprint()),
        containerSize: CGSize(width: 400, height: 600)
    )
}

#Preview("With Nodes") {
    var blueprint = LearningBlueprint()
    blueprint.topic = "Swift Programming"
    blueprint.goal = "Build iOS apps"
    
    // Create topic node
    let topicNode = BlueprintNode(
        id: UUID(),
        title: "Swift",
        type: .topic,
        connections: [],
        position: CGPoint(x: 200, y: 300)
    )
    
    // Create goal node
    let goalNode = BlueprintNode(
        id: UUID(),
        title: "Build Apps",
        type: .goal,
        connections: [topicNode.id],
        position: CGPoint(x: 280, y: 220)
    )
    
    // Create skill nodes
    let skill1 = BlueprintNode(
        id: UUID(),
        title: "SwiftUI",
        type: .skill,
        connections: [topicNode.id],
        position: CGPoint(x: 280, y: 380)
    )
    
    let skill2 = BlueprintNode(
        id: UUID(),
        title: "Data Flow",
        type: .skill,
        connections: [topicNode.id],
        position: CGPoint(x: 120, y: 380)
    )
    
    blueprint.nodes = [topicNode, goalNode, skill1, skill2]
    
    return LiveBlueprintPreview(
        blueprint: .constant(blueprint),
        containerSize: CGSize(width: 400, height: 600)
    )
}
