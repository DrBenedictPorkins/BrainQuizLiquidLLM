import SwiftUI

struct FinalResultView: View {
    @Environment(QuizEngine.self) private var engine

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if engine.phase == .generatingFinalSummary {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .symbolEffect(.pulse)
                    Text("Writing your assessment...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let session = engine.session {
                ScrollView {
                    VStack(spacing: 20) {
                        // Grade + score
                        VStack(spacing: 8) {
                            if let summary = session.finalSummary {
                                Text(summary.grade)
                                    .font(.system(size: 80, weight: .black, design: .rounded))
                                    .foregroundStyle(Color.accentColor)

                                Text(summary.title)
                                    .font(.title2.bold())
                                    .multilineTextAlignment(.center)
                            }

                            Text("\(session.totalCorrect)/\(session.totalAnswered) correct")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            // Difficulty progression
                            HStack(spacing: 4) {
                                ForEach(Array(session.difficultyProgression.enumerated()), id: \.offset) { i, diff in
                                    if i > 0 {
                                        Image(systemName: "arrow.right")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    DifficultyBadge(difficulty: diff)
                                }
                            }
                        }
                        .padding(.top, 32)

                        // Assessment text
                        if let summary = session.finalSummary {
                            VStack(alignment: .leading, spacing: 16) {
                                AssessmentBlock(label: "What you did well", text: summary.strengths, icon: "star.fill", color: .yellow)
                                AssessmentBlock(label: "Areas to explore", text: summary.areasToImprove, icon: "book.fill", color: .blue)
                                AssessmentBlock(label: "Next step", text: summary.recommendation, icon: "arrow.right.circle.fill", color: .green)
                            }
                            .padding(.horizontal)
                        }

                        // Round breakdown
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Round Breakdown")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(session.rounds) { round in
                                HStack {
                                    Text("Round \(round.roundNumber)")
                                        .font(.subheadline)
                                    DifficultyBadge(difficulty: round.difficulty)
                                    Spacer()
                                    Text("\(round.correctCount)/\(round.questionsAnswered)")
                                        .font(.subheadline.monospacedDigit().weight(.medium))
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(.background, in: RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                            }
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                engine.selectTopic(session.topicSelection)
                            } label: {
                                Label("Play Again", systemImage: "arrow.clockwise")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                engine.resetSession()
                            } label: {
                                Text("New Topic")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}

struct AssessmentBlock: View {
    let label: String
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)

            Text(text)
                .font(.subheadline)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
