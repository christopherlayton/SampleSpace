import SwiftUI

/// The welcome tour, shown on first launch (and from Help → Welcome Tour…): the story, how
/// levels are played and scored, and a systems check that R, its packages and Quarto are ready.
struct OnboardingView: View {
    var onFinish: () -> Void
    @State private var page = 0
    @State private var diagnostics: RDiagnostics?
    private let pageCount = 3

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                StarfieldView(animated: false)
                Group {
                    switch page {
                    case 0: welcome
                    case 1: howItPlays
                    default: systemsCheck
                    }
                }
                .padding(36)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            Divider()
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<pageCount, id: \.self) { index in
                        Circle()
                            .fill(index == page ? Theme.accent : .white.opacity(0.25))
                            .frame(width: 7, height: 7)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page \(page + 1) of \(pageCount)")
                Spacer()
                Button("Skip") { onFinish() }
                    .keyboardShortcut(.cancelAction)
                if page > 0 {
                    Button("Back") { page -= 1 }
                }
                Button(page == pageCount - 1 ? "Start Exploring" : "Next") {
                    if page == pageCount - 1 { onFinish() } else { page += 1 }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(16)
        }
        .frame(width: 720, height: 540)
        .task { diagnostics = await RDiagnostics.run(rscriptPath: Preferences.customRscriptPath,
                                                     quartoPath: Preferences.customQuartoPath) }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 16) {
            Image(systemName: "sparkles").font(.system(size: 40)).foregroundStyle(Theme.gold)
                .accessibilityHidden(true)
            Text("Welcome aboard the *Sample Space*").font(Theme.titleFont)
            Text("You're a cadet on a survey ship. Its data bank holds the **Crew Log**: the real record of every person who flew in space from 1961 to 2019. The ship's computer can store the log but can't read it. It speaks **R**.")
            Text("Each sector on the Star Map teaches an R skill and a piece of statistics, from your first mean to *t*-tests, ANOVA, chi-square and regression, and recovers one entry of the log. The last sector turns it all into a reproducible results report: the same journey your dissertation data will take.")
            Text("Coming from SPSS? So is the game: SPSS Translate levels show you SPSS output and ask for the R that reproduces it.")
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var howItPlays: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("How it plays").font(Theme.titleFont)
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .topLeading), GridItem(.flexible(), alignment: .topLeading)],
                      alignment: .leading, spacing: 14) {
                item("chevron.left.forwardslash.chevron.right", "Code, Debug, SPSS Translate",
                     "Write R; **Run** (⌘↩) is free, **Check** (⇧⌘↩) grades it against the mission.")
                item("questionmark.bubble", "Briefing and Predict", "Short questions; Predict shows what R really printed.")
                item("flask", "Labs", "Interactive simulations with goals, then \"now do it in R\".")
                item("flag.checkered", "Boss levels", "A whole analysis in steps, ending in an APA write-up.")
                item("star.fill", "Stars", "One for passing, one for no hints, one for passing within par.")
                item("fuelpump.fill", "Fuel and streak", "Practise daily to stay fuelled. A missed day costs fuel, never progress.")
                item("sparkles", "Review Nebula", "Ten quick cards a day bring back what you've learned.")
                item("hammer", "Workbench", "Your own data, your own Quarto report, no scoring.")
            }
        }
    }

    private func item(_ symbol: String, _ title: String, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: symbol).foregroundStyle(Theme.accent).frame(width: 22).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold)
                Text(AttributedString.inlineMarkdown(text)).font(.callout).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var systemsCheck: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ship systems check").font(Theme.titleFont)
            Text("Sample Space runs your code in the R installed on this Mac, so what you learn here is exactly what you'll use for your dissertation.")
            if let diagnostics {
                DiagnosticsView(diagnostics: diagnostics)
                if !diagnostics.rReady {
                    Text("You can still look around. Fix this in Settings → R & Quarto (⌘,), then press Apply and Check.")
                        .font(.callout).foregroundStyle(Theme.warn)
                } else {
                    Label("All systems go.", systemImage: "checkmark.seal.fill").foregroundStyle(Theme.pass)
                }
            } else {
                HStack(spacing: 8) {
                    ProgressView().controlSize(.small)
                    Text("Checking R, its packages and Quarto…").foregroundStyle(.secondary)
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
