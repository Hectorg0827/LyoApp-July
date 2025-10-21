# 🧪 Phase 1.8: Testing & Quality Assurance Guide

**Status:** Ready for Testing  
**Date:** October 6, 2025  
**Build:** ✅ Successful  

---

## 🎯 Testing Objectives

1. **Verify all features work end-to-end**
2. **Ensure smooth user experience across devices**
3. **Identify and document any issues**
4. **Validate performance and memory usage**
5. **Confirm accessibility compliance**

---

## 🚀 Quick Start Testing

### Step 1: Launch the App
```bash
# Option A: Using Xcode
1. Open LyoApp.xcodeproj
2. Select "LyoApp 1" scheme
3. Choose iPhone 15 Pro simulator
4. Press ⌘R to run

# Option B: Using VS Code Task
1. Open Command Palette (⌘⇧P)
2. Type "Tasks: Run Task"
3. Select "Build Xcode Project"
4. Wait for build to complete
5. Open Simulator manually
```

### Step 2: Navigate to Diagnostic Flow
1. Launch app
2. Wait for launch screen
3. Tap "Get Started" or similar button
4. **Avatar Selection** screen should appear

### Step 3: Complete Full Flow
1. **Avatar Selection:** Pick an avatar, enter name, tap Continue
2. **Diagnostic Dialogue:** Answer all 6 questions
3. **Course Generation:** Watch blueprint convert to course
4. **AI Classroom:** Enter learning experience

---

## 📋 Detailed Test Cases

### Test Suite 1: Avatar Selection (Phase 1.3b)

#### TC-1.1: Select Avatar
**Steps:**
1. Launch app → Avatar selection
2. Tap on "Energetic" avatar (⚡)
3. Verify selection indicator appears (checkmark)
4. Tap on "Wise" avatar (🧙)
5. Verify previous selection cleared

**Expected:**
- ✅ Only one avatar selected at a time
- ✅ Checkmark appears on selected avatar
- ✅ Visual feedback on tap (scale animation)

**Pass Criteria:** Selection works, visual feedback clear

---

#### TC-1.2: Name Input
**Steps:**
1. Tap text field "Name your companion"
2. Type "TestBot"
3. Verify text appears
4. Clear text, type "A" (single character)
5. Clear text, type 50-character name

**Expected:**
- ✅ Keyboard appears correctly
- ✅ Text displays as typed
- ✅ Single character accepted
- ✅ Long names handled gracefully (truncate or wrap)

**Pass Criteria:** Text input works, no crashes on edge cases

---

#### TC-1.3: Continue Button
**Steps:**
1. Without selecting avatar, tap Continue
2. Verify behavior (should allow or show error?)
3. Select avatar, leave name empty
4. Tap Continue
5. Select avatar, enter name, tap Continue

**Expected:**
- ✅ Gracefully handles missing selection/name
- ✅ Transitions to diagnostic dialogue
- ✅ Smooth animation (slide from right)

**Pass Criteria:** Button behavior logical, no crashes

---

#### TC-1.4: Skip Button
**Steps:**
1. Tap "Skip for now"
2. Verify default avatar used
3. Check if name defaults to "Lyo"
4. Verify transition to diagnostic

**Expected:**
- ✅ Default avatar assigned
- ✅ Default name assigned
- ✅ Smooth transition

**Pass Criteria:** Skip works, sensible defaults applied

---

### Test Suite 2: Diagnostic Dialogue (Phase 1.6)

#### TC-2.1: Initial State
**Steps:**
1. Enter diagnostic dialogue
2. Observe TopProgressBar
3. Check conversation area
4. Check blueprint preview

**Expected:**
- ✅ Avatar mood circle displays (😊 friendly)
- ✅ "Building Your Path" text visible
- ✅ "Question 1 of 6" displays
- ✅ Progress bar at 0%
- ✅ First AI message appears: "What would you love to learn?"
- ✅ Blueprint area empty (no nodes yet)

**Pass Criteria:** All UI elements render correctly

---

#### TC-2.2: Answer Question 1 (Open-Ended)
**Steps:**
1. Type "Python programming" in text field
2. Tap send button (or press return)
3. Watch for response

