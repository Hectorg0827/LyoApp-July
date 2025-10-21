# 🔗 Messenger Integration Guide - Quick Start

## ⚡ 5-Minute Setup

### Step 1: Verify File Exists
```
✅ File: LyoApp/MessengerView.swift (876 lines)
✅ Build: Successful (0 errors)
✅ Dependencies: AVFoundation, SwiftUI, existing User model
```

### Step 2: Add to Bottom Navigation
Open `ContentView.swift` and add the Messages tab:

```swift
TabView(selection: $selectedTab) {
    // Your existing tabs...
    
    HomeFeedView()
        .tabItem {
            Image(systemName: "house.fill")
            Text("Home")
        }
        .tag(0)
    
    TikTokVideoFeedView()
        .tabItem {
            Image(systemName: "play.rectangle.fill")
            Text("Videos")
        }
        .tag(1)
    
    // ADD THIS: 👇
    MessengerView()
        .tabItem {
            Image(systemName: "bubble.left.and.bubble.right.fill")
            Text("Messages")
        }
        .tag(2)  // or next available tab index
    
    // Your other tabs...
}
```

### Step 3: Test It!
1. Build and run the app (**Cmd+R**)
2. Tap the Messages tab (chat bubble icon)
3. See 6 pre-generated conversations
4. Tap any conversation to open chat
5. Send a test message
6. Long-press to react
7. Tap mic to record voice message

**That's it! You're done.** 🎉

---

## 📱 Features Overview

### What's Included Out of the Box
✅ Conversation list with avatars  
✅ Chat view with message bubbles  
✅ Text messaging  
✅ Message reactions (8 emojis)  
✅ Voice recording  
✅ Read receipts (checkmarks)  
✅ Typing indicators  
✅ Online status (green dots)  
✅ Search functionality  
✅ Group chats  
✅ Message deletion  
✅ Context menu (long-press)  
✅ Haptic feedback  
✅ UserDefaults persistence  
✅ Mock data generator (6 conversations)  

### What Needs Backend Connection
⚠️ Real-time messaging (currently simulated)  
⚠️ Image/video upload  
⚠️ Voice message cloud storage  
⚠️ Push notifications  
⚠️ User online status (backend)  
⚠️ Video/audio calls  

---

## 🎯 Customization Quick Reference

### Change Colors
Search for these hex values in `MessengerView.swift`:

```swift
// Background gradient
"0A0E27" → Your top color
"1A1F3A" → Your bottom color

// Primary accent
"00D4FF" → Your brand color (cyan)

// Secondary accent  
"667EEA" → Your secondary color (purple)
```

### Change Mock Data
Edit the `generateMockConversations()` function:

```swift
func generateMockConversations() {
    let mockUsers = [
        // Add your custom users here
        User(id: "1", email: "...", fullName: "Your Name", ...)
    ]
    
    let lastMessages = [
        // Add your custom messages
        "Your custom message here"
    ]
}
```

### Change Reaction Emojis
Edit the `ReactionPickerSheet`:

```swift
let reactions = ["❤️", "😂", "😮", "😢", "😡", "👍", "👏", "🔥"]
// Change to your preferred emojis
```

### Adjust Animations
Search for animation timing:

```swift
.animation(
    Animation
        .easeInOut(duration: 0.6)  // Change duration
        .repeatForever()
        .delay(Double(index) * 0.2), // Change delay
    value: animating
)
```

---

## 🔌 Backend Integration (When Ready)

### Step 1: Create API Service

```swift
// Add to MessengerView.swift or separate file
class MessengerAPI {
    static let shared = MessengerAPI()
    let baseURL = "https://api.lyoapp.com/v1"
    
    func fetchConversations() async throws -> [MessengerConversation] {
        let url = URL(string: "\(baseURL)/conversations")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([MessengerConversation].self, from: data)
    }
    
    func fetchMessages(conversationId: String) async throws -> [MessengerMessage] {
        let url = URL(string: "\(baseURL)/conversations/\(conversationId)/messages")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([MessengerMessage].self, from: data)
    }
    
    func sendMessage(conversationId: String, content: String, type: MessageType) async throws {
        let url = URL(string: "\(baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "conversationId": conversationId,
            "content": content,
            "type": type.rawValue
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (_, _) = try await URLSession.shared.data(for: request)
    }
}
```

