import SwiftUI

/// What SPSS would show for an SPSS Translate level: the menu path, the dialog settings, the
/// pasted syntax and the Output Viewer tables, drawn in SPSS's own light style so it reads as
/// "the other program".
struct SPSSPanelView: View {
    let panel: SPSSPanel
    @State private var showSyntax = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("In SPSS", systemImage: "arrow.left.arrow.right")
                .font(.headline)
                .foregroundStyle(Theme.accent)

            if !panel.menu.isEmpty { menuPath }

            if let dialog = panel.dialog, !dialog.isEmpty {
                Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                    ForEach(Array(dialog.enumerated()), id: \.offset) { _, setting in
                        GridRow {
                            Text(setting.label + ":").foregroundStyle(.secondary)
                            Text(setting.value).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .font(.callout)
            }

            if let syntax = panel.syntax {
                DisclosureGroup(isExpanded: $showSyntax) {
                    Text(syntax)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(Color(white: 0.1))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(Color(white: 0.96), in: RoundedRectangle(cornerRadius: 6))
                } label: {
                    Text("Syntax (Paste)").font(.callout.weight(.semibold))
                }
            }

            if !panel.output.isEmpty {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(Array(panel.output.enumerated()), id: \.offset) { _, table in
                        // Wide tables scroll sideways rather than widening the lesson pane.
                        ScrollView(.horizontal) {
                            SPSSTableView(table: table)
                        }
                        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topTrailing) {
                    Text("Output Viewer")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(white: 0.45))
                        .padding(6)
                }
                .environment(\.colorScheme, .light)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("SPSS output")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.accent.opacity(0.3)))
    }

    private var menuPath: some View {
        // Wraps onto more lines when the pane is narrow.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) { menuItems }
            VStack(alignment: .leading, spacing: 4) { menuItems }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Menu: " + panel.menu.joined(separator: ", then "))
    }

    @ViewBuilder private var menuItems: some View {
        ForEach(Array(panel.menu.enumerated()), id: \.offset) { index, item in
            HStack(spacing: 4) {
                if index > 0 {
                    Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                }
                Text(item)
                    .font(.callout.weight(.medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 5))
            }
        }
    }
}

/// One SPSS pivot table: centred bold title, header rows, row labels on the left, numbers on
/// the right, light rules, footnotes underneath.
struct SPSSTableView: View {
    let table: SPSSTable

    private let ink = Color(white: 0.12)
    private let rule = Color(white: 0.6)
    private let header = Color(white: 0.93)

    var body: some View {
        VStack(alignment: .center, spacing: 6) {
            Text(table.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(ink)
            Grid(alignment: .leading, horizontalSpacing: 0, verticalSpacing: 0) {
                if let groups = table.groups {
                    GridRow {
                        ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                            cell(group.text, header: true, alignment: .center)
                                .gridCellColumns(group.span)
                        }
                    }
                }
                GridRow {
                    ForEach(Array(table.columns.enumerated()), id: \.offset) { index, title in
                        cell(title, header: true, alignment: index < table.headerColumns ? .leading : .center)
                    }
                }
                ForEach(Array(table.rows.enumerated()), id: \.offset) { rowIndex, row in
                    GridRow {
                        ForEach(Array(row.enumerated()), id: \.offset) { index, value in
                            let isLabel = index < table.headerColumns
                            cell(value, header: false, alignment: isLabel ? .leading : .trailing,
                                 label: isLabel, topRule: !isLabel || !value.isEmpty || rowIndex == 0)
                        }
                    }
                }
            }
            .overlay(Rectangle().stroke(rule, lineWidth: 0.5))
            .fixedSize()
            if let notes = table.footnotes {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(notes, id: \.self) { Text($0) }
                }
                .font(.system(size: 11))
                .foregroundStyle(Color(white: 0.3))
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(minWidth: 0)
        .textSelection(.enabled)
    }

    private func cell(_ text: String, header isHeader: Bool, alignment: Alignment, label: Bool = false,
                      topRule: Bool = true) -> some View {
        Text(text)
            .font(.system(size: 12, weight: isHeader || label ? .medium : .regular).monospacedDigit())
            .foregroundStyle(ink)
            .multilineTextAlignment(alignment == .trailing ? .trailing : (alignment == .center ? .center : .leading))
            .lineLimit(3)
            .frame(minWidth: 44, maxWidth: isHeader && alignment == .center ? 110 : .infinity, alignment: alignment)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .background(isHeader || label ? header : .white)
            .overlay(alignment: .top) {
                if topRule { Rectangle().fill(rule.opacity(0.6)).frame(height: 0.5) }
            }
            .overlay(alignment: .leading) { Rectangle().fill(rule.opacity(0.35)).frame(width: 0.5) }
    }
}
