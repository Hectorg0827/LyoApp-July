# 🎯 Unity Integration - Complete Implementation Plan

## 🚨 CRITICAL FIXES (Do First)

### **Phase 1: Core Unity Bridge** ⚡️
**Status:** BLOCKING - Must complete before anything else

#### 1.1 Uncomment & Fix UnitySendMessage Declaration
**File:** `LyoApp/Core/Services/UnityManager.swift`
**Current Issue:** Lines 133-134 are commented out
```swift
// CURRENT (BROKEN):
// @_silgen_name("UnitySendMessage")
// func UnitySendMessage(_ className: UnsafePointer<CChar>?, _ methodName: UnsafePointer<CChar>?, _ message: UnsafePointer<CChar>?)

// REQUIRED FIX:
@_silgen_name("UnitySendMessage")
func UnitySendMessage(
    _ className: UnsafePointer<CChar>?,
    _ methodName: UnsafePointer<CChar>?,
    _ message: UnsafePointer<CChar>?
)
```
**Impact:** Without this, `sendMessage()` will fail at runtime

#### 1.2 Create Unity Container View
**File:** `LyoApp/Views/UnityClassroomContainerView.swift` (NEW FILE)
```swift
import SwiftUI
import UIKit

struct UnityClassroomContainerView: UIViewRepresentable {
    let resource: LearningResource
    @Binding var isPresented: Bool
    
    func makeUIView(context: Context) -> UIView {
        let unityView = UnityManager.shared.getUnityView()
        
        // Send initial course data to Unity
        if let jsonData = resource.toUnityJSON() {
            UnityManager.shared.sendMessage(
                to: "ClassroomController",
                methodName: "LoadCourse",
                message: jsonData
            )
        }
        
        return unityView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Handle updates if needed
    }
}
```

#### 1.3 Integrate Unity View into App Flow
**File:** `LyoApp/LearningHub/Views/LearningHubLandingView.swift`
**Add:**
```swift
@StateObject private var learningDataManager = LearningDataManager.shared

var body: some View {
    ZStack {
        // Existing content...
        
        // Unity Classroom Overlay
        if learningDataManager.showDynamicClassroom,
           let resource = learningDataManager.selectedResource {
            UnityClassroomContainerView(
                resource: resource,
                isPresented: $learningDataManager.showDynamicClassroom
            )
            .edgesIgnoringSafeArea(.all)
            .transition(.move(edge: .bottom))
        }
    }
}
```

---

## 🔧 STRUCTURAL IMPROVEMENTS (Do Second)

### **Phase 2: Model Standardization**

#### 2.1 Unify ChatMessage Types
**Problem:** Multiple `ChatMessage` definitions causing ambiguity

**Solution:**
**File:** `LyoApp/Models/ChatMessage.swift` (NEW FILE)
```swift
import Foundation

/// Canonical chat message model used across the app
/// Replaces all duplicate ChatMessage structs
typealias ChatMessage = AIMessage

/// Standard chat message for AI conversations
struct AIMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isFromUser: Bool
    let timestamp: Date
    let messageType: MessageType
    let interactionId: Int?
    
    enum MessageType: String, Codable {
        case text, code, explanation, quiz, resource
    }
    
    init(
        id: UUID = UUID(),
        content: String,
        isFromUser: Bool,
        timestamp: Date = Date(),
        messageType: MessageType = .text,
        interactionId: Int? = nil
    ) {
        self.id = id
        self.content = content
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.messageType = messageType
        self.interactionId = interactionId
    }
}

/// Extension for common chat operations
extension AIMessage {
    var date: Date { timestamp }
    var isUser: Bool { isFromUser }
}
```

**File:** `LyoApp/Services/AIChatService.swift`
**Remove local `ChatMessage` struct (lines 212+)**
**Change:**
```swift
// DELETE:
struct ChatMessage: Identifiable { ... }

// USE CANONICAL TYPE INSTEAD:
// Already defined - just use ChatMessage or AIMessage
```

**File:** `LyoApp/LearningHub/ViewModels/LearningChatViewModel.swift`
**Update definition:**
```swift
// BEFORE:
@Published var messages: [ChatMessage] = []

// AFTER (same, but remove any local struct definition):
@Published var messages: [ChatMessage] = [] // Uses canonical AIMessage
```

