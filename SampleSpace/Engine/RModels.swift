import Foundation

/// One piece of code to run, plus the level checks to grade it with. Usually R; Python
/// Wormhole levels send Python (`language`), with checks written for `Python/checks.py`.
struct RJob: Sendable {
    /// The learner's code.
    var code: String
    /// Code calling the helpers in `R/checks.R` (or `Python/checks.py`). `nil` means "just run it".
    var checks: String?
    /// Code run silently in the learner's environment before their code (e.g. loading data).
    var setup: String?
    /// Passed to `set.seed()` just before the learner's code, so random results are repeatable.
    var seed: Int?
    /// How long the learner's code may run, in seconds.
    var timeLimit: Double = 10
    /// A folder of data files (CSV, .sav…) copied into the run's scratch folder, which is
    /// the learner's working directory, so `read_csv("file.csv")` finds them.
    var dataDirectory: URL?
    /// Console width R formats output to.
    var consoleWidth: Int = 80
    /// A file name such as `report.qmd`: the code is then a Quarto document, knitted rather
    /// than run line by line.
    var document: String?
    /// Which runner runs it.
    var language: CodeLanguage = .r
}

/// What happened when a job ran.
struct RRunResult: Sendable {
    enum Status: String, Sendable, Decodable {
        /// The code ran to the end.
        case ok
        /// The code stopped with an R error.
        case error
        /// R couldn't parse the code.
        case parseError = "parse_error"
        /// The code ran past its time limit and was stopped.
        case timeout
        /// The harness itself failed (bad level setup, R crashed, `quit()` bypassed…).
        case runnerError = "runner_error"
    }

    var status: Status
    var console: [ConsoleEntry]
    /// PNG data for each plot drawn, in order.
    var plots: [Data]
    var checks: [CheckResult]
    /// True when the code ran without an error and every check passed.
    var passed: Bool
    /// Seconds spent running the learner's code.
    var duration: Double
    /// For documents: the knitted Markdown (no YAML header); figures are `{{plot:N}}` lines.
    var document: String? = nil
    /// For documents: the title from the YAML header.
    var documentTitle: String? = nil

    var errorEntry: ConsoleEntry? { console.last(where: { $0.kind == .error }) }
    var hasInternalCheckErrors: Bool { checks.contains(where: \.internal) }
}

struct ConsoleEntry: Sendable, Hashable, Decodable {
    enum Kind: String, Sendable, Decodable {
        case input, output, message, warning, error
    }

    var kind: Kind
    var text: String
    /// The call an error or warning came from, when it is useful to show.
    var call: String?

    enum CodingKeys: String, CodingKey {
        case kind = "type", text, call
    }

    /// The entry as the R console would print it.
    var consoleText: String { consoleText(language: .r) }

    /// The entry as that language's console would print it. Python's runner sends errors and
    /// warnings as "KeyError: 'hours'" with `call` = "line 3".
    func consoleText(language: CodeLanguage) -> String {
        if language == .python {
            switch kind {
            case .input:
                return text.split(separator: "\n", omittingEmptySubsequences: false)
                    .enumerated()
                    .map { ($0.offset == 0 ? ">>> " : "... ") + $0.element }
                    .joined(separator: "\n")
            case .output, .message:
                return text
            case .warning:
                return call.map { "Warning on \($0): \(text)" } ?? "Warning: \(text)"
            case .error:
                return call.map { "Error on \($0): \(text)" } ?? "Error: \(text)"
            }
        }
        return switch kind {
        case .input:
            text.split(separator: "\n", omittingEmptySubsequences: false)
                .enumerated()
                .map { ($0.offset == 0 ? "> " : "+ ") + $0.element }
                .joined(separator: "\n")
        case .output, .message:
            text
        case .warning:
            call.map { "Warning in \($0): \(text)" } ?? "Warning: \(text)"
        case .error:
            call.map { "Error in \($0): \(text)" } ?? "Error: \(text)"
        }
    }
}

struct CheckResult: Sendable, Hashable, Decodable {
    var passed: Bool
    /// What was checked, for the checklist.
    var label: String
    /// Friendly feedback when the check failed.
    var message: String?
    /// The check itself failed to run. For a learner this is usually a missing object;
    /// when running a level's own solution it means the level is broken.
    var `internal`: Bool
    /// The Boss level step this check belongs to (1-based), set by `step(n)` in check.R.
    var step: Int? = nil
}

enum REngineError: Error, LocalizedError {
    case rscriptNotFound([String])
    case pythonNotFound([String])
    case runnerNotFound
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .rscriptNotFound(let paths):
            "Couldn't find R. Looked for Rscript at: \(paths.joined(separator: ", "))."
        case .pythonNotFound(let paths):
            "Python Wormhole levels need Python 3 with pandas, scipy, statsmodels and seaborn. "
                + "Couldn't find python3 at: \(paths.joined(separator: ", ")). Set its path in Settings → R & Python."
        case .runnerNotFound:
            "The R runner script is missing from the app bundle."
        case .launchFailed(let reason):
            "Couldn't start R: \(reason)"
        }
    }
}
