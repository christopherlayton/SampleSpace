import SwiftUI

/// A code level: the briefing on the left, the editor and its output on the right.
struct LevelView: View {
    let level: Level
    @Environment(GameModel.self) private var model
    @State private var confirmReset = false
    @State private var confirmSolution = false

    var body: some View {
        let session = model.session(for: level)
        ZStack {
            StarfieldView()
            HSplitView {
                LessonView(level: level, sector: model.sector(containing: level), session: session)
                    .frame(minWidth: 300, idealWidth: 400, maxWidth: 560)
                    .background(.ultraThinMaterial)

                VSplitView {
                    VStack(spacing: 0) {
                        actionBar(session)
                        Divider()
                        CodeEditor(text: Bindable(session).code)
                    }
                    .frame(minHeight: 220, idealHeight: 380)

                    OutputPanel(session: session)
                        .frame(minHeight: 150, idealHeight: 260)
                }
                .frame(minWidth: 460)
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
        .confirmationDialog("Put the starter code back?", isPresented: $confirmReset) {
            Button("Reset Code", role: .destructive) { session.reset() }
        } message: {
            Text("Your code in the editor will be replaced. You can undo with ⌘Z.")
        }
        .confirmationDialog("Show the solution?", isPresented: $confirmSolution) {
            Button("Show Solution") { session.showSolution() }
        } message: {
            Text("You can still finish the level, but this attempt will earn at most one star.")
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
                .help("Run your code without checking it (⌘↩). Running is free.")
            }

            Button { session.check() } label: {
                Label("Check", systemImage: "checkmark.seal")
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.return, modifiers: [.command, .shift])
            .disabled(session.isBusy)
            .help("Run your code and check it against the mission (⇧⌘↩).")

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
            .help("Put the starter code back")

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
