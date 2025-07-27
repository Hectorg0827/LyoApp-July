import SwiftUI

// MARK: - Learning Hub Components for Build
/// Contains all Learning Hub related views to ensure successful compilation

// MARK: - Main Learning Hub View
struct LearningHubView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Learning Hub")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Enhance your skills with quantum learning")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 20)
                    
                    // Featured Courses
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Featured Courses")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(sampleCourses, id: \.id) { course in
                                    CourseCardSimple(course: course)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Learning Paths
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Learning Paths")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ForEach(samplePaths, id: \.id) { path in
                                LearningPathRow(path: path)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
        }
    }
    
    // Sample data
    private var sampleCourses: [SimpleCourse] {
        [
            SimpleCourse(id: 1, title: "SwiftUI Mastery", subtitle: "Build beautiful iOS apps", progress: 0.3),
            SimpleCourse(id: 2, title: "AI & Machine Learning", subtitle: "Learn the future of tech", progress: 0.1),
            SimpleCourse(id: 3, title: "Design Fundamentals", subtitle: "Master visual design", progress: 0.7)
        ]
    }
    
    private var samplePaths: [SimpleLearningPath] {
        [
            SimpleLearningPath(id: 1, title: "iOS Developer", coursesCount: 8, duration: "3 months"),
            SimpleLearningPath(id: 2, title: "UI/UX Designer", coursesCount: 6, duration: "2 months"),
            SimpleLearningPath(id: 3, title: "Data Scientist", coursesCount: 12, duration: "6 months")
        ]
    }
}

// MARK: - Learning Assistant View
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
    }
    
    private func answerQuestions() {
        print("🤖 LIO: Ready to answer your questions...")
    }
    
    private func setGoals() {
        print("🤖 LIO: Let's set your learning goals...")
    }
    
    private func checkProgress() {
        print("🤖 LIO: Checking your learning progress...")
    }
}

// MARK: - Supporting Components

struct CourseCardSimple: View {
    let course: SimpleCourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 200, height: 120)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "play.fill")
                                .foregroundColor(.white)
                                .font(.title2)
                                .padding()
                        }
                    }
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(course.subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
                
                ProgressView(value: course.progress)
                    .progressViewStyle(LinearProgressViewStyle()).tint(.blue)
                    .scaleEffect(y: 0.8)
            }
        }
        .frame(width: 200)
    }
}

struct LearningPathRow: View {
    let path: SimpleLearningPath
    
    var body: some View {
        HStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "graduationcap.fill")
                        .foregroundColor(.blue)
                        .font(.title3)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(path.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("\(path.coursesCount) courses • \(path.duration)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: {
                print("Start learning path: \(path.title)")
            }) {
                Text("Start")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Simple Data Models

struct SimpleCourse {
    let id: Int
    let title: String
    let subtitle: String
    let progress: Double
}

struct SimpleLearningPath {
    let id: Int
    let title: String
    let coursesCount: Int
    let duration: String
}
