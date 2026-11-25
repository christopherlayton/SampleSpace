import Foundation

/// Fuel and streak, worked out from the days you practised.
///
/// - A practice day is a day you pressed **Check** on a level or answered a Review Nebula card.
/// - Practising fills the tank to 100% and adds one day to the streak.
/// - Each day away burns 25% of the tank. Today only counts as missed once it is over.
/// - Run dry (four days away in a row) and the streak starts again next time you practise.
///   XP, stars and badges are never lost: a missed day costs fuel, not progress.
struct FuelState: Equatable, Sendable {
    static let burnPerMissedDay = 0.25

    /// 0–1.
    var fuel: Double
    /// Practice days in the current run.
    var streak: Int
    var bestStreak: Int
    var practisedToday: Bool

    static let empty = FuelState(fuel: 1, streak: 0, bestStreak: 0, practisedToday: false)

    static func compute(practiceDays: [String], today: Date = .now, calendar: Calendar = .current) -> FuelState {
        let days = Set(practiceDays.compactMap { DayKey.dayNumber($0, calendar: calendar) }).sorted()
        guard !days.isEmpty else { return .empty }
        let todayNumber = DayKey.dayNumber(for: today, calendar: calendar)

        var fuel = 1.0, streak = 0, best = 0
        var previous: Int?
        for day in days where day <= todayNumber {
            if let previous {
                fuel -= burnPerMissedDay * Double(day - previous - 1)
                if fuel <= 0 { streak = 0 }
            }
            fuel = 1
            streak += 1
            best = max(best, streak)
            previous = day
        }
        guard let last = previous else { return .empty }
        // Days missed since the last practice, not counting today.
        fuel -= burnPerMissedDay * Double(max(0, todayNumber - last - 1))
        if fuel <= 0 {
            fuel = 0
            streak = 0
        }
        return FuelState(fuel: fuel, streak: streak, bestStreak: best, practisedToday: last == todayNumber)
    }
}

/// Local calendar days as `yyyy-MM-dd` strings, and day numbers for counting gaps.
enum DayKey {
    static func key(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func date(_ key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }

    static func dayNumber(_ key: String, calendar: Calendar = .current) -> Int? {
        date(key, calendar: calendar).map { dayNumber(for: $0, calendar: calendar) }
    }

    /// Whole days since a fixed reference, in the given calendar.
    static func dayNumber(for date: Date, calendar: Calendar = .current) -> Int {
        let reference = calendar.date(from: DateComponents(year: 2000, month: 1, day: 1, hour: 12))!
        let start = calendar.startOfDay(for: date)
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: reference), to: start).day ?? 0
    }
}
