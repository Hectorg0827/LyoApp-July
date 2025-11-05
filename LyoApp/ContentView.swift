import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var networkManager: SimpleNetworkManager
    @EnvironmentObject var voiceActivationService: VoiceActivationService
    @EnvironmentObject var userDataManager: UserDataManager
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            // Home Feed Tab
            HomeFeedView()
                .tabItem {
                    Label("Home", systemImage: appState.selectedTab == .home ? "house.fill" : "house")
                }
                .tag(MainTab.home)
            
            // Discover Tab (using HomeFeedView for now)
            HomeFeedView()
                .tabItem {
                    Label("Discover", systemImage: appState.selectedTab == .discover ? "safari.fill" : "safari")
                }
                .tag(MainTab.discover)
            
            // Learning Hub Tab  
            LearnTabView()
                .tabItem {
                    Label("Learn", systemImage: appState.selectedTab == .ai ? "graduationcap.fill" : "graduationcap")
                }
                .tag(MainTab.ai)
            
            // Create Post Tab (placeholder)
            Text("Create Post")
                .tabItem {
                    Label("Post", systemImage: "plus")
                }
                .tag(MainTab.post)
            
            // More Tab
            MoreTabView()
                .tabItem {
                    Label("More", systemImage: appState.selectedTab == .more ? "ellipsis.circle.fill" : "ellipsis.circle")
                }
                .tag(MainTab.more)
        }
        .onAppear {
            print("🔍 ContentView with TabView appeared")
            print("📊 Services status:")
            print("  - AuthManager: \(authManager == nil ? "❌" : "✅")")
            print("  - NetworkManager: \(networkManager == nil ? "❌" : "✅")")
            print("  - UserDataManager: \(userDataManager == nil ? "❌" : "✅")")
            print("  - VoiceService: \(voiceActivationService == nil ? "❌" : "✅")")
            print("  - AppState: \(appState == nil ? "❌" : "✅")")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(AuthenticationManager.shared)
        .environmentObject(SimpleNetworkManager.shared)
        .environmentObject(VoiceActivationService.shared)
        .environmentObject(UserDataManager.shared)
}
