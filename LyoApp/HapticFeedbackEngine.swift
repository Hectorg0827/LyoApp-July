import UIKit
import os.log

// MARK: - Haptic Feedback Engine with Capability Checking
class HapticFeedbackEngine: ObservableObject {
    static let shared = HapticFeedbackEngine()
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LyoApp", category: "HapticFeedback")
    
    // Haptic Feedback Generators
    private var impactFeedbackLight: UIImpactFeedbackGenerator?
    private var impactFeedbackMedium: UIImpactFeedbackGenerator?
    private var impactFeedbackHeavy: UIImpactFeedbackGenerator?
    private var selectionFeedback: UISelectionFeedbackGenerator?
    private var notificationFeedback: UINotificationFeedbackGenerator?
    
    // Device Capability Flags
    private let isSimulator: Bool
    private let supportsHaptics: Bool
    
    private init() {
        // Check if running on simulator
        #if targetEnvironment(simulator)
        isSimulator = true
        #else
        isSimulator = false
        #endif
        
        // Check device haptic capabilities
        supportsHaptics = UIDevice.current.userInterfaceIdiom == .phone && !isSimulator
        
        if supportsHaptics {
            initializeHapticGenerators()
            logger.info("✅ Haptic feedback engine initialized with full haptic support")
        } else if isSimulator {
            logger.info("⚠️ Haptic feedback engine initialized - simulator mode (haptics disabled)")
        } else {
            logger.info("⚠️ Haptic feedback engine initialized - device doesn't support haptics")
        }
    }
    
    private func initializeHapticGenerators() {
        guard supportsHaptics else { return }
        
        impactFeedbackLight = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackMedium = UIImpactFeedbackGenerator(style: .medium)
        impactFeedbackHeavy = UIImpactFeedbackGenerator(style: .heavy)
        selectionFeedback = UISelectionFeedbackGenerator()
        notificationFeedback = UINotificationFeedbackGenerator()
        
        // Prepare generators for better performance
        impactFeedbackLight?.prepare()
        impactFeedbackMedium?.prepare()
        impactFeedbackHeavy?.prepare()
        selectionFeedback?.prepare()
        notificationFeedback?.prepare()
    }
    
    // MARK: - Public Haptic Methods
    
    /// Light impact feedback (e.g., button tap)
    func lightImpact() {
        performHaptic {
            impactFeedbackLight?.impactOccurred()
            impactFeedbackLight?.prepare() // Re-prepare for next use
        }
    }
    
    /// Medium impact feedback (e.g., switch toggle)
    func mediumImpact() {
        performHaptic {
            impactFeedbackMedium?.impactOccurred()
            impactFeedbackMedium?.prepare()
        }
    }
    
    /// Heavy impact feedback (e.g., significant action)
    func heavyImpact() {
        performHaptic {
            impactFeedbackHeavy?.impactOccurred()
            impactFeedbackHeavy?.prepare()
        }
    }
    
    /// Selection feedback (e.g., picker wheel, selection change)
    func selectionChanged() {
        performHaptic {
            selectionFeedback?.selectionChanged()
            selectionFeedback?.prepare()
        }
    }
    
    /// Success notification feedback
    func notificationSuccess() {
        performHaptic {
            notificationFeedback?.notificationOccurred(.success)
            notificationFeedback?.prepare()
        }
    }
    
    /// Warning notification feedback
    func notificationWarning() {
        performHaptic {
            notificationFeedback?.notificationOccurred(.warning)
            notificationFeedback?.prepare()
        }
    }
    
    /// Error notification feedback
    func notificationError() {
        performHaptic {
            notificationFeedback?.notificationOccurred(.error)
            notificationFeedback?.prepare()
        }
    }
    
    // MARK: - Custom Haptic Patterns
    
    /// Double tap haptic pattern
    func doubleTap() {
        guard supportsHaptics else {
            provideFallbackFeedback()
            return
        }
        
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }
    
