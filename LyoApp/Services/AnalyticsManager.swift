import Foundation
import OSLog

// MARK: - Lightweight Analytics Manager
@MainActor
class AnalyticsManager: ObservableObject {
	static let shared = AnalyticsManager()
	private let logger = Logger(subsystem: "com.lyo.analytics", category: "events")
	private init() {}

	func trackScreenView(_ name: String) {
		logger.info("screen_view: \(name, privacy: .public)")
	}

	func trackUserAction(_ action: String, parameters: [String: Any] = [:]) {
		logger.info("user_action: \(action, privacy: .public) params: \(String(describing: parameters), privacy: .auto)")
	}
	
	// Simplified learning progress tracking
	func trackLearningProgress(courseId: String, percentage: Double) {
		logger.info("learning_progress: course=\(courseId, privacy: .public) percent=\(percentage, privacy: .public)")
	}
}
