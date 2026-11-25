import SwiftUI

/// The right pane of a Briefing or Predict level: one multiple-choice question at a time.
/// Pick a choice (click or press its number), lock it in (⇧⌘↩), then read why. On Predict
/// levels the question's code then runs in real R so the actual output sits under your guess.
struct QuizView: View {
    let session: LevelSession
    let onShowSolution: () -> Void
    @Environment(GameModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shake = 0

    private var quiz: QuizProgress { session.quiz }

    var body: some View {
        VStack(spacing: 0) {
            bar
            Divider()
            ScrollView {
                if let question = quiz.current {
                    questionView(question)
                        .id(quiz.index)
                        .padding(24)
                        .frame(maxWidth: 720, alignment: .leading)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .background(.black.opacity(0.12))
    }

    // MARK: Bar

    private var bar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(quiz.questions.indices, id: \.self) { index in
                    Button { session.goToQuestion(index) } label: { dot(index) }
                        .buttonStyle(.plain)
                        .disabled(index > quiz.solvedCount)
                        .help("Question \(index + 1)")
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Questions")

            Divider().frame(height: 18)

            if session.allHintsShown, !session.solutionShown, !session.level.hints.isEmpty {
                Button(action: onShowSolution) { Label("Answers", systemImage: "key") }
                    .help("Mark the right answers")
            } else {
                Button { session.showHint() } label: {
                    Label(session.level.hints.isEmpty ? "No hints"
                          : "Hint \(min(session.hintsShown + 1, session.level.hints.count))/\(session.level.hints.count)",
                          systemImage: "lightbulb")
                }
                .disabled(session.allHintsShown)
                .help("Reveal the next hint. Finishing without hints earns a star.")
            }

            Spacer()

            Label("\(quiz.attempts)/\(session.level.par)", systemImage: "checkmark.seal")
                .help("Answers locked in / par. Getting every answer right first time earns a star.")
                .foregroundStyle(quiz.attempts > session.level.par ? Theme.warn : .secondary)
                .font(.caption.monospacedDigit())
            if let best = model.bestStars(session.level.id) {
                StarRow(count: best, size: 11).help("Your best for this level")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.3))
    }

    private func dot(_ index: Int) -> some View {
        let solved = quiz.isSolved(index)
        let current = index == quiz.index
        return Text("\(index + 1)")
            .font(.system(.caption, design: .rounded).weight(.bold))
            .frame(width: 24, height: 24)
            .background(solved ? Theme.pass.opacity(0.35) : (current ? Theme.accent.opacity(0.3) : .white.opacity(0.06)),
                        in: Circle())
            .overlay(Circle().stroke(current ? Theme.accent : .clear, lineWidth: 1.5))
            .foregroundStyle(index > quiz.solvedCount ? .secondary : .primary)
            .accessibilityValue(solved ? "Answered" : (current ? "Current" : "Not answered"))
    }

    // MARK: Question

    private func questionView(_ question: QuizQuestion) -> some View {
        let solved = quiz.currentSolved
        let wrong = quiz.wrongChoices(quiz.index)
        return VStack(alignment: .leading, spacing: 16) {
            Text("Question \(quiz.index + 1) of \(quiz.questions.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)
            Text(AttributedString.inlineMarkdown(question.prompt))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)

            if let code = question.code {
                VStack(alignment: .leading, spacing: 6) {
                    Label(session.level.type == .predict && question.runsCode ? "Predict what R prints" : "Code",
                          systemImage: "terminal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    CodeBlock(code: code)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { index, choice in
                    choiceButton(index: index, text: choice, question: question, solved: solved,
                                 isWrong: wrong.contains(index))
                }
            }
            .modifier(Shake(amount: reduceMotion ? 0 : 8, shakes: CGFloat(shake)))

            if solved {
                feedback(question)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                HStack(spacing: 12) {
                    Button {
                        let before = quiz.attempts
                        let wasWrong = quiz.wrongChoices(quiz.index).count
                        session.lockInAnswer()
                        if quiz.attempts > before, quiz.wrongChoices(quiz.index).count > wasWrong {
                            withAnimation(.linear(duration: 0.35)) { shake += 1 }
                        }
                    } label: {
                        Label("Lock in", systemImage: "checkmark.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: [.command, .shift])
                    .disabled(quiz.selection == nil)
                    .help("Lock in your answer (⇧⌘↩)")

                    if !wrong.isEmpty {
                        Label("Not quite. Read the code again and pick another answer.", systemImage: "xmark.circle")
                            .foregroundStyle(Theme.warn)
                            .font(.callout)
                    } else {
                        Text("Press 1–\(question.choices.count) to choose.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: solved)
    }

    private func choiceButton(index: Int, text: String, question: QuizQuestion, solved: Bool,
                              isWrong: Bool) -> some View {
        let selected = quiz.selection == index
        let isAnswer = index == question.answer
        let showRight = solved && isAnswer
        let markAnswer = session.solutionShown && isAnswer && !solved
        let tint: Color = showRight ? Theme.pass : (isWrong ? Theme.fail : (selected ? Theme.accent : .white))
        return Button { session.select(index) } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(index + 1)")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .frame(width: 20, height: 20)
                    .background(tint.opacity(0.25), in: Circle())
                Group {
                    if question.showsChoicesAsCode {
                        Text(text).font(Theme.codeFont)
                    } else {
                        Text(AttributedString.inlineMarkdown(text))
                    }
                }
                .strikethrough(isWrong)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                if showRight {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.pass)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.fail)
                } else if markAnswer {
                    Image(systemName: "key.fill").foregroundStyle(Theme.gold).help("The right answer")
                }
            }
            .padding(12)
            .background(tint.opacity(selected || showRight || isWrong ? 0.12 : 0.04),
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(tint.opacity(selected || showRight ? 0.8 : 0.15), lineWidth: selected || showRight ? 1.5 : 1))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(solved || isWrong)
        .opacity(isWrong ? 0.6 : 1)
        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: [])
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityValue(showRight ? "Right answer" : (isWrong ? "Wrong" : ""))
    }

    @ViewBuilder private func feedback(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(quiz.wrongChoices(quiz.index).isEmpty ? "Right first time." : "Right.",
                  systemImage: "checkmark.seal.fill")
                .font(.headline)
                .foregroundStyle(Theme.pass)
            if let explain = question.explain {
                MarkdownView(markdown: explain)
            }
            if question.runsCode {
                VStack(alignment: .leading, spacing: 6) {
                    Label("What R actually printed", systemImage: "terminal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Group {
                        if let entries = session.quizOutputs[quiz.index] {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                                    ConsoleLine(entry: entry)
                                }
                            }
                        } else {
                            ProgressView().controlSize(.small)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.editorBackground, in: RoundedRectangle(cornerRadius: 10))
                    .textSelection(.enabled)
                }
            }
            HStack {
                Spacer()
                if quiz.isLast {
                    Button { session.finishQuiz() } label: { Label("Finish", systemImage: "flag.checkered") }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: [.command, .shift])
                        .disabled(!quiz.finished)
                } else {
                    Button { session.nextQuestion() } label: { Label("Next question", systemImage: "arrow.right") }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: [.command, .shift])
                }
            }
        }
        .padding(14)
        .background(Theme.pass.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.pass.opacity(0.3)))
    }
}

/// A side-to-side wobble for a wrong answer.
private struct Shake: GeometryEffect {
    var amount: CGFloat
    var shakes: CGFloat
    var animatableData: CGFloat {
        get { shakes }
        set { shakes = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(shakes * .pi * 4), y: 0))
    }
}
