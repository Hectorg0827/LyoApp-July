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
    private let apiClient: LyoAPIService
    private let environment: APIEnvironment
    private let logger = Logger(subsystem: "com.lyo.app", category: "TaskOrchestrator")
    private let overallTimeout: TimeInterval = 600.0 // 10 minutes
    
    init(apiClient: LyoAPIService, environment: APIEnvironment = .current) {
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
            var delay: TimeInterval = 2.0
            let maxDelay: TimeInterval = 30.0
            let maxDuration: TimeInterval = 600.0 // 10 minutes
            let startTime = Date()
            
            logger.info("📊 Starting task polling for: \(taskId)")
            
            while true {
                // Check overall timeout
                if Date().timeIntervalSince(startTime) > overallTimeout {
                    logger.warning("⏰ Task monitoring timeout reached")
                    let timeoutError = ProblemDetails.internalServerError(
                        detail: "Task monitoring timed out after \(maxDuration) seconds"
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

// MARK: - Supporting Types

/// API Environment configuration
enum APIEnvironment {
    case development
    case staging  
    case production
    
    static let current: APIEnvironment = {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }()
    
    var webSocketBase: URL {
        switch self {
        case .development:
            return URL(string: "ws://localhost:8000")!
        case .staging:
            return URL(string: "wss://staging-api.lyoapp.com")!
        case .production:
            return URL(string: "wss://api.lyoapp.com")!
        }
    }
}

/// WebSocket client for real-time task monitoring
private class WebSocketClient {
    private var webSocketTask: URLSessionWebSocketTask?
    
    var connectionStatus: Bool {
        return webSocketTask != nil
    }
    
    func connect(url: URL, onMessage: @escaping (Result<Data, Error>) -> Void) {
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()
        
        receiveMessage(onMessage: onMessage)
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
    }
    
    private func receiveMessage(onMessage: @escaping (Result<Data, Error>) -> Void) {
        webSocketTask?.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        onMessage(.success(data))
                    }
                case .data(let data):
                    onMessage(.success(data))
                @unknown default:
                    break
                }
                
                // Continue receiving messages
                self.receiveMessage(onMessage: onMessage)
                
            case .failure(let error):
                onMessage(.failure(error))
            }
        }
    }
}

/// Problem Details error type for API errors
struct ProblemDetails: Error, Codable {
    let type: String
    let title: String
    let status: Int
    let detail: String?
    let instance: String?
    
    var isRateLimitError: Bool {
        return status == 429
    }
    
    var isServerError: Bool {
        return status >= 500
    }
    
    static func internalServerError(detail: String) -> ProblemDetails {
        return ProblemDetails(
            type: "about:blank",
            title: "Internal Server Error",
            status: 500,
            detail: detail,
            instance: nil
        )
    }
}

// MARK: - Extensions for existing types
extension LyoAPIService {
    /// POST request with custom headers
    func post<T: Codable, R: Codable>(
        _ endpoint: String,
        body: T,
        headers: [String: String]
    ) async throws -> R {
        // Create the request
        guard let url = URL(string: "\(self.baseURL)/\(endpoint)") else {
            throw ProblemDetails.internalServerError(detail: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add custom headers
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        
        // Add authentication if available
        if let token = self.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode body
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProblemDetails.internalServerError(detail: "Invalid response")
            }
            
            // Handle different status codes
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                return try decoder.decode(R.self, from: data)
            case 401:
                throw ProblemDetails(
                    type: "about:blank",
                    title: "Unauthorized",
                    status: 401,
                    detail: "Authentication required",
                    instance: endpoint
                )
            case 429:
                throw ProblemDetails(
                    type: "about:blank", 
                    title: "Rate Limited",
                    status: 429,
                    detail: "Too many requests",
                    instance: endpoint
                )
            case 500...599:
                throw ProblemDetails(
                    type: "about:blank",
                    title: "Server Error",
                    status: httpResponse.statusCode,
                    detail: "Internal server error",
                    instance: endpoint
                )
            default:
                throw ProblemDetails(
                    type: "about:blank",
                    title: "API Error",
                    status: httpResponse.statusCode,
                    detail: "Request failed",
                    instance: endpoint
                )
            }
        } catch {
            if error is ProblemDetails {
                throw error
            }
            throw ProblemDetails.internalServerError(detail: error.localizedDescription)
        }
    }
    
    /// GET request for task status
    func get<R: Codable>(_ endpoint: String) async throws -> R {
        guard let url = URL(string: "\(self.baseURL)/\(endpoint)") else {
            throw ProblemDetails.internalServerError(detail: "Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication if available
        if let token = self.authToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProblemDetails.internalServerError(detail: "Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                return try decoder.decode(R.self, from: data)
            case 401:
                throw ProblemDetails(
                    type: "about:blank",
                    title: "Unauthorized", 
                    status: 401,
                    detail: "Authentication required",
                    instance: endpoint
                )
            case 404:
                throw ProblemDetails(
                    type: "about:blank",
                    title: "Not Found",
                    status: 404,
                    detail: "Resource not found",
                    instance: endpoint
                )
            case 429:
                throw ProblemDetails(
                    type: "about:blank",
                    title: "Rate Limited",
                    status: 429,
                    detail: "Too many requests", 
                    instance: endpoint
                )
            case 500...599:
                throw ProblemDetails(
                    type: "about:blank",
                    title: "Server Error",
                    status: httpResponse.statusCode,
                    detail: "Internal server error",
                    instance: endpoint
                )
            default:
                throw ProblemDetails(
                    type: "about:blank",
                    title: "API Error",
                    status: httpResponse.statusCode,
                    detail: "Request failed",
                    instance: endpoint
                )
            }
        } catch {
            if error is ProblemDetails {
                throw error
            }
            throw ProblemDetails.internalServerError(detail: error.localizedDescription)
        }
    }
}