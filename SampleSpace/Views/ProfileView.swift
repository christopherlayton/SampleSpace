import SwiftUI

/// Pilot Profile: rank and XP, fuel and streak history, badges, and progress per sector.
struct ProfileView: View {
    @Environment(GameModel.self) private var model
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            StarfieldView()
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let problem = model.progressProblem {
                        Label(problem, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Theme.warn)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.warn.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                    HStack(alignment: .top, spacing: 18) {
                        RankCard(xp: model.xp)
                        FuelCard(fuel: model.fuel, practiceDays: model.progress.practiceDays, today: model.now())
                    }
                    ShipsLogCard(sectors: model.sectors)
                    BadgesCard(earned: model.progress.badges)
                    SectorsCard(sectors: model.sectors, stars: model.bestStars)
                    HStack {
                        Spacer()
                        Button("Reset All Progress…", role: .destructive) { confirmReset = true }
                            .controlSize(.small)
                    }
                }
                .padding(24)
                .frame(maxWidth: 900)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("Pilot Profile")
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset) {
            Button("Reset Everything", role: .destructive) { model.resetProgress() }
        } message: {
            Text("Stars, XP, rank, badges, streak and saved code will all be erased. This can't be undone.")
        }
    }
}

// MARK: - Cards

private struct Card<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)
            content
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct RankCard: View {
    let xp: Int

    var body: some View {
        let rank = Rank.forXP(xp)
        Card(title: "Rank", symbol: "person.badge.shield.checkmark") {
            HStack(spacing: 14) {
                Image(systemName: rank.symbol)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 56, height: 56)
                    .background(Theme.gold.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(rank.title).font(Theme.titleFont)
                    Text("\(xp) XP").font(.headline.monospacedDigit()).foregroundStyle(Theme.gold)
                }
            }
            if let next = rank.next {
                ProgressView(value: Rank.progress(xp: xp))
                    .tint(Theme.gold)
                Text("\(next.minimumXP - xp) XP to \(next.title)")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Top rank. Your committee awaits.").font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                ForEach(Rank.allCases, id: \.self) { r in
                    Image(systemName: r.symbol)
                        .font(.caption)
                        .foregroundStyle(r <= rank ? Theme.gold : .white.opacity(0.25))
                        .help("\(r.title): \(r.minimumXP) XP")
                }
            }
        }
    }
}

private struct FuelCard: View {
    let fuel: FuelState
    let practiceDays: [String]
    let today: Date

