import Foundation

// MARK: - Canonical SystemHealthResponse
// Unified model used by LyoAPIService & ErrorHandlingService.
// All prior scattered variants are deprecated/disabled.
public struct SystemHealthResponse: Codable, Sendable {
    public let status: String                 // e.g. "healthy", "degraded", "down"
    public let version: String?               // backend/API semantic version (optional)
    public let timestamp: String?             // ISO8601 timestamp string (optional)
    public let service: String?               // service identifier (optional)
    public let environment: String?           // deployment environment (optional)
    public let endpoints: [String: String]?   // endpoint status mapping (optional)
    public let services: [String: String]?    // legacy subsystem status mapping (optional)

    public init(
        status: String,
        version: String? = nil,
        timestamp: String? = nil,
        service: String? = nil,
        environment: String? = nil,
        endpoints: [String: String]? = nil,
        services: [String: String]? = nil
    ) {
        self.status = status
        self.version = version ?? "unknown"
        self.timestamp = timestamp ?? ISO8601DateFormatter().string(from: Date())
        self.service = service
        self.environment = environment
        self.endpoints = endpoints
        self.services = services
    }

    // Accept "degraded" as operational so the app can start while showing warnings.
    public var isHealthy: Bool { status == "healthy" || status == "operational" || status == "degraded" }
    
    // Custom decoder to handle various backend response formats
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Status is required
        status = try container.decode(String.self, forKey: .status)
        
        // Version is optional
        version = try? container.decode(String.self, forKey: .version)
        
        // Timestamp is optional
        timestamp = try? container.decode(String.self, forKey: .timestamp)

        // Additional metadata fields (optional)
        service = try? container.decode(String.self, forKey: .service)
        environment = try? container.decode(String.self, forKey: .environment)
        endpoints = try? container.decode([String: String].self, forKey: .endpoints)
        services = try? container.decode([String: String].self, forKey: .services)
    }
    
    private enum CodingKeys: String, CodingKey {
        case status
        case version
        case timestamp
        case service
        case environment
        case endpoints
        case services
    }

    public static func mock(healthy: Bool = true) -> SystemHealthResponse {
        SystemHealthResponse(
            status: healthy ? "healthy" : "degraded",
            version: "1.0.0",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            service: "Mock Backend",
            environment: healthy ? "production" : "degraded",
            endpoints: [
                "auth": healthy ? "active" : "degraded",
                "feed": healthy ? "active" : "degraded"
            ],
            services: [
                "api": healthy ? "operational" : "degraded",
                "database": "operational",
                "ai": healthy ? "operational" : "warming"
            ]
        )
    }
}

// Backwards compatibility alias guard (only active if some stale cached reference expects a namespaced variant).
// Remove after confirming builds no longer emit 'cannot find type SystemHealthResponse' stemming from duplicates.
@available(*, deprecated, message: "Canonical SystemHealthResponse in root is the single source of truth")
public typealias LyoSystemHealthResponse = SystemHealthResponse
