import Foundation

/// Demo task orchestrator for testing the course generation UI without a backend
class DemoTaskOrchestrator {
    private let logger = Logger(subsystem: "com.lyo.app", category: "DemoTaskOrchestrator")
    
    /// Simulate course generation with realistic progress updates
    func generateCourse(
        topic: String,
        interests: [String],
        onProgress: @escaping (TaskEvent) -> Void
    ) async throws -> String {
        
        logger.info("🎭 Starting demo course generation for topic: \(topic)")
        
        // Generate a realistic course ID
        let courseId = "course_\(UUID().uuidString.prefix(8))"
        let taskId = "task_\(UUID().uuidString.prefix(8))"
        
        // Track analytics for demo
        Analytics.shared.track("course_generate_requested", properties: [
            "task_id": taskId,
            "provisional_course_id": courseId,
            "demo_mode": true
        ])
        
        // Simulate the course generation process with realistic timing
        let progressSteps = [
            (10, "Analyzing topic: \(topic)..."),
            (25, "Gathering relevant content..."),
            (40, "Structuring course outline..."),
            (55, "Creating learning objectives..."),
            (70, "Generating chapter content..."),
            (85, "Adding exercises and assessments..."),
            (95, "Finalizing course structure..."),
            (100, "Course generation complete!")
        ]
        
        for (progress, message) in progressSteps {
            // Send progress update
            let event = TaskEvent(
                state: progress < 100 ? .running : .done,
                progressPct: progress,
                message: message,
                resultId: progress == 100 ? courseId : nil,
                error: nil
            )
            
            await MainActor.run {
                onProgress(event)
            }
            
            // Track progress analytics
            if progress < 100 {
                Analytics.shared.track("course_generate_running", properties: [
                    "task_id": taskId,
                    "progress": progress,
                    "message": message,
                    "demo_mode": true
                ])
            } else {
                Analytics.shared.track("course_generate_ready", properties: [
                    "task_id": taskId,
                    "result_id": courseId,
                    "demo_mode": true
                ])
            }
            
            // Realistic delay between updates (1-3 seconds)
            let delay = TimeInterval.random(in: 1.0...3.0)
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        logger.info("✅ Demo course generation completed: \(courseId)")
        return courseId
    }
    
    /// Simulate an error scenario for testing error handling
    func generateCourseWithError(
        topic: String,
        interests: [String], 
        onProgress: @escaping (TaskEvent) -> Void
    ) async throws -> String {
        
        // Start normally
        let taskId = "task_\(UUID().uuidString.prefix(8))"
        
        let event = TaskEvent(
            state: .running,
            progressPct: 20,
            message: "Starting course generation...",
            resultId: nil,
            error: nil
        )
        
        await MainActor.run {
            onProgress(event)
        }
        
        // Wait a bit then simulate error
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let errorEvent = TaskEvent(
            state: .error,
            progressPct: 20,
            message: "Generation failed",
            resultId: nil,
            error: "Demo error: Unable to process topic '\(topic)'"
        )
        
        await MainActor.run {
            onProgress(errorEvent)
        }
        
        Analytics.shared.track("course_generate_error", properties: [
            "task_id": taskId,
            "error": "Demo error",
            "demo_mode": true
        ])
        
        throw ProblemDetails.internalServerError(detail: "Demo error: Course generation failed")
    }
}

// MARK: - Logger import fix
import OSLog