import Foundation

enum PromptBuilder {

    // MARK: - System Prompts

    static let listSystemPrompt = "Output ONLY a JSON array. No prose, no markdown, no extra text before or after."
    static let answersSystemPrompt = "Output ONLY a JSON object. No prose, no markdown, no extra text before or after."
    static let summarySystemPrompt = "Output ONLY a JSON object. No prose, no markdown, no extra text before or after."

    // MARK: - Phase 0: Sub-categories

    static func subCategoriesPrompt(topic: String) -> String {
        """
        Topic: "\(topic)"
        List 5 distinct sub-areas of this topic, each specific enough for 5 unique quiz questions.
        Example for "History": ["Ancient Rome","World War II","The Renaissance","The Cold War","Ancient Egypt"]
        Output for "\(topic)":
        """
    }

    // MARK: - Phase 1: Question list

    static func questionsListPrompt(subCategory: String, difficulty: Difficulty) -> String {
        """
        Sub-category: "\(subCategory)"
        Difficulty: \(difficulty.rawValue) — \(difficulty.promptDescription)
        Write 5 trivia quiz questions about this sub-category. Rules:
        - Each question must have exactly ONE short, definitive correct answer (a name, date, number, or fact)
        - Questions must be answerable with a single word or short phrase — suitable for multiple choice
        - Do NOT write recipe, how-to, list, or open-ended questions
        - Each must end with "?"
        Example: ["What year did the first iPhone release?","Who invented the telephone?","What gas makes up most of Earth's atmosphere?","How many bones are in the human body?","Which planet is closest to the Sun?"]
        Output 5 questions about "\(subCategory)":
        """
    }

    // MARK: - Phase 2: Answers

    static func answersPrompt(question: String) -> String {
        """
        Example:
        Question: "Which planet is closest to the Sun?"
        {"correctAnswer":"Mercury","wrongAnswers":["Venus","Mars","Earth"],"explanation":"Mercury orbits just 57.9 million km from the Sun, closer than any other planet."}

        Now answer:
        Question: "\(question)"
        """
    }

    // MARK: - Round summary

    static func roundSummaryPrompt(round: Round, topic: String) -> String {
        let scoreStr = "\(round.correctCount)/\(round.questionsAnswered)"
        let wrongList = round.wrongAnswers.map { record in
            "- \(record.question.text) (correct: \(record.question.choices[record.question.correctIndex]))"
        }.joined(separator: "\n")

        let factsInstruction = wrongList.isEmpty
            ? "Since all answers were correct, output an empty didYouKnowFacts array."
            : "For each wrong answer, write a surprising \"Did you know\" fact about the broader topic — the fact must NOT restate the correct answer, it must reveal something unexpected or lesser-known about that subject."

        return """
        Round \(round.roundNumber) of a quiz on "\(round.subCategory)" (topic: "\(topic)"): score \(scoreStr) (\(Int(round.scorePercent * 100))%).
        Questions answered wrong: \(wrongList.isEmpty ? "none" : "\n" + wrongList)
        Write a round summary JSON with: a short encouraging title (4-6 words), one encouraging sentence about the round. \(factsInstruction)
        Example for a wrong answer on "Which planet is closest to the Sun?": the fact should NOT say "Mercury is closest to the Sun" — instead say something like "Did you know Mercury has no atmosphere, so surface temperatures swing from -180°C at night to 430°C during the day?"
        Example output with facts: {"title":"Great effort!","nextRoundRationale":"You showed real focus on this round!","didYouKnowFacts":[{"questionText":"Which planet is closest to the Sun?","fact":"Did you know Mercury has no atmosphere, so temperatures swing from -180°C at night to 430°C during the day?"}]}
        Example output with no wrong answers: {"title":"Perfect round!","nextRoundRationale":"You nailed every question!","didYouKnowFacts":[]}
        Output the JSON for Round \(round.roundNumber):
        """
    }

    // MARK: - Dispute

    static func disputePrompt(question: String, markedCorrect: String, userAnswer: String) -> String {
        """
        Fact-check this quiz answer:
        Question: "\(question)"
        Answer marked as correct by the quiz: "\(markedCorrect)"
        User's answer: "\(userAnswer)"
        Is "\(markedCorrect)" actually the correct answer? If the quiz answer is wrong and the user's answer is right, set upheld to true.
        Example (dispute upheld): {"upheld":true,"explanation":"Humans have 4 limbs (2 arms, 2 legs), not 10 — 10 is the number of fingers."}
        Example (dispute rejected): {"upheld":false,"explanation":"Mercury is indeed the closest planet to the Sun, orbiting at just 57.9 million km."}
        Output JSON:
        """
    }

    // MARK: - Final summary

    static func finalSummaryPrompt(session: GameSession) -> String {
        let roundBreakdown = session.rounds.enumerated().map { i, round in
            "Round \(i + 1) (\(round.subCategory), \(round.difficulty.displayName)): \(round.correctCount)/\(round.questionsAnswered)"
        }.joined(separator: "\n")

        return """
        Quiz on "\(session.topicSelection.promptString)": \(session.totalCorrect)/\(session.totalAnswered) (\(Int(session.overallScore * 100))%).
        \(roundBreakdown)
        Write a final quiz summary JSON with: an encouraging title (5-8 words), 2-3 sentences on strengths, and 1-2 sentences on areas to improve, and one concrete recommendation.
        Example: {"title":"Solid performance today!","strengths":"You showed strong recall on most topics.","areasToImprove":"Review the questions you missed to reinforce those concepts.","recommendation":"Try a harder difficulty next time."}
        Output the JSON summary:
        """
    }
}
