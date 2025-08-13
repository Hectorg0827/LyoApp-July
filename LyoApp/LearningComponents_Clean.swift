import SwiftUI

// MARK: - Learning Hub Components for Build
/// Contains simple learning components to ensure successful compilation
/// Note: Main LearningHubView is defined in /LearningHub/Views/LearningHubView.swift

// MARK: - Simple Learning Components
struct LearningProgressView: View {
    var body: some View {
        VStack {
            Text("Learning Progress")
                .font(.title2)
                .padding()
        }
    }
}

struct LearningCardSimple: View {
    let title: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
                .padding()
        }
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}
