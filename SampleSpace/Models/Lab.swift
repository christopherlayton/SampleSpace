import Foundation

/// The interactive simulations ("Labs"). Each kind is a native instrument that publishes named
/// numeric **readings** (e.g. `mean`, `area`, `se`); a lab level's goals are conditions on them.
enum LabKind: String, Sendable, Codable, CaseIterable {
    case distributionSculptor = "distribution_sculptor"
    case samplingMachine = "sampling_machine"

    var title: String {
        switch self {
        case .distributionSculptor: "Distribution Sculptor"
        case .samplingMachine: "Sampling Machine"
        }
    }

    var symbol: String {
        switch self {
        case .distributionSculptor: "bell.fill"
        case .samplingMachine: "square.stack.3d.down.right.fill"
        }
    }

    var blurb: String {
        switch self {
        case .distributionSculptor:
            "Shape a normal curve with its mean and SD, shade areas and read them as proportions and z-scores."
        case .samplingMachine:
            "Draw random crews from the Crew Log and watch their averages pile up into a sampling distribution."
        }
    }

    /// Every reading the instrument publishes, with what it means. Goal conditions may only use
    /// these names (a test checks the content).
    var readings: [String: String] {
        switch self {
        case .distributionSculptor: [
            "mean": "mean of the curve",
            "sd": "standard deviation of the curve",
            "cutoff": "the first cutoff (x value)",
            "z": "z-score of the first cutoff",
            "lower": "the lower of the two cutoffs",
            "upper": "the upper of the two cutoffs",
            "z_lower": "z-score of the lower cutoff",
            "z_upper": "z-score of the upper cutoff",
            "area": "proportion of the curve shaded (0–1)",
            "shade_below": "1 when shading below the cutoff",
            "shade_above": "1 when shading above the cutoff",
            "shade_between": "1 when shading between the cutoffs",
            "shade_outside": "1 when shading both tails outside the cutoffs",
        ]
        case .samplingMachine: [
            "n": "sample (crew) size",
            "samples": "samples drawn at this size",
            "mean_of_means": "mean of the sample means",
            "se": "SD of the sample means (the simulated standard error)",
            "theory_se": "σ / √n",
            "skew": "skewness of the sample means",
            "pop_mean": "population mean",
            "pop_sd": "population SD",
        ]
        }
    }
}

/// The `lab` object in a lab level's level.json:
///
///     "lab": {
///       "kind": "distribution_sculptor",
///       "settings": { "start_mean": 100, "start_sd": 15, "x_range": [40, 160] },
///       "goals": [
///         { "text": "Set the curve to mean 100, SD 15.",
///           "when": [ { "reading": "mean", "equals": 100, "tolerance": 0.5 },
///                     { "reading": "sd", "min": 14.75, "max": 15.25 } ] }
///       ]
///     }
struct LabSpec: Hashable, Sendable, Decodable {
    let kind: LabKind
    var settings = LabSettings()
    var goals: [LabGoal] = []

    enum CodingKeys: String, CodingKey { case kind, settings, goals }

    init(kind: LabKind, settings: LabSettings = LabSettings(), goals: [LabGoal] = []) {
        self.kind = kind
        self.settings = settings
        self.goals = goals
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(LabKind.self, forKey: .kind)
        settings = try c.decodeIfPresent(LabSettings.self, forKey: .settings) ?? LabSettings()
        goals = try c.decodeIfPresent([LabGoal].self, forKey: .goals) ?? []
    }
}

/// Starting values and ranges for an instrument. Every field is optional; each lab has defaults.
/// Keys in level.json are snake_case (`start_sd`, `x_range`, …).
struct LabSettings: Hashable, Sendable, Decodable {
    // Distribution Sculptor
    var startMean: Double?
    var startSd: Double?
    var meanRange: [Double]?
    var sdRange: [Double]?
    var xRange: [Double]?
    /// "below", "above", "between" or "outside".
    var shade: String?
    var cutoff: Double?
    var cutoff2: Double?

    // Sampling Machine
    /// A CSV in the level folder holding the population.
    var populationFile: String?
    var populationColumn: String?
    var populationLabel: String?
    var unit: String?
    var startN: Int?
    var maxN: Int?
}

/// One goal: met when every condition holds at the same moment. Once met it stays met.
struct LabGoal: Hashable, Sendable, Decodable {
    let text: String
    var detail: String?
    let when: [LabCondition]

    func isMet(by readings: [String: Double]) -> Bool {
        !when.isEmpty && when.allSatisfy { $0.holds(in: readings) }
    }
}

/// A condition on one reading: `equals` (± `tolerance`, default 1e-9), and/or `min`/`max`.
struct LabCondition: Hashable, Sendable, Decodable {
    let reading: String
    var equals: Double?
    var tolerance: Double?
    var min: Double?
    var max: Double?

    func holds(in readings: [String: Double]) -> Bool {
        guard let value = readings[reading], value.isFinite else { return false }
        if let equals, abs(value - equals) > (tolerance ?? 1e-9) { return false }
        if let min, value < min { return false }
        if let max, value > max { return false }
        return true
    }
}

/// Which goals a lab attempt has reached. Goals latch: moving a slider away afterwards doesn't
/// un-meet them.
struct LabGoalTracker: Equatable, Sendable {
    let goals: [LabGoal]
    private(set) var reached: Set<Int> = []

    init(goals: [LabGoal]) { self.goals = goals }

    var allReached: Bool { reached.count == goals.count }
    /// The first goal not yet reached, to highlight as "current".
    var current: Int? { goals.indices.first { !reached.contains($0) } }

    /// Updates from fresh readings. Returns the goals that were reached just now.
    @discardableResult
    mutating func update(_ readings: [String: Double]) -> [Int] {
        let newly = goals.indices.filter { !reached.contains($0) && goals[$0].isMet(by: readings) }
        reached.formUnion(newly)
        return newly
    }
}

// MARK: - Statistics helpers

enum Stats {
    /// Standard normal cumulative probability, Φ(z).
    static func normalCDF(_ z: Double) -> Double { 0.5 * erfc(-z / 2.0.squareRoot()) }

    static func normalDensity(_ x: Double, mean: Double, sd: Double) -> Double {
        let z = (x - mean) / sd
        return exp(-0.5 * z * z) / (sd * (2 * Double.pi).squareRoot())
    }

    static func mean(_ x: [Double]) -> Double {
        x.isEmpty ? .nan : x.reduce(0, +) / Double(x.count)
    }

    /// Sample SD (n − 1), like R's `sd()`.
    static func sd(_ x: [Double]) -> Double {
        guard x.count > 1 else { return .nan }
        let m = mean(x)
        return (x.reduce(0) { $0 + ($1 - m) * ($1 - m) } / Double(x.count - 1)).squareRoot()
    }

    /// Moment skewness, Σ(x − m)³/n ÷ (Σ(x − m)²/n)^1.5 (0 for a symmetric shape).
    static func skewness(_ x: [Double]) -> Double {
        guard x.count > 2 else { return .nan }
        let m = mean(x)
        let n = Double(x.count)
        var m2 = 0.0, m3 = 0.0
        for v in x {
            let d = v - m
            m2 += d * d
            m3 += d * d * d
        }
        m2 /= n
        m3 /= n
        return m2 > 0 ? m3 / pow(m2, 1.5) : 0
    }
}
