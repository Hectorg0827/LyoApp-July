import SwiftUI

// MARK: - AI-Powered Learning Assistant View
struct AILearningAssistantView: View {
    @StateObject private var aiService = GemmaAIService.shared
    @EnvironmentObject var appState: AppState
    
    @State private var selectedTab = 0
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            AIAssistantHeader(isExpanded: $isExpanded)
            
            if isExpanded {
                // Main Content
                TabView(selection: $selectedTab) {
                    AIContentAnalysisView()
                        .tabItem {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Analyze")
                        }
                        .tag(0)
                    
                    AIStudyQuestionsView()
                        .tabItem {
                            Image(systemName: "questionmark.circle")
                            Text("Questions")
                        }
                        .tag(1)
                    
                    AIRecommendationsView()
                        .tabItem {
                            Image(systemName: "sparkles")
                            Text("Recommendations")
                        }
                        .tag(2)
                    
                    AILearningPathView()
                        .tabItem {
                            Image(systemName: "map")
                            Text("Path")
                        }
                        .tag(3)
                }
                .frame(height: 400)
                .background(DesignTokens.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding()
        .background(DesignTokens.backgroundSecondary)
        .onAppear {
            // Initialize AI service if needed
            if !aiService.isInitialized {
                Task {
                    // AI service auto-initializes
                }
            }
        }
    }
}

// MARK: - AI Assistant Header
struct AIAssistantHeader: View {
    @Binding var isExpanded: Bool
    @StateObject private var aiService = GemmaAIService.shared
    
    var body: some View {
        HStack {
            // AI Status Indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(aiService.isInitialized ? .green : .orange)
                    .frame(width: 8, height: 8)
                
                Text("AI Assistant")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(DesignTokens.textPrimary)
                
                if aiService.isProcessing {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            Spacer()
            
            // Expand/Collapse Button
            Button(action: {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }) {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(DesignTokens.accent)
                    .font(.title3)
            }
        }
        .padding()
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Content Analysis View
struct AIContentAnalysisView: View {
    @StateObject private var aiService = GemmaAIService.shared
    @State private var inputText = ""
    @State private var analysis: ContentAnalysis?
    @State private var isAnalyzing = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Content Analysis")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.textPrimary)
                
                // Input Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste content to analyze:")
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.textSecondary)
                    
                    TextEditor(text: $inputText)
                        .frame(height: 100)
                        .padding(8)
                        .background(DesignTokens.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Button(action: analyzeContent) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text("Analyze with AI")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(DesignTokens.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(inputText.isEmpty || isAnalyzing)
                }
                
                // Analysis Results
                if let analysis = analysis {
                    AnalysisResultsView(analysis: analysis)
                }
            }
            .padding()
        }
    }
    
    private func analyzeContent() {
        isAnalyzing = true
        Task {
            let result = await aiService.analyzeContent(inputText)
            await MainActor.run {
                self.analysis = result
                self.isAnalyzing = false
            }
        }
    }
}

// MARK: - Analysis Results View
struct AnalysisResultsView: View {
    let analysis: ContentAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis Results")
                .font(.headline)
                .foregroundColor(DesignTokens.textPrimary)
            
            // Difficulty Level
            HStack {
                Text("Difficulty:")
                    .fontWeight(.medium)
                Spacer()
                DifficultyBadge(level: analysis.difficulty)
            }
            
            // Reading Time
            HStack {
                Text("Reading Time:")
                    .fontWeight(.medium)
                Spacer()
                Text("\(analysis.estimatedReadingTime) min")
                    .foregroundColor(DesignTokens.textSecondary)
            }
            
