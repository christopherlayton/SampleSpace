import Foundation
import Synchronization

/// Runs learner code in the system R (and, for Python Wormhole levels, the system Python).
///
/// Each run is a fresh `Rscript runner.R job.json` process with its own scratch folder,
/// so runs can't leak objects into each other. `runner.R` enforces the time limit for
/// ordinary R loops; this actor is the backstop for code R can't interrupt (long
/// `Sys.sleep()`, C code, a learner calling `setTimeLimit()`), killing the process a
/// little after the limit.
///
/// A job whose `language` is `.python` runs `python3 -X utf8 runner.py job.json` instead
/// (`Python/runner.py`, the same job and result files). Python is optional: without it the
/// engine still runs R, and Python jobs throw `REngineError.pythonNotFound`.
actor REngine {
    static let rscriptCandidates = [
        "/usr/local/bin/Rscript",
        "/opt/homebrew/bin/Rscript",
        "/Library/Frameworks/R.framework/Resources/bin/Rscript",
    ]

    /// Where python3 usually is. (Not /usr/bin/python3: that's the Command Line Tools stub,
    /// which may offer to install the tools instead of running.)
    static let pythonCandidates = [
        "/usr/local/bin/python3",
        "/opt/homebrew/bin/python3",
        "/Library/Frameworks/Python.framework/Versions/Current/bin/python3",
    ]

    /// Extra time R gets to start up and write its result before the process is killed.
    static let killGrace: Double = 3

    nonisolated let rscriptURL: URL
    let runnerURL: URL
    /// Python, for Python Wormhole levels; nil when it wasn't found.
    nonisolated let pythonURL: URL?
    let pythonRunnerURL: URL?
    private let pythonLookedAt: [String]
    private let scratchRoot: URL

    init(rscriptPath: String? = nil, runnerURL: URL? = nil,
         pythonPath: String? = nil, pythonRunnerURL: URL? = nil) throws {
        let fm = FileManager.default
        let candidates = rscriptPath.map { [$0] } ?? Self.rscriptCandidates
        guard let path = candidates.first(where: { fm.isExecutableFile(atPath: $0) }) else {
            throw REngineError.rscriptNotFound(candidates)
        }
        guard let runner = runnerURL ?? Bundle.main.url(forResource: "runner", withExtension: "R",
                                                        subdirectory: "R") else {
            throw REngineError.runnerNotFound
        }
        rscriptURL = URL(filePath: path)
        self.runnerURL = runner
        pythonLookedAt = pythonPath.map { [$0] } ?? Self.pythonCandidates
        pythonURL = pythonLookedAt.first(where: { fm.isExecutableFile(atPath: $0) }).map { URL(filePath: $0) }
        self.pythonRunnerURL = pythonRunnerURL ?? Bundle.main.url(forResource: "runner", withExtension: "py",
                                                                  subdirectory: "Python")
        scratchRoot = fm.temporaryDirectory.appending(path: "SampleSpace-runs", directoryHint: .isDirectory)
    }

    func run(_ job: RJob) async throws -> RRunResult {
        let fm = FileManager.default
        let executable: URL
        var arguments: [String]
        switch job.language {
        case .r:
            executable = rscriptURL
            arguments = ["--no-init-file", runnerURL.path]
        case .python:
            guard let pythonURL else { throw REngineError.pythonNotFound(pythonLookedAt) }
            guard let pythonRunnerURL else { throw REngineError.runnerNotFound }
            executable = pythonURL
            arguments = ["-X", "utf8", pythonRunnerURL.path]
        }
        let runDir = scratchRoot.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try fm.createDirectory(at: runDir, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: runDir) }

        let jobURL = runDir.appending(path: "job.json")
        try JSONEncoder().encode(JobFile(job: job, outputDir: runDir.path)).write(to: jobURL)

        let logURL = runDir.appending(path: "rscript.log")
        fm.createFile(atPath: logURL.path, contents: nil)
        let log = try FileHandle(forWritingTo: logURL)
        defer { try? log.close() }

        let process = Process()
        arguments.append(jobURL.path)
        process.executableURL = executable
        process.arguments = arguments
        process.currentDirectoryURL = runDir
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = log
        process.standardError = log
        var environment = ProcessInfo.processInfo.environment
        environment["LANG"] = "en_US.UTF-8"
        environment["LC_ALL"] = "en_US.UTF-8"
        environment["LANGUAGE"] = "en"
        environment["PYTHONDONTWRITEBYTECODE"] = "1"
        environment["PYTHONIOENCODING"] = "utf-8"
        process.environment = environment

        let watchdog = Watchdog()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                process.terminationHandler = { _ in continuation.resume() }
                do {
                    try process.run()
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: REngineError.launchFailed(error.localizedDescription))
                    return
                }
                watchdog.arm(pid: process.processIdentifier, after: job.timeLimit + Self.killGrace)
            }
        } onCancel: {
            watchdog.kill(reason: .cancelled)
        }
        watchdog.disarm()
        try Task.checkCancellation()

        let resultURL = runDir.appending(path: "result.json")
        if watchdog.reason == .timedOut {
            return Self.killedResult(job: job)
        }
        guard let data = try? Data(contentsOf: resultURL),
              let file = try? JSONDecoder().decode(ResultFile.self, from: data) else {
            let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
            return Self.failedResult(exitCode: process.terminationStatus, log: logText, language: job.language)
        }
        let plots = file.plots.compactMap { try? Data(contentsOf: runDir.appending(path: $0)) }
        return RRunResult(status: file.status, console: file.console, plots: plots,
                          checks: file.checks, passed: file.passed, duration: file.duration,
                          document: file.document, documentTitle: file.title)
    }

    private static func killedResult(job: RJob) -> RRunResult {
        let limit = job.timeLimit.formatted(.number.precision(.fractionLength(0...1)))
        let message = "Your code ran for more than \(limit) second\(job.timeLimit == 1 ? "" : "s") "
            + "and \(job.language.displayName) couldn't stop it on its own, so Sample Space ended it. "
            + "Look for a loop that never ends or a very long Sys.sleep()."
        return RRunResult(status: .timeout, console: [ConsoleEntry(kind: .error, text: message)],
                          plots: [], checks: [], passed: false, duration: job.timeLimit)
    }

    private static func failedResult(exitCode: Int32, log: String, language: CodeLanguage) -> RRunResult {
        let tail = log.split(separator: "\n").suffix(15).joined(separator: "\n")
        var message = "\(language.displayName) stopped without finishing (exit code \(exitCode))."
        if !tail.isEmpty { message += "\n\(tail)" }
        return RRunResult(status: .runnerError, console: [ConsoleEntry(kind: .error, text: message)],
                          plots: [], checks: [], passed: false, duration: 0)
    }
}

