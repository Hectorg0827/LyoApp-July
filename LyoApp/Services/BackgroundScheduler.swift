import Foundation
import UIKit

/// Manages background tasks and app lifecycle events
final class BackgroundScheduler {
    static let shared = BackgroundScheduler()

    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    private init() {}

    /// Handle app entering background
    func handleAppDidEnterBackground() {
        beginBackgroundTask()
        Task { await saveAppState() }
    }

    /// Handle app becoming active
    func handleAppDidBecomeActive() {
        endBackgroundTask()
        Task { await refreshAppData() }
    }

    private func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask {
            self.endBackgroundTask()
        }
    }

    private func endBackgroundTask() {
        guard backgroundTask != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }

    private func saveAppState() async {
        // Lightweight background save
        print("📝 BackgroundScheduler: saving app state")
    }

    private func refreshAppData() async {
        // Lightweight refresh
        print("🔄 BackgroundScheduler: refreshing app data")
    }
}
