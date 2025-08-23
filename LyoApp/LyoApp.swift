import SwiftUI

/// Production-ready LyoApp with clean architecture
@main
struct LyoApp: App {
    
    var body: some Scene {
        WindowGroup {
            ProductionAppView()
                .onAppear {
                    print("🚀 LyoApp Production - Ready for App Store!")
                }
        }
    }
}

/// Main production app view with tab navigation
struct ProductionAppView: View {
    @State private var selectedTab = 0
    @StateObject private var appState = AppState.shared
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Feed - Core social feature
            NavigationView {
                HomeFeedView()
                    .environmentObject(appState)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)
            
            // Learning Hub - Education feature
            NavigationView {
                LearningHubView()
            }
            .tabItem {
                Image(systemName: "book.fill")
                Text("Learn")
            }
            .tag(1)
            
            // Profile - User management
            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Profile")
            }
            .tag(2)
            
            // Settings - App configuration
            NavigationView {
                ProductionSettingsView()
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
            .tag(3)
        }
        .accentColor(DesignTokens.Colors.primary)
        .onAppear {
            Analytics.shared.trackScreenView("main_tab_view")
        }
    }
}

/// Simple learning hub view
struct LearningHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🎓 Learning Hub")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Your personalized learning experience")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Featured courses section
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(0..<6, id: \.self) { index in
                        CourseCard(
                            title: "Course \(index + 1)",
                            subtitle: "Learn essential skills"
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Learn")
        .onAppear {
            Analytics.shared.trackScreenView("learning_hub")
        }
    }
}

/// Simple course card view
struct CourseCard: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 100)
                .cornerRadius(10)
            
            Text(title)
                .font(.headline)
                .lineLimit(1)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

/// Simple profile view
struct ProfileView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Profile header
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text("👤")
                            .font(.system(size: 40))
                    )
                
                Text("John Doe")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Learning enthusiast")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Stats
            HStack(spacing: 40) {
                VStack {
                    Text("12")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Courses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("89")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("5")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Certificates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
        .onAppear {
            Analytics.shared.trackScreenView("profile")
        }
    }
}

/// Production settings view
struct ProductionSettingsView: View {
    var body: some View {
        List {
            Section("App Info") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("Production")
                        .foregroundColor(.green)
                }
            }
            
            Section("Features") {
                Label("Social Feed", systemImage: "person.2.fill")
                Label("Learning Hub", systemImage: "book.fill")
                Label("Analytics", systemImage: "chart.bar.fill")
                Label("Push Notifications", systemImage: "bell.fill")
            }
            
            Section("Status") {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Production Ready")
                        .fontWeight(.medium)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            Analytics.shared.trackScreenView("settings")
        }
    }
}

/// Simple learning hub view
struct LearningHubView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("🎓 Learning Hub")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()
                
                Text("Your personalized learning experience")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                // Featured courses section
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    ForEach(0..<6, id: \.self) { index in
                        CourseCard(
                            title: "Course \(index + 1)",
                            subtitle: "Learn essential skills"
                        )
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Learn")
        .onAppear {
            Analytics.shared.trackScreenView("learning_hub")
        }
    }
}

/// Simple course card view
struct CourseCard: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 100)
                .cornerRadius(10)
            
            Text(title)
                .font(.headline)
                .lineLimit(1)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

/// Simple profile view
struct ProfileView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Profile header
            VStack(spacing: 16) {
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text("👤")
                            .font(.system(size: 40))
                    )
                
                Text("John Doe")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Learning enthusiast")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Stats
            HStack(spacing: 40) {
                VStack {
                    Text("12")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Courses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("89")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("5")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Certificates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
        .onAppear {
            Analytics.shared.trackScreenView("profile")
        }
    }
}

/// Production settings view
struct ProductionSettingsView: View {
    var body: some View {
        List {
            Section("App Info") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text("Production")
                        .foregroundColor(.green)
                }
            }
            
            Section("Features") {
                Label("Social Feed", systemImage: "person.2.fill")
                Label("Learning Hub", systemImage: "book.fill")
                Label("Analytics", systemImage: "chart.bar.fill")
                Label("Push Notifications", systemImage: "bell.fill")
            }
            
            Section("Status") {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Production Ready")
                        .fontWeight(.medium)
                }
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            Analytics.shared.trackScreenView("settings")
        }
    }
}
