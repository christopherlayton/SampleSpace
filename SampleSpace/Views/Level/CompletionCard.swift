import SwiftUI

/// Shown when every check passes: the stars earned, why, and where to go next.
/// (Step 5 adds the bigger celebration, ranks and saved progress.)
struct CompletionCard: View {
    let level: Level
    let completion: LevelSession.Completion
    let next: Level?
    let onNext: (Level) -> Void
    let onMap: () -> Void
    let onReplay: () -> Void
    let onStay: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shownStars = 0

    private var stars: Int { completion.score.stars }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture(perform: onStay)

            VStack(spacing: 18) {
                Text("Planet charted!")
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                Text(level.title).font(.title3).foregroundStyle(.secondary)

                HStack(spacing: 14) {
                    ForEach(0..<3, id: \.self) { index in
                        let lit = index < shownStars
                        Image(systemName: lit ? "star.fill" : "star")
                            .font(.system(size: 46, weight: .bold))
                            .foregroundStyle(lit ? Theme.gold : .white.opacity(0.25))
                            .shadow(color: lit ? Theme.gold.opacity(0.7) : .clear, radius: 12)
                            .scaleEffect(lit ? 1 : 0.8)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(stars) of 3 stars")

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(completion.score.criteria.enumerated()), id: \.offset) { _, line in
                        Label(line.text, systemImage: line.met ? "star.fill" : "star")
                            .foregroundStyle(line.met ? Theme.gold : .secondary)
                    }
                }
                .font(.callout)

                Text(completion.firstClear ? "+\(completion.xp) XP" : "Already cleared: XP is earned once")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(completion.firstClear ? Theme.gold : .secondary)

                HStack(spacing: 10) {
                    if stars < 3 {
                        Button("Replay for ★★★", action: onReplay)
                    }
                    Button("Star Map", action: onMap)
                    if let next {
                        Button {
                            onNext(next)
                        } label: {
                            Label("Next: \(next.title)", systemImage: "arrow.right")
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                    } else {
                        Button("Keep Exploring", action: onStay)
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                    }
                }
                .controlSize(.large)
            }
            .padding(32)
            .frame(maxWidth: 460)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.gold.opacity(0.5), lineWidth: 1.5))
            .shadow(radius: 30)
            .onKeyPress(.escape) { onStay(); return .handled }
        }
        .task {
            if reduceMotion {
                shownStars = stars
                return
            }
            for count in 0...stars {
                withAnimation(.spring(duration: 0.4, bounce: 0.5)) { shownStars = count }
                try? await Task.sleep(for: .milliseconds(280))
            }
        }
    }
}
