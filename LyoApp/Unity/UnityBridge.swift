import Foundation
import UIKit

/// Runtime-based Unity bridge. Works as a graceful stub when Unity isn't integrated.
final class UnityBridge: NSObject {
    static let shared = UnityBridge()

    private var unityFrameworkInstance: AnyObject?
    private(set) var isUnityLoaded = false

    private override init() { super.init() }

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
            print("✅ Unity runtime initialized (dynamic)")
        } else {
            print("⚠️ Unity runtime not responsive to getInstance selector")
        }
    }

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
}
