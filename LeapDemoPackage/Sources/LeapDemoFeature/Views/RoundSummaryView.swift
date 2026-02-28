import SwiftUI

struct RoundSummaryView: View {
    @Environment(QuizEngine.self) private var engine

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            if engine.phase == .generatingRoundSummary {
                VStack(spacing: 16) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                        .symbolEffect(.pulse)
                    Text("Tallying results...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let session = engine.session,
                      let round = session.rounds.last,
                      let summary = round.summary {
                ScrollView {
                    VStack(spacing: 20) {
                        // Score header
                        VStack(spacing: 8) {
                            Text(summary.title)
                                .font(.title.bold())
                                .multilineTextAlignment(.center)

                            HStack(spacing: 4) {
                                Text("\(round.correctCount)")
                                    .font(.system(size: 56, weight: .black, design: .rounded))
                                Text("/\(round.questionsAnswered)")
                                    .font(.system(size: 32, weight: .medium, design: .rounded))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 16)
                            }

                            DifficultyBadge(difficulty: round.difficulty)
                        }
                        .padding(.top, 32)

                        // Did you know facts
                        if !summary.didYouKnowFacts.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Did you know?")
                                    .font(.headline)
                                    .padding(.horizontal)

                                ForEach(summary.didYouKnowFacts, id: \.questionText) { fact in
                                    DidYouKnowCard(fact: fact)
                                        .padding(.horizontal)
                                }
                            }
                        }

                        // Next round callout
                        VStack(spacing: 8) {
                            Text(summary.nextRoundRationale)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 4) {
                                Text("Next round:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                DifficultyBadge(difficulty: summary.nextDifficulty)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.background, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                        // Action buttons
                        VStack(spacing: 12) {
                            Button {
                                Task { await engine.continueToNextRound() }
                            } label: {
                                Label("Next Round", systemImage: "arrow.right")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                Task { await engine.finishSession() }
                            } label: {
                                Text("Finish Session")
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

struct DidYouKnowCard: View {
    let fact: DidYouKnowFact

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(fact.questionText)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(2)

            Text(fact.fact)
                .font(.subheadline)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
    }
}