    /// Success pattern (ascending impacts)
    func successPattern() {
        guard supportsHaptics else {
            provideFallbackFeedback()
            return
        }
        
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpact()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.notificationSuccess()
        }
    }
    
    /// Error pattern (strong feedback)
    func errorPattern() {
        guard supportsHaptics else {
            provideFallbackFeedback()
            return
        }
        
        heavyImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.notificationError()
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func performHaptic(_ hapticAction: @escaping () -> Void) {
        guard supportsHaptics else {
            provideFallbackFeedback()
            return
        }
        
        // Ensure haptic runs on main thread
        if Thread.isMainThread {
            hapticAction()
        } else {
            DispatchQueue.main.async {
                hapticAction()
            }
        }
    }
    
    private func provideFallbackFeedback() {
        if isSimulator {
            // Visual feedback for simulator
            logger.debug("🔇 Haptic feedback requested (simulator) - providing visual feedback")
            provideSilentFeedback()
        } else {
            // Device doesn't support haptics - could use system sounds as fallback
            logger.debug("🔇 Haptic feedback requested (unsupported device)")
        }
    }
    
    private func provideSilentFeedback() {
        // Could implement visual feedback here (e.g., brief animation)
        // For now, just log the feedback
        logger.debug("💫 Visual feedback provided instead of haptic")
    }
    
    // MARK: - Utility Methods
    
    /// Check if haptics are available
    var isHapticAvailable: Bool {
        return supportsHaptics
    }
    
    /// Get device haptic support info
    var hapticSupportInfo: String {
        if isSimulator {
            return "Simulator - Haptics Disabled"
        } else if supportsHaptics {
            return "Physical Device - Haptics Enabled"
        } else {
            return "Physical Device - Haptics Not Supported"
        }
    }
    
    /// Reset and re-prepare all haptic generators (useful after app becomes active)
    func resetHapticGenerators() {
        guard supportsHaptics else { return }
        
        logger.debug("🔄 Resetting haptic generators")
        initializeHapticGenerators()
    }
}

// MARK: - SwiftUI View Extension for Easy Haptic Access
extension View {
    /// Add light haptic feedback to any view interaction
    func hapticTap() -> some View {
        self.onTapGesture {
            HapticFeedbackEngine.shared.lightImpact()
        }
    }
    
    /// Add selection haptic feedback
    func hapticSelection() -> some View {
        self.onTapGesture {
            HapticFeedbackEngine.shared.selectionChanged()
        }
    }
    
    /// Add success haptic feedback
    func hapticSuccess() -> some View {
        self.onTapGesture {
            HapticFeedbackEngine.shared.successPattern()
        }
    }
    
    /// Add custom haptic feedback
    func hapticFeedback(_ intensity: HapticIntensity) -> some View {
        self.onTapGesture {
            switch intensity {
            case .light:
                HapticFeedbackEngine.shared.lightImpact()
            case .medium:
                HapticFeedbackEngine.shared.mediumImpact()
            case .heavy:
                HapticFeedbackEngine.shared.heavyImpact()
            case .selection:
                HapticFeedbackEngine.shared.selectionChanged()
            case .success:
                HapticFeedbackEngine.shared.notificationSuccess()
            case .warning:
                HapticFeedbackEngine.shared.notificationWarning()
            case .error:
                HapticFeedbackEngine.shared.notificationError()
            }
        }
    }
}

// MARK: - Haptic Intensity Enum
enum HapticIntensity: CaseIterable {
    case light
    case medium
    case heavy
    case selection
    case success
    case warning
    case error
    
    var description: String {
        switch self {
        case .light: return "Light Impact"
        case .medium: return "Medium Impact"
        case .heavy: return "Heavy Impact"
        case .selection: return "Selection Change"
        case .success: return "Success Notification"
        case .warning: return "Warning Notification"
        case .error: return "Error Notification"
        }
    }
}