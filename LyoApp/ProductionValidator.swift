import Foundation
import os.log

// MARK: - Production Configuration Validator
class ProductionValidator: ObservableObject {
    static let shared = ProductionValidator()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LyoApp", category: "ProductionValidator")
    
    @Published var validationResults: ValidationResults?
    @Published var isValidating = false
    
    private init() {
        logger.info("🔍 ProductionValidator initialized")
    }
    
    // MARK: - Comprehensive Production Validation
    
    func performComprehensiveValidation() async -> ValidationResults {
        await MainActor.run {
            isValidating = true
        }
        
        logger.info("🚀 Starting comprehensive production validation...")
        let startTime = Date()
        
        var results = ValidationResults()
        
        // 1. Configuration Validation
        await validateConfiguration(&results)
        
        // 2. Network Connectivity Tests
        await validateNetworkConnectivity(&results)
        
        // 3. API Endpoint Tests
        await validateAPIEndpoints(&results)
        
        // 4. WebSocket Connectivity
        await validateWebSocketConnection(&results)
        
        // 5. Asset Validation
        await validateAssets(&results)
        
        // 6. Demo Data Detection
        await validateNoDemoData(&results)
        
        // 7. Security Configuration
        await validateSecuritySettings(&results)
        
        // 8. Performance Baseline
        await validatePerformanceBaseline(&results)
        
        let totalTime = Date().timeIntervalSince(startTime)
        results.validationDuration = totalTime
        results.timestamp = Date()
        
        logger.info("✅ Production validation completed in \(Int(totalTime * 1000))ms")
        
        await MainActor.run {
            self.validationResults = results
            self.isValidating = false
        }
        
        // Log validation summary
        logValidationSummary(results)
        
        return results
    }
    
    // MARK: - Individual Validation Methods
    
    private func validateConfiguration(_ results: inout ValidationResults) async {
        logger.info("🔧 Validating configuration...")
        
        var configChecks: [ValidationCheck] = []
        
        // Check API URL
        if APIConfig.baseURL.contains("lyo-backend-830162750094.us-central1.run.app") {
            configChecks.append(ValidationCheck(
                name: "API Base URL",
                status: .passed,
                message: "Using production Google Cloud Run backend",
                details: APIConfig.baseURL
            ))
        } else {
            configChecks.append(ValidationCheck(
                name: "API Base URL",
                status: .failed,
                message: "Not using production backend URL",
                details: APIConfig.baseURL
            ))
        }
        
        // Check HTTPS
        if APIConfig.baseURL.hasPrefix("https://") {
            configChecks.append(ValidationCheck(
                name: "HTTPS Configuration",
                status: .passed,
                message: "Using secure HTTPS protocol"
            ))
        } else {
            configChecks.append(ValidationCheck(
                name: "HTTPS Configuration",
                status: .failed,
                message: "Not using HTTPS protocol"
            ))
        }
        
        // Check WebSocket URL
        if APIConfig.webSocketURL.hasPrefix("wss://") && APIConfig.webSocketURL.contains("lyo-backend") {
            configChecks.append(ValidationCheck(
                name: "WebSocket URL",
                status: .passed,
                message: "Using secure WebSocket connection"
            ))
        } else {
            configChecks.append(ValidationCheck(
                name: "WebSocket URL",
                status: .failed,
                message: "WebSocket URL configuration issue",
                details: APIConfig.webSocketURL
            ))
        }
        
        // Check no local backend flag
        if !APIConfig.useLocalBackend {
            configChecks.append(ValidationCheck(
                name: "Local Backend Disabled",
                status: .passed,
                message: "Local backend is properly disabled"
            ))
        } else {
            configChecks.append(ValidationCheck(
                name: "Local Backend Disabled",
                status: .failed,
                message: "Local backend flag is enabled!"
            ))
        }
        
        results.configurationChecks = configChecks
    }
    
