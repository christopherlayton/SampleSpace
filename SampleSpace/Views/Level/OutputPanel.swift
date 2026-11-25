import AppKit
import SwiftUI

/// The bottom-right pane: console, plots and check results from the last run.
struct OutputPanel: View {
    @Bindable var session: LevelSession

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Picker("Output", selection: $session.outputTab) {
                    Text("Console").tag(LevelSession.OutputTab.console)
                    Text(session.plots.isEmpty ? "Plots" : "Plots (\(session.plots.count))")
                        .tag(LevelSession.OutputTab.plots)
                    Text(checksTitle).tag(LevelSession.OutputTab.checks)
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
                case .checks: ChecksView(session: session)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.editorBackground.opacity(0.92))
    }

    private var checksTitle: String {
        guard !session.checks.isEmpty else { return "Checks" }
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

private struct ConsoleLine: View {
    let entry: ConsoleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.consoleText)
                .font(Theme.codeFont)
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
                    ForEach(Array(session.checks.enumerated()), id: \.offset) { _, check in
                        CheckRow(check: check)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder private var summary: some View {
        let passed = session.checks.filter(\.passed).count
        let total = session.checks.count
        if passed == total, session.lastStatus == .ok {
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

private func placeholder(_ text: String, symbol: String) -> some View {
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
