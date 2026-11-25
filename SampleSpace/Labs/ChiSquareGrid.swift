import Charts
import SwiftUI

/// Lab: a contingency table you can edit. Each cell shows its observed count and the count
/// expected if rows and columns were independent (row total × column total ÷ N), tinted by its
/// Pearson residual. χ² adds up (O − E)² / E over the cells; Cramér's V turns it into an effect
/// size that doesn't grow with N. Yates' continuity correction, R's default for 2 × 2 tables, can
/// be switched on to match `chisq.test()`.
@MainActor @Observable
final class ChiSquareGrid {
    static let maxCount = 100_000

    let rowLabels: [String]
    let colLabels: [String]
    let startCounts: [[Int]]
    private(set) var counts: [[Int]]
    var yates = false

    init(rowLabels: [String] = ["Row 1", "Row 2"], colLabels: [String] = ["Column 1", "Column 2"],
         counts: [[Int]]? = nil) {
        let rows = max(rowLabels.count, 2), cols = max(colLabels.count, 2)
        self.rowLabels = rowLabels.count >= 2 ? rowLabels : (1...rows).map { "Row \($0)" }
        self.colLabels = colLabels.count >= 2 ? colLabels : (1...cols).map { "Column \($0)" }
        let start = (0..<rows).map { i in
            (0..<cols).map { j in
                (counts.flatMap { $0.indices.contains(i) && $0[i].indices.contains(j) ? $0[i][j] : nil } ?? 25)
                    .clamped(to: 0...Self.maxCount)
            }
        }
        startCounts = start
        self.counts = start
    }

    convenience init(settings: LabSettings) {
        self.init(rowLabels: settings.rowLabels ?? ["Row 1", "Row 2"], colLabels: settings.colLabels ?? ["Column 1", "Column 2"],
                  counts: settings.startCounts)
    }

    var rows: Int { rowLabels.count }
    var cols: Int { colLabels.count }
    var isTwoByTwo: Bool { rows == 2 && cols == 2 }

    func set(_ i: Int, _ j: Int, to value: Int) {
        guard counts.indices.contains(i), counts[i].indices.contains(j) else { return }
        counts[i][j] = value.clamped(to: 0...Self.maxCount)
    }

    /// Multiplies every count (rounding), keeping the pattern and changing N.
    func scale(by factor: Double) {
        counts = counts.map { row in row.map { Int((Double($0) * factor).rounded()).clamped(to: 0...Self.maxCount) } }
    }

    /// Replaces the counts with the (rounded) expected counts: no association left.
    func makeIndependent() {
        let e = (0..<rows).map { i in (0..<cols).map { j in expected(i, j) } }
        guard e.joined().allSatisfy(\.isFinite) else { return }
        counts = e.map { row in row.map { Int($0.rounded()) } }
    }

    func reset() { counts = startCounts }

    // MARK: The test

    var rowTotals: [Int] { counts.map { $0.reduce(0, +) } }
    var colTotals: [Int] { (0..<cols).map { j in counts.reduce(0) { $0 + $1[j] } } }
    var n: Int { rowTotals.reduce(0, +) }

    func expected(_ i: Int, _ j: Int) -> Double {
        n > 0 ? Double(rowTotals[i]) * Double(colTotals[j]) / Double(n) : .nan
    }

    /// Pearson residual, (O − E) / √E.
    func residual(_ i: Int, _ j: Int) -> Double {
        let e = expected(i, j)
        return e > 0 ? (Double(counts[i][j]) - e) / e.squareRoot() : .nan
    }

    private var cells: [(o: Double, e: Double)] {
        (0..<rows).flatMap { i in (0..<cols).map { j in (Double(counts[i][j]), expected(i, j)) } }
    }

    /// Pearson's χ² without any correction (what Cramér's V uses).
    var pearson: Double {
        let c = cells
        guard c.allSatisfy({ $0.e > 0 }) else { return .nan }
        return c.reduce(0) { $0 + pow($1.o - $1.e, 2) / $1.e }
    }

    /// The statistic as `chisq.test(correct = yates)` computes it: for a 2 × 2 table with the
    /// correction, every |O − E| shrinks by min(0.5, smallest |O − E|).
    var statistic: Double {
        guard yates, isTwoByTwo else { return pearson }
        let c = cells
        guard c.allSatisfy({ $0.e > 0 }) else { return .nan }
        let shrink = min(0.5, c.map { abs($0.o - $0.e) }.min() ?? 0)
        return c.reduce(0) { $0 + pow(abs($1.o - $1.e) - shrink, 2) / $1.e }
    }

    var df: Double { Double((rows - 1) * (cols - 1)) }
    var p: Double { statistic.isFinite ? Stats.chiSquareUpper(statistic, df: df) : .nan }
    var cramersV: Double {
        let k = Double(min(rows, cols) - 1)
        return pearson.isFinite && n > 0 ? (pearson / (Double(n) * k)).squareRoot() : .nan
    }
    var minExpected: Double { cells.map(\.e).min() ?? .nan }
    var maxResidual: Double {
        (0..<rows).flatMap { i in (0..<cols).map { j in abs(residual(i, j)) } }.max() ?? .nan
    }

    var readings: [String: Double] {
        [
            "chi_square": statistic, "df": df, "p": p, "cramers_v": cramersV, "n": Double(n),
            "min_expected": minExpected, "yates": yates ? 1 : 0, "max_residual": maxResidual,
        ]
    }
}

