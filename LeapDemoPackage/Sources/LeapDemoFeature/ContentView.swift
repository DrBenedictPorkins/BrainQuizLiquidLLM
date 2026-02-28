import SwiftUI

public struct ContentView: View {
    @State private var engine = QuizEngine()
    @State private var showResetConfirmation = false
    @State private var showErrorDetail = false

    public init() {}

    public var body: some View {
        @Bindable var engine = engine
        Group {
            switch engine.phase {
            case .splash:
                SplashView()
            case .idle:
                TopicSelectionView()
            case .selectingDifficulty:
                DifficultySelectionView()
            case .generatingQuestion, .awaitingAnswer, .showingFeedback:
                QuizView(showResetConfirmation: $showResetConfirmation)
            case .generatingRoundSummary, .roundComplete:
                RoundSummaryView()
            case .generatingFinalSummary, .sessionComplete:
                FinalResultView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: engine.phase)
        .environment(engine)
        .confirmationDialog("Start over?", isPresented: $showResetConfirmation) {
            Button("Reset Session", role: .destructive) {
                engine.resetSession()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear the current session so another player can start fresh.")
        }
        .alert("LLM is misbehaving", isPresented: $engine.generationFailed) {
            Button("Try Again") { Task { await engine.retryGeneration() } }
            Button("Show Error") { showErrorDetail = true }
            Button("Finish Session", role: .destructive) { Task { await engine.finishSession() } }
        } message: {
            Text("Failed to generate a valid question after 3 attempts.")
        }
        .sheet(isPresented: $showErrorDetail) {
            ErrorDetailView(detail: engine.generationFailedDetail) {
                showErrorDetail = false
                Task { await engine.retryGeneration() }
            }
        }
    }
}

private struct ErrorDetailView: View {
    let detail: String
    let onRetry: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(detail)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .navigationTitle("Error Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retry") { onRetry() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        UIPasteboard.general.string = detail
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
}
