import SwiftUI

struct UserProfileView: View {
    let userId: String?
    @ObservedObject private var uploadManager = MediaUploadManager.shared
    @ObservedObject private var apiClient = APIClient.shared
    @ObservedObject private var webSocket = WebSocketManager.shared
    
    @State private var userProfile: UserProfile?
    @State private var isLoading = true
    @State private var showImagePicker = false
    @State private var showEditProfile = false
    @State private var isCurrentUser = false
    @State private var selectedImage: UIImage?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading profile...")
                            .frame(maxHeight: .infinity)
                    } else if let profile = userProfile {
                        ProfileHeaderView(
                            profile: profile,
                            isCurrentUser: isCurrentUser,
                            onEditTapped: { showEditProfile = true },
                            onFollowTapped: { followUser() },
                            onMessageTapped: { startConversation() },
                            onProfileImageTapped: { showImagePicker = true }
                        )
                        
                        ProfileStatsView(profile: profile)
                        
                        ProfilePostsView(userId: profile.id)
                        
                    } else {
                        ErrorView(
                            title: "Profile Not Found",
                            message: "This user profile could not be loaded.",
                            action: { loadProfile() }
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadProfile()
            }
            .refreshable {
                await loadProfile()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(profile: userProfile!)
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(selectedImage: $selectedImage)
            }
            .onChange(of: selectedImage) { image in
                if let image = image {
                    uploadProfileImage(image)
                }
            }
        }
    }
    
    private func loadProfile() async {
        isLoading = true
        
        do {
            let response = try await apiClient.getUserProfile(userId)
            userProfile = response.user
            isCurrentUser = userId == nil // If no userId provided, assume current user
        } catch {
            print("Failed to load profile: \(error)")
        }
        
        isLoading = false
    }
    
    private func followUser() {
        guard let profile = userProfile else { return }
        
        Task {
            do {
                if profile.isFollowing == true {
                    let response = try await apiClient.unfollowUser(profile.id)
                    userProfile?.isFollowing = response.isFollowing
                    userProfile?.followersCount = response.followersCount
                } else {
                    let response = try await apiClient.followUser(profile.id)
                    userProfile?.isFollowing = response.isFollowing
                    userProfile?.followersCount = response.followersCount
                }
            } catch {
                print("Failed to follow/unfollow user: \(error)")
            }
        }
    }
    
    private func startConversation() {
        guard let profile = userProfile else { return }
        
        Task {
            if webSocket.isConnected {
                await webSocket.sendChatMessage("Hello!", to: profile.id)
            }
        }
    }
    
    private func uploadProfileImage(_ image: UIImage) {
        Task {
            do {
                let uploadedFile = try await uploadManager.uploadImage(image, filename: "profile_image.jpg")
                
                // Update profile with new image URL
                let updateRequest = UpdateUserProfileRequest(
                    username: nil,
                    email: nil,
                    fullName: nil,
                    bio: nil,
                    profileImageUrl: uploadedFile.url
                )
                
                let response = try await apiClient.updateUserProfile(updateRequest)
                userProfile = response.user
                
            } catch {
                print("Failed to upload profile image: \(error)")
            }
        }
    }
}

struct ProfileHeaderView: View {
    let profile: UserProfile
    let isCurrentUser: Bool
    let onEditTapped: () -> Void
    let onFollowTapped: () -> Void
    let onMessageTapped: () -> Void
    let onProfileImageTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image
            Button(action: isCurrentUser ? onProfileImageTapped : {}) {
                AsyncImage(url: URL(string: profile.profileImageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.blue, lineWidth: 3)
                )
            }
            .disabled(!isCurrentUser)
            
