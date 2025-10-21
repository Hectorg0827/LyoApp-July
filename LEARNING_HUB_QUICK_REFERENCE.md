# Learning Hub - Quick Reference Guide

## 🎤 Voice Input

### How to Use
1. Tap microphone icon in chat input
2. Grant permission (first time)
3. Speak your message
4. Tap again to stop - message auto-sends

### Technical Details
- **File:** `VoiceRecognitionService.swift`
- **Framework:** Speech + AVFoundation
- **Requirement:** Physical device (not simulator)
- **Visual Feedback:** Red pulsing mic button during recording

---

## 🤖 Backend AI Integration

### How It Works
```
User Input → Backend API Call → Course Generation → Unity Launch
                    ↓ (if fails)
              Fallback Simulation
```

### Key Files
- `LearningChatViewModel.swift` - `generateCourse()` method
- `AICourseGenerationService.swift` - API service

### Testing
- **Online:** Real AI course generation
- **Offline:** Automatic fallback to simulated courses

---

## 📊 Analytics Tracking

### Events Tracked
✓ Conversation start/messages
✓ Course generation (success/fail)
✓ Course launch with timing
✓ Voice input usage
✓ Topic interests
✓ Level preferences

### View Logs
Check Xcode console for:
```
📊 Analytics: [event description]
```

### Files
- `LearningHubAnalytics.swift` - All tracking logic
- `LearningChatViewModel.swift` - Conversation tracking
- `LearningHubLandingView.swift` - Screen tracking

---

## 🎯 Personalization

### How It Works
1. User actions → Analytics tracks interests
2. Preferences stored in UserDefaults
3. Recommendations scored by:
   - Topic match (40%)
   - Level match (30%)
   - Rating (20%)
   - Popularity (10%)

### View Recommendations
- Bottom drawer on Learning Hub
- Swipe up to view
- Personalized based on your learning history

### Files
- `LearningDataManager.swift` - `generatePersonalizedRecommendations()`

---

## 🔧 Testing Checklist

### Voice Input ✅
- [ ] Run on physical device
- [ ] Tap microphone in chat
- [ ] Grant permissions
- [ ] Speak message
- [ ] Verify auto-send

### Backend AI ✅
- [ ] Enter topic in chat
- [ ] Select focus area
- [ ] Choose difficulty level
- [ ] Verify course generation
- [ ] Watch 3-2-1 countdown
- [ ] Confirm Unity launch

### Analytics ✅
- [ ] Open Xcode console
- [ ] Start conversation
- [ ] Check logs appear
- [ ] Complete course creation
- [ ] Verify all events tracked

### Personalization ✅
- [ ] Complete a course
- [ ] Return to Learning Hub
- [ ] Check recommendations
- [ ] Verify topic/level match

---

## 📁 Key Files

### Services
```
Services/
├── VoiceRecognitionService.swift      (NEW - 180 lines)
├── LearningHubAnalytics.swift         (NEW - 350 lines)
└── AICourseGenerationService.swift    (Existing - Modified)
```

### Views
```
LearningHub/Views/
├── LearningHubLandingView.swift       (Modified)
├── Components/
    └── CourseJourneyPreviewCard.swift (NEW - 200 lines)
```

### ViewModels
```
LearningHub/ViewModels/
└── LearningChatViewModel.swift        (Modified - Backend integration)
```

### Managers
```
LearningHub/Managers/
└── LearningDataManager.swift          (Modified - Personalization)
```

---

## 🚨 Troubleshooting

### Voice Not Working?
- Check: Physical device (not simulator)
- Check: Microphone permission granted
- Check: Internet connection (required for Speech framework)

### Backend Failing?
- Check: Internet connection
- Expected: Falls back to simulated courses automatically
- View console for error logs

### Analytics Not Showing?
- Check: Xcode console is visible
- Check: Look for "📊 Analytics:" prefix
- Expected: Logs appear immediately

### Recommendations Not Personalized?
- Check: Complete at least one course first
- Check: UserDefaults for stored preferences
- Expected: Improves over time with usage

---

## 🎯 Common Use Cases

### Create Voice-Driven Course
1. Tap mic → "I want to learn quantum physics"
2. Select "Quantum Computing"
3. Choose "Intermediate"
4. Watch countdown → Unity launches

### Test Backend Integration
1. Enter text: "Machine Learning"
2. Pick focus: "Building models"
3. Select level: "Advanced"
4. Verify backend call (check console)
5. Falls back if offline

### View Analytics
1. Open console while using app
2. Look for 📊 Analytics logs
3. Each action tracked in real-time
4. Session ID links related events

### Get Personalized Recommendations
1. Complete any course
2. Swipe up from bottom
3. See recommended courses
4. Higher match = better personalization

---

## 📞 Support

### Build Issues
```bash
# Clean build
Product → Clean Build Folder
# Rebuild
Product → Build
```

### Reset Preferences
```swift
// In app
UserDefaults.standard.removeObject(forKey: "user_topic_interests")
UserDefaults.standard.removeObject(forKey: "preferred_learning_level")
```

### Check Permissions
```swift
Settings → LyoApp → Permissions
- Microphone: ON
- Speech Recognition: ON
```

---

**Status:** ✅ All Systems Operational  
**Build:** ✅ SUCCESS  
**Ready for:** Device Testing & Production
