import Charts
import SwiftUI

/// Lab: the garden of forking paths. Every simulated study compares two groups drawn from the
/// *same* population, so H₀ is always true and every "finding" is a false alarm. Measure more
/// outcomes and report whichever comes out significant, or peek at the data as it comes in and
/// stop as soon as p < α, and watch the false-alarm rate climb far past α. A Bonferroni correction
/// (α ÷ number of outcomes) pulls the multiple-outcomes rate back down.
@MainActor @Observable
final class PHackingGarden {
    struct Study: Identifiable {
        let id: Int
        /// The outcome that came out "significant", if any.
        let hitOutcome: Int?
        /// The look at which the study stopped (1-based).
        let stoppedAt: Int
        var isHit: Bool { hitOutcome != nil }
    }

    static let alphas: [Double] = [0.01, 0.05, 0.10]
    static let shown = 200
    static let outcomeRange: ClosedRange<Int> = 1...20
    static let lookRange: ClosedRange<Int> = 1...10
    static let nRange: ClosedRange<Int> = 10...100

    /// Outcomes measured in each study; any one significant counts as a finding.
    var outcomes: Int {
        didSet {
            let clamped = outcomes.clamped(to: Self.outcomeRange)
            if clamped != outcomes { outcomes = clamped }
            if outcomes != oldValue { clear() }
        }
    }
    /// How many times the data are tested as they come in (1 = once, at the end).
    var looks: Int {
        didSet {
            let clamped = looks.clamped(to: Self.lookRange)
            if clamped != looks { looks = clamped }
            if looks != oldValue { clear() }
        }
    }
    /// People per group at the end of the study.
    var n: Int {
        didSet {
            let clamped = n.clamped(to: Self.nRange)
            if clamped != n { n = clamped }
            if n != oldValue { clear() }
        }
    }
    var alpha: Double { didSet { if alpha != oldValue { clear() } } }
    var bonferroni: Bool { didSet { if bonferroni != oldValue { clear() } } }

    private(set) var recent: [Study] = []
    private(set) var total = 0
    private(set) var hits = 0
    @ObservationIgnored private var nextID = 0
    @ObservationIgnored private var rng: SplitMix64

    init(outcomes: Int = 1, looks: Int = 1, n: Int = 20, alpha: Double = 0.05, bonferroni: Bool = false,
         seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.outcomes = outcomes.clamped(to: Self.outcomeRange)
        self.looks = looks.clamped(to: Self.lookRange)
        self.n = n.clamped(to: Self.nRange)
        self.alpha = alpha
        self.bonferroni = bonferroni
        rng = SplitMix64(seed: seed)
    }

    convenience init(settings: LabSettings) {
        self.init(outcomes: settings.outcomes ?? 1, looks: settings.looks ?? 1, n: settings.startN ?? 20,
                  alpha: settings.alpha ?? 0.05)
    }

    func clear() {
        recent = []
        total = 0
        hits = 0
    }

    /// α for each single test: divided by the number of outcomes under Bonferroni.
    var perTestAlpha: Double { bonferroni ? alpha / Double(outcomes) : alpha }
    var rate: Double { total > 0 ? Double(hits) / Double(total) : .nan }
    /// The false-alarm rate for independent outcomes tested once each: 1 − (1 − α)^k.
    var theoryRate: Double { 1 - pow(1 - perTestAlpha, Double(outcomes)) }

    /// People per group at each look, e.g. 4, 8, 12, 16, 20 for 5 looks at n = 20.
    var lookSizes: [Int] {
        var sizes: [Int] = []
        for l in 1...looks {
            let size = max(2, Int((Double(n) * Double(l) / Double(looks)).rounded()))
            if sizes.last != size { sizes.append(size) }
        }
        return sizes
    }

    /// Runs `count` studies. Each outcome is a two-sample Student's t-test on fresh N(0, 1) data in
    /// both groups, tested at every look; the study stops at the first significant result.
    func run(_ count: Int) {
        let sizes = lookSizes
        let critical = sizes.map { Stats.tQuantile(1 - perTestAlpha / 2, df: Double(2 * $0 - 2)) }
        let k = outcomes
        var sumA = [Double](repeating: 0, count: k), sqA = sumA, sumB = sumA, sqB = sumA
        for _ in 0..<max(count, 0) {
            for j in 0..<k { sumA[j] = 0; sqA[j] = 0; sumB[j] = 0; sqB[j] = 0 }
            var have = 0
            var hit: Int?
            var stopped = sizes.count
            look: for (l, size) in sizes.enumerated() {
                for j in 0..<k {
                    for _ in have..<size {
                        let a = Stats.normalDraw(&rng), b = Stats.normalDraw(&rng)
                        sumA[j] += a; sqA[j] += a * a
                        sumB[j] += b; sqB[j] += b * b
                    }
                }
                have = size
                let m = Double(size)
                for j in 0..<k {
                    let ssA = sqA[j] - sumA[j] * sumA[j] / m, ssB = sqB[j] - sumB[j] * sumB[j] / m
                    let pooled = (ssA + ssB) / (2 * m - 2)
                    let t = (sumA[j] / m - sumB[j] / m) / (pooled * 2 / m).squareRoot()
                    if abs(t) > critical[l] {
                        hit = j
                        stopped = l + 1
                        break look
                    }
                }
            }
            total += 1
            if hit != nil { hits += 1 }
            recent.append(Study(id: nextID, hitOutcome: hit, stoppedAt: stopped))
            nextID += 1
        }
        if recent.count > Self.shown { recent.removeFirst(recent.count - Self.shown) }
    }

