import Charts
import SwiftUI

/// Lab: fit a line by hand. Drag the line's two handles (or use the sliders) and watch the
/// residuals and their squares; the sum of squared errors (SSE) is what least squares makes as
/// small as possible. The best line can be shown for comparison.
@MainActor @Observable
final class LeastSquaresFit {
    let xs: [Double]
    let ys: [Double]
    let xLabel: String
    let yLabel: String
    let xDomain: ClosedRange<Double>
    let yDomain: ClosedRange<Double>
    let bestSlope: Double
    let bestIntercept: Double
    let bestSSE: Double
    /// Total sum of squares around the mean of y: the SSE of the best flat line.
    let sst: Double

    var intercept: Double
    var slope: Double
    var showSquares = true
    var showBest = false

    init(xs: [Double], ys: [Double], xLabel: String, yLabel: String, startIntercept: Double? = nil,
         startSlope: Double = 0) {
        self.xs = xs
        self.ys = ys
        self.xLabel = xLabel
        self.yLabel = yLabel
        func padded(_ v: [Double]) -> ClosedRange<Double> {
            let lo = v.min() ?? 0, hi = v.max() ?? 1
            let pad = max((hi - lo) * 0.12, 0.5)
            return (lo - pad)...(hi + pad)
        }
        xDomain = padded(xs)
        yDomain = padded(ys)
        let fit = Stats.correlation(xs, ys)
        bestSlope = fit.slope
        bestIntercept = fit.intercept
        let my = Stats.mean(ys)
        sst = ys.reduce(0) { $0 + ($1 - my) * ($1 - my) }
        bestSSE = zip(xs, ys).reduce(0) { $0 + pow($1.1 - (fit.intercept + fit.slope * $1.0), 2) }
        slope = startSlope
        intercept = startIntercept ?? (yDomain.lowerBound + (yDomain.upperBound - yDomain.lowerBound) * 0.25)
    }

    /// Loads two columns from a CSV in the level folder, keeping rows where both are numbers.
    static func make(settings: LabSettings, folder: URL) throws -> LeastSquaresFit {
        let file = settings.dataFile ?? "sleep_morale.csv"
        let xName = settings.xColumn ?? "sleep_hours", yName = settings.yColumn ?? "morale_score"
        let table = try CSVTable(contentsOf: folder.appending(path: file))
        guard let xi = table.header.firstIndex(of: xName), let yi = table.header.firstIndex(of: yName) else {
            throw LabError.badPopulation("\(file) needs columns \"\(xName)\" and \"\(yName)\".")
        }
        var xs: [Double] = [], ys: [Double] = []
        for row in table.rows where row.count > max(xi, yi) {
            if let x = Double(row[xi]), let y = Double(row[yi]) { xs.append(x); ys.append(y) }
        }
        guard xs.count > 2 else { throw LabError.badPopulation("\(file) has too few complete rows.") }
        return LeastSquaresFit(xs: xs, ys: ys, xLabel: settings.xLabel ?? xName, yLabel: settings.yLabel ?? yName,
                               startIntercept: settings.startIntercept, startSlope: settings.startSlope ?? 0)
    }

    func predict(_ x: Double) -> Double { intercept + slope * x }

    var sse: Double { zip(xs, ys).reduce(0) { $0 + pow($1.1 - predict($1.0), 2) } }
    var rSquared: Double { sst > 0 ? 1 - sse / sst : .nan }

    /// Sets the line through two points (the handles at each end of the x-axis).
    func setLine(leftY: Double, rightY: Double) {
        let x0 = xDomain.lowerBound, x1 = xDomain.upperBound
        slope = (rightY - leftY) / (x1 - x0)
        intercept = leftY - slope * x0
    }

    func snapToBest() {
        slope = bestSlope
        intercept = bestIntercept
    }

    var readings: [String: Double] {
        let sse = self.sse
        return [
            "intercept": intercept, "slope": slope, "sse": sse, "best_sse": bestSSE,
            "sse_ratio": bestSSE > 0 ? sse / bestSSE : .nan, "r_squared": rSquared,
            "best_slope": bestSlope, "best_intercept": bestIntercept, "best_shown": showBest ? 1 : 0,
        ]
    }

    var slopeRange: ClosedRange<Double> {
        let span = (yDomain.upperBound - yDomain.lowerBound) / (xDomain.upperBound - xDomain.lowerBound)
        return (-2 * span)...(2 * span)
    }

    var interceptRange: ClosedRange<Double> {
        // Wide enough to reach any line through the plot, given the slope range.
        let reach = max(abs(slopeRange.lowerBound), abs(slopeRange.upperBound)) * max(abs(xDomain.lowerBound), abs(xDomain.upperBound))
        return (yDomain.lowerBound - reach)...(yDomain.upperBound + reach)
    }
}

// MARK: - View