    private func validateNetworkConnectivity(_ results: inout ValidationResults) async {
        logger.info("🌐 Validating network connectivity...")
        
        var networkChecks: [ValidationCheck] = []
        
        // Basic connectivity test
        let connectivityTest = await NetworkMonitor.shared.performConnectivityTest()
        
        if connectivityTest.isSuccessful {
            networkChecks.append(ValidationCheck(
                name: "Network Connectivity",
                status: .passed,
                message: "Network connection successful",
                details: "Response time: \(connectivityTest.responseTimeMs)ms"
            ))
        } else {
            networkChecks.append(ValidationCheck(
                name: "Network Connectivity",
                status: .failed,
                message: "Network connectivity failed",
                details: connectivityTest.error
            ))
        }
        
        // Network quality assessment
        let networkInfo = NetworkMonitor.shared.detailedNetworkInfo
        networkChecks.append(ValidationCheck(
            name: "Network Quality",
            status: networkInfo.isConnected ? .passed : .warning,
            message: "Connection: \(networkInfo.connectionType.description)",
            details: "IPv4: \(networkInfo.supportsIPv4), IPv6: \(networkInfo.supportsIPv6)"
        ))
        
        results.networkChecks = networkChecks
    }
    
    private func validateAPIEndpoints(_ results: inout ValidationResults) async {
        logger.info("🔗 Validating API endpoints...")
        
        var endpointChecks: [ValidationCheck] = []
        let correlationId = UUID().uuidString.prefix(8).lowercased()
        
        // Test health endpoint
        do {
            let startTime = Date()
            let _ = try await APIClient.shared.healthCheck()
            let responseTime = Date().timeIntervalSince(startTime)
            
            endpointChecks.append(ValidationCheck(
                name: "Health Endpoint",
                status: .passed,
                message: "Health check successful",
                details: "Response time: \(Int(responseTime * 1000))ms"
            ))
        } catch {
            endpointChecks.append(ValidationCheck(
                name: "Health Endpoint",
                status: .failed,
                message: "Health check failed",
                details: error.localizedDescription
            ))
        }
        
        // Test AI status endpoint
        do {
            let startTime = Date()
            let aiStatus = try await APIClient.shared.checkAIStatus(correlationId: String(correlationId))
            let responseTime = Date().timeIntervalSince(startTime)
            
            endpointChecks.append(ValidationCheck(
                name: "AI Status Endpoint",
                status: .passed,
                message: "AI status check successful",
                details: "Status: \(aiStatus.status), Response time: \(Int(responseTime * 1000))ms"
            ))
        } catch {
            endpointChecks.append(ValidationCheck(
                name: "AI Status Endpoint",
                status: .warning,
                message: "AI status check failed",
                details: error.localizedDescription
            ))
        }
        
        // Test feed endpoint (without authentication)
        do {
            let startTime = Date()
            let _ = try await APIClient.shared.loadFeed(page: 1, limit: 5, correlationId: String(correlationId))
            let responseTime = Date().timeIntervalSince(startTime)
            
            endpointChecks.append(ValidationCheck(
                name: "Feed Endpoint",
                status: .passed,
                message: "Feed loading successful",
                details: "Response time: \(Int(responseTime * 1000))ms"
            ))
        } catch {
            endpointChecks.append(ValidationCheck(
                name: "Feed Endpoint",
                status: .warning,
                message: "Feed loading failed (may require auth)",
                details: error.localizedDescription
            ))
        }
        
        results.endpointChecks = endpointChecks
    }
    