**Expected:**
- ✅ User message appears (blue, right-aligned)
- ✅ Message bubble animates in
- ✅ Text field clears
- ✅ Brief delay (~500ms)
- ✅ Topic node appears in blueprint (blue circle, "Python programming")
- ✅ Next AI message: "Great! What's your main goal?"
- ✅ Progress bar updates to 33% (Question 2 of 6)
- ✅ Avatar mood changes to curious (🧐)

**Pass Criteria:** Full conversation cycle works, blueprint updates

---

#### TC-2.3: Answer Question 2 (Open-Ended)
**Steps:**
1. Type "Build mobile apps"
2. Send

**Expected:**
- ✅ User message appears
- ✅ Goal node appears (green circle, connected to topic)
- ✅ Connection line drawn between topic and goal
- ✅ Next question: "How much time can you dedicate per week?"
- ✅ Suggested chips appear: [1-2 hours] [3-5 hours] [6-10 hours] [10+ hours]
- ✅ Progress bar: 50% (Question 3 of 6)

**Pass Criteria:** Multiple-choice UI appears correctly

---

#### TC-2.4: Answer Question 3 (Multiple Choice)
**Steps:**
1. Tap suggested chip "3-5 hours"
2. Watch response

**Expected:**
- ✅ Chip animates on tap
- ✅ User message appears with selected text
- ✅ No new node (pace is property, not node)
- ✅ Next question: "How do you learn best?"
- ✅ New chips: [Hands-on projects] [Video tutorials] [Reading] [Interactive exercises]
- ✅ Progress bar: 67% (Question 4 of 6)

**Pass Criteria:** Suggested chips work, no duplicate nodes

---

#### TC-2.5: Answer Question 4 (Multiple Choice)
**Steps:**
1. Tap "Hands-on projects"

**Expected:**
- ✅ Skill node appears (purple circle)
- ✅ Connected to topic node
- ✅ Next question: "What's your experience level?"
- ✅ New chips: [Complete beginner] [Know the basics] [Intermediate] [Advanced]
- ✅ Progress bar: 83% (Question 5 of 6)

**Pass Criteria:** Skill node appears, connections correct

---

#### TC-2.6: Answer Question 5 (Multiple Choice)
**Steps:**
1. Tap "Complete beginner"

**Expected:**
- ✅ Milestone node appears (pink circle)
- ✅ Connected to topic node
- ✅ Next question: "What motivates you to learn?"
- ✅ New chips: [Career growth] [Personal interest] [Build something] [Solve problems]
- ✅ Progress bar: 100% (Question 6 of 6)

**Pass Criteria:** Milestone node appears, near completion

---

#### TC-2.7: Answer Question 6 (Multiple Choice - Final)
**Steps:**
1. Tap "Build something"

**Expected:**
- ✅ No new node (motivation is property)
- ✅ Final AI message: "Perfect! I've created your personalized learning path. Let's get started! 🎉"
- ✅ Avatar mood changes to excited (🤩)
- ✅ Progress bar: 100%
- ✅ Brief pause (~1s)
- ✅ Transition to course generation screen

**Pass Criteria:** Completes gracefully, transitions to next screen

---

#### TC-2.8: Blueprint Visualization
**Steps:**
1. During diagnostic, observe blueprint preview
2. Count nodes after each question
3. Verify connections

**Expected:**
- ✅ Question 1: 1 node (topic) - center position
- ✅ Question 2: 2 nodes (topic + goal) - 1 connection
- ✅ Question 3: Still 2 nodes
- ✅ Question 4: 3 nodes (+ skill) - 2 connections
- ✅ Question 5: 4 nodes (+ milestone) - 3 connections
- ✅ Question 6: Still 4 nodes
- ✅ Nodes don't overlap
- ✅ Connection lines visible and clear

**Pass Criteria:** Blueprint builds progressively, visually clear

---

#### TC-2.9: Typing Custom Response
**Steps:**
1. On multiple-choice question, ignore chips
2. Type custom response in text field
3. Send

**Expected:**
- ✅ Custom text accepted
- ✅ Conversation continues
- ✅ Blueprint updates based on custom response

**Pass Criteria:** Not forced to use suggested chips

---

#### TC-2.10: Long User Responses
**Steps:**
1. Type 500+ character response
2. Send

**Expected:**
- ✅ Message accepts long text
- ✅ Bubble wraps text correctly
- ✅ Doesn't break UI layout
- ✅ Conversation continues normally

**Pass Criteria:** No crashes, layout intact

---

### Test Suite 3: Integration & Flow

