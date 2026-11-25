import Charts
import SwiftUI

/// Lab: the null hypothesis on trial. Set a two-group study's evidence (mean difference, pooled
/// SD, n per group) and see where its t statistic falls on the t distribution H₀ predicts. The
/// shaded tail is the p-value; the verdict compares it with α. A simulation runs the study many
/// times in a world where H₀ is true, so the p-value becomes a proportion you can count.
@MainActor @Observable
final class PValueCourtroom {
    enum Tails: String, CaseIterable, Identifiable, Sendable {
        case two, greater, less
        var id: Self { self }
        var title: String {
            switch self {
            case .two: "Two-sided"
            case .greater: "Greater"
            case .less: "Less"
            }
        }
        var rAlternative: String {
            switch self {
            case .two: "two.sided"
            case .greater: "greater"
            case .less: "less"
            }
        }
    }

    static let alphas: [Double] = [0.10, 0.05, 0.01]

    let label: String
    let diffRange: ClosedRange<Double>
    let sdRange: ClosedRange<Double>
    let maxN: Int

    var diff: Double { didSet { if diff != oldValue { diff = diff.clamped(to: diffRange); resetSimulation() } } }
    var sd: Double { didSet { if sd != oldValue { sd = sd.clamped(to: sdRange); resetSimulation() } } }
    var n: Int {
        didSet {
            let clamped = min(max(n, 2), maxN)
            if clamped != n { n = clamped }
            if n != oldValue { resetSimulation() }
        }
    }
    var tails: Tails
    var alpha: Double
    /// t statistics from studies simulated under H₀ at the current n and SD.
    private(set) var simulated: [Double] = []
    @ObservationIgnored private var rng: SplitMix64

    init(label: String = "Difference in post-test anxiety (points)", diff: Double = 1.8, sd: Double = 6.5,
         n: Int = 19, maxN: Int = 500, diffRange: ClosedRange<Double> = -10...10,
         sdRange: ClosedRange<Double> = 1...20, tails: Tails = .two, alpha: Double = 0.05,
         seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.label = label
        self.diffRange = diffRange
        self.sdRange = sdRange
        self.maxN = max(maxN, 2)
        self.diff = diff.clamped(to: diffRange)
        self.sd = sd.clamped(to: sdRange)
        self.n = min(max(n, 2), max(maxN, 2))
        self.tails = tails
        self.alpha = alpha
        rng = SplitMix64(seed: seed)
    }

    convenience init(settings: LabSettings) {
        func range(_ values: [Double]?, _ fallback: ClosedRange<Double>) -> ClosedRange<Double> {
            guard let values, values.count == 2, values[0] < values[1] else { return fallback }
            return values[0]...values[1]
        }
        self.init(label: settings.populationLabel ?? "Difference in post-test anxiety (points)",
                  diff: settings.startDiff ?? 1.8, sd: settings.startSd ?? 6.5, n: settings.startN ?? 19,
                  maxN: settings.maxN ?? 500, diffRange: range(settings.diffRange, -10...10),
                  sdRange: range(settings.sdRange, 1...20),
                  tails: settings.tails.flatMap(Tails.init(rawValue:)) ?? .two, alpha: settings.alpha ?? 0.05)
    }

    // MARK: The test

    var df: Double { Double(2 * n - 2) }
    var se: Double { sd * (2 / Double(n)).squareRoot() }
    var t: Double { diff / se }

    /// Probability, under H₀, of a t at least as extreme as this one, in the direction(s) tested.
    func pValue(for t: Double) -> Double {
        switch tails {
        case .two: 2 * Stats.tCDF(-abs(t), df: df)
        case .greater: 1 - Stats.tCDF(t, df: df)
        case .less: Stats.tCDF(t, df: df)
        }
    }

    var p: Double { pValue(for: t) }
    var reject: Bool { p < alpha }
    /// The critical t (positive) beyond which H₀ is rejected.
    var critical: Double { Stats.tQuantile(1 - alpha / (tails == .two ? 2 : 1), df: df) }

    func isAsExtreme(_ value: Double) -> Bool {
        switch tails {
        case .two: abs(value) >= abs(t)
        case .greater: value >= t
        case .less: value <= t
        }
    }

    // MARK: Simulation

    /// Runs `count` studies in a world where H₀ is true: two groups of n from the same normal
    /// population with this SD, each giving a pooled-variance t.
    func simulate(_ count: Int = 1000) {
        var results: [Double] = []
        results.reserveCapacity(count)
        for _ in 0..<count {
            var a = [Double](), b = [Double]()
            a.reserveCapacity(n); b.reserveCapacity(n)
            for _ in 0..<n { a.append(sd * Stats.normalDraw(&rng)) }
            for _ in 0..<n { b.append(sd * Stats.normalDraw(&rng)) }
            let pooled = ((Stats.sd(a) * Stats.sd(a) + Stats.sd(b) * Stats.sd(b)) / 2).squareRoot()
            results.append((Stats.mean(a) - Stats.mean(b)) / (pooled * (2 / Double(n)).squareRoot()))
        }
        simulated.append(contentsOf: results)
        if simulated.count > 20_000 { simulated.removeFirst(simulated.count - 20_000) }
    }

