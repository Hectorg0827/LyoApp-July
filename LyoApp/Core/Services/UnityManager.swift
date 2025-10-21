//
//  UnityManager.swift
//  LyoApp
//
//  Manages UnityFramework lifecycle and communication with Classroom module
//

import UIKit

class UnityManager: NSObject {
    
    static let shared = UnityManager()
    
    private var unityFramework: NSObject?
    private var unityView: UIView?
    private var isInitialized = false
    
    /// Initialize Unity Framework on app launch
    func initializeUnity() {
        guard !isInitialized else {
            print("[UnityManager] Already initialized")
            return
        }
        
        do {
            try unityFramework = UnityFrameworkLoad()
            
            // Run on background thread
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                if let framework = self?.unityFramework as? NSObject {
                    if framework.responds(to: Selector(("runEmbedded"))) {
                        framework.perform(
                            Selector(("runEmbeddedWithArguments:options:completeHandler:")),
                            with: CommandLine.arguments,
                            with: nil,
                            with: { [weak self] in
                                self?.isInitialized = true
                                print("[UnityManager] Unity initialized successfully")
                                DispatchQueue.main.async {
                                    NotificationCenter.default.post(
                                        name: NSNotification.Name("UnityInitialized"),
                                        object: nil
                                    )
                                }
                            }
                        )
                    }
                }
            }
        } catch {
            print("[UnityManager] Failed to initialize: \(error)")
        }
    }
    
    /// Get Unity view for embedding
    func getUnityView() -> UIView? {
        guard let framework = unityFramework else {
            print("[UnityManager] Framework not initialized")
            return nil
        }
        
        if unityView == nil {
            if let controller = framework.perform(Selector(("appController"))) {
                if let rootVC = controller.takeUnretainedValue() as? NSObject {
                    if let view = rootVC.value(forKey: "rootViewController") as? UIViewController {
                        unityView = view.view
                    }
                }
            }
        }
        
        return unityView
    }
    
    /// Send message to Unity C# code
    func sendMessage(to className: String, methodName: String, message: String) {
        guard isInitialized else {
            print("[UnityManager] Unity not ready")
            return
        }
        
        UnitySendMessage(
            className,
            methodName,
            message
        )
    }
    
    /// Shutdown Unity Framework
    func shutdownUnity() {
        guard isInitialized else { return }
        
        if let framework = unityFramework {
            framework.perform(Selector(("unload")))
        }
        
        isInitialized = false
        unityView = nil
        
        print("[UnityManager] Shutdown complete")
    }
    
    /// Check if Unity is ready
    func isUnityReady() -> Bool {
        return isInitialized
    }
}

// MARK: - Bridging Functions

@discardableResult
func UnityFrameworkLoad() throws -> NSObject {
    let bundlePath = Bundle.main.bundlePath
    let frameworkPath = bundlePath + "/Frameworks/UnityFramework.framework"
    
    guard let bundle = Bundle(path: frameworkPath) else {
        throw NSError(domain: "UnityManager", code: 1)
    }
    
    guard bundle.load() else {
        throw NSError(domain: "UnityManager", code: 2)
    }
    
    guard let frameworkClass = NSClassFromString("UnityFramework") as? NSObject.Type else {
        throw NSError(domain: "UnityManager", code: 3)
    }
    
    return frameworkClass.init()
}

// MARK: - C Bridge (for Unity interop)
// CRITICAL: This declaration is required for sendMessage() to work
@_silgen_name("UnitySendMessage")
func UnitySendMessage(_ className: UnsafePointer<CChar>?, _ methodName: UnsafePointer<CChar>?, _ message: UnsafePointer<CChar>?)
