// Centralized global model aliases and utilities
import Foundation
import SwiftUI
import SwiftData

// MARK: - GlobalModels Namespace
struct GlobalModels {
    // Global display mode enum
    enum DisplayMode: String, CaseIterable {
        case grid = "grid"
        case list = "list"
        case carousel = "carousel"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            case .carousel: return "rectangle.stack"
            }
        }
    }
}

// Build sentinel referencing DisplayMode to force early compilation; remove once build stable.
@inline(__always) func _assertDisplayModeReachable() {
    _ = GlobalModels.DisplayMode.grid
}