    func resetSimulation() { simulated = [] }

    var simulatedP: Double {
        simulated.isEmpty ? .nan : Double(simulated.count(where: isAsExtreme)) / Double(simulated.count)
    }

    // MARK: Readings

    var readings: [String: Double] {
        [
            "t": t, "df": df, "p": p, "alpha": alpha, "critical": critical,
            "reject": reject ? 1 : 0, "two_sided": tails == .two ? 1 : 0, "one_sided": tails == .two ? 0 : 1,
            "n": Double(n), "diff": diff, "sd": sd,
            "simulations": Double(simulated.count), "sim_p": simulatedP,
        ]
    }

    var rCode: String {
        let tt = String(format: "%.3f", t), d = DistributionSculptor.format(df)
        return switch tails {
        case .two: "2 * pt(-abs(\(tt)), df = \(d))"
        case .greater: "pt(\(tt), df = \(d), lower.tail = FALSE)"
        case .less: "pt(\(tt), df = \(d))"
        }
    }

    // MARK: Drawing

    static let tRange: ClosedRange<Double> = -5...5

    func nullCurve(points: Int = 240) -> [DistributionSculptor.Point] {
        let lo = Self.tRange.lowerBound, hi = Self.tRange.upperBound
        return (0...points).map { i in
            let x = lo + (hi - lo) * Double(i) / Double(points)
            return .init(id: i, x: x, y: Stats.tDensity(x, df: df))
        }
    }

    /// The curve with only the region `inside` kept, with vertical edges at the boundaries.
    func shaded(points: Int = 240, inside: (Double) -> Bool, edges: [Double]) -> [DistributionSculptor.Point] {
        let lo = Self.tRange.lowerBound, hi = Self.tRange.upperBound
        let step = (hi - lo) / Double(points)
        let tiny = step / 1000
        let grid = ((0...points).map { lo + Double($0) * step } + edges.filter { Self.tRange.contains($0) }).sorted()
        var result: [DistributionSculptor.Point] = []
        for x in grid {
            if edges.contains(x) {
                result.append(.init(id: result.count, x: x, y: inside(x - tiny) ? Stats.tDensity(x, df: df) : 0))
                result.append(.init(id: result.count, x: x, y: inside(x + tiny) ? Stats.tDensity(x, df: df) : 0))
            } else {
                result.append(.init(id: result.count, x: x, y: inside(x) ? Stats.tDensity(x, df: df) : 0))
            }
        }
        return result
    }

    var pRegion: [DistributionSculptor.Point] {
        let edges = tails == .two ? [-abs(t), abs(t)] : [t]
        return shaded(inside: isAsExtreme, edges: edges)
    }

    var rejectionRegion: [DistributionSculptor.Point] {
        let c = critical
        switch tails {
        case .two: return shaded(inside: { abs($0) >= c }, edges: [-c, c])
        case .greater: return shaded(inside: { $0 >= c }, edges: [c])
        case .less: return shaded(inside: { $0 <= -c }, edges: [-c])
        }
    }

    var simulatedBins: [SamplingMachine.Bin] {
        SamplingMachine.bins(simulated.filter { Self.tRange.contains($0) }, domain: Self.tRange, count: 60)
    }
}

// MARK: - View

