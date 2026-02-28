import Foundation
import LeapSDK

enum DisputeResult: Sendable {
    case upheld(explanation: String)
    case rejected(explanation: String)

    var isUpheld: Bool {
        if case .upheld = self { return true }
        return false
    }

    var explanation: String {
        switch self {
        case .upheld(let e), .rejected(let e): return e
        }
    }
}

@Generatable("Verdict on whether a disputed quiz answer was correct")
struct GeneratedDisputeVerdict: Codable, Sendable {
    @Guide("true if the dispute is upheld — meaning the answer marked as correct by the quiz was actually wrong; false if the original quiz answer was correct")
    var upheld: Bool

    @Guide("A clear, factual one-sentence explanation confirming what the actual correct answer is")
    var explanation: String
}
