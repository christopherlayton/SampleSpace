import Charts
import SwiftUI

/// Lab: draw samples from a population whose mean μ you know, build a t confidence interval from
/// each, and watch them fall like rain. Green intervals capture μ, red ones miss. About 95% of 95%
/// intervals capture it in the long run, but any single interval either does or doesn't.
@MainActor @Observable
final class CIRain {
    struct Interval: Identifiable {
        let id: Int
        let mean: Double
        let lower: Double
        let upper: Double
        var covers: Bool
        var width: Double { upper - lower }
    }

    static let levels: [Double] = [0.80, 0.90, 0.95, 0.99]
    /// The most intervals kept at one setting.
    static let maxIntervals = 10_000
    /// How many of the latest intervals are drawn.
    static let shown = 60

    let mu: Double
    let sigma: Double
    let label: String
    let unit: String
    let maxN: Int
    /// Fixed x-axis: wide enough for most intervals at small n.
    let xDomain: ClosedRange<Double>

    /// Sample size. Changing it starts a new set of intervals.
    var n: Int {
        didSet {
            let clamped = min(max(n, 2), maxN)
            if clamped != n { n = clamped }
            if n != oldValue { clear() }
        }
    }
    /// Confidence level (0.95 for 95%). Changing it starts a new set.
    var level: Double { didSet { if level != oldValue { clear() } } }
    private(set) var intervals: [Interval] = []
    private(set) var isAuto = false
    @ObservationIgnored private var nextID = 0
    @ObservationIgnored private var rng: SplitMix64
    @ObservationIgnored private var autoTask: Task<Void, Never>?

    init(mu: Double = 40, sigma: Double = 5, label: String = "Age at first flight", unit: String = "years",
         startN: Int = 10, maxN: Int = 200, level: Double = 0.95,
         seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.mu = mu
        self.sigma = max(sigma, 1e-9)
        self.label = label
        self.unit = unit
        self.maxN = max(maxN, 2)
        n = min(max(startN, 2), max(maxN, 2))
        self.level = level
        xDomain = (mu - 3 * sigma)...(mu + 3 * sigma)
        rng = SplitMix64(seed: seed)
    }

    convenience init(settings: LabSettings) {
        self.init(mu: settings.mu ?? 40, sigma: settings.sigma ?? 5,
                  label: settings.populationLabel ?? "Age at first flight", unit: settings.unit ?? "years",
                  startN: settings.startN ?? 10, maxN: settings.maxN ?? 200, level: settings.level ?? 0.95)
    }

    /// The t multiplier for the current n and level, e.g. qt(0.975, n − 1).
    var multiplier: Double { Stats.tQuantile(1 - (1 - level) / 2, df: Double(n - 1)) }

    func draw(_ count: Int = 1) {
        let t = multiplier
        for _ in 0..<max(count, 0) {
            var sample = [Double]()
            sample.reserveCapacity(n)
            for _ in 0..<n { sample.append(mu + sigma * Stats.normalDraw(&rng)) }
            let m = Stats.mean(sample)
            let half = t * Stats.sd(sample) / Double(n).squareRoot()
            intervals.append(Interval(id: nextID, mean: m, lower: m - half, upper: m + half,
                                      covers: m - half <= mu && mu <= m + half))
            nextID += 1
        }
        if intervals.count > Self.maxIntervals { intervals.removeFirst(intervals.count - Self.maxIntervals) }
    }

    func clear() { intervals = [] }

    func toggleAuto() {
        if isAuto { stopAuto(); return }
        isAuto = true
        autoTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isAuto else { return }
                self.draw(1)
                if self.intervals.count >= Self.maxIntervals { self.stopAuto(); return }
                try? await Task.sleep(for: .milliseconds(60))
            }
        }
    }

    func stopAuto() {
        isAuto = false
        autoTask?.cancel()
        autoTask = nil
    }

    // MARK: Readings

    var hits: Int { intervals.count(where: \.covers) }
    var coverage: Double { intervals.isEmpty ? .nan : Double(hits) / Double(intervals.count) }
    var meanWidth: Double { intervals.isEmpty ? .nan : intervals.reduce(0) { $0 + $1.width } / Double(intervals.count) }
    /// The width you'd expect on average: 2 × t × σ/√n (a little more than σ-based, since s varies).
    var expectedWidth: Double { 2 * multiplier * sigma / Double(n).squareRoot() }
    var latest: ArraySlice<Interval> { intervals.suffix(Self.shown) }

    var readings: [String: Double] {
        [
            "n": Double(n), "level": level, "intervals": Double(intervals.count),
            "coverage": coverage, "misses": Double(intervals.count - hits), "mean_width": meanWidth, "mu": mu,
        ]
    }

    var rCode: String {
        "t.test(x, conf.level = \(DistributionSculptor.format(level)))$conf.int"
    }
}

