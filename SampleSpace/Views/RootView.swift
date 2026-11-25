import SwiftUI

enum Destination: String, CaseIterable, Identifiable {
    case map, labs, workbench, review, profile

    var id: Self { self }

    var title: String {
        switch self {
        case .map: "Star Map"
        case .labs: "Lab Bay"
        case .workbench: "Workbench"
        case .review: "Review Nebula"
        case .profile: "Pilot Profile"
        }
    }

    var symbol: String {
        switch self {
        case .map: "map"
        case .labs: "flask"
        case .workbench: "hammer"
        case .review: "sparkles"
        case .profile: "person.crop.circle"
        }
    }
}

struct RootView: View {
    @State private var destination: Destination? = .map
    @State private var model = GameModel()
    /// The Workbench pushes nothing, but a path-bound stack keeps SwiftUI happy when the
    /// detail column switches between stacks.
    @State private var workbenchPath: [String] = []

    var body: some View {
        NavigationSplitView {
            List(Destination.allCases, selection: $destination) { item in
                Label(item.title, systemImage: item.symbol)
                    .badge(item == .review ? model.reviewQueue().count : 0)
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
            case .labs:
                LabBayView()
            case .workbench:
                NavigationStack(path: $workbenchPath) { WorkbenchView() }
            case .review:
                ReviewView()
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