struct LeastSquaresFitView: View {
    @Bindable var lab: LeastSquaresFit
    @State private var dragging: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drag the two gold handles to move the line. Each square's area is one residual squared; least squares makes their total as small as it can be.")
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            chart.frame(height: 320)
            stats
            controls
        }
    }

    private var chart: some View {
        let x0 = lab.xDomain.lowerBound, x1 = lab.xDomain.upperBound
        return Chart {
            if lab.showBest {
                LineMark(x: .value(lab.xLabel, x0), y: .value(lab.yLabel, lab.bestIntercept + lab.bestSlope * x0),
                         series: .value("Line", "best"))
                    .foregroundStyle(Theme.pass.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                LineMark(x: .value(lab.xLabel, x1), y: .value(lab.yLabel, lab.bestIntercept + lab.bestSlope * x1),
                         series: .value("Line", "best"))
                    .foregroundStyle(Theme.pass.opacity(0.8))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            }
            ForEach(Array(zip(lab.xs, lab.ys).enumerated()), id: \.offset) { _, point in
                RuleMark(x: .value(lab.xLabel, point.0), yStart: .value("Fit", lab.predict(point.0)),
                         yEnd: .value(lab.yLabel, point.1))
                    .foregroundStyle(Theme.fail.opacity(0.6))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                PointMark(x: .value(lab.xLabel, point.0), y: .value(lab.yLabel, point.1))
                    .foregroundStyle(Theme.accent)
                    .symbolSize(36)
            }
            LineMark(x: .value(lab.xLabel, x0), y: .value(lab.yLabel, lab.predict(x0)), series: .value("Line", "yours"))
                .foregroundStyle(Theme.gold)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            LineMark(x: .value(lab.xLabel, x1), y: .value(lab.yLabel, lab.predict(x1)), series: .value("Line", "yours"))
                .foregroundStyle(Theme.gold)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
            ForEach([x0, x1], id: \.self) { x in
                PointMark(x: .value(lab.xLabel, x), y: .value(lab.yLabel, lab.predict(x).clamped(to: lab.yDomain)))
                    .symbol(.square)
                    .symbolSize(140)
                    .foregroundStyle(Theme.gold)
            }
        }
        .chartXScale(domain: lab.xDomain)
        .chartYScale(domain: lab.yDomain)
        .chartXAxisLabel(lab.xLabel)
        .chartYAxisLabel(lab.yLabel)
        .chartBackground { proxy in
            if lab.showSquares { squares(proxy) }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in drag(value.location, proxy: proxy, geometry: geometry) }
                        .onEnded { _ in dragging = nil })
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Scatterplot with your line")
        .accessibilityValue("Sum of squared errors \(String(format: "%.2f", lab.sse))")
    }

    /// Each residual drawn as a real square in screen space, beside its point.
    private func squares(_ proxy: ChartProxy) -> some View {
        GeometryReader { geometry in
            let origin = proxy.plotFrame.map { geometry[$0].origin } ?? .zero
            Path { path in
                for (x, y) in zip(lab.xs, lab.ys) {
                    guard let px = proxy.position(forX: x), let py = proxy.position(forY: y),
                          let pf = proxy.position(forY: lab.predict(x)) else { continue }
                    let side = abs(py - pf)
                    // Put the square on whichever side of the point has room.
                    let left = px + side > (proxy.plotFrame.map { geometry[$0].width } ?? .infinity)
                    path.addRect(CGRect(x: origin.x + (left ? px - side : px), y: origin.y + min(py, pf),
                                        width: side, height: side))
                }
            }
            .fill(Theme.fail.opacity(0.12))
        }
    }

    private func drag(_ location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let frame = proxy.plotFrame.map({ geometry[$0] }) else { return }
        let local = CGPoint(x: location.x - frame.minX, y: location.y - frame.minY)
        guard let (x, y) = proxy.value(at: local, as: (Double, Double).self) else { return }
        let x0 = lab.xDomain.lowerBound, x1 = lab.xDomain.upperBound
        if dragging == nil {
            // The handle on the nearer half of the plot.
            dragging = x < (x0 + x1) / 2 ? 0 : 1
        }
        let snapped = (y * 1000).rounded() / 1000
        if dragging == 0 {
            lab.setLine(leftY: snapped, rightY: lab.predict(x1))
        } else {
            lab.setLine(leftY: lab.predict(x0), rightY: snapped)
        }
    }

    private var stats: some View {
        HStack(alignment: .top, spacing: 18) {
            LabStat(title: "Your SSE", value: String(format: "%.2f", lab.sse), tint: Theme.gold)
            LabStat(title: "Least-squares SSE", value: lab.showBest ? String(format: "%.2f", lab.bestSSE) : "?",
                    tint: Theme.pass)
            LabStat(title: "Yours vs best", value: lab.showBest
                    ? String(format: "+%.1f%%", (lab.sse / lab.bestSSE - 1) * 100) : "?")
            LabStat(title: "R² of your line", value: String(format: "%.3f", lab.rSquared))
            Spacer(minLength: 0)
        }
    }

    private var controls: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
            GridRow {
                Text("Intercept")
                Slider(value: Binding(get: { lab.intercept }, set: { lab.intercept = ($0 * 1000).rounded() / 1000 }),
                       in: lab.interceptRange)
                NumberField(value: $lab.intercept)
            }
            GridRow {
                Text("Slope")
                Slider(value: Binding(get: { lab.slope }, set: { lab.slope = ($0 * 1000).rounded() / 1000 }),
                       in: lab.slopeRange)
                NumberField(value: $lab.slope)
            }
            GridRow {
                Text("Show")
                HStack {
                    Toggle("Squares", isOn: $lab.showSquares)
                    Toggle("Least-squares line", isOn: $lab.showBest)
                    Spacer()
                    Text(RSyntax.attributed("ŷ = \(String(format: "%.3f", lab.intercept)) + \(String(format: "%.3f", lab.slope)) × x"))
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
