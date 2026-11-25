import Foundation
import Observation

/// The working state of one code level: the learner's code, the last run's output, and the
/// attempt counters that decide the stars.
@MainActor @Observable
final class LevelSession {
    enum OutputTab: String, CaseIterable, Identifiable {
        case console, plots, checks
        var id: Self { self }
    }

    enum Activity: Equatable { case idle, running, checking }

    /// What the completion card shows.
    struct Completion: Equatable {
        var score: StarScore
        var xp: Int
        var firstClear: Bool
    }

    let level: Level
    var code: String

    // Last run
    private(set) var console: [ConsoleEntry] = []
    private(set) var plots: [Data] = []
    private(set) var checks: [CheckResult] = []
    private(set) var lastStatus: RRunResult.Status?
    private(set) var lastDuration: Double?
    private(set) var lastRunWasCheck = false
    private(set) var activity: Activity = .idle
    var outputTab: OutputTab = .console
    var selectedPlot = 0

    // Attempt
    private(set) var hintsShown = 0
    private(set) var solutionShown = false
    private(set) var checkAttempts = 0
    private(set) var runCount = 0
    var completion: Completion?

    private let engine: REngine?
    let engineError: String?
    private let onPass: (Int) -> Bool
    private var task: Task<Void, Never>?
    /// Bumped for every run, so a cancelled run that finishes late can't overwrite a newer one.
    private var generation = 0

    init(level: Level, engine: REngine?, engineError: String?, onPass: @escaping (Int) -> Bool) {
        self.level = level
        self.code = level.starterCode
        self.engine = engine
        self.engineError = engineError
        self.onPass = onPass
    }

    var isBusy: Bool { activity != .idle }
    var allHintsShown: Bool { hintsShown >= level.hints.count }
    var isStarterCode: Bool { code == level.starterCode }

    var score: StarScore {
        StarScore(passed: true, hintsUsed: hintsShown, solutionShown: solutionShown,
                  checkAttempts: checkAttempts, par: level.par)
    }

    // MARK: Actions

    func run() { start(check: false) }
    func check() { start(check: true) }

    private func start(check: Bool) {
        task?.cancel()
        task = Task { await perform(check: check) }
    }

    /// Runs the code (and, for Check, the level's checks) and updates the output.
    func perform(check: Bool) async {
        guard let engine else {
            console = [ConsoleEntry(kind: .error, text: engineError ?? "R isn't available.")]
            outputTab = .console
            return
        }
        generation += 1
        let thisRun = generation
        activity = check ? .checking : .running
        if check { checkAttempts += 1 } else { runCount += 1 }
        defer { if generation == thisRun { activity = .idle } }

        let result: RRunResult
        do {
            result = try await engine.run(level.job(code: code, check: check))
        } catch is CancellationError {
            return
        } catch {
            guard generation == thisRun else { return }
            console = [ConsoleEntry(kind: .error, text: error.localizedDescription)]
            plots = []
            lastStatus = .runnerError
            outputTab = .console
            return
        }
        guard !Task.isCancelled, generation == thisRun else { return }

        console = result.console
        plots = result.plots
        selectedPlot = 0
        lastStatus = result.status
        lastDuration = result.duration
        lastRunWasCheck = check
        if check {
            checks = result.checks
            outputTab = .checks
            if result.passed {
                let score = self.score
                let firstClear = onPass(score.stars)
                completion = Completion(score: score, xp: level.xp, firstClear: firstClear)
            }
        } else {
            outputTab = result.status == .ok && !plots.isEmpty ? .plots : .console
        }
    }

    func showHint() {
        guard !allHintsShown else { return }
        hintsShown += 1
    }

    func showSolution() {
        hintsShown = level.hints.count
        solutionShown = true
    }

    /// Puts the starter code back. Hints and checks used so far still count.
    func reset() {
        code = level.starterCode
    }

    /// Starts the level over for a better score: starter code, no hints, no checks used.
    func replay() {
        cancel()
        code = level.starterCode
        console = []
        plots = []
        checks = []
        lastStatus = nil
        lastDuration = nil
        hintsShown = 0
        solutionShown = false
        checkAttempts = 0
        runCount = 0
        completion = nil
        outputTab = .console
    }

    /// Stops a run in progress (R is killed by the engine).
    func cancel() {
        task?.cancel()
        task = nil
        generation += 1
        if activity != .idle {
            console = [ConsoleEntry(kind: .message, text: "Run stopped.")]
            outputTab = .console
        }
        activity = .idle
    }
}
