import SwiftUI

struct FeedbackCard: View {
    let isCorrect: Bool
    let explanation: String
    let disputeResult: DisputeResult?
    let isDisputePending: Bool
    let canDispute: Bool
    let onDispute: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: headerIcon)
                    .foregroundStyle(headerColor)
                    .font(.title3)
                Text(headerText)
                    .font(.headline)
                    .foregroundStyle(headerColor)
            }

            // Explanation (original, shown when wrong and no upheld dispute)
            if !isCorrect, case .none = disputeResult {
                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Dispute verdict
            if let result = disputeResult {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Label(
                        result.isUpheld ? "Dispute upheld" : "Dispute rejected",
                        systemImage: result.isUpheld ? "checkmark.seal.fill" : "xmark.seal.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(result.isUpheld ? .green : .orange)

                    Text(result.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Dispute controls
            if isDisputePending {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Fact-checking...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if canDispute {
                Button(action: onDispute) {
                    Label("Dispute this answer", systemImage: "exclamationmark.bubble")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(headerColor.opacity(0.08))
                .stroke(headerColor.opacity(0.3), lineWidth: 1)
        )
        .animation(.spring(duration: 0.3), value: isDisputePending)
        .animation(.spring(duration: 0.3), value: disputeResult != nil)
    }

    private var headerIcon: String {
        if isCorrect {
            return disputeResult?.isUpheld == true ? "checkmark.seal.fill" : "checkmark.circle.fill"
        }
        return "xmark.circle.fill"
    }

    private var headerText: String {
        if isCorrect {
            return disputeResult?.isUpheld == true ? "Dispute upheld!" : "Correct!"
        }
        return "Not quite"
    }

    private var headerColor: Color {
        isCorrect ? .green : .red
    }
}
