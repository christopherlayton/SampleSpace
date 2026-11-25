import Foundation
import Testing
@testable import SampleSpace

private func card(_ id: String, level: String = "l1", kind: ReviewCard.Kind = .concept) -> ReviewCard {
    ReviewCard(id: id, kind: kind, levelID: level, prompt: id, choices: ["a", "b", "c", "d"], answer: 1)
}

private func day(_ key: String) -> Date { DayKey.date(key)! }

@Suite("Review scheduler")
struct ReviewSchedulerTests {
    @Test func rightAnswersClimbTheBoxes() {
        var state: CardState?
        var today = day("2026-11-24")
        var gaps: [Int] = []
        for _ in 0..<8 {
            let next = ReviewScheduler.answer(state, correct: true, today: today)
            let gap = DayKey.dayNumber(next.due)! - DayKey.dayNumber(for: today)
            gaps.append(gap)
            today = DayKey.date(next.due)!
            state = next
        }
        #expect(gaps == [1, 3, 7, 14, 30, 60, 120, 120])
        #expect(state?.box == 8)
        #expect(state?.reviews == 8)
        #expect(state?.introduced == "2026-11-24")
    }

    @Test func aMissSendsTheCardBackToTodayAndCountsALapse() {
        let learned = CardState(box: 3, due: "2026-11-24", introduced: "2026-11-01", reviews: 3, lapses: 0)
        let missed = ReviewScheduler.answer(learned, correct: false, today: day("2026-11-24"))
        #expect(missed.box == 0)
        #expect(missed.due == "2026-11-24")
        #expect(missed.lapses == 1)
        let relearned = ReviewScheduler.answer(missed, correct: true, today: day("2026-11-24"))
        #expect(relearned.box == 1)
        #expect(relearned.due == "2026-11-25")
        // A miss on a brand-new card isn't a lapse: it was never learned.
        #expect(ReviewScheduler.answer(nil, correct: false, today: day("2026-11-24")).lapses == 0)
    }

    @Test func theQueueIsDueCardsMostOverdueFirstThenNewOnes() {
        let cards = (1...5).map { card("c\($0)") }
        var record = ReviewRecord()
        record.cards["c1"] = CardState(box: 2, due: "2026-11-24", introduced: "2026-11-01", reviews: 2, lapses: 0)
        record.cards["c2"] = CardState(box: 1, due: "2026-11-20", introduced: "2026-11-01", reviews: 1, lapses: 0)
        record.cards["c3"] = CardState(box: 4, due: "2026-12-30", introduced: "2026-11-01", reviews: 4, lapses: 0)
        let queue = ReviewScheduler.queue(cards: cards, record: record, today: day("2026-11-24"))
        #expect(queue.map(\.id) == ["c2", "c1", "c4", "c5"])
        let ahead = ReviewScheduler.ahead(cards: cards, record: record, today: day("2026-11-24"), limit: 10)
        #expect(ahead.map(\.id) == ["c3"])
        #expect(ReviewScheduler.nextDue(cards: cards, record: record) == "2026-11-20")
    }

    @Test func newCardsAreLimitedPerDay() {
        let cards = (1...30).map { card("c\($0)") }
        var record = ReviewRecord()
        #expect(ReviewScheduler.queue(cards: cards, record: record, today: day("2026-11-24")).count
                == ReviewScheduler.newPerDay)
        // Four introduced today (and answered right) leave six new ones for today.
        for id in ["c1", "c2", "c3", "c4"] {
            record.cards[id] = ReviewScheduler.answer(nil, correct: true, today: day("2026-11-24"))
        }
        let queue = ReviewScheduler.queue(cards: cards, record: record, today: day("2026-11-24"))
        #expect(queue.map(\.id) == ["c5", "c6", "c7", "c8", "c9", "c10"])
        // Tomorrow those four are due, and ten more new ones join.
        #expect(ReviewScheduler.queue(cards: cards, record: record, today: day("2026-11-25")).count == 14)
    }

    @Test func aSessionRepeatsMissedCardsUntilRight() {
        var session = ReviewSession(queue: [card("a"), card("b")])
        session.record(correct: false)
        session.record(correct: true)               // ignored: already answered
        session.advance()
        session.record(correct: true)
        session.advance()
        #expect(session.current?.id == "a")         // the miss comes back
        #expect(session.remaining == 1)
        session.record(correct: true)
        session.advance()
        #expect(session.finished)
        #expect(session.answered == 3)
        #expect(session.rightFirstTime == 1)
    }
}