#### 2.2 Extend GeneratedCourse Model
**File:** `LyoApp/Services/AICourseGenerationService.swift`
**Add missing properties:**
```swift
struct GeneratedCourse: Codable {
    let id: UUID
    let title: String
    let description: String
    let topic: String
    let level: LearningLevel
    let lessons: [LessonOutline]
    let totalDuration: Int
    let modules: [CourseModule]
    
    // NEW: Unity integration fields
    let unitySceneName: String?
    let totalXP: Int?
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        topic: String,
        level: LearningLevel,
        lessons: [LessonOutline],
        totalDuration: Int,
        modules: [CourseModule],
        unitySceneName: String? = nil,
        totalXP: Int? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.topic = topic
        self.level = level
        self.lessons = lessons
        self.totalDuration = totalDuration
        self.modules = modules
        self.unitySceneName = unitySceneName ?? inferUnityScene(from: topic)
        self.totalXP = totalXP ?? calculateTotalXP(lessons: lessons)
    }
    
    // Infer Unity scene from topic
    private static func inferUnityScene(from topic: String) -> String {
        let normalized = topic.lowercased()
        if normalized.contains("maya") || normalized.contains("civilization") {
            return "MayaCivilization"
        } else if normalized.contains("mars") || normalized.contains("space") {
            return "MarsExploration"
        } else if normalized.contains("chemistry") || normalized.contains("lab") {
            return "ChemistryLab"
        } else {
            return "DefaultClassroom"
        }
    }
    
    // Calculate total XP from lessons
    private static func calculateTotalXP(lessons: [LessonOutline]) -> Int {
        return lessons.reduce(0) { total, lesson in
            total + (lesson.estimatedDuration * 10) // 10 XP per minute
        }
    }
}
```

---

## 🎨 UI/UX ENHANCEMENTS (Do Third)

### **Phase 3: Complete UI Flow**

#### 3.1 Add Course Preview Before Launch
**File:** `LyoApp/LearningHub/Views/CoursePreviewSheet.swift` (NEW FILE)
```swift
import SwiftUI

struct CoursePreviewSheet: View {
    let course: CourseJourney
    let onLaunch: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("🎓 Ready to Learn")
                .font(.system(size: 32, weight: .bold))
            
            Text(course.title)
                .font(.title2)
                .multilineTextAlignment(.center)
            
            // Course details
            VStack(alignment: .leading, spacing: 12) {
                DetailRow(
                    icon: "clock.fill",
                    label: "Duration",
                    value: course.durationString
                )
                DetailRow(
                    icon: "star.fill",
                    label: "XP Reward",
                    value: "\(course.xpReward) XP"
                )
                DetailRow(
                    icon: "cube.fill",
                    label: "Environment",
                    value: course.environmentName
                )
                DetailRow(
                    icon: "list.bullet",
                    label: "Modules",
                    value: "\(course.modules.count) lessons"
                )
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
            
            // Modules list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(course.modules.enumerated()), id: \.offset) { index, module in
                        HStack {
                            Text("\(index + 1).")
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            Text(module.title)
                            Spacer()
                            Text("\(module.estimatedMinutes) min")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .frame(maxHeight: 200)
            
            // Actions
            HStack(spacing: 16) {
                Button("Cancel") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.secondary.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(12)
                
                Button("Launch Classroom") {
                    onLaunch()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
        .padding()
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
```

#### 3.2 Add Loading States
**File:** `LyoApp/LearningHub/Views/UnityLoadingView.swift` (NEW FILE)
```swift
import SwiftUI

struct UnityLoadingView: View {
    let courseName: String
    @State private var progress: Double = 0.0
    @State private var loadingText: String = "Initializing..."
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(width: 200)
            
            Text(loadingText)
                .font(.headline)
            
            Text("Preparing \(courseName)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .onAppear {
            simulateLoading()
        }
    }
    
    private func simulateLoading() {
        let stages = [
            (0.2, "Loading Unity engine..."),
            (0.4, "Preparing 3D environment..."),
            (0.6, "Loading course content..."),
            (0.8, "Initializing AI tutor..."),
            (1.0, "Ready!")
        ]
        
        for (progress, text) in stages {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(stages.firstIndex(where: { $0.0 == progress })!)) {
                withAnimation {
                    self.progress = progress
                    self.loadingText = text
                }
            }
        }
    }
}
```

