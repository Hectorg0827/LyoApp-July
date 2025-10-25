import Foundation
import Network

// MARK: - Network Debug Helper
@MainActor
class NetworkDebugHelper: ObservableObject {
    static let shared = NetworkDebugHelper()
    
    @Published var connectionStatus: String = "Unknown"
    @Published var backendStatus: String = "Unknown"
    @Published var lastTestResult: String = "Not tested"
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startNetworkMonitoring()
    }
    
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            Task { @MainActor in
                if path.status == .satisfied {
                    self.connectionStatus = "Connected"
                } else {
                    self.connectionStatus = "Disconnected"
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // Test all your backend endpoints
    func testAllConnections() async {
        lastTestResult = "Testing..."
        
        var results: [String] = []
        
        // Test 1: Network connectivity
        results.append("🌐 Network: \(connectionStatus)")
        
        // Test 2: Backend health check
        await testBackendHealth(&results)
        
        // Test 3: API Client connection
        await testAPIClient(&results)
        
        // Test 4: Learning API Service
        await testLearningAPI(&results)
        
        lastTestResult = results.joined(separator: "\n")
    }
    
    private func testBackendHealth(_ results: inout [String]) async {
        do {
            let response = try await APIClient.shared.healthCheck()
            results.append("✅ Backend Health: \(response.status)")
            backendStatus = "Healthy"
        } catch {
            results.append("❌ Backend Health: \(error.localizedDescription)")
            backendStatus = "Error"
        }
    }
    
    private func testAPIClient(_ results: inout [String]) async {
        await APIClient.shared.checkBackendConnection()
        if APIClient.shared.isConnected {
            results.append("✅ API Client: Connected")
        } else {
            results.append("❌ API Client: Not connected")
        }
    }
    
    private func testLearningAPI(_ results: inout [String]) async {
        do {
            let response = try await LearningAPIService.shared.healthCheck()
            results.append("✅ Learning API: \(response.status)")
        } catch {
            results.append("❌ Learning API: \(error.localizedDescription)")
        }
    }
    
    // Test specific endpoints
    func testEndpoint(_ url: String) async -> String {
        guard let url = URL(string: url) else {
            return "❌ Invalid URL"
        }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return "✅ Status: \(httpResponse.statusCode)"
            } else {
                return "❌ Invalid response"
            }
        } catch {
            return "❌ Error: \(error.localizedDescription)"
        }
    }
    
    // Get current configuration info
    func getConfigurationInfo() -> String {
        var info: [String] = []
        
        info.append("📋 Configuration Info:")
        info.append("• API Base URL: \(APIConfig.baseURL)")
        info.append("• WebSocket URL: \(APIConfig.webSocketURL)")
        info.append("• Use Mock Data: \(DevelopmentConfig.useMockData)")
        info.append("• Debug Mode: \(APIConfig.isProduction ? "Production" : "Debug")")
        info.append("• Learning API: \(LearningAPIService.shared)")
        
        return info.joined(separator: "\n")
    }
}

// MARK: - Simple Debug View
import SwiftUI

struct NetworkDebugView: View {
    @StateObject private var debugHelper = NetworkDebugHelper.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Status Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Connection Status")
                            .font(.headline)
                        
                        HStack {
                            Circle()
                                .fill(debugHelper.connectionStatus == "Connected" ? .green : .red)
                                .frame(width: 10, height: 10)
                            Text("Network: \(debugHelper.connectionStatus)")
                        }
                        
                        HStack {
                            Circle()
                                .fill(debugHelper.backendStatus == "Healthy" ? .green : .red)
                                .frame(width: 10, height: 10)
                            Text("Backend: \(debugHelper.backendStatus)")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Configuration Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Configuration")
                            .font(.headline)
                        
                        Text(debugHelper.getConfigurationInfo())
                            .font(.system(.caption, design: .monospaced))
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Test Results Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Test Results")
                            .font(.headline)
                        
                        if debugHelper.lastTestResult != "Not tested" {
                            Text(debugHelper.lastTestResult)
                                .font(.system(.caption, design: .monospaced))
                        } else {
                            Text("Tap 'Test All Connections' to run tests")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    
                    // Actions
                    Button("Test All Connections") {
                        Task {
                            await debugHelper.testAllConnections()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
            .navigationTitle("Network Debug")
        }
    }
}

// MARK: - Preview
struct NetworkDebugView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkDebugView()
    }
}