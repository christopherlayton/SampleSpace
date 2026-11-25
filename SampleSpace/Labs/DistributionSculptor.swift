import Charts
import SwiftUI

/// Lab: a normal curve you shape with its mean and SD. Shade below, above, between or outside
/// cutoffs and read the area as a proportion, with each cutoff's z-score and the `pnorm()` call
/// that gives the same number.
@MainActor @Observable
final class DistributionSculptor {
    enum Shade: String, CaseIterable, Identifiable, Sendable {
        case below, above, between, outside
        var id: Self { self }
        var title: String {
            switch self {
            case .below: "Below"
            case .above: "Above"
            case .between: "Between"
            case .outside: "Both tails"
            }
        }
        var usesTwoCutoffs: Bool { self == .between || self == .outside }
    }

    let meanRange: ClosedRange<Double>
    let sdRange: ClosedRange<Double>
    let xRange: ClosedRange<Double>

    var mean: Double { didSet { if mean != oldValue { mean = mean.clamped(to: meanRange) } } }
    var sd: Double { didSet { if sd != oldValue { sd = sd.clamped(to: sdRange) } } }
    var shade: Shade
    var cutoff: Double { didSet { if cutoff != oldValue { cutoff = cutoff.clamped(to: xRange) } } }
    var cutoff2: Double { didSet { if cutoff2 != oldValue { cutoff2 = cutoff2.clamped(to: xRange) } } }
    /// Lines at the mean ± 1, 2 and 3 SDs, labelled with z.
    var showGuides = true

    init(settings: LabSettings = LabSettings()) {
        func range(_ values: [Double]?, _ fallback: ClosedRange<Double>) -> ClosedRange<Double> {
            guard let values, values.count == 2, values[0] < values[1] else { return fallback }
            return values[0]...values[1]
        }
        xRange = range(settings.xRange, 40...160)
        let span = xRange.upperBound - xRange.lowerBound
        meanRange = range(settings.meanRange, xRange)
        sdRange = range(settings.sdRange, (span / 40)...(span / 4))
        let mid = (xRange.lowerBound + xRange.upperBound) / 2
        mean = (settings.startMean ?? mid).clamped(to: meanRange)
        sd = (settings.startSd ?? span / 8).clamped(to: sdRange)
        shade = settings.shade.flatMap(Shade.init(rawValue:)) ?? .below
        cutoff = (settings.cutoff ?? mid).clamped(to: xRange)
        cutoff2 = (settings.cutoff2 ?? mid + span / 8).clamped(to: xRange)
    }

    // MARK: Readings

    var lower: Double { min(cutoff, cutoff2) }
    var upper: Double { max(cutoff, cutoff2) }
    func z(_ x: Double) -> Double { (x - mean) / sd }
    func cdf(_ x: Double) -> Double { Stats.normalCDF(z(x)) }

    /// Proportion of the curve that is shaded.
    var area: Double {
        switch shade {
        case .below: cdf(cutoff)
        case .above: 1 - cdf(cutoff)
        case .between: cdf(upper) - cdf(lower)
        case .outside: cdf(lower) + (1 - cdf(upper))
        }
    }

    var readings: [String: Double] {
        [
            "mean": mean, "sd": sd, "cutoff": cutoff, "z": z(cutoff),
            "lower": lower, "upper": upper, "z_lower": z(lower), "z_upper": z(upper),
            "area": area,
            "shade_below": shade == .below ? 1 : 0, "shade_above": shade == .above ? 1 : 0,
            "shade_between": shade == .between ? 1 : 0, "shade_outside": shade == .outside ? 1 : 0,
        ]
    }

    /// The R call that gives the shaded area.
    var rCode: String {
        let m = Self.format(mean), s = Self.format(sd)
        let a = Self.format(cutoff), lo = Self.format(lower), hi = Self.format(upper)
        return switch shade {
        case .below: "pnorm(\(a), mean = \(m), sd = \(s))"
        case .above: "pnorm(\(a), mean = \(m), sd = \(s), lower.tail = FALSE)"
        case .between: "pnorm(\(hi), \(m), \(s)) - pnorm(\(lo), \(m), \(s))"
        case .outside: "pnorm(\(lo), \(m), \(s)) + pnorm(\(hi), \(m), \(s), lower.tail = FALSE)"
        }
    }

