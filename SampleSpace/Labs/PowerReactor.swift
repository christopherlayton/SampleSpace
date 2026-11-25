import Charts
import SwiftUI

/// Lab: the power of a two-sample t-test. Set the true effect size d, the sample size per group
/// and α, and see two distributions of t: the one H₀ predicts and the one you'd really get with
/// that effect. Power is the share of the real one beyond the critical value. Numbers match R's
/// `power.t.test()`.
@MainActor @Observable
final class PowerReactor {
    static let alphas: [Double] = [0.10, 0.05, 0.01]

    let maxN: Int
    let dRange: ClosedRange<Double>

    var d: Double { didSet { if d != oldValue { d = d.clamped(to: dRange) } } }
    var n: Int {
        didSet {
            let clamped = min(max(n, 2), maxN)
            if clamped != n { n = clamped }
        }
    }
    var alpha: Double
    var twoSided: Bool

    init(d: Double = 0.2, n: Int = 10, alpha: Double = 0.05, twoSided: Bool = true, maxN: Int = 500,
         dRange: ClosedRange<Double> = 0...1.5) {
        self.maxN = max(maxN, 2)
        self.dRange = dRange
        self.d = d.clamped(to: dRange)
        self.n = min(max(n, 2), max(maxN, 2))
        self.alpha = alpha
        self.twoSided = twoSided
    }

    convenience init(settings: LabSettings) {
        self.init(d: settings.startD ?? 0.2, n: settings.startN ?? 10, alpha: settings.alpha ?? 0.05,
                  twoSided: (settings.tails ?? "two") == "two", maxN: settings.maxN ?? 500)
    }

    // MARK: Readings

    var df: Double { Double(2 * (n - 1)) }
    var ncp: Double { d * (Double(n) / 2).squareRoot() }
    var critical: Double { Stats.tQuantile(1 - alpha / (twoSided ? 2 : 1), df: df) }
    var power: Double { Stats.twoSamplePower(d: d, n: Double(n), alpha: alpha, twoSided: twoSided) }

    /// The smallest n per group with at least 80% power at this d and α (nil if over maxN × 10).
    var nFor80: Int? {
        guard d > 0 else { return nil }
        var lo = 2, hi = maxN * 10
        guard Stats.twoSamplePower(d: d, n: Double(hi), alpha: alpha, twoSided: twoSided) >= 0.8 else { return nil }
        while lo < hi {
            let mid = (lo + hi) / 2
            if Stats.twoSamplePower(d: d, n: Double(mid), alpha: alpha, twoSided: twoSided) >= 0.8 { hi = mid } else { lo = mid + 1 }
        }
        return lo
    }

    var readings: [String: Double] {
        let power = self.power
        return [
            "d": d, "n": Double(n), "alpha": alpha, "two_sided": twoSided ? 1 : 0,
            "power": power, "beta": 1 - power, "ncp": ncp, "critical": critical,
            "n_for_80": nFor80.map(Double.init) ?? .nan,
        ]
    }

    var rCode: String {
        "power.t.test(n = \(n), delta = \(DistributionSculptor.format(d)), sd = 1, sig.level = \(DistributionSculptor.format(alpha))\(twoSided ? "" : ", alternative = \"one.sided\""))"
    }

    // MARK: Drawing

    var tDomain: ClosedRange<Double> { -4...max(6, ncp + 4) }

    struct CurvePoint: Identifiable {
        let id: Int
        let x: Double
        let null: Double
        let alt: Double
    }

    func curves(points: Int = 160) -> [CurvePoint] {
        let domain = tDomain
        return (0...points).map { i in
            let x = domain.lowerBound + (domain.upperBound - domain.lowerBound) * Double(i) / Double(points)
            return CurvePoint(id: i, x: x, null: Stats.tDensity(x, df: df),
                              alt: Stats.noncentralTDensity(x, df: df, ncp: ncp))
        }
    }

    /// Power at a spread of sample sizes, for the small power-curve chart.
    func powerCurve(points: Int = 40) -> [DistributionSculptor.Point] {
        (0...points).map { i in
            let n = 2 + Double(maxN - 2) * pow(Double(i) / Double(points), 2)
            return .init(id: i, x: n, y: Stats.twoSamplePower(d: d, n: n.rounded(), alpha: alpha, twoSided: twoSided))
        }
    }
}

// MARK: - View

struct PowerReactorView: View {
    @Bindable var lab: PowerReactor

