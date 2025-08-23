import SwiftUI

// MARK: - Placeholder Views for MoreTabView

struct LearningAnalyticsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Learning Analytics")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Track your learning progress and achievements")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("This feature will show:\n• Study time tracking\n• Course completion rates\n• Learning streaks\n• Performance metrics")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct StudyGroupsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "person.3")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("Study Groups")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Collaborate and learn with others")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("This feature will include:\n• Join study groups\n• Create new groups\n• Share resources\n• Group discussions")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Study Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AchievementsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "trophy")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                Text("Achievements")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your learning accomplishments")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("This feature will show:\n• Completed courses\n• Learning badges\n• Milestones reached\n• Certificates earned")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview {
    LearningAnalyticsView()
        .environmentObject(AppState.shared as AppState)
}

#Preview {
    StudyGroupsView()
        .environmentObject(AppState.shared as AppState)
}

#Preview {
    AchievementsView()
        .environmentObject(AppState.shared as AppState)
}