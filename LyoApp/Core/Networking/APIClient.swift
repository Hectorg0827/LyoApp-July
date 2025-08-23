import Foundation
import OSLog

/// Production-ready API client with auth injection and automatic token refresh
public struct APIClient {
    private let environment: APIEnvironment
    private let authManager: AuthManager
    private let session: URLSession
    private let logger = Logger(subsystem: "com.lyo.app", category: "APIClient")
    
    public init(environment: APIEnvironment = .current) {
        self.environment = environment
        // Create a temporary AuthManager for initialization - will be replaced
        self.authManager = AuthManager(apiClient: nil)
        
        // Configure URLSession for production use
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        config.waitsForConnectivity = true
        config.allowsCellularAccess = true
        
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Main Request Method
    
    /// Generic request method with automatic auth injection and 401 handling
    func send<T: Decodable, B: Encodable>(
        _ path: String,
        method: String = "GET",
        body: B? = nil,
        headers: [String: String] = [:],
        retryCount: Int = 0
    ) async throws -> T {
        
        // Build request
        let url = environment.v1.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add custom headers
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add authorization header
        await authManager.authorize(&request)
        
        // Add request body if provided
        if let body = body {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try encoder.encode(body)
            } catch {
                logger.error("Failed to encode request body: \(error.localizedDescription)")
                throw ProblemDetails.invalidRequest(detail: "Failed to encode request body")
            }
        }
        
        // Log request (redact sensitive headers)
        logRequest(request)
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProblemDetails.internalServerError(detail: "Invalid response type")
            }
            
            // Log response
            logResponse(httpResponse, data: data)
            
            // Handle status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success - decode and return
                return try decodeResponse(data)
                
            case 401:
                // Unauthorized - attempt token refresh and retry once
                if retryCount == 0 {
                    logger.info("Received 401, attempting token refresh...")
                    try await authManager.refreshTokens(using: environment)
                    return try await send(path, method: method, body: body, headers: headers, retryCount: 1)
                } else {
                    // Already retried, authentication failed
                    throw try decodeErrorResponse(data) ?? ProblemDetails.unauthorized()
                }
                
            case 400...499:
                // Client error - decode Problem Details if available
                throw try decodeErrorResponse(data) ?? ProblemDetails.invalidRequest(detail: "Client error: \(httpResponse.statusCode)")
                
            case 500...599:
                // Server error - decode Problem Details if available
                throw try decodeErrorResponse(data) ?? ProblemDetails.internalServerError(detail: "Server error: \(httpResponse.statusCode)")
                
            default:
                // Unexpected status code
                throw ProblemDetails.internalServerError(detail: "Unexpected status code: \(httpResponse.statusCode)")
            }
            
        } catch let error as ProblemDetails {
            throw error
        } catch {
            logger.error("Network request failed: \(error.localizedDescription)")
            throw ProblemDetails.internalServerError(detail: "Network request failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Response Decoding
    
    private func decodeResponse<T: Decodable>(_ data: Data) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.error("Response decoding failed: \(error.localizedDescription)")
            
            // Log sample of response data for debugging (first 500 chars)
            if let responseString = String(data: data, encoding: .utf8) {
                let sample = String(responseString.prefix(500))
                logger.debug("Response sample: \(sample)")
            }
            
            throw ProblemDetails.internalServerError(detail: "Failed to decode response")
        }
    }
    
    private func decodeErrorResponse(_ data: Data) throws -> ProblemDetails? {
        do {
            return try JSONDecoder().decode(ProblemDetails.self, from: data)
        } catch {
            // If we can't decode as ProblemDetails, return nil
            return nil
        }
    }
    
    // MARK: - Logging
    
    private func logRequest(_ request: URLRequest) {
        #if DEBUG
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown"
        
        logger.info("🌐 \(method) \(url)")
        
        // Log headers (redact sensitive ones)
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers {
                if key.lowercased().contains("authorization") {
                    logger.debug("📋 \(key): [REDACTED]")
                } else {
                    logger.debug("📋 \(key): \(value)")
                }
            }
        }
        
        // Log body (limit size)
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            let truncated = String(bodyString.prefix(200))
            logger.debug("📦 Body: \(truncated)\(bodyString.count > 200 ? "..." : "")")
        }
        #endif
    }
    
    private func logResponse(_ response: HTTPURLResponse, data: Data) {
        #if DEBUG
        let status = response.statusCode
        let url = response.url?.absoluteString ?? "unknown"
        
        logger.info("📥 \(status) \(url)")
        
        // Log response body for errors or debug mode
        if status >= 400, let responseString = String(data: data, encoding: .utf8) {
            let truncated = String(responseString.prefix(500))
            logger.debug("📦 Error Response: \(truncated)\(responseString.count > 500 ? "..." : "")")
        }
        #endif
    }
}

// MARK: - Convenience Methods
extension APIClient {
    
    /// GET request
    func get<T: Decodable>(_ path: String, headers: [String: String] = [:]) async throws -> T {
        return try await send(path, method: "GET", body: EmptyBody?.none, headers: headers)
    }
    
    /// POST request
    func post<T: Decodable, B: Encodable>(_ path: String, body: B, headers: [String: String] = [:]) async throws -> T {
        return try await send(path, method: "POST", body: body, headers: headers)
    }
    
    /// PUT request
    func put<T: Decodable, B: Encodable>(_ path: String, body: B, headers: [String: String] = [:]) async throws -> T {
        return try await send(path, method: "PUT", body: body, headers: headers)
    }
    
    /// DELETE request
    func delete(_ path: String, headers: [String: String] = [:]) async throws {
        let _: EmptyResponse = try await send(path, method: "DELETE", body: EmptyBody?.none, headers: headers)
    }
}

// MARK: - Helper Types
private struct EmptyBody: Encodable {}
private struct EmptyResponse: Decodable {}

// MARK: - Request ID Generation
extension APIClient {
    
    /// Add request ID for tracking
    private func addRequestId(to request: inout URLRequest) {
        let requestId = UUID().uuidString.prefix(8)
        request.setValue(String(requestId), forHTTPHeaderField: "X-Request-ID")
    }
}