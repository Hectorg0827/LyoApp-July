import SwiftUI

// MARK: - Learning Assistant View
/// Simplified AI assistant for learning support
struct LearningAssistantView: View {
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var showingChat = false
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                if showingChat {
                    chatInterface
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale),
                            removal: .opacity
                        ))
                } else {
                    assistantButton
                        .transition(.opacity)
                }
            }
            .padding()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showingChat)
    }
    
    private var assistantButton: some View {
        Button(action: {
            withAnimation {
                showingChat.toggle()
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 2) {
                    Image(systemName: "brain.head.profile")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    Text("Lio")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isExpanded ? 1.1 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever()) {
                isExpanded.toggle()
            }
        }
    }
    
    private var chatInterface: some View {
        VStack(spacing: 16) {
            // Chat Header
            HStack {
                Button(action: {
                    withAnimation {
                        showingChat = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text("Lio - AI Learning Assistant")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Ready to help you learn")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Circle()
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.white)
                    )
            }
            
            // Quick Actions
            VStack(spacing: 8) {
                Text("How can I help you today?")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 8) {
                    quickActionButton("📚 Recommend courses", action: recommendCourses)
                    quickActionButton("❓ Answer questions", action: answerQuestions)
                    quickActionButton("🎯 Set learning goals", action: setGoals)
                    quickActionButton("📊 Check progress", action: checkProgress)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .frame(width: 300, height: 250)
    }
    
    private func quickActionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Actions
    private func recommendCourses() {
        print("🤖 LIO: Recommending personalized courses...")
        // Add course recommendation logic
    }
    
    private func answerQuestions() {
        print("🤖 LIO: Ready to answer your questions...")
        // Add Q&A logic
    }
    
    private func setGoals() {
        print("🤖 LIO: Let's set your learning goals...")
        // Add goal setting logic
    }
    
    private func checkProgress() {
        print("🤖 LIO: Checking your learning progress...")
        // Add progress checking logic
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        
        LearningAssistantView()
            .environmentObject(AppState())
    }
}
