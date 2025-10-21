//
//  AppDelegate+Unity.swift
//  LyoApp
//
//  Extension for Unity lifecycle management
//

import UIKit

extension AppDelegate {
    
    func initializeUnityFramework() {
        UnityManager.shared.initializeUnity()
        
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("UnityInitialized"),
            object: nil,
            queue: .main
        ) { _ in
            print("[AppDelegate] Unity framework ready")
        }
    }
    
    func shutdownUnityFramework() {
        UnityManager.shared.shutdownUnity()
    }
}