    /// Dragging moves cutoffs in steps that suit the scale (1 for a 40–160 axis, 0.01 for −4 to 4).
    var dragStep: Double {
        pow(10, (log10(xRange.upperBound - xRange.lowerBound)).rounded(.down) - 2)
    }

    // MARK: Drawing

    struct Point: Identifiable {
        let id: Int
        let x: Double
        let y: Double
    }

    func density(_ x: Double) -> Double { Stats.normalDensity(x, mean: mean, sd: sd) }

    /// Height of the y-axis. It stays fixed for most SDs, so a wider curve visibly gets flatter
    /// (the area stays 1); only a very narrow curve raises it, so the peak is never cut off.
    var yMax: Double {
        let span = xRange.upperBound - xRange.lowerBound
        let fixed = Stats.normalDensity(0, mean: 0, sd: max(sdRange.lowerBound, span / 16))
        return max(fixed, Stats.normalDensity(0, mean: 0, sd: sd)) * 1.08
    }

    func curve(points: Int = 240) -> [Point] {
        let step = (xRange.upperBound - xRange.lowerBound) / Double(points)
        return (0...points).map { i in
            let x = xRange.lowerBound + Double(i) * step
            return Point(id: i, x: x, y: density(x))
        }
    }

    func isShaded(_ x: Double) -> Bool {
        switch shade {
        case .below: x <= cutoff
        case .above: x >= cutoff
        case .between: x >= lower && x <= upper
        case .outside: x <= lower || x >= upper
        }
    }

    /// The curve with unshaded parts flattened to 0, with vertical edges exactly at the cutoffs.
    func shadedOutline(points: Int = 240) -> [Point] {
        let step = (xRange.upperBound - xRange.lowerBound) / Double(points)
        let edges = shade.usesTwoCutoffs ? [lower, upper] : [cutoff]
        let tiny = step / 1000
        let plain = (0...points).map { xRange.lowerBound + Double($0) * step }
            .filter { x in !edges.contains { abs($0 - x) < tiny } }
        let grid = (plain + edges).sorted()
        var result: [Point] = []
        for x in grid {
            let y = density(x)
            if edges.contains(x) {
                result.append(Point(id: result.count, x: x, y: isShaded(x - tiny) ? y : 0))
                result.append(Point(id: result.count, x: x, y: isShaded(x + tiny) ? y : 0))
            } else {
                result.append(Point(id: result.count, x: x, y: isShaded(x) ? y : 0))
            }
        }
        return result
    }

    /// Short number formatting for labels and R code: up to 4 decimals, no trailing zeros.
    static func format(_ value: Double, decimals: Int = 4) -> String {
        var text = String(format: "%.\(decimals)f", value)
        if text.contains(".") {
            while text.hasSuffix("0") { text.removeLast() }
            if text.hasSuffix(".") { text.removeLast() }
        }
        return text == "-0" ? "0" : text
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self { min(max(self, range.lowerBound), range.upperBound) }
}

// MARK: - View

struct DistributionSculptorView: View {
    @Bindable var lab: DistributionSculptor
    @State private var dragging: Int?

    var body: some View {
        VStack(spacing: 12) {
            chart
                .frame(height: 260)
            readout
            controls
        }
    }

