import SwiftUI

// MARK: - Main Tab Definition
enum MainTab: String, CaseIterable {
    case home = "Home"
    case discover = "Discover"
    case ai = "AI"
    case post = "Post"
    case more = "More"
    
    var icon: String {
        switch self {
        case .home:
            return "house"
        case .discover:
            return "safari"
        case .ai:
            return "brain.head.profile"
        case .post:
            return "plus"
        case .more:
            return "ellipsis"
        }
    }
    
    var accessibleName: String {
        switch self {
        case .home:
            return "Home Feed"
        case .discover:
            return "Discover Content"
        case .ai:
            return "AI Learning"
        case .post:
            return "Create Post"
        case .more:
            return "More Options"
        }
    }
    
    var accessibilityDescription: String {
        switch self {
        case .home:
            return "View your personalized feed and latest updates"
        case .discover:
            return "Explore new content and trending topics"
        case .ai:
            return "Access AI-powered learning features"
        case .post:
            return "Create a new post or story"
        case .more:
            return "Access additional app features and settings"
        }
    }
    
    var accessibilityIdentifier: String {
        return "tab_\(self.rawValue.lowercased())"
    }
}
