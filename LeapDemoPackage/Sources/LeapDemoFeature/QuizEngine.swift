import Foundation
import LeapSDK
import Observation

@Observable
@MainActor
final class QuizEngine {

    // MARK: - Model State
    var modelState: ModelState = .unloaded

    enum ModelState: Equatable {
        case unloaded
        case downloading(progress: Double)
        case loading
        case ready
        case failed(String)
    }

    // MARK: - Quiz State
    var session: GameSession?
    var currentQuestion: Question?
    var phase: QuizPhase = .splash
    var selectedModel: ModelConfig = .default
    var loadedModel: ModelConfig? = nil
    var generationError: String? = nil
    var generationStatus: String = ""
    var generationFailed: Bool = false
    var generationFailedDetail: String = ""
    var isDisputePending: Bool = false

    enum QuizPhase: Equatable {
        case splash
        case idle
        case selectingDifficulty
        case generatingQuestion
        case awaitingAnswer
        case showingFeedback(isCorrect: Bool)
        case generatingRoundSummary
        case roundComplete
        case generatingFinalSummary
        case sessionComplete
    }

    // MARK: - Private
    private(set) var pendingTopicSelection: TopicSelection?
    private var modelRunner: (any ModelRunner)?

    private enum GenerationError: Error {
        case noRunner
        case emptyList
        case invalidAnswers(String)
    }

    // MARK: - Model Loading

