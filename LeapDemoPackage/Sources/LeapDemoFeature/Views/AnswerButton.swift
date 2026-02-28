import SwiftUI

struct AnswerButton: View {
    enum State {
        case `default`
        case selected
        case correct
        case wrong
    }

    let text: String
    let index: Int
    let state: State
    let action: () -> Void

    private var backgroundColor: Color {
        switch state {
        case .default: return Color(.secondarySystemBackground)
        case .selected: return Color.accentColor.opacity(0.15)
        case .correct: return Color.green.opacity(0.15)
        case .wrong: return Color.red.opacity(0.15)
        }
    }

    private var borderColor: Color {
        switch state {
        case .default: return Color.clear
        case .selected: return Color.accentColor
        case .correct: return Color.green
        case .wrong: return Color.red
        }
    }

    private var iconName: String? {
        switch state {
        case .correct: return "checkmark.circle.fill"
        case .wrong: return "xmark.circle.fill"
        default: return nil
        }
    }

    private var iconColor: Color {
        state == .correct ? .green : .red
    }

    private let labels = ["A", "B", "C", "D"]

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(labels[index])
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(borderColor == .clear ? .secondary : borderColor)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle().fill(backgroundColor == Color(.secondarySystemBackground)
                            ? Color(.tertiarySystemBackground)
                            : borderColor.opacity(0.15))
                    )

                Text(text)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let icon = iconName {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.title3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(backgroundColor)
                    .stroke(borderColor, lineWidth: 1.5)
            )
        }
        .disabled(state == .correct || state == .wrong)
        .accessibilityLabel("Answer \(labels[index]): \(text)")
        .accessibilityAddTraits(state == .selected ? [.isButton, .isSelected] : .isButton)
        .animation(.spring(duration: 0.2), value: state)
    }
}