    var body: some View {
        let power = lab.power
        VStack(alignment: .leading, spacing: 12) {
            Text("White: t if H₀ is true (no effect). Gold: t if the effect really is d = \(DistributionSculptor.format(lab.d)). Beyond the dashed line you reject H₀.")
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            distributions.frame(height: 220)
            HStack(alignment: .top, spacing: 18) {
                LabStat(title: "Power (1 − β)", value: String(format: "%.1f%%", power * 100),
                        tint: power >= 0.8 ? Theme.pass : Theme.gold)
                LabStat(title: "β (miss rate)", value: String(format: "%.1f%%", (1 - power) * 100))
                LabStat(title: "α (false alarm)", value: String(format: "%.0f%%", lab.alpha * 100), tint: Theme.fail)
                LabStat(title: "n for 80%", value: lab.nFor80.map { "\($0) per group" } ?? "–", tint: Theme.accent)
                Spacer(minLength: 0)
            }
            powerCurve.frame(height: 110)
            controls
        }
    }

    private var distributions: some View {
        let curves = lab.curves()
        let c = lab.critical
        return Chart {
            ForEach(curves) { p in
                AreaMark(x: .value("t", p.x), y: .value("Density", p.x >= c ? p.alt : 0), series: .value("Region", "power"))
                    .foregroundStyle(Theme.pass.opacity(0.45))
                    .interpolationMethod(.linear)
            }
            ForEach(curves) { p in
                AreaMark(x: .value("t", p.x), y: .value("Density", p.x < c ? p.alt : 0), series: .value("Region", "beta"))
                    .foregroundStyle(Theme.gold.opacity(0.15))
                    .interpolationMethod(.linear)
            }
            ForEach(curves) { p in
                AreaMark(x: .value("t", p.x), y: .value("Density", p.x >= c || (lab.twoSided && p.x <= -c) ? p.null : 0),
                         series: .value("Region", "alpha"))
                    .foregroundStyle(Theme.fail.opacity(0.55))
                    .interpolationMethod(.linear)
            }
            ForEach(curves) { p in
                LineMark(x: .value("t", p.x), y: .value("Density", p.null), series: .value("Series", "H0"))
                    .foregroundStyle(.white)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            ForEach(curves) { p in
                LineMark(x: .value("t", p.x), y: .value("Density", p.alt), series: .value("Series", "H1"))
                    .foregroundStyle(Theme.gold)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            RuleMark(x: .value("Critical t", c))
                .foregroundStyle(.white.opacity(0.7))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .annotation(position: .top, spacing: 2) {
                    Text("critical t = \(String(format: "%.2f", c))").font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
                }
        }
        .chartXScale(domain: lab.tDomain)
        .chartYScale(domain: 0...0.45)
        .chartYAxis(.hidden)
        .chartXAxisLabel("t (df = \(DistributionSculptor.format(lab.df)))", alignment: .trailing)
        .padding(.top, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Null and alternative distributions of t")
        .accessibilityValue("Power \(String(format: "%.0f", lab.power * 100)) percent")
    }

    private var powerCurve: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Power against n per group, at d = \(DistributionSculptor.format(lab.d))")
                .font(.caption.weight(.semibold))
            Chart {
                ForEach(lab.powerCurve()) { p in
                    LineMark(x: .value("n", p.x), y: .value("Power", p.y))
                        .foregroundStyle(Theme.accent)
                }
                RuleMark(y: .value("80%", 0.8))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                PointMark(x: .value("n", Double(lab.n)), y: .value("Power", lab.power))
                    .foregroundStyle(Theme.gold)
                    .symbolSize(60)
            }
            .chartXScale(domain: 0...Double(lab.maxN))
            .chartYScale(domain: 0...1)
            .chartYAxis { AxisMarks(values: [0, 0.5, 0.8, 1]) { AxisGridLine(); AxisValueLabel() } }
            .accessibilityHidden(true)
        }
    }

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Effect size d")
                Slider(value: Binding(get: { lab.d }, set: { lab.d = ($0 * 100).rounded() / 100 }), in: lab.dRange)
                NumberField(value: $lab.d)
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
                    Picker("α", selection: $lab.alpha) {
                        ForEach(PowerReactor.alphas, id: \.self) {
                            Text("α = " + String(format: "%.2f", $0).replacingOccurrences(of: "0.", with: ".")).tag($0)
                        }
                    }
                    .pickerStyle(.segmented).labelsHidden().fixedSize()
                    Picker("Tails", selection: $lab.twoSided) {
                        Text("Two-sided").tag(true)
                        Text("One-sided").tag(false)
                    }
                    .pickerStyle(.segmented).labelsHidden().fixedSize()
                    Spacer()
                }
                .gridCellColumns(2)
            }
            GridRow {
                Text("In R")
                Text(RSyntax.attributed(lab.rCode))
                    .font(Theme.codeFont)
                    .textSelection(.enabled)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.editorBackground, in: RoundedRectangle(cornerRadius: 6))
                    .gridCellColumns(2)
            }
        }
        .font(.callout)
    }
}
