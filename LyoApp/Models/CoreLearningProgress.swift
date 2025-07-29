import Foundation

// MARK: - Core Learning Progress Model
struct CoreLearningProgress: Codable, Identifiable {
    let id = UUID()
    let courseId: String
    let lessonId: String
    let percentage: Double
    let timeSpent: TimeInterval
    let timestamp: Date
    
    init(courseId: String, lessonId: String, percentage: Double, timeSpent: TimeInterval) {
        self.courseId = courseId
        self.lessonId = lessonId
        self.percentage = percentage
        self.timeSpent = timeSpent
        self.timestamp = Date()
    }
}

// MARK: - Progress Analytics Extension
extension CoreLearningProgress {
    var isCompleted: Bool {
        return percentage >= 100.0
    }
    
    var formattedTimeSpent: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: timeSpent) ?? "0s"
    }
}
