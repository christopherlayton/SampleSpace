import Foundation

/// Badges: one-off achievements shown on the Pilot Profile.
///
/// Most are worked out from saved progress after each clear. A few depend on something that
/// happened during a run (a plot was drawn, an error was fixed) and are awarded at that moment.
struct Badge: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let detail: String
    let symbol: String

    static let all: [Badge] = [
        Badge(id: "lift-off", title: "Lift-off", detail: "Clear your first level.", symbol: "airplane.departure"),
        Badge(id: "perfect-landing", title: "Perfect Landing", detail: "Earn three stars on a level.",
              symbol: "star.circle.fill"),
        Badge(id: "solo-flight", title: "Solo Flight", detail: "Clear five levels without hints.",
              symbol: "person.fill.checkmark"),
        Badge(id: "first-plot", title: "First Plot", detail: "Draw your first plot in R.",
              symbol: "chart.xyaxis.line"),
        Badge(id: "bug-hunter", title: "Bug Hunter", detail: "Clear a level after your code hit an error.",
              symbol: "ladybug.fill"),
        Badge(id: "sector-charted", title: "Sector Charted", detail: "Clear every level in a sector.",
              symbol: "map.fill"),
        Badge(id: "star-collector", title: "Star Collector",
              detail: "Earn three stars on every level in a sector.", symbol: "sparkles"),
        Badge(id: "three-day-burn", title: "Three-Day Burn", detail: "Reach a 3-day streak.",
              symbol: "flame.fill"),
        Badge(id: "week-in-orbit", title: "Week in Orbit", detail: "Reach a 7-day streak.",
              symbol: "globe.americas.fill"),
        Badge(id: "assumption-checker", title: "Assumption Checker",
              detail: "Clear a level that checks an assumption, e.g. with shapiro.test() or leveneTest().",
              symbol: "checkmark.shield.fill"),
        Badge(id: "spss-defector", title: "SPSS Defector", detail: "Clear your first SPSS Translate level.",
              symbol: "arrow.left.arrow.right.circle.fill"),
        Badge(id: "null-survivor", title: "Null Hypothesis Survivor",
              detail: "Chart every level in Inference Station.", symbol: "shield.lefthalf.filled"),
        Badge(id: "nebula-regular", title: "Nebula Regular",
              detail: "Meet the daily review goal in the Review Nebula on 5 days.", symbol: "sparkles"),
    ]

    static func named(_ id: String) -> Badge? { all.first { $0.id == id } }

    /// Sector id of Inference Station, for "Null Hypothesis Survivor".
    static let inferenceSectorID = 7

    /// Badges the saved progress has earned (whether or not they were already recorded).
    /// `clearedCode` is the code that just passed, for code-based badges.
    static func earned(by progress: PilotProgress, sectors: [Sector], streak: FuelState,
                       clearedLevel: Level?, clearedCode: String?) -> Set<String> {
        var ids = Set<String>()
        let cleared = progress.levels
        if !cleared.isEmpty { ids.insert("lift-off") }
        if cleared.values.contains(where: { $0.bestStars == 3 }) { ids.insert("perfect-landing") }
        if cleared.values.filter(\.clearedWithoutHints).count >= 5 { ids.insert("solo-flight") }

        let charted = sectors.filter { !$0.levels.isEmpty && $0.levels.allSatisfy { cleared[$0.id] != nil } }
        if !charted.isEmpty { ids.insert("sector-charted") }
        if charted.contains(where: { $0.levels.allSatisfy { cleared[$0.id]?.bestStars == 3 } }) {
            ids.insert("star-collector")
        }
        if charted.contains(where: { $0.id == inferenceSectorID }) { ids.insert("null-survivor") }

        if progress.review.goalDays >= 5 { ids.insert("nebula-regular") }
        if streak.bestStreak >= 3 { ids.insert("three-day-burn") }
        if streak.bestStreak >= 7 { ids.insert("week-in-orbit") }

        let levels = sectors.flatMap(\.levels)
        if levels.contains(where: { $0.type == .spssTranslate && cleared[$0.id] != nil }) {
            ids.insert("spss-defector")
        }
        if let code = clearedCode, clearedLevel != nil,
           ["shapiro.test(", "leveneTest(", "levene_test(", "check_model("].contains(where: code.contains) {
            ids.insert("assumption-checker")
        }
        return ids
    }
}