// MARK: - View

struct CIRainView: View {
    @Bindable var lab: CIRain
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Population: \(lab.label), normal with μ = \(DistributionSculptor.format(lab.mu)) \(lab.unit), σ = \(DistributionSculptor.format(lab.sigma))")
                    .font(.caption.weight(.semibold))
                Text("Each line is one sample's \(Int((lab.level * 100).rounded()))% confidence interval; the newest is at the top.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            chart.frame(height: 300)
            stats
            controls
        }
        .onDisappear { lab.stopAuto() }
    }

    private var chart: some View {
        let latest = Array(lab.latest)
        let top = (latest.last?.id ?? 0)
        return Chart {
            RuleMark(x: .value("μ", lab.mu))
                .foregroundStyle(Theme.gold)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .annotation(position: .top, spacing: 2) {
                    Text("μ = \(DistributionSculptor.format(lab.mu))").font(.caption2.weight(.semibold)).foregroundStyle(Theme.gold)
                }
            ForEach(latest) { interval in
                let row = Double(top - interval.id)
                let tint = interval.covers ? Theme.pass : Theme.fail
                RuleMark(xStart: .value("Lower", max(interval.lower, lab.xDomain.lowerBound)),
                         xEnd: .value("Upper", min(interval.upper, lab.xDomain.upperBound)),
                         y: .value("Sample", row))
                    .foregroundStyle(tint.opacity(interval.covers ? 0.7 : 1))
                    .lineStyle(StrokeStyle(lineWidth: interval.covers ? 2 : 3.5, lineCap: .round))
                PointMark(x: .value("Mean", interval.mean.clamped(to: lab.xDomain)), y: .value("Sample", row))
                    .symbolSize(10)
                    .foregroundStyle(.white)
            }
        }
        .chartXScale(domain: lab.xDomain)
        .chartYScale(domain: -1...Double(CIRain.shown))
        .chartYAxis(.hidden)
        .chartXAxisLabel(lab.unit, alignment: .trailing)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: lab.intervals.count)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confidence intervals")
        .accessibilityValue(lab.intervals.isEmpty ? "None drawn yet"
                            : "\(lab.hits) of \(lab.intervals.count) capture the true mean")
    }

    private var stats: some View {
        HStack(spacing: 18) {
            LabStat(title: "Captured μ", value: lab.intervals.isEmpty ? "–" : String(format: "%.1f%%", lab.coverage * 100),
                    tint: Theme.pass)
            LabStat(title: "Intervals", value: "\(lab.intervals.count)")
            LabStat(title: "Missed", value: "\(lab.intervals.count - lab.hits)", tint: Theme.fail)
            LabStat(title: "Average width", value: lab.intervals.isEmpty ? "–" : String(format: "%.2f", lab.meanWidth))
            LabStat(title: "t multiplier", value: String(format: "%.3f", lab.multiplier), tint: Theme.gold)
            Spacer(minLength: 0)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text("Sample size n")
                Slider(value: Binding(get: { Double(lab.n) }, set: { lab.n = Int($0.rounded()) }),
                       in: 2...Double(lab.maxN))
                    .frame(minWidth: 120)
                Stepper(value: $lab.n, in: 2...lab.maxN) {
                    Text("\(lab.n)").monospacedDigit().frame(minWidth: 28, alignment: .trailing)
                }
                Picker("Confidence", selection: $lab.level) {
                    ForEach(CIRain.levels, id: \.self) { Text("\(Int(($0 * 100).rounded()))%").tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            HStack(spacing: 10) {
                Button("Draw 1") { lab.draw(1) }
                Button("Draw 20") { lab.draw(20) }
                Button("Draw 100") { lab.draw(100) }
                Button { lab.toggleAuto() } label: {
                    Label(lab.isAuto ? "Stop" : "Rain", systemImage: lab.isAuto ? "stop.fill" : "cloud.rain.fill")
                }
                Button("Clear") { lab.clear() }.disabled(lab.intervals.isEmpty)
                Spacer()
                Text(RSyntax.attributed(lab.rCode))
                    .font(Theme.codeFont)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.editorBackground, in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .font(.callout)
    }
}

/// A labelled number in a lab's readout row.
struct LabStat: View {
    let title: String
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .accessibilityElement(children: .combine)
    }
}
