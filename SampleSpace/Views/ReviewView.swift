import SwiftUI

/// The Review Nebula: quick-fire cards on everything cleared so far, spaced so it sticks.
/// Cards are collected by clearing levels; `ReviewScheduler` decides what's due each day.
/// Choice cards answer on the first pick (click or number key); fill cards on Return.
struct ReviewView: View {
    @Environment(GameModel.self) private var model
    @State private var session: ReviewSession?
    /// Whether the session in progress is reviewing ahead (cards not due yet).
    @State private var reviewingAhead = false

    var body: some View {
        ZStack {
            StarfieldView()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if let session, let card = session.current {
                        ReviewCardView(card: card, session: Binding(get: { self.session ?? session },
                                                                    set: { self.session = $0 }),
                                       onEnd: { self.session = nil })
                            .id("\(card.id)-\(session.position)")
                    } else if let session, session.finished {
                        summary(session)
                    } else {
                        startPanel
                    }
                }
                .padding(28)
                .frame(maxWidth: 820, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Review Nebula")
    }

    // MARK: Header

    private var header: some View {
        let today = model.reviewedToday
        let goal = ReviewScheduler.dailyGoal
        let collected = model.reviewCards
        let learned = collected.filter { (model.cardState($0)?.box ?? 0) >= 3 }.count
        return HStack(alignment: .center, spacing: 22) {
            GoalRing(done: today, goal: goal)
            VStack(alignment: .leading, spacing: 6) {
                Text("Review Nebula").font(Theme.titleFont)
                Text(today >= goal ? "Daily goal reached. Extra cards still strengthen your memory."
                     : "Answer \(goal - today) more card\(goal - today == 1 ? "" : "s") to reach today's goal. Reviewing keeps the ship fuelled.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    stat("\(model.reviewQueue().count)", "due now", "tray.full")
                    stat("\(collected.count)/\(model.allReviewCardCount)", "collected", "square.stack.3d.up")
                    stat("\(learned)", "well learned", "brain.head.profile")
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }

    private func stat(_ value: String, _ label: String, _ symbol: String) -> some View {
        Label {
            HStack(spacing: 4) {
                Text(value).font(Theme.hudFont.monospacedDigit())
                Text(label).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbol).foregroundStyle(Theme.accent)
        }
        .font(.callout)
        .accessibilityElement(children: .combine)
    }

    // MARK: Start, empty and finished states

    @ViewBuilder private var startPanel: some View {
        let queue = model.reviewQueue()
        let collected = model.reviewCards
        VStack(alignment: .leading, spacing: 14) {
            if collected.isEmpty {
                Label("No cards yet", systemImage: "sparkles").font(.title3.weight(.semibold))
                Text("Every level you clear adds cards to the nebula: its quiz questions, plus fill-in-the-code, concept and \"which test?\" cards on what it taught. Clear a level on the Star Map to collect your first.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if queue.isEmpty {
                Label("All caught up", systemImage: "checkmark.seal.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.pass)
                Text(caughtUpText(collected))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                let ahead = model.reviewAhead()
                if !ahead.isEmpty {
                    Button { start(ahead, ahead: true) } label: {
                        Label("Review \(ahead.count) ahead", systemImage: "forward")
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                    .help("Practise the cards due soonest (⌘↩). Right answers still move them up a box.")
                }
            } else {
                let newCount = queue.filter { model.cardState($0) == nil }.count
                Label("\(queue.count) card\(queue.count == 1 ? "" : "s") ready", systemImage: "sparkles")
                    .font(.title3.weight(.semibold))
                Text(readyText(due: queue.count - newCount, new: newCount))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button { start(queue, ahead: false) } label: {
                    Label("Start review", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
                .help("Start (⌘↩)")
            }
            howItWorks
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
    }

    private var howItWorks: some View {
        DisclosureGroup("How the nebula schedules cards") {
            Text("A right answer moves a card up a box and pushes its next review further away: 1, 3, 7, 14, 30, 60, then 120 days. A wrong answer sends it back to the start, and it comes round again before the session ends. Up to \(ReviewScheduler.newPerDay) new cards join each day.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
        .padding(.top, 6)
    }

    private func readyText(due: Int, new: Int) -> String {
        switch (due, new) {
        case (0, _): "\(new) new card\(new == 1 ? "" : "s") from levels you've cleared."
        case (_, 0): "\(due) card\(due == 1 ? "" : "s") due for review."
        default: "\(due) due for review and \(new) new."
        }
    }

    private func caughtUpText(_ collected: [ReviewCard]) -> String {
        guard let next = ReviewScheduler.nextDue(cards: collected, record: model.progress.review),
              let date = DayKey.date(next) else {
            return "Nothing is due. Clear more levels to collect more cards."
        }
        let when = Calendar.current.isDateInTomorrow(date) ? "tomorrow"
            : date.formatted(.dateTime.weekday(.wide).month().day())
        return "Nothing more is due today. The next cards come round \(when)."
    }

    private func summary(_ session: ReviewSession) -> some View {
        let goalMet = model.reviewedToday >= ReviewScheduler.dailyGoal
        return VStack(alignment: .leading, spacing: 12) {
            Label(reviewingAhead ? "Practice round complete" : "Session complete", systemImage: "flag.checkered")
                .font(.title3.weight(.semibold))
            let distinct = Set(session.queue.map(\.id)).count
            Text("\(distinct) card\(distinct == 1 ? "" : "s"), \(session.rightFirstTime) right first time.")
                .foregroundStyle(.secondary)
            if goalMet {
                Label("Today's goal of \(ReviewScheduler.dailyGoal) cards is met.", systemImage: "star.fill")
                    .foregroundStyle(Theme.gold)
            }
            Button { self.session = nil } label: { Label("Done", systemImage: "checkmark") }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: .command)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
    }

    private func start(_ cards: [ReviewCard], ahead: Bool) {
        reviewingAhead = ahead
        session = ReviewSession(queue: cards)
    }
}

// MARK: - One card

private struct ReviewCardView: View {
    let card: ReviewCard
    @Binding var session: ReviewSession
    let onEnd: () -> Void
    @Environment(GameModel.self) private var model
    @State private var picked: Int?
    @State private var typed = ""
    @State private var outcome: CardState?
    /// The card's box when it was shown (answering moves it, but the label shouldn't jump).
    @State private var shownBox: Int??
    @FocusState private var fieldFocused: Bool

    private var answered: Bool { session.result != nil }
    private var order: [Int] { card.choiceOrder(day: DayKey.dayNumber(for: model.now())) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            topBar
            Text(AttributedString.inlineMarkdown(card.prompt))
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            if let code = card.code {
                VStack(alignment: .leading, spacing: 6) {
                    Label(card.kind == .predict ? "Predict what R prints" : (card.kind == .fill ? "Fill the blank" : "Code"),
                          systemImage: "terminal")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    CodeBlock(code: answered && card.kind == .fill ? (card.filledCode ?? code) : code)
                }
            }
            if card.isChoice { choices } else { fillField }
            if answered { feedback }
        }
        .padding(22)
        .background(.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08)))
        .onAppear {
            fieldFocused = card.kind == .fill
            shownBox = .some(model.cardState(card)?.box)
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            Label(card.kind.title, systemImage: card.kind.symbol)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.accent.opacity(0.18), in: Capsule())
                .foregroundStyle(Theme.accent)
            if let level = model.level(id: card.levelID) {
                Text("From \(level.title)\(model.sectorName(forLevel: level.id).map { ", \($0)" } ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            let box = shownBox ?? model.cardState(card)?.box
            Text(box.map { $0 == 0 ? "Learning" : "Box \($0)" } ?? "New")
                .font(.caption.weight(.semibold))
                .foregroundStyle(box == nil ? Theme.gold : .secondary)
            Text("\(session.remaining) left")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            Button(action: onEnd) { Image(systemName: "xmark") }
                .buttonStyle(.borderless)
                .keyboardShortcut(.cancelAction)
                .help("End the session (Esc). Answers so far are saved.")
                .accessibilityLabel("End session")
        }
    }

    // MARK: Choices

    private var choices: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(order.enumerated()), id: \.offset) { position, index in
                choiceButton(position: position, index: index)
            }
            if !answered {
                Text("Pick an answer: click it or press 1–\(card.choices.count).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func choiceButton(position: Int, index: Int) -> some View {
        let isAnswer = index == card.answer
        let isPicked = picked == index
        let tint: Color = answered ? (isAnswer ? Theme.pass : (isPicked ? Theme.fail : .white)) : .white
        return Button { choose(index) } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text("\(position + 1)")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .frame(width: 20, height: 20)
                    .background(tint.opacity(0.25), in: Circle())
                Group {
                    if card.choicesAreCode {
                        Text(card.choices[index]).font(Theme.codeFont)
                    } else {
                        Text(AttributedString.inlineMarkdown(card.choices[index]))
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                if answered && isAnswer {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.pass)
                } else if answered && isPicked {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.fail)
                }
            }
            .padding(12)
            .background(tint.opacity(answered && (isAnswer || isPicked) ? 0.12 : 0.04),
                        in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(tint.opacity(answered && (isAnswer || isPicked) ? 0.8 : 0.15)))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(answered)
        .keyboardShortcut(KeyEquivalent(Character("\(position + 1)")), modifiers: [])
        .accessibilityValue(answered ? (isAnswer ? "Right answer" : (isPicked ? "Your answer, wrong" : "")) : "")
    }

    private func choose(_ index: Int) {
        guard !answered else { return }
        picked = index
        submit(correct: index == card.answer)
    }

    // MARK: Fill

    private var fillField: some View {
        HStack(spacing: 10) {
            TextField("What goes in the blank?", text: $typed)
                .font(Theme.codeFont)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .focused($fieldFocused)
                .disabled(answered)
                .onSubmit { if !answered { checkFill() } }
                .frame(maxWidth: 360)
            if !answered {
                Button("Check", action: checkFill)
                    .buttonStyle(.borderedProminent)
                    .disabled(typed.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Show answer") { submit(correct: false) }
                    .help("Counts as a miss, so the card comes round again soon.")
            }
        }
    }

    private func checkFill() {
        guard !typed.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        submit(correct: card.accepts(typed))
    }

    // MARK: Answering

    private func submit(correct: Bool) {
        session.record(correct: correct)
        outcome = model.recordReview(card, correct: correct)
    }

    private var feedback: some View {
        let right = session.result == true
        return VStack(alignment: .leading, spacing: 10) {
            Label(right ? "Right." : "Not quite.", systemImage: right ? "checkmark.seal.fill" : "xmark.seal.fill")
                .font(.headline)
                .foregroundStyle(right ? Theme.pass : Theme.fail)
            if card.kind == .fill, let answer = card.answers.first {
                HStack(spacing: 6) {
                    Text(right ? "Accepted:" : "The blank is")
                    Text(answer).font(Theme.codeFont).foregroundStyle(Theme.accent)
                }
                .font(.callout)
            }
            if let explain = card.explain {
                MarkdownView(markdown: explain)
            }
            HStack {
                if let outcome {
                    Label(nextText(outcome), systemImage: "calendar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { session.advance() } label: {
                    Label(session.remaining > 1 ? "Next card" : "Finish", systemImage: "arrow.right")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .help("Return")
            }
        }
        .padding(14)
        .background((right ? Theme.pass : Theme.fail).opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke((right ? Theme.pass : Theme.fail).opacity(0.3)))
    }

    private func nextText(_ state: CardState) -> String {
        let days = ReviewScheduler.interval(forBox: state.box)
        switch days {
        case 0: return "Again before this session ends"
        case 1: return "Box \(state.box) · back tomorrow"
        default: return "Box \(state.box) · back in \(days) days"
        }
    }
}

// MARK: - Goal ring

private struct GoalRing: View {
    let done: Int
    let goal: Int

    var body: some View {
        let fraction = min(1, Double(done) / Double(max(goal, 1)))
        ZStack {
            Circle().stroke(.white.opacity(0.1), lineWidth: 9)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(fraction >= 1 ? Theme.gold : Theme.accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.4), value: fraction)
            VStack(spacing: 0) {
                Text("\(done)").font(.system(.title2, design: .rounded).weight(.bold).monospacedDigit())
                Text("of \(goal) today").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(width: 92, height: 92)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily review goal")
        .accessibilityValue("\(done) of \(goal) cards today")
    }
}
