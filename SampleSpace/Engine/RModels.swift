import Foundation

/// One piece of R code to run, plus the level checks to grade it with.
struct RJob: Sendable {
    /// The learner's code.
    var code: String
    /// R code calling the helpers in `R/checks.R`. `nil` means "just run it".
    var checks: String?
    /// Code run silently in the learner's environment before their code (e.g. loading data).
    var setup: String?
    /// Passed to `set.seed()` just before the learner's code, so random results are repeatable.
    var seed: Int?
    /// How long the learner's code may run, in seconds.
    var timeLimit: Double = 10
    /// Working directory for the learner's code. Defaults to the run's scratch folder.
    var workingDirectory: URL?
    /// Console width R formats output to.
    var consoleWidth: Int = 80
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
    var consoleText: String {
        switch kind {
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
}

enum REngineError: Error, LocalizedError {
    case rscriptNotFound([String])
    case runnerNotFound
    case launchFailed(String)

    var errorDescription: String? {
        switch self {
        case .rscriptNotFound(let paths):
            "Couldn't find R. Looked for Rscript at: \(paths.joined(separator: ", "))."
        case .runnerNotFound:
            "The R runner script is missing from the app bundle."
        case .launchFailed(let reason):
            "Couldn't start R: \(reason)"
        }
    }
}
