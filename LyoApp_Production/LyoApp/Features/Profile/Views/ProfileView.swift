import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeader(user: authManager.currentUser)
                    
                    // Stats Section
                    StatsSection(stats: authManager.currentUser?.stats)
                    
                    // Menu Items
                    VStack(spacing: 0) {
                        ProfileMenuItem(
                            icon: "person.circle.fill",
                            title: "Edit Profile",
                            action: { /* Edit profile */ }
                        )
                        
                        ProfileMenuItem(
                            icon: "gear",
                            title: "Settings",
                            action: { /* Settings */ }
                        )
                        
                        ProfileMenuItem(
                            icon: "trophy.fill",
                            title: "Achievements",
                            action: { /* Achievements */ }
                        )
                        
                        ProfileMenuItem(
                            icon: "heart.fill",
                            title: "Favorites",
                            action: { /* Favorites */ }
                        )
                        
                        ProfileMenuItem(
                            icon: "questionmark.circle.fill",
                            title: "Help & Support",
                            action: { /* Help */ }
                        )
                        
                        ProfileMenuItem(
                            icon: "info.circle.fill",
                            title: "About",
                            action: { /* About */ }
                        )
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Logout Button
                    Button(action: {
                        Task {
                            await authManager.logout()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .background(Color(.systemGroupedBackground))
        }
    }
}

struct ProfileHeader: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 16) {
            AsyncImage(url: URL(string: user?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 4)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 4) {
                Text(user?.fullName ?? "User Name")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("@\(user?.username ?? "username")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bio = user?.bio {
                    Text(bio)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                if user?.isVerified == true {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.blue)
                        Text("Verified")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StatsSection: View {
    let stats: UserStats?
    
    var body: some View {
        HStack(spacing: 0) {
            StatItem(
                title: "Courses",
                value: "\(stats?.completedCourses ?? 0)",
                subtitle: "Completed"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "Points",
                value: "\(stats?.totalPoints ?? 0)",
                subtitle: "Earned"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "Level",
                value: "\(stats?.level ?? 1)",
                subtitle: "Current"
            )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileMenuItem: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let networkManager = NetworkManager.shared
    
    func updateProfile() async {
        // Implementation for profile update
    }
}