            // Topics
            if !analysis.topics.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Topics:")
                        .fontWeight(.medium)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                        ForEach(analysis.topics, id: \.self) { topic in
                            Text(topic)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(DesignTokens.accent.opacity(0.1))
                                .foregroundColor(DesignTokens.accent)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Summary
            if !analysis.summary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Summary:")
                        .fontWeight(.medium)
                    
                    Text(analysis.summary)
                        .font(.body)
                        .foregroundColor(DesignTokens.textSecondary)
                        .padding()
                        .background(DesignTokens.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Learning Objectives
            if !analysis.learningObjectives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Learning Objectives:")
                        .fontWeight(.medium)
                    
                    ForEach(analysis.learningObjectives, id: \.self) { objective in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(DesignTokens.accent)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(objective)
                                .font(.body)
                                .foregroundColor(DesignTokens.textSecondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(DesignTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Study Questions View
struct AIStudyQuestionsView: View {
    @StateObject private var aiService = GemmaAIService.shared
    @EnvironmentObject var appState: AppState
    
    @State private var selectedResource: LearningResource?
    @State private var questions: [StudyQuestion] = []
    @State private var isGenerating = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI Study Questions")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.textPrimary)
                
                // Resource Selection
                ResourcePickerView(
                    resources: appState.learningResources,
                    selectedResource: $selectedResource
                )
                
                // Generate Button
                Button(action: generateQuestions) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "questionmark.circle")
                        }
                        Text("Generate Study Questions")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(DesignTokens.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(selectedResource == nil || isGenerating)
                
                // Questions List
                if !questions.isEmpty {
                    StudyQuestionsListView(questions: questions)
                }
            }
            .padding()
        }
    }
    
    private func generateQuestions() {
        guard let resource = selectedResource else { return }
        
        isGenerating = true
        Task {
            let content = "\(resource.title) \(resource.description)"
            let generatedQuestions = await aiService.generateStudyQuestions(for: content, count: 5)
            
            await MainActor.run {
                self.questions = generatedQuestions
                self.isGenerating = false
            }
        }
    }
}

// MARK: - Resource Picker View
struct ResourcePickerView: View {
    let resources: [LearningResource]
    @Binding var selectedResource: LearningResource?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a resource:")
                .font(.subheadline)
                .foregroundColor(DesignTokens.textSecondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(resources) { resource in
                        ResourceCardMini(
                            resource: resource,
                            isSelected: selectedResource?.id == resource.id
                        ) {
                            selectedResource = resource
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Mini Resource Card
struct ResourceCardMini: View {
    let resource: LearningResource
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(resource.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            if let category = resource.category {
                Text(category)
                    .font(.caption2)
                    .foregroundColor(DesignTokens.textSecondary)
            }
        }
        .padding(8)
        .frame(width: 120, height: 60)
        .background(isSelected ? DesignTokens.accent.opacity(0.1) : DesignTokens.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? DesignTokens.accent : DesignTokens.borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Study Questions List
struct StudyQuestionsListView: View {
    let questions: [StudyQuestion]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generated Questions")
                .font(.headline)
                .foregroundColor(DesignTokens.textPrimary)
            
            ForEach(questions) { question in
                QuestionCardView(question: question)
            }
        }
    }
}

// MARK: - Question Card
struct QuestionCardView: View {
    let question: StudyQuestion
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(question.question)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.textPrimary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(DesignTokens.accent)
                }
            }
            
            HStack {
                Text(question.concept)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(DesignTokens.accent.opacity(0.1))
                    .foregroundColor(DesignTokens.accent)
                    .clipShape(Capsule())
                
                DifficultyBadge(level: question.difficulty)
                
                Spacer()
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Study Notes:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(DesignTokens.textSecondary)
                    
                    TextEditor(text: .constant(""))
                        .frame(height: 80)
                        .padding(8)
                        .background(DesignTokens.backgroundPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding()
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - AI Recommendations View
struct AIRecommendationsView: View {
    @StateObject private var aiService = GemmaAIService.shared
    @EnvironmentObject var appState: AppState
    
    @State private var recommendations: [PersonalizedRecommendation] = []
    @State private var isGenerating = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI Recommendations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.textPrimary)
                
                Button(action: generateRecommendations) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Get Personalized Recommendations")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(DesignTokens.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(isGenerating)
                
                if !recommendations.isEmpty {
                    RecommendationsListView(recommendations: recommendations)
                }
            }
            .padding()
        }
    }
    
    private func generateRecommendations() {
        guard let user = appState.currentUser else { return }
        
        isGenerating = true
        Task {
            let preferences = UserLearningPreferences(
                preferredDifficulty: .intermediate,
                favoriteTopics: ["iOS", "Swift", "Programming"],
                learningStyle: .visual,
                dailyGoalMinutes: 30
            )
            
            let generated = await aiService.generatePersonalizedRecommendations(
                for: user,
                basedOn: appState.learningResources,
                preferences: preferences
            )
            
            await MainActor.run {
                self.recommendations = generated
                self.isGenerating = false
            }
        }
    }
}

// MARK: - Recommendations List
struct RecommendationsListView: View {
    let recommendations: [PersonalizedRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommendations for You")
                .font(.headline)
                .foregroundColor(DesignTokens.textPrimary)
            
            ForEach(recommendations) { recommendation in
                RecommendationCardView(recommendation: recommendation)
            }
        }
    }
}

// MARK: - Recommendation Card
struct RecommendationCardView: View {
    let recommendation: PersonalizedRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(recommendation.title)
                    .font(.headline)
                    .foregroundColor(DesignTokens.textPrimary)
                
                Spacer()
                
                PriorityBadge(priority: recommendation.priority)
            }
            
            Text(recommendation.description)
                .font(.body)
                .foregroundColor(DesignTokens.textSecondary)
            
            Text(recommendation.reason)
                .font(.caption)
                .foregroundColor(DesignTokens.textSecondary)
                .italic()
            
            HStack {
                Text("Confidence: \(Int(recommendation.confidence * 100))%")
                    .font(.caption)
                    .foregroundColor(DesignTokens.textSecondary)
                
                Spacer()
                
                Button("View Details") {
                    // Handle tap
                }
                .font(.caption)
                .foregroundColor(DesignTokens.accent)
            }
        }
        .padding()
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(priorityColor(recommendation.priority).opacity(0.3), lineWidth: 1)
        )
    }
    
    private func priorityColor(_ priority: PersonalizedRecommendation.Priority) -> Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}