    private var chart: some View {
        Chart {
            ForEach(lab.shadedOutline()) { point in
                AreaMark(x: .value("x", point.x), y: .value("Shaded", point.y))
                    .foregroundStyle(Theme.accent.opacity(0.45))
                    .interpolationMethod(.linear)
            }
            ForEach(lab.curve()) { point in
                LineMark(x: .value("x", point.x), y: .value("Density", point.y), series: .value("Series", "curve"))
                    .foregroundStyle(.white)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            if lab.showGuides {
                ForEach(-3...3, id: \.self) { k in
                    let x = lab.mean + Double(k) * lab.sd
                    if lab.xRange.contains(x) {
                        RuleMark(x: .value("Guide", x))
                            .foregroundStyle(.white.opacity(k == 0 ? 0.45 : 0.18))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: k == 0 ? [] : [3, 4]))
                            .annotation(position: .top, alignment: .center, spacing: 2) {
                                Text(k == 0 ? "z 0" : String(format: "%+d", k))
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                    }
                }
            }
            ForEach(cutoffs, id: \.self) { index in
                let x = index == 0 ? lab.cutoff : lab.cutoff2
                RuleMark(x: .value("Cutoff", x))
                    .foregroundStyle(Theme.gold)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .annotation(position: .bottom, alignment: .center, spacing: 4) {
                        Text("\(DistributionSculptor.format(x, decimals: 2))  z = \(String(format: "%.2f", lab.z(x)))")
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.gold.opacity(0.85), in: Capsule())
                            .foregroundStyle(.black)
                    }
            }
        }
        .chartXScale(domain: lab.xRange)
        .chartYScale(domain: 0...lab.yMax)
        .chartYAxis(.hidden)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in drag(to: value.location, proxy: proxy, geometry: geometry) }
                        .onEnded { _ in dragging = nil })
            }
        }
        .padding(.top, 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Normal curve, mean \(DistributionSculptor.format(lab.mean)), SD \(DistributionSculptor.format(lab.sd))")
        .accessibilityValue("Shaded area \(String(format: "%.4f", lab.area))")
        .help("Drag on the curve to move the cutoff")
    }

    private var cutoffs: [Int] { lab.shade.usesTwoCutoffs ? [0, 1] : [0] }

    private func drag(to location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let frame = proxy.plotFrame.map({ geometry[$0] }),
              let x: Double = proxy.value(atX: location.x - frame.minX) else { return }
        let step = lab.dragStep
        let snapped = (x / step).rounded() * step
        if dragging == nil {
            dragging = lab.shade.usesTwoCutoffs && abs(x - lab.cutoff2) < abs(x - lab.cutoff) ? 1 : 0
        }
        if dragging == 1 { lab.cutoff2 = snapped } else { lab.cutoff = snapped }
    }

    private var readout: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Shaded area").font(.caption).foregroundStyle(.secondary)
                Text(String(format: "%.4f", lab.area))
                    .font(.system(.title, design: .rounded).weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.accent)
                    .contentTransition(.numericText())
                Text(String(format: "%.2f%% of the curve", lab.area * 100))
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Same number in R").font(.caption).foregroundStyle(.secondary)
                Text(RSyntax.attributed(lab.rCode))
                    .font(Theme.codeFont)
                    .textSelection(.enabled)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.editorBackground, in: RoundedRectangle(cornerRadius: 8))
            }
            Spacer(minLength: 0)
        }
    }

    /// A slider binding that rounds to tidy values (e.g. 100 rather than 100.2734).
    private func snapped(_ key: ReferenceWritableKeyPath<DistributionSculptor, Double>, step: Double) -> Binding<Double> {
        Binding(get: { lab[keyPath: key] },
                set: { lab[keyPath: key] = (($0 / step).rounded() * step * 1e6).rounded() / 1e6 })
    }

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Mean")
                Slider(value: snapped(\.mean, step: lab.dragStep), in: lab.meanRange)
                NumberField(value: $lab.mean)
            }
            GridRow {
                Text("SD")
                Slider(value: snapped(\.sd, step: lab.dragStep / 10), in: lab.sdRange)
                NumberField(value: $lab.sd)
            }
            GridRow {
                Text("Shade")
                Picker("Shade", selection: $lab.shade) {
                    ForEach(DistributionSculptor.Shade.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Toggle("Guides", isOn: $lab.showGuides)
                    .help("Lines at the mean ± 1, 2 and 3 SDs")
            }
            GridRow {
                Text(lab.shade.usesTwoCutoffs ? "Cutoffs" : "Cutoff")
                HStack(spacing: 8) {
                    NumberField(value: $lab.cutoff)
                    if lab.shade.usesTwoCutoffs {
                        Text("and").foregroundStyle(.secondary)
                        NumberField(value: $lab.cutoff2)
                    }
                    Text("drag on the curve, or type a value")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .gridCellColumns(2)
            }
        }
        .font(.callout)
    }
}

/// A small numeric text field that commits on Return or when focus leaves.
struct NumberField: View {
    @Binding var value: Double
    var width: CGFloat = 70

    var body: some View {
        TextField("", value: $value, format: .number.precision(.fractionLength(0...3)))
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .frame(width: width)
    }
}
