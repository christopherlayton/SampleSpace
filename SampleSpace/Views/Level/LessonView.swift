import SwiftUI

/// The left pane of a level: the briefing, then any hints revealed, then the solution if shown.
struct LessonView: View {
    let level: Level
    let sector: Sector?
    let session: LevelSession

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    MarkdownView(markdown: level.lesson) { name in
                        if name == "spss", let spss = level.spss { AnyView(SPSSPanelView(panel: spss)) } else { nil }
                    }
                    if let spss = level.spss, !level.lesson.contains("{{spss}}") {
                        SPSSPanelView(panel: spss)
                    }
                    hints
                    if session.solutionShown, !level.solutionCode.isEmpty { solution.id("solution") }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .onChange(of: session.hintsShown) { _, count in
                guard count > 0 else { return }
                withAnimation { proxy.scrollTo("hint-\(count)", anchor: .bottom) }
            }
            .onChange(of: session.solutionShown) { _, shown in
                if shown { withAnimation { proxy.scrollTo("solution", anchor: .bottom) } }
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            if let sector {
                Label(sector.name, systemImage: "circle.fill")
                    .labelStyle(TintedIconLabel(tint: sector.color))
            }
            Label(level.type.displayName, systemImage: level.type.symbol)
            Spacer()
            Label("\(level.xp) XP", systemImage: "bolt.fill")
                .foregroundStyle(Theme.gold)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
    }

    @ViewBuilder private var hints: some View {
        if session.hintsShown > 0 {
            VStack(alignment: .leading, spacing: 10) {
                Label("Hints", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .foregroundStyle(Theme.gold)
                ForEach(0..<min(session.hintsShown, level.hints.count), id: \.self) { index in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1).").monospacedDigit().foregroundStyle(.secondary)
                        Text(AttributedString.inlineMarkdown(level.hints[index]))
                            .textSelection(.enabled)
                    }
                    .id("hint-\(index + 1)")
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.gold.opacity(0.35)))
        }
    }

    private var solution: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Solution", systemImage: "key.fill")
                .font(.headline)
                .foregroundStyle(Theme.accent)
            Text("Read it, then type it yourself rather than copying. Typing it is how it sticks.")
                .font(.callout)
                .foregroundStyle(.secondary)
            CodeBlock(code: level.solutionCode, isDocument: level.isDocument)
        }
    }
}

private struct TintedIconLabel: LabelStyle {
    let tint: Color
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon.foregroundStyle(tint).imageScale(.small)
            configuration.title
        }
    }
}

// MARK: - Markdown

/// Renders lesson Markdown: headings, paragraphs, lists, quotes ("Coming from SPSS?"
/// call-outs), tables and highlighted R code blocks.
struct MarkdownView: View {
    let markdown: String
    /// What to show at a `{{name}}` placeholder line (nothing if it returns nil).
    var slot: (String) -> AnyView?
    private let blocks: [MarkdownBlock]

    init(markdown: String, slot: @escaping (String) -> AnyView? = { _ in nil }) {
        self.markdown = markdown
        self.slot = slot
        blocks = MarkdownBlock.parse(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                view(for: block)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder private func view(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(AttributedString.inlineMarkdown(text))
                .font(level == 1 ? Theme.titleFont
                      : .system(level == 2 ? .title3 : .headline, design: .rounded).weight(.bold))
                .padding(.top, level == 1 ? 0 : 6)
        case .paragraph(let text):
            Text(AttributedString.inlineMarkdown(text))
                .fixedSize(horizontal: false, vertical: true)
        case .code(let code, let language):
            CodeBlock(code: code, isDocument: ["qmd", "quarto", "markdown", "md", "rmd"].contains(language?.lowercased() ?? ""))
        case .bullets(let items):
            list(items) { _ in Text("•") }
        case .numbered(let items):
            list(items) { Text("\($0 + 1).").monospacedDigit() }
        case .quote(let text):
            Text(AttributedString.inlineMarkdown(text))
                .fixedSize(horizontal: false, vertical: true)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .leading) {
                    UnevenRoundedRectangle(topLeadingRadius: 10, bottomLeadingRadius: 10)
                        .fill(Theme.accent.opacity(0.7))
                        .frame(width: 3)
                }
        case .table(let header, let rows):
            table(header: header, rows: rows)
        case .rule:
            Divider()
        case .placeholder(let name):
            if let view = slot(name) { view }
        }
    }

    private func list(_ items: [String], marker: @escaping (Int) -> Text) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    marker(index).foregroundStyle(Theme.accent).frame(minWidth: 14, alignment: .trailing)
                    Text(AttributedString.inlineMarkdown(item))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func table(header: [String], rows: [[String]]) -> some View {
        Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 6) {
            GridRow {
                ForEach(Array(header.enumerated()), id: \.offset) { _, cell in
                    Text(AttributedString.inlineMarkdown(cell)).font(.callout.weight(.semibold))
                }
            }
            Divider()
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        Text(AttributedString.inlineMarkdown(cell)).font(.callout)
                    }
                }
            }
        }
        .padding(12)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }
}

/// A read-only, highlighted R code block.
struct CodeBlock: View {
    let code: String
    /// Highlight as a Quarto document rather than R.
    var isDocument = false

    var body: some View {
        Text(isDocument ? RSyntax.attributedDocument(code) : RSyntax.attributed(code))
            .font(Theme.codeFont)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(Theme.editorBackground, in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(.white.opacity(0.08)))
    }
}