            // User Info
            VStack(spacing: 4) {
                Text(profile.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("@\(profile.username)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let bio = profile.bio {
                    Text(bio)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            
            // Action Buttons
            HStack(spacing: 16) {
                if isCurrentUser {
                    Button(action: onEditTapped) {
                        Label("Edit Profile", systemImage: "pencil")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button(action: onFollowTapped) {
                        Text(profile.isFollowing == true ? "Following" : "Follow")
                            .foregroundColor(profile.isFollowing == true ? .secondary : .white)
                    }
                    .buttonStyle(.borderedProminent)
                    .background(profile.isFollowing == true ? Color.gray : Color.blue)
                    
                    Button(action: onMessageTapped) {
                        Label("Message", systemImage: "message")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

struct ProfileStatsView: View {
    let profile: UserProfile
    
    var body: some View {
        HStack(spacing: 32) {
            StatView(title: "Posts", count: profile.postsCount)
            StatView(title: "Followers", count: profile.followersCount)
            StatView(title: "Following", count: profile.followingCount)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct StatView: View {
    let title: String
    let count: Int
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ProfilePostsView: View {
    let userId: String
    @State private var posts: [FeedPost] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Posts")
                .font(.headline)
                .padding(.horizontal)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if posts.isEmpty {
                Text("No posts yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(posts, id: \.id) { post in
                        PostThumbnailView(post: post)
                    }
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            loadUserPosts()
        }
    }
    
    private func loadUserPosts() {
        // Mock data for now - would load actual user posts from API
        posts = [
            FeedPost(
                id: UUID().uuidString,
                userId: userId,
                username: "user",
                userAvatar: nil,
                content: "Sample post content",
                imageURLs: nil,
                videoURL: nil,
                likesCount: 10,
                commentsCount: 2,
                sharesCount: 1,
                isLiked: false,
                isBookmarked: false,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                tags: []
            )
        ]
        isLoading = false
    }
}

struct PostThumbnailView: View {
    let post: FeedPost
    
    var body: some View {
        VStack {
            if let imageURLs = post.imageURLs, !imageURLs.isEmpty {
                AsyncImage(url: URL(string: imageURLs.first!)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 120)
                .clipped()
            } else {
                Rectangle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(height: 120)
                    .overlay(
                        VStack {
                            Image(systemName: "text.alignleft")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text("Text Post")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    )
            }
        }
        .cornerRadius(8)
        .onTapGesture {
            // Navigate to post detail
        }
    }
}

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var profile: UserProfile
    @State private var isLoading = false
    
    init(profile: UserProfile) {
        _profile = State(initialValue: profile)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Information") {
                    TextField("Full Name", text: Binding(
                        get: { profile.fullName },
                        set: { profile = UserProfile(
                            id: profile.id,
                            username: profile.username,
                            email: profile.email,
                            fullName: $0,
                            bio: profile.bio,
                            profileImageUrl: profile.profileImageUrl,
                            followersCount: profile.followersCount,
                            followingCount: profile.followingCount,
                            postsCount: profile.postsCount,
                            isFollowing: profile.isFollowing,
                            isFollower: profile.isFollower,
                            createdAt: profile.createdAt
                        )}
                    ))
                    
                    TextField("Username", text: Binding(
                        get: { profile.username },
                        set: { profile = UserProfile(
                            id: profile.id,
                            username: $0,
                            email: profile.email,
                            fullName: profile.fullName,
                            bio: profile.bio,
                            profileImageUrl: profile.profileImageUrl,
                            followersCount: profile.followersCount,
                            followingCount: profile.followingCount,
                            postsCount: profile.postsCount,
                            isFollowing: profile.isFollowing,
                            isFollower: profile.isFollower,
                            createdAt: profile.createdAt
                        )}
                    ))
                    
                    TextField("Bio", text: Binding(
                        get: { profile.bio ?? "" },
                        set: { profile = UserProfile(
                            id: profile.id,
                            username: profile.username,
                            email: profile.email,
                            fullName: profile.fullName,
                            bio: $0.isEmpty ? nil : $0,
                            profileImageUrl: profile.profileImageUrl,
                            followersCount: profile.followersCount,
                            followingCount: profile.followingCount,
                            postsCount: profile.postsCount,
                            isFollowing: profile.isFollowing,
                            isFollower: profile.isFollower,
                            createdAt: profile.createdAt
                        )}
                    ), axis: .vertical)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProfile()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    private func saveProfile() {
        isLoading = true
        
        Task {
            do {
                let updateRequest = UpdateUserProfileRequest(
                    username: profile.username,
                    email: nil,
                    fullName: profile.fullName,
                    bio: profile.bio,
                    profileImageUrl: profile.profileImageUrl
                )
                
                _ = try await APIClient.shared.updateUserProfile(updateRequest)
                
                await MainActor.run {
                    dismiss()
                }
                
            } catch {
                print("Failed to update profile: \(error)")
            }
            
            isLoading = false
        }
    }
}

struct ErrorView: View {
    let title: String
    let message: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Image Picker
struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        
        init(_ parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.editedImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    UserProfileView(userId: nil)
}