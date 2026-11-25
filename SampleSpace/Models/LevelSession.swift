import Foundation
import Observation

/// The working state of one level: the learner's code, the last run's output, and the attempt
/// counters that decide the stars. For a Lab level it also holds the running instrument and the
/// lab goals reached; Check stays locked until every goal is reached. For a quiz level
/// (Briefing, Predict) it holds the answers so far and, for Predict, what R really printed.
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
        var outcome: GameModel.ClearOutcome
    }

    let level: Level
    var code: String {
        didSet { if code != oldValue { model?.draftChanged(level: level, code: code) } }
    }
    /// Receives practice, clears and drafts. Set by `GameModel.session(for:)`.
    @ObservationIgnored weak var model: GameModel?

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
    /// The code hit an R error at some point in this attempt (for the Bug Hunter badge).
    private(set) var hadErrorThisAttempt = false
    var completion: Completion?

    // Lab
    /// The running instrument, for Lab levels.
    @ObservationIgnored private(set) lazy var instrument: LabInstrument? = LabInstrument.make(for: level)
    private(set) var labGoals: LabGoalTracker
    /// Which stage of a lab level is showing: the instrument, or "now do it in R".
    var labStage: LabStage = .lab

    enum LabStage: Hashable { case lab, r }

    // Quiz
    private(set) var quiz: QuizProgress
    /// What R printed for each Predict question, once its answer was locked in.
    private(set) var quizOutputs: [Int: [ConsoleEntry]] = [:]
    /// The Predict question whose code R is running now.
    private(set) var quizRunning: Int?
    private var quizTask: Task<Void, Never>?

    private let engine: REngine?
    let engineError: String?
    private var task: Task<Void, Never>?
    /// Bumped for every run, so a cancelled run that finishes late can't overwrite a newer one.
    private var generation = 0

    init(level: Level, engine: REngine?, engineError: String?, draft: String? = nil) {
        self.level = level
        self.code = draft ?? level.starterCode
        self.engine = engine
        self.engineError = engineError
        labGoals = LabGoalTracker(goals: level.lab?.goals ?? [])
        quiz = QuizProgress(questions: level.quiz ?? [])
    }

    var isBusy: Bool { activity != .idle }
    var allHintsShown: Bool { hintsShown >= level.hints.count }
    var isStarterCode: Bool { code == level.starterCode }
    var isLab: Bool { level.lab != nil }
    var isQuiz: Bool { level.type.isQuiz }

    /// Check is open: always for code levels; for labs once every goal is reached (or the
    /// level was cleared before).
    var labReady: Bool {
        !isLab || labGoals.allReached || model?.bestStars(level.id) != nil
    }

    /// Feeds fresh instrument readings to the goals. Returns the goals reached just now.
    @discardableResult
    func updateLab(readings: [String: Double]) -> [Int] {
        guard isLab else { return [] }
        var goals = labGoals
        let newly = goals.update(readings)
        if !newly.isEmpty { labGoals = goals }
        return newly
    }

    var score: StarScore {
        StarScore(passed: true, hintsUsed: hintsShown, solutionShown: solutionShown,
                  checkAttempts: isQuiz ? quiz.attempts : checkAttempts, par: level.par,
                  attemptNoun: isQuiz ? "answer" : "check")
    }

    // MARK: Actions

    func run() { start(check: false) }
    func check() {
        guard labReady else { return }
        start(check: true)
    }

    private func start(check: Bool) {
        task?.cancel()
        task = Task { await perform(check: check) }
    }

    /// Runs the code (and, for Check, the level's checks) and updates the output.
    func perform(check: Bool) async {
        if check, !labReady { return }
        guard let engine else {
            console = [ConsoleEntry(kind: .error, text: engineError ?? "R isn't available.")]
            outputTab = .console
            return
        }
        generation += 1
        let thisRun = generation
        activity = check ? .checking : .running
        if check {
            checkAttempts += 1
            model?.recordCheck()
        } else {
            runCount += 1
        }
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
        model?.recordRun(drewPlot: !result.plots.isEmpty)
        if result.status != .ok, result.status != .runnerError { hadErrorThisAttempt = true }
        if check {
            checks = result.checks
            outputTab = .checks
            if result.passed, let model {
                let score = self.score
                let outcome = model.recordClear(level: level, score: score, code: code,
                                                hadErrorThisAttempt: hadErrorThisAttempt)
                completion = Completion(score: score, outcome: outcome)
            }
        } else {
            outputTab = result.status == .ok && !plots.isEmpty ? .plots : .console
        }
    }

    // MARK: Quiz

    /// Picks a choice for the current question (before it is answered).
    func select(_ choice: Int) {
        guard !quiz.currentSolved, !quiz.wrongChoices(quiz.index).contains(choice) else { return }
        quiz.selection = choice
    }

    /// Locks in the selected choice. A right answer to a Predict question runs its code in R so
    /// the real output appears next to the prediction.
    func lockInAnswer() {
        let question = quiz.index
        let result = quiz.lockIn()
        guard result != .ignored else { return }
        model?.recordCheck()
        if result == .right { runQuizCode(question) }
    }

    func nextQuestion() { quiz.next() }
    func goToQuestion(_ index: Int) { quiz.go(to: index) }

    /// Records the clear once every question is answered.
    func finishQuiz() {
        guard quiz.finished, completion == nil, let model else { return }
        let score = self.score
        let outcome = model.recordClear(level: level, score: score, code: "", hadErrorThisAttempt: false)
        completion = Completion(score: score, outcome: outcome)
    }

    private func runQuizCode(_ question: Int) {
        let q = quiz.questions[question]
        guard q.runsCode, let code = q.code, quizOutputs[question] == nil else { return }
        guard let engine else {
            quizOutputs[question] = [ConsoleEntry(kind: .error, text: engineError ?? "R isn't available.")]
            return
        }
        quizRunning = question
        quizTask = Task {
            let entries: [ConsoleEntry]
            do {
                entries = try await engine.run(level.job(code: code, check: false)).console
            } catch {
                entries = [ConsoleEntry(kind: .error, text: error.localizedDescription)]
            }
            guard !Task.isCancelled else { return }
            quizOutputs[question] = entries
            if quizRunning == question { quizRunning = nil }
        }
    }

    /// Waits for a Predict question's R run (for tests).
    func waitForQuizRun() async { await quizTask?.value }

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
    /// Lab goals already reached stay reached (the stars are earned in the R part).
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
        hadErrorThisAttempt = false
        completion = nil
        outputTab = .console
        quiz = QuizProgress(questions: level.quiz ?? [])
    }

    /// Stops a run in progress (R is killed by the engine).
    func cancel() {
        task?.cancel()
        task = nil
        quizTask?.cancel()
        quizRunning = nil
        instrument?.stop()
        generation += 1
        if activity != .idle {
            console = [ConsoleEntry(kind: .message, text: "Run stopped.")]
            outputTab = .console
        }
        activity = .idle
    }
}
