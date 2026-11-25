import Foundation
import Testing
@testable import SampleSpace

@Suite("Settings and systems check")
@MainActor
struct PolishTests {
    @Test(.timeLimit(.minutes(1)))
    func systemsCheckFindsRAndItsPackages() async {
        let report = await RDiagnostics.run(rscriptPath: nil, quartoPath: nil)
        #expect(report.rVersion?.hasPrefix("R version") == true, "\(report.problem ?? "")")
        #expect(report.missingPackages.isEmpty, "missing: \(report.missingPackages)")
        #expect(report.installCommand == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func systemsCheckReportsAMissingR() async {
        let report = await RDiagnostics.run(rscriptPath: "/nowhere/Rscript", quartoPath: "/nowhere/quarto")
        #expect(report.rVersion == nil && report.problem != nil)
        #expect(report.quartoPath == nil)
    }

    @Test func installCommandListsWhatIsMissing() {
        let report = RDiagnostics(rVersion: "R version 4.5.3", missingPackages: ["afex", "haven"])
        #expect(report.installCommand == #"install.packages(c("afex","haven"), repos = "https://cloud.r-project.org")"#)
        #expect(!report.rReady)
    }

    @Test func reloadingTheEngineKeepsDrafts() throws {
        let model = GameModel(store: .temporary())
        let level = try #require(model.level(id: "launch-pad.calculator-console"))
        let session = model.session(for: level)
        session.code = "23 + 17"
        model.reloadEngine()
        #expect(model.engine != nil)
        let fresh = model.session(for: level)
        #expect(fresh !== session, "open levels get fresh sessions on the new engine")
        #expect(fresh.code == "23 + 17", "the draft survives")
    }

    @Test func soundCuesUseRealSystemSounds() {
        let cues: [SoundEffects.Cue] = [.checkPassed, .checkFailed, .stepCleared, .levelCleared, .badge,
                                        .promotion, .reviewRight, .reviewWrong]
        for cue in cues {
            #expect(NSSoundExists(cue.soundName), "\(cue.soundName)")
        }
    }

    private func NSSoundExists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: "/System/Library/Sounds/\(name).aiff")
    }
}
