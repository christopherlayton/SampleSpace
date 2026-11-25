import Charts
import SwiftUI

/// Lab: three (or more) groups of points and the one-way ANOVA that compares them. Move the group
/// means apart or together, widen or narrow the spread within groups, add people, and watch the
/// total variation split into a between-groups part and a within-groups part. F is the ratio of
/// their mean squares.
///
/// The noise is standardised so the numbers are exact: each group's sample mean is exactly the
/// mean you set, and the pooled within-group SD is exactly the SD you set.
@MainActor @Observable
final class AnovaSplitter {
    enum Deviations: String, CaseIterable, Identifiable {
        case within, between, total, none
        var id: Self { self }
        var title: String {
            switch self {
            case .within: "Within"
            case .between: "Between"
            case .total: "Total"
            case .none: "None"
            }
        }
    }

    static let domain: ClosedRange<Double> = 0...100
    static let meanRange: ClosedRange<Double> = 10...90
    static let sdRange: ClosedRange<Double> = 1...25
    static let nRange: ClosedRange<Int> = 3...50

    let labels: [String]
    let yLabel: String
    let grand = 50.0
    var k: Int { labels.count }

    /// People per group. Changing it draws new people.
    var n: Int {
        didSet {
            let clamped = n.clamped(to: Self.nRange)
            if clamped != n { n = clamped }
            if n != oldValue { drawPeople() }
        }
    }
    /// The pooled SD within groups.
    var withinSD: Double {
        didSet {
            let clamped = withinSD.clamped(to: Self.sdRange)
            if clamped != withinSD { withinSD = clamped }
        }
    }
    /// Spacing between neighbouring group means; setting it lines the means up evenly around 50.
    var spacing: Double {
        didSet {
            let clamped = spacing.clamped(to: 0...(80 / Double(max(k - 1, 1))))
            if clamped != spacing { spacing = clamped }
            spaceMeans()
        }
    }
    private(set) var means: [Double] = []
    var show: Deviations = .within
    /// Standardised noise: each group's values average exactly 0 and the pooled SD is exactly 1.
    private(set) var noise: [[Double]] = []
    /// Fixed sideways offsets so points in a group don't sit on top of each other.
    private(set) var jitter: [[Double]] = []
    @ObservationIgnored private var rng: SplitMix64

    init(labels: [String] = ["A", "B", "C"], yLabel: String = "Score", startN: Int = 10, startSD: Double = 10,
         startSpacing: Double = 6, seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.labels = labels.count >= 2 ? labels : ["A", "B", "C"]
        self.yLabel = yLabel
        n = startN.clamped(to: Self.nRange)
        withinSD = startSD.clamped(to: Self.sdRange)
        spacing = max(startSpacing, 0)
        rng = SplitMix64(seed: seed)
        spaceMeans()
        drawPeople()
    }

    convenience init(settings: LabSettings) {
        self.init(labels: settings.groupLabels ?? ["A", "B", "C"], yLabel: settings.yLabel ?? "Score",
                  startN: settings.startN ?? 10, startSD: settings.startSd ?? 10, startSpacing: settings.startDiff ?? 6)
    }

    private func spaceMeans() {
        let mid = Double(k - 1) / 2
        means = (0..<k).map { (grand + spacing * (Double($0) - mid)).clamped(to: Self.meanRange) }
    }

    /// New people: fresh noise, re-standardised.
    func drawPeople() {
        var z = (0..<k).map { _ in (0..<n).map { _ in Stats.normalDraw(&rng) } }
        z = z.map { group in
            let m = Stats.mean(group)
            return group.map { $0 - m }
        }
        let pooled = (z.joined().reduce(0) { $0 + $1 * $1 } / Double(k * (n - 1))).squareRoot()
        noise = z.map { group in group.map { $0 / pooled } }
        jitter = (0..<k).map { _ in (0..<n).map { _ in Double(rng.next() >> 11) / Double(1 << 53) * 0.5 - 0.25 } }
    }

    func setMean(_ group: Int, to value: Double) {
        guard means.indices.contains(group) else { return }
        means[group] = value.clamped(to: Self.meanRange)
    }

    func value(_ group: Int, _ i: Int) -> Double { means[group] + withinSD * noise[group][i] }

    // MARK: The ANOVA

    var grandMean: Double { Stats.mean(means) }
    var ssBetween: Double {
        let g = grandMean
        return Double(n) * means.reduce(0) { $0 + ($1 - g) * ($1 - g) }
    }
    var ssWithin: Double {
        (0..<k).reduce(0) { total, g in
            total + (0..<n).reduce(0) { $0 + pow(value(g, $1) - means[g], 2) }
        }
    }
    var ssTotal: Double { ssBetween + ssWithin }
    var dfBetween: Double { Double(k - 1) }
    var dfWithin: Double { Double(k * (n - 1)) }
    var msBetween: Double { ssBetween / dfBetween }
    var msWithin: Double { ssWithin / dfWithin }
    var f: Double { msWithin > 0 ? msBetween / msWithin : .nan }
    var p: Double { f.isFinite ? Stats.fUpper(f, df1: dfBetween, df2: dfWithin) : .nan }
    var etaSquared: Double { ssTotal > 0 ? ssBetween / ssTotal : .nan }
    var meansRange: Double { (means.max() ?? 0) - (means.min() ?? 0) }

