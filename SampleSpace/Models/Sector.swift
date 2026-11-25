import SwiftUI

enum SectorStatus: Sendable {
    case locked, current, completed
}

/// One system on the star map. Placeholder data for now; Step 3 replaces this with
/// sectors loaded from the Content/ folder.
struct Sector: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let rSkills: String
    let statsConcepts: String
    let hue: Double
    /// Position on the map, in 0–1 coordinates.
    let mapPosition: CGPoint
    let planetSize: CGFloat
    var status: SectorStatus = .locked
    var isOptional = false
    var hasRing = false

    var color: Color { .planet(hue: hue) }
}

extension Sector {
    static let placeholderMap: [Sector] = [
        Sector(id: 0, name: "Launch Pad", rSkills: "Console, arithmetic, objects, functions, help",
               statsConcepts: "—", hue: 0.55, mapPosition: CGPoint(x: 0.07, y: 0.78), planetSize: 70,
               status: .current),
        Sector(id: 1, name: "Vector Belt", rSkills: "c(), indexing, types, NA, factors",
               statsConcepts: "Levels of measurement", hue: 0.08, mapPosition: CGPoint(x: 0.17, y: 0.52),
               planetSize: 58, hasRing: true),
        Sector(id: 2, name: "Data Frame Docks", rSkills: "Data frames, tibbles, read_csv, haven::read_sav",
               statsConcepts: "Variables vs. cases", hue: 0.33, mapPosition: CGPoint(x: 0.27, y: 0.76),
               planetSize: 64),
        Sector(id: 3, name: "Wrangler's Reach", rSkills: "dplyr verbs, pipes, recoding, missing data",
               statsConcepts: "Reverse-scoring, composite scales", hue: 0.95,
               mapPosition: CGPoint(x: 0.37, y: 0.50), planetSize: 60),
        Sector(id: 4, name: "Descriptive Drift", rSkills: "mean, sd, psych::describe, tables",
               statsConcepts: "Central tendency, spread, skew, z-scores", hue: 0.15,
               mapPosition: CGPoint(x: 0.30, y: 0.22), planetSize: 56),
        Sector(id: 5, name: "Plot Nebula", rSkills: "ggplot2", statsConcepts: "Reading distributions visually",
               hue: 0.78, mapPosition: CGPoint(x: 0.45, y: 0.15), planetSize: 66, hasRing: true),
        Sector(id: 6, name: "Probability Expanse", rSkills: "rnorm, pnorm, sample, replicate",
               statsConcepts: "Sampling distributions, CLT, standard error", hue: 0.48,
               mapPosition: CGPoint(x: 0.55, y: 0.38), planetSize: 72),
        Sector(id: 7, name: "Inference Station", rSkills: "Simulation",
               statsConcepts: "p-values, CIs, Type I/II error, effect size, power", hue: 0.62,
               mapPosition: CGPoint(x: 0.50, y: 0.67), planetSize: 62),
        Sector(id: 8, name: "Means Cluster", rSkills: "t.test, leveneTest, cohens_d",
               statsConcepts: "One-sample, independent and paired t-tests", hue: 0.02,
               mapPosition: CGPoint(x: 0.63, y: 0.83), planetSize: 58),
        Sector(id: 9, name: "Variance Rift", rSkills: "aov, TukeyHSD, afex",
               statsConcepts: "One-way, factorial, repeated-measures ANOVA", hue: 0.70,
               mapPosition: CGPoint(x: 0.74, y: 0.60), planetSize: 68, hasRing: true),
        Sector(id: 10, name: "Relationship Ring", rSkills: "cor.test, chisq.test, lm",
               statsConcepts: "Correlation, chi-square, regression", hue: 0.40,
               mapPosition: CGPoint(x: 0.70, y: 0.28), planetSize: 64),
        Sector(id: 11, name: "Dissertation Dock", rSkills: "Quarto, APA tables, renv",
               statsConcepts: "A full reproducible analysis", hue: 0.12,
               mapPosition: CGPoint(x: 0.85, y: 0.17), planetSize: 80),
        Sector(id: 12, name: "Python Wormhole", rSkills: "pandas, statsmodels, seaborn",
               statsConcepts: "The same analyses in Python", hue: 0.85,
               mapPosition: CGPoint(x: 0.92, y: 0.50), planetSize: 54, isOptional: true),
    ]
}

/// Player stats shown in the HUD. Placeholder until Step 5 adds real progress.
struct PlayerSnapshot: Sendable {
    var rank = "Cadet"
    var xp = 0
    var stars = 0
    var fuel = 1.0
}