// MARK: - Learning Path View
struct AILearningPathView: View {
    @StateObject private var aiService = GemmaAIService.shared
    @State private var goal = ""
    @State private var learningPath: LearningPath?
    @State private var isGenerating = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("AI Learning Path")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(DesignTokens.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("What would you like to learn?")
                        .font(.subheadline)
                        .foregroundColor(DesignTokens.textSecondary)
                    
                    TextField("e.g., iOS App Development", text: $goal)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: generateLearningPath) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "map")
                            }
                            Text("Generate Learning Path")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(DesignTokens.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(goal.isEmpty || isGenerating)
                }
                
                if let path = learningPath {
                    LearningPathView(path: path)
                }
            }
            .padding()
        }
    }
    
    private func generateLearningPath() {
        isGenerating = true
        Task {
            let generated = await aiService.generateLearningPath(
                goal: goal,
                currentLevel: .beginner,
                timeAvailable: 5 * 60, // 5 hours per week
                preferredTypes: [.video, .course, .article]
            )
            
            await MainActor.run {
                self.learningPath = generated
                self.isGenerating = false
            }
        }
    }
}

// MARK: - Learning Path Display
struct LearningPathView: View {
    let path: LearningPath
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(path.title)
                .font(.headline)
                .foregroundColor(DesignTokens.textPrimary)
            
            Text(path.description)
                .font(.body)
                .foregroundColor(DesignTokens.textSecondary)
            
            HStack {
                Text("Duration: \(path.estimatedDuration)")
                Spacer()
                DifficultyBadge(level: path.difficulty)
            }
            .font(.caption)
            
            if !path.curriculum.isEmpty {
                Text("Curriculum:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(path.curriculum) { module in
                    CurriculumModuleCard(module: module)
                }
            }
        }
        .padding()
        .background(DesignTokens.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Curriculum Module Card
struct CurriculumModuleCard: View {
    let module: CurriculumModule
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(module.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(DesignTokens.textPrimary)
                
                Text(module.description)
                    .font(.caption)
                    .foregroundColor(DesignTokens.textSecondary)
            }
            
            Spacer()
            
            Text("\(module.estimatedTime)w")
                .font(.caption)
                .foregroundColor(DesignTokens.textSecondary)
        }
        .padding(8)
        .background(DesignTokens.backgroundSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Helper Components

struct DifficultyBadge: View {
    let level: DifficultyLevel
    
    var body: some View {
        Text(level.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(difficultyColor.opacity(0.1))
            .foregroundColor(difficultyColor)
            .clipShape(Capsule())
    }
    
    private var difficultyColor: Color {
        switch level {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        case .expert: return .purple
        }
    }
}

struct PriorityBadge: View {
    let priority: PersonalizedRecommendation.Priority
    
    var body: some View {
        Text(priority.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.1))
            .foregroundColor(priorityColor)
            .clipShape(Capsule())
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .urgent: return .purple
        }
    }
}