// MARK: - View

struct ChiSquareGridView: View {
    @Bindable var lab: ChiSquareGrid

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Type or step the observed counts. Under each count is the count expected if rows and columns were independent; red cells hold more than expected, blue fewer.")
                .font(.caption.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .top, spacing: 18) {
                table
                VStack(alignment: .leading, spacing: 10) {
                    LabStat(title: lab.yates && lab.isTwoByTwo ? "χ² (Yates)" : "χ²",
                            value: lab.statistic.isFinite ? String(format: "%.2f", lab.statistic) : "–", tint: Theme.accent)
                    LabStat(title: "df", value: "\(Int(lab.df))")
                    LabStat(title: "p", value: apaP(lab.p))
                    LabStat(title: "Cramér's V", value: lab.cramersV.isFinite ? String(format: "%.2f", lab.cramersV) : "–",
                            tint: Theme.gold)
                }
                .frame(minWidth: 110, alignment: .leading)
            }
            if lab.minExpected.isFinite, lab.minExpected < 5 {
                Label("An expected count is below 5 (\(String(format: "%.1f", lab.minExpected))): the χ² approximation is shaky. Consider Fisher's exact test.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.gold)
            }
            rowShares.frame(height: CGFloat(40 + 30 * lab.rows))
            controls
        }
    }

    private var table: some View {
        Grid(alignment: .center, horizontalSpacing: 8, verticalSpacing: 8) {
            GridRow {
                Text("")
                ForEach(lab.colLabels, id: \.self) { Text($0).font(.caption.weight(.semibold)) }
                Text("Total").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            ForEach(0..<lab.rows, id: \.self) { i in
                GridRow {
                    Text(lab.rowLabels[i]).font(.caption.weight(.semibold)).gridColumnAlignment(.leading)
                    ForEach(0..<lab.cols, id: \.self) { j in cell(i, j) }
                    Text("\(lab.rowTotals[i])").monospacedDigit().foregroundStyle(.secondary)
                }
            }
            GridRow {
                Text("Total").font(.caption.weight(.semibold)).foregroundStyle(.secondary).gridColumnAlignment(.leading)
                ForEach(0..<lab.cols, id: \.self) { j in
                    Text("\(lab.colTotals[j])").monospacedDigit().foregroundStyle(.secondary)
                }
                Text("N = \(lab.n)").monospacedDigit().font(.callout.weight(.semibold))
            }
        }
    }

    private func cell(_ i: Int, _ j: Int) -> some View {
        let r = lab.residual(i, j)
        let tint = r.isFinite ? (r > 0 ? Theme.fail : Theme.accent).opacity(min(abs(r) / 3, 1) * 0.55) : .clear
        let e = lab.expected(i, j)
        return VStack(spacing: 3) {
            HStack(spacing: 2) {
                Button { lab.set(i, j, to: lab.counts[i][j] - 1) } label: { Image(systemName: "minus") }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("One fewer in \(lab.rowLabels[i]), \(lab.colLabels[j])")
                TextField("", value: Binding(get: { lab.counts[i][j] }, set: { lab.set(i, j, to: $0) }), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .monospacedDigit()
                    .frame(width: 64)
                    .accessibilityLabel("Observed count, \(lab.rowLabels[i]), \(lab.colLabels[j])")
                Button { lab.set(i, j, to: lab.counts[i][j] + 1) } label: { Image(systemName: "plus") }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("One more in \(lab.rowLabels[i]), \(lab.colLabels[j])")
            }
            Text(e.isFinite ? "E = \(String(format: "%.1f", e))" : "E = –")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .background(tint, in: RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.15)))
    }

    /// Each row's split across the columns. Under independence every bar splits the same way.
    private var rowShares: some View {
        let shares: [RowShare] = (0..<lab.rows).flatMap { i in
            (0..<lab.cols).map { j in
                RowShare(row: lab.rowLabels[i], col: lab.colLabels[j],
                         share: lab.rowTotals[i] > 0 ? Double(lab.counts[i][j]) / Double(lab.rowTotals[i]) : 0)
            }
        }
        return Chart(shares) { item in
            BarMark(x: .value("Share of row", item.share), y: .value("Row", item.row))
                .foregroundStyle(by: .value("Column", item.col))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in AxisValueLabel() }
        }
        .chartXScale(domain: 0...1)
        .chartXAxis {
            AxisMarks(values: [0, 0.25, 0.5, 0.75, 1]) { value in
                AxisGridLine()
                AxisValueLabel { if let v = value.as(Double.self) { Text("\(Int(v * 100))%") } }
            }
        }
        .chartLegend(position: .top, alignment: .leading)
        .accessibilityLabel("Each row's percentages across the columns")
    }

    private struct RowShare: Identifiable {
        let row: String
        let col: String
        let share: Double
        var id: String { row + "|" + col }
    }

    private var controls: some View {
        HStack(spacing: 10) {
            Button("× 2") { lab.scale(by: 2) }.help("Double every count: same pattern, twice the N")
            Button("÷ 2") { lab.scale(by: 0.5) }.help("Halve every count: same pattern, half the N")
            Button("Make independent") { lab.makeIndependent() }
            Button("Reset") { lab.reset() }
            Divider().frame(height: 18)
            Toggle("Yates correction (R's 2 × 2 default)", isOn: $lab.yates).disabled(!lab.isTwoByTwo)
        }
        .font(.callout)
    }
}
