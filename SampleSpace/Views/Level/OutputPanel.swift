import AppKit
import SwiftUI

/// The bottom-right pane: console, plots and check results from the last run. Documents add a
/// Report tab with the knitted report; Boss levels group the checks by step.
struct OutputPanel: View {
    @Bindable var session: LevelSession

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("Output", selection: $session.outputTab) {
                    Text("Console").tag(LevelSession.OutputTab.console)
                    Text(session.plots.isEmpty ? "Plots" : "Plots (\(session.plots.count))")
                        .tag(LevelSession.OutputTab.plots)
                    if session.level.isDocument {
                        Text("Report").tag(LevelSession.OutputTab.report)
                    }
                    if !session.level.checkCode.isEmpty {
                        Text(checksTitle).tag(LevelSession.OutputTab.checks)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
                Spacer()
                status
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.black.opacity(0.25))

            Group {
                switch session.outputTab {
                case .console: ConsoleView(entries: session.console)
                case .plots: PlotsView(session: session)
                case .report: ReportView(session: session)
                case .checks: ChecksView(session: session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.editorBackground.opacity(0.92))
    }

    private var checksTitle: String {
        guard !session.checks.isEmpty else { return "Checks" }
        if session.isBoss { return "Checks: step \(min(session.currentStep, session.steps.count))/\(session.steps.count)" }
        let passed = session.checks.filter(\.passed).count
        return "Checks \(passed)/\(session.checks.count)"
    }

    @ViewBuilder private var status: some View {
        switch session.activity {
        case .running, .checking:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text(session.activity == .checking ? "Checking…" : "Running…")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        case .idle:
            if let status = session.lastStatus {
                Label(statusText(status), systemImage: statusSymbol(status))
                    .font(.caption)
                    .foregroundStyle(statusColor(status))
            }
        }
    }

    private func statusText(_ status: RRunResult.Status) -> String {
        switch status {
        case .ok:
            let time = (session.lastDuration ?? 0).formatted(.number.precision(.fractionLength(2)))
            return "Ran in \(time) s"
        case .error: return "Stopped with an error"
        case .parseError: return "R couldn't read the code"
        case .timeout: return "Took too long"
        case .runnerError: return "Couldn't run"
        }
    }

    private func statusSymbol(_ status: RRunResult.Status) -> String {
        status == .ok ? "checkmark.circle" : "exclamationmark.triangle"
    }

    private func statusColor(_ status: RRunResult.Status) -> Color {
        status == .ok ? .secondary : Theme.fail
    }
}

// MARK: - Console

struct ConsoleView: View {
    let entries: [ConsoleEntry]

    var body: some View {
        if entries.isEmpty {
            placeholder("Press Run (⌘↩) to send your code to R. Its output appears here.",
                        symbol: "terminal")
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                            ConsoleLine(entry: entry).id(index)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                }
                .onAppear { proxy.scrollTo(entries.count - 1, anchor: .bottom) }
                .onChange(of: entries) { _, new in proxy.scrollTo(new.count - 1, anchor: .bottom) }
            }
        }
    }
}

struct ConsoleLine: View {
    @Environment(\.codeFontSize) private var codeFontSize
    let entry: ConsoleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.consoleText)
                .font(Theme.code(codeFontSize))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
            if let explanation = ErrorExplainer.explain(entry) {
                Label {
                    Text(AttributedString.inlineMarkdown(explanation))
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "lightbulb.fill").foregroundStyle(Theme.gold)
                }
                .font(.callout)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var color: Color {
        switch entry.kind {
        case .input: Theme.codeText.opacity(0.55)
        case .output: Theme.codeText
        case .message: Theme.accent.opacity(0.85)
        case .warning: Theme.warn
        case .error: Theme.fail
        }
    }
}

// MARK: - Plots

private struct PlotsView: View {
    @Bindable var session: LevelSession

