import Foundation

/// The kinds of level in the plan. `.code` and `.lab` are playable; the others arrive in
/// later steps (Briefing/Predict/Debug/SPSS Translate in Step 8, Boss in Step 14).
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
/// A Lab level (`"type": "lab"`) also has a `lab` object in level.json (see `LabSpec`): the
/// instrument and its goals. Its starter/solution/check files are the "now do it in R" hand-off.
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

    let lesson: String
    let starterCode: String
    let solutionCode: String
    let checkCode: String
    let setupCode: String?

    /// The folder the level was loaded from. Any data files in it are copied into R's
    /// working directory for each run.
    let folder: URL

    /// A job that runs `code` the way this level expects, with or without its checks.
    func job(code: String, check: Bool = true) -> RJob {
        RJob(code: code, checks: check ? checkCode : nil, setup: setupCode, seed: seed,
             timeLimit: timeLimit, dataDirectory: folder)
    }
}
