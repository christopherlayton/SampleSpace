import Foundation

// MARK: - Cards

/// One quick-fire card in the Review Nebula. Cards come from two places:
///
/// - **Quiz questions**: every question of a Briefing or Predict level becomes a card once
///   that level is cleared (`ReviewCard.fromQuiz`).
/// - **review.json** in a sector folder: hand-written cards, each tied to a level in that
///   sector and collected when the level is cleared:
///
///       { "cards": [
///         { "id": "launch-pad/assign", "level": "launch-pad.storing-cargo", "type": "fill",
///           "prompt": "Store 42 in `fuel`.", "code": "fuel ___ 42", "answers": ["<-"],
///           "explain": "…" },
///         { "id": "…", "level": "…", "type": "concept",
///           "prompt": "…", "choices": ["…", "…"], "answer": 1, "explain": "…" },
///         { "id": "…", "level": "…", "type": "which_test",
///           "prompt": "A scenario…", "answer": "paired_t", "options": ["…"], "explain": "…" }
///       ] }
///
///   `fill` cards have one `___` blank in `code` and the accepted `answers` (compared without
///   spaces, quotes made straight). `which_test` answers and options are `StatTest` keys;
///   `options` defaults to `StatTest.defaultOptions`. Card ids must be unique across sectors.
struct ReviewCard: Identifiable, Hashable, Sendable {
    enum Kind: String, Sendable, CaseIterable {
        case concept, predict, fill, whichTest

        var title: String {
            switch self {
            case .concept: "Concept"
            case .predict: "Predict"
            case .fill: "Fill in the code"
            case .whichTest: "Which test?"
            }
        }

        var symbol: String {
            switch self {
            case .concept: "lightbulb"
            case .predict: "questionmark.bubble"
            case .fill: "text.cursor"
            case .whichTest: "arrow.triangle.branch"
            }
        }
    }

    static let blank = "___"

    let id: String
    let kind: Kind
    let levelID: String
    let prompt: String
    var code: String?
    /// Concept, Predict and Which-test cards.
    var choices: [String] = []
    var answer = 0
    var choicesAreCode = false
    /// Fill cards: accepted answers for the blank.
    var answers: [String] = []
    var explain: String?

    var isChoice: Bool { kind != .fill }

    /// Cards for every question of a Briefing or Predict level.
    static func fromQuiz(_ level: Level) -> [ReviewCard] {
        guard level.type.isQuiz else { return [] }
        return (level.quiz ?? []).enumerated().map { index, question in
            ReviewCard(id: "quiz:\(level.id)#\(index + 1)", kind: level.type == .predict ? .predict : .concept,
                       levelID: level.id, prompt: question.prompt, code: question.code,
                       choices: question.choices, answer: question.answer,
                       choicesAreCode: question.showsChoicesAsCode, explain: question.explain)
        }
    }

    // MARK: Fill answers

    /// Whether a typed answer fills the blank correctly.
    func accepts(_ typed: String) -> Bool {
        let given = Self.normalise(typed)
        return !given.isEmpty && answers.contains { Self.normalise($0) == given }
    }

    /// The code with the first accepted answer in the blank.
    var filledCode: String? {
        guard kind == .fill, let code, let first = answers.first else { return code }
        return code.replacingOccurrences(of: Self.blank, with: first)
    }

    /// Ignores spaces and curly quotes, so `replace=TRUE` matches `replace = TRUE`.
    static func normalise(_ text: String) -> String {
        let straight = text
            .replacingOccurrences(of: "\u{201C}", with: "\"").replacingOccurrences(of: "\u{201D}", with: "\"")
            .replacingOccurrences(of: "\u{2018}", with: "'").replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "'", with: "\"")
        return String(straight.filter { !$0.isWhitespace })
    }

    /// The order to show the choices in: shuffled per card and per day (so a card isn't
    /// remembered by position), except Which-test cards, whose list is always in the same order.
    func choiceOrder(day: Int) -> [Int] {
        guard kind == .concept || kind == .predict else { return Array(choices.indices) }
        var generator = SplitMix64(seed: Self.fnv1a(id) &+ UInt64(bitPattern: Int64(day)))
        return Array(choices.indices).shuffled(using: &generator)
    }

    /// A stable hash (Swift's `hashValue` changes between launches).
    static func fnv1a(_ text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01b3
        }
        return hash
    }
}

/// The tests a "which test?" card can offer. The keys are used in review.json, and
/// scripts/validate_content.R keeps the same list.
enum StatTest: String, CaseIterable, Sendable {
    case oneSampleT = "one_sample_t"
    case independentT = "independent_t"
    case pairedT = "paired_t"
    case oneWayANOVA = "one_way_anova"
    case factorialANOVA = "factorial_anova"
    case repeatedMeasuresANOVA = "repeated_measures_anova"
    case chiSquare = "chi_square"
    case correlation
    case regression

