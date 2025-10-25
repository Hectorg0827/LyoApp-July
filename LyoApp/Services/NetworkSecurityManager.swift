import Foundation
import Network
import CryptoKit
import OSLog

// MARK: - Network Security Manager
@MainActor
final class NetworkSecurityManager: NSObject, ObservableObject {
    static let shared = NetworkSecurityManager()
    
    private let logger = Logger(subsystem: "com.lyo.app", category: "NetworkSecurity")
    
    // Certificate pinning configuration (only for production)
    private let pinnedDomains: [String] = {
        if BackendConfig.isLocalEnvironment {
            return []  // Skip pinning for local backend
        }
        return ["lyo-backend-830162750094.us-central1.run.app"]
    }()
    private let pinnedCertificateHashes: [String] = [
        // SHA256 hashes of expected certificates (to be updated with actual certificates)
        "E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855" // Placeholder
    ]
    
    // Security policies
    private let allowedTLSVersions: [String] = ["TLSv1.2", "TLSv1.3"]
    private let requiredCipherSuites: [String] = [
        "TLS_AES_256_GCM_SHA384",
        "TLS_CHACHA20_POLY1305_SHA256",
        "TLS_AES_128_GCM_SHA256"
    ]
    
    override init() {
        super.init()
        logger.info("🔒 NetworkSecurityManager initialized")
    }
    
    // MARK: - URL Session with Security
    
    func createSecureURLSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        
        // Basic security configuration
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCredentialStorage = nil
        configuration.httpCookieStorage = nil
        
