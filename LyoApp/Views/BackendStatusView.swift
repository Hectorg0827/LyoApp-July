import SwiftUI

// MARK: - Backend Status View
struct BackendStatusView: View {
    @StateObject private var backendService = BackendIntegrationService.shared
    @State private var showDiagnostics = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Connection Status Card
                    connectionStatusCard
                    
                    // Backend Info Card
                    if let backendInfo = backendService.backendInfo {
                        backendInfoCard(backendInfo)
                    }
                    
                    // Service Status Cards
                    serviceStatusCards
                    
                    // Actions Section
                    actionsSection
                    
                    // Cache Status
                    cacheStatusCard
                    
                    // Diagnostics Section
                    if showDiagnostics {
                        diagnosticsCard
                    }
                }
                .padding()
            }
            .navigationTitle("Backend Status")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Diagnostics") {
                        showDiagnostics.toggle()
                    }
                }
            }
            .refreshable {
                await refreshAll()
            }
        }
        .task {
            await backendService.connect()
        }
    }
    
    // MARK: - Connection Status Card
    private var connectionStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: backendService.connectionStatusIcon)
                    .foregroundColor(backendService.connectionStatusColor)
                    .font(.title2)
                
                Text("Connection Status")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if backendService.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack {
                Text(backendService.connectionStatus.displayText)
                    .font(.subheadline)
                    .foregroundColor(backendService.connectionStatusColor)
                
                Spacer()
                
                if let lastCheck = backendService.lastHealthCheck {
                    Text("Last check: \(lastCheck, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let error = backendService.error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Backend Info Card
    private func backendInfoCard(_ info: BackendIntegrationService.BackendInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "server.rack")
                    .foregroundColor(.blue)
                
                Text("Backend Information")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                infoRow("Version", info.version)
                infoRow("Service", info.service ?? "Unknown")
                infoRow("Environment", info.environment ?? "Unknown")
                infoRow("Status", info.status.capitalized)
            }
            
            if !info.capabilities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Capabilities")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 4) {
                        ForEach(info.capabilities, id: \.self) { capability in
                            Text("• \(capability.replacingOccurrences(of: "_", with: " ").capitalized)")
                                .font(.caption)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Service Status Cards
    private var serviceStatusCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            serviceStatusCard(
                title: "API",
                status: backendService.apiVersion,
                icon: "globe",
                color: backendService.isConnected ? .green : .red
            )
            
            serviceStatusCard(
                title: "Database",
                status: backendService.databaseStatus,
                icon: "externaldrive",
                color: statusColor(backendService.databaseStatus)
            )
            
            serviceStatusCard(
                title: "AI Service",
                status: backendService.aiServiceStatus,
                icon: "brain.head.profile",
                color: statusColor(backendService.aiServiceStatus)
            )
            
            serviceStatusCard(
                title: "Authentication",
                status: backendService.currentUser != nil ? "Authenticated" : "Guest",
                icon: "person.badge.key",
                color: backendService.currentUser != nil ? .green : .orange
            )
        }
    }
    
    private func serviceStatusCard(title: String, status: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(status)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Actions")
                    .font(.headline)
                Spacer()
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                actionButton(
                    title: "Reconnect",
                    icon: "arrow.clockwise",
                    color: .blue,
                    action: {
                        Task {
                            await backendService.connect()
                        }
                    }
                )
                
                actionButton(
                    title: "Health Check",
                    icon: "stethoscope",
                    color: .green,
                    action: {
                        Task {
                            await backendService.performHealthCheck()
                        }
                    }
                )
                
                actionButton(
                    title: "Refresh Data",
                    icon: "arrow.triangle.2.circlepath",
                    color: .orange,
                    action: {
                        Task {
                            await backendService.refreshAllData()
                        }
                    }
                )
                
                actionButton(
                    title: "Test AI",
                    icon: "brain",
                    color: .purple,
                    action: {
                        Task {
                            _ = try? await backendService.generateAIContent(prompt: "Hello, test connection")
                        }
                    }
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .disabled(backendService.isLoading)
    }
    
    // MARK: - Cache Status Card
    private var cacheStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tray.2")
                    .foregroundColor(.indigo)
                
                Text("Cache Status")
                    .font(.headline)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                infoRow("Feed Posts", "\(backendService.cachedFeedPosts.count)")
                infoRow("Learning Resources", "\(backendService.cachedLearningResources.count)")
                infoRow("User Session", backendService.currentUser?.email ?? "None")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Diagnostics Card
    private var diagnosticsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundColor(.gray)
                
                Text("Diagnostics")
                    .font(.headline)
                
                Spacer()
                
                Button("Copy") {
                    let diagnostics = backendService.getConnectionDiagnostics()
                    let jsonData = try? JSONSerialization.data(withJSONObject: diagnostics, options: .prettyPrinted)
                    if let jsonData = jsonData, let jsonString = String(data: jsonData, encoding: .utf8) {
                        UIPasteboard.general.string = jsonString
                    }
                }
                .font(.caption)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 16) {
                    let diagnostics = backendService.getConnectionDiagnostics()
                    ForEach(Array(diagnostics.keys.sorted()), id: \.self) { key in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            let value = diagnostics[key] ?? "N/A"
                            Text(verbatim: String(describing: value))
                                .font(.caption2)
                                .foregroundColor(.primary)
                                .padding(4)
                                .background(Color(.systemGray5))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Views
    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Helper Functions
    private func statusColor(_ status: String) -> Color {
        switch status.lowercased() {
        case "healthy", "operational", "available", "ok":
            return .green
        case "degraded", "warning":
            return .orange
        case "unavailable", "error", "failed":
            return .red
        default:
            return .gray
        }
    }
    
    private func refreshAll() async {
        await backendService.refreshAllData()
    }
}

// MARK: - Preview
struct BackendStatusView_Previews: PreviewProvider {
    static var previews: some View {
        BackendStatusView()
    }
}
