import Foundation
import Observation

/// App-wide state: the loaded content, the R engine, navigation, and the pilot's saved progress
/// (stars, XP, rank, fuel and streak, badges, unlocked levels and code drafts).
@MainActor @Observable
final class GameModel {
    private(set) var library: ContentLibrary?
    private(set) var loadError: String?
    private(set) var engine: REngine?
    private(set) var engineError: String?
    /// Quarto, for rendering reports; nil when it isn't installed.
    private(set) var quarto: QuartoRenderer?

    /// Level ids pushed on top of the star map.
    var path: [String] = []

    private(set) var progress: PilotProgress
    private(set) var unlocks = UnlockState(sectorStatus: [:], openLevels: [])
    /// A problem reading or writing the progress file, shown on the Pilot Profile.
    private(set) var progressProblem: String?
    /// Badges earned outside the completion card (e.g. the first plot), waiting to be shown.
    var toasts: [Badge] = []

    @ObservationIgnored private let store: ProgressStore
    @ObservationIgnored private var sessions: [String: LevelSession] = [:]
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    /// The current time; tests replace it to play across several days.
    @ObservationIgnored var now: () -> Date = { .now }

    init(store: ProgressStore = .standard) {
        self.store = store
        let loaded = store.load()
        progress = loaded.progress
        progressProblem = loaded.problem
        do {
            library = try ContentLibrary.loadBundled()
        } catch {
            loadError = error.localizedDescription
        }
        (engine, engineError, quarto) = Self.makeEngine()
        refreshUnlocks()
    }

    /// R and Quarto, from the paths in Settings (or the usual places when those are empty).
    private static func makeEngine() -> (REngine?, String?, QuartoRenderer?) {
        do {
            let engine = try REngine(rscriptPath: Preferences.customRscriptPath)
            return (engine, nil, QuartoRenderer(rscriptURL: engine.rscriptURL, quartoPath: Preferences.customQuartoPath))
        } catch {
            return (nil, error.localizedDescription, nil)
        }
    }

    /// Finds R and Quarto again after their paths change in Settings. Open levels get fresh
    /// sessions; code drafts are kept (they are saved in the progress file).
    func reloadEngine() {
        for session in sessions.values { session.cancel() }
        sessions = [:]
        (engine, engineError, quarto) = Self.makeEngine()
    }

    // MARK: Reading state

    /// Sectors with their status from progress.
    var sectors: [Sector] {
        (library?.sectors ?? []).map { sector in
            var sector = sector
            sector.status = unlocks.sectorStatus[sector.id] ?? .locked
            return sector
        }
    }

    var xp: Int { XP.total(progress, levels: library?.levels ?? []) }
    var rank: Rank { Rank.forXP(xp) }
    var fuel: FuelState { FuelState.compute(practiceDays: progress.practiceDays, today: now()) }

    var player: PlayerSnapshot {
        let fuel = self.fuel
        return PlayerSnapshot(rank: rank, xp: xp, stars: progress.totalStars, fuel: fuel.fuel, streak: fuel.streak)
    }

    func bestStars(_ levelID: String) -> Int? { progress.levels[levelID]?.bestStars }

    func level(id: String) -> Level? { library?.level(id: id) }

    func sector(containing level: Level) -> Sector? {
        sectors.first { $0.levels.contains { $0.id == level.id } }
    }

    func isOpen(_ level: Level) -> Bool { unlocks.openLevels.contains(level.id) }

    /// Open (every level type is playable).
    func isPlayable(_ level: Level) -> Bool { level.type.isPlayable && isOpen(level) }

    /// Every Lab level, for the Lab Bay's free-play instruments.
    var labLevels: [Level] { (library?.levels ?? []).filter { $0.lab != nil } }

    /// The level after this one in play order, if it can be played.
    func nextLevel(after level: Level) -> Level? {
        let next: Level?
        if let id = level.unlocks?.first {
            next = self.level(id: id)
        } else {
            let all = library?.levels ?? []
            next = all.firstIndex(of: level).flatMap { all.indices.contains($0 + 1) ? all[$0 + 1] : nil }
        }
        return next.flatMap { isPlayable($0) ? $0 : nil }
    }

    // MARK: Sessions

    /// The level's working state, kept while the app is open so leaving and coming back keeps
    /// your console and hint count. Code drafts are also saved to disk.
    func session(for level: Level) -> LevelSession {
        if let existing = sessions[level.id] { return existing }
        let session = LevelSession(level: level, engine: engine, engineError: engineError,
                                   draft: progress.drafts[level.id])
        session.model = self
        sessions[level.id] = session
        return session
    }

    // MARK: Workbench

