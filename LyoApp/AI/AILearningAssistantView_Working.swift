import SwiftUI

// MARK: - Simple AI Learning Assistant View (Renamed to avoid conflicts)
struct AILearningAssistantPanelView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var aiService = GemmaService.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("AI Learning Assistant")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Circle()
                    .fill(aiService.isModelLoaded ? .green : .orange)
                    .frame(width: 8, height: 8)
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            if isExpanded {
                // Simple AI Features
                VStack(spacing: 12) {
                    Text("AI features are loading...")
                        .foregroundColor(.secondary)
                        .font(.body)
                    
                    if aiService.isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Text("Model Status: \(aiService.isModelLoaded ? "Ready" : "Loading...")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    AILearningAssistantPanelView()
        .environmentObject(AppState())
}
