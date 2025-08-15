import SwiftUI

/// Backend Status Monitor
/// Monitors backend connectivity and provides real-time status updates
@MainActor
class BackendStatusMonitor: ObservableObject {
    @Published var isBackendAvailable = false
    @Published var backendStatus: BackendStatus = .checking
    @Published var lastStatusCheck = Date()
    @Published var availableEndpoints: [String] = []
    
    private var statusTimer: Timer?
    private let healthCheckInterval: TimeInterval = 10.0 // Check every 10 seconds
    
    enum BackendStatus {
        case checking
        case connected
        case disconnected
        case error(String)
        
        var displayName: String {
            switch self {
            case .checking: return "Checking..."
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        var color: Color {
            switch self {
            case .checking: return .orange
            case .connected: return .green
            case .disconnected: return .red
            case .error: return .red
            }
        }
    }
    
    init() {
        startStatusMonitoring()
    }
    
    deinit {
        stopStatusMonitoring()
    }
    
    func startStatusMonitoring() {
        // Initial check
        checkBackendStatus()
        
        // Setup timer for periodic checks
        statusTimer = Timer.scheduledTimer(withTimeInterval: healthCheckInterval, repeats: true) { _ in
            Task { @MainActor in
                self.checkBackendStatus()
            }
        }
    }
    
    func stopStatusMonitoring() {
        statusTimer?.invalidate()
        statusTimer = nil
    }
    
    private func checkBackendStatus() {
        backendStatus = .checking
        lastStatusCheck = Date()
        
        Task {
            await performBackendHealthCheck()
        }
    }
    
    private func performBackendHealthCheck() async {
        let baseURL = LyoConfiguration.getBackendURL()
        
        // Try multiple health endpoints
        let healthEndpoints = [
            "/health",
            "/ai/health", 
            "/api/health",
            "/status",
            "/api/v1/health"
        ]
        
        for endpoint in healthEndpoints {
            if await testEndpoint(url: "\(baseURL)\(endpoint)") {
                backendStatus = .connected
                isBackendAvailable = true
                availableEndpoints.append(endpoint)
                return
            }
        }
        
        // If no health endpoint works, backend is not available
        backendStatus = .disconnected
        isBackendAvailable = false
        availableEndpoints.removeAll()
    }
    
    private func testEndpoint(url: String) async -> Bool {
        guard let url = URL(string: url) else { return false }
        
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 3.0
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            
            return false
        } catch {
            return false
        }
    }
    
    func forceStatusCheck() {
        checkBackendStatus()
    }
}

/// Backend Status View
/// Shows current backend connection status in the UI
struct BackendStatusView: View {
    @StateObject private var statusMonitor = BackendStatusMonitor()
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusMonitor.backendStatus.color)
                .frame(width: 8, height: 8)
                .scaleEffect(statusMonitor.backendStatus == .checking ? 1.5 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), 
                          value: statusMonitor.backendStatus == .checking)
            
            Text(statusMonitor.backendStatus.displayName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !statusMonitor.isBackendAvailable {
                Button("Retry") {
                    statusMonitor.forceStatusCheck()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .onAppear {
            statusMonitor.startStatusMonitoring()
        }
        .onDisappear {
            statusMonitor.stopStatusMonitoring()
        }
    }
}

// MARK: - Backend Status Indicator Component
struct BackendStatusIndicator: View {
    @StateObject private var monitor = BackendStatusMonitor()
    @State private var showingDetails = false
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(monitor.backendStatus.color)
                .frame(width: 6, height: 6)
            
            Text(monitor.backendStatus.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.1))
        )
        .onTapGesture {
            showingDetails.toggle()
        }
        .alert("Backend Status", isPresented: $showingDetails) {
            Button("Retry") {
                monitor.checkBackendStatus()
            }
            Button("OK") { }
        } message: {
            Text("""
            Status: \(monitor.backendStatus.displayName)
            Last check: \(formatTime(monitor.lastStatusCheck))
            
            If disconnected:
            1. Start your backend server
            2. Run: uvicorn main:app --reload --port 8000
            3. Tap Retry
            """)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Enhanced Error View
struct BackendErrorView: View {
    let error: String
    let onRetry: () -> Void
    let onContinueWithMock: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Backend Unavailable")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Cannot connect to the backend server")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if !error.isEmpty {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
            }
            
            VStack(spacing: 12) {
                Button("Retry Connection") {
                    onRetry()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Continue with Demo Data") {
                    onContinueWithMock()
                }
                .buttonStyle(.bordered)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("To start backend server:")
                    .font(.headline)
                
                Group {
                    Text("1. Open Terminal")
                    Text("2. Navigate to backend folder")
                    Text("3. Run: uvicorn main:app --reload --port 8000")
                    Text("4. Wait for server to start")
                    Text("5. Tap 'Retry Connection'")
                }
                .font(.caption)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
        }
        .padding()
    }

/// Enhanced Error View with Backend Status
struct EnhancedErrorView: View {
    let error: String
    let onRetry: () -> Void
    
    @StateObject private var statusMonitor = BackendStatusMonitor()
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Connection Issue")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Backend Status
            VStack(spacing: 8) {
                Text("Backend Status")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                BackendStatusView()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
            )
            
            // Instructions
            if !statusMonitor.isBackendAvailable {
                VStack(alignment: .leading, spacing: 4) {
                    Text("To enable full functionality:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("1. Start the backend server on localhost:8000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("2. Visit http://localhost:8000/docs to verify")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("3. The app will auto-reconnect when available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
            
            HStack(spacing: 16) {
                Button("Use Offline Mode") {
                    // Switch to mock data mode
                    onRetry()
                }
                .foregroundColor(.secondary)
                
                Button("Retry Connection") {
                    statusMonitor.forceStatusCheck()
                    onRetry()
                }
                .foregroundColor(.blue)
                .fontWeight(.medium)
            }
        }
        .padding()
    }
}

#Preview {
    EnhancedErrorView(error: "Could not connect to backend server") {
        print("Retry tapped")
    }
}
