import SwiftUI

/// The ship's Lab Bay: every lab instrument, free to play with at any time. No goals, no
/// scoring; the scored lab missions live in their sectors on the Star Map.
struct LabBayView: View {
    @Environment(GameModel.self) private var model
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                StarfieldView()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Lab Bay").font(Theme.titleFont)
                            Text("Free play with the ship's instruments. The scored lab missions, with goals and the R hand-off, are on the Star Map in their sectors.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: 560, alignment: .leading)
                        }
                        if model.labLevels.isEmpty {
                            Text("No labs installed yet.").foregroundStyle(.secondary)
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 260), spacing: 16)], spacing: 16) {
                            ForEach(model.labLevels) { level in
                                Button { path.append(level.id) } label: { card(level) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Lab Bay")
            .navigationDestination(for: String.self) { id in
                if let level = model.level(id: id) {
                    LabSandboxView(level: level)
                }
            }
        }
    }

    private func card(_ level: Level) -> some View {
        let kind = level.lab?.kind
        let sector = model.sector(containing: level)
        return VStack(alignment: .leading, spacing: 10) {
            Image(systemName: kind?.symbol ?? "flask")
                .font(.system(size: 30))
                .foregroundStyle(sector?.color ?? Theme.accent)
            Text(kind?.title ?? level.title).font(.title3.weight(.bold))
            Text(kind?.blurb ?? level.summary)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if let sector {
                Label("Mission: \(level.title), \(sector.name)", systemImage: "scope")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.1)))
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// One instrument in free play: a fresh copy each time it's opened.
struct LabSandboxView: View {
    let level: Level
    @State private var instrument: LabInstrument?

    var body: some View {
        ZStack {
            StarfieldView(animated: false)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let kind = level.lab?.kind {
                        Text(kind.blurb).foregroundStyle(.secondary)
                    }
                    if let instrument {
                        LabInstrumentView(instrument: instrument)
                    }
                }
                .padding(22)
                .frame(maxWidth: 980)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .padding(24)
            }
        }
        .navigationTitle(level.lab?.kind.title ?? level.title)
        .navigationSubtitle("Free play")
        .onAppear { if instrument == nil { instrument = LabInstrument.make(for: level) } }
        .onDisappear { instrument?.stop() }
    }
}
