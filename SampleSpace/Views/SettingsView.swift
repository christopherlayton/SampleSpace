import AppKit
import SwiftUI

/// Settings (⌘,): sounds and motion, text sizes, and where R and Quarto live.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettings()
                .tabItem { Label("General", systemImage: "gearshape") }
            TextSettings()
                .tabItem { Label("Text", systemImage: "textformat.size") }
            RSettings()
                .tabItem { Label("R & Quarto", systemImage: "terminal") }
        }
        .frame(width: 560)
        .padding(.vertical, 8)
    }
}

private struct GeneralSettings: View {
    @AppStorage(Preferences.soundsEnabled) private var sounds = true
    @AppStorage(Preferences.animatedBackground) private var animated = true
    @AppStorage(Preferences.hasSeenOnboarding) private var hasSeenOnboarding = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Form {
            Toggle("Play sounds", isOn: $sounds)
            Text("Short cues when a check passes or fails, a Boss step or level is cleared, a badge or promotion arrives, and for Review Nebula answers.")
                .font(.caption).foregroundStyle(.secondary)
            Toggle("Animate the starfield", isOn: $animated)
                .disabled(reduceMotion)
            Text(reduceMotion ? "Reduce Motion is on in System Settings, so the stars and confetti stay still."
                 : "The stars only move on the map and the Pilot Profile, and pause when the window isn't active.")
                .font(.caption).foregroundStyle(.secondary)
            Button("Show the Welcome Tour Again") { hasSeenOnboarding = false }
        }
        .formStyle(.grouped)
        .frame(height: 260)
    }
}

private struct TextSettings: View {
    @AppStorage(Preferences.codeFontSize) private var codeSize = Preferences.defaultCodeFontSize
    @AppStorage(Preferences.lessonFontSize) private var lessonSize = Preferences.defaultLessonFontSize

    var body: some View {
        Form {
            sizeRow("Code", value: $codeSize, range: Preferences.codeFontRange,
                    help: "The editor, the console and code in lessons.")
            Text("mean(scores, na.rm = TRUE)")
                .font(Theme.code(codeSize))
                .foregroundStyle(Theme.codeText)
            sizeRow("Lesson text", value: $lessonSize, range: Preferences.lessonFontRange,
                    help: "Briefings and the Report tab.")
            Text("The median mission lasted 261 hours.")
                .font(.system(size: lessonSize))
            Button("Reset Sizes") {
                codeSize = Preferences.defaultCodeFontSize
                lessonSize = Preferences.defaultLessonFontSize
            }
        }
        .formStyle(.grouped)
        .frame(height: 300)
    }

    private func sizeRow(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, help: String) -> some View {
        LabeledContent {
            HStack {
                Slider(value: value, in: range, step: 1) { Text(title) }
                    .labelsHidden()
                    .frame(width: 200)
                Stepper("\(Int(value.wrappedValue)) pt", value: value, in: range)
                    .monospacedDigit()
            }
        } label: {
            VStack(alignment: .leading) {
                Text(title)
                Text(help).font(.caption).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) size")
        .accessibilityValue("\(Int(value.wrappedValue)) points")
    }
}

private struct RSettings: View {
    @Environment(GameModel.self) private var model
    @AppStorage(Preferences.rscriptPath) private var rscriptPath = ""
    @AppStorage(Preferences.quartoPath) private var quartoPath = ""
    @State private var diagnostics: RDiagnostics?
    @State private var checking = false

    var body: some View {
        Form {
            Section {
                pathRow("Rscript", text: $rscriptPath, placeholder: "Automatic (\(REngine.rscriptCandidates[0]))")
                pathRow("Quarto", text: $quartoPath, placeholder: "Automatic (\(QuartoRenderer.candidates[0]))")
            } footer: {
                Text("Leave a path empty to let Sample Space look in the usual places. Changes apply when you press Apply.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Systems check") {
                HStack {
                    Button("Apply and Check") { apply() }
                        .disabled(checking)
                    if checking { ProgressView().controlSize(.small) }
                }
                if let diagnostics { DiagnosticsView(diagnostics: diagnostics) }
                if let error = model.engineError {
                    Label(error, systemImage: "exclamationmark.triangle.fill").foregroundStyle(Theme.fail)
                }
            }
        }
        .formStyle(.grouped)
        .frame(height: 420)
        .task { if diagnostics == nil { await check() } }
    }

    private func pathRow(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        LabeledContent(title) {
            HStack {
                TextField(title, text: text, prompt: Text(placeholder))
                    .labelsHidden()
                    .textFieldStyle(.roundedBorder)
                Button("Choose…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = false
                    panel.allowsMultipleSelection = false
                    panel.treatsFilePackagesAsDirectories = true
                    panel.message = "Choose the \(title) program"
                    if panel.runModal() == .OK, let url = panel.url { text.wrappedValue = url.path }
                }
            }
        }
    }

    private func apply() {
        model.reloadEngine()
        Task { await check() }
    }

    private func check() async {
        checking = true
        diagnostics = await RDiagnostics.run(rscriptPath: Preferences.customRscriptPath,
                                             quartoPath: Preferences.customQuartoPath)
        checking = false
    }
}

/// The results of a systems check: R, its packages, and Quarto.
struct DiagnosticsView: View {
    let diagnostics: RDiagnostics

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            row(ok: diagnostics.rVersion != nil,
                title: diagnostics.rVersion ?? "R not found",
                detail: diagnostics.rscriptPath ?? diagnostics.problem ?? "")
            row(ok: diagnostics.rVersion != nil && diagnostics.missingPackages.isEmpty,
                title: diagnostics.missingPackages.isEmpty ? "All \(RDiagnostics.packages.count) R packages installed"
                    : "Missing packages: \(diagnostics.missingPackages.joined(separator: ", "))",
                detail: diagnostics.installCommand.map { "Install them in R with:\n\($0)" } ?? "")
            row(ok: diagnostics.quartoPath != nil,
                title: diagnostics.quartoVersion.map { "Quarto \($0)" } ?? "Quarto not found",
                detail: diagnostics.quartoPath ?? "Only needed for Render (quarto.org). Knitting in the app works without it.")
        }
        .textSelection(.enabled)
    }

    private func row(ok: Bool, title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(ok ? Theme.pass : Theme.warn)
                .accessibilityLabel(ok ? "Ready" : "Needs attention")
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium))
                if !detail.isEmpty {
                    Text(detail).font(.caption.monospaced()).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
