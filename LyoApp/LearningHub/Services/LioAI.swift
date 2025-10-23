import Foundation

// MARK: - Lio AI Service
/// Service for communicating with the Lio AI backend
/// Handles chat interactions, learning assistance, and content generation
struct LioAI {
    
    // MARK: - Configuration
    #if DEBUG
    private static let baseURL = "http://localhost:8000/ai/v1"
    #else
    private static let baseURL = "https://lyo-backend-830162750094.us-central1.run.app/ai/v1"
    #endif
    private static let timeout: TimeInterval = 30.0
    
    // MARK: - Chat & Assistance
    
    /// Generate an AI reply to user message
    static func generateReply(to message: String) async -> String {
        print("🤖 DEBUG: Generating AI reply for '\(message)'...")
        
        // Simulate AI processing time
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000)) // 1-3 seconds
        
        // Generate contextual responses based on message content
        let lowercaseMessage = message.lowercased()
        
        if lowercaseMessage.contains("swift") || lowercaseMessage.contains("ios") {
            return """
            Great question about Swift/iOS development! 🍎
            
            Based on your query, I'd recommend starting with:
            • Apple's official Swift documentation
            • Stanford CS193p course (free on iTunes U)
            • Building simple projects to practice
            
            What specific aspect of iOS development interests you most?
            """
        } else if lowercaseMessage.contains("learn") || lowercaseMessage.contains("study") {
            return """
            I love helping with learning! 📚
            
            Here's my approach to effective learning:
            1. Start with fundamentals
            2. Practice regularly with hands-on projects
            3. Join communities and ask questions
            4. Teach others what you learn
            
            What topic would you like to dive into?
            """
        } else if lowercaseMessage.contains("help") || lowercaseMessage.contains("stuck") {
            return """
            I'm here to help! 💪
            
            When you're stuck, try this process:
            • Break the problem into smaller parts
            • Check documentation and examples
            • Experiment with simple test cases
            • Don't hesitate to ask specific questions
            
            What specific challenge are you facing?
            """
        } else if lowercaseMessage.contains("project") || lowercaseMessage.contains("build") {
            return """
            Building projects is the best way to learn! 🛠️
            
            Here are some great project ideas:
            • Personal expense tracker
            • Weather app with animations
            • Task management with CoreData
            • Social learning platform (like we're building!)
            
            What type of project interests you?
            """
        } else {
            return """
            That's an interesting question! 🤔
            
            I'm here to help you on your learning journey. I can assist with:
            • Programming concepts and best practices
            • Learning path recommendations
            • Project ideas and guidance
            • Study strategies and motivation
            
            Feel free to ask me anything about learning and development!
            """
        }
    }
    
    /// Get learning path suggestions
    static func suggestLearningPath(for topic: String, level: String = "beginner") async -> LioAILearningPath {
        print("🗺️ Generating learning path for '\(topic)' at \(level) level...")
        
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Generate a structured learning path
        return LioAILearningPath(
            title: "Master \(topic.capitalized)",
            description: "A comprehensive learning path to become proficient in \(topic)",
            estimatedDuration: "4-6 weeks",
            difficulty: level,
            steps: [
                LearningStep(title: "Foundations", description: "Learn the basic concepts", estimatedTime: "1 week"),
                LearningStep(title: "Hands-on Practice", description: "Build simple projects", estimatedTime: "2 weeks"),
                LearningStep(title: "Advanced Topics", description: "Dive into complex scenarios", estimatedTime: "2 weeks"),
                LearningStep(title: "Real-world Project", description: "Create a portfolio project", estimatedTime: "1 week")
            ]
        )
    }
    
    /// Get study tips for a specific topic
    static func getStudyTips(for topic: String) async -> [String] {
        print("💡 Generating study tips for '\(topic)'...")
        
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        return [
            "Start with the official documentation for \(topic)",
            "Practice coding examples daily for 30 minutes",
            "Join online communities and forums",
            "Build small projects to apply concepts",
            "Teach someone else what you've learned",
            "Keep a learning journal to track progress"
        ]
    }
    
    /// Analyze user's learning progress and provide insights
    static func analyzeProgress(completedResources: [LearningResource]) async -> ProgressInsight {
        print("📊 Analyzing learning progress for \(completedResources.count) resources...")
        
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        let totalHours = completedResources.compactMap { resource in
            // Parse duration string like "2h 30m" to hours
            return parseDurationToHours(resource.estimatedDuration ?? "1h")
        }.reduce(0, +)
        
        return ProgressInsight(
            totalHoursLearned: totalHours,
            topicsExplored: Set(completedResources.flatMap { $0.tags }).count,
            strengthAreas: ["iOS Development", "UI Design"],
            improvementAreas: ["Backend Development", "Testing"],
            nextRecommendations: ["Advanced SwiftUI", "CoreData Mastery"]
        )
    }
}

// MARK: - Supporting Models
struct LioAILearningPath {
    let title: String
    let description: String
    let estimatedDuration: String
    let difficulty: String
    let steps: [LearningStep]
}

struct LearningStep {
    let title: String
    let description: String
    let estimatedTime: String
}

struct ProgressInsight {
    let totalHoursLearned: Double
    let topicsExplored: Int
    let strengthAreas: [String]
    let improvementAreas: [String]
    let nextRecommendations: [String]
}

// MARK: - Helper Functions
private extension LioAI {
    static func parseDurationToHours(_ duration: String) -> Double {
        // Simple parser for "2h 30m" format
        let components = duration.components(separatedBy: " ")
        var hours: Double = 0
        
        for component in components {
            if component.hasSuffix("h") {
                hours += Double(component.dropLast()) ?? 0
            } else if component.hasSuffix("m") {
                hours += (Double(component.dropLast()) ?? 0) / 60.0
            }
        }
        
        return max(hours, 1.0) // Minimum 1 hour
    }
}

// MARK: - Error Handling
extension LioAI {
    enum AIError: LocalizedError {
        case responseGenerationFailed
        case contextTooLong
        case rateLimited
        case serviceUnavailable
        
        var errorDescription: String? {
            switch self {
            case .responseGenerationFailed:
                return "Failed to generate AI response"
            case .contextTooLong:
                return "Message is too long for processing"
            case .rateLimited:
                return "Too many requests. Please wait a moment."
            case .serviceUnavailable:
                return "AI service is temporarily unavailable"
            }
        }
    }
}
