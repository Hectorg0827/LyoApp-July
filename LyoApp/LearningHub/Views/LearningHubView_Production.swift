import SwiftUI
import OSLog

/// Production-ready Learning Hub View - Routes to new chat-driven interface
struct LearningHubView: View {
    var body: some View {
        // Use the new enhanced Learning Hub Landing View
        LearningHubLandingView()
    }
}

// MARK: - Preview
#Preview {
    LearningHubView()
        .preferredColorScheme(.dark)
}