@Suite("Review cards")
struct ReviewCardTests {
    @Test func fillAnswersIgnoreSpacesAndCurlyQuotes() {
        let fill = ReviewCard(id: "f", kind: .fill, levelID: "l", prompt: "", code: "sample(x, ___)",
                              answers: ["replace = TRUE"])
        #expect(fill.accepts("replace=TRUE"))
        #expect(fill.accepts("  replace  =  TRUE "))
        #expect(!fill.accepts("replace = true"))
        #expect(!fill.accepts(""))
        #expect(fill.filledCode == "sample(x, replace = TRUE)")
        let quoted = ReviewCard(id: "q", kind: .fill, levelID: "l", prompt: "", code: "m(___)", answers: ["\"lm\""])
        #expect(quoted.accepts("\u{201C}lm\u{201D}"))
        #expect(quoted.accepts("'lm'"))
    }

    @Test func choiceOrderIsAStablePermutation() {
        let concept = card("concept-card")
        let order = concept.choiceOrder(day: 9000)
        #expect(order.sorted() == [0, 1, 2, 3])
        #expect(concept.choiceOrder(day: 9000) == order)
        let days = Set((9000..<9020).map { concept.choiceOrder(day: $0) })
        #expect(days.count > 1, "the order should change from day to day")
        #expect(card("w", kind: .whichTest).choiceOrder(day: 9000) == [0, 1, 2, 3])
    }

    @Test func reviewFileEntriesBecomeCards() throws {
        let json = """
        { "cards": [
          { "id": "a", "level": "s.one", "type": "fill", "prompt": "p", "code": "x ___ 1", "answers": ["<-"] },
          { "id": "b", "level": "s.one", "type": "which_test", "prompt": "p", "answer": "paired_t" },
          { "id": "c", "level": "s.one", "type": "concept", "prompt": "p", "choices": ["x", "y"], "answer": 1 }
        ] }
        """
        let file = try JSONDecoder().decode(ReviewFile.self, from: Data(json.utf8))
        let cards = try file.reviewCards(levelIDs: ["s.one"]).get()
        #expect(cards.map(\.kind) == [.fill, .whichTest, .concept])
        #expect(cards[1].choices == StatTest.defaultOptions.map(\.name))
        #expect(cards[1].choices[cards[1].answer] == StatTest.pairedT.name)

        guard case .failure(let error) = file.reviewCards(levelIDs: ["s.two"]) else {
            Issue.record("a card for a level outside the sector should be rejected")
            return
        }
        #expect(error.card == "a")
    }

