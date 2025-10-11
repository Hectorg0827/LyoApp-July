# Copilot AI Coding Agent Instructions for LyoApp

## Project Overview
- **LyoApp** is a SwiftUI-based iOS application with a modular architecture. Major features include a social feed, user profiles, course recommendations, and analytics.
- The codebase is organized by feature, with each major screen or service in its own Swift file (e.g., `HomeFeedView.swift`, `User.swift`, `Course.swift`).
- Data models are shared across features. The canonical `User` and `Course` models are defined in their respective files and should be used throughout the app.

## Key Architectural Patterns
- **Feed System:**
  - The feed is managed by a `FeedManager` class (see `HomeFeedView.swift`), which implements the `FeedDataProvider` protocol.
  - Feed content is represented as an enum (`FeedContentType`) that can be a video, course suggestion, or user suggestion.
  - All user-related data in the feed and suggestions must use the canonical `User` model from `User.swift`.
- **Views:**
  - SwiftUI is used throughout. Views are split by function (e.g., `FeedItemView`, `UserProfileSheet`, `CourseCard`).
  - Use `@StateObject` and `@EnvironmentObject` for view models and app state.
  - UI tokens and design constants are centralized in `DesignTokens.swift`.
- **Mock Data:**
  - Mock data for users, courses, and feed items is generated in the feed manager using the canonical models.
  - When adding new mock data, follow the structure in `generateSuggestedUsers()` and `generateRandomFeedItem()`.

## Developer Workflows
- **Build:**
  - Use the VS Code task: `Build Xcode Project` (runs `xcodebuild -scheme LyoApp -workspace LyoApp.xcworkspace build`).
- **Testing:**
  - Tests are colocated with their implementation (e.g., `WebSocketServiceTests.swift`).
  - Run tests via Xcode or command line as appropriate for Swift projects.
- **Debugging:**
  - Use SwiftUI previews (`#Preview`) for rapid UI iteration.
  - Analytics and memory warnings are handled in view lifecycle hooks (`onAppear`, `onDisappear`).

## Project-Specific Conventions
- **Canonical Models:**
  - Always use the main `User` and `Course` models for all user/course data. Do not duplicate user structs (e.g., `FeedUser`, `SuggestedUser`).
- **Accessibility:**
  - Use the provided `AccessibleText`, `AccessibleButton`, and `AccessibleCard` components for accessible UI.
- **Design Tokens:**
  - All colors, spacing, and typography should use `DesignTokens.swift`.
- **Async Data Loading:**
  - Use `Task { ... }` and `@MainActor` for async operations in view models.
- **Performance:**
  - Use `LazyRenderView` and optimized view patterns for large lists and feed content.

## Integration Points
- **Analytics:**
  - Analytics tracking is handled via `.trackScreenView()` and related hooks in views.
- **Networking:**
  - Network and WebSocket logic is in `NetworkLayer.swift` and `WebSocketService.swift`.
- **Assets:**
  - Images and icons are managed in `Assets.xcassets`.

## Example: Adding a New Feed Content Type
1. Update `FeedContentType` in `HomeFeedView.swift`.
2. Update `FeedManager` to generate and handle the new type.
3. Add a new SwiftUI view for the content type.
4. Update `FeedContentView` to render the new type.

## Key Files
- `HomeFeedView.swift`: Feed logic, main view, and feed manager.
- `User.swift`: Canonical user model.
- `Course.swift`: Canonical course model.
- `DesignTokens.swift`: Design system constants.
- `NetworkLayer.swift`, `WebSocketService.swift`: Networking.

---

If you are unsure about a pattern or encounter duplicate models, always prefer the canonical model and check for existing usage in the main feature files.