---

## 🌐 BACKEND INTEGRATION (Do Fourth)

### **Phase 4: Unity-Backend Communication**

#### 4.1 Add Unity Scene Metadata to Backend
**File:** `LyoApp/Services/ClassroomAPIService.swift`
**Update `generateCourse` response mapping:**
```swift
func generateCourse(
    topic: String,
    level: LearningLevel,
    outcomes: [String],
    pedagogy: Pedagogy
) async throws -> ClassroomCourse {
    // Existing implementation...
    
    // NEW: Determine Unity scene
    let unityScene = determineUnityScene(for: topic)
    
    let request = CourseGenerationRequest(
        topic: topic,
        level: level.rawValue,
        outcomes: outcomes,
        pedagogy: pedagogy,
        unitySceneName: unityScene // Add to request
    )
    
    // Rest of implementation...
}

private func determineUnityScene(for topic: String) -> String {
    let normalized = topic.lowercased()
    
    // Map topics to Unity scenes
    if normalized.contains("history") || normalized.contains("civilization") {
        return "HistoricalEnvironment"
    } else if normalized.contains("science") || normalized.contains("chemistry") {
        return "ScienceLab"
    } else if normalized.contains("space") || normalized.contains("astronomy") {
        return "SpaceExploration"
    } else if normalized.contains("math") {
        return "MathematicsStudio"
    } else {
        return "DefaultClassroom"
    }
}
```

#### 4.2 Add JSON Serialization for Unity
**File:** `LyoApp/LearningHub/Models/LearningResource.swift`
**Add extension:**
```swift
extension LearningResource {
    func toUnityJSON() -> String? {
        let dict: [String: Any] = [
            "courseId": id,
            "title": title,
            "description": description,
            "difficulty": difficultyLevel?.rawValue ?? "beginner",
            "estimatedDuration": estimatedDuration ?? "30 min",
            "category": category ?? "General",
            "tags": tags,
            "environment": inferEnvironment(),
            "modules": [] // Add actual modules when available
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dict),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        
        return jsonString
    }
    
    private func inferEnvironment() -> String {
        guard let cat = category?.lowercased() else { return "default" }
        
        if cat.contains("history") {
            return "historical"
        } else if cat.contains("science") {
            return "laboratory"
        } else if cat.contains("space") {
            return "cosmos"
        } else {
            return "modern_classroom"
        }
    }
}
```

---

## 🎮 UNITY C# SCRIPTS (Do Fifth)

### **Phase 5: Unity-Side Implementation**

