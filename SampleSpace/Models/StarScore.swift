import Foundation

/// How many stars a cleared level earns, and why.
///
/// - ★ for passing every check.
/// - ★ for not using any hints.
/// - ★ for passing within the level's par: at most `par` presses of **Check**.
///   **Run** is free, so trying things out never costs a star.
///
/// Showing the solution caps the attempt at one star.
struct StarScore: Hashable, Sendable {
    var passed: Bool
    var hintsUsed: Int
    var solutionShown: Bool
    var checkAttempts: Int
    var par: Int

    var noHints: Bool { hintsUsed == 0 && !solutionShown }
    var withinPar: Bool { checkAttempts <= par && !solutionShown }

    var stars: Int {
        guard passed else { return 0 }
        if solutionShown { return 1 }
        return 1 + (noHints ? 1 : 0) + (withinPar ? 1 : 0)
    }

    /// One line per star for the completion card.
    var criteria: [(met: Bool, text: String)] {
        let checks = "\(checkAttempts) check\(checkAttempts == 1 ? "" : "s")"
        return [
            (passed, "Passed every check"),
            (noHints, solutionShown ? "Solution was shown" : (hintsUsed == 0 ? "No hints used"
                                                               : "\(hintsUsed) hint\(hintsUsed == 1 ? "" : "s") used")),
            (withinPar, "Solved in \(checks) (par \(par))"),
        ]
    }
}
