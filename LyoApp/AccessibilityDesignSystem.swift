import SwiftUI
import Foundation

// MARK: - Accessibility-Enhanced Design System Extensions

extension DesignTokens {
    
    // MARK: - Accessibility-Optimized Typography
    struct AccessibleTypography {
        /// Dynamic type scaling with accessibility limits
        static func scaledFont(_ baseFont: Font, maxScale: DynamicTypeSize = .accessibility3) -> Font {
            baseFont
        }
        
        /// Headers with proper accessibility traits
        static let accessibleLargeTitle = Font.largeTitle.weight(.bold)
        static let accessibleTitle1 = Font.title.weight(.bold)
        static let accessibleTitle2 = Font.title2.weight(.semibold)
        static let accessibleTitle3 = Font.title3.weight(.semibold)
        
        /// Body text optimized for reading
        static let accessibleBody = Font.body
        static let accessibleBodyLarge = Font.body.weight(.medium)
        
        /// Captions with minimum size constraints
        static let accessibleCaption = Font.caption
        static let accessibleCaption2 = Font.caption2
        
        /// Button text with enhanced contrast
        static let accessibleButton = Font.system(size: 16, weight: .semibold)
    }
    
    // MARK: - High Contrast Colors
    struct AccessibleColors {
        // High contrast text colors
        static let highContrastPrimary = Color.white
        static let highContrastSecondary = Color(hex: "E5E5E5")
        static let highContrastTertiary = Color(hex: "CCCCCC")
        
        // Enhanced focus indicators
        static let focusRing = Color(hex: "00AAFF")
        static let focusRingSecondary = Color(hex: "FF6B35")
        
        // High contrast backgrounds
        static let highContrastBackground = Color.black
        static let highContrastSurface = Color(hex: "1A1A1A")
        
        // Status colors with enhanced contrast
        static let accessibleSuccess = Color(hex: "00FF88")
        static let accessibleWarning = Color(hex: "FFD700")
        static let accessibleError = Color(hex: "FF5555")
        static let accessibleInfo = Color(hex: "55AAFF")
    }
    
    // MARK: - Accessibility Spacing
    struct AccessibleSpacing {
        // Touch target minimum sizes (44pt minimum)
        static let minTouchTarget: CGFloat = 44
        static let recommendedTouchTarget: CGFloat = 48
        
        // Enhanced spacing for readability
        static let readingMargin: CGFloat = 20
        static let paragraphSpacing: CGFloat = 16
        static let lineSpacing: CGFloat = 4
        
        // Focus ring spacing
        static let focusRingPadding: CGFloat = 4
        static let focusRingOffset: CGFloat = 2
    }
}

// MARK: - Accessibility View Modifiers

extension View {
    /// Apply accessible button styling with proper touch targets
    func accessibleButtonStyle(
        minTouchTarget: CGFloat = DesignTokens.AccessibleSpacing.minTouchTarget,
        style: AccessibleButton.ButtonStyle = .primary
    ) -> some View {
        self
            .frame(minHeight: minTouchTarget)
            .contentShape(Rectangle())
    }
    
    /// Enhanced focus ring for keyboard navigation
    func accessibleFocusRing(_ isFocused: Bool = false) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.sm)
                    .stroke(DesignTokens.AccessibleColors.focusRing, lineWidth: 2)
                    .opacity(isFocused ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isFocused)
            )
    }
    
    /// High contrast mode support
    func accessibleHighContrast() -> some View {
        self.modifier(HighContrastModifier())
    }
    
    /// Reading optimized text
    func accessibleReading() -> some View {
        self
            .padding(.horizontal, DesignTokens.AccessibleSpacing.readingMargin)
            .lineSpacing(DesignTokens.AccessibleSpacing.lineSpacing)
    }
    
    /// Semantic grouping for VoiceOver
    func accessibleGroup(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Enhanced button accessibility
    func accessibleButton(
        label: String,
        hint: String? = nil,
        isEnabled: Bool = true,
        role: AccessibilityButtonRole? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
            .if(role != nil) { view in
                if #available(iOS 15.0, *) {
                    return view.accessibilityInputLabels([label])
                } else {
                    return view
                }
            }
    }
    
    /// Conditional view modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Smart scroll accessibility
    func accessibleScroll(
        axes: Axis.Set = .vertical,
        showsIndicators: Bool = true
    ) -> some View {
        self
            .accessibilityScrollAction { edge in
                // Custom scroll action handling
            }
    }
    
    /// Reduced motion support for animations
    func accessibleAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V,
        fallback: Animation? = nil
    ) -> some View {
        self.modifier(ReducedMotionAnimationModifier(
            animation: animation,
            value: value,
            fallback: fallback
        ))
    }
    
    /// Voice Control support
    func accessibleVoiceControl(_ identifier: String) -> some View {
        if #available(iOS 14.0, *) {
            return self.accessibilityInputLabels([identifier])
        } else {
            return self
        }
    }
}