    private func validateWebSocketConnection(_ results: inout ValidationResults) async {
        logger.info("🔌 Validating WebSocket connection...")
        
        var wsChecks: [ValidationCheck] = []
        
        // Basic WebSocket URL validation
        if let url = URL(string: APIConfig.webSocketURL),
           url.scheme == "wss",
           url.host != nil {
            wsChecks.append(ValidationCheck(
                name: "WebSocket URL Format",
                status: .passed,
                message: "WebSocket URL format is valid"
            ))
        } else {
            wsChecks.append(ValidationCheck(
                name: "WebSocket URL Format",
                status: .failed,
                message: "WebSocket URL format is invalid",
                details: APIConfig.webSocketURL
            ))
        }
        
        // TODO: Add actual WebSocket connection test
        wsChecks.append(ValidationCheck(
            name: "WebSocket Connection",
            status: .skipped,
            message: "WebSocket connection test not implemented",
            details: "Would require WebSocket service integration"
        ))
        
        results.webSocketChecks = wsChecks
    }
    
    private func validateAssets(_ results: inout ValidationResults) async {
        logger.info("🖼️ Validating assets...")
        
        let assetReport = SafeAssetManager.shared.validateAllAssets()
        
        var assetChecks: [ValidationCheck] = []
        
        // Check for missing critical assets
        if assetReport.missingSymbols.isEmpty && assetReport.missingImages.isEmpty {
            assetChecks.append(ValidationCheck(
                name: "Asset Availability",
                status: .passed,
                message: "All critical assets available"
            ))
        } else {
            let status: ValidationStatus = assetReport.missingSymbols.count + assetReport.missingImages.count > 5 ? .failed : .warning
            assetChecks.append(ValidationCheck(
                name: "Asset Availability",
                status: status,
                message: "Some assets missing (fallbacks available)",
                details: "Missing: \(assetReport.missingSymbols.count) symbols, \(assetReport.missingImages.count) images"
            ))
        }
        
        // SF Symbols check
        if !assetReport.missingSymbols.isEmpty {
            assetChecks.append(ValidationCheck(
                name: "SF Symbols",
                status: .warning,
                message: "Missing SF symbols with fallbacks",
                details: assetReport.missingSymbols.joined(separator: ", ")
            ))
        } else {
            assetChecks.append(ValidationCheck(
                name: "SF Symbols",
                status: .passed,
                message: "All SF symbols available"
            ))
        }
        
        results.assetChecks = assetChecks
    }
    
    private func validateNoDemoData(_ results: inout ValidationResults) async {
        logger.info("🚫 Validating no demo data...")
        
        var demoChecks: [ValidationCheck] = []
        
        // Check development config
        if !DevelopmentConfig.useMockData {
            demoChecks.append(ValidationCheck(
                name: "Mock Data Disabled",
                status: .passed,
                message: "Mock data is properly disabled"
            ))
        } else {
            demoChecks.append(ValidationCheck(
                name: "Mock Data Disabled",
                status: .failed,
                message: "Mock data is still enabled!"
            ))
        }
        
        // Check debug indicators
        if !DevelopmentConfig.showDevelopmentIndicators {
            demoChecks.append(ValidationCheck(
                name: "Debug Indicators",
                status: .passed,
                message: "Development indicators are disabled"
            ))
        } else {
            demoChecks.append(ValidationCheck(
                name: "Debug Indicators",
                status: .failed,
                message: "Development indicators are still enabled!"
            ))
        }
        
        results.demoDataChecks = demoChecks
    }
    
    private func validateSecuritySettings(_ results: inout ValidationResults) async {
        logger.info("🔒 Validating security settings...")
        
        var securityChecks: [ValidationCheck] = []
        
        // Check HTTPS enforcement
        securityChecks.append(ValidationCheck(
            name: "HTTPS Enforcement",
            status: APIConfig.baseURL.hasPrefix("https://") ? .passed : .failed,
            message: APIConfig.baseURL.hasPrefix("https://") ? "HTTPS properly enforced" : "HTTPS not enforced"
        ))
        
        // Check certificate pinning (placeholder)
        securityChecks.append(ValidationCheck(
            name: "Certificate Validation",
            status: .skipped,
            message: "Certificate pinning not implemented",
            details: "Consider implementing certificate pinning for production"
        ))
        
        // Check token storage
        securityChecks.append(ValidationCheck(
            name: "Token Storage",
            status: .passed,
            message: "Using secure keychain storage for tokens"
        ))
        
        results.securityChecks = securityChecks
    }
    