// MARK: - Files exchanged with runner.R

private struct JobFile: Encodable {
    let code: String
    let checks: String?
    let setup: String?
    let seed: Int?
    let timeLimit: Double
    let dataDir: String?
    let width: Int
    let outputDir: String
    let document: String?

    init(job: RJob, outputDir: String) {
        code = job.code
        checks = job.checks
        setup = job.setup
        seed = job.seed
        timeLimit = job.timeLimit
        dataDir = job.dataDirectory?.path
        width = job.consoleWidth
        self.outputDir = outputDir
        document = job.document
    }

    enum CodingKeys: String, CodingKey {
        case code, checks, setup, seed, width, document
        case timeLimit = "time_limit"
        case dataDir = "data_dir"
        case outputDir = "output_dir"
    }
}

private struct ResultFile: Decodable {
    let status: RRunResult.Status
    let console: [ConsoleEntry]
    let plots: [String]
    let checks: [CheckResult]
    let passed: Bool
    let duration: Double
    let document: String?
    let title: String?
}

// MARK: - Watchdog

/// Kills an R process that runs too long or whose task is cancelled.
private final class Watchdog: Sendable {
    enum Reason: Sendable { case timedOut, cancelled }

    private struct State {
        var pid: pid_t?
        var finished = false
        var reason: Reason?
        var cancelledEarly = false
        var timer: Task<Void, Never>?
    }

    private let state = Mutex(State())

    var reason: Reason? { state.withLock { $0.reason } }

    func arm(pid: pid_t, after seconds: Double) {
        let timer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled else { return }
            self?.kill(reason: .timedOut)
        }
        let killNow = state.withLock { s in
            s.pid = pid
            s.timer = timer
            return s.cancelledEarly
        }
        if killNow { kill(reason: .cancelled) }
    }

    func kill(reason: Reason) {
        let pid: pid_t? = state.withLock { s in
            guard !s.finished, s.reason == nil else { return nil }
            guard let pid = s.pid else {
                if reason == .cancelled { s.cancelledEarly = true }
                return nil
            }
            s.reason = reason
            return pid
        }
        guard let pid else { return }
        Darwin.kill(pid, SIGTERM)
        // Give R a moment to exit cleanly, then make sure.
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            let stillRunning = state.withLock { !$0.finished }
            if stillRunning { Darwin.kill(pid, SIGKILL) }
        }
    }

    func disarm() {
        let timer = state.withLock { s in
            s.finished = true
            return s.timer
        }
        timer?.cancel()
    }
}
