# Migration Guide: Refactored Architecture

## Overview

This guide helps you migrate existing code to use the new consolidated architecture. All changes are **backward compatible**, but updating to the new patterns is recommended.

---

## Quick Reference

| Old Pattern | New Pattern | Status |
|------------|-------------|---------|
| `import ChatMessage` | No import needed | ✅ Deprecated |
| `AIMessage` with `sender: String` | `AIMessage` with `isFromUser: Bool` | ✅ Both work |
| `Color(hex: "...")` | `Color("...")` | ⚠️ Update required |
| `DesignTokens.X` (not found) | `DesignTokens.X` (public now) | ✅ Fixed |
| `APIEnvironment` (not found) | `APIEnvironment.current` | ✅ Fixed |

---

## Migration Steps by Category

### 1. AIMessage / ChatMessage

#### What Changed
- **OLD:** AIMessage defined in multiple places
- **NEW:** Single definition in `Models/Models.swift`
- **Impact:** All references now work correctly

#### Migration

**✅ No action required** - Backward compatibility maintained!

**Old code still works:**
```swift
// This still works (bridged)
let msg = AIMessage(
    content: "Hello",
    sender: "user",  // ← Old pattern
    timestamp: Date()
)
```

**Recommended new pattern:**
```swift
// Better - use new pattern
let msg = AIMessage(
    content: "Hello",
    isFromUser: true,  // ← New pattern
    timestamp: Date()
)
```

**If you have `import ChatMessage`:**
```swift
// BEFORE
import ChatMessage
let msg = AIMessage(...)

// AFTER (remove import)
let msg = AIMessage(...)  // No import needed
```

---

### 2. Color(hex:) Extension

#### What Changed
- **OLD:** `Color(hex: "6366F1")` with label
- **NEW:** `Color("6366F1")` without label
- **Impact:** Must update all usages

#### Migration

**⚠️ Action Required** - Update all Color calls

**Search and replace:**
```swift
// Find:    Color(hex: "
// Replace: Color("
```

**Examples:**
```swift
// BEFORE
Color(hex: "6366F1")
Color(hex: "FF0000")
.foregroundColor(Color(hex: "00FF00"))

// AFTER
Color("6366F1")
Color("FF0000")
.foregroundColor(Color("00FF00"))
```

**Script to help:**
```bash
# Run in terminal from project root
find LyoApp -name "*.swift" -exec sed -i '' 's/Color(hex: "/Color("/g' {} \;
```

---

### 3. DesignTokens Access

#### What Changed
- **OLD:** DesignTokens not visible (not public)
- **NEW:** DesignTokens fully public and accessible
- **Impact:** Previous "cannot find" errors now fixed

#### Migration

**✅ No action required** - Should work now!

**Before (would fail):**
```swift
.animation(DesignTokens.Animations.bouncy)  // ❌ Cannot find
```

**After (works now):**
```swift
.animation(DesignTokens.Animations.bouncy)  // ✅ Works!
```

**If still not working:**
1. Clean build folder: `Cmd + Shift + K`
2. Clean derived data
3. Rebuild project

---

### 4. APIEnvironment & APIKeys

#### What Changed
- **OLD:** Not public, couldn't access
- **NEW:** Fully public and accessible
- **Impact:** Previous "cannot find" errors now fixed

#### Migration

**✅ No action required** - Should work now!

**Usage:**
```swift
// Access environment
let env = APIEnvironment.current
let baseURL = env.base
let isLocal = APIEnvironment.isLocal

// Access API keys
let url = APIKeys.baseURL
let apiKey = APIKeys.geminiAPIKey
```

---

### 5. Avatar System

#### What Changed
- **OLD:** Types scattered across multiple files
- **NEW:** Definitions in Models.swift, extensions in AvatarModels.swift
- **Impact:** All types now accessible, no duplicates

#### Migration

**✅ No action required** - All types work!

**Available types (all public):**
```swift
Avatar
AvatarStyle
Personality
CompanionMood
CompanionState
AvatarMemory
UserAction
AvatarAppearance
PersonalityProfile
CalibrationAnswers
ScaffoldingStyle
```

**Usage:**
```swift
let avatar = Avatar()
let mood = CompanionMood.excited
let personality = Personality.friendlyCurious
```

---

### 6. Post, UserBadge, ClassroomCourse

