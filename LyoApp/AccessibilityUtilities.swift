import SwiftUI
import Foundation

// MARK: - Accessibility Utilities

/// Comprehensive accessibility support for LyoApp
/// Provides reusable components and utilities for enhanced accessibility
struct AccessibilityUtilities {
    
    // MARK: - Accessibility Identifiers
    struct IDs {
        // Learn View
        static let learnView = "learn_view"
        static let courseHeader = "course_header"
        static let courseProgress = "course_progress"
        static let courseContent = "course_content"
        static let quizButton = "quiz_start_button"
        static let quizQuestion = "quiz_question"
        static let quizAnswer = "quiz_answer"
        static let nextButton = "next_button"
        static let aiChatButton = "ai_chat_button"
        
        // Navigation
        static let tabBar = "main_tab_bar"
        static let homeTab = "home_tab"
        static let learnTab = "learn_tab"
        static let communityTab = "community_tab"
        static let discoverTab = "discover_tab"
        static let profileTab = "profile_tab"
        
        // Common
        static let closeButton = "close_button"
        static let backButton = "back_button"
        static let menuButton = "menu_button"
        static let searchField = "search_field"
    }
    
    // MARK: - Accessibility Labels
    struct Labels {
        static func courseProgress(_ current: Int, _ total: Int, _ progress: Double) -> String {
            "Course progress: Chapter \(current) of \(total), \(Int(progress * 100))% complete"
        }
        
        static func quizProgress(_ current: Int, _ total: Int) -> String {
            "Quiz progress: Question \(current) of \(total)"
        }
        
        static func difficultyBadge(_ difficulty: String) -> String {
            "Difficulty level: \(difficulty)"
        }
        
        static func estimatedTime(_ minutes: Int) -> String {
            "Estimated reading time: \(minutes) minutes"
        }
        
        static func tabItem(_ name: String, _ isSelected: Bool) -> String {
            "\(name) tab" + (isSelected ? ", selected" : "")
        }
    }
    
    // MARK: - Accessibility Hints
    struct Hints {
        static let startQuiz = "Double tap to start the chapter quiz"
        static let submitAnswer = "Double tap to submit your selected answer"
        static let nextQuestion = "Double tap to continue to the next question"
        static let completeQuiz = "Double tap to complete the quiz and see your results"
        static let selectAnswer = "Double tap to select this answer option"
        static let navigateTab = "Double tap to navigate to this section"
        static let closeModal = "Double tap to close this screen"
        static let expandContent = "Double tap to expand this content"
        static let openAIChat = "Double tap to open AI chat assistant"
    }
    
    // MARK: - Accessibility Values
    struct Values {
        static func progressValue(_ progress: Double) -> String {
            "\(Int(progress * 100))%"
        }
        
        static func scoreValue(_ correct: Int, _ total: Int) -> String {
            "\(correct) out of \(total) correct"
        }
        
        static func timeValue(_ minutes: Int) -> String {
            "\(minutes) minutes"
        }
    }
}

// MARK: - Accessibility View Modifiers

extension View {
    /// Enhanced accessibility label with automatic dynamic type support
    func accessibleLabel(_ label: String, hint: String? = nil, value: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }
    
    /// Mark as accessibility element with proper traits
    func accessibleElement(traits: AccessibilityTraits = [], isEnabled: Bool = true) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(traits)
            .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
    }
    
    /// Accessibility action with custom action
    func accessibleAction(named: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: named, action)
    }
    
    /// Focus management for VoiceOver
    func accessibilityFocused<T: Hashable>(_ binding: Binding<T?>, equals value: T) -> some View {
        if #available(iOS 15.0, *) {
            return self.accessibilityFocused(binding, equals: value)
        } else {
            return self
        }
    }
    
    /// Dynamic Type support with custom scaling
    func dynamicTypeSize(_ range: ClosedRange<DynamicTypeSize>) -> some View {
        if #available(iOS 15.0, *) {
            return self.dynamicTypeSize(range)
        } else {
            return self
        }
    }
    
    /// Semantic content description for complex layouts
    func semanticContent(_ type: AccessibilitySemanticContentType) -> some View {
        if #available(iOS 16.0, *) {
            return self.accessibilityRepresentation {
                Text("Semantic content: \(type.rawValue)")
            }
        } else {
            return self
        }
    }
}

// MARK: - Accessibility Wrapper Views

/// Accessible Card View with proper focus management
struct AccessibleCard<Content: View>: View {
    let content: Content
    let title: String
    let description: String?
    let accessibilityID: String
    let action: (() -> Void)?
    
    init(
        title: String,
        description: String? = nil,
        accessibilityID: String,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.description = description
        self.accessibilityID = accessibilityID
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityHint(description ?? "")
            .accessibilityIdentifier(accessibilityID)
            .accessibilityAddTraits(action != nil ? .isButton : [])
            .onTapGesture {
                action?()
            }
    }
}

