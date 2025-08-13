import UIKit

/// Centralized haptic feedback manager for consistent tactile feedback across the app
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    /// Light haptic feedback for subtle interactions
    func light() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackGenerator.impactOccurred()
    }
    
    /// Medium haptic feedback for standard interactions
    func medium() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackGenerator.impactOccurred()
    }
    
    /// Heavy haptic feedback for significant interactions
    func heavy() {
        let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedbackGenerator.impactOccurred()
    }
    
    /// Success haptic feedback for positive actions
    func success() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.notificationOccurred(.success)
    }
    
    /// Warning haptic feedback for cautionary actions
    func warning() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.notificationOccurred(.warning)
    }
    
    /// Error haptic feedback for negative actions
    func error() {
        let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
        notificationFeedbackGenerator.notificationOccurred(.error)
    }
    
    /// Selection haptic feedback for picker or selection changes
    func selection() {
        let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator.selectionChanged()
    }
}