    var readings: [String: Double] {
        [
            "f": f, "p": p, "eta_squared": etaSquared,
            "ss_between": ssBetween, "ss_within": ssWithin, "ss_total": ssTotal,
            "df_between": dfBetween, "df_within": dfWithin, "ms_between": msBetween, "ms_within": msWithin,
            "n": Double(n), "groups": Double(k), "means_range": meansRange, "within_sd": withinSD,
        ]
    }
}

/// A p-value as APA writes it: no leading zero, and "< .001" for very small values.
func apaP(_ p: Double) -> String {
    guard p.isFinite else { return "–" }
    if p < 0.001 { return "< .001" }
    return String(format: "%.3f", p).replacingOccurrences(of: "0.", with: ".")
}

// MARK: - View

struct AnovaSplitterView: View {
    @Bindable var lab: AnovaSplitter
    @State private var dragging: Int?
    /// Group mean minus the pointer's value at the grab, so a group moves with the pointer
    /// instead of jumping to it.
    @State private var grabOffset = 0.0

    static let palette: [Color] = [.cyan, .pink, .mint, .orange, .purple]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drag a group up or down to move its mean. The gold bars are the group means; the dashed line is the grand mean.")
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 16) {
                chart.frame(minWidth: 300, maxWidth: .infinity).frame(height: 300)
                VStack(alignment: .leading, spacing: 10) {
                    LabStat(title: "F", value: lab.f.isFinite ? String(format: "%.2f", lab.f) : "–", tint: Theme.accent)
                    LabStat(title: "p", value: apaP(lab.p))
                    LabStat(title: "η²", value: lab.etaSquared.isFinite ? String(format: "%.2f", lab.etaSquared) : "–",
                            tint: Theme.gold)
                    fCurve.frame(width: 170, height: 90)
                }
                .frame(width: 170, alignment: .leading)
            }
            partition
            table
            controls
        }
    }

    private var chart: some View {
        Chart {
            RuleMark(y: .value(lab.yLabel, lab.grandMean))
                .foregroundStyle(.white.opacity(0.6))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
            ForEach(0..<lab.k, id: \.self) { g in
                let color = Self.palette[g % Self.palette.count]
                if lab.show == .between {
                    RuleMark(x: .value("Group", Double(g)), yStart: .value(lab.yLabel, lab.grandMean),
                             yEnd: .value(lab.yLabel, lab.means[g]))
                        .foregroundStyle(Theme.gold.opacity(0.55))
                        .lineStyle(StrokeStyle(lineWidth: 8))
                }
                ForEach(0..<lab.n, id: \.self) { i in
                    let x = Double(g) + lab.jitter[g][i]
                    let y = lab.value(g, i)
                    if lab.show == .within {
                        RuleMark(x: .value("Group", x), yStart: .value(lab.yLabel, lab.means[g]), yEnd: .value(lab.yLabel, y))
                            .foregroundStyle(color.opacity(0.45))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                    } else if lab.show == .total {
                        RuleMark(x: .value("Group", x), yStart: .value(lab.yLabel, lab.grandMean), yEnd: .value(lab.yLabel, y))
                            .foregroundStyle(Theme.fail.opacity(0.4))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                    }
                    PointMark(x: .value("Group", x), y: .value(lab.yLabel, y))
                        .foregroundStyle(color)
                        .symbolSize(dragging == g ? 50 : 30)
                }
                RuleMark(xStart: .value("Group", Double(g) - 0.38), xEnd: .value("Group", Double(g) + 0.38),
                         y: .value(lab.yLabel, lab.means[g]))
                    .foregroundStyle(Theme.gold)
                    .lineStyle(StrokeStyle(lineWidth: 3))
            }
        }
        .chartXScale(domain: -0.5...(Double(lab.k) - 0.5))
        .chartYScale(domain: AnovaSplitter.domain)
        .chartXAxis {
            AxisMarks(values: Array(0..<lab.k).map(Double.init)) { value in
                AxisValueLabel {
                    if let x = value.as(Double.self), lab.labels.indices.contains(Int(x)) {
                        Text(lab.labels[Int(x)])
                    }
                }
            }
        }
        .chartYAxisLabel(lab.yLabel)
        .chartPlotStyle { $0.clipped() }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in drag(value.location, proxy: proxy, geometry: geometry) }
                        .onEnded { _ in dragging = nil; grabOffset = 0 })
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Dot plot of \(lab.k) groups of \(lab.n)")
        .accessibilityValue(zip(lab.labels, lab.means).map { "\($0) mean \(String(format: "%.1f", $1))" }
            .joined(separator: ", ") + ", F = \(String(format: "%.2f", lab.f))")
        .help("Drag a group to move its mean")
    }

    private func drag(_ location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let frame = proxy.plotFrame.map({ geometry[$0] }) else { return }
        let local = CGPoint(x: location.x - frame.minX, y: location.y - frame.minY)
        guard let (x, y) = proxy.value(at: local, as: (Double, Double).self) else { return }
        if dragging == nil {
            let g = Int(x.rounded())
            guard (0..<lab.k).contains(g), abs(x - Double(g)) < 0.45 else { return }
            dragging = g
            grabOffset = lab.means[g] - y
        }
        if let g = dragging { lab.setMean(g, to: ((y + grabOffset) * 10).rounded() / 10) }
    }

    /// The F distribution for these df, with the observed F and its upper tail (p) shaded.
    private var fCurve: some View {
        let d1 = lab.dfBetween, d2 = lab.dfWithin
        let f = lab.f.isFinite ? lab.f : 0
        let xMax = max(6, min(f * 1.15, 40))
        let xs = stride(from: 0.02, through: xMax, by: xMax / 120).map { $0 }
        let points = xs.map { (x: $0, y: min(Stats.fDensity($0, df1: d1, df2: d2), 1.2)) }
        return Chart {
            ForEach(points.filter { $0.x >= f }, id: \.x) { point in
                AreaMark(x: .value("F", point.x), y: .value("Density", point.y))
                    .foregroundStyle(Theme.fail.opacity(0.45))
            }
            ForEach(points, id: \.x) { point in
                LineMark(x: .value("F", point.x), y: .value("Density", point.y))
                    .foregroundStyle(.white.opacity(0.8))
            }
            RuleMark(x: .value("F", f)).foregroundStyle(Theme.accent)
        }
        .chartXScale(domain: 0...xMax)
        .chartYAxis(.hidden)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .accessibilityLabel("F distribution with \(Int(d1)) and \(Int(d2)) degrees of freedom; the shaded tail is p")
    }

    /// SS total as one bar, split into its between and within parts.
    private var partition: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("SS total = SS between + SS within").font(.caption).foregroundStyle(.secondary)
            GeometryReader { geo in
                let share = lab.ssTotal > 0 ? lab.ssBetween / lab.ssTotal : 0
                HStack(spacing: 0) {
                    Rectangle().fill(Theme.gold.opacity(0.85)).frame(width: geo.size.width * share)
                    Rectangle().fill(Theme.accent.opacity(0.55))
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 16)
            HStack {
                Text("Between groups \(String(format: "%.0f", lab.ssBetween))").foregroundStyle(Theme.gold)
                Spacer()
                Text("Within groups \(String(format: "%.0f", lab.ssWithin))").foregroundStyle(Theme.accent)
            }
            .font(.caption.monospacedDigit())
        }
        .accessibilityElement(children: .combine)
    }

    private var table: some View {
        Grid(alignment: .trailing, horizontalSpacing: 18, verticalSpacing: 3) {
            GridRow {
                Text("Source").gridColumnAlignment(.leading)
                Text("SS"); Text("df"); Text("MS"); Text("F"); Text("p")
            }
            .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            GridRow {
                Text("Between groups").gridColumnAlignment(.leading)
                Text(String(format: "%.1f", lab.ssBetween)); Text("\(Int(lab.dfBetween))")
                Text(String(format: "%.1f", lab.msBetween))
                Text(lab.f.isFinite ? String(format: "%.2f", lab.f) : "–"); Text(apaP(lab.p))
            }
            GridRow {
                Text("Within groups").gridColumnAlignment(.leading)
                Text(String(format: "%.1f", lab.ssWithin)); Text("\(Int(lab.dfWithin))")
                Text(String(format: "%.1f", lab.msWithin)); Text(""); Text("")
            }
            GridRow {
                Text("Total").gridColumnAlignment(.leading)
                Text(String(format: "%.1f", lab.ssTotal)); Text("\(Int(lab.dfBetween + lab.dfWithin))")
                Text(""); Text(""); Text("")
            }
        }
        .font(.callout.monospacedDigit())
    }

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Distance between means")
                Slider(value: $lab.spacing, in: 0...(80 / Double(max(lab.k - 1, 1))), step: 0.5)
                Text(String(format: "%.1f", lab.spacing)).monospacedDigit().frame(width: 44, alignment: .trailing)
            }
            GridRow {
                Text("SD within groups")
                Slider(value: $lab.withinSD, in: AnovaSplitter.sdRange, step: 0.5)
                Text(String(format: "%.1f", lab.withinSD)).monospacedDigit().frame(width: 44, alignment: .trailing)
            }
            GridRow {
                Text("People per group")
                HStack {
                    Stepper(value: $lab.n, in: AnovaSplitter.nRange) { Text("\(lab.n)").monospacedDigit() }
                    Button("New people") { lab.drawPeople() }
                    Spacer()
                    Text("Show").foregroundStyle(.secondary)
                    Picker("Show deviations", selection: $lab.show) {
                        ForEach(AnovaSplitter.Deviations.allCases) { Text($0.title).tag($0) }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }
                .gridCellColumns(2)
            }
        }
        .font(.callout)
    }
}
