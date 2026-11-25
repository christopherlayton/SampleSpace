import SwiftUI

/// The bar above a lab level's right pane: the two stages (the instrument, then "now do it in R")
/// and how many goals are reached.
struct LabStageBar: View {
    let session: LevelSession

    var body: some View {
        HStack(spacing: 12) {
            Picker("Stage", selection: Bindable(session).labStage) {
                Label("1  Lab", systemImage: session.level.lab?.kind.symbol ?? "flask")
                    .tag(LevelSession.LabStage.lab)
                Label("2  Now do it in R", systemImage: session.labReady ? "chevron.left.forwardslash.chevron.right"
                                                                         : "lock.fill")
                    .tag(LevelSession.LabStage.r)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .help("The R stage opens once every lab goal is reached")

            Spacer()

            let goals = session.labGoals
            Label("\(goals.reached.count)/\(goals.goals.count) goals", systemImage: "scope")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(goals.allReached ? Theme.pass : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.3))
        .onChange(of: session.labStage) { _, stage in
            // The R stage stays locked until the goals are reached.
            if stage == .r, !session.labReady { session.labStage = .lab }
        }
    }
}

/// Stage 1 of a lab level: the instrument, with the goals beside it.
struct LabStageView: View {
    let session: LevelSession
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var justReached: Int?

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                if let instrument = session.instrument {
                    LabInstrumentView(instrument: instrument)
                        .padding(18)
                        .modifier(ReadingsWatcher(instrument: instrument) { readings in
                            let newly = session.updateLab(readings: readings)
                            if let first = newly.first { flash(first) }
                        })
                }
            }
            .frame(minWidth: 380, maxWidth: .infinity)

            Divider()

            GoalsPanel(session: session, justReached: justReached)
                .frame(width: 250)
        }
    }

    private func flash(_ goal: Int) {
        withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.5)) { justReached = goal }
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation { if justReached == goal { justReached = nil } }
        }
    }
}

/// Re-reads the instrument's readings whenever they change and passes them on.
private struct ReadingsWatcher: ViewModifier {
    let instrument: LabInstrument
    let onChange: ([String: Double]) -> Void

    func body(content: Content) -> some View {
        let readings = instrument.readings
        content.onChange(of: ReadingsKey(readings), initial: true) { _, key in onChange(key.readings) }
    }

    /// Compares readings so that NaN equals NaN (an empty pile of means has no SD yet).
    struct ReadingsKey: Equatable {
        let readings: [String: Double]
        init(_ readings: [String: Double]) { self.readings = readings }
        static func == (a: Self, b: Self) -> Bool {
            a.readings.count == b.readings.count && a.readings.allSatisfy { key, value in
                guard let other = b.readings[key] else { return false }
                return value == other || (value.isNaN && other.isNaN)
            }
        }
    }
}

/// The lab's goals: reached ones ticked, the current one highlighted, and the hand-off to R.
struct GoalsPanel: View {
    let session: LevelSession
    let justReached: Int?

    var body: some View {
        let tracker = session.labGoals
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Label("Lab goals", systemImage: "scope")
                    .font(.headline)
                    .foregroundStyle(Theme.accent)
                ForEach(Array(tracker.goals.enumerated()), id: \.offset) { index, goal in
                    goalRow(index: index, goal: goal, reached: tracker.reached.contains(index),
                            current: tracker.current == index)
                }
                if session.labReady {
                    handOff
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Text("Reach every goal to open stage 2, where you do the same thing in R.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(.easeOut(duration: 0.3), value: tracker.reached)
        }
        .background(.black.opacity(0.18))
    }

    private func goalRow(index: Int, goal: LabGoal, reached: Bool, current: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: reached ? "checkmark.circle.fill" : (current ? "circle.dashed" : "circle"))
                .foregroundStyle(reached ? Theme.pass : (current ? Theme.gold : .secondary))
                .scaleEffect(justReached == index ? 1.5 : 1)
            VStack(alignment: .leading, spacing: 3) {
                Text(AttributedString.inlineMarkdown(goal.text))
                    .font(.callout.weight(current ? .semibold : .regular))
                    .foregroundStyle(reached ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = goal.detail, current || reached {
                    Text(AttributedString.inlineMarkdown(detail))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(8)
        .background(current ? Theme.gold.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityValue(reached ? "Reached" : (current ? "Current goal" : "Not reached"))
    }

    private var handOff: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.labGoals.allReached ? "All goals reached." : "You've charted this lab before.")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.pass)
            Text("Now do it in R: the same numbers, from code you can rerun.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                session.labStage = .r
            } label: {
                Label("Now do it in R", systemImage: "arrow.right")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(Theme.pass.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}