    @Test func badEntriesAreRejected() throws {
        let cases = [
            #"{ "id": "x", "level": "s.one", "type": "fill", "prompt": "p", "code": "no blank", "answers": ["1"] }"#,
            #"{ "id": "x", "level": "s.one", "type": "concept", "prompt": "p", "choices": ["a", "b"], "answer": 2 }"#,
            #"{ "id": "x", "level": "s.one", "type": "which_test", "prompt": "p", "answer": "anova" }"#,
            #"{ "id": "x", "level": "s.one", "type": "essay", "prompt": "p" }"#,
        ]
        for entry in cases {
            let file = try JSONDecoder().decode(ReviewFile.self, from: Data(#"{ "cards": [\#(entry)] }"#.utf8))
            if case .success = file.reviewCards(levelIDs: ["s.one"]) { Issue.record("accepted: \(entry)") }
        }
    }

    @Test func bundledContentHasCardsForEveryWrittenSector() throws {
        let library = try ContentLibrary.loadBundled()
        let cards = library.reviewCards
        #expect(Set(cards.map(\.id)).count == cards.count)
        let levelIDs = Set(library.levels.map(\.id))
        #expect(cards.allSatisfy { levelIDs.contains($0.levelID) })
        let quizQuestions = library.levels.filter(\.type.isQuiz).reduce(0) { $0 + ($1.quiz?.count ?? 0) }
        #expect(cards.filter { $0.id.hasPrefix("quiz:") }.count == quizQuestions)
        for sector in library.sectors.prefix(9) {
            #expect(!sector.reviewCards.isEmpty, "\(sector.name) has no review.json cards")
        }
        #expect(cards.contains { $0.kind == .fill })
        #expect(cards.contains { $0.kind == .whichTest })
        #expect(cards.contains { $0.kind == .predict })
        // Curriculum order: the first card comes from the first sector.
        #expect(cards.first?.levelID.hasPrefix("launch-pad.") == true)
    }
}

@Suite("Review progress")
@MainActor
struct ReviewProgressTests {
    @Test func olderSavesWithoutReviewDataStillLoad() throws {
        let store = ProgressStore.temporary()
        try FileManager.default.createDirectory(at: store.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let old = #"{ "version": 1, "levels": {}, "practiceDays": ["2026-11-20"], "badges": {} }"#
        try Data(old.utf8).write(to: store.url)
        let loaded = store.load()
        #expect(loaded.problem == nil)
        #expect(loaded.progress.practiceDays == ["2026-11-20"])
        #expect(loaded.progress.review == ReviewRecord())
        #expect(loaded.progress.drafts.isEmpty)
    }

    @Test func reviewStateRoundTripsThroughTheFile() throws {
        let store = ProgressStore.temporary()
        var progress = PilotProgress()
        progress.review.cards["c"] = CardState(box: 2, due: "2026-11-27", introduced: "2026-11-20", reviews: 3, lapses: 1)
        progress.review.answered["2026-11-24"] = 12
        progress.review.correct["2026-11-24"] = 9
        try store.save(progress)
        #expect(store.load().progress == progress)
    }

    @Test func cardsAreCollectedByClearingLevels() throws {
        let model = GameModel(store: .temporary())
        #expect(model.reviewCards.isEmpty)
        #expect(model.reviewQueue().isEmpty)
        let level = try #require(model.level(id: "launch-pad.reading-the-console"))
        _ = model.recordClear(level: level, score: StarScore(passed: true, hintsUsed: 0, solutionShown: false,
                                                             checkAttempts: 4, par: 4),
                              code: "", hadErrorThisAttempt: false)
        #expect(model.reviewCards.count == level.quiz?.count)
        #expect(model.reviewCards.allSatisfy { $0.levelID == level.id })
        #expect(model.reviewQueue().count == level.quiz?.count)
    }

    @Test func reviewingCountsAsPracticeAndEarnsTheNebulaBadge() throws {
        let store = ProgressStore.temporary()
        let model = GameModel(store: store)
        for id in ["launch-pad.calculator-console", "launch-pad.reading-the-console", "launch-pad.storing-cargo"] {
            let level = try #require(model.level(id: id))
            _ = model.recordClear(level: level, score: StarScore(passed: true, hintsUsed: 0, solutionShown: false,
                                                                 checkAttempts: 1, par: 4),
                                  code: "", hadErrorThisAttempt: false)
        }
        let cards = model.reviewCards
        #expect(cards.count >= 5)
        var date = DayKey.date("2026-11-20")!
        model.now = { date }
        model.toasts = []
        for dayIndex in 0..<5 {
            #expect(!model.progress.badges.keys.contains("nebula-regular"), "day \(dayIndex)")
            for answer in 0..<ReviewScheduler.dailyGoal {
                model.recordReview(cards[answer % cards.count], correct: answer % 3 != 0)
            }
            #expect(model.reviewedToday == ReviewScheduler.dailyGoal)
            #expect(model.fuel.practisedToday)
            date = Calendar.current.date(byAdding: .day, value: 1, to: date)!
        }
        #expect(model.progress.review.goalDays == 5)
        #expect(model.progress.badges.keys.contains("nebula-regular"))
        #expect(model.toasts.map(\.id).contains("nebula-regular"))
        #expect(model.fuel.bestStreak == 5)
        // Saved straight away.
        #expect(store.load().progress.review == model.progress.review)
    }
}
