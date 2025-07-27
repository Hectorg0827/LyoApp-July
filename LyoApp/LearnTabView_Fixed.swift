import SwiftUI

// MARK: - Enhanced Learn Tab View with Learning Hub Integration
/// Replaces the basic learn tab with comprehensive Learning Hub functionality
struct LearnTabView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Main Learning Hub Interface
            LearningHubView()
                .environmentObject(appState)
            
            // AI Learning Assistant Overlay
            LearningAssistantView()
                .environmentObject(appState)
        }
        .onAppear {
            print("📚 LEARN TAB: Loaded with enhanced Learning Hub")
            trackScreenView()
        }
    }
    
    // MARK: - Analytics
    private func trackScreenView() {
        // Track that user accessed the enhanced learning hub
        print("📊 ANALYTICS: Enhanced Learning Hub accessed")
    }
}

// MARK: - Preview
#Preview {
    LearnTabView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
