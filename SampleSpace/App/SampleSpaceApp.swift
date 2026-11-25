import SwiftUI

@main
struct SampleSpaceApp: App {
    @State private var model: GameModel
    @AppStorage(Preferences.hasSeenOnboarding) private var hasSeenOnboarding = false

    init() {
        Preferences.register()
        _model = State(initialValue: GameModel())
    }

    var body: some Scene {
        WindowGroup("Sample Space") {
            RootView()
                .environment(model)
                .frame(minWidth: 1000, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1320, height: 840)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(after: .help) {
                Button("Welcome Tour…") { hasSeenOnboarding = false }
            }
        }

        Settings {
            SettingsView()
                .environment(model)
                .preferredColorScheme(.dark)
        }
    }
}