struct PValueCourtroomView: View {
    @Bindable var lab: PValueCourtroom

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("On trial: H₀, \"the two groups don't differ\". The curve is what t looks like if H₀ is true.")
                    .font(.caption.weight(.semibold))
                Text("Your evidence: \(lab.label) = \(DistributionSculptor.format(lab.diff, decimals: 2)), SD \(DistributionSculptor.format(lab.sd, decimals: 2)), n = \(lab.n) per group.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            chart.frame(height: 240)
            verdict
            controls
        }
    }

    private var chart: some View {
        let bins = lab.simulatedBins
        let binWidth = (PValueCourtroom.tRange.upperBound - PValueCourtroom.tRange.lowerBound) / 60
        let scale = Double(lab.simulated.count) * binWidth
        let observed = lab.t.clamped(to: PValueCourtroom.tRange)
        return Chart {
            if !lab.simulated.isEmpty {
                ForEach(bins.filter { $0.count > 0 }) { bin in
                    RectangleMark(xStart: .value("From", bin.start), xEnd: .value("To", bin.end),
                                  yStart: .value("Density", 0), yEnd: .value("Density", Double(bin.count) / scale))
                        .foregroundStyle(.white.opacity(lab.isAsExtreme(bin.mid) ? 0.35 : 0.12))
                }
            }
            ForEach(lab.rejectionRegion) { point in
                AreaMark(x: .value("t", point.x), y: .value("Density", point.y), series: .value("Region", "reject"))
                    .foregroundStyle(Theme.fail.opacity(0.18))
                    .interpolationMethod(.linear)
            }
            ForEach(lab.pRegion) { point in
                AreaMark(x: .value("t", point.x), y: .value("Density", point.y), series: .value("Region", "p"))
                    .foregroundStyle(Theme.accent.opacity(0.55))
                    .interpolationMethod(.linear)
            }
            ForEach(lab.nullCurve()) { point in
                LineMark(x: .value("t", point.x), y: .value("Density", point.y), series: .value("Series", "null"))
                    .foregroundStyle(.white)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            ForEach(lab.tails == .two ? [-lab.critical, lab.critical] : [lab.tails == .greater ? lab.critical : -lab.critical],
                    id: \.self) { c in
                RuleMark(x: .value("Critical t", c))
                    .foregroundStyle(Theme.fail.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
            RuleMark(x: .value("Observed t", observed))
                .foregroundStyle(Theme.gold)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .annotation(position: .top, spacing: 2) {
                    Text("t = \(String(format: "%.2f", lab.t))\(abs(lab.t) > 5 ? " (off the chart)" : "")")
                        .font(.caption.monospacedDigit().weight(.semibold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.gold.opacity(0.85), in: Capsule())
                        .foregroundStyle(.black)
                }
        }
        .chartXScale(domain: PValueCourtroom.tRange)
        .chartYScale(domain: 0...0.45)
        .chartYAxis(.hidden)
        .chartXAxisLabel("t under H₀ (df = \(DistributionSculptor.format(lab.df)))", alignment: .trailing)
        .padding(.top, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Null distribution of t with the observed t marked")
        .accessibilityValue("t = \(String(format: "%.2f", lab.t)), p = \(pText(lab.p))")
    }

    private func pText(_ p: Double) -> String {
        p < 0.001 ? "< .001" : String(format: "%.3f", p).replacingOccurrences(of: "0.", with: ".")
    }

    private var verdict: some View {
        HStack(alignment: .top, spacing: 16) {
            LabStat(title: "t", value: String(format: "%.2f", lab.t))
            LabStat(title: "p", value: pText(lab.p), tint: Theme.accent)
            LabStat(title: "α", value: String(format: "%.2f", lab.alpha).replacingOccurrences(of: "0.", with: "."))
            VStack(alignment: .leading, spacing: 3) {
                Label(lab.reject ? "Verdict: reject H₀" : "Verdict: not enough evidence to reject H₀",
                      systemImage: lab.reject ? "hammer.fill" : "scale.3d")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(lab.reject ? Theme.gold : .primary)
                Text("If H₀ were true, a result at least this extreme would turn up in \(percent(lab.p)) of studies like this one.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !lab.simulated.isEmpty {
                    Text("Simulated under H₀: \(lab.simulated.count(where: lab.isAsExtreme)) of \(lab.simulated.count) studies were as extreme (\(percent(lab.simulatedP))).")
                        .font(.caption.monospacedDigit()).foregroundStyle(Theme.accent)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func percent(_ p: Double) -> String {
        p < 0.001 ? "fewer than 0.1%" : String(format: "%.1f%%", p * 100)
    }

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Mean difference")
                Slider(value: Binding(get: { lab.diff }, set: { lab.diff = ($0 * 10).rounded() / 10 }), in: lab.diffRange)
                NumberField(value: $lab.diff)
            }
            GridRow {
                Text("Pooled SD")
                Slider(value: Binding(get: { lab.sd }, set: { lab.sd = ($0 * 10).rounded() / 10 }), in: lab.sdRange)
                NumberField(value: $lab.sd)
            }
            GridRow {
                Text("n per group")
                Slider(value: Binding(get: { Double(lab.n) }, set: { lab.n = Int($0.rounded()) }), in: 2...Double(lab.maxN))
                Stepper(value: $lab.n, in: 2...lab.maxN) {
                    Text("\(lab.n)").monospacedDigit().frame(minWidth: 32, alignment: .trailing)
                }
            }
            GridRow {
                Text("Test")
                HStack {
                    Picker("Tails", selection: $lab.tails) {
                        ForEach(PValueCourtroom.Tails.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented).labelsHidden().fixedSize()
                    Picker("α", selection: $lab.alpha) {
                        ForEach(PValueCourtroom.alphas, id: \.self) {
                            Text("α = " + String(format: "%.2f", $0).replacingOccurrences(of: "0.", with: ".")).tag($0)
                        }
                    }
                    .pickerStyle(.segmented).labelsHidden().fixedSize()
                }
                .gridCellColumns(2)
            }
            GridRow {
                Text("Retrial")
                HStack {
                    Button("Simulate 1,000 studies under H₀") { lab.simulate(1000) }
                    Button("Clear") { lab.resetSimulation() }.disabled(lab.simulated.isEmpty)
                    Spacer()
                    Text(RSyntax.attributed(lab.rCode))
                        .font(Theme.codeFont)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Theme.editorBackground, in: RoundedRectangle(cornerRadius: 6))
                }
                .gridCellColumns(2)
            }
        }
        .font(.callout)
    }
}