    var body: some View {
        if session.plots.isEmpty {
            placeholder("Plots your code draws appear here, for example `plot(1:10)`.",
                        symbol: "chart.xyaxis.line")
        } else {
            let index = min(session.selectedPlot, session.plots.count - 1)
            VStack(spacing: 8) {
                if let image = NSImage(data: session.plots[index]) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .accessibilityLabel("Plot \(index + 1) of \(session.plots.count)")
                }
                if session.plots.count > 1 {
                    HStack {
                        Button { session.selectedPlot = index - 1 } label: { Image(systemName: "chevron.left") }
                            .disabled(index == 0)
                            .accessibilityLabel("Previous plot")
                        Text("Plot \(index + 1) of \(session.plots.count)")
                            .font(.caption).monospacedDigit().foregroundStyle(.secondary)
                        Button { session.selectedPlot = index + 1 } label: { Image(systemName: "chevron.right") }
                            .disabled(index == session.plots.count - 1)
                            .accessibilityLabel("Next plot")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Report

/// The knitted document, laid out like the report it will become.
struct ReportView: View {
    let session: LevelSession

    var body: some View {
        if let document = session.document {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if let title = session.documentTitle {
                        Text(title).font(.system(.title, design: .serif).weight(.semibold))
                    }
                    MarkdownView(markdown: document) { name in
                        guard name.hasPrefix("plot:"), let n = Int(name.dropFirst(5)),
                              session.plots.indices.contains(n - 1),
                              let image = NSImage(data: session.plots[n - 1]) else { return nil }
                        return AnyView(
                            Image(nsImage: image)
                                .resizable()
                                .interpolation(.high)
                                .scaledToFit()
                                .frame(maxWidth: 620)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .accessibilityLabel("Figure \(n)"))
                    }
                }
                .padding(20)
                .frame(maxWidth: 760, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else if session.lastStatus != nil, session.lastStatus != .ok {
            placeholder("The document didn't knit. The Console tab shows the error and the line it stopped at.",
                        symbol: "exclamationmark.triangle")
        } else {
            placeholder("Press Run (⌘↩) to knit your document: R runs each chunk, fills in the inline `r` values, "
                        + "and the report appears here. **Render** makes the finished HTML with Quarto.",
                        symbol: "doc.richtext")
        }
    }
}

// MARK: - Checks

private struct ChecksView: View {
    let session: LevelSession

    var body: some View {
        if session.checks.isEmpty {
            placeholder("Press Check (⇧⌘↩) when you think you've got it. Run is free; "
                        + "each Check counts toward this level's par of \(session.level.par).",
                        symbol: "checklist")
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    summary
                    if session.isBoss {
                        bossSteps
                    } else {
                        ForEach(Array(session.checks.enumerated()), id: \.offset) { _, check in
                            CheckRow(check: check)
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Steps already passed and the step in play show their checks; later steps stay closed.
    private var bossSteps: some View {
        ForEach(Array(session.steps.enumerated()), id: \.offset) { index, step in
            let number = index + 1
            let these = session.checks.filter { ($0.step ?? 1) == number }
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: number <= session.stepsPassed ? "checkmark.circle.fill"
                          : number == session.currentStep ? "\(number).circle.fill" : "lock.circle")
                        .foregroundStyle(number <= session.stepsPassed ? Theme.pass
                                         : number == session.currentStep ? Theme.accent : .secondary)
                    Text("Step \(number): \(step.title)").font(.callout.weight(.semibold))
                    Spacer()
                    if number <= session.currentStep {
                        Text("\(these.filter(\.passed).count)/\(these.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                if number <= session.currentStep {
                    ForEach(Array(these.enumerated()), id: \.offset) { _, check in
                        CheckRow(check: check).padding(.leading, 26)
                    }
                } else if number == session.currentStep + 1 {
                    Text("Opens when step \(number - 1) passes.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 26)
                }
            }
            .opacity(number > session.currentStep ? 0.6 : 1)
        }
    }

    @ViewBuilder private var summary: some View {
        let passed = session.checks.filter(\.passed).count
        let total = session.checks.count
        if session.isBoss, !(passed == total && session.lastStatus == .ok) {
            VStack(alignment: .leading, spacing: 4) {
                Label("\(session.stepsPassed) of \(session.steps.count) steps cleared", systemImage: "flag.checkered")
                    .font(.headline)
                if let status = session.lastStatus, status != .ok {
                    Text("Your code stopped with an error, so the steps after it can't pass yet. "
                         + "The Console tab shows where.")
                        .font(.callout)
                        .foregroundStyle(Theme.warn)
                }
            }
        } else if passed == total, session.lastStatus == .ok {
            Label("All \(total) checks passed. Planet charted!", systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Theme.pass)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Label("\(passed) of \(total) checks passed", systemImage: "scope")
                    .font(.headline)
                if let status = session.lastStatus, status != .ok {
                    Text("Your code stopped before the end, so some checks may fail only because of "
                         + "that. Fix the error in the Console tab first.")
                        .font(.callout)
                        .foregroundStyle(Theme.warn)
                }
            }
        }
    }
}

private struct CheckRow: View {
    let check: CheckResult

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(color)
                .accessibilityLabel(check.passed ? "Passed" : "Not yet")
            VStack(alignment: .leading, spacing: 3) {
                Text(AttributedString.inlineMarkdown(check.label))
                    .fontWeight(.medium)
                if !check.passed, let message = check.message {
                    Text(AttributedString.inlineMarkdown(message))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .textSelection(.enabled)
    }

    private var symbol: String {
        check.passed ? "checkmark.circle.fill" : (check.internal ? "exclamationmark.circle.fill" : "xmark.circle.fill")
    }

    private var color: Color {
        check.passed ? Theme.pass : (check.internal ? Theme.warn : Theme.fail)
    }
}

// MARK: - Shared

func placeholder(_ text: String, symbol: String) -> some View {
    VStack(spacing: 10) {
        Image(systemName: symbol).font(.title).foregroundStyle(Theme.accent.opacity(0.7))
        Text(AttributedString.inlineMarkdown(text))
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
            .frame(maxWidth: 380)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
}
