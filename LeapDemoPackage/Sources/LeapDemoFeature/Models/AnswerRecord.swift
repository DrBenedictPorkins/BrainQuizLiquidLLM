import Foundation

struct AnswerRecord: Identifiable, Sendable {
    let id: UUID
    let question: Question
    let selectedIndex: Int
    var isCorrect: Bool
    var disputeResult: DisputeResult?

    init(question: Question, selectedIndex: Int) {
        self.id = UUID()
        self.question = question
        self.selectedIndex = selectedIndex
        self.isCorrect = selectedIndex == question.correctIndex
    }
}
