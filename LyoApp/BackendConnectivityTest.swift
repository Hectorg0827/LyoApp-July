import Foundation
import SwiftUI
import Combine

// MARK: - Backend Connectivity Test
@MainActor
class BackendConnectivityTest: ObservableObject {
    static let shared = BackendConnectivityTest()
    
    @Published var testResults: [TestResult] = []
    @Published var overallStatus: ConnectionStatus = .unknown
    @Published var isRunning = false
    
    private var googleCloudBackend: String {
        return APIConfig.baseURL
    }
    
    enum ConnectionStatus {
        case unknown
        case connected
        case failed
        case partiallyConnected
        
        var displayText: String {
            switch self {
            case .unknown: return "Unknown"
            case .connected: return "✅ Connected"
            case .failed: return "❌ Failed"
            case .partiallyConnected: return "⚠️ Partial"
            }
        }
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .connected: return .green
            case .failed: return .red
            case .partiallyConnected: return .orange
            }
        }
    }
    
    struct TestResult {
        let name: String
        let endpoint: String
        let status: ConnectionStatus
        let responseTime: TimeInterval?
        let error: String?
        let timestamp: Date
    }
    
    private init() {}
    
    // MARK: - Main Test Runner
    func runComprehensiveTest() async {
        isRunning = true
        testResults.removeAll()
        
        print("🧪 Starting comprehensive backend connectivity test...")
        
        let tests = [
            ("Health Check", "/health"),
            ("Auth Endpoint", "/auth"),
            ("AI Health", "/ai/health"),
            ("Learning API", "/learning"),
            ("Feed API", "/feed"),
            ("WebSocket Info", "/ws")
        ]
        
        for (name, endpoint) in tests {
            await testEndpoint(name: name, endpoint: endpoint)
        }
        
        // Calculate overall status
        calculateOverallStatus()
        
        isRunning = false
        print("🧪 Backend connectivity test completed. Overall status: \(overallStatus.displayText)")
    }
    
    // MARK: - Individual Endpoint Tests
    private func testEndpoint(name: String, endpoint: String) async {
        let startTime = Date()
        
        do {
            let fullURL = googleCloudBackend + endpoint
            guard let url = URL(string: fullURL) else {
                addResult(name: name, endpoint: endpoint, status: .failed, 
                         responseTime: nil, error: "Invalid URL", timestamp: startTime)
                return
            }
            
            var request = URLRequest(url: url)
            request.timeoutInterval = 10.0
            request.httpMethod = "GET"
            request.setValue("LyoApp/1.0", forHTTPHeaderField: "User-Agent")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                let status: ConnectionStatus = (200...299).contains(httpResponse.statusCode) ? .connected : .failed
                let error = status == .failed ? "HTTP \(httpResponse.statusCode)" : nil
                
                addResult(name: name, endpoint: endpoint, status: status, 
                         responseTime: responseTime, error: error, timestamp: startTime)
                
                print("🌐 \(name): \(httpResponse.statusCode) (\(String(format: "%.2f", responseTime))s)")
            }
            
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            addResult(name: name, endpoint: endpoint, status: .failed, 
                     responseTime: responseTime, error: error.localizedDescription, timestamp: startTime)
            
            print("❌ \(name): \(error.localizedDescription)")
        }
    }
    
    private func addResult(name: String, endpoint: String, status: ConnectionStatus, 
                          responseTime: TimeInterval?, error: String?, timestamp: Date) {
        let result = TestResult(
            name: name,
            endpoint: endpoint,
            status: status,
            responseTime: responseTime,
            error: error,
            timestamp: timestamp
        )
        testResults.append(result)
    }
    
    private func calculateOverallStatus() {
        let connectedCount = testResults.filter { $0.status == .connected }.count
        let totalCount = testResults.count
        
        if connectedCount == totalCount {
            overallStatus = .connected
        } else if connectedCount > 0 {
            overallStatus = .partiallyConnected
        } else {
            overallStatus = .failed
        }
    }
    
    // MARK: - Specific Service Tests
    func testAPIServices() async {
        print("🧪 Testing API services...")
        
        // Test BackendIntegrationService
        await BackendIntegrationService.shared.performHealthCheck()
        print("✅ BackendIntegrationService: Health check completed")
        
        // Test NetworkManager
        do {
            _ = NetworkManager.shared
            let _: [String: Any] = try await performHealthCheck()
            print("✅ NetworkManager: Connected")
        } catch {
            print("❌ NetworkManager: \(error.localizedDescription)")
        }
        
        // Test APIClient
        do {
            let apiClient = APIClient.shared
            let _ = try await apiClient.healthCheck()
            print("✅ APIClient: Connected")
        } catch {
            print("❌ APIClient: \(error.localizedDescription)")
        }
    }
    
    private func performHealthCheck() async throws -> [String: Any] {
        guard let url = URL(string: "\(googleCloudBackend)/health") else {
            throw NSError(domain: "InvalidURL", code: 0)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 5.0
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "HealthCheckFailed", code: 0)
        }
        
        return try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
    }
}

// MARK: - Connectivity Test View
struct BackendConnectivityTestView: View {
    @StateObject private var connectivityTest = BackendConnectivityTest.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 10) {
                    Text("🌐 Backend Connectivity")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Google Cloud Run")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Overall Status
                    HStack {
                        Text("Status:")
                        Text(connectivityTest.overallStatus.displayText)
                            .foregroundColor(connectivityTest.overallStatus.color)
                            .fontWeight(.bold)
                    }
                    .font(.headline)
                }
                .padding()
                
                // Test Button
                if !connectivityTest.isRunning {
                    Button("Run Connectivity Test") {
                        Task {
                            await connectivityTest.runComprehensiveTest()
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                } else {
                    ProgressView("Testing endpoints...")
                        .padding()
                }
                
                // Results List
                if !connectivityTest.testResults.isEmpty {
                    List(connectivityTest.testResults, id: \.name) { result in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.name)
                                    .font(.headline)
                                
                                Text(result.endpoint)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                if let error = result.error {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(result.status.displayText)
                                    .font(.caption)
                                    .foregroundColor(result.status.color)
                                
                                if let responseTime = result.responseTime {
                                    Text("\(String(format: "%.2f", responseTime))s")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Spacer()
                
                // Service Status
                Button("Test API Services") {
                    Task {
                        await connectivityTest.testAPIServices()
                    }
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
            .navigationTitle("Backend Test")
        }
    }
}

// MARK: - Preview
struct BackendConnectivityTestView_Previews: PreviewProvider {
    static var previews: some View {
        BackendConnectivityTestView()
    }
}