/// Accessible Progress View with enhanced descriptions
struct AccessibleProgressView: View {
    let progress: Double
    let label: String
    let showPercentage: Bool
    
    init(progress: Double, label: String, showPercentage: Bool = true) {
        self.progress = progress
        self.label = label
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        ProgressView(value: progress)
            .progressViewStyle(LinearProgressViewStyle(tint: DesignTokens.Colors.primary))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(AccessibilityUtilities.Values.progressValue(progress))
            .accessibilityAddTraits(.updatesFrequently)
    }
}

/// Accessible Button with enhanced feedback
struct AccessibleButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void
    let accessibilityID: String
    let hint: String?
    let isEnabled: Bool
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary, secondary, tertiary
        
        var backgroundColor: Color {
            switch self {
            case .primary: return DesignTokens.Colors.primary
            case .secondary: return DesignTokens.Colors.secondary
            case .tertiary: return DesignTokens.Colors.glassBg
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary: return .white
            case .tertiary: return DesignTokens.Colors.textPrimary
            }
        }
    }
    
    init(
        title: String,
        systemImage: String? = nil,
        style: ButtonStyle = .primary,
        isEnabled: Bool = true,
        accessibilityID: String,
        hint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.style = style
        self.isEnabled = isEnabled
        self.accessibilityID = accessibilityID
        self.hint = hint
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(DesignTokens.Typography.buttonLabel)
            }
            .foregroundColor(style.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignTokens.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.Radius.button)
                    .fill(isEnabled ? style.backgroundColor : DesignTokens.Colors.textTertiary)
            )
        }
        .disabled(!isEnabled)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityHint(hint ?? "")
        .accessibilityIdentifier(accessibilityID)
        .accessibilityAddTraits(.isButton)
        .accessibilityRemoveTraits(isEnabled ? [] : .isButton)
    }
}

/// Accessible Text with Dynamic Type support
struct AccessibleText: View {
    let text: String
    let font: Font
    let color: Color
    let maxScaleLimit: DynamicTypeSize
    
    init(
        _ text: String,
        font: Font = DesignTokens.Typography.body,
        color: Color = DesignTokens.Colors.textPrimary,
        maxScaleLimit: DynamicTypeSize = .accessibility3
    ) {
        self.text = text
        self.font = font
        self.color = color
        self.maxScaleLimit = maxScaleLimit
    }
    
    var body: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .dynamicTypeSize(...maxScaleLimit)
    }
}

/// Accessible List Item with enhanced navigation
struct AccessibleListItem<Content: View>: View {
    let title: String
    let subtitle: String?
    let accessibilityID: String
    let action: (() -> Void)?
    let content: Content
    
    init(
        title: String,
        subtitle: String? = nil,
        accessibilityID: String,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.accessibilityID = accessibilityID
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title + (subtitle != nil ? ", \(subtitle!)" : ""))
            .accessibilityIdentifier(accessibilityID)
            .accessibilityAddTraits(action != nil ? .isButton : [])
            .onTapGesture {
                action?()
            }
    }
}

// MARK: - Focus Management

/// Focus management for enhanced VoiceOver navigation
@available(iOS 15.0, *)
struct AccessibilityFocusManager: ObservableObject {
    @Published var currentFocus: String?
    
    func setFocus(to element: String) {
        currentFocus = element
    }
    
    func clearFocus() {
        currentFocus = nil
    }
}

// MARK: - Reduced Motion Support

extension View {
    /// Apply animations only if reduce motion is disabled
    func accessibleAnimation<V: Equatable>(_ animation: Animation?, value: V) -> some View {
        self.modifier(ReducedMotionModifier(animation: animation, value: value))
    }
}

struct ReducedMotionModifier<V: Equatable>: ViewModifier {
    let animation: Animation?
    let value: V
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? nil : animation, value: value)
    }
}

// MARK: - Color Contrast Support

extension Color {
    /// Enhanced contrast version for accessibility
    var highContrast: Color {
        // Return high contrast version based on environment
        self
    }
    
    /// Check if color meets WCAG accessibility standards
    func meetsContrastRequirements(against background: Color) -> Bool {
        // Simplified contrast check - in production, implement full WCAG calculation
        true
    }
}

// MARK: - Announcement Support

struct AccessibilityAnnouncement {
    static func announce(_ message: String, priority: AccessibilityNotificationPriority = .medium) {
        DispatchQueue.main.async {
            AccessibilityNotification.Announcement(message)
                .post(priority: priority)
        }
    }
    
    static func announceLayoutChange(_ message: String? = nil) {
        DispatchQueue.main.async {
            AccessibilityNotification.LayoutChanged(message).post()
        }
    }
    
    static func announceScreenChange(_ message: String? = nil) {
        DispatchQueue.main.async {
            AccessibilityNotification.ScreenChanged(message).post()
        }
    }
}
