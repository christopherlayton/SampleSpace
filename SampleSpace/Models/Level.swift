import Foundation

/// The kinds of level in the plan.
///
/// - Code, Debug and SPSS Translate levels are played in the editor and checked by `check.R`.
///   A Debug level's starter is broken code to fix; an SPSS Translate level shows SPSS output
///   (the `spss` object) to reproduce in R.
/// - Briefing and Predict levels are quizzes (the `quiz` list); they need no R files.
/// - Lab levels have an instrument and goals (the `lab` object), then an R hand-off.
/// - Boss levels are a whole analysis in one script, in steps (the `steps` list): check.R marks
///   which checks belong to each step with `step(n)`, and each step opens when the one before
///   passes.
enum LevelType: String, Sendable, Codable, CaseIterable {
    case briefing, code, predict, debug
    case spssTranslate = "spss_translate"
    case lab, boss

    var displayName: String {
        switch self {
        case .briefing: "Briefing"
        case .code: "Code"
        case .predict: "Predict"
        case .debug: "Debug"
        case .spssTranslate: "SPSS Translate"
        case .lab: "Lab"
        case .boss: "Boss"
        }
    }

    var symbol: String {
        switch self {
        case .briefing: "book.pages"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .predict: "questionmark.bubble"
        case .debug: "ladybug"
        case .spssTranslate: "arrow.left.arrow.right"
        case .lab: "flask"
        case .boss: "flag.checkered"
        }
    }

    /// Played as multiple-choice questions rather than in the editor.
    var isQuiz: Bool { self == .briefing || self == .predict }

    /// The app can play this type (every type, since Step 14).
    var isPlayable: Bool { true }
}

/// One step of a Boss level, e.g. "Import" or "Write it up".
struct BossStep: Hashable, Sendable, Decodable {
    let title: String
    /// One line on what this step asks for, shown in the step bar.
    let summary: String?
}

/// One level, loaded from a folder under its sector:
///
///     level.json   id, title, summary, type, xp, par, hints, unlocks, time_limit, seed
///     lesson.md    briefing text (Markdown)
///     starter.R    what the editor starts with
///     solution.R   reference answer
///     check.R      checks, using the helpers in R/checks.R
///     setup.R      optional: run silently before the learner's code (e.g. load data)
///
/// Briefing and Predict levels have a `quiz` list in level.json instead of R files (see
/// `QuizQuestion`); their starter/solution/check files are optional and unused.
/// SPSS Translate levels have an `spss` object (see `SPSSPanel`), shown where lesson.md has a
/// `{{spss}}` line (or after the lesson if it has none).
/// A Lab level (`"type": "lab"`) also has a `lab` object in level.json (see `LabSpec`): the
/// instrument and its goals. Its starter/solution/check files are the "now do it in R" hand-off.
/// A level with `"document": "report.qmd"` is written as a Quarto document: its starter and
/// solution are `starter.qmd` and `solution.qmd`, and runs knit it (see `R/runner.R`).
/// A Boss level has `steps`, and its check.R groups checks with `step(n)`.
struct Level: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let summary: String
    let type: LevelType
    let xp: Int
    /// Runs at or under this count earn the third star.
    let par: Int
    let hints: [String]
    /// Level ids this one unlocks. `nil` means "the next level in the sector".
    let unlocks: [String]?
    let timeLimit: Double
    let seed: Int?
    /// The instrument and goals, for Lab levels.
    var lab: LabSpec? = nil
    /// The questions, for Briefing and Predict levels.
    var quiz: [QuizQuestion]? = nil
    /// The SPSS menu path, syntax and output, for SPSS Translate levels.
    var spss: SPSSPanel? = nil
    /// The steps, for Boss levels.
    var steps: [BossStep]? = nil
    /// The document's file name (e.g. `report.qmd`) when the level is a Quarto document.
    var document: String? = nil

    let lesson: String
    let starterCode: String
    let solutionCode: String
    let checkCode: String
    let setupCode: String?

    /// The folder the level was loaded from. Any data files in it are copied into R's
    /// working directory for each run.
    let folder: URL

    var isDocument: Bool { document != nil }

    /// A job that runs `code` the way this level expects, with or without its checks.
    /// Predict questions' code is always plain R, so pass `asDocument: false` for those.
    func job(code: String, check: Bool = true, asDocument: Bool = true) -> RJob {
        RJob(code: code, checks: check && !checkCode.isEmpty ? checkCode : nil, setup: setupCode, seed: seed,
             timeLimit: timeLimit, dataDirectory: folder, document: asDocument ? document : nil)
    }
}
