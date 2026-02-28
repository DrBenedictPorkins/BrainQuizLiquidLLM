import Foundation
import LeapSDK

@Generatable("A final assessment of the player's complete quiz session")
struct GeneratedFinalSummary: Codable, Sendable {
    @Guide("An encouraging session title, 5-8 words")
    var title: String

    @Guide("2-3 sentences on what the player did well")
    var strengths: String

    @Guide("1-2 sentences on topics or areas to study more")
    var areasToImprove: String

    @Guide("One concrete recommendation for next steps")
    var recommendation: String
}

struct FinalSummary: Sendable {
    let title: String
    let strengths: String
    let areasToImprove: String
    let recommendation: String
    let grade: String

    init(from generated: GeneratedFinalSummary, score: Double) {
        self.title = generated.title
        self.strengths = generated.strengths
        self.areasToImprove = generated.areasToImprove
        self.recommendation = generated.recommendation
        self.grade = FinalSummary.computeGrade(score: score)
    }

    static func computeGrade(score: Double) -> String {
        switch score {
        case 0.93...: return "A+"
        case 0.90...: return "A"
        case 0.87...: return "A-"
        case 0.83...: return "B+"
        case 0.80...: return "B"
        case 0.77...: return "B-"
        case 0.73...: return "C+"
        case 0.70...: return "C"
        case 0.67...: return "C-"
        case 0.60...: return "D"
        default: return "F"
        }
    }
}

struct GameSession: Identifiable, Sendable {
    let id: UUID
    let topicSelection: TopicSelection
    var rounds: [Round]
    var finalSummary: FinalSummary?
    let startedAt: Date
    var subCategories: [String]

    init(topicSelection: TopicSelection) {
        self.id = UUID()
        self.topicSelection = topicSelection
        self.rounds = []
        self.startedAt = Date()
        self.subCategories = []
    }

    var currentRound: Round? { rounds.last }
    var totalAnswered: Int { rounds.flatMap(\.answers).count }
    var totalCorrect: Int { rounds.flatMap(\.answers).filter(\.isCorrect).count }
    var overallScore: Double {
        guard totalAnswered > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswered)
    }
    var difficultyProgression: [Difficulty] { rounds.map(\.difficulty) }
}
