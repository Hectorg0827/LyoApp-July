import Foundation
import OSLog

/// Task state from server
struct TaskEvent: Decodable {
    enum State: String, Decodable {
        case queued
        case running
        case done
        case error
    }
    
    let state: State
    let progressPct: Int?
    let message: String?
    let resultId: String?
    let error: String?
    
    /// Whether this is a terminal state
    var isTerminal: Bool {
        return state == .done || state == .error
    }
}

/// Task orchestrator for managing long-running operations with WebSocket + polling fallback
final class TaskOrchestrator {
    private let apiClient: APIClient
    private let environment: APIEnvironment
    private let logger = Logger(subsystem: "com.lyo.app", category: "TaskOrchestrator")
    
    init(apiClient: APIClient, environment: APIEnvironment = .current) {
        self.apiClient = apiClient
        self.environment = environment
    }
    
    // MARK: - Course Generation
    
    /// Start course generation and return task info
    func startCourseGeneration(topic: String, interests: [String]) async throws -> (taskId: String, provisionalCourseId: String) {
        
        let requestBody = CourseGenerationRequest(topic: topic, interests: interests)
        let headers = [
            "Idempotency-Key": UUID().uuidString,
            "Prefer": "respond-async"
        ]
        
        let response: CourseGenerationResponse = try await apiClient.post(
            "courses:generate",
            body: requestBody,
            headers: headers
        )
        
        logger.info("🚀 Course generation started - Task: \(response.task_id), Course: \(response.provisional_course_id)")
        
        // Track analytics event
        Analytics.log("course_generate_requested", [
            "task_id": response.task_id,
            "provisional_course_id": response.provisional_course_id
        ])
        
        return (response.task_id, response.provisional_course_id)
    }
    
    // MARK: - Task Monitoring
    
    /// Monitor task progress via WebSocket with automatic fallback to polling
    func monitorTask(
        taskId: String,
        onUpdate: @escaping (TaskEvent) -> Void,
        onCompletion: @escaping (Result<TaskEvent, Error>) -> Void
    ) {
        logger.info("👀 Starting task monitoring for: \(taskId)")
        
        // Try WebSocket first
        monitorViaWebSocket(
            taskId: taskId,
            onUpdate: onUpdate,
            onFallbackNeeded: { [weak self] in
                self?.logger.warning("🔄 WebSocket failed, falling back to polling")
                self?.monitorViaPolling(taskId: taskId, onUpdate: onUpdate, onCompletion: onCompletion)
            },
            onCompletion: onCompletion
        )
    }
    
    // MARK: - WebSocket Monitoring
    