    var body: some View {
        Card(title: "Fuel and streak", symbol: "fuelpump.fill") {
            HStack(spacing: 18) {
                Gauge(value: fuel.fuel) {
                    Text("Fuel")
                } currentValueLabel: {
                    Text("\(Int((fuel.fuel * 100).rounded()))%")
                }
                .gaugeStyle(.accessoryCircular)
                .tint(fuel.fuel > 0.5 ? Theme.pass : (fuel.fuel > 0.25 ? Theme.warn : Theme.fail))
                .scaleEffect(1.3)
                .frame(width: 70, height: 70)
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(fuel.streak)-day streak", systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(fuel.streak > 0 ? .orange : .secondary)
                    Text("Best: \(fuel.bestStreak) day\(fuel.bestStreak == 1 ? "" : "s")")
                        .font(.caption).foregroundStyle(.secondary)
                    Text(fuel.practisedToday ? "Practised today. Tank full."
                         : "Press Check on any level today to refuel.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            DayGrid(practiceDays: Set(practiceDays), today: today)
            Text("Each day away burns 25% fuel. Four days away in a row and the streak restarts. "
                 + "XP, stars and badges are never lost.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// The last four weeks, one square per day, lit on practice days.
private struct DayGrid: View {
    let practiceDays: Set<String>
    let today: Date

    var body: some View {
        let calendar = Calendar.current
        let days = (0..<28).reversed().compactMap { calendar.date(byAdding: .day, value: -$0, to: today) }
        VStack(alignment: .leading, spacing: 4) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(14), spacing: 4), count: 14), spacing: 4) {
                ForEach(days, id: \.self) { day in
                    let key = DayKey.key(for: day)
                    let practised = practiceDays.contains(key)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(practised ? Theme.pass : Color.white.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 3)
                            .stroke(calendar.isDate(day, inSameDayAs: today) ? Theme.accent : .clear))
                        .frame(width: 14, height: 14)
                        .help("\(day.formatted(date: .abbreviated, time: .omitted))\(practised ? ": practised" : "")")
                }
            }
            Text("Last 4 weeks").font(.caption2).foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Practised on \(days.filter { practiceDays.contains(DayKey.key(for: $0)) }.count) of the last 28 days")
    }
}

/// The Crew Log entries recovered so far, one per charted sector (see STORY.md).
private struct ShipsLogCard: View {
    let sectors: [Sector]

    var body: some View {
        let withLogs = sectors.filter { $0.log != nil }
        let recovered = withLogs.filter { $0.status == .completed }
        Card(title: "Ship's Log \(recovered.count)/\(withLogs.count)", symbol: "doc.text.magnifyingglass") {
            Text("Each sector you chart recovers an entry from the Crew Log: real findings from the "
                 + "record of everyone who flew in space from 1961 to 2019.")
                .font(.callout)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(withLogs) { sector in
                    if sector.status == .completed, let log = sector.log {
                        LogEntryView(entry: log)
                    } else {
                        Label("\(sector.log?.title ?? "") · chart \(sector.name) to recover it",
                              systemImage: "lock.fill")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Text("Crew Log data: Stavnichuk, M., & Corlett, T. (2020). Astronaut database [Data set]. "
                 + "Mendeley Data. doi:10.17632/86tsnnbv2w.1. CC BY 4.0. Cleaned for TidyTuesday by G. Karamanis.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

private struct BadgesCard: View {
    let earned: [String: Date]

    var body: some View {
        Card(title: "Badges \(earned.count)/\(Badge.all.count)", symbol: "rosette") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 12)], alignment: .leading, spacing: 12) {
                ForEach(Badge.all) { badge in
                    let date = earned[badge.id]
                    HStack(spacing: 10) {
                        BadgeIcon(badge: badge, earned: date != nil)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(badge.title).font(.callout.weight(.semibold))
                                .foregroundStyle(date != nil ? .primary : .secondary)
                            Text(badge.detail).font(.caption).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let date {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2).foregroundStyle(Theme.gold)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityValue(date != nil ? "Earned" : "Not earned yet")
                }
            }
        }
    }
}

private struct SectorsCard: View {
    let sectors: [Sector]
    let stars: (String) -> Int?

    var body: some View {
        Card(title: "Sectors", symbol: "map") {
            VStack(spacing: 10) {
                ForEach(sectors) { sector in
                    let cleared = sector.levels.filter { stars($0.id) != nil }.count
                    let earned = sector.levels.reduce(0) { $0 + (stars($1.id) ?? 0) }
                    HStack(spacing: 10) {
                        Circle().fill(sector.color).frame(width: 10, height: 10)
                            .opacity(sector.status == .locked ? 0.4 : 1)
                        Text(sector.name).frame(width: 170, alignment: .leading)
                            .foregroundStyle(sector.status == .locked ? .secondary : .primary)
                        if sector.levels.isEmpty {
                            Text("Not charted yet").font(.caption).foregroundStyle(.secondary)
                            Spacer()
                        } else {
                            ProgressView(value: Double(cleared), total: Double(sector.levels.count))
                                .tint(sector.color)
                            Text("\(cleared)/\(sector.levels.count)").monospacedDigit()
                                .frame(width: 44, alignment: .trailing)
                            Label("\(earned)/\(sector.levels.count * 3)", systemImage: "star.fill")
                                .monospacedDigit()
                                .foregroundStyle(Theme.gold)
                                .frame(width: 70, alignment: .trailing)
                        }
                        Image(systemName: sector.status == .completed ? "checkmark.seal.fill"
                              : (sector.status == .locked ? "lock.fill" : "circle.dotted"))
                            .foregroundStyle(sector.status == .completed ? Theme.gold : .secondary)
                            .frame(width: 18)
                    }
                    .font(.callout)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}
