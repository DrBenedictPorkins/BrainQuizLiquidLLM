import SwiftUI

struct QuestionGeneratingView: View {
    let status: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse)

            ZStack {
                Text(status.isEmpty ? "Generating question..." : status)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .id(status)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(y: 8)),
                        removal: .opacity.combined(with: .offset(y: -8))
                    ))
            }
            .animation(.easeInOut(duration: 0.35), value: status)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
