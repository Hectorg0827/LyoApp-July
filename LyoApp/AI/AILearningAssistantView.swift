import SwiftUI

// Keep this file as a tiny, self-contained preview-only view.
// No dependencies on other services or models to avoid build issues.
struct AILearningAssistantPreview: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.largeTitle)
                .foregroundColor(.blue)
            Text("Lio AI Assistant")
                .font(.headline)
            Text("Preview-only component")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    AILearningAssistantPreview()
}
