import SwiftUI

/// The main screen: a scrollable map of sectors joined by a flight route.
struct StarMapView: View {
    @Environment(GameModel.self) private var model
    @State private var selectedID: Sector.ID?
    private var sectors: [Sector] { model.sectors }
    private let mapSize = CGSize(width: 1500, height: 900)

    var body: some View {
        ZStack {
            StarfieldView()

            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    RouteView(sectors: sectors, mapSize: mapSize)
                    ForEach(sectors) { sector in
                        Button {
                            withAnimation(.spring(duration: 0.35)) { selectedID = sector.id }
                        } label: {
                            PlanetNode(sector: sector, isSelected: sector.id == selectedID)
                        }
                        .buttonStyle(.plain)
                        .position(x: sector.mapPosition.x * mapSize.width,
                                  y: sector.mapPosition.y * mapSize.height)
                    }
                }
                .frame(width: mapSize.width, height: mapSize.height)
                .padding(.top, 40)
            }
            .scrollIndicators(.hidden)
        }
        .overlay(alignment: .top) { HUDBar(player: model.player).padding(.top, 12) }
        .overlay {
            if let loadError = model.loadError {
                ContentUnavailableView("Couldn't load the star map", systemImage: "exclamationmark.triangle",
                                       description: Text(loadError))
                    .padding(30)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .frame(maxWidth: 520)
            }
        }
        .overlay(alignment: .trailing) {
            if let sector = sectors.first(where: { $0.id == selectedID }) {
                SectorPanel(sector: sector, bestStars: model.bestStars, open: model.open) {
                    withAnimation(.spring(duration: 0.3)) { selectedID = nil }
                }
                .padding(20)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .navigationTitle("Star Map")
    }
}

// MARK: - Route

private struct RouteView: View {
    let sectors: [Sector]
    let mapSize: CGSize

