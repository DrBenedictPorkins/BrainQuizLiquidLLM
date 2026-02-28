import Foundation

enum Difficulty: String, Codable, CaseIterable, Sendable, Equatable {
    case easy
    case medium
    case hard
    case expert

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }

    var promptDescription: String {
        switch self {
        case .easy: return "basic recall facts that a casual learner or child would know"
        case .medium: return "conceptual questions requiring solid understanding"
        case .hard: return "nuanced questions requiring deep knowledge"
        case .expert: return "specialist-level questions with subtle distinctions"
        }
    }

    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "orange"
        case .expert: return "red"
        }
    }

    var next: Difficulty {
        switch self {
        case .easy: return .medium
        case .medium: return .hard
        case .hard: return .expert
        case .expert: return .expert
        }
    }

    var previous: Difficulty {
        switch self {
        case .easy: return .easy
        case .medium: return .easy
        case .hard: return .medium
        case .expert: return .hard
        }
    }
}