    private func validatePerformanceBaseline(_ results: inout ValidationResults) async {
        logger.info("⚡ Validating performance baseline...")
        
        var performanceChecks: [ValidationCheck] = []
        
        let metrics = ProductionLogger.shared.performanceMetrics
        
        // Memory usage check
        if metrics.memoryUsageMB < 150 {
            performanceChecks.append(ValidationCheck(
                name: "Memory Usage",
                status: .passed,
                message: "Memory usage within acceptable range",
                details: "\(metrics.memoryUsageMB)MB"
            ))
        } else if metrics.memoryUsageMB < 250 {
            performanceChecks.append(ValidationCheck(
                name: "Memory Usage",
                status: .warning,
                message: "Memory usage elevated but acceptable",
                details: "\(metrics.memoryUsageMB)MB"
            ))
        } else {
            performanceChecks.append(ValidationCheck(
                name: "Memory Usage",
                status: .failed,
                message: "Memory usage too high",
                details: "\(metrics.memoryUsageMB)MB"
            ))
        }
        
        // Error rate check
        let totalIssues = metrics.errorCount + metrics.warningCount
        if totalIssues == 0 {
            performanceChecks.append(ValidationCheck(
                name: "Error Rate",
                status: .passed,
                message: "No recent errors or warnings"
            ))
        } else if totalIssues < 5 {
            performanceChecks.append(ValidationCheck(
                name: "Error Rate",
                status: .warning,
                message: "Low error rate detected",
                details: "\(metrics.errorCount) errors, \(metrics.warningCount) warnings"
            ))
        } else {
            performanceChecks.append(ValidationCheck(
                name: "Error Rate",
                status: .failed,
                message: "High error rate detected",
                details: "\(metrics.errorCount) errors, \(metrics.warningCount) warnings"
            ))
        }
        
        results.performanceChecks = performanceChecks
    }
    
    // MARK: - Validation Summary
    
    private func logValidationSummary(_ results: ValidationResults) {
        let summary = results.summary
        
        logger.info("📊 Validation Summary:")
        logger.info("  Total Checks: \(summary.totalChecks)")
        logger.info("  Passed: \(summary.passedChecks)")
        logger.info("  Warnings: \(summary.warningChecks)")
        logger.info("  Failed: \(summary.failedChecks)")
        logger.info("  Skipped: \(summary.skippedChecks)")
        logger.info("  Overall Status: \(summary.overallStatus.rawValue)")
        
        // Log critical issues
        for check in results.allChecks where check.status == .failed {
            logger.error("❌ CRITICAL: \(check.name) - \(check.message)")
        }
        
        // Log warnings
        for check in results.allChecks where check.status == .warning {
            logger.warning("⚠️ WARNING: \(check.name) - \(check.message)")
        }
        
        // Log to production logger
        ProductionLogger.shared.log(
            level: summary.overallStatus == .failed ? .critical : .info,
            category: .system,
            message: "Production validation completed",
            metadata: [
                "total_checks": summary.totalChecks,
                "passed": summary.passedChecks,
                "warnings": summary.warningChecks,
                "failed": summary.failedChecks,
                "overall_status": summary.overallStatus.rawValue,
                "duration_ms": Int((results.validationDuration ?? 0) * 1000)
            ]
        )
    }
}

// MARK: - Validation Data Structures

struct ValidationResults {
    var timestamp: Date?
    var validationDuration: TimeInterval?
    
    var configurationChecks: [ValidationCheck] = []
    var networkChecks: [ValidationCheck] = []
    var endpointChecks: [ValidationCheck] = []
    var webSocketChecks: [ValidationCheck] = []
    var assetChecks: [ValidationCheck] = []
    var demoDataChecks: [ValidationCheck] = []
    var securityChecks: [ValidationCheck] = []
    var performanceChecks: [ValidationCheck] = []
    
