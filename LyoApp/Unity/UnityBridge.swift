import Foundation
import UIKit

/// Protocol for receiving messages from Unity
protocol UnityMessageListener: AnyObject {
    func onUnityMessage(gameObject: String, methodName: String, message: String)
}

/// Runtime-based Unity bridge with two-way communication support
/// Works as a graceful stub when Unity isn't integrated
final class UnityBridge: NSObject {
    static let shared = UnityBridge()

    private var unityFrameworkInstance: AnyObject?
    private(set) var isUnityLoaded = false
    private var messageListeners: [UnityMessageListener] = []

    private override init() { super.init() }

    // MARK: - Unity Availability & Initialization

    func isAvailable() -> Bool {
        return Bundle.main.path(forResource: "UnityFramework", ofType: "framework") != nil
    }

    func initializeUnity() {
        guard !isUnityLoaded else { return }
        guard let bundlePath = Bundle.main.path(forResource: "UnityFramework", ofType: "framework") else {
            print("⚠️ UnityFramework.framework not found - skipping Unity initialization")
            return
        }

        guard let bundle = Bundle(path: bundlePath) else {
            print("⚠️ Unable to create bundle for UnityFramework")
            return
        }

        if !bundle.isLoaded { bundle.load() }

        guard let principal = bundle.principalClass as? NSObject.Type else {
            print("⚠️ Unity principal class not available")
            return
        }

        // Attempt to call getInstance dynamically
        let selector = NSSelectorFromString("getInstance")
        if principal.responds(to: selector) {
            let instance = principal.perform(selector)?.takeUnretainedValue()
            unityFrameworkInstance = instance
            isUnityLoaded = true
            
            // Register as listener for Unity messages
            registerAsUnityListener()
            
            print("✅ Unity runtime initialized (dynamic) with two-way communication")
        } else {
            print("⚠️ Unity runtime not responsive to getInstance selector")
        }
    }

    // MARK: - Unity View Management

    func getUnityView() -> UIView? {
        guard let instance = unityFrameworkInstance else { return nil }
        let appControllerSel = NSSelectorFromString("appController")
        guard let appController = instance.perform(appControllerSel)?.takeUnretainedValue() else { return nil }
        let rootViewSel = NSSelectorFromString("rootView")
        let view = appController.perform(rootViewSel)?.takeUnretainedValue()
        return view as? UIView
    }

    func showUnity() {
        guard isUnityLoaded else { return }
        let sel = NSSelectorFromString("showUnity")
        _ = unityFrameworkInstance?.perform(sel)
    }

    func pauseUnity() {
        guard isUnityLoaded else { return }
        let sel = NSSelectorFromString("pause:")
        _ = unityFrameworkInstance?.perform(sel, with: true)
    }

    func resumeUnity() {
        guard isUnityLoaded else { return }
        let sel = NSSelectorFromString("pause:")
        _ = unityFrameworkInstance?.perform(sel, with: false)
    }
    
    // MARK: - Two-Way Communication
    
    /// Sends a message from Swift to Unity
    /// - Parameters:
    ///   - objectName: The name of the GameObject in Unity to receive the message
    ///   - methodName: The name of the method to call on the GameObject
    ///   - message: The message string to send
    func sendMessageToUnity(objectName: String, methodName: String, message: String) {
        guard isUnityLoaded, let instance = unityFrameworkInstance else {
            print("⚠️ Unity not loaded, cannot send message")
            return
        }
        
        // Unity's SendMessage API signature: sendMessageToGOWithName:functionName:message:
        let selector = NSSelectorFromString("sendMessageToGOWithName:functionName:message:")
        
        if instance.responds(to: selector) {
            // Use NSInvocation for methods with more than 2 arguments
            let method = instance.method(for: selector)
            typealias SendMessageFunction = @convention(c) (AnyObject, Selector, NSString, NSString, NSString) -> Void
            let sendMessage = unsafeBitCast(method, to: SendMessageFunction.self)
            sendMessage(instance, selector, objectName as NSString, methodName as NSString, message as NSString)
            print("📤 Sent message to Unity: \(objectName).\(methodName)(\(message))")
        } else {
            print("⚠️ Unity instance doesn't respond to sendMessageToGOWithName")
        }
    }
    
    /// Registers this bridge as a listener for Unity framework events
    private func registerAsUnityListener() {
        guard let instance = unityFrameworkInstance else { return }
        
        // Unity uses a delegate pattern - set self as the framework listener
        let selector = NSSelectorFromString("registerFrameworkListener:")
        if instance.responds(to: selector) {
            _ = instance.perform(selector, with: self)
            print("✅ Registered as Unity framework listener")
        }
    }
    
    // MARK: - Message Listener Management
    
    /// Adds a listener to receive messages from Unity
    func addMessageListener(_ listener: UnityMessageListener) {
        messageListeners.append(listener)
        print("✅ Added Unity message listener")
    }
    
    /// Removes a message listener
    func removeMessageListener(_ listener: UnityMessageListener) {
        messageListeners.removeAll { $0 === listener }
        print("✅ Removed Unity message listener")
    }
    
    /// Internal method to handle messages from Unity
    /// This will be called by Unity via Objective-C runtime
    @objc func onMessage(_ message: String) {
        print("📥 Received message from Unity: \(message)")
        
        // Parse the message (expected format: "GameObjectName:MethodName:Message")
        let components = message.components(separatedBy: ":")
        guard components.count >= 3 else {
            print("⚠️ Invalid message format from Unity")
            return
        }
        
        let gameObject = components[0]
        let methodName = components[1]
        let payload = components[2...].joined(separator: ":")
        
        // Notify all listeners
        for listener in messageListeners {
            listener.onUnityMessage(gameObject: gameObject, methodName: methodName, message: payload)
        }
    }
    
    // MARK: - Convenience Methods for Course Loading
    
    /// Loads a specific course in the Unity 3D classroom
    /// - Parameter courseId: The UUID of the course to load
    func loadCourse(courseId: UUID) {
        sendMessageToUnity(
            objectName: "CourseLoader",
            methodName: "LoadCourse",
            message: courseId.uuidString
        )
    }
    
    /// Loads a specific lesson in the Unity 3D classroom
    /// - Parameters:
    ///   - courseId: The UUID of the course
    ///   - lessonId: The UUID of the lesson
    func loadLesson(courseId: UUID, lessonId: UUID) {
        let payload = "\(courseId.uuidString)|\(lessonId.uuidString)"
        sendMessageToUnity(
            objectName: "LessonLoader",
            methodName: "LoadLesson",
            message: payload
        )
    }
}
