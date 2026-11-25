import Foundation
import Testing
@testable import SampleSpace

@Suite("Boss levels and Quarto documents")
@MainActor
struct BossLevelTests {
    private func check(_ step: Int?, _ passed: Bool) -> CheckResult {
        CheckResult(passed: passed, label: "c", message: nil, internal: false, step: step)
    }

    @Test func stepsPassCountsFromTheFirstUntilOneFails() {
        let checks = [check(1, true), check(1, true), check(2, true), check(3, false), check(4, true)]
        #expect(LevelSession.stepsPassed(checks, stepCount: 4) == 2)
        #expect(LevelSession.stepsPassed([check(1, false), check(2, true)], stepCount: 2) == 0)
        #expect(LevelSession.stepsPassed([check(1, true), check(2, true)], stepCount: 2) == 2)
        // A step with no checks (e.g. the script stopped before it) doesn't count as passed.
        #expect(LevelSession.stepsPassed([check(1, true)], stepCount: 3) == 1)
    }

    @Test func bossLevelsLoadTheirSteps() throws {
        let library = try ContentLibrary.loadBundled()
        let bosses = library.levels.filter { $0.type == .boss }
        #expect(bosses.map(\.id) == ["dissertation-dock.mentoring-boss", "dissertation-dock.programme-boss",
                                     "dissertation-dock.dry-run"])
        #expect(bosses.allSatisfy { ($0.steps ?? []).count >= 2 && $0.type.isPlayable })
        let finale = try #require(library.level(id: "dissertation-dock.dry-run"))
        #expect(finale.document == "report.qmd")
        #expect(finale.starterCode.hasPrefix("---\n"), "a document's starter is the .qmd file")
        #expect(library.sectors[11].levels.count == 12)
        #expect(library.sectors[11].reviewCards.count >= 20)
    }

    @Test(.timeLimit(.minutes(1)))
    func aBossOpensItsStepsOneByOne() async throws {
        let model = GameModel(store: .temporary())
        let level = try #require(model.level(id: "dissertation-dock.mentoring-boss"))
        let session = model.session(for: level)

        await session.perform(check: true)
        #expect(session.stepsPassed == 0 && session.currentStep == 1)

        // The solution up to the end of step 3 passes the first three steps.
        let lines = level.solutionCode.components(separatedBy: "\n")
        let stop = try #require(lines.firstIndex { $0.hasPrefix("# Step 4") })
        session.code = lines[..<stop].joined(separator: "\n")
        await session.perform(check: true)
        #expect(session.stepsPassed == 3)
        #expect(session.stepJustCleared == 3)
        #expect(session.completion == nil)
        #expect(session.checks.allSatisfy { $0.step != nil })

        session.code = level.solutionCode
        await session.perform(check: true)
        #expect(session.stepsPassed == 7)
        #expect(session.completion?.score.stars == 3)
        #expect(model.bestStars(level.id) == 3)

        session.replay()
        #expect(session.stepsPassed == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func documentsKnitIntoAReport() async throws {
        let engine = try REngine()
        let level = try #require(try ContentLibrary.loadBundled().level(id: "dissertation-dock.first-report"))
        let result = try await engine.run(level.job(code: level.solutionCode))
        #expect(result.passed)
        #expect(result.documentTitle == "Crew Log Report")
        let document = try #require(result.document)
        #expect(document.contains("1,277 missions flown by 564 astronauts"))
        #expect(!document.contains("read_csv"), "the setup chunk is hidden")

        let broken = try await engine.run(level.job(code: "---\ntitle: x\n---\n\nValue `r nope`.\n", check: false))
        #expect(broken.status == .error)
        #expect(broken.errorEntry?.text.contains("line 5") == true)
    }

    @Test(.timeLimit(.minutes(1)))
    func knittedFiguresBecomePlotSlots() async throws {
        let engine = try REngine()
        let code = "---\ntitle: Plot\n---\n\n```{r}\n#| echo: false\nplot(1:10)\n```\n"
        let result = try await engine.run(RJob(code: code, document: "report.qmd"))
        #expect(result.status == .ok)
        #expect(result.plots.count == 1)
        #expect(result.document?.contains("{{plot:1}}") == true)
    }

    @Test(.timeLimit(.minutes(1)))
    func apaChecksExplainWhatIsWrong() async throws {
        let engine = try REngine()
        let checks = """
            test <- t.test(extra ~ group, data = sleep)
            expect_apa(good, test, c(d = -0.83))
            expect_apa(bad, test, c(d = -0.83))
            """
        let code = """
            good <- "*t*(17.78) = -1.86, *p* = .079, *d* = 0.83"
            bad <- "t(17.78) = -1.9, p = 0.079, d = .83"
            """
        let result = try await engine.run(RJob(code: code, checks: checks))
        #expect(result.checks.count == 6)
        #expect(result.checks.prefix(3).allSatisfy { $0.passed })
        let failures = result.checks.suffix(3)
        #expect(failures.allSatisfy { !$0.passed && !$0.internal })
        #expect(failures.map { $0.message ?? "" }.joined().contains("leading zero"))
    }

    @Test func quartoSourceIsColouredOnlyWhereItIsR() {
        let text = "---\ntitle: \"Hi\"\n---\n\n# Results\n\nIt's `r nrow(x)` rows.\n\n```{r}\nx <- 1\n```\n"
        let ns = text as NSString
        let tokens = RSyntax.documentTokens(in: text).map { ($0.kind, ns.substring(with: $0.range)) }
        #expect(tokens.contains { $0.0 == .comment && $0.1 == "title: \"Hi\"" })
        #expect(tokens.contains { $0.0 == .keyword && $0.1 == "# Results" })
        #expect(tokens.contains { $0.0 == .function && $0.1 == "nrow" })
        #expect(tokens.contains { $0.0 == .assignment && $0.1 == "<-" })
        #expect(!tokens.contains { $0.0 == .string && $0.1.hasPrefix("'s") }, "an apostrophe in prose isn't a string")
    }

    @Test func nestedFencesShowAWholeQuartoExample() {
        let blocks = MarkdownBlock.parse("````qmd\n```{r}\nx <- 1\n```\n````\nAfter.")
        #expect(blocks == [.code("```{r}\nx <- 1\n```", language: "qmd"), .paragraph("After.")])
    }

    @Test(.timeLimit(.minutes(1)))
    func theWorkbenchTemplateKnits() async throws {
        let engine = try REngine()
        let template = try #require(Bundle.main.url(forResource: "template", withExtension: "qmd",
                                                    subdirectory: "Content/workbench"))
        let bank = try #require(Bundle.main.url(forResource: "data-bank", withExtension: nil, subdirectory: "Content"))
        let job = RJob(code: try String(contentsOf: template, encoding: .utf8), timeLimit: 60,
                       dataDirectory: bank, document: "report.qmd")
        let result = try await engine.run(job)
        #expect(result.status == .ok, "\(result.console.map(\.text))")
        #expect(result.document?.contains("1,277 rows") == true)
    }

    /// The full pipeline with the real `quarto` command (skipped if Quarto isn't installed).
    @Test(.timeLimit(.minutes(2)))
    func quartoRendersTheReport() async throws {
        let engine = try REngine()
        guard let quarto = QuartoRenderer(rscriptURL: engine.rscriptURL) else { return }
        let level = try #require(try ContentLibrary.loadBundled().level(id: "dissertation-dock.first-report"))
        let folder = FileManager.default.temporaryDirectory.appending(path: "ss-render-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let report = try await quarto.render(document: level.solutionCode, fileName: "report.qmd",
                                             dataDirectory: level.folder, into: folder)
        #expect(report.pathExtension == "html")
        let html = try String(contentsOf: report, encoding: .utf8)
        #expect(html.contains("1,277"))
    }
}