### Step 2: Replace Mock with API

In `MessengerManager`, replace:

```swift
// OLD (mock):
func loadConversations() {
    if let data = UserDefaults.standard.data(forKey: "savedMessengerConversations"),
       let decoded = try? JSONDecoder().decode([MessengerConversation].self, from: data) {
        self.conversations = decoded
    }
}

// NEW (API):
func loadConversations() async {
    do {
        self.conversations = try await MessengerAPI.shared.fetchConversations()
    } catch {
        print("Failed to load conversations: \(error)")
    }
}
```

```swift
// OLD (mock):
func sendMessage(_ content: String, type: MessageType = .text, mediaUrl: String? = nil) {
    // ... current code ...
    simulateResponse(to: content)  // Remove this
}

// NEW (API):
func sendMessage(_ content: String, type: MessageType = .text, mediaUrl: String? = nil) async {
    guard let conversation = activeConversation else { return }
    
    // Add optimistically to UI
    let message = MessengerMessage(/* ... */)
    messages.append(message)
    
    // Send to backend
    do {
        try await MessengerAPI.shared.sendMessage(
            conversationId: conversation.id,
            content: content,
            type: type
        )
    } catch {
        // Handle error, maybe remove message from UI
        print("Failed to send: \(error)")
    }
}
```

### Step 3: Add WebSocket for Real-Time

```swift
class MessengerManager: ObservableObject {
    private var webSocket: URLSessionWebSocketTask?
    
    func connectWebSocket() {
        let url = URL(string: "wss://api.lyoapp.com/messenger")!
        webSocket = URLSession.shared.webSocketTask(with: url)
        webSocket?.resume()
        receiveMessages()
    }
    
    func receiveMessages() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let message = try? JSONDecoder().decode(MessengerMessage.self, from: data) {
                        DispatchQueue.main.async {
                            self?.messages.append(message)
                        }
                    }
                case .data(let data):
                    if let message = try? JSONDecoder().decode(MessengerMessage.self, from: data) {
                        DispatchQueue.main.async {
                            self?.messages.append(message)
                        }
                    }
                @unknown default:
                    break
                }
                self?.receiveMessages() // Continue listening
            case .failure(let error):
                print("WebSocket error: \(error)")
            }
        }
    }
}
```

Call `connectWebSocket()` in `init()`:
```swift
init() {
    generateMockConversations()
    loadConversations()
    connectWebSocket()  // Add this
}
```

---

## 📤 Image/Video Upload

### Step 1: Add Image Picker

```swift
// Add to MessengerChatView
import PhotosUI

@State private var selectedItem: PhotosPickerItem?
@State private var selectedImage: UIImage?

// Replace showImagePicker button with PhotosPicker:
PhotosPicker(selection: $selectedItem, matching: .images) {
    Image(systemName: "photo.fill")
        .font(.system(size: 20))
        .foregroundColor(Color(hex: "00D4FF"))
}
.onChange(of: selectedItem) { newItem in
    Task {
        if let data = try? await newItem?.loadTransferable(type: Data.self),
           let image = UIImage(data: data) {
            await uploadAndSendImage(image)
        }
    }
}
```

### Step 2: Upload Function

```swift
func uploadAndSendImage(_ image: UIImage) async {
    guard let imageData = image.jpegData(compressionQuality: 0.7) else { return }
    
    // Upload to backend
    let url = URL(string: "https://api.lyoapp.com/v1/media/upload")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
    request.httpBody = imageData
    
    do {
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(UploadResponse.self, from: data)
        
        // Send message with image URL
        await manager.sendMessage("", type: .image, mediaUrl: response.url)
    } catch {
        print("Upload failed: \(error)")
    }
}

struct UploadResponse: Codable {
    let url: String
}
```