#### What Changed
- **OLD:** Not public, couldn't access from other files
- **NEW:** Fully public
- **Impact:** NetworkLayer and other files can now use these types

#### Migration

**✅ No action required** - Should work now!

**Usage:**
```swift
let post = Post(author: user, content: "Hello")
let badge = UserBadge(...)
let course = ClassroomCourse(...)
```

---

## File-Specific Migrations

### If You're Editing: Models/ChatMessage.swift

**⚠️ STOP!** This file is deprecated.

**Instead:**
- Add types to `Models/Models.swift`
- Add extensions to appropriate files (AIModels.swift, AvatarModels.swift)

```swift
// DON'T ADD TO ChatMessage.swift
// ❌ ChatMessage.swift
struct MyNewType { }

// DO ADD TO Models.swift
// ✅ Models.swift
public struct MyNewType {
    public var property: String
}
```

---

### If You're Editing: GamificationOverlay.swift

**Issue:** Cannot find DesignTokens

**Solution:** Already fixed - DesignTokens is now public

**Verify:**
```swift
import SwiftUI

struct GamificationOverlay: View {
    var body: some View {
        VStack {
            // Should work now
            Text("Hello")
                .animation(DesignTokens.Animations.bouncy)
        }
    }
}
```

---

### If You're Editing: NetworkLayer.swift

**Issue:** Cannot find Post, ClassroomCourse, APIKeys

**Solution:** Already fixed - all are now public

**Verify:**
```swift
func fetchPosts() async throws -> [Post] {  // ✅ Works
    try await request(endpoint: "/posts", responseType: [Post].self)
}

func fetchCourses() async throws -> [ClassroomCourse] {  // ✅ Works
    try await request(endpoint: "/courses", responseType: [ClassroomCourse].self)
}

private var baseURL: URL {
    return URL(string: APIKeys.baseURL)!  // ✅ Works
}
```

---

### If You're Editing: APIConfig.swift

**Issue:** Cannot find APIEnvironment

**Solution:** Already fixed - APIEnvironment is now public

**Verify:**
```swift
struct APIConfig {
    static var baseURL: String {
        return APIEnvironment.current.base.absoluteString  // ✅ Works
    }
}
```

---

## Testing Your Migration

### Quick Test Checklist

Run through these to verify everything works:

```swift
// 1. AIMessage
let msg1 = AIMessage(content: "Test", isFromUser: true)
let msg2 = AIMessage(content: "Test", sender: "user")  // Legacy
print(msg1.sender)  // Should print "user"

// 2. Color
let color = Color("6366F1")  // No hex: label

// 3. DesignTokens
let glass = DesignTokens.Glass.contentLayer
let anim = DesignTokens.Animations.bouncy

// 4. APIEnvironment
let env = APIEnvironment.current
let url = env.base

// 5. APIKeys
let baseURL = APIKeys.baseURL

// 6. Avatar System
let avatar = Avatar()
let mood = CompanionMood.excited

// 7. Post, Badge, Course
let badge = UserBadge(...)
// (with appropriate parameters)
```

### Build Test

```bash
# Clean build
xcodebuild clean -project LyoApp.xcodeproj -scheme "LyoApp 1"

# Build
xcodebuild build -project LyoApp.xcodeproj -scheme "LyoApp 1" -sdk iphonesimulator
```

---

## Common Issues & Solutions

### Issue: "Cannot find type AIMessage"

**Cause:** Looking for AIMessage in wrong place

**Solution:**
```swift
// DON'T import ChatMessage
// import ChatMessage  // ❌

// DO use directly (it's in Models.swift, same module)
let msg = AIMessage(...)  // ✅
```

---

### Issue: "Ambiguous use of AIMessage"

**Cause:** Old duplicate definitions still in derived data

**Solution:**
1. Clean build folder: `Cmd + Shift + K`
2. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/LyoApp-*
   ```
3. Rebuild

---

### Issue: "Cannot find DesignTokens"

**Cause 1:** Derived data not updated
**Solution:** Clean and rebuild

**Cause 2:** DesignTokens.swift not in build target
**Solution:** Check Xcode → File Inspector → Target Membership

---

### Issue: "Extraneous argument label 'hex:' in call"

**Cause:** Using old Color(hex:) syntax

**Solution:** Remove hex: label
```swift
// WRONG
Color(hex: "FF0000")

