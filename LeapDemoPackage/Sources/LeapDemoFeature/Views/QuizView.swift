import SwiftUI

struct QuizView: View {
    @Environment(QuizEngine.self) private var engine
    @Binding var showResetConfirmation: Bool
    @State private var selectedIndex: Int? = nil

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Header bar
                QuizHeaderBar(showResetConfirmation: $showResetConfirmation)

                if engine.phase == .generatingQuestion {
                    QuestionGeneratingView(status: engine.generationStatus)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let question = engine.currentQuestion {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Difficulty + round badge
                            if let session = engine.session, let round = session.currentRound {
                                HStack {
                                    DifficultyBadge(difficulty: round.difficulty)
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text("Round \(round.roundNumber)  •  \(round.questionsAnswered + 1)/5")
                                            .font(.caption.weight(.medium))
                                            .foregroundStyle(.secondary)
                                        if !round.subCategory.isEmpty {
                                            Text(round.subCategory)
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 16)
                            }

                            // Question card
                            Text(question.text)
                                .font(.title3.weight(.semibold))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 20)
                                .frame(maxWidth: .infinity)
                                .background(.background, in: RoundedRectangle(cornerRadius: 20))
                                .padding(.horizontal)

                            // Answer choices
                            VStack(spacing: 10) {
                                ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                                    AnswerButton(
                                        text: choice,
                                        index: index,
                                        state: answerButtonState(for: index, question: question)
                                    ) {
                                        guard case .awaitingAnswer = engine.phase else { return }
                                        selectedIndex = index
                                        Task { await engine.submitAnswer(choiceIndex: index) }
                                    }
                                }
                            }
                            .padding(.horizontal)

                            // Feedback card (shown inline after answer)
                            if case .showingFeedback(let isCorrect) = engine.phase,
                               let question = engine.currentQuestion {
                                let lastAnswer = engine.session?.rounds.last?.answers.last
                                FeedbackCard(
                                    isCorrect: isCorrect,
                                    explanation: question.explanation,
                                    disputeResult: lastAnswer?.disputeResult,
                                    isDisputePending: engine.isDisputePending,
                                    canDispute: !isCorrect && lastAnswer?.disputeResult == nil
                                ) {
                                    Task { await engine.disputeCurrentAnswer() }
                                }
                                .padding(.horizontal)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }

                            Spacer(minLength: 100)
                        }
                    }

                    // Sticky Next button shown during feedback
                    if case .showingFeedback = engine.phase {
                        FeedbackNextButton()
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
        .onChange(of: engine.currentQuestion?.id) { _, _ in
            withAnimation { selectedIndex = nil }
        }
    }

    private func answerButtonState(for index: Int, question: Question) -> AnswerButton.State {
        guard case .showingFeedback = engine.phase else {
            return selectedIndex == index ? .selected : .default
        }
        if index == question.correctIndex { return .correct }
        if index == selectedIndex { return .wrong }
        return .default
    }
}

private struct FeedbackNextButton: View {
    @Environment(QuizEngine.self) private var engine
    @State private var countdown = 10

    var body: some View {
        Button {
            Task { await engine.advanceFromFeedback() }
        } label: {
            HStack {
                Text("Next")
                    .font(.headline)
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.15), lineWidth: 2)
                    Circle()
                        .trim(from: 0, to: CGFloat(countdown) / 10)
                        .stroke(Color.primary.opacity(0.6), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: countdown)
                    Text("\(countdown)")
                        .font(.caption.monospacedDigit())
                }
                .frame(width: 28, height: 28)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(.tint, in: RoundedRectangle(cornerRadius: 16))
            .foregroundStyle(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
        .task {
            for i in stride(from: 10, through: 1, by: -1) {
                countdown = i
                if engine.isDisputePending {
                    // Dispute started — stop ticking; user taps Next after reading verdict
                    return
                }
                try? await Task.sleep(for: .seconds(1))
            }
            // Fire in a new unstructured task so it isn't cancelled
            // when this view disappears due to the phase change it triggers.
            Task { await engine.advanceFromFeedback() }
        }
    }
}

struct QuizHeaderBar: View {
    @Environment(QuizEngine.self) private var engine
    @Binding var showResetConfirmation: Bool

    var body: some View {
        HStack {
            // Score
            if let session = engine.session {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(session.totalCorrect)/\(session.totalAnswered)")
                        .font(.headline.monospacedDigit())
                    Text("score")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Topic label
            if let session = engine.session {
                Text(session.topicSelection.promptString)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 12) {
                // Reset button
                Button {
                    showResetConfirmation = true
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("Reset session")

                // Finish button
                Button {
                    Task { await engine.finishSession() }
                } label: {
                    Text("Finish")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                }
                .accessibilityLabel("Finish session and see results")
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.bar)
    }
}