    var readings: [String: Double] {
        [
            "outcomes": Double(outcomes), "looks": Double(looks), "n": Double(n), "alpha": alpha,
            "bonferroni": bonferroni ? 1 : 0, "studies": Double(total), "false_positive_rate": rate,
            "theory_rate": theoryRate, "per_test_alpha": perTestAlpha,
        ]
    }
}

// MARK: - View

struct PHackingGardenView: View {
    @Bindable var lab: PHackingGarden

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Every study compares two groups drawn from the same population: there is never a real effect, so every red flower is a false alarm.")
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 16) {
                garden.frame(width: 330, height: 170)
                VStack(alignment: .leading, spacing: 10) {
                    LabStat(title: "Studies run", value: "\(lab.total)")
                    LabStat(title: "Reported a \"finding\"", value: percent(lab.rate), tint: Theme.fail)
                    LabStat(title: lab.looks > 1 ? "Expected without peeking" : "Expected",
                            value: percent(lab.theoryRate), tint: Theme.gold)
                }
                .frame(minWidth: 150, alignment: .leading)
            }
            comparison.frame(height: 100)
            controls
        }
    }

    private func percent(_ x: Double) -> String { x.isFinite ? String(format: "%.1f%%", x * 100) : "–" }

    /// The latest 200 studies: green sprouts found nothing, red flowers "found" something.
    private var garden: some View {
        Canvas { context, size in
            let columns = 20, rows = 10
            let w = size.width / CGFloat(columns), h = size.height / CGFloat(rows)
            for (index, study) in lab.recent.enumerated() {
                let c = index % columns, r = index / columns
                let center = CGPoint(x: (CGFloat(c) + 0.5) * w, y: (CGFloat(r) + 0.5) * h)
                if study.isHit {
                    let petal = min(w, h) * 0.2
                    for a in 0..<5 {
                        let angle = Double(a) / 5 * 2 * .pi
                        let p = CGPoint(x: center.x + cos(angle) * petal, y: center.y + sin(angle) * petal)
                        context.fill(Path(ellipseIn: CGRect(x: p.x - petal, y: p.y - petal, width: 2 * petal, height: 2 * petal)),
                                     with: .color(Theme.fail.opacity(0.85)))
                    }
                    context.fill(Path(ellipseIn: CGRect(x: center.x - petal * 0.7, y: center.y - petal * 0.7,
                                                        width: petal * 1.4, height: petal * 1.4)), with: .color(Theme.gold))
                } else {
                    var stem = Path()
                    stem.move(to: CGPoint(x: center.x, y: center.y + h * 0.3))
                    stem.addLine(to: CGPoint(x: center.x, y: center.y - h * 0.1))
                    context.stroke(stem, with: .color(Theme.pass.opacity(0.6)), lineWidth: 1.5)
                    context.fill(Path(ellipseIn: CGRect(x: center.x - 2.5, y: center.y - h * 0.1 - 2.5, width: 5, height: 5)),
                                 with: .color(Theme.pass.opacity(0.7)))
                }
            }
        }
        .background(.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            if lab.recent.isEmpty {
                Text("Run some studies").font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Garden of the latest \(lab.recent.count) studies")
        .accessibilityValue("\(lab.recent.filter(\.isHit).count) reported a finding")
    }

    private var comparison: some View {
        let bars: [(String, Double, Color)] = [
            ("α for one test", lab.alpha, .white.opacity(0.5)),
            (lab.looks > 1 ? "Expected without peeking" : "Expected", lab.theoryRate, Theme.gold),
            ("Your garden", lab.rate.isFinite ? lab.rate : 0, Theme.fail),
        ]
        return Chart(bars, id: \.0) { bar in
            BarMark(x: .value("False-alarm rate", bar.1), y: .value("", bar.0))
                .foregroundStyle(bar.2)
                .annotation(position: .trailing) {
                    Text(String(format: "%.1f%%", bar.1 * 100)).font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in AxisValueLabel() }
        }
        .chartXScale(domain: 0...max(0.25, min(1, (bars.map(\.1).max() ?? 0) * 1.25)))
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int((v * 100).rounded()))%") } }
            }
        }
    }

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Outcomes per study")
                Stepper(value: $lab.outcomes, in: PHackingGarden.outcomeRange) {
                    Text("\(lab.outcomes)\(lab.outcomes == 1 ? "" : ": report whichever is significant")").monospacedDigit()
                }
            }
            GridRow {
                Text("Looks at the data")
                Stepper(value: $lab.looks, in: PHackingGarden.lookRange) {
                    Text(lab.looks == 1 ? "1: test once, at the end"
                         : "\(lab.looks): test after every \(lab.n / lab.looks) per group, stop at p < α").monospacedDigit()
                }
            }
            GridRow {
                Text("People per group")
                Stepper(value: $lab.n, in: PHackingGarden.nRange, step: 10) { Text("\(lab.n)").monospacedDigit() }
            }
            GridRow {
                Text("α")
                HStack {
                    Picker("α", selection: $lab.alpha) {
                        ForEach(PHackingGarden.alphas, id: \.self) { Text(String(format: "%.2f", $0)).tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    Toggle("Bonferroni (α ÷ outcomes = \(String(format: "%.4g", lab.perTestAlpha)))", isOn: $lab.bonferroni)
                }
            }
            GridRow {
                Text("Run")
                HStack {
                    Button("1 study") { lab.run(1) }
                    Button("100 studies") { lab.run(100) }
                    Button("1,000 studies") { lab.run(1000) }
                    Button("Clear") { lab.clear() }.disabled(lab.total == 0)
                }
            }
        }
        .font(.callout)
    }
}