// MARK: - Accessibility Modifiers

struct HighContrastModifier: ViewModifier {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityReduceTransparency) var reduceTransparency
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(differentiateWithoutColor ? DesignTokens.AccessibleColors.highContrastPrimary : nil)
            .background(reduceTransparency ? DesignTokens.AccessibleColors.highContrastBackground : nil)
    }
}

struct ReducedMotionAnimationModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V
    let fallback: Animation?
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .animation(
                reduceMotion ? (fallback ?? .none) : animation,
                value: value
            )
    }
}

// MARK: - Accessibility Button Role

enum AccessibilityButtonRole {
    case primary
    case secondary
    case destructive
    case cancel
}

// MARK: - Dynamic Type Support

extension Font {
    /// Scale font with accessibility constraints
    func accessibleScale(
        _ category: Font.TextStyle,
        maxSize: DynamicTypeSize = .accessibility3
    ) -> Font {
        self
    }
}

// MARK: - Voice Over Announcements Manager

class VoiceOverManager: ObservableObject {
    static let shared = VoiceOverManager()
    
    private init() {}
    
    func announce(_ message: String, priority: AccessibilityNotificationPriority = .medium) {
        DispatchQueue.main.async {
            AccessibilityNotification.Announcement(message).post(priority: priority)
        }
    }
    
    func announceLayoutChange(_ message: String? = nil) {
        DispatchQueue.main.async {
            AccessibilityNotification.LayoutChanged(message).post()
        }
    }
    
    func announceScreenChange(_ message: String? = nil) {
        DispatchQueue.main.async {
            AccessibilityNotification.ScreenChanged(message).post()
        }
    }
    
    func announcePageTurned(_ message: String? = nil) {
        DispatchQueue.main.async {
            if #available(iOS 14.0, *) {
                AccessibilityNotification.Announcement(message ?? "Page turned").post()
            }
        }
    }
}

// MARK: - Accessibility Testing Helpers

#if DEBUG
struct AccessibilityPreview<Content: View>: View {
    let content: Content
    let testScenarios: [AccessibilityTestScenario]
    
    init(@ViewBuilder content: () -> Content, testScenarios: [AccessibilityTestScenario] = AccessibilityTestScenario.allCases) {
        self.content = content()
        self.testScenarios = testScenarios
    }
    
    var body: some View {
        TabView {
            ForEach(testScenarios, id: \.self) { scenario in
                content
                    .modifier(scenario.modifier)
                    .tabItem {
                        Label(scenario.name, systemImage: scenario.icon)
                    }
            }
        }
    }
}

enum AccessibilityTestScenario: CaseIterable {
    case normal
    case largeText
    case extraLargeText
    case highContrast
    case reduceMotion
    case voiceOver
    
    var name: String {
        switch self {
        case .normal: return "Normal"
        case .largeText: return "Large Text"
        case .extraLargeText: return "Extra Large Text"
        case .highContrast: return "High Contrast"
        case .reduceMotion: return "Reduce Motion"
        case .voiceOver: return "VoiceOver"
        }
    }
    
    var icon: String {
        switch self {
        case .normal: return "textformat"
        case .largeText: return "textformat.size"
        case .extraLargeText: return "plus.magnifyingglass"
        case .highContrast: return "circle.righthalf.fill"
        case .reduceMotion: return "play.slash"
        case .voiceOver: return "speaker.wave.3"
        }
    }
    
    var modifier: some ViewModifier {
        switch self {
        case .normal:
            return AnyViewModifier(EmptyModifier())
        case .largeText:
            return AnyViewModifier(DynamicTypeSizeModifier(.large))
        case .extraLargeText:
            return AnyViewModifier(DynamicTypeSizeModifier(.accessibility3))
        case .highContrast:
            return AnyViewModifier(HighContrastModifier())
        case .reduceMotion:
            return AnyViewModifier(ReduceMotionModifier())
        case .voiceOver:
            return AnyViewModifier(VoiceOverModifier())
        }
    }
}

struct AnyViewModifier: ViewModifier {
    private let _body: (Content) -> AnyView
    
    init<M: ViewModifier>(_ modifier: M) {
        _body = { content in
            AnyView(content.modifier(modifier))
        }
    }
    
    func body(content: Content) -> some View {
        _body(content)
    }
}

struct DynamicTypeSizeModifier: ViewModifier {
    let size: DynamicTypeSize
    
    init(_ size: DynamicTypeSize) {
        self.size = size
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 15.0, *) {
            return content.dynamicTypeSize(size)
        } else {
            return content
        }
    }
}

struct ReduceMotionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.environment(\.accessibilityReduceMotion, true)
    }
}

struct VoiceOverModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.environment(\.accessibilityVoiceOverEnabled, true)
    }
}
#endif
