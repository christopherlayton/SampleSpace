import SwiftUI

@main
struct SampleSpaceApp: App {
    var body: some Scene {
        WindowGroup("Sample Space") {
            RootView()
                .frame(minWidth: 1000, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 1320, height: 840)
        .windowToolbarStyle(.unified)
    }
}
