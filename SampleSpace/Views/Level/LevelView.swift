import AppKit
import SwiftUI

/// A level: the briefing on the left, the editor and its output on the right.
/// A lab level puts the instrument and its goals on the right first, then hands off to the
/// editor ("now do it in R") once the goals are reached. Briefing and Predict levels put a
/// quiz on the right instead of the editor; Debug levels add a bug report over the editor;
/// Boss levels add the step bar; Quarto documents add Render and a Report tab.
struct LevelView: View {
    let level: Level
    @Environment(GameModel.self) private var model
    @Environment(\.codeFontSize) private var codeFontSize
    @State private var confirmReset = false
    @State private var confirmSolution = false

    var body: some View {
        let session = model.session(for: level)
        ZStack {
            StarfieldView(animated: false)
            HSplitView {
                LessonView(level: level, sector: model.sector(containing: level), session: session)
                    .frame(minWidth: 300, idealWidth: 400, maxWidth: 560)
                    .background(.ultraThinMaterial)

                Group {
                    if session.isQuiz {
                        QuizView(session: session, onShowSolution: { confirmSolution = true })
                    } else if session.isLab {
                        VStack(spacing: 0) {
                            LabStageBar(session: session)
                            Divider()
                            if session.labStage == .lab {
                                LabStageView(session: session)
                            } else {
                                codeWorkspace(session)
                            }
                        }
                    } else {
                        codeWorkspace(session)
                    }
                }
                .frame(minWidth: session.isLab ? 620 : 460)
            }
            if let completion = session.completion {
                CompletionCard(level: level, completion: completion, next: model.nextLevel(after: level),
                               onNext: { next in
                                   session.completion = nil
                                   model.replaceTop(with: next)
                               },
                               onMap: {
                                   session.completion = nil
                                   model.path.removeAll()
                               },
                               onReplay: { session.replay() },
                               onStay: { session.completion = nil })
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
            }
        }
        .animation(.spring(duration: 0.35), value: session.completion)
        .navigationTitle(level.title)
        .navigationSubtitle(model.sector(containing: level)?.name ?? "")
        .onDisappear { session.cancel() }
        .onChange(of: session.checkResultsVersion) { _, _ in checkFeedback(session) }
        .onChange(of: session.completion) { _, completion in
            guard let completion else { return }
            SoundEffects.play(completion.outcome.rankUp != nil ? .promotion : .levelCleared)
        }
        .confirmationDialog("Put the starter code back?", isPresented: $confirmReset) {
            Button("Reset Code", role: .destructive) { session.reset() }
        } message: {
            Text("Your code in the editor will be replaced. You can undo with ⌘Z.")
        }
        .confirmationDialog(session.isQuiz ? "Mark the right answers?" : "Show the solution?",
                            isPresented: $confirmSolution) {
            Button(session.isQuiz ? "Mark Answers" : "Show Solution") { session.showSolution() }
        } message: {
            Text("You can still finish the level, but this attempt will earn at most one star.")
        }
    }

    /// A sound, and for VoiceOver a spoken summary, when a Check's results arrive. A clear has
    /// its own sound (the completion card), and a Boss step its own announcement (the step bar).
    private func checkFeedback(_ session: LevelSession) {
        guard session.completion == nil, !session.checks.isEmpty else { return }
        if session.stepJustCleared != nil {
            SoundEffects.play(.stepCleared)
            return
        }
        SoundEffects.play(session.checks.allSatisfy(\.passed) ? .checkPassed : .checkFailed)
        let passed = session.checks.filter(\.passed).count
        var text = "\(passed) of \(session.checks.count) checks passed."
        if let first = session.checks.first(where: { !$0.passed }) { text += " Next: \(first.label)" }
        if session.isBoss { text = "Step \(min(session.currentStep, session.steps.count)) of \(session.steps.count). " + text }
        NSAccessibility.post(element: NSApp.mainWindow as Any, notification: .announcementRequested,
                             userInfo: [.announcement: text.replacingOccurrences(of: "`", with: ""),
                                        .priority: NSAccessibilityPriorityLevel.high.rawValue])
    }