    var name: String {
        switch self {
        case .oneSampleT: "One-sample t-test"
        case .independentT: "Independent-samples t-test"
        case .pairedT: "Paired-samples t-test"
        case .oneWayANOVA: "One-way ANOVA"
        case .factorialANOVA: "Factorial ANOVA"
        case .repeatedMeasuresANOVA: "Repeated-measures ANOVA"
        case .chiSquare: "Chi-square test of independence"
        case .correlation: "Correlation (Pearson's r)"
        case .regression: "Linear regression"
        }
    }

    static let defaultOptions: [StatTest] = [.oneSampleT, .independentT, .pairedT, .oneWayANOVA,
                                             .chiSquare, .correlation]
}

// MARK: - review.json

struct ReviewFile: Decodable {
    let cards: [Entry]

    struct Entry: Decodable {
        let id: String
        let level: String
        let type: String
        let prompt: String
        let code: String?
        let choices: [String]?
        let answer: Answer?
        let answers: [String]?
        let options: [String]?
        let explain: String?
    }

    /// An index for choice cards, a test key for Which-test cards.
    enum Answer: Decodable {
        case index(Int)
        case key(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let index = try? container.decode(Int.self) {
                self = .index(index)
            } else {
                self = .key(try container.decode(String.self))
            }
        }
    }

    /// Turns the file's entries into cards, or says what's wrong with the first bad one.
    func reviewCards(levelIDs: Set<String>) -> Result<[ReviewCard], ReviewFileError> {
        var cards: [ReviewCard] = []
        for entry in self.cards {
            func bad(_ text: String) -> Result<[ReviewCard], ReviewFileError> { .failure(.init(card: entry.id, problem: text)) }
            guard levelIDs.contains(entry.level) else { return bad("level \"\(entry.level)\" isn't in this sector") }
            switch entry.type {
            case "concept":
                let choices = entry.choices ?? []
                guard choices.count >= 2 else { return bad("needs at least two choices") }
                guard case .index(let answer)? = entry.answer, choices.indices.contains(answer) else {
                    return bad("answer must be the 0-based index of a choice")
                }
                cards.append(ReviewCard(id: entry.id, kind: .concept, levelID: entry.level, prompt: entry.prompt,
                                        code: entry.code, choices: choices, answer: answer,
                                        choicesAreCode: false, explain: entry.explain))
            case "fill":
                guard let code = entry.code, code.components(separatedBy: ReviewCard.blank).count == 2 else {
                    return bad("needs code with exactly one \(ReviewCard.blank) blank")
                }
                let answers = entry.answers ?? []
                guard !answers.isEmpty else { return bad("needs at least one accepted answer") }
                cards.append(ReviewCard(id: entry.id, kind: .fill, levelID: entry.level, prompt: entry.prompt,
                                        code: code, answers: answers, explain: entry.explain))
            case "which_test":
                let keys = entry.options ?? StatTest.defaultOptions.map(\.rawValue)
                let options = keys.compactMap(StatTest.init(rawValue:))
                guard options.count == keys.count, options.count >= 2 else { return bad("unknown test in options") }
                guard case .key(let key)? = entry.answer, let test = StatTest(rawValue: key),
                      let answer = options.firstIndex(of: test) else {
                    return bad("answer must be one of the options' test keys")
                }
                cards.append(ReviewCard(id: entry.id, kind: .whichTest, levelID: entry.level, prompt: entry.prompt,
                                        choices: options.map(\.name), answer: answer, explain: entry.explain))
            default:
                return bad("unknown type \"\(entry.type)\" (use concept, fill or which_test)")
            }
        }
        return .success(cards)
    }
}

struct ReviewFileError: Error, Equatable {
    let card: String
    let problem: String
}

// MARK: - Saved review state

/// The Review Nebula's part of the save file.
struct ReviewRecord: Codable, Equatable, Sendable {
    /// Card id → where it is in the schedule (only cards seen at least once).
    var cards: [String: CardState] = [:]
    /// Cards answered per day (`yyyy-MM-dd` → count), for the daily goal.
    var answered: [String: Int] = [:]
    /// Of those, answered correctly.
    var correct: [String: Int] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cards = try container.decodeIfPresent([String: CardState].self, forKey: .cards) ?? [:]
        answered = try container.decodeIfPresent([String: Int].self, forKey: .answered) ?? [:]
        correct = try container.decodeIfPresent([String: Int].self, forKey: .correct) ?? [:]
    }

    /// Days on which the daily goal was met.
    var goalDays: Int { answered.values.filter { $0 >= ReviewScheduler.dailyGoal }.count }
}

struct CardState: Codable, Equatable, Sendable {
    /// 0 = still learning; each right answer in a row moves the card up a box.
    var box: Int
    /// The day it's next due, `yyyy-MM-dd`.
    var due: String
    /// The day it was first answered.
    var introduced: String
    var reviews: Int
    /// Times it was forgotten after being learned.
    var lapses: Int
}

