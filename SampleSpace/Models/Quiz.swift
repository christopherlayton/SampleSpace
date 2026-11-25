import Foundation

/// One multiple-choice question in a Briefing or Predict level, from the `quiz` list in
/// level.json:
///
///     "quiz": [
///       { "prompt": "What will R print?",
///         "code": "c(1, \"a\", TRUE)",
///         "choices": ["[1] 1 \"a\" TRUE", "[1] \"1\"    \"a\"    \"TRUE\""],
///         "answer": 1,
///         "explain": "A vector holds one type, so everything becomes text." }
///     ]
///
/// - `answer` is the 0-based index of the right choice.
/// - `code` (Predict levels) is shown read-only and run in real R once the answer is locked in,
///   so the learner sees the actual output. The validator checks that the right choice matches
///   what R prints, unless `"match_output": false` (for questions like "what type is it?").
/// - `choices_are_code` shows the choices in a monospaced font (default: on when there is code).
struct QuizQuestion: Hashable, Sendable, Decodable {
    let prompt: String
    var code: String?
    let choices: [String]
    let answer: Int
    var explain: String?
    var matchOutput: Bool?
    var choicesAreCode: Bool?

    var showsChoicesAsCode: Bool { choicesAreCode ?? (code != nil) }
}

/// Where a quiz attempt stands: which question is showing, what was picked, and how many
/// answers were locked in. Wrong picks are remembered (and greyed out) so a retry is a new
/// choice. Pure state, so it can be tested without the UI.
struct QuizProgress: Equatable, Sendable {
    let questions: [QuizQuestion]
    private(set) var index = 0
    /// Locked-in wrong choices, per question.
    private(set) var wrong: [Int: Set<Int>] = [:]
    /// Questions answered correctly.
    private(set) var solved: Set<Int> = []
    /// Every lock-in, right or wrong (the quiz's equivalent of pressing Check).
    private(set) var attempts = 0
    var selection: Int?

    init(questions: [QuizQuestion]) { self.questions = questions }

    var current: QuizQuestion? { questions.indices.contains(index) ? questions[index] : nil }
    var currentSolved: Bool { solved.contains(index) }
    var finished: Bool { !questions.isEmpty && solved.count == questions.count }
    var isLast: Bool { index == questions.count - 1 }
    func wrongChoices(_ question: Int) -> Set<Int> { wrong[question] ?? [] }
    func isSolved(_ question: Int) -> Bool { solved.contains(question) }
    /// Questions are answered in order, so this is also the furthest question you can open.
    var solvedCount: Int { solved.count }

    enum LockResult: Equatable { case right, wrong, ignored }

    /// Locks in the selected choice for the current question.
    @discardableResult
    mutating func lockIn() -> LockResult {
        guard let question = current, let pick = selection, !currentSolved,
              question.choices.indices.contains(pick), !wrongChoices(index).contains(pick) else { return .ignored }
        attempts += 1
        if pick == question.answer {
            solved.insert(index)
            return .right
        }
        wrong[index, default: []].insert(pick)
        selection = nil
        return .wrong
    }

    /// Moves on once the current question is answered.
    mutating func next() {
        guard currentSolved, index + 1 < questions.count else { return }
        index += 1
        selection = nil
    }

    /// Goes back to look at an earlier question (answered ones stay answered).
    mutating func go(to question: Int) {
        guard questions.indices.contains(question), question <= solvedCount else { return }
        index = question
        selection = currentSolved ? questions[question].answer : nil
    }
}
