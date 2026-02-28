import SwiftUI

struct DifficultyBadge: View {
    let difficulty: Difficulty

    private var color: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }

    var body: some View {
        Text(difficulty.displayName)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
            .accessibilityLabel("Difficulty: \(difficulty.displayName)")
    }
}
