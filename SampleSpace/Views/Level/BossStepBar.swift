import AppKit
import SwiftUI

/// The bar above a Boss level's editor: every step of the analysis, which have passed, the one
/// in play (with what it asks for) and the locked ones still to come.
struct BossStepBar: View {
    let session: LevelSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(session.steps.enumerated()), id: \.offset) { index, step in
                        if index > 0 {
                            Rectangle()
                                .fill(index < session.currentStep ? Theme.pass.opacity(0.7) : .white.opacity(0.15))
                                .frame(width: 14, height: 2)
                                .accessibilityHidden(true)
                        }
                        pill(number: index + 1, step: step)
                    }
                }
                .padding(.horizontal, 12)
            }
            if let banner = bannerText {
                Label(banner, systemImage: "flag.checkered")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(Theme.pass)
                    .padding(.horizontal, 12)
                    .transition(.opacity)
            } else if let step = currentStep {
                Text(AttributedString.inlineMarkdown("**Step \(session.currentStep): \(step.title).** \(step.summary ?? "")"))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.07))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: session.stepJustCleared)
        .onChange(of: session.stepJustCleared) { _, step in
            guard let step else { return }
            NSAccessibility.post(element: NSApp.mainWindow as Any, notification: .announcementRequested,
                                 userInfo: [.announcement: "Step \(step) cleared", .priority: NSAccessibilityPriorityLevel.high.rawValue])
            Task {
                try? await Task.sleep(for: .seconds(4))
                if session.stepJustCleared == step { session.stepJustCleared = nil }
            }
        }
    }

    private var currentStep: BossStep? {
        session.steps.indices.contains(session.currentStep - 1) ? session.steps[session.currentStep - 1] : nil
    }

    private var bannerText: String? {
        guard let cleared = session.stepJustCleared, session.steps.indices.contains(cleared) else { return nil }
        return "Step \(cleared) cleared. On to step \(cleared + 1): \(session.steps[cleared].title)."
    }

    private func pill(number: Int, step: BossStep) -> some View {
        let passed = number <= session.stepsPassed
        let current = number == session.currentStep
        return HStack(spacing: 5) {
            Image(systemName: passed ? "checkmark.circle.fill" : current ? "\(number).circle.fill" : "lock.circle")
                .foregroundStyle(passed ? Theme.pass : current ? Theme.gold : .secondary)
            Text(step.title)
                .font(.caption.weight(current ? .bold : .medium))
                .foregroundStyle(current ? .primary : .secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(current ? Theme.gold.opacity(0.16) : .white.opacity(0.05), in: Capsule())
        .overlay(Capsule().stroke(current ? Theme.gold.opacity(0.6) : .clear))
        .help(step.summary ?? step.title)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(number), \(step.title): \(passed ? "passed" : current ? "in play" : "locked")")
    }
}

/// The Render button for Quarto documents, and what happened to the last render.
struct RenderControls: View {
    let session: LevelSession
    var folderName: String? = nil
    var dataDirectory: URL? = nil
    @State private var showProblem = false

    var body: some View {
        HStack(spacing: 6) {
            Button {
                session.renderReport(folderName: folderName, dataDirectory: dataDirectory)
            } label: {
                Label("Render", systemImage: "doc.richtext")
            }
            .keyboardShortcut("r", modifiers: [.command, .option])
            .disabled(session.renderState == .rendering)
            .help("Render the finished report with Quarto (⌥⌘R). It runs the whole document again in a fresh R.")

            switch session.renderState {
            case .idle:
                EmptyView()
            case .rendering:
                ProgressView().controlSize(.small)
                Text("Rendering…").font(.caption).foregroundStyle(.secondary)
            case .done(let url):
                Button { NSWorkspace.shared.open(url) } label: {
                    Label("Open \(url.pathExtension.uppercased())", systemImage: "arrow.up.forward.square")
                }
                .help("Open the rendered report (\(url.lastPathComponent))")
                Button { NSWorkspace.shared.activateFileViewerSelecting([url]) } label: {
                    Image(systemName: "folder")
                }
                .help("Show the report in Finder")
                .accessibilityLabel("Show the report in Finder")
            case .failed(let message):
                Button { showProblem = true } label: {
                    Label("Render failed", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(Theme.fail)
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showProblem) {
                    ScrollView {
                        Text(message)
                            .font(Theme.codeFont)
                            .textSelection(.enabled)
                            .padding(14)
                            .frame(maxWidth: 520, alignment: .leading)
                    }
                    .frame(maxHeight: 320)
                }
            }
        }
        .onChange(of: session.renderState) { _, state in
            if case .done(let url) = state { NSWorkspace.shared.open(url) }
        }
    }
}