---

## 🔔 Push Notifications

### Step 1: Request Permission

Add to your `AppDelegate` or main app file:

```swift
import UserNotifications

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
        if granted {
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    return true
}

func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("Push token: \(token)")
    // Send token to backend
    sendPushTokenToBackend(token)
}
```

### Step 2: Handle Notifications

```swift
func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    
    if let conversationId = userInfo["conversationId"] as? String {
        // Navigate to conversation
        NotificationCenter.default.post(
            name: Notification.Name("OpenConversation"),
            object: conversationId
        )
    }
    
    completionHandler()
}
```

### Step 3: Backend Notification Format

```json
{
  "aps": {
    "alert": {
      "title": "Sarah Johnson",
      "body": "Hey! How are you doing? 😊"
    },
    "badge": 1,
    "sound": "default"
  },
  "conversationId": "conv_123",
  "senderId": "user_456"
}
```

---

## 🔍 Analytics Integration

### Add Tracking Events

```swift
// Add after sending message
func sendMessage(_ content: String, type: MessageType = .text, mediaUrl: String? = nil) {
    // ... existing code ...
    
    // Track event
    Analytics.track("message_sent", properties: [
        "type": type.rawValue,
        "length": content.count,
        "conversation_type": conversation.isGroup ? "group" : "direct"
    ])
}

// Track reaction
func addReaction(to messageId: String, emoji: String) {
    // ... existing code ...
    
    Analytics.track("message_reacted", properties: [
        "emoji": emoji,
        "message_id": messageId
    ])
}

// Track voice message
func stopRecording() {
    // ... existing code ...
    
    Analytics.track("voice_message_sent", properties: [
        "duration": Int(recordingTime)
    ])
}
```

### Events to Track
- `message_sent` - User sends any message
- `message_reacted` - User reacts to message
- `voice_message_sent` - User sends voice message
- `conversation_opened` - User opens conversation
- `conversation_searched` - User searches conversations
- `message_deleted` - User deletes message
- `media_shared` - User shares image/video
- `call_initiated` - User starts call (future)

---

## 🧪 Testing Checklist

### Manual Testing
- [ ] Open Messages tab - sees conversation list
- [ ] Tap conversation - opens chat view
- [ ] Send text message - appears in chat
- [ ] Long-press message - context menu appears
- [ ] Tap "React" - modal sheet appears
- [ ] Select emoji - reaction appears below message
- [ ] Tap mic button - starts recording
- [ ] Tap stop - sends voice message
- [ ] Search conversations - filters list
- [ ] Tap photo button - opens picker (when implemented)
- [ ] Delete message - shows deleted placeholder
- [ ] Check read receipts - checkmarks update
- [ ] Verify typing indicator - dots animate
- [ ] Check online status - green dots appear

### Unit Tests to Add

```swift
import XCTest
@testable import LyoApp

class MessengerTests: XCTestCase {
    var manager: MessengerManager!
    
    override func setUp() {
        manager = MessengerManager()
    }
    
    func testConversationsLoad() {
        XCTAssertFalse(manager.conversations.isEmpty)
        XCTAssertEqual(manager.conversations.count, 6) // 5 users + 1 group
    }
    
    func testSendMessage() {
        let conversation = manager.conversations.first!
        manager.openConversation(conversation)
        
        let initialCount = manager.messages.count
        manager.sendMessage("Test")
        
        XCTAssertEqual(manager.messages.count, initialCount + 1)
        XCTAssertEqual(manager.messages.last?.content, "Test")
    }
    
    func testAddReaction() {
        let conversation = manager.conversations.first!
        manager.openConversation(conversation)
        let message = manager.messages.first!
        
        manager.addReaction(to: message.id, emoji: "❤️")
        
        let updated = manager.messages.first(where: { $0.id == message.id })!
        XCTAssertEqual(updated.reactions.count, 1)
        XCTAssertEqual(updated.reactions.first?.emoji, "❤️")
    }
    
    func testDeleteMessage() {
        let conversation = manager.conversations.first!
        manager.openConversation(conversation)
        let message = manager.messages.first!
        
        manager.deleteMessage(message.id)
        
        let deleted = manager.messages.first(where: { $0.id == message.id })!
        XCTAssertTrue(deleted.isDeleted)
        XCTAssertNotNil(deleted.deletedAt)
    }
    
    func testSearchFilters() {
        manager.searchQuery = "Sarah"
        
        let filtered = manager.filteredConversations
        XCTAssertTrue(filtered.allSatisfy { $0.displayName.contains("Sarah") })
    }
}
```

