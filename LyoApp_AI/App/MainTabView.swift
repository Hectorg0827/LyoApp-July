import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Learn Tab
            CourseListView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "graduationcap.fill" : "graduationcap")
                    Text("Learn")
                }
                .tag(0)
            
            // Tutor Tab
            TutorChatView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "brain.head.profile.fill" : "brain.head.profile")
                    Text("Tutor")
                }
                .tag(1)
            
            // Feed Tab
            FeedView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "house.fill" : "house")
                    Text("Feed")
                }
                .tag(2)
            
            // Messages Tab
            ThreadsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "message.fill" : "message")
                    Text("Messages")
                }
                .tag(3)
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(Tokens.Colors.brand)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppContainer(debug: true))
}