#### 5.1 Create Classroom Controller
**File:** `Unity/Assets/Scripts/ClassroomController.cs` (Unity C# - **CREATE IN UNITY PROJECT**)
```csharp
using UnityEngine;
using System;

public class ClassroomController : MonoBehaviour
{
    [Header("Environment Prefabs")]
    public GameObject defaultClassroom;
    public GameObject mayaCivilization;
    public GameObject chemistryLab;
    public GameObject marsExploration;
    
    [Header("Current State")]
    private CourseData currentCourse;
    private string currentEnvironment;
    
    // Called from Swift via UnitySendMessage
    public void LoadCourse(string jsonData)
    {
        Debug.Log($"[Unity] Received course data: {jsonData}");
        
        try
        {
            currentCourse = JsonUtility.FromJson<CourseData>(jsonData);
            LoadEnvironment(currentCourse.environment);
            ConfigureCourseElements();
        }
        catch (Exception e)
        {
            Debug.LogError($"[Unity] Failed to load course: {e.Message}");
        }
    }
    
    private void LoadEnvironment(string environmentName)
    {
        Debug.Log($"[Unity] Loading environment: {environmentName}");
        
        // Deactivate all environments
        defaultClassroom?.SetActive(false);
        mayaCivilization?.SetActive(false);
        chemistryLab?.SetActive(false);
        marsExploration?.SetActive(false);
        
        // Activate requested environment
        switch (environmentName.ToLower())
        {
            case "historical":
            case "mayacivilization":
                mayaCivilization?.SetActive(true);
                currentEnvironment = "Maya";
                break;
                
            case "laboratory":
            case "chemistrylab":
                chemistryLab?.SetActive(true);
                currentEnvironment = "Lab";
                break;
                
            case "cosmos":
            case "marsexploration":
                marsExploration?.SetActive(true);
                currentEnvironment = "Mars";
                break;
                
            default:
                defaultClassroom?.SetActive(true);
                currentEnvironment = "Default";
                break;
        }
        
        Debug.Log($"[Unity] Environment loaded: {currentEnvironment}");
    }
    
    private void ConfigureCourseElements()
    {
        // Configure course-specific elements
        Debug.Log($"[Unity] Configuring course: {currentCourse.title}");
        // Add lesson markers, interactive elements, etc.
    }
    
    // Send progress back to Swift
    public void ReportProgress(float percentage)
    {
        // TODO: Implement callback to Swift
        Debug.Log($"[Unity] Progress: {percentage}%");
    }
}

[Serializable]
public class CourseData
{
    public string courseId;
    public string title;
    public string description;
    public string difficulty;
    public string estimatedDuration;
    public string category;
    public string environment;
    public string[] tags;
}
```

---

## 📱 TESTING & VALIDATION (Do Last)

### **Phase 6: Integration Testing**

#### 6.1 Create Test Harness
**File:** `LyoApp/Debug/UnityIntegrationTest.swift` (NEW FILE)
```swift
import SwiftUI

#if DEBUG
struct UnityIntegrationTestView: View {
    @State private var testResults: [String] = []
    
    var body: some View {
        VStack {
            Text("Unity Integration Tests")
                .font(.title)
            
            Button("Test Unity Initialization") {
                testUnityInit()
            }
            .padding()
            
            Button("Test Message Sending") {
                testMessageSending()
            }
            .padding()
            
            Button("Test Course Launch") {
                testCourseLaunch()
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(testResults, id: \.self) { result in
                        Text(result)
                            .font(.caption)
                            .padding(4)
                    }
                }
            }
        }
    }
    
    private func testUnityInit() {
        testResults.append("Testing Unity initialization...")
        UnityManager.shared.initializeUnity()
        testResults.append("✅ Unity init called")
    }
    
    private func testMessageSending() {
        testResults.append("Testing message sending...")
        UnityManager.shared.sendMessage(
            to: "ClassroomController",
            methodName: "LoadCourse",
            message: "{\"title\":\"Test Course\"}"
        )
        testResults.append("✅ Message sent")
    }
    
    private func testCourseLaunch() {
        testResults.append("Testing course launch flow...")
        Task {
            let mockResource = LearningResource.sampleResources().first!
            await LearningDataManager.shared.launchCourse(mockResource)
            await MainActor.run {
                testResults.append("✅ Course launched: \(LearningDataManager.shared.showDynamicClassroom)")
            }
        }
    }
}
#endif
```

---

## 📊 SUCCESS METRICS

Track these to ensure quality:

- [ ] Unity view displays successfully
- [ ] Messages sent to Unity without errors
- [ ] Course data properly serialized to JSON
- [ ] Environment switching works in Unity
- [ ] No ChatMessage type conflicts
- [ ] Build succeeds with no errors
- [ ] All analytics events fire correctly

---

## ⏱️ ESTIMATED TIMELINE

- **Phase 1** (Critical): 2-3 hours
- **Phase 2** (Models): 1-2 hours
- **Phase 3** (UI): 3-4 hours
- **Phase 4** (Backend): 2-3 hours
- **Phase 5** (Unity C#): 4-6 hours
- **Phase 6** (Testing): 2-3 hours

**Total:** ~15-20 hours for complete implementation

---

## 🚀 QUICK START CHECKLIST

1. ✅ Uncomment `UnitySendMessage` in UnityManager.swift
2. ✅ Create `UnityClassroomContainerView.swift`
3. ✅ Add overlay to `LearningHubLandingView.swift`
4. ✅ Test basic Unity view display
5. ✅ Create ChatMessage.swift canonical model
6. ✅ Extend GeneratedCourse with Unity fields
7. ✅ Add Unity C# ClassroomController
8. ✅ Test end-to-end flow

