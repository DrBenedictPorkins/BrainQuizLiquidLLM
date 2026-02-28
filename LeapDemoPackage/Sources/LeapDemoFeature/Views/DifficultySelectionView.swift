import SwiftUI

struct DifficultySelectionView: View {
    @Environment(QuizEngine.self) private var engine

    private let selectable: [Difficulty] = [.easy, .medium, .hard]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 6) {
                if let selection = engine.pendingTopicSelection {
                    Text(selection.promptString)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 40)
                }
                Text("Choose a difficulty")
                    .font(.title2.bold())
                    .padding(.top, 4)
            }
            .padding(.bottom, 32)

            // Difficulty cards
            VStack(spacing: 14) {
                ForEach(selectable, id: \.self) { difficulty in
                    DifficultyCard(difficulty: difficulty) {
                        guard let selection = engine.pendingTopicSelection else { return }
                        Task { await engine.startSession(topicSelection: selection, initialDifficulty: difficulty) }
                    }
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Back link
            Button {
                engine.resetSession()
            } label: {
                Text("Back to topics")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

private struct DifficultyCard: View {
    let difficulty: Difficulty
    let action: () -> Void

    private var accentColor: Color {
        switch difficulty {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .overlay(
                        Circle().strokeBorder(accentColor, lineWidth: 2)
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(difficulty.displayName.prefix(1))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(accentColor)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(difficulty.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(difficulty.promptDescription.capitalized)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(.background, in: RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(difficulty.displayName): \(difficulty.promptDescription)")
    }
}
