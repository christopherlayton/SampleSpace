import SwiftUI

/// Shown when every check passes: the stars earned and why, XP, any promotion, new badges,
/// what opened up, and where to go next. Confetti for first clears, new bests and promotions.
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
    @State private var showExtras = false

    private var stars: Int { completion.score.stars }
    private var outcome: GameModel.ClearOutcome { completion.outcome }
    private var isNewBest: Bool { stars > (outcome.previousBest ?? 0) }
    private var celebrate: Bool { outcome.firstClear || isNewBest || outcome.rankUp != nil }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture(perform: onStay)

            if celebrate { ConfettiView() }

            VStack(spacing: 16) {
                if let rank = outcome.rankUp {
                    promotion(rank)
                }
                Text(outcome.firstClear ? "Planet charted!" : (isNewBest ? "New best!" : "Cleared again"))
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                Text(level.title).font(.title3).foregroundStyle(.secondary)

                starRow

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(completion.score.criteria.enumerated()), id: \.offset) { _, line in
                        Label(line.text, systemImage: line.met ? "star.fill" : "star")
                            .foregroundStyle(line.met ? Theme.gold : .secondary)
                    }
                }
                .font(.callout)

                Text(xpText)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(outcome.xpGained > 0 ? Theme.gold : .secondary)

                if showExtras { extras.transition(.opacity.combined(with: .move(edge: .bottom))) }

                buttons
            }
            .padding(32)
            .frame(maxWidth: 480)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(Theme.gold.opacity(0.5), lineWidth: 1.5))
            .shadow(radius: 30)
            .onKeyPress(.escape) { onStay(); return .handled }
        }
        .task {
            if reduceMotion {
                shownStars = stars
                showExtras = true
                return
            }
            for count in 0...stars {
                withAnimation(.spring(duration: 0.4, bounce: 0.5)) { shownStars = count }
                try? await Task.sleep(for: .milliseconds(280))
            }
            withAnimation(.easeOut(duration: 0.3)) { showExtras = true }
        }
    }

    private var xpText: String {
        if outcome.xpGained == 0 {
            let best = outcome.previousBest ?? stars
            return best == 3 ? "All stars already earned" : "No new XP: beat your best of \(best)★ to earn more"
        }
        if outcome.firstClear { return "+\(outcome.xpGained) XP" }
        return "+\(outcome.xpGained) XP star bonus"
    }

    private var starRow: some View {
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
    }

    private func promotion(_ rank: Rank) -> some View {
        Label("Promoted to \(rank.title)!", systemImage: rank.symbol)
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Theme.gold, in: Capsule())
            .shadow(color: Theme.gold.opacity(0.6), radius: 14)
    }

    @ViewBuilder private var extras: some View {
        if !outcome.newBadges.isEmpty || !outcome.opened.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(outcome.newBadges) { badge in
                    HStack(spacing: 10) {
                        BadgeIcon(badge: badge, earned: true, size: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Badge: \(badge.title)").font(.callout.weight(.semibold))
                            Text(badge.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                ForEach(outcome.opened, id: \.self) { name in
                    Label("Unlocked: \(name)", systemImage: "lock.open.fill")
                        .font(.callout)
                        .foregroundStyle(Theme.accent)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var buttons: some View {
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
}

/// A badge medallion: coloured when earned, dim and locked when not.
struct BadgeIcon: View {
    let badge: Badge
    let earned: Bool
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(earned ? AnyShapeStyle(LinearGradient(colors: [Theme.gold, Color.planet(hue: 0.08)],
                                                             startPoint: .top, endPoint: .bottom))
                             : AnyShapeStyle(Color.white.opacity(0.08)))
            Circle().stroke(earned ? Theme.gold : Color.white.opacity(0.15), lineWidth: 1.5)
            Image(systemName: earned ? badge.symbol : "lock.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(earned ? Color.black.opacity(0.75) : Color.white.opacity(0.35))
        }
        .frame(width: size, height: size)
        .shadow(color: earned ? Theme.gold.opacity(0.4) : .clear, radius: 6)
        .accessibilityHidden(true)
    }
}
