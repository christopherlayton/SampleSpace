import Foundation
import Testing
@testable import SampleSpace

extension ProgressStore {
    /// A progress file in a fresh temporary folder, so tests never touch the real save.
    static func temporary() -> ProgressStore {
        ProgressStore(url: FileManager.default.temporaryDirectory
            .appending(path: "SampleSpaceTests-\(UUID().uuidString)/progress.json"))
    }
}

/// Builds small sectors and levels for unlock and badge tests.
private enum Fixture {
    static func level(_ id: String, unlocks: [String]? = nil, type: LevelType = .code) -> Level {
        Level(id: id, title: id, summary: "", type: type, xp: 50, par: 2, hints: [], unlocks: unlocks,
              timeLimit: 10, seed: nil, lesson: "", starterCode: "", solutionCode: "", checkCode: "",
              setupCode: nil, folder: URL(filePath: "/tmp"))
    }

    static func sector(_ id: Int, _ levels: [Level], optional: Bool = false) -> Sector {
        Sector(id: id, name: "S\(id)", rSkills: "", statsConcepts: "", hue: 0.5, mapPosition: .zero,
               planetSize: 60, isOptional: optional, levels: levels)
    }

    static func cleared(_ ids: [String], stars: Int = 3, noHints: Bool = true) -> PilotProgress {
        var progress = PilotProgress()
        for id in ids {
            progress.levels[id] = LevelProgress(bestStars: stars, firstCleared: .now, lastCleared: .now,
                                                clearedWithoutHints: noHints)
        }
        return progress
    }
}

@Suite("Unlocking")
struct UnlockTests {
    let sectors = [
        Fixture.sector(0, [Fixture.level("a1"), Fixture.level("a2"), Fixture.level("a3")]),
        Fixture.sector(1, [Fixture.level("b1"), Fixture.level("b2")]),
        Fixture.sector(2, []),
        Fixture.sector(3, [Fixture.level("d1")]),
    ]

    @Test func freshPilotHasOnlyTheFirstLevelOpen() {
        let state = UnlockState.compute(sectors: sectors, cleared: [])
        #expect(state.openLevels == ["a1"])
        #expect(state.sectorStatus == [0: .current, 1: .locked, 2: .locked, 3: .locked])
    }

    @Test func clearingALevelOpensTheNextOne() {
        let state = UnlockState.compute(sectors: sectors, cleared: ["a1"])
        #expect(state.openLevels == ["a1", "a2"])
    }

    @Test func chartingASectorOpensTheNext() {
        let state = UnlockState.compute(sectors: sectors, cleared: ["a1", "a2", "a3"])
        #expect(state.sectorStatus[0] == .completed)
        #expect(state.sectorStatus[1] == .current)
        #expect(state.openLevels.contains("b1"))
        #expect(!state.openLevels.contains("b2"))
    }

    @Test func aSectorWithoutLevelsBlocksTheRest() {
        let state = UnlockState.compute(sectors: sectors, cleared: ["a1", "a2", "a3", "b1", "b2"])
        #expect(state.sectorStatus[2] == .current)
        #expect(state.sectorStatus[3] == .locked)
    }

    @Test func aStartedSectorStaysOpenWhenLevelsAreAddedBeforeIt() {
        // Sector 0 gained a new level (a4) after the pilot had moved on to sector 1.
        let grown = [
            Fixture.sector(0, [Fixture.level("a1"), Fixture.level("a2"), Fixture.level("a3"), Fixture.level("a4")]),
            Fixture.sector(1, [Fixture.level("b1"), Fixture.level("b2")]),
            Fixture.sector(3, [Fixture.level("d1")]),
        ]
        let state = UnlockState.compute(sectors: grown, cleared: ["a1", "a2", "a3", "b1"])
        #expect(state.sectorStatus[0] == .current)
        #expect(state.openLevels.isSuperset(of: ["a4", "b1", "b2"]))
        #expect(state.sectorStatus[1] == .current)
        #expect(state.sectorStatus[3] == .locked)
    }

    @Test func explicitUnlocksSkipAhead() {
        let custom = [Fixture.sector(0, [Fixture.level("x", unlocks: ["z"]), Fixture.level("y"), Fixture.level("z")])]
        let state = UnlockState.compute(sectors: custom, cleared: ["x"])
        #expect(state.openLevels == ["x", "z"])
    }
}

