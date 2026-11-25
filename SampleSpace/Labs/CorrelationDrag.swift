import Charts
import SwiftUI

/// Lab: a cloud of points you can drag, with Pearson's r updating live. Make a new cloud at a
/// chosen correlation, then add an outlier and see how far one point can move r.
@MainActor @Observable
final class CorrelationDrag {
    struct Dot: Identifiable, Equatable {
        let id: Int
        var x: Double
        var y: Double
        var isOutlier = false
    }

    static let domain: ClosedRange<Double> = 0...10

    private(set) var dots: [Dot] = []
    var showLine = true
    let count: Int
    @ObservationIgnored private var nextID = 0
    @ObservationIgnored private var rng: SplitMix64

    init(count: Int = 20, startR: Double = 0.3, seed: UInt64 = UInt64.random(in: 0...UInt64.max)) {
        self.count = max(count, 3)
        rng = SplitMix64(seed: seed)
        newCloud(r: startR)
    }

    convenience init(settings: LabSettings) {
        self.init(count: settings.points ?? 20, startR: settings.startR ?? 0.3)
    }

    /// A fresh cloud whose sample correlation is exactly `r` (within rounding), centred on the
    /// middle of the plot so there's room to drag.
    func newCloud(r target: Double) {
        let r = target.clamped(to: -0.99...0.99)
        var x = (0..<count).map { _ in Stats.normalDraw(&rng) }
        var e = (0..<count).map { _ in Stats.normalDraw(&rng) }
        // Make x and e exactly uncorrelated and standardised, so y = r·x + √(1−r²)·e has correlation r.
        x = standardise(x)
        let fit = Stats.correlation(x, e)
        e = standardise(zip(e, x).map { $0 - fit.slope * $1 })
        let y = zip(x, e).map { r * $0 + (1 - r * r).squareRoot() * $1 }
        dots = zip(x, y).map { a, b in
            defer { nextID += 1 }
            return Dot(id: nextID, x: (5 + 1.3 * a).clamped(to: Self.domain), y: (5 + 1.3 * b).clamped(to: Self.domain))
        }
    }

    private func standardise(_ v: [Double]) -> [Double] {
        let m = Stats.mean(v), s = Stats.sd(v)
        return v.map { ($0 - m) / s }
    }

    func move(_ id: Int, x: Double, y: Double) {
        guard let i = dots.firstIndex(where: { $0.id == id }) else { return }
        dots[i].x = x.clamped(to: Self.domain)
        dots[i].y = y.clamped(to: Self.domain)
    }

    /// Adds one point far from the cloud, in the corner that works against the current trend.
    func addOutlier() {
        let r = self.r.isFinite ? self.r : 0
        dots.append(Dot(id: nextID, x: 9.6, y: r >= 0 ? 0.4 : 9.6, isOutlier: true))
        nextID += 1
    }

    func removeOutliers() { dots.removeAll(where: \.isOutlier) }

    // MARK: Readings

    private func fit(_ dots: [Dot]) -> (r: Double, slope: Double, intercept: Double) {
        Stats.correlation(dots.map(\.x), dots.map(\.y))
    }

    var r: Double { fit(dots).r }
    var withoutOutliers: Double { fit(dots.filter { !$0.isOutlier }).r }
    var outliers: Int { dots.count(where: \.isOutlier) }

    var readings: [String: Double] {
        let f = fit(dots)
        return [
            "r": f.r, "abs_r": abs(f.r), "r_squared": f.r * f.r, "n": Double(dots.count), "slope": f.slope,
            "outliers": Double(outliers),
            "outlier_effect": outliers == 0 ? 0 : abs(f.r - withoutOutliers),
        ]
    }
}

// MARK: - View

struct CorrelationDragView: View {
    @Bindable var lab: CorrelationDrag
    @State private var dragging: Int?
    @State private var targetR = 0.0

