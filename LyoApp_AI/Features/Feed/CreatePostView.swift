import SwiftUI

struct CreatePostView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var container: AppContainer
    
    @State private var postText: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // Text Input Area
                ZStack(alignment: .topLeading) {
                    if postText.isEmpty {
                        Text("What's on your mind?")
                            .font(DesignTokens.Typography.bodyMedium)
                            .foregroundColor(DesignTokens.Colors.textTertiary)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }
                    
                    TextEditor(text: $postText)
                        .font(DesignTokens.Typography.bodyMedium)
                        .foregroundColor(DesignTokens.Colors.textPrimary)
                        .background(Color.clear)
                        .frame(minHeight: 100)
                }
                .padding(DesignTokens.Spacing.md)
                .background(DesignTokens.Colors.glassBg)
                .cornerRadius(DesignTokens.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.md)
                        .stroke(DesignTokens.Colors.glassBorder, lineWidth: 1)
                )
                
                Spacer()
                
                // Submit Button
                AccessibleButton(
                    title: isSubmitting ? "Posting..." : "Share Post",
                    style: .primary,
                    size: .large,
                    isLoading: isSubmitting
                ) {
                    submitPost()
                }
                .disabled(postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
            }
            .padding(DesignTokens.Spacing.lg)
            .background(DesignTokens.Colors.primaryBg.ignoresSafeArea())
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(DesignTokens.Colors.textSecondary)
            )
        }
    }
    
    private func submitPost() {
        guard !postText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isSubmitting = true
        
        Task {
            do {
                let createPost = CreatePost(
                    text: postText.trimmingCharacters(in: .whitespacesAndNewlines),
                    media: nil,
                    visibility: .public
                )
                
                let _ = try await container.feedService.createPost(createPost)
                
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // Handle error - could show alert
                    print("❌ Error creating post: \(error)")
                }
            }
        }
    }
}

#Preview {
    CreatePostView()
        .environmentObject(AppContainer.development())
}