@Suite("Fuel and streak")
struct FuelTests {
    let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return c
    }()

    private func state(_ days: [String], today: String) -> FuelState {
        FuelState.compute(practiceDays: days, today: DayKey.date(today, calendar: calendar)!, calendar: calendar)
    }

    @Test func newPilotHasAFullTank() {
        #expect(state([], today: "2026-11-24") == .empty)
    }

    @Test func consecutiveDaysBuildAStreak() {
        let s = state(["2026-11-22", "2026-11-23", "2026-11-24"], today: "2026-11-24")
        #expect(s.streak == 3)
        #expect(s.fuel == 1)
        #expect(s.practisedToday)
    }

    @Test func todayIsNotMissedUntilItIsOver() {
        let s = state(["2026-11-23"], today: "2026-11-24")
        #expect(s.fuel == 1)
        #expect(s.streak == 1)
        #expect(!s.practisedToday)
    }

    @Test func eachMissedDayBurnsAQuarter() {
        #expect(state(["2026-11-20"], today: "2026-11-23").fuel == 0.5)   // missed 21st, 22nd
        let s = state(["2026-11-20", "2026-11-23"], today: "2026-11-23")
        #expect(s.streak == 2)                                             // survived the gap
        #expect(s.fuel == 1)                                               // practising refuels
    }

    @Test func runningDryRestartsTheStreakButKeepsTheBest() {
        let s = state(["2026-11-01", "2026-11-02", "2026-11-03", "2026-11-08"], today: "2026-11-08")
        #expect(s.streak == 1)
        #expect(s.bestStreak == 3)
        let dry = state(["2026-11-01"], today: "2026-11-06")
        #expect(dry.fuel == 0)
        #expect(dry.streak == 0)
    }

    @Test func dayKeysRoundTrip() {
        let date = DayKey.date("2026-03-08", calendar: calendar)!   // a daylight-saving change
        #expect(DayKey.key(for: date, calendar: calendar) == "2026-03-08")
        #expect(DayKey.dayNumber("2026-03-09", calendar: calendar)! - DayKey.dayNumber("2026-03-08", calendar: calendar)! == 1)
    }
}

@Suite("Ranks and XP")
struct RankTests {
    @Test func ranksFollowXP() {
        #expect(Rank.forXP(0) == .cadet)
        #expect(Rank.forXP(399) == .cadet)
        #expect(Rank.forXP(400) == .ensign)
        #expect(Rank.forXP(100_000) == .principalInvestigator)
        #expect(Rank.progress(xp: 1450) == 0.5)
        #expect(Rank.progress(xp: 16_000) == 1)
    }

    @Test func starsAddBonusXP() {
        let level = Fixture.level("a")
        #expect(XP.value(of: level, stars: 0) == 0)
        #expect(XP.value(of: level, stars: 1) == 50)
        #expect(XP.value(of: level, stars: 3) == 50 + 2 * XP.perBonusStar)
    }
}

@Suite("Badges")
struct BadgeTests {
    @Test func earnedFromProgress() {
        let sectors = [Fixture.sector(0, [Fixture.level("a1"), Fixture.level("a2")])]
        let streak = FuelState(fuel: 1, streak: 3, bestStreak: 3, practisedToday: true)
        let earned = Badge.earned(by: Fixture.cleared(["a1", "a2"]), sectors: sectors, streak: streak,
                                  clearedLevel: sectors[0].levels[1], clearedCode: "shapiro.test(x)")
        #expect(earned == ["lift-off", "perfect-landing", "sector-charted", "star-collector",
                           "three-day-burn", "assumption-checker"])
    }

    @Test func soloFlightNeedsFiveHintFreeClears() {
        let sectors = [Fixture.sector(0, (1...5).map { Fixture.level("l\($0)") })]
        let four = Fixture.cleared(["l1", "l2", "l3", "l4"], stars: 2)
        #expect(!Badge.earned(by: four, sectors: sectors, streak: .empty, clearedLevel: nil, clearedCode: nil)
            .contains("solo-flight"))
        let five = Fixture.cleared(["l1", "l2", "l3", "l4", "l5"], stars: 2)
        #expect(Badge.earned(by: five, sectors: sectors, streak: .empty, clearedLevel: nil, clearedCode: nil)
            .contains("solo-flight"))
    }

    @Test func everyBadgeHasAUniqueID() {
        #expect(Set(Badge.all.map(\.id)).count == Badge.all.count)
    }
}