#### TC-3.1: Complete Journey
**Steps:**
1. Start from launch
2. Complete avatar selection
3. Complete all 6 diagnostic questions
4. Reach course generation

**Expected:**
- ✅ Smooth transitions between states
- ✅ No data loss between screens
- ✅ Blueprint data passed correctly
- ✅ Topic from blueprint used in course generation

**Pass Criteria:** End-to-end flow works seamlessly

---

#### TC-3.2: Back Navigation (if applicable)
**Steps:**
1. Enter diagnostic dialogue
2. Attempt to go back (swipe or button)
3. Check behavior

**Expected:**
- Current: Back navigation may not be implemented
- Future: Should ask "Are you sure? Progress will be lost"

**Pass Criteria:** Document current behavior

---

#### TC-3.3: App Backgrounding
**Steps:**
1. Start diagnostic, answer 2 questions
2. Press Home button (background app)
3. Wait 10 seconds
4. Reopen app

**Expected:**
- ✅ Returns to diagnostic screen
- ✅ Conversation history preserved
- ✅ Blueprint preserved
- ✅ Can continue from where left off

**Pass Criteria:** State persists during backgrounding

---

#### TC-3.4: App Termination
**Steps:**
1. Start diagnostic, answer 3 questions
2. Force quit app (swipe up in app switcher)
3. Relaunch app

**Expected:**
- Current: Starts from beginning (no persistence)
- Future: Could restore session

**Pass Criteria:** Document current behavior (no persistence is OK for MVP)

---

### Test Suite 4: UI/UX Quality

#### TC-4.1: iPhone SE (Small Screen)
**Steps:**
1. Switch simulator to iPhone SE (3rd gen)
2. Run through diagnostic flow
3. Check all UI elements

**Expected:**
- ✅ 60/40 split still readable
- ✅ No text truncation
- ✅ Buttons tappable (44pt minimum)
- ✅ Blueprint nodes don't overlap
- ✅ Message bubbles fit in conversation area

**Pass Criteria:** Usable on small screens

---

#### TC-4.2: iPhone 15 Pro Max (Large Screen)
**Steps:**
1. Switch to iPhone 15 Pro Max
2. Run through diagnostic flow

**Expected:**
- ✅ Layout scales appropriately
- ✅ No awkward spacing
- ✅ Text not too spread out
- ✅ Blueprint uses extra space well

**Pass Criteria:** Looks good on large screens

---

#### TC-4.3: iPad (Tablet)
**Steps:**
1. Switch to iPad Pro 12.9"
2. Test both portrait and landscape
3. Check layout

**Expected:**
- ✅ 60/40 split maintained
- ✅ Blueprint has more room for nodes
- ✅ Conversation area not stretched awkwardly
- ✅ Landscape mode works

**Pass Criteria:** Tablet experience is good

---

#### TC-4.4: Dark Mode
**Steps:**
1. Enable Dark Mode in simulator (Settings → Display)
2. Run through diagnostic

**Expected:**
- ✅ All text readable
- ✅ Contrast sufficient
- ✅ Colors adapted for dark background
- ✅ No blinding white elements

**Pass Criteria:** Dark mode looks professional

---

#### TC-4.5: Light Mode
**Steps:**
1. Enable Light Mode
2. Run through diagnostic

**Expected:**
- ✅ All text readable
- ✅ Contrast sufficient
- ✅ Colors work on light background

**Pass Criteria:** Light mode default looks good

---

#### TC-4.6: Animations
**Steps:**
1. Watch all animations during diagnostic
2. Rate smoothness (60fps ideal)

**Expected:**
- ✅ Progress bar animates smoothly
- ✅ Message bubbles slide in fluidly
- ✅ Node appearance is smooth
- ✅ Transition between screens smooth
- ✅ No stuttering or lag

**Pass Criteria:** Animations at 60fps, no jank

---

### Test Suite 5: Performance

#### TC-5.1: Memory Usage
**Steps:**
1. Open Xcode → Debug → Memory Report
2. Note baseline memory
3. Run through diagnostic
4. Note peak memory

**Expected:**
- ✅ Baseline: ~30-50MB
- ✅ During diagnostic: ~50-80MB
- ✅ No memory leaks
- ✅ Memory releases after completion

**Pass Criteria:** Memory usage reasonable, no leaks

---