    private func monitorViaWebSocket(
        taskId: String,
        onUpdate: @escaping (TaskEvent) -> Void,
        onFallbackNeeded: @escaping () -> Void,
        onCompletion: @escaping (Result<TaskEvent, Error>) -> Void
    ) {
        let wsURL = environment.webSocketBase.appendingPathComponent("v1/ws/tasks/\(taskId)")
        let webSocket = WebSocketClient()
        
        var fallbackTriggered = false
        
        webSocket.connect(url: wsURL) { [weak self] result in
            switch result {
            case .success(let data):
                do {
                    let event = try JSONDecoder().decode(TaskEvent.self, from: data)
                    
                    // Track analytics based on event state
                    switch event.state {
                    case .running:
                        Analytics.log("course_generate_running", [
                            "task_id": taskId,
                            "progress": event.progressPct ?? 0,
                            "message": event.message ?? ""
                        ])
                    case .done:
                        Analytics.log("course_generate_ready", [
                            "task_id": taskId,
                            "result_id": event.resultId ?? ""
                        ])
                    case .error:
                        Analytics.log("course_generate_error", [
                            "task_id": taskId,
                            "error": event.error ?? "Unknown error"
                        ])
                    default:
                        break
                    }
                    
                    DispatchQueue.main.async {
                        onUpdate(event)
                        
                        if event.isTerminal {
                            webSocket.disconnect()
                            onCompletion(.success(event))
                        }
                    }
                    
                } catch {
                    self?.logger.error("❌ Failed to decode WebSocket task event: \(error)")
                    
                    if !fallbackTriggered {
                        fallbackTriggered = true
                        webSocket.disconnect()
                        onFallbackNeeded()
                    }
                }
                
            case .failure(let error):
                self?.logger.error("❌ WebSocket error: \(error)")
                
                if !fallbackTriggered {
                    fallbackTriggered = true
                    webSocket.disconnect()
                    onFallbackNeeded()
                }
            }
        }
        
        // Set a timeout for WebSocket connection
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 10) {
            if !webSocket.connectionStatus && !fallbackTriggered {
                fallbackTriggered = true
                webSocket.disconnect()
                onFallbackNeeded()
            }
        }
    }
    
    // MARK: - Polling Monitoring
    
    private func monitorViaPolling(
        taskId: String,
        onUpdate: @escaping (TaskEvent) -> Void,
        onCompletion: @escaping (Result<TaskEvent, Error>) -> Void
    ) {
        Task {
            var delay: TimeInterval = 1.5 // Start with 1.5 second delay
            let maxDelay: TimeInterval = 10.0 // Cap at 10 seconds
            let overallTimeout: TimeInterval = 15 * 60 // 15 minutes total timeout
            let startTime = Date()
            
            logger.info("📊 Starting task polling for: \(taskId)")
            
            while true {
                // Check overall timeout
                if Date().timeIntervalSince(startTime) > overallTimeout {
                    logger.warning("⏰ Task monitoring timeout reached")
                    
                    // Track timeout analytics
                    Analytics.log("course_generate_timeout", [
                        "task_id": taskId,
                        "timeout_duration": overallTimeout
                    ])
                    
                    let timeoutError = ProblemDetails.internalServerError(
                        detail: "Task monitoring timed out after \(Int(overallTimeout / 60)) minutes. We'll notify you when it's ready."
                    )
                    await MainActor.run {
                        onCompletion(.failure(timeoutError))
                    }
                    break
                }
                
                do {
                    let event: TaskEvent = try await apiClient.get("tasks/\(taskId)")
                    
                    await MainActor.run {
                        onUpdate(event)
                        
                        if event.isTerminal {
                            onCompletion(.success(event))
                        }
                    }
                    
                    // Break if task is done
                    if event.isTerminal {
                        break
                    }
                    
                    // Wait before next poll
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    // Increase delay with exponential backoff
                    delay = min(delay * 1.6, maxDelay)
                    
                } catch {
                    logger.error("❌ Polling error: \(error)")
                    
                    // Handle specific error types
                    if let problemDetails = error as? ProblemDetails {
                        if problemDetails.isRateLimitError {
                            // Increase delay significantly for rate limits
                            delay = min(delay * 2.0, 30.0)
                        } else if problemDetails.isServerError {
                            // Back off for server errors
                            delay = min(delay * 1.8, maxDelay)
                        } else {
                            // For other errors, fail immediately
                            await MainActor.run {
                                onCompletion(.failure(error))
                            }
                            break
                        }
                    }
                    
                    // Wait before retrying
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
    }
}

// MARK: - Request/Response Models
private struct CourseGenerationRequest: Codable {
    let topic: String
    let interests: [String]
}

private struct CourseGenerationResponse: Codable {
    let task_id: String
    let provisional_course_id: String
}

// MARK: - Convenience Methods
extension TaskOrchestrator {
    
    /// Simplified course generation with automatic monitoring
    func generateCourse(
        topic: String,
        interests: [String],
        onProgress: @escaping (TaskEvent) -> Void
    ) async throws -> String {
        
        // Start generation
        let (taskId, provisionalCourseId) = try await startCourseGeneration(topic: topic, interests: interests)
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            monitorTask(
                taskId: taskId,
                onUpdate: onProgress,
                onCompletion: { result in
                    guard !hasResumed else { return }
                    hasResumed = true
                    
                    switch result {
                    case .success(let event):
                        if event.state == .done, let resultId = event.resultId {
                            continuation.resume(returning: resultId)
                        } else if event.state == .error {
                            let error = ProblemDetails.internalServerError(
                                detail: event.error ?? "Course generation failed"
                            )
                            continuation.resume(throwing: error)
                        }
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }
}