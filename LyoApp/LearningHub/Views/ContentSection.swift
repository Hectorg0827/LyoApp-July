// ContentSection.swift (legacy placeholder)
// This file previously contained a large implementation that introduced duplicate
// view/type declarations (LearningResourceCard / LearningResourceRow) and malformed
// Swift code after partial manual edits. All functional code has been migrated into
// dedicated view files (e.g. LearningResourceCards.swift, LearningCardView.swift).
//
// We retain a minimal, syntactically valid placeholder to avoid removing the file
// from the Xcode project immediately (reducing risk of project reference churn).
// It is safe to delete once project references are cleaned.

import SwiftUI

/// No‑op placeholder. Not referenced at runtime.
struct LegacyContentSectionPlaceholder: View {
    var body: some View { EmptyView() }
}

// MARK: - Preview (kept trivial to avoid unused warnings)
#if DEBUG
#Preview {
    LegacyContentSectionPlaceholder()
}
#endif