#### TC-5.2: CPU Usage
**Steps:**
1. Open Xcode → Debug → CPU Usage
2. Monitor during diagnostic

**Expected:**
- ✅ Idle: < 5% CPU
- ✅ During animations: < 30% CPU
- ✅ During text input: < 10% CPU
- ✅ No sustained high CPU

**Pass Criteria:** CPU usage acceptable

---

#### TC-5.3: Response Time
**Steps:**
1. Measure time from tap to UI update
2. Use stopwatch or screen recording

**Expected:**
- ✅ Chip tap → message appears: < 100ms
- ✅ Send button → message appears: < 100ms
- ✅ User message → AI response: ~500ms (intentional delay)
- ✅ AI response → next question: < 200ms

**Pass Criteria:** UI feels responsive

---

#### TC-5.4: Battery Usage
**Steps:**
1. Enable Energy Log in Xcode
2. Run diagnostic for 5 minutes
3. Check energy impact

**Expected:**
- ✅ Energy impact: Low
- ✅ No excessive background activity
- ✅ No unnecessary network calls

**Pass Criteria:** Low battery impact

---

### Test Suite 6: Accessibility

#### TC-6.1: VoiceOver
**Steps:**
1. Enable VoiceOver (Settings → Accessibility)
2. Navigate diagnostic with VoiceOver

**Expected:**
- ✅ All buttons announced
- ✅ Message content read aloud
- ✅ Progress updates announced
- ✅ Node types announced
- ✅ Swipe gestures work

**Pass Criteria:** Fully navigable with VoiceOver

---

#### TC-6.2: Dynamic Type
**Steps:**
1. Settings → Accessibility → Display & Text Size → Larger Text
2. Increase text size to maximum
3. Run diagnostic

**Expected:**
- ✅ All text scales
- ✅ Layout adjusts to accommodate
- ✅ No text truncation
- ✅ Buttons still tappable

**Pass Criteria:** Works with largest text size

---

#### TC-6.3: Color Blindness
**Steps:**
1. Simulate color blindness modes
2. Check if node types distinguishable

**Expected:**
- ✅ Nodes distinguishable by shape/label (not just color)
- ✅ UI usable without color perception

**Pass Criteria:** Color not the only differentiator

---

### Test Suite 7: Edge Cases

#### TC-7.1: Rapid Input
**Steps:**
1. Tap suggested chips rapidly (5 taps in 1 second)
2. Type and send very quickly

**Expected:**
- ✅ No duplicate messages
- ✅ Queue handled correctly
- ✅ No UI corruption
- ✅ No crashes

**Pass Criteria:** Handles rapid input gracefully

---

#### TC-7.2: Empty Input
**Steps:**
1. Try to send empty message
2. Verify behavior

**Expected:**
- ✅ Send button disabled OR
- ✅ Ignores empty sends
- ✅ No empty bubbles appear

**Pass Criteria:** Empty input handled

---

#### TC-7.3: Special Characters
**Steps:**
1. Type message with emojis: "I want to learn Python 🐍 programming 💻"
2. Type message with symbols: "C++ & JavaScript (ES6+)"
3. Send

**Expected:**
- ✅ Emojis display correctly
- ✅ Special characters handled
- ✅ No encoding issues

**Pass Criteria:** Special characters work

---

#### TC-7.4: Very Long Topic Name
**Steps:**
1. First question, type: "I want to learn advanced machine learning with TensorFlow, PyTorch, and scikit-learn for computer vision, natural language processing, and reinforcement learning applications"

**Expected:**
- ✅ Message wraps in bubble
- ✅ Topic node displays truncated or full text
- ✅ Blueprint doesn't break layout

**Pass Criteria:** Long text handled gracefully

---

#### TC-7.5: No Internet (if applicable)
**Steps:**
1. Disable network connection
2. Run diagnostic

**Expected:**
- Current: Should work (no network needed for diagnostic)
- Future: May need network for AI analysis

**Pass Criteria:** Works offline for now

---

## 📊 Test Results Template

### Test Session Info
- **Date:** _____________
- **Tester:** _____________
- **Device:** _____________
- **iOS Version:** _____________
- **Build Number:** _____________

### Summary
- **Total Tests:** 40+
- **Passed:** ___
- **Failed:** ___
- **Skipped:** ___
- **Blocked:** ___

