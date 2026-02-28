import Foundation

struct GeneratedAnswers: Codable, Sendable {
    let correctAnswer: String
    let wrongAnswers: [String]
    let explanation: String
}

struct Question: Identifiable, Sendable {
    let id: UUID
    let text: String
    let choices: [String]
    let correctIndex: Int
    let explanation: String
    let difficulty: Difficulty
    let topic: String

    init(text: String, answers: GeneratedAnswers, difficulty: Difficulty, topic: String) {
        self.id = UUID()
        self.text = text
        self.explanation = answers.explanation
        self.difficulty = difficulty
        self.topic = topic
        var choices = Array(answers.wrongAnswers.prefix(3))
        let correctIndex = Int.random(in: 0...choices.count)
        choices.insert(answers.correctAnswer, at: correctIndex)
        self.choices = choices
        self.correctIndex = correctIndex
    }
}
