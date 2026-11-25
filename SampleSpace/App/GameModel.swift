import Foundation
import Observation

/// App-wide state: the loaded content, the R engine, navigation, and the pilot's saved progress
/// (stars, XP, rank, fuel and streak, badges, unlocked levels and code drafts).
@MainActor @Observable
final class GameModel {
    private(set) var library: ContentLibrary?
    private(set) var loadError: String?
    let engine: REngine?
    let engineError: String?

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
        do {
            engine = try REngine()
            engineError = nil
        } catch {
            engine = nil
            engineError = error.localizedDescription
        }
        refreshUnlocks()
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

    /// Open, and of a type the app can play yet (everything but Boss levels).
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
        let today = DayKey.key(for: now())
        guard progress.practiceDays.last != today else { return }
        progress.practiceDays.append(today)
        progress.practiceDays.sort()
        save()
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