    func loadModel() async {
        guard modelState != .ready else {
            phase = .idle
            return
        }
        modelState = .downloading(progress: 0)
        do {
            modelRunner = try await Leap.load(
                model: selectedModel.modelId,
                quantization: selectedModel.quantization,
                downloadProgressHandler: { @Sendable [weak self] progress, _ in
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        if progress < 1.0 {
                            self.modelState = .downloading(progress: progress)
                        } else {
                            self.modelState = .loading
                        }
                    }
                }
            )
            loadedModel = selectedModel
            modelState = .ready
            phase = .idle
        } catch {
            modelState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Session Management

    func selectTopic(_ topicSelection: TopicSelection) {
        pendingTopicSelection = topicSelection
        phase = .selectingDifficulty
    }

    func startSession(topicSelection: TopicSelection, initialDifficulty: Difficulty) async {
        session = GameSession(topicSelection: topicSelection)
        pendingTopicSelection = nil
        phase = .generatingQuestion

        let topic = topicSelection.promptString
        var subCategories: [String] = []
        do {
            subCategories = try await generateSubCategories(topic: topic)
        } catch {
            // Fallback: single sub-category equal to the topic
        }

        if var s = session {
            s.subCategories = subCategories
            session = s
        }

        let firstSubCategory = subCategories.first ?? topic
        await startNewRound(difficulty: initialDifficulty, subCategory: firstSubCategory)
    }

    func resetSession() {
        session = nil
        currentQuestion = nil
        pendingTopicSelection = nil
        generationFailed = false
        generationFailedDetail = ""
        phase = .idle
    }

    func resetToSplash() {
        session = nil
        currentQuestion = nil
        pendingTopicSelection = nil
        generationFailed = false
        generationFailedDetail = ""
        phase = .splash
    }

    // MARK: - Answer Submission

    func submitAnswer(choiceIndex: Int) async {
        guard var session,
              let lastIndex = session.rounds.indices.last,
              let question = currentQuestion else { return }

        let record = AnswerRecord(question: question, selectedIndex: choiceIndex)
        session.rounds[lastIndex].answers.append(record)
        self.session = session

        let isCorrect = record.isCorrect
        phase = .showingFeedback(isCorrect: isCorrect)
    }

    func advanceFromFeedback() async {
        guard case .showingFeedback = phase,
              let session,
              let lastIndex = session.rounds.indices.last else { return }

        if session.rounds[lastIndex].isComplete {
            await generateRoundSummary()
        } else {
            await generateNextAnswer()
        }
    }

    // MARK: - Finish Early

    func finishSession() async {
        phase = .generatingFinalSummary
        await generateFinalSummary()
    }

    // MARK: - Round Management

    func continueToNextRound() async {
        guard let session,
              let lastRound = session.rounds.last,
              let summary = lastRound.summary else { return }

        let nextRoundNumber = session.rounds.count + 1
        let cats = session.subCategories
        let subCategory: String
        if cats.isEmpty {
            subCategory = session.topicSelection.promptString
        } else {
            subCategory = cats[(nextRoundNumber - 1) % cats.count]
        }

        await startNewRound(difficulty: summary.nextDifficulty, subCategory: subCategory)
    }

    private func startNewRound(difficulty: Difficulty, subCategory: String) async {
        guard var session else { return }
        let roundNumber = session.rounds.count + 1
        let newRound = Round(roundNumber: roundNumber, difficulty: difficulty, subCategory: subCategory)
        session.rounds.append(newRound)
        self.session = session

        phase = .generatingQuestion

        do {
            let questions = try await generateQuestionList(subCategory: subCategory, difficulty: difficulty)
            guard !questions.isEmpty else { throw GenerationError.emptyList }
            if let lastIndex = self.session?.rounds.indices.last {
                self.session?.rounds[lastIndex].pendingQuestionTexts = questions
            }
            await generateNextAnswer()
        } catch {
            generationError = "\(type(of: error)): \(error)"
            phase = .idle
        }
    }

    // MARK: - Generation

    private func logPrompt(phase: String, system: String, user: String, temp: Float) {
        print("""
        ┌─ [LLM] \(phase) (temp: \(temp))
        │  SYSTEM: \(system)
        │  USER:   \(user)
        └─────────────────────────────────────────
        """)
    }

    private func generateSubCategories(topic: String) async throws -> [String] {
        func attempt(temp: Float) async throws -> [String] {
            guard let runner = modelRunner else { throw GenerationError.noRunner }
            let userPrompt = PromptBuilder.subCategoriesPrompt(topic: topic)
            logPrompt(phase: "Phase 0 — Sub-categories", system: PromptBuilder.listSystemPrompt, user: userPrompt, temp: temp)
            let conversation = runner.createConversation(systemPrompt: PromptBuilder.listSystemPrompt)
            let options = GenerationOptions(temperature: temp, maxOutputTokens: 200)
            var output = ""
            for try await response in conversation.generateResponse(
                userTextMessage: userPrompt,
                generationOptions: options
            ) {
                if case .chunk(let text) = response { output += text }
            }
            let json = extractJSONArray(output)
            let result = try JSONDecoder().decode([String].self, from: Data(json.utf8))
            guard !result.isEmpty else { throw GenerationError.emptyList }
            return result
        }

        generationStatus = "Picking a topic angle..."
        do {
            return try await attempt(temp: 0.7)
        } catch {
            generationStatus = "Still thinking..."
            return try await attempt(temp: 0.9)
        }
    }

    private func generateQuestionList(subCategory: String, difficulty: Difficulty) async throws -> [String] {
        func attempt(temp: Float) async throws -> [String] {
            guard let runner = modelRunner else { throw GenerationError.noRunner }
            let userPrompt = PromptBuilder.questionsListPrompt(subCategory: subCategory, difficulty: difficulty)
            logPrompt(phase: "Phase 1 — Question list", system: PromptBuilder.listSystemPrompt, user: userPrompt, temp: temp)
            let conversation = runner.createConversation(systemPrompt: PromptBuilder.listSystemPrompt)
            let options = GenerationOptions(temperature: temp, maxOutputTokens: 400)
            var output = ""
            for try await response in conversation.generateResponse(
                userTextMessage: userPrompt,
                generationOptions: options
            ) {
                if case .chunk(let text) = response { output += text }
            }
            let json = extractJSONArray(output)
            let result = try JSONDecoder().decode([String].self, from: Data(json.utf8))
            guard !result.isEmpty else { throw GenerationError.emptyList }
            return Array(result.prefix(5))
        }

        generationStatus = "Writing your questions..."
        do {
            return try await attempt(temp: 1.0)
        } catch {
            generationStatus = "Finding better questions..."
            return try await attempt(temp: 1.2)
        }
    }

    private func generateNextAnswer() async {
        guard let session, let currentRound = session.currentRound else { return }
        let answerCount = currentRound.answers.count
        guard answerCount < currentRound.pendingQuestionTexts.count else { return }

        let questionText = currentRound.pendingQuestionTexts[answerCount]
        phase = .generatingQuestion

        let attempts: [(Float, String)] = [
            (0.8, "Crafting answer choices..."),
            (1.1, "Thinking a bit harder..."),
            (1.3, "One more try..."),
        ]

        var lastRawOutput = ""
        for (temp, status) in attempts {
            generationStatus = status
            do {
                let question = try await generateAnswers(
                    for: questionText,
                    difficulty: currentRound.difficulty,
                    subCategory: currentRound.subCategory,
                    temperature: temp
                )
                currentQuestion = question
                phase = .awaitingAnswer
                return
            } catch GenerationError.invalidAnswers(let raw) {
                lastRawOutput = raw
                continue
            } catch {
                generationError = "\(type(of: error)): \(error)"
                phase = .idle
                return
            }
        }

        // All 3 attempts exhausted
        generationFailedDetail = """
            Question: \(questionText)
            Difficulty: \(currentRound.difficulty.rawValue)
            Sub-category: \(currentRound.subCategory)
            Last LLM output:
            \(lastRawOutput)
            """
        generationFailed = true
    }

    func retryGeneration() async {
        generationFailed = false
        await generateNextAnswer()
    }

    // MARK: - Dispute

    func disputeCurrentAnswer() async {
        guard case .showingFeedback(let isCorrect) = phase,
              !isCorrect,
              !isDisputePending,
              var session,
              let lastRoundIndex = session.rounds.indices.last,
              let lastAnswerIndex = session.rounds[lastRoundIndex].answers.indices.last,
              let question = currentQuestion else { return }

        let record = session.rounds[lastRoundIndex].answers[lastAnswerIndex]
        let markedCorrect = question.choices[question.correctIndex]
        let userAnswer = question.choices[record.selectedIndex]

        isDisputePending = true

        let result = await generateDisputeVerdict(
            question: question.text,
            markedCorrect: markedCorrect,
            userAnswer: userAnswer
        )

        session.rounds[lastRoundIndex].answers[lastAnswerIndex].disputeResult = result
        if result.isUpheld {
            session.rounds[lastRoundIndex].answers[lastAnswerIndex].isCorrect = true
            self.session = session
            phase = .showingFeedback(isCorrect: true)
        } else {
            self.session = session
        }

        isDisputePending = false
    }

    private func generateDisputeVerdict(question: String, markedCorrect: String, userAnswer: String) async -> DisputeResult {
        guard let runner = modelRunner else { return .rejected(explanation: "Could not verify.") }
        let userPrompt = PromptBuilder.disputePrompt(question: question, markedCorrect: markedCorrect, userAnswer: userAnswer)
        logPrompt(phase: "Dispute", system: PromptBuilder.answersSystemPrompt, user: userPrompt, temp: 0.2)
        do {
            let conversation = runner.createConversation(systemPrompt: PromptBuilder.answersSystemPrompt)
            let options = GenerationOptions(temperature: 0.2, maxOutputTokens: 200)
            var output = ""
            for try await response in conversation.generateResponse(userTextMessage: userPrompt, generationOptions: options) {
                if case .chunk(let text) = response { output += text }
            }
            let verdict = try JSONDecoder().decode(GeneratedDisputeVerdict.self, from: Data(extractJSON(output).utf8))
            return verdict.upheld
                ? .upheld(explanation: verdict.explanation)
                : .rejected(explanation: verdict.explanation)
        } catch {
            return .rejected(explanation: "Verification failed.")
        }
    }

    private func generateAnswers(for questionText: String, difficulty: Difficulty, subCategory: String, temperature: Float = 0.8) async throws -> Question {
        guard let runner = modelRunner else { throw GenerationError.noRunner }
        let userPrompt = PromptBuilder.answersPrompt(question: questionText)
        logPrompt(phase: "Phase 2 — Answers", system: PromptBuilder.answersSystemPrompt, user: userPrompt, temp: temperature)
        let conversation = runner.createConversation(systemPrompt: PromptBuilder.answersSystemPrompt)
        let options = GenerationOptions(temperature: temperature, maxOutputTokens: 300)
        var output = ""
        for try await response in conversation.generateResponse(
            userTextMessage: userPrompt,
            generationOptions: options
        ) {
            if case .chunk(let text) = response { output += text }
        }
        let json = extractJSON(output)
        var answers: GeneratedAnswers
        do {
            answers = try JSONDecoder().decode(GeneratedAnswers.self, from: Data(json.utf8))
        } catch {
            throw GenerationError.invalidAnswers(output)
        }
        answers = GeneratedAnswers(
            correctAnswer: stripChoicePrefix(answers.correctAnswer),
            wrongAnswers: Array(answers.wrongAnswers.map { stripChoicePrefix($0) }.prefix(3)),
            explanation: answers.explanation
        )
        guard answers.wrongAnswers.count == 3 else {
            throw GenerationError.invalidAnswers(output)
        }
        return Question(text: questionText, answers: answers, difficulty: difficulty, topic: subCategory)
    }

    private func generateRoundSummary() async {
        guard let runner = modelRunner, var session, let currentRound = session.currentRound else { return }

        phase = .generatingRoundSummary

        let topic = session.topicSelection.promptString
        let prompt = PromptBuilder.roundSummaryPrompt(round: currentRound, topic: topic)
        logPrompt(phase: "Round Summary", system: PromptBuilder.summarySystemPrompt, user: prompt, temp: 0.6)

        do {
            let conversation = runner.createConversation(systemPrompt: PromptBuilder.summarySystemPrompt)
            let options = GenerationOptions(temperature: 0.6, maxOutputTokens: 600)
            var output = ""
            for try await response in conversation.generateResponse(userTextMessage: prompt, generationOptions: options) {
                if case .chunk(let text) = response { output += text }
            }
            let generated = try JSONDecoder().decode(GeneratedRoundSummary.self, from: Data(extractJSON(output).utf8))
            let summary = RoundSummary(from: generated, round: currentRound)
            if let lastIndex = session.rounds.indices.last {
                session.rounds[lastIndex].summary = summary
            }
            self.session = session
            phase = .roundComplete
        } catch {
            let fallbackGenerated = GeneratedRoundSummary(
                title: "Round Complete!",
                nextRoundRationale: "Keep going!",
                didYouKnowFacts: []
            )
            let fallback = RoundSummary(from: fallbackGenerated, round: currentRound)
            if let lastIndex = session.rounds.indices.last {
                session.rounds[lastIndex].summary = fallback
            }
            self.session = session
            phase = .roundComplete
        }
    }

    private func generateFinalSummary() async {
        guard let runner = modelRunner, var session else { return }

        let prompt = PromptBuilder.finalSummaryPrompt(session: session)
        logPrompt(phase: "Final Summary", system: PromptBuilder.summarySystemPrompt, user: prompt, temp: 0.6)

        do {
            let conversation = runner.createConversation(systemPrompt: PromptBuilder.summarySystemPrompt)
            let options = GenerationOptions(temperature: 0.6, maxOutputTokens: 400)
            var output = ""
            for try await response in conversation.generateResponse(userTextMessage: prompt, generationOptions: options) {
                if case .chunk(let text) = response { output += text }
            }
            let generated = try JSONDecoder().decode(GeneratedFinalSummary.self, from: Data(extractJSON(output).utf8))
            session.finalSummary = FinalSummary(from: generated, score: session.overallScore)
            self.session = session
            phase = .sessionComplete
        } catch {
            phase = .sessionComplete
        }
    }

    // MARK: - JSON Extraction

    private func stripCodeBlock(_ text: String) -> String {
        // Remove ```json ... ``` or ``` ... ``` wrappers the model sometimes adds
        guard let start = text.range(of: "```") else { return text }
        let afterFence = text[start.upperBound...]
        let contentStart = afterFence.drop(while: { $0.isLetter || $0 == "\n" })
        guard let end = contentStart.range(of: "```") else { return text }
        return String(contentStart[contentStart.startIndex..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractJSON(_ text: String) -> String {
        let cleaned = stripCodeBlock(text)
        guard let start = cleaned.firstIndex(of: "{") else { return cleaned }
        var depth = 0
        var inString = false
        var escaped = false
        var idx = start
        while idx < cleaned.endIndex {
            let c = cleaned[idx]
            if escaped { escaped = false }
            else if c == "\\" && inString { escaped = true }
            else if c == "\"" { inString.toggle() }
            else if !inString {
                if c == "{" { depth += 1 }
                else if c == "}" {
                    depth -= 1
                    if depth == 0 { return String(cleaned[start...idx]) }
                }
            }
            idx = cleaned.index(after: idx)
        }
        return cleaned
    }

    private func extractJSONArray(_ text: String) -> String {
        let cleaned = stripCodeBlock(text)
        guard let start = cleaned.firstIndex(of: "[") else { return cleaned }
        var depth = 0
        var inString = false
        var escaped = false
        var idx = start
        while idx < cleaned.endIndex {
            let c = cleaned[idx]
            if escaped { escaped = false }
            else if c == "\\" && inString { escaped = true }
            else if c == "\"" { inString.toggle() }
            else if !inString {
                if c == "[" { depth += 1 }
                else if c == "]" {
                    depth -= 1
                    if depth == 0 { return String(cleaned[start...idx]) }
                }
            }
            idx = cleaned.index(after: idx)
        }
        return cleaned
    }

    private func stripChoicePrefix(_ choice: String) -> String {
        let pattern = #"^[A-Da-d][.):\-]\s*"#
        if let range = choice.range(of: pattern, options: .regularExpression) {
            return String(choice[range.upperBound...])
        }
        return choice
    }
}
