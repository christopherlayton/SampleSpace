import Charts
import SwiftUI

/// Lab: draw random samples ("crews") of size n from a real population, with replacement, and
/// watch the sample means pile up. Shows the Central Limit Theorem from a skewed population and
/// the standard error shrinking with √n.
@MainActor @Observable
final class SamplingMachine {
    // Random draws use `SplitMix64` (StarfieldView.swift), seedable so tests can repeat a run.
    let population: [Double]
    let label: String
    let unit: String
    let maxN: Int
    let popMean: Double
    let popSD: Double
    let popSkew: Double
    /// Shared x-axis for the population and the means, so you can see the means narrow.
    let xDomain: ClosedRange<Double>
    let populationBins: [Bin]

    /// Sample size. Changing it starts a new pile of means.
    var n: Int {
        didSet {
            let clamped = min(max(n, 1), maxN)
            if clamped != n { n = clamped }
            if n != oldValue { clear() }
        }
    }
    private(set) var means: [Double] = []
    private(set) var lastSample: [Double] = []
    var showCurve = true
    private(set) var isAuto = false

    /// The most means kept; enough for a smooth histogram.
    static let maxSamples = 20_000

    @ObservationIgnored private var rng: SplitMix64
    @ObservationIgnored private var autoTask: Task<Void, Never>?

    init(population: [Double], label: String, unit: String = "", startN: Int = 2, maxN: Int = 100,
         seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.population = population
        self.label = label
        self.unit = unit
        self.maxN = max(maxN, 1)
        n = min(max(startN, 1), max(maxN, 1))
        popMean = Stats.mean(population)
        popSD = Stats.sd(population)
        popSkew = Stats.skewness(population)
        let lo = min(0, population.min() ?? 0)
        let hi = population.max() ?? 1
        xDomain = lo...(hi > lo ? hi : lo + 1)
        populationBins = Self.bins(population, domain: xDomain, count: Self.populationBinCount)
        rng = SplitMix64(seed: seed)
    }

    /// Loads the population from a CSV in the level folder (`population_file` / `population_column`).
    static func make(settings: LabSettings, folder: URL) throws -> SamplingMachine {
        let file = settings.populationFile ?? "astronauts.csv"
        let column = settings.populationColumn ?? "hours_mission"
        let table = try CSVTable(contentsOf: folder.appending(path: file))
        guard let values = table.numbers(in: column), values.count > 1 else {
            throw LabError.badPopulation("\(file) has no numeric column \"\(column)\".")
        }
        return SamplingMachine(population: values, label: settings.populationLabel ?? column,
                               unit: settings.unit ?? "", startN: settings.startN ?? 2,
                               maxN: settings.maxN ?? 100)
    }

    // MARK: Drawing samples

    /// Draws `count` samples of size n and records each mean.
    func draw(_ count: Int = 1) {
        guard !population.isEmpty, count > 0 else { return }
        var newMeans: [Double] = []
        newMeans.reserveCapacity(count)
        var sample: [Double] = []
        for _ in 0..<count {
            sample = (0..<n).map { _ in population[Int(rng.next() % UInt64(population.count))] }
            newMeans.append(Stats.mean(sample))
        }
        lastSample = sample
        means.append(contentsOf: newMeans)
        if means.count > Self.maxSamples { means.removeFirst(means.count - Self.maxSamples) }
    }

    func clear() {
        means = []
        lastSample = []
    }

