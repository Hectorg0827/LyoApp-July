import Foundation
import Combine

@MainActor
class DynamicClassroomManager: ObservableObject {
    static let shared = DynamicClassroomManager()
    
    @Published var classroomConfig: DynamicClassroomConfig?
    @Published var isGenerating = false
    @Published var error: String?
    @Published var currentEnvironment: ClassroomEnvironment?
    @Published var tutorPersonality: TutorPersonality?
    @Published var contextualQuiz: ContextualQuiz?
    @Published var studentScore = 0
    @Published var lessonsCompleted = 0
    
    private let apiClient = APIClient.shared
    private let environmentMapper = SubjectContextMapper.shared
    
    // MARK: - Generate Dynamic Classroom
    
    func generateClassroomForCourse(_ course: Course) async {
        isGenerating = true
        defer { isGenerating = false }
        
        do {
            // Map course to environment
            let environment = try await environmentMapper.mapCourseToEnvironment(course)
            self.currentEnvironment = environment
            
            print("📍 Environment mapped: \(environment.setting)")
            
            // Request classroom generation from backend
            let config = try await requestClassroomGeneration(
                courseId: course.id.uuidString,
                subject: course.subject,
                topic: course.topic,
                environment: environment
            )
            
            self.classroomConfig = config
            self.tutorPersonality = config.tutorPersonality
            self.contextualQuiz = config.quiz
            
            print("✅ Classroom generated: \(config.classroomId)")
            print("📍 Environment: \(environment.setting)")
            print("👨‍🎓 Tutor: \(config.tutorPersonality.role)")
            
        } catch {
            print("❌ Classroom generation failed: \(error)")
            self.error = "Failed to generate classroom: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Backend Request
    
    private func requestClassroomGeneration(
        courseId: String,
        subject: String,
        topic: String,
        environment: ClassroomEnvironment
    ) async throws -> DynamicClassroomConfig {
        
        let payload: [String: Any] = [
            "course_id": courseId,
            "subject": subject,
            "topic": topic,
            "environment": environment.rawConfiguration,
            "difficulty": "intermediate"
        ]
        
        // For now, return mock data since backend endpoint may not exist
        // In production, this would call: apiClient.post(...) 
        return generateMockClassroomConfig(
            courseId: courseId,
            environment: environment,
            subject: subject
        )
    }
    
    // MARK: - Submit Quiz Answer (Context-Aware)
    
    func submitQuizAnswer(questionId: String, answer: String) async {
        guard let quiz = contextualQuiz else { return }
        
        do {
            // In production, this calls the backend
            // For now, we'll grade locally with context awareness
            let score = gradeAnswerWithContext(answer: answer, questionId: questionId)
            self.studentScore += score
            
            print("📊 Answer graded: \(score)/100")
            
        } catch {
            print("❌ Failed to submit answer: \(error)")
        }
    }
    
    private func gradeAnswerWithContext(answer: String, questionId: String) -> Int {
        // Context-aware grading based on environment
        let baseScore = answer.count > 10 ? 70 : 30
        let environmentBonus = (currentEnvironment?.culturalElements?.count ?? 0) > 0 ? 20 : 0
        return min(baseScore + environmentBonus, 100)
    }
    
    // MARK: - Mock Data Generator
    
    private func generateMockClassroomConfig(
        courseId: String,
        environment: ClassroomEnvironment,
        subject: String
    ) -> DynamicClassroomConfig {
        
        let scene = SceneConfiguration(
            setting: environment.setting,
            location: environment.location,
            timePeriod: environment.timeperiod,
            weather: environment.weather ?? "clear",
            lighting: "natural",
            atmosphere: environment.atmosphere.rawValue,
            sceneObjects: generateSceneObjects(for: environment.setting)
        )
        
        let avatar = AvatarConfiguration(
            role: environment.avatarRole,
            appearance: "culturally_appropriate_\(environment.setting)",
            accent: "native_speaker",
            knowledgeDomain: subject,
            behaviorProfile: "expert_educator"
        )
        
        let tutor = TutorPersonality(
            personality: environment.avatarRole,
            teachingStyle: "immersive_contextual",
            languageFlavor: "subject_expert",
            engagementLevel: "highly_engaging",
            subjectExpertise: subject
        )
        
        let questions = generateContextualQuestions(for: subject, environment: environment)
        let quiz = ContextualQuiz(
            quizType: "immersive_contextual",
            settingContext: environment.setting,
            questions: questions,
            maxScore: 100
        )
        
        return DynamicClassroomConfig(
            classroomId: "classroom-\(courseId)",
            scene: scene,
            avatar: avatar,
            tutorPersonality: tutor,
            quiz: quiz,
            sessionToken: UUID().uuidString,
            ttl: 3600
        )
    }
    
    private func generateSceneObjects(for setting: String) -> [SceneObject] {
        switch setting {
        case "maya_ceremonial_center":
            return [
                SceneObject(
                    type: "pyramid",
                    name: "Temple of the Great Jaguar",
                    position: "center",
                    interactive: true,
                    trivia: "Built around 732 CE, represents Maya architectural achievement"
                ),
                SceneObject(
                    type: "artifact",
                    name: "Calendar Stone",
                    position: "foreground",
                    interactive: true,
                    trivia: "Used for tracking time and religious ceremonies"
                )
            ]
        case "mars_habitation_base":
            return [
                SceneObject(
                    type: "habitat",
                    name: "Pressurized Living Module",
                    position: "center",
                    interactive: true,
                    trivia: "Maintains Earth-like pressure for human survival"
                ),
                SceneObject(
                    type: "rover",
                    name: "Geological Survey Rover",
                    position: "exterior",
                    interactive: true,
                    trivia: "Collects samples for analysis"
                )
            ]
        case "modern_chemistry_lab":
            return [
                SceneObject(
                    type: "equipment",
                    name: "Periodic Table Display",
                    position: "wall",
                    interactive: true,
                    trivia: "Reference for all chemical elements"
                ),
                SceneObject(
                    type: "workstation",
                    name: "Student Lab Bench",
                    position: "center",
                    interactive: true,
                    trivia: "Where experiments are conducted"
                )
            ]
        default:
            return []
        }
    }
    
    private func generateContextualQuestions(
        for subject: String,
        environment: ClassroomEnvironment
    ) -> [ContextualQuestion] {
        
        switch subject {
        case "history":
            return [
                ContextualQuestion(
                    id: "q1",
                    questionText: "Based on the architecture around us, what can you infer about the society that built these structures?",
                    questionType: "artifact_identification",
                    context: "Standing in \(environment.location) during \(environment.timeperiod)",
                    timeLimit: 60,
                    scoringRubric: "analytical_reasoning"
                ),
                ContextualQuestion(
                    id: "q2",
                    questionText: "Why would this civilization choose this location for their settlement?",
                    questionType: "environmental_analysis",
                    context: "Considering the climate, resources, and strategic position",
                    timeLimit: 45,
                    scoringRubric: "strategic_thinking"
                )
            ]
        case "science":
            return [
                ContextualQuestion(
                    id: "q1",
                    questionText: "What challenges would humans face living in this environment?",
                    questionType: "environmental_analysis",
                    context: "Analyzing the present conditions around us",
                    timeLimit: 60,
                    scoringRubric: "critical_thinking"
                ),
                ContextualQuestion(
                    id: "q2",
                    questionText: "How do the tools and equipment here help us study this subject?",
                    questionType: "methodology",
                    context: "Examining the scientific instruments available",
                    timeLimit: 45,
                    scoringRubric: "scientific_literacy"
                )
            ]
        default:
            return [
                ContextualQuestion(
                    id: "q1",
                    questionText: "What did you learn in this immersive environment?",
                    questionType: "reflection",
                    context: "Reflecting on your experience",
                    timeLimit: 60,
                    scoringRubric: "comprehension"
                )
            ]
        }
    }
}

// MARK: - Data Models

struct DynamicClassroomConfig: Codable {
    let classroomId: String
    let scene: SceneConfiguration
    let avatar: AvatarConfiguration
    let tutorPersonality: TutorPersonality
    let quiz: ContextualQuiz
    let sessionToken: String
    let ttl: Int
    
    enum CodingKeys: String, CodingKey {
        case classroomId = "classroom_id"
        case scene, avatar
        case tutorPersonality = "tutor_personality"
        case quiz
        case sessionToken = "session_token"
        case ttl
    }
}

struct SceneConfiguration: Codable {
    let setting: String
    let location: String
    let timePeriod: String
    let weather: String
    let lighting: String
    let atmosphere: String
    let sceneObjects: [SceneObject]
    
    enum CodingKeys: String, CodingKey {
        case setting, location
        case timePeriod = "time_period"
        case weather, lighting, atmosphere
        case sceneObjects = "scene_objects"
    }
}

struct SceneObject: Codable {
    let type: String
    let name: String
    let position: String
    let interactive: Bool
    let trivia: String?
    let modelId: String?
    
    enum CodingKeys: String, CodingKey {
        case type, name, position, interactive, trivia
        case modelId = "model_id"
    }
}

struct AvatarConfiguration: Codable {
    let role: String
    let appearance: String
    let accent: String?
    let knowledgeDomain: String
    let behaviorProfile: String
    
    enum CodingKeys: String, CodingKey {
        case role, appearance, accent
        case knowledgeDomain = "knowledge_domain"
        case behaviorProfile = "behavior_profile"
    }
}

struct TutorPersonality: Codable {
    let personality: String
    let teachingStyle: String
    let languageFlavor: String
    let engagementLevel: String
    let subjectExpertise: String
    
    enum CodingKeys: String, CodingKey {
        case personality
        case teachingStyle = "teaching_style"
        case languageFlavor = "language_flavor"
        case engagementLevel = "engagement_level"
        case subjectExpertise = "subject_expertise"
    }
    
    var role: String {
        personality.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

struct ContextualQuiz: Codable {
    let quizType: String
    let settingContext: String
    let questions: [ContextualQuestion]
    let maxScore: Int
    
    enum CodingKeys: String, CodingKey {
        case quizType = "quiz_type"
        case settingContext = "setting_context"
        case questions
        case maxScore = "max_score"
    }
}

struct ContextualQuestion: Codable, Identifiable {
    let id: String
    let questionText: String
    let questionType: String
    let context: String
    let timeLimit: Int
    let scoringRubric: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionText = "question_text"
        case questionType = "question_type"
        case context
        case timeLimit = "time_limit"
        case scoringRubric = "scoring_rubric"
    }
}

struct QuizGradingResponse: Codable {
    let score: Int
    let contextualFeedback: String
    let nextQuestion: ContextualQuestion?
    let hints: [String]
    
    enum CodingKeys: String, CodingKey {
        case score
        case contextualFeedback = "contextual_feedback"
        case nextQuestion = "next_question"
        case hints
    }
}

struct ClassroomGenerationRequest: Encodable {
    let courseId: String
    let subject: String
    let topic: String
    let environment: [String: Any]
    let difficulty: String
    
    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case subject, topic, environment, difficulty
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(courseId, forKey: .courseId)
        try container.encode(subject, forKey: .subject)
        try container.encode(topic, forKey: .topic)
        try container.encode(difficulty, forKey: .difficulty)
        // environment intentionally omitted due to [String: Any]
    }
}

// MARK: - LearningResource Helper Methods
extension DynamicClassroomManager {
    /// Gets the location string for a learning resource based on its category
    func getLocationForResource(_ resource: LearningResource) -> String {
        let context = SubjectContextMapper.shared.getContextForSubject(resource.category ?? "General")
        return context.location
    }
    
    /// Gets the time period string for a learning resource based on its category
    func getTimePeriodForResource(_ resource: LearningResource) -> String {
        let context = SubjectContextMapper.shared.getContextForSubject(resource.category ?? "General")
        return context.timePeriod
    }
    
    /// Prepares the classroom for a learning resource
    func prepareClassroom(with courseData: [String: Any]) async {
        await MainActor.run {
            self.isGenerating = true
        }
        
        // Extract course details
        let lessonId = courseData["lessonId"] as? String ?? "unknown"
        let category = courseData["category"] as? String ?? "General"
        _ = courseData["difficulty"] as? String ?? "Intermediate"
        
        // Get environment context
        let context = SubjectContextMapper.shared.getContextForSubject(category)
        
        await MainActor.run {
            self.currentEnvironment = ClassroomEnvironment(
                setting: category,
                location: context.location,
                timeperiod: context.timePeriod,
                avatarRole: "tutor",
                atmosphere: .academic,
                weather: nil,
                culturalElements: context.culturalElements
            )
            self.isGenerating = false
        }
        
        print("🎓 Classroom prepared for: \(lessonId)")
        print("📍 Location: \(context.location)")
        print("⏰ Time Period: \(context.timePeriod)")
    }
}