    private var bugReport: some View {
        Label {
            Text("**Bug report:** this code is broken. Run it, read what R says, and fix it. Reset brings the broken version back.")
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "ladybug.fill").foregroundStyle(Theme.fail)
        }
        .font(.callout)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.fail.opacity(0.1))
    }

    private func codeWorkspace(_ session: LevelSession) -> some View {
        VSplitView {
            VStack(spacing: 0) {
                actionBar(session)
                Divider()
                if level.type == .debug { bugReport }
                if session.isBoss { BossStepBar(session: session) }
                CodeEditor(text: Bindable(session).code, language: level.isDocument ? .quarto : .r, fontSize: codeFontSize)
            }
            .frame(minHeight: 220, idealHeight: 380)

            OutputPanel(session: session)
                .frame(minHeight: 150, idealHeight: 260)
        }
    }

    private func actionBar(_ session: LevelSession) -> some View {
        HStack(spacing: 8) {
            if session.isBusy {
                Button { session.cancel() } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .keyboardShortcut(".", modifiers: .command)
                .help("Stop R (⌘.)")
            } else {
                Button { session.run() } label: {
                    Label("Run", systemImage: "play.fill")
                }
                .keyboardShortcut(.return, modifiers: .command)
                .help(level.isDocument ? "Knit your document without checking it (⌘↩). Running is free."
                      : "Run your code without checking it (⌘↩). Running is free.")
            }

            Button { session.check() } label: {
                Label("Check", systemImage: session.labReady ? "checkmark.seal" : "lock.fill")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [.command, .shift])
            .disabled(session.isBusy || !session.labReady)
            .help(session.labReady ? "Run your code and check it against the mission (⇧⌘↩)."
                  : "Reach every lab goal first, then check your R.")

            Divider().frame(height: 18)

            if session.allHintsShown, !session.solutionShown {
                Button { confirmSolution = true } label: {
                    Label("Solution", systemImage: "key")
                }
                .help("Show the reference solution")
            } else {
                Button { session.showHint() } label: {
                    Label(hintTitle(session), systemImage: "lightbulb")
                }
                .disabled(session.allHintsShown)
                .help("Reveal the next hint. Finishing without hints earns a star.")
            }

            Button { confirmReset = true } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .disabled(session.isStarterCode)
            .help(level.type == .debug ? "Put the broken code back" : "Put the starter code back")

            if level.isDocument {
                Divider().frame(height: 18)
                RenderControls(session: session)
            }

            Spacer()

            attemptStatus(session)
        }
        .controlSize(.regular)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.3))
    }

    private func hintTitle(_ session: LevelSession) -> String {
        session.level.hints.isEmpty ? "No hints" : "Hint \(min(session.hintsShown + 1, session.level.hints.count))/\(session.level.hints.count)"
    }

    private func attemptStatus(_ session: LevelSession) -> some View {
        HStack(spacing: 10) {
            Label("\(session.checkAttempts)/\(level.par)", systemImage: "checkmark.seal")
                .help("Checks used / par. Passing within par earns a star.")
                .foregroundStyle(session.checkAttempts > level.par ? Theme.warn : .secondary)
            if let best = model.bestStars(level.id) {
                StarRow(count: best, size: 11)
                    .help("Your best for this level")
            }
        }
        .font(.caption.monospacedDigit())
    }
}

/// Filled and empty stars, e.g. ★★☆.
struct StarRow: View {
    let count: Int
    var total = 3
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<total, id: \.self) { index in
                Image(systemName: index < count ? "star.fill" : "star")
                    .font(.system(size: size, weight: .semibold))
                    .foregroundStyle(index < count ? Theme.gold : .secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) of \(total) stars")
    }
}