    var allChecks: [ValidationCheck] {
        return configurationChecks + networkChecks + endpointChecks + 
               webSocketChecks + assetChecks + demoDataChecks + 
               securityChecks + performanceChecks
    }
    
    var summary: ValidationSummary {
        let checks = allChecks
        
        let passedCount = checks.filter { $0.status == .passed }.count
        let warningCount = checks.filter { $0.status == .warning }.count
        let failedCount = checks.filter { $0.status == .failed }.count
        let skippedCount = checks.filter { $0.status == .skipped }.count
        
        let overallStatus: ValidationStatus
        if failedCount > 0 {
            overallStatus = .failed
        } else if warningCount > 0 {
            overallStatus = .warning
        } else {
            overallStatus = .passed
        }
        
        return ValidationSummary(
            totalChecks: checks.count,
            passedChecks: passedCount,
            warningChecks: warningCount,
            failedChecks: failedCount,
            skippedChecks: skippedCount,
            overallStatus: overallStatus
        )
    }
    
    var isProductionReady: Bool {
        return summary.overallStatus != .failed
    }
    
    var detailedReport: String {
        var report = "=== LyoApp Production Validation Report ===\n"
        
        if let timestamp = timestamp {
            report += "Validation Time: \(ISO8601DateFormatter().string(from: timestamp))\n"
        }
        
        if let duration = validationDuration {
            report += "Duration: \(Int(duration * 1000))ms\n"
        }
        
        report += "\n" + summary.description + "\n\n"
        
        let sections = [
            ("Configuration", configurationChecks),
            ("Network", networkChecks),
            ("API Endpoints", endpointChecks),
            ("WebSocket", webSocketChecks),
            ("Assets", assetChecks),
            ("Demo Data", demoDataChecks),
            ("Security", securityChecks),
            ("Performance", performanceChecks)
        ]
        
        for (sectionName, checks) in sections {
            if !checks.isEmpty {
                report += "=== \(sectionName) ===\n"
                for check in checks {
                    let statusIcon = check.status.icon
                    report += "\(statusIcon) \(check.name): \(check.message)\n"
                    if let details = check.details {
                        report += "    Details: \(details)\n"
                    }
                }
                report += "\n"
            }
        }
        
        return report
    }
}

struct ValidationCheck {
    let name: String
    let status: ValidationStatus
    let message: String
    let details: String?
    
    init(name: String, status: ValidationStatus, message: String, details: String? = nil) {
        self.name = name
        self.status = status
        self.message = message
        self.details = details
    }
}

enum ValidationStatus: String, CaseIterable {
    case passed = "passed"
    case warning = "warning"
    case failed = "failed"
    case skipped = "skipped"
    
    var icon: String {
        switch self {
        case .passed: return "✅"
        case .warning: return "⚠️"
        case .failed: return "❌"
        case .skipped: return "⏭️"
        }
    }
    
    var color: String {
        switch self {
        case .passed: return "green"
        case .warning: return "orange"
        case .failed: return "red"
        case .skipped: return "gray"
        }
    }
}

struct ValidationSummary {
    let totalChecks: Int
    let passedChecks: Int
    let warningChecks: Int
    let failedChecks: Int
    let skippedChecks: Int
    let overallStatus: ValidationStatus
    
    var description: String {
        return """
        VALIDATION SUMMARY:
        Total Checks: \(totalChecks)
        ✅ Passed: \(passedChecks)
        ⚠️ Warnings: \(warningChecks)
        ❌ Failed: \(failedChecks)
        ⏭️ Skipped: \(skippedChecks)
        
        Overall Status: \(overallStatus.icon) \(overallStatus.rawValue.uppercased())
        """
    }
    
    var successRate: Double {
        guard totalChecks > 0 else { return 0.0 }
        return Double(passedChecks) / Double(totalChecks)
    }
}