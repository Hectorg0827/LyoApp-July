import SwiftUI
import Foundation

extension AppState {
    func saveUserPreferences() {
        UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        UserDefaults.standard.set(isListeningForWakeWord, forKey: "isListeningForWakeWord")
        UserDefaults.standard.set(hasActiveSession, forKey: "hasActiveLyoSession")
        
        if let objective = currentLearningObjective {
            UserDefaults.standard.set(objective, forKey: "currentLearningObjective")
        }
        
        UserDefaults.standard.set(showFloatingCompanion, forKey: "showFloatingCompanion")
        
        if let topic = currentTopic {
            UserDefaults.standard.set(topic, forKey: "currentTopic")
        }
        if let path = currentLearningPath {
            UserDefaults.standard.set(path.rawValue, forKey: "currentLearningPath")
        }
        UserDefaults.standard.set(pathProgress, forKey: "pathProgress")
    }
}