        // TLS Configuration
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        
        // Create session with custom delegate for certificate pinning
        let session = URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: nil
        )
        
        logger.info("🔒 Secure URL session created with certificate pinning")
        return session
    }
    
    // MARK: - Certificate Validation
    
    private func validateCertificatePinning(for host: String, serverTrust: SecTrust) -> Bool {
        // Skip certificate pinning for local development
        if BackendConfig.isLocalEnvironment {
            logger.info("ℹ️ Certificate pinning skipped for local backend")
            return true
        }
        
        guard pinnedDomains.contains(host) else {
            // Allow non-pinned domains (for development)
            return true
        }
        
        // Get server certificate
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            logger.error("❌ Could not get server certificate")
            return false
        }
        
        // Get certificate data
        let serverCertData = SecCertificateCopyData(serverCertificate)
        let data = CFDataGetBytePtr(serverCertData)
        let size = CFDataGetLength(serverCertData)
        let certData = Data(bytes: data!, count: size)
        
        // Calculate SHA256 hash
        let hash = SHA256.hash(data: certData)
        let hashString = hash.compactMap { String(format: "%02X", $0) }.joined()
        
        // Check against pinned hashes
        let isPinned = pinnedCertificateHashes.contains(hashString)
        
        if isPinned {
            logger.info("✅ Certificate pinning validation successful for \(host)")
        } else {
            logger.error("❌ Certificate pinning validation failed for \(host)")
            logger.error("❌ Expected: \(pinnedCertificateHashes)")
            logger.error("❌ Received: \(hashString)")
        }
        
        return isPinned
    }
    
    // MARK: - Request Security Enhancement
    
    func secureRequest(_ request: inout URLRequest) {
        // Add security headers
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("no-store", forHTTPHeaderField: "Pragma")
        request.setValue("1", forHTTPHeaderField: "DNT")
        request.setValue("same-origin", forHTTPHeaderField: "Sec-Fetch-Site")
        request.setValue("navigate", forHTTPHeaderField: "Sec-Fetch-Mode")
        request.setValue("document", forHTTPHeaderField: "Sec-Fetch-Dest")
        
        // Add user agent
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        request.setValue("LyoApp/\(version) (\(build)) iOS", forHTTPHeaderField: "User-Agent")
        
        // Add request ID for tracking
        request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Request-ID")
        
        // Add device information (anonymized)
        let deviceId = SecureTokenManager.shared.getDeviceId()
        request.setValue(SHA256.hash(data: deviceId.data(using: .utf8)!).compactMap { String(format: "%02x", $0) }.joined(), forHTTPHeaderField: "X-Device-Hash")
    }
    
    // MARK: - Input Validation & Sanitization
    
    func sanitizeUserInput(_ input: String) -> String {
        var sanitized = input
        
        // Remove potentially dangerous characters
        let dangerousChars = CharacterSet(charactersIn: "<>\"'&")
        sanitized = sanitized.components(separatedBy: dangerousChars).joined()
        
        // Limit length
        if sanitized.count > 1000 {
            sanitized = String(sanitized.prefix(1000))
        }
        
        // Trim whitespace
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return sanitized
    }
    
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }
    
    func validatePassword(_ password: String) -> (isValid: Bool, requirements: [String]) {
        var requirements: [String] = []
        var isValid = true
        
        if password.count < 8 {
            requirements.append("At least 8 characters")
            isValid = false
        }
        
        if !password.contains(where: { $0.isUppercase }) {
            requirements.append("At least one uppercase letter")
            isValid = false
        }
        
        if !password.contains(where: { $0.isLowercase }) {
            requirements.append("At least one lowercase letter")
            isValid = false
        }
        
        if !password.contains(where: { $0.isNumber }) {
            requirements.append("At least one number")
            isValid = false
        }
        
        if !password.contains(where: { "!@#$%^&*()_+-=[]{}|;:,.<>?".contains($0) }) {
            requirements.append("At least one special character")
            isValid = false
        }
        
        return (isValid, requirements)
    }
    
    // MARK: - API Security
    
    func generateNonce() -> String {
        return UUID().uuidString
    }
    
    func generateTimestamp() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
    
    func generateRequestSignature(method: String, url: String, params: [String: String] = [:]) -> String {
        // Simple signature generation (in production, use HMAC-SHA256)
        let timestamp = generateTimestamp()
        let nonce = generateNonce()
        
        let baseString = "\(method)&\(url)&\(timestamp)&\(nonce)"
        let hash = SHA256.hash(data: baseString.data(using: .utf8)!)
        
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Security Monitoring
    
    @Published var securityEvents: [SecurityEvent] = []
    
    struct SecurityEvent {
        let timestamp: Date
        let type: EventType
        let description: String
        let severity: Severity
        
        enum EventType {
            case certificateValidationFailed
            case suspiciousRequest
            case authenticationAttempt
            case tokenRefresh
            case dataViolation
        }
        
        enum Severity {
            case low, medium, high, critical
        }
    }
    
    func logSecurityEvent(_ type: SecurityEvent.EventType, description: String, severity: SecurityEvent.Severity = .medium) {
        let event = SecurityEvent(
            timestamp: Date(),
            type: type,
            description: description,
            severity: severity
        )
        
        securityEvents.append(event)
        
        // Keep only last 100 events
        if securityEvents.count > 100 {
            securityEvents.removeFirst(securityEvents.count - 100)
        }
        
        logger.log(level: severity == .critical || severity == .high ? .error : .info,
                  "🚨 Security Event: \(description)")
    }
    
    // MARK: - Network Monitoring
    
    func isNetworkTrusted() -> Bool {
        // Basic network trust assessment
        // In production, this could check for VPN, proxy detection, etc.
        return true
    }
    
    func detectSuspiciousActivity(for request: URLRequest) -> Bool {
        // Basic suspicious activity detection
        guard let url = request.url else { return false }
        
        // Check for suspicious patterns
        let suspiciousPatterns = ["../", "script>", "javascript:", "data:"]
        let urlString = url.absoluteString.lowercased()
        
        for pattern in suspiciousPatterns {
            if urlString.contains(pattern) {
                logSecurityEvent(.suspiciousRequest, 
                               description: "Suspicious pattern detected in URL: \(pattern)",
                               severity: .high)
                return true
            }
        }
        
        return false
    }
}

// MARK: - URLSessionDelegate for Certificate Pinning
extension NetworkSecurityManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, 
                   didReceive challenge: URLAuthenticationChallenge,
                   completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            logger.error("❌ Invalid server trust or host")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Perform certificate pinning validation
        if validateCertificatePinning(for: host, serverTrust: serverTrust) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            logSecurityEvent(.certificateValidationFailed,
                           description: "Certificate pinning failed for host: \(host)",
                           severity: .critical)
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

// MARK: - Security Extensions
extension String {
    var isSecurePassword: Bool {
        return NetworkSecurityManager.shared.validatePassword(self).isValid
    }
    
    var sanitized: String {
        return NetworkSecurityManager.shared.sanitizeUserInput(self)
    }
}

extension URLRequest {
    mutating func applySecurityEnhancements() {
        NetworkSecurityManager.shared.secureRequest(&self)
    }
}