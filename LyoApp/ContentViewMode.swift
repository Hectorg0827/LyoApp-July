import Foundation

// MARK: - DisplayMode (formerly ContentViewMode)
// Lightweight display mode enum extracted from disabled legacy component file.
// Referenced by SearchResultsView and other learning hub views. Kept minimal.
public enum DisplayMode: CaseIterable, Hashable {
    case grid
    case list
    case carousel
}

// Alias removed to eliminate phantom 'ContentViewMode' compiler errors after migration.
