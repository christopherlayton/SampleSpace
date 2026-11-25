import SwiftUI

enum Destination: String, CaseIterable, Identifiable {
    case map, review, profile

    var id: Self { self }

    var title: String {
        switch self {
        case .map: "Star Map"
        case .review: "Review Nebula"
        case .profile: "Pilot Profile"
        }
    }

    var symbol: String {
        switch self {
        case .map: "map"
        case .review: "sparkles"
        case .profile: "person.crop.circle"
        }
    }
}

struct RootView: View {
    @State private var destination: Destination? = .map
    @State private var model = GameModel()

    var body: some View {
        NavigationSplitView {
            List(Destination.allCases, selection: $destination) { item in
                Label(item.title, systemImage: item.symbol)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch destination ?? .map {
            case .map:
                NavigationStack(path: $model.path) {
                    StarMapView()
                        .navigationDestination(for: String.self) { id in
                            if let level = model.level(id: id) {
                                LevelView(level: level)
                            } else {
                                ContentUnavailableView("Level not found", systemImage: "questionmark.circle",
                                                       description: Text(id))
                            }
                        }
                }
            case .review:
                ComingSoonView(title: "Review Nebula", symbol: "sparkles",
                               message: "Quick-fire review of what you've learned, spaced so it sticks. Arrives in Step 12.")
            case .profile:
                ProfileView()
            }
        }
        .overlay(alignment: .bottom) { BadgeToast() }
        .environment(model)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
            model.save()
        }
    }
}

struct ComingSoonView: View {
    let title: String
    let symbol: String
    let message: String

    var body: some View {
        ZStack {
            StarfieldView()
            VStack(spacing: 14) {
                Image(systemName: symbol)
                    .font(.system(size: 44))
                    .foregroundStyle(Theme.accent)
                Text(title).font(Theme.titleFont)
                Text(message)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 340)
            }
            .padding(36)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
        }
        .navigationTitle(title)
    }
}