@Suite("Saved progress")
@MainActor
struct SavedProgressTests {
    @Test func roundTripsThroughTheFile() throws {
        let store = ProgressStore.temporary()
        var progress = Fixture.cleared(["launch-pad.calculator-console"], stars: 2)
        progress.practiceDays = ["2026-11-24"]
        progress.badges["lift-off"] = Date(timeIntervalSince1970: 1_800_000_000)
        progress.drafts["launch-pad.storing-cargo"] = "x <- 1"
        try store.save(progress)
        let loaded = store.load()
        #expect(loaded.problem == nil)
        #expect(loaded.progress.levels.keys.sorted() == ["launch-pad.calculator-console"])
        #expect(loaded.progress.practiceDays == ["2026-11-24"])
        #expect(loaded.progress.badges["lift-off"] == Date(timeIntervalSince1970: 1_800_000_000))
        #expect(loaded.progress.drafts == progress.drafts)
    }

    @Test func anUnreadableFileIsMovedAsideNotLost() throws {
        let store = ProgressStore.temporary()
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: store.url)
        let loaded = store.load()
        #expect(loaded.progress == PilotProgress())
        #expect(loaded.problem != nil)
        let siblings = try FileManager.default.contentsOfDirectory(atPath: store.url.deletingLastPathComponent().path)
        #expect(siblings.contains { $0.hasPrefix("progress.unreadable-") })
    }

    @Test func modelRestoresProgressAndDrafts() async throws {
        let store = ProgressStore.temporary()
        do {
            let model = GameModel(store: store)
            let level = try #require(model.level(id: "launch-pad.calculator-console"))
            let session = model.session(for: level)
            session.code = level.solutionCode
            await session.perform(check: true)
            #expect(session.completion != nil)
            let next = try #require(model.level(id: "launch-pad.storing-cargo"))
            model.session(for: next).code = "n_responses <- 40"
            model.save()
        }
        let reopened = GameModel(store: store)
        #expect(reopened.bestStars("launch-pad.calculator-console") == 3)
        #expect(reopened.xp > 0)
        #expect(reopened.fuel.practisedToday)
        let briefing = try #require(reopened.level(id: "launch-pad.reading-the-console"))
        #expect(reopened.isPlayable(briefing))
        let next = try #require(reopened.level(id: "launch-pad.storing-cargo"))
        #expect(!reopened.isPlayable(next))
        #expect(reopened.session(for: next).code == "n_responses <- 40")
    }

    @Test func practiceAcrossDaysBuildsAStreakAndBadge() throws {
        let model = GameModel(store: .temporary())
        var day = DayKey.date("2026-11-20")!
        model.now = { day }
        for _ in 0..<3 {
            model.recordCheck()
            day = Calendar.current.date(byAdding: .day, value: 1, to: day)!
        }
        day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        #expect(model.fuel.streak == 3)
        let level = try #require(model.level(id: "launch-pad.calculator-console"))
        let outcome = model.recordClear(level: level, score: StarScore(passed: true, hintsUsed: 0, solutionShown: false,
                                                                       checkAttempts: 1, par: 2),
                                        code: level.solutionCode, hadErrorThisAttempt: true)
        #expect(Set(outcome.newBadges.map(\.id)) == ["bug-hunter", "lift-off", "perfect-landing", "three-day-burn"])
    }

    @Test func clearingTheWholeSectorReportsWhatOpened() throws {
        let model = GameModel(store: .temporary())
        let levels = try #require(model.sectors.first?.levels)
        let perfect = StarScore(passed: true, hintsUsed: 0, solutionShown: false, checkAttempts: 1, par: 2)
        var outcome: GameModel.ClearOutcome?
        for level in levels {
            outcome = model.recordClear(level: level, score: perfect, code: "", hadErrorThisAttempt: false)
        }
        #expect(model.sectors.first?.status == .completed)
        #expect(model.sectors[1].status == .current)
        #expect(outcome?.opened == ["Vector Belt", "Cargo Manifest"])
        #expect(outcome?.recoveredLog?.title == "Entry 1: Vostok 1")
        #expect(outcome?.newBadges.map(\.id).contains("sector-charted") == true)
        #expect(outcome?.newBadges.map(\.id).contains("star-collector") == true)
    }

    @Test func resetWipesEverything() throws {
        let store = ProgressStore.temporary()
        let model = GameModel(store: store)
        model.recordCheck()
        model.resetProgress()
        #expect(model.progress == PilotProgress())
        #expect(store.load().progress == PilotProgress())
    }
}