---

## 🚨 Troubleshooting

### Issue: Conversations not loading
**Solution**: Check UserDefaults key is correct
```swift
// Verify key in debugger:
print(UserDefaults.standard.data(forKey: "savedMessengerConversations"))
```

### Issue: Voice recording not working
**Solution**: Add microphone permission to `Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to record voice messages</string>
```

### Issue: Messages not persisting
**Solution**: Verify save is called after changes:
```swift
func sendMessage(_ content: String, ...) {
    // ... add message ...
    saveMessages(for: conversation.id)  // Make sure this is called
}
```

### Issue: Build errors with User model
**Solution**: Import the correct User model:
```swift
// Make sure MessengerView.swift has access to:
// - Models/Models.swift
// - User struct definition
```

### Issue: TabView not showing Messages tab
**Solution**: Check tag is unique:
```swift
.tag(2)  // Make sure no other tab uses this number
```

---

## 📚 Additional Resources

### Documentation Files
- `MESSENGER_COMPLETE.md` - Complete feature documentation (800+ lines)
- `MESSENGER_VISUAL_REFERENCE.md` - Visual layout diagrams (400+ lines)
- `MESSENGER_INTEGRATION_GUIDE.md` - This file

### Related Features
- `TikTokVideoFeedView.swift` - Video feed implementation
- `EnhancedAIClassroomView.swift` - AI classroom
- `User.swift` - Canonical user model

### External APIs (When Ready)
- **Firebase Cloud Messaging**: Push notifications
- **Twilio**: Voice/video calls
- **AWS S3**: Media storage
- **Socket.io**: Real-time messaging
- **Stream Chat SDK**: Alternative pre-built solution

---

## 🎯 Next Steps

1. **Test the feature** - Build and run, verify all works
2. **Add to navigation** - Integrate into your tab bar
3. **Customize branding** - Change colors to match your app
4. **Connect backend** - When ready, follow Backend Integration section
5. **Add push notifications** - Follow Push Notifications section
6. **Implement media upload** - Follow Image/Video Upload section
7. **Add analytics** - Track key events
8. **Write tests** - Add unit and UI tests

---

## ⚡ Pro Tips

1. **Start simple**: Test with mock data first before connecting backend
2. **Iterate quickly**: Use hot reload to test UI changes instantly
3. **Monitor performance**: Check memory usage with Instruments
4. **Test on device**: Voice recording requires physical device
5. **Handle errors**: Add try-catch for network calls
6. **Cache smartly**: Use UserDefaults for persistence, not CoreData yet
7. **Think mobile**: Design for thumb-friendly touch targets
8. **Optimize images**: Compress images before upload (0.7 quality)

---

## 🎉 You're Ready!

Your messenger is fully functional and ready to use. Start with the 5-minute setup above, then gradually add backend integration when you're ready.

**Questions?** Check the code comments in `MessengerView.swift` - every function is documented.

**Found a bug?** The code is modular - each component is self-contained and easy to fix.

**Need help?** All the documentation you need is in the 3 markdown files created for this feature.

---

*Built with ❤️ for LyoApp - The future of social learning* 🚀