    var body: some View {
        Canvas { ctx, _ in
            let points = sectors.map {
                CGPoint(x: $0.mapPosition.x * mapSize.width, y: $0.mapPosition.y * mapSize.height)
            }
            guard points.count > 1 else { return }
            for i in 1..<points.count {
                let a = points[i - 1], b = points[i]
                var path = Path()
                path.move(to: a)
                // Gentle curve: bow the control point sideways from the midpoint.
                let mid = CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
                let bow: CGFloat = i.isMultiple(of: 2) ? 40 : -40
                path.addQuadCurve(to: b, control: CGPoint(x: mid.x + bow, y: mid.y - bow / 2))

                let open = sectors[i].status != .locked
                let style = StrokeStyle(lineWidth: open ? 3 : 2, lineCap: .round,
                                        dash: sectors[i].isOptional ? [2, 8] : (open ? [] : [6, 9]))
                ctx.stroke(path, with: .color(open ? Theme.accent.opacity(0.8) : Theme.route.opacity(0.35)),
                           style: style)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Planet

private struct PlanetNode: View {
    let sector: Sector
    let isSelected: Bool
    @State private var hovering = false
    @State private var pulse = false

    private var locked: Bool { sector.status == .locked }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                if !locked {
                    Circle()
                        .fill(sector.color.opacity(0.45))
                        .frame(width: sector.planetSize * 1.5)
                        .blur(radius: 18)
                }
                if sector.status == .current {
                    Circle()
                        .stroke(Theme.accent.opacity(pulse ? 0 : 0.8), lineWidth: 2)
                        .frame(width: sector.planetSize * (pulse ? 1.9 : 1.15))
                        .onAppear {
                            withAnimation(.easeOut(duration: 1.8).repeatForever(autoreverses: false)) {
                                pulse = true
                            }
                        }
                }
                planetBody
                if sector.hasRing {
                    Ellipse()
                        .stroke(sector.color.opacity(0.7), lineWidth: 3)
                        .frame(width: sector.planetSize * 1.7, height: sector.planetSize * 0.42)
                        .rotationEffect(.degrees(-18))
                }
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: sector.planetSize * 0.26, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                        .shadow(radius: 4)
                }
            }
            .frame(width: sector.planetSize * 1.9, height: sector.planetSize * 1.4)
            .saturation(locked ? 0.25 : 1)
            .opacity(locked ? 0.7 : 1)

            VStack(spacing: 2) {
                Text(sector.name)
                    .font(.system(.headline, design: .rounded))
                Text(sector.isOptional ? "Optional sector" : "Sector \(sector.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(isSelected ? 0.55 : 0.3), in: Capsule())
            .overlay(Capsule().stroke(isSelected ? Theme.accent : .clear, lineWidth: 1.5))
        }
        .scaleEffect(hovering ? 1.08 : 1)
        .animation(.spring(duration: 0.25), value: hovering)
        .onHover { hovering = $0 }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(sector.name), sector \(sector.id), \(locked ? "locked" : "open")")
    }

    private var planetBody: some View {
        Circle()
            .fill(RadialGradient(
                colors: [.white.opacity(0.9), sector.color, sector.color.opacity(0.5), .black.opacity(0.85)],
                center: UnitPoint(x: 0.32, y: 0.28),
                startRadius: 0, endRadius: sector.planetSize * 0.75))
            .frame(width: sector.planetSize, height: sector.planetSize)
            .shadow(color: sector.color.opacity(locked ? 0 : 0.6), radius: 10)
    }
}

// MARK: - HUD

private struct HUDBar: View {
    let player: PlayerSnapshot

    var body: some View {
        HStack(spacing: 10) {
            chip("person.badge.shield.checkmark", player.rank, Theme.accent)
            chip("bolt.fill", "\(player.xp) XP", Theme.gold)
            chip("star.fill", "\(player.stars)", Theme.gold)
            chip("fuelpump.fill", "Fuel \(Int(player.fuel * 100))%", .green)
        }
        .padding(6)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func chip(_ symbol: String, _ text: String, _ tint: Color) -> some View {
        Label {
            Text(text).font(Theme.hudFont)
        } icon: {
            Image(systemName: symbol).foregroundStyle(tint)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.white.opacity(0.06), in: Capsule())
    }
}

// MARK: - Sector detail panel

private struct SectorPanel: View {
    let sector: Sector
    let bestStars: [String: Int]
    let open: (Level) -> Void
    let close: () -> Void

    private var locked: Bool { sector.status == .locked }
    /// The first level not cleared yet, else the first level.
    private var nextLevel: Level? {
        sector.levels.first { bestStars[$0.id] == nil } ?? sector.levels.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Circle().fill(sector.color).frame(width: 14, height: 14).padding(.top, 6)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sector.name).font(Theme.titleFont)
                    Text(sector.isOptional ? "Optional sector" : "Sector \(sector.id)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark.circle.fill").font(.title3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Close")
            }

            section("R skills", sector.rSkills, symbol: "chevron.left.forwardslash.chevron.right")
            section("Stats concepts", sector.statsConcepts, symbol: "chart.bar.xaxis")

            Divider()

            levelList

            Button {
                if let nextLevel { open(nextLevel) }
            } label: {
                Label(locked ? "Locked" : (sector.levels.contains { bestStars[$0.id] != nil } ? "Continue" : "Enter sector"),
                      systemImage: locked ? "lock.fill" : "arrow.right.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(locked || nextLevel == nil)

            if locked {
                Text("Clear the previous sector to unlock this one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 300)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(sector.color.opacity(0.5), lineWidth: 1))
    }

    @ViewBuilder private var levelList: some View {
        if sector.levels.isEmpty {
            Label("Levels for this sector haven't been charted yet.", systemImage: "hourglass")
                .font(.callout)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(sector.levels.count) levels")
                    Spacer()
                    Text("\(sector.totalXP) XP")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)

                ForEach(Array(sector.levels.enumerated()), id: \.element.id) { index, level in
                    Button { open(level) } label: { levelRow(index: index, level: level) }
                        .buttonStyle(.plain)
                        .disabled(locked)
                }
            }
        }
    }

    private func levelRow(index: Int, level: Level) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(index + 1)")
                .font(.system(.caption, design: .rounded).weight(.bold))
                .frame(width: 20, height: 20)
                .background(sector.color.opacity(0.35), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(level.title).font(.callout.weight(.semibold))
                Text(level.summary).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if let stars = bestStars[level.id] {
                StarRow(count: stars, size: 9)
            } else {
                Image(systemName: level.type.symbol)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help(level.type.displayName)
            }
        }
        .padding(6)
        .contentShape(Rectangle())
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityHint(locked ? "Locked" : "Opens the level")
    }

    private func section(_ title: String, _ body: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.accent)
                .textCase(.uppercase)
            Text(body)
        }
    }
}