// RIGHT
Color("FF0000")
```

---

### Issue: "Cannot convert value of type 'String' to expected argument type 'Bool'"

**Cause:** Mixing old/new AIMessage initializers

**Solution:**
```swift
// If using sender
let msg = AIMessage(content: "Hi", sender: "user")  // Use bridged init

// If using isFromUser
let msg = AIMessage(content: "Hi", isFromUser: true)  // Use new init
```

---

## Advanced: Creating New Types

### Adding a New Model

**Step 1:** Add to Models/Models.swift
```swift
// At end of Models/Models.swift
public struct MyNewType: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var description: String

    public init(id: UUID = UUID(), name: String, description: String) {
        self.id = id
        self.name = name
        self.description = description
    }
}
```

**Step 2:** Add extensions if needed
```swift
// In appropriate extension file (e.g., AIModels.swift)
extension MyNewType {
    public var displayName: String {
        return name.uppercased()
    }
}
```

---

### Adding a New Enum

```swift
// In Models/Models.swift
public enum MyNewEnum: String, Codable, CaseIterable {
    case option1 = "Option 1"
    case option2 = "Option 2"

    public var description: String {
        switch self {
        case .option1: return "First option"
        case .option2: return "Second option"
        }
    }
}
```

---

### Adding to Design System

```swift
// In DesignTokens.swift, within DesignTokens struct
public struct MyNewTokens {
    public static let primaryValue = "value"
    public static let secondaryValue = 42

    public struct Nested {
        public static let nestedValue = Color.blue
    }
}

// Usage
let value = DesignTokens.MyNewTokens.primaryValue
```

---

## Rollback Plan

If you need to temporarily rollback:

### Emergency Rollback

**Not recommended**, but if absolutely necessary:

```bash
# Revert specific file
git checkout HEAD -- LyoApp/Models/Models.swift

# Or revert all changes
git reset --hard HEAD~1  # Only if no other changes!
```

**Better approach:** Fix the specific issue instead of rolling back.

---

## Support & Questions

### Documentation
- **Architecture Guide:** `ARCHITECTURE_GUIDE.md`
- **This Migration Guide:** `MIGRATION_GUIDE.md`

### Common Commands

```bash
# Clean build
xcodebuild clean

# Build project
xcodebuild build -project LyoApp.xcodeproj -scheme "LyoApp 1"

# Find Color(hex:) usage
grep -r "Color(hex:" LyoApp/

# Replace Color(hex:) usage
find LyoApp -name "*.swift" -exec sed -i '' 's/Color(hex: "/Color("/g' {} \;

# Find AIMessage usage
grep -r "AIMessage" LyoApp/ --include="*.swift"
```

---

## Checklist: Migration Complete

Use this checklist to verify your migration:

- [ ] ✅ Removed all `import ChatMessage` statements
- [ ] ✅ Updated `Color(hex: "...")` to `Color("...")`
- [ ] ✅ Verified DesignTokens accessible
- [ ] ✅ Verified APIEnvironment accessible
- [ ] ✅ Verified all Avatar types accessible
- [ ] ✅ Clean build succeeds
- [ ] ✅ No "cannot find type" errors
- [ ] ✅ No "ambiguous use" errors
- [ ] ✅ App runs without crashes
- [ ] ✅ Reviewed ARCHITECTURE_GUIDE.md
- [ ] ✅ Updated team documentation

---

## Timeline

### Immediate (Do Now)
- [ ] Update `Color(hex:)` calls
- [ ] Remove `import ChatMessage`
- [ ] Clean build to verify

### Short Term (This Week)
- [ ] Update AIMessage to use `isFromUser` in new code
- [ ] Review all model usages
- [ ] Update team on changes

### Long Term (This Month)
- [ ] Migrate all old `sender: String` usage to `isFromUser: Bool`
- [ ] Remove deprecated patterns
- [ ] Add new features using new architecture

---

## Summary

The refactoring provides:

✅ **Cleaner code** - Single source of truth
✅ **Better performance** - No duplicate compilation
✅ **Easier maintenance** - Clear structure
✅ **Backward compatible** - Old code still works
✅ **Future-proof** - Solid foundation

Most migrations are **automatic** - just clean and rebuild!

---

**Last Updated:** 2025-10-20
**Version:** 2.0
**Status:** Production Ready
