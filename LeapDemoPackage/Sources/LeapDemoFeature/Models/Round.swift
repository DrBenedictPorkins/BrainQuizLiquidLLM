import Foundation
import LeapSDK

@Generatable("A summary card shown at the end of a quiz round")
struct GeneratedRoundSummary: Codable, Sendable {
    @Guide("Short encouraging title for the round performance, 4-6 words, e.g. 'Great Round!' or 'Tough One!'")
    var title: String

    @Guide("One encouraging sentence about the round performance, e.g. 'You showed real effort on this round!'")
    var nextRoundRationale: String

    @Guide("An array of surprising tangential facts, one for each question the user got wrong. Each fact must NOT restate the correct answer — instead share something unexpected or lesser-known about the broader topic, starting with 'Did you know...'")
    var didYouKnowFacts: [DidYouKnowFact]
}

@Generatable("A 'Did you know' fact for a wrong answer")
struct DidYouKnowFact: Codable, Sendable {
    @Guide("The question text this fact relates to")
    var questionText: String

    @Guide("A surprising fact starting with 'Did you know...' about the broader topic — must NOT just restate the correct answer")
    var fact: String
}

struct RoundSummary: Sendable {
    let title: String
    let nextRoundRationale: String
    let nextDifficulty: Difficulty
    let didYouKnowFacts: [DidYouKnowFact]

    init(from generated: GeneratedRoundSummary, round: Round) {
        self.title = generated.title
        self.nextRoundRationale = generated.nextRoundRationale
        self.didYouKnowFacts = generated.didYouKnowFacts
        self.nextDifficulty = RoundSummary.computeNextDifficulty(score: round.scorePercent, current: round.difficulty)
    }

    private static func computeNextDifficulty(score: Double, current: Difficulty) -> Difficulty {
        switch score {
        case 0.8...: return current.next
        case ..<0.4: return current.previous
        default: return current
        }
    }
}

struct Round: Identifiable, Sendable {
    let id: UUID
    let roundNumber: Int
    let difficulty: Difficulty
    let subCategory: String
    var answers: [AnswerRecord]
    var summary: RoundSummary?
    var pendingQuestionTexts: [String]

    init(roundNumber: Int, difficulty: Difficulty, subCategory: String) {
        self.id = UUID()
        self.roundNumber = roundNumber
        self.difficulty = difficulty
        self.subCategory = subCategory
        self.answers = []
        self.pendingQuestionTexts = []
    }

    var questionsAnswered: Int { answers.count }
    var correctCount: Int { answers.filter(\.isCorrect).count }
    var scorePercent: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctCount) / Double(questionsAnswered)
    }
    var isComplete: Bool { questionsAnswered >= 5 }
    var wrongAnswers: [AnswerRecord] { answers.filter { !$0.isCorrect } }
}