    /// Where the Workbench keeps your data files:
    /// `~/Library/Application Support/SampleSpace/Workbench/`.
    nonisolated static var workbenchFolder: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "SampleSpace/Workbench", directoryHint: .isDirectory)
    }

    /// The data files in the Workbench folder, by name.
    static func workbenchDataFiles() -> [URL] {
        let fm = FileManager.default
        let files = (try? fm.contentsOfDirectory(at: workbenchFolder, includingPropertiesForKeys: [.isDirectoryKey],
                                                 options: .skipsHiddenFiles)) ?? []
        return files
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true }
            .filter { !["r", "md", "qmd", "json"].contains($0.pathExtension.lowercased()) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
    }

    /// The Workbench's session: a Quarto document with no checks, saved like a level draft.
    /// The first time, the folder gets a copy of the Crew Log so the template knits at once.
    func workbenchSession() -> LevelSession {
        if let existing = sessions[Self.workbenchID] { return existing }
        let fm = FileManager.default
        let folder = Self.workbenchFolder
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
            if let log = Bundle.main.url(forResource: "astronauts", withExtension: "csv", subdirectory: "Content/data-bank") {
                try? fm.copyItem(at: log, to: folder.appending(path: "astronauts.csv"))
            }
        }
        let template = Bundle.main.url(forResource: "template", withExtension: "qmd", subdirectory: "Content/workbench")
            .flatMap { try? String(contentsOf: $0, encoding: .utf8) } ?? "---\ntitle: \"Results\"\n---\n"
        let level = Level(id: Self.workbenchID, title: "Workbench", summary: "", type: .code, xp: 0, par: 0,
                          hints: [], unlocks: nil, timeLimit: 120, seed: nil, document: "report.qmd",
                          lesson: "", starterCode: template, solutionCode: "", checkCode: "", setupCode: nil,
                          folder: folder)
        let session = LevelSession(level: level, engine: engine, engineError: engineError,
                                   draft: progress.drafts[Self.workbenchID])
        session.model = self
        sessions[Self.workbenchID] = session
        return session
    }

    static let workbenchID = "workbench"

    // MARK: Recording play

    /// What clearing a level changed, for the completion card.
    struct ClearOutcome: Equatable {
        var firstClear: Bool
        var xpGained: Int
        var previousBest: Int?
        var rankUp: Rank?
        var newBadges: [Badge]
        /// Names of levels and sectors this clear opened.
        var opened: [String]
        /// The Crew Log entry recovered, when this clear charted its sector for the first time.
        var recoveredLog: LogEntry? = nil
    }

    /// A press of Check counts as practice for today.
    func recordCheck() {
        if markPractisedToday() { save() }
    }

    /// Adds today to the practice days. Returns whether it was new.
    private func markPractisedToday() -> Bool {
        let today = DayKey.key(for: now())
        guard !progress.practiceDays.contains(today) else { return false }
        progress.practiceDays.append(today)
        progress.practiceDays.sort()
        return true
    }

    // MARK: Review Nebula

    /// Cards collected so far: those whose level has been cleared.
    var reviewCards: [ReviewCard] {
        let cleared = progress.levels
        return (library?.reviewCards ?? []).filter { cleared[$0.levelID] != nil }
    }

    /// Every card the content holds, collected or not.
    var allReviewCardCount: Int { library?.reviewCards.count ?? 0 }

    /// Today's queue: cards due, then today's new cards.
    func reviewQueue() -> [ReviewCard] {
        ReviewScheduler.queue(cards: reviewCards, record: progress.review, today: now())
    }

    /// Cards not due yet, soonest first.
    func reviewAhead(limit: Int = ReviewScheduler.dailyGoal) -> [ReviewCard] {
        ReviewScheduler.ahead(cards: reviewCards, record: progress.review, today: now(), limit: limit)
    }

    var reviewedToday: Int { progress.review.answered[DayKey.key(for: now())] ?? 0 }

    func cardState(_ card: ReviewCard) -> CardState? { progress.review.cards[card.id] }

    func sectorName(forLevel id: String) -> String? {
        sectors.first { $0.levels.contains { $0.id == id } }?.name
    }

    /// Records an answer: reschedules the card, counts it towards today's goal, counts as
    /// practice for fuel and streak, and awards any badge that earns (shown as a toast).
    @discardableResult
    func recordReview(_ card: ReviewCard, correct: Bool) -> CardState {
        let date = now()
        let key = DayKey.key(for: date)
        let state = ReviewScheduler.answer(progress.review.cards[card.id], correct: correct, today: date)
        progress.review.cards[card.id] = state
        progress.review.answered[key, default: 0] += 1
        if correct { progress.review.correct[key, default: 0] += 1 }
        _ = markPractisedToday()
        let earned = Badge.earned(by: progress, sectors: sectors, streak: fuel, clearedLevel: nil, clearedCode: nil)
        for badge in Badge.all where earned.contains(badge.id) {
            if let new = award(badge.id) { toasts.append(new) }
        }
        save()
        return state
    }

    /// Notes a run's side effects that can earn a badge straight away.
    func recordRun(drewPlot: Bool) {
        if drewPlot, let badge = award("first-plot") { toasts.append(badge) }
    }

    func recordClear(level: Level, score: StarScore, code: String, hadErrorThisAttempt: Bool) -> ClearOutcome {
        let date = now()
        let oldXP = xp
        let oldRank = rank
        let oldOpen = unlocks.openLevels
        let oldSectors = unlocks.sectorStatus
        let previous = progress.levels[level.id]

        var record = previous ?? LevelProgress(bestStars: 0, firstCleared: date, lastCleared: date, clears: 0,
                                               clearedWithoutHints: false)
        record.bestStars = max(record.bestStars, score.stars)
        record.lastCleared = date
        record.clears += 1
        record.clearedWithoutHints = record.clearedWithoutHints || score.noHints
        progress.levels[level.id] = record
        refreshUnlocks()

        var newBadges: [Badge] = []
        if hadErrorThisAttempt, let badge = award("bug-hunter") { newBadges.append(badge) }
        let earned = Badge.earned(by: progress, sectors: sectors, streak: fuel,
                                  clearedLevel: level, clearedCode: code)
        for badge in Badge.all where earned.contains(badge.id) {
            if let new = award(badge.id) { newBadges.append(new) }
        }

        var opened: [String] = []
        for sector in sectors where oldSectors[sector.id] == .locked && sector.status != .locked {
            opened.append(sector.name)
        }
        for id in unlocks.openLevels.subtracting(oldOpen).sorted() {
            if let title = self.level(id: id)?.title { opened.append(title) }
        }

        let chartedNow = sector(containing: level)
            .flatMap { oldSectors[$0.id] != .completed && $0.status == .completed ? $0 : nil }

        save()
        let newRank = rank
        return ClearOutcome(firstClear: previous == nil, xpGained: xp - oldXP, previousBest: previous?.bestStars,
                            rankUp: newRank > oldRank ? newRank : nil, newBadges: newBadges, opened: opened,
                            recoveredLog: chartedNow?.log)
    }

    /// Records a badge. Returns it if it is new.
    private func award(_ id: String) -> Badge? {
        guard progress.badges[id] == nil, let badge = Badge.named(id) else { return nil }
        progress.badges[id] = now()
        save()
        return badge
    }

    func draftChanged(level: Level, code: String) {
        let draft: String? = code == level.starterCode ? nil : code
        guard progress.drafts[level.id] != draft else { return }
        progress.drafts[level.id] = draft
        saveSoon()
    }

    /// Wipes all saved progress (used from the Pilot Profile).
    func resetProgress() {
        for session in sessions.values { session.cancel() }
        sessions = [:]
        path = []
        toasts = []
        progress = PilotProgress()
        refreshUnlocks()
        save()
    }

    // MARK: Opening levels

    func open(_ level: Level) {
        guard isPlayable(level) else { return }
        path.append(level.id)
    }

    /// Replaces the current level with another, so Back still goes to the map.
    func replaceTop(with level: Level) {
        if path.isEmpty { path = [level.id] } else { path[path.count - 1] = level.id }
    }

    // MARK: Saving

    private func refreshUnlocks() {
        unlocks = UnlockState.compute(sectors: library?.sectors ?? [], cleared: progress.clearedIDs)
        if Self.unlockAll {
            for sector in library?.sectors ?? [] where unlocks.sectorStatus[sector.id] == .locked {
                unlocks.sectorStatus[sector.id] = .current
            }
            unlocks.openLevels.formUnion((library?.levels ?? []).map(\.id))
        }
    }

    /// Launch with `-UnlockAll YES` to open every sector and level, for trying out content
    /// before the sectors in front of it are written. Progress is still saved as usual.
    @ObservationIgnored static var unlockAll: Bool { UserDefaults.standard.bool(forKey: "UnlockAll") }

    /// Saves now. Called after anything that matters (clears, badges, practice days).
    func save() {
        saveTask?.cancel()
        saveTask = nil
        do {
            try store.save(progress)
        } catch {
            progressProblem = "Couldn't save progress: \(error.localizedDescription)"
        }
    }

    /// Saves shortly, so typing in the editor doesn't write the file on every keystroke.
    private func saveSoon() {
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled else { return }
            self?.save()
        }
    }
}