    var body: some View {
        let f = Stats.correlation(lab.dots.map(\.x), lab.dots.map(\.y))
        VStack(alignment: .leading, spacing: 12) {
            Text("Drag any point. r measures how tightly the points follow a straight line, from −1 to +1.")
                .font(.caption.weight(.semibold))
            HStack(alignment: .top, spacing: 16) {
                chart(f).frame(width: 340, height: 340)
                VStack(alignment: .leading, spacing: 12) {
                    LabStat(title: "Pearson's r", value: f.r.isFinite ? String(format: "%.2f", f.r) : "–",
                            tint: Theme.accent)
                    LabStat(title: "r²", value: f.r.isFinite ? String(format: "%.2f", f.r * f.r) : "–")
                    if lab.outliers > 0 {
                        LabStat(title: "r without the outlier", value: String(format: "%.2f", lab.withoutOutliers),
                                tint: Theme.fail)
                    }
                    LabStat(title: "Points", value: "\(lab.dots.count)")
                    meter(f.r)
                }
                .frame(minWidth: 150, alignment: .leading)
            }
            controls
        }
    }

    private func chart(_ f: (r: Double, slope: Double, intercept: Double)) -> some View {
        Chart {
            if lab.showLine, f.slope.isFinite {
                let d = CorrelationDrag.domain
                LineMark(x: .value("x", d.lowerBound), y: .value("y", f.intercept + f.slope * d.lowerBound))
                    .foregroundStyle(Theme.gold.opacity(0.8))
                LineMark(x: .value("x", d.upperBound), y: .value("y", f.intercept + f.slope * d.upperBound))
                    .foregroundStyle(Theme.gold.opacity(0.8))
            }
            ForEach(lab.dots) { dot in
                PointMark(x: .value("x", dot.x), y: .value("y", dot.y))
                    .symbolSize(dragging == dot.id ? 160 : 80)
                    .foregroundStyle(dot.isOutlier ? Theme.fail : Theme.accent)
            }
        }
        .chartXScale(domain: CorrelationDrag.domain)
        .chartYScale(domain: CorrelationDrag.domain)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { value in drag(value.location, proxy: proxy, geometry: geometry) }
                        .onEnded { _ in dragging = nil })
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Scatterplot of \(lab.dots.count) points")
        .accessibilityValue(f.r.isFinite ? "r = \(String(format: "%.2f", f.r))" : "")
        .help("Drag a point to move it")
    }

    private func drag(_ location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) {
        guard let frame = proxy.plotFrame.map({ geometry[$0] }) else { return }
        let local = CGPoint(x: location.x - frame.minX, y: location.y - frame.minY)
        guard let (x, y) = proxy.value(at: local, as: (Double, Double).self) else { return }
        if dragging == nil {
            // Grab the nearest point within about half a grid unit.
            let nearest = lab.dots.min { hypot($0.x - x, $0.y - y) < hypot($1.x - x, $1.y - y) }
            guard let nearest, hypot(nearest.x - x, nearest.y - y) < 0.6 else { return }
            dragging = nearest.id
        }
        if let id = dragging { lab.move(id, x: x, y: y) }
    }

    /// A −1…+1 bar with the current r marked.
    private func meter(_ r: Double) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(colors: [Theme.fail, .white.opacity(0.25), Theme.pass], startPoint: .leading, endPoint: .trailing)
                        .clipShape(Capsule())
                    if r.isFinite {
                        Circle().fill(.white).frame(width: 12, height: 12)
                            .offset(x: (r + 1) / 2 * (geo.size.width - 12))
                    }
                }
            }
            .frame(height: 12)
            HStack {
                Text("−1"); Spacer(); Text("0"); Spacer(); Text("+1")
            }
            .font(.caption2.monospacedDigit()).foregroundStyle(.secondary)
        }
        .frame(width: 150)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Text("New cloud at r =")
            Slider(value: $targetR, in: -0.9...0.9, step: 0.1).frame(width: 140)
            Text(String(format: "%+.1f", targetR)).monospacedDigit().frame(width: 34)
            Button("Make") { lab.newCloud(r: targetR) }
            Divider().frame(height: 18)
            Button("Add outlier") { lab.addOutlier() }
            Button("Remove outliers") { lab.removeOutliers() }.disabled(lab.outliers == 0)
            Toggle("Best-fit line", isOn: $lab.showLine)
        }
        .font(.callout)
    }
}