// MARK: - Scheduler

/// A Leitner-style spaced-repetition scheduler.
///
/// - A right answer moves a card up one box; its next review is that box's interval away:
///   1, 3, 7, 14, 30, 60, then 120 days.
/// - A wrong answer sends it back to box 0: due again today (the session asks it again
///   before it ends), then tomorrow once it's right.
/// - Each day's queue is every card due (most overdue first), then up to `newPerDay` cards
///   never seen before, in curriculum order.
/// - The daily goal is `dailyGoal` cards answered.
enum ReviewScheduler {
    static let intervals = [1, 3, 7, 14, 30, 60, 120]
    static let dailyGoal = 10
    static let newPerDay = 10

    /// Days until the next review for a card in this box.
    static func interval(forBox box: Int) -> Int {
        box <= 0 ? 0 : intervals[min(box, intervals.count) - 1]
    }

    static func answer(_ state: CardState?, correct: Bool, today: Date, calendar: Calendar = .current) -> CardState {
        let key = DayKey.key(for: today, calendar: calendar)
        var card = state ?? CardState(box: 0, due: key, introduced: key, reviews: 0, lapses: 0)
        card.reviews += 1
        if correct {
            card.box += 1
        } else {
            if card.box > 0 { card.lapses += 1 }
            card.box = 0
        }
        let next = calendar.date(byAdding: .day, value: interval(forBox: card.box), to: today) ?? today
        card.due = DayKey.key(for: next, calendar: calendar)
        return card
    }

    /// Today's queue from the cards collected so far.
    static func queue(cards: [ReviewCard], record: ReviewRecord, today: Date,
                      calendar: Calendar = .current) -> [ReviewCard] {
        let todayNumber = DayKey.dayNumber(for: today, calendar: calendar)
        let key = DayKey.key(for: today, calendar: calendar)
        var due: [(card: ReviewCard, day: Int, box: Int, order: Int)] = []
        var fresh: [ReviewCard] = []
        for (order, card) in cards.enumerated() {
            if let state = record.cards[card.id] {
                if let day = DayKey.dayNumber(state.due, calendar: calendar), day <= todayNumber {
                    due.append((card, day, state.box, order))
                }
            } else {
                fresh.append(card)
            }
        }
        due.sort { ($0.day, $0.box, $0.order) < ($1.day, $1.box, $1.order) }
        let introducedToday = record.cards.values.filter { $0.introduced == key }.count
        let allowance = max(0, newPerDay - introducedToday)
        return due.map(\.card) + fresh.prefix(allowance)
    }

    /// Cards that aren't due yet, soonest first, for reviewing ahead.
    static func ahead(cards: [ReviewCard], record: ReviewRecord, today: Date, limit: Int,
                      calendar: Calendar = .current) -> [ReviewCard] {
        let todayNumber = DayKey.dayNumber(for: today, calendar: calendar)
        let upcoming = cards.enumerated().compactMap { order, card -> (ReviewCard, Int, Int)? in
            guard let state = record.cards[card.id],
                  let day = DayKey.dayNumber(state.due, calendar: calendar), day > todayNumber else { return nil }
            return (card, day, order)
        }
        return upcoming.sorted { ($0.1, $0.2) < ($1.1, $1.2) }.prefix(limit).map(\.0)
    }

    /// The day the next card falls due, if every card due is done.
    static func nextDue(cards: [ReviewCard], record: ReviewRecord) -> String? {
        let ids = Set(cards.map(\.id))
        return record.cards.filter { ids.contains($0.key) }.map(\.value.due).min()
    }
}

// MARK: - A review session

/// One sitting in the Review Nebula: the queue, where you are, and what you got right.
/// A card answered wrongly goes to the back of the queue, so a session ends with every card
/// right once. Pure state, so it can be tested without the UI.
struct ReviewSession: Equatable, Sendable {
    private(set) var queue: [ReviewCard]
    private(set) var position = 0
    private(set) var answered = 0
    private(set) var rightFirstTime = 0
    private(set) var missed: Set<String> = []
    /// Whether the current card has been answered (and if so, rightly).
    private(set) var result: Bool?

    init(queue: [ReviewCard]) { self.queue = queue }

    var current: ReviewCard? { queue.indices.contains(position) ? queue[position] : nil }
    var finished: Bool { current == nil }
    /// Cards still to see, counting the current one.
    var remaining: Int { max(0, queue.count - position) }

    mutating func record(correct: Bool) {
        guard let card = current, result == nil else { return }
        result = correct
        answered += 1
        if correct {
            if !missed.contains(card.id) { rightFirstTime += 1 }
        } else {
            missed.insert(card.id)
            queue.append(card)
        }
    }

    mutating func advance() {
        guard result != nil else { return }
        position += 1
        result = nil
    }
}