    /// Keeps drawing (10 samples every 1/20 s) until stopped.
    func toggleAuto() {
        if isAuto { stopAuto(); return }
        isAuto = true
        autoTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isAuto else { return }
                self.draw(10)
                if self.means.count >= Self.maxSamples { self.stopAuto(); return }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    func stopAuto() {
        isAuto = false
        autoTask?.cancel()
        autoTask = nil
    }

    // MARK: Readings

    var meanOfMeans: Double { Stats.mean(means) }
    var simulatedSE: Double { Stats.sd(means) }
    var theorySE: Double { popSD / Double(n).squareRoot() }
    var skewOfMeans: Double { Stats.skewness(means) }

    var readings: [String: Double] {
        [
            "n": Double(n), "samples": Double(means.count),
            "mean_of_means": meanOfMeans, "se": simulatedSE, "theory_se": theorySE,
            "skew": skewOfMeans, "pop_mean": popMean, "pop_sd": popSD,
        ]
    }

    // MARK: Histograms

    struct Bin: Identifiable {
        let id: Int
        let start: Double
        let end: Double
        let count: Int
        var mid: Double { (start + end) / 2 }
    }

    static func bins(_ values: [Double], domain: ClosedRange<Double>, count: Int) -> [Bin] {
        let width = (domain.upperBound - domain.lowerBound) / Double(count)
        var counts = Array(repeating: 0, count: count)
        for v in values {
            let i = Int((v - domain.lowerBound) / width)
            counts[min(max(i, 0), count - 1)] += 1
        }
        return counts.enumerated().map { i, c in
            Bin(id: i, start: domain.lowerBound + Double(i) * width,
                end: domain.lowerBound + Double(i + 1) * width, count: c)
        }
    }

    static let populationBinCount = 50
    static let meansBinCount = 150
    var meansBinWidth: Double { (xDomain.upperBound - xDomain.lowerBound) / Double(Self.meansBinCount) }
    var meansBins: [Bin] { Self.bins(means, domain: xDomain, count: Self.meansBinCount) }

    /// The normal curve the CLT predicts, scaled to the means histogram: N(μ, σ/√n).
    func predictedCurve(points: Int = 120) -> [DistributionSculptor.Point] {
        let se = theorySE
        let lo = max(xDomain.lowerBound, popMean - 4 * se)
        let hi = min(xDomain.upperBound, popMean + 4 * se)
        guard hi > lo else { return [] }
        let scale = Double(means.count) * meansBinWidth
        return (0...points).map { i in
            let x = lo + (hi - lo) * Double(i) / Double(points)
            return .init(id: i, x: x, y: Stats.normalDensity(x, mean: popMean, sd: se) * scale)
        }
    }
}

enum LabError: Error, LocalizedError {
    case badPopulation(String)
    var errorDescription: String? {
        switch self {
        case .badPopulation(let detail): "Couldn't load the lab's population: \(detail)"
        }
    }
}

// MARK: - View

struct SamplingMachineView: View {
    @Bindable var lab: SamplingMachine

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            populationChart.frame(height: 140)
            sampleStrip.frame(height: 54)
            meansChart.frame(height: 210)
            stats
            controls
        }
        .onDisappear { lab.stopAuto() }
    }

    private func caption(_ text: String, _ detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(text).font(.caption.weight(.semibold))
            Text(detail).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
    }

    private var hours: String { lab.unit.isEmpty ? "" : " \(lab.unit)" }

    private var populationChart: some View {
        VStack(alignment: .leading, spacing: 2) {
            caption("Population: \(lab.label)",
                    "N = \(lab.population.count)   μ = \(Int(lab.popMean.rounded()))\(hours)   σ = \(Int(lab.popSD.rounded()))\(hours)   skew \(String(format: "%.2f", lab.popSkew))")
            Chart {
                ForEach(lab.populationBins) { bin in
                    RectangleMark(xStart: .value("From", bin.start), xEnd: .value("To", bin.end),
                                  yStart: .value("Count", 0), yEnd: .value("Count", bin.count))
                        .foregroundStyle(Theme.nebulaViolet.opacity(0.9))
                }
                RuleMark(x: .value("μ", lab.popMean))
                    .foregroundStyle(Theme.gold)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            .chartXScale(domain: lab.xDomain)
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .accessibilityLabel("Population histogram, strongly right-skewed")
        }
    }

    private var sampleStrip: some View {
        VStack(alignment: .leading, spacing: 2) {
            caption("Latest crew", lab.lastSample.isEmpty ? "draw one below"
                    : "n = \(lab.lastSample.count)   mean = \(Int(Stats.mean(lab.lastSample).rounded()))\(hours)")
            Chart {
                ForEach(Array(lab.lastSample.enumerated()), id: \.offset) { index, value in
                    PointMark(x: .value("Value", value), y: .value("Row", Double(index % 5)))
                        .symbolSize(28)
                        .foregroundStyle(Theme.accent)
                }
                if !lab.lastSample.isEmpty {
                    RuleMark(x: .value("Crew mean", Stats.mean(lab.lastSample)))
                        .foregroundStyle(Theme.pass)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                }
            }
            .chartXScale(domain: lab.xDomain)
            .chartYScale(domain: -0.8...4.8)
            .chartYAxis(.hidden)
            .chartXAxis(.hidden)
            .accessibilityHidden(true)
        }
    }

    private var meansChart: some View {
        VStack(alignment: .leading, spacing: 2) {
            caption("Sampling distribution: one mean per crew",
                    "\(lab.means.count) crews of n = \(lab.n)")
            Chart {
                ForEach(lab.meansBins.filter { $0.count > 0 }) { bin in
                    RectangleMark(xStart: .value("From", bin.start), xEnd: .value("To", bin.end),
                                  yStart: .value("Crews", 0), yEnd: .value("Crews", bin.count))
                        .foregroundStyle(Theme.pass.opacity(0.85))
                }
                if lab.showCurve, lab.means.count >= 20 {
                    ForEach(lab.predictedCurve()) { point in
                        LineMark(x: .value("Mean", point.x), y: .value("Crews", point.y),
                                 series: .value("Series", "normal"))
                            .foregroundStyle(Theme.gold)
                            .lineStyle(StrokeStyle(lineWidth: 1.5))
                    }
                }
                RuleMark(x: .value("μ", lab.popMean))
                    .foregroundStyle(Theme.gold.opacity(0.7))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
            }
            .chartXScale(domain: lab.xDomain)
            .chartYAxis(.hidden)
            .chartXAxisLabel(lab.unit.isEmpty ? lab.label : lab.unit, alignment: .trailing)
            .accessibilityLabel("Histogram of \(lab.means.count) sample means")
        }
    }

    private var stats: some View {
        HStack(spacing: 18) {
            stat("Mean of means", lab.means.isEmpty ? "–" : "\(Int(lab.meanOfMeans.rounded()))")
            stat("SE (SD of means)", lab.means.count < 2 ? "–" : "\(Int(lab.simulatedSE.rounded()))",
                 tint: Theme.pass)
            stat("σ / √n", "\(Int(lab.theorySE.rounded()))", tint: Theme.gold)
            stat("Skew of means", lab.means.count < 3 ? "–" : String(format: "%.2f", lab.skewOfMeans))
            Spacer(minLength: 0)
        }
    }

    private func stat(_ title: String, _ value: String, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(.title3, design: .rounded).weight(.bold).monospacedDigit())
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Text("Crew size n")
            Slider(value: Binding(get: { Double(lab.n) }, set: { lab.n = Int($0.rounded()) }),
                   in: 1...Double(lab.maxN))
                .frame(minWidth: 120)
            Stepper(value: $lab.n, in: 1...lab.maxN) {
                Text("\(lab.n)").monospacedDigit().frame(minWidth: 28, alignment: .trailing)
            }
            Divider().frame(height: 18)
            Button("Draw 1") { lab.draw(1) }
            Button("Draw 100") { lab.draw(100) }
            Button("Draw 1,000") { lab.draw(1000) }
            Button { lab.toggleAuto() } label: {
                Label(lab.isAuto ? "Stop" : "Auto", systemImage: lab.isAuto ? "stop.fill" : "play.fill")
            }
            Button("Clear") { lab.clear() }
                .disabled(lab.means.isEmpty)
            Toggle("Normal curve", isOn: $lab.showCurve)
                .help("Overlay the normal curve the Central Limit Theorem predicts: mean μ, SD σ/√n")
        }
        .font(.callout)
    }
}
