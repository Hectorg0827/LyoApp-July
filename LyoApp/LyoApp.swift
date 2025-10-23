//
//  LyoApp.swift
//  LyoApp
//
//  Created by Hector Garcia on 7/22/24.
//

import SwiftUI

@main
struct LyoApp: App {
    // Create state objects lazily to prevent initialization hanging
    @StateObject private var safeAppManager = SafeAppManager()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            SafeAppView()
                .environmentObject(safeAppManager)
                .onAppear {
                    setupApp()
                }
                .onChange(of: scenePhase) { newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    private func setupApp() {
        print("🚀 LyoApp started safely")
        safeAppManager.initializeServices()
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            print("📱 App entered background")
            BackgroundScheduler.shared.handleAppDidEnterBackground()
        case .active:
            print("📱 App became active")
            BackgroundScheduler.shared.handleAppDidBecomeActive()
        case .inactive:
            print("📱 App became inactive")
        @unknown default:
            break
        }
    }
}

// MARK: - Safe App Manager
@MainActor
class SafeAppManager: ObservableObject {
    @Published var appState: AppState?
    @Published var authManager: AuthenticationManager?
    @Published var networkManager: SimpleNetworkManager?
    @Published var voiceActivationService: VoiceActivationService?
    @Published var userDataManager: UserDataManager?
    @Published var isLoading = true
    @Published var initializationError: String?
    
    func initializeServices() {
        Task { @MainActor in
            print("📱 Starting safe service initialization...")
            
            // Initialize services one by one
            await initializeAppState()
            await initializeNetworkManager()
            await initializeAuthManager()
            await initializeVoiceService()
            await initializeUserDataManager()
            
            isLoading = false
            print("✅ All services initialized successfully")
        }
    }
    
    private func initializeAppState() async {
        appState = AppState.shared
        await Task.yield() // Yield to allow other tasks to run
        print("✅ AppState initialized")
    }
    
    private func initializeNetworkManager() async {
        networkManager = SimpleNetworkManager.shared
        await Task.yield()
        print("✅ NetworkManager initialized")
    }
    
    private func initializeAuthManager() async {
        authManager = AuthenticationManager.shared
        await Task.yield()
        print("✅ AuthManager initialized")
    }
    
    private func initializeVoiceService() async {
        voiceActivationService = VoiceActivationService.shared
        await Task.yield()
        print("✅ VoiceService initialized")
    }
    
    private func initializeUserDataManager() async {
        userDataManager = UserDataManager.shared
        await Task.yield()
        print("✅ UserDataManager initialized")
    }
}

// MARK: - Safe App View
struct SafeAppView: View {
    @EnvironmentObject var safeAppManager: SafeAppManager
    
    var body: some View {
        Group {
            if safeAppManager.isLoading {
                LaunchScreenView()
            } else if let error = safeAppManager.initializationError {
                VStack {
                    Text("Error Initializing App")
                        .font(.headline)
                    Text(error)
                        .font(.caption)
                }
            } else if let appState = safeAppManager.appState,
                      let authManager = safeAppManager.authManager,
                      let networkManager = safeAppManager.networkManager,
                      let voiceActivationService = safeAppManager.voiceActivationService,
                      let userDataManager = safeAppManager.userDataManager {
                
                ContentView()
                    .environmentObject(appState)
                    .environmentObject(authManager)
                    .environmentObject(networkManager)
                    .environmentObject(voiceActivationService)
                    .environmentObject(userDataManager)
                
            } else {
                Text("An unknown error occurred.")
            }
        }
    }
}