### Critical Issues (P0)
| ID | Description | Steps to Reproduce | Impact |
|----|-------------|-------------------|--------|
|    |             |                   |        |

### High Priority Issues (P1)
| ID | Description | Steps to Reproduce | Impact |
|----|-------------|-------------------|--------|
|    |             |                   |        |

### Medium Priority Issues (P2)
| ID | Description | Steps to Reproduce | Impact |
|----|-------------|-------------------|--------|
|    |             |                   |        |

### Low Priority Issues (P3)
| ID | Description | Steps to Reproduce | Impact |
|----|-------------|-------------------|--------|
|    |             |                   |        |

### Enhancement Suggestions
1. 
2. 
3. 

### Performance Metrics
- **Memory (Peak):** ______ MB
- **CPU (Average):** ______ %
- **Frame Rate:** ______ fps
- **Battery Impact:** Low / Medium / High

### Notes
_Any additional observations, comments, or context_

---

## 🐛 Bug Report Template

### Bug ID: [XXX]
**Priority:** P0 / P1 / P2 / P3  
**Status:** Open / In Progress / Fixed / Won't Fix

### Summary
_Brief one-line description_

### Environment
- **Device:** 
- **iOS Version:** 
- **App Version:** 

### Steps to Reproduce
1. 
2. 
3. 

### Expected Behavior
_What should happen_

### Actual Behavior
_What actually happens_

### Screenshots/Video
_Attach if available_

### Frequency
Always / Sometimes / Rare

### Workaround
_If any exists_

### Additional Context
_Logs, stack traces, related bugs_

---

## ✅ Acceptance Criteria for Production

### Must-Have (Blockers)
- [ ] All critical bugs (P0) fixed
- [ ] No crashes during normal usage
- [ ] All 6 questions work correctly
- [ ] Blueprint builds as expected
- [ ] Flow completes end-to-end
- [ ] Works on iPhone SE and iPhone 15 Pro
- [ ] Dark mode functional
- [ ] VoiceOver basic support

### Should-Have (High Priority)
- [ ] All P1 bugs fixed
- [ ] Performance acceptable (< 100MB, 60fps)
- [ ] iPad experience good
- [ ] Animations smooth
- [ ] Edge cases handled gracefully
- [ ] Memory no leaks

### Nice-to-Have (Polish)
- [ ] P2 bugs fixed
- [ ] All devices tested
- [ ] Accessibility fully compliant
- [ ] Animation polish
- [ ] Visual tweaks
- [ ] Copy improvements

---

## 🚀 When to Ship

### Green Light Criteria
✅ All Must-Have items complete  
✅ No known P0 bugs  
✅ < 3 P1 bugs remaining  
✅ Positive internal feedback  
✅ Performance metrics within target  
✅ Core flow works reliably  

### Hold/Fix Criteria
❌ Any P0 bug open  
❌ > 5 P1 bugs open  
❌ Frequent crashes  
❌ Major UX issue discovered  
❌ Performance unacceptable  

---

## 📞 Support

### Issue Reporting
- **GitHub Issues:** Create issue with "Phase 1.8" label
- **Internal:** Slack #lyoapp-testing channel
- **Direct:** Email to dev team

### Debug Logs
```swift
// Add this to DiagnosticViewModel if needed
func debugLog(_ message: String) {
    #if DEBUG
    print("[Diagnostic] \(Date()): \(message)")
    #endif
}
```

### Common Issues & Fixes

**Issue:** Diagnostic screen blank  
**Fix:** Check viewModel.startDiagnostic() is called in .onAppear

**Issue:** Progress bar stuck at 0%  
**Fix:** Verify currentStep incrementing in processUserResponse()

**Issue:** Blueprint nodes overlapping  
**Fix:** Adjust calculateNodePositions() logic

**Issue:** Suggested chips not appearing  
**Fix:** Check suggestedResponses array populated in askNextQuestion()

---

## 📚 Resources

- **Phase 1 Summary:** `PHASE_1_COMPLETE_SUMMARY.md`
- **Visual Guide:** `PHASE_1_VISUAL_GUIDE.md`
- **Implementation Plan:** `CO_CREATIVE_AI_MENTOR_IMPLEMENTATION_PLAN.md`
- **Copilot Instructions:** `.github/copilot-instructions.md`

---

*Testing Guide Generated: October 6, 2025*  
*LyoApp Co-Creative AI Mentor - Phase 1.8*
