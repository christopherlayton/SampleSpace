import Foundation
import Testing
@testable import SampleSpace

/// Python is optional, so these run only when python3 with pandas, scipy, statsmodels and
/// seaborn is installed (`scripts/validate_content.sh` checks the content the same way).
private let pythonReady: Bool = {
    guard let python = REngine.pythonCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
        return false
    }
    let process = Process()
    process.executableURL = URL(filePath: python)
    process.arguments = ["-c", "import pandas, scipy, statsmodels, seaborn, pyreadstat"]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    guard (try? process.run()) != nil else { return false }
    process.waitUntilExit()
    return process.terminationStatus == 0
}()

@Suite("Python engine", .enabled(if: pythonReady), .timeLimit(.minutes(2)))
struct PythonEngineTests {
    let engine: REngine

    init() throws {
        engine = try REngine()
    }

    private func run(_ code: String, checks: String? = nil, timeLimit: Double = 10, seed: Int? = nil,
                     setup: String? = nil, data: URL? = nil) async throws -> RRunResult {
        try await engine.run(RJob(code: code, checks: checks, setup: setup, seed: seed, timeLimit: timeLimit,
                                  dataDirectory: data, language: .python))
    }

    private func texts(_ result: RRunResult, _ kind: ConsoleEntry.Kind) -> [String] {
        result.console.filter { $0.kind == kind }.map(\.text)
    }

    @Test func echoesValuesLikeThePythonPrompt() async throws {
        let result = try await run("x = [2, 4, 6]\nx[0]\nprint(\"done\")\nfor v in x:\n    v\nNone")
        #expect(result.status == .ok)
        #expect(texts(result, .input) == ["x = [2, 4, 6]", "x[0]", "print(\"done\")", "for v in x:\n    v", "None"])
        #expect(texts(result, .output) == ["2", "done"], "only top-level expressions echo, and None doesn't")
        #expect(result.console[3].consoleText(language: .python) == ">>> print(\"done\")")
        #expect(result.console.first { $0.text.hasPrefix("for") }?.consoleText(language: .python) == ">>> for v in x:\n...     v")
    }

    @Test func printsNumpyScalarsAsPlainNumbers() async throws {
        let result = try await run("import pandas as pd\npd.Series([4, None, 6]).mean()")
        #expect(texts(result, .output) == ["5.0"])
    }

    @Test func statementsSharingALineEchoOnce() async throws {
        let result = try await run("a = 1; b = 2\na + b")
        #expect(texts(result, .input) == ["a = 1; b = 2", "a + b"])
        #expect(texts(result, .output) == ["3"])
    }

    @Test func stopsAtTheFirstErrorWithItsLine() async throws {
        let result = try await run("x = 1\ny = x + z\nprint(\"never\")")
        #expect(result.status == .error)
        #expect(!result.passed)
        let error = try #require(result.errorEntry)
        #expect(error.text == "NameError: name 'z' is not defined")
        #expect(error.consoleText(language: .python) == "Error on line 2: NameError: name 'z' is not defined")
        #expect(!texts(result, .input).contains("print(\"never\")"))
    }

    @Test func reportsSyntaxErrorsBeforeRunningAnything() async throws {
        let result = try await run("print(\"first\")\nfirst = log[log[\"n\"] = 1]")
        #expect(result.status == .parseError)
        #expect(texts(result, .output).isEmpty)
        let error = try #require(result.errorEntry)
        #expect(error.text.hasPrefix("Python couldn't read your code: SyntaxError"))
        #expect(error.call == "line 2")
        #expect(ErrorExplainer.explain(error, language: .python)?.contains("`==`") == true)
    }

    @Test func warningsAreKeptWithTheirLine() async throws {
        let result = try await run("import warnings\nwarnings.warn(\"careful\")")
        #expect(result.status == .ok)
        let warning = try #require(result.console.first { $0.kind == .warning })
        #expect(warning.consoleText(language: .python) == "Warning on line 2: UserWarning: careful")
    }

    @Test func savesAFigurePerShowAndAnyLeftOpen() async throws {
        let code = """
            import matplotlib.pyplot as plt
            plt.hist([1, 2, 2, 3])
            plt.xlabel("hours")
            plt.show()
            plt.plot([1, 2, 3])
            """
        let result = try await run(code, checks: "expect_plot(2)\nexpect_true(plot_label('x', 1) == 'hours')")
        #expect(result.status == .ok)
        #expect(result.plots.count == 2)
        #expect(result.plots.allSatisfy { $0.starts(with: [0x89, 0x50, 0x4E, 0x47]) }, "PNG data")
        #expect(texts(result, .output).isEmpty, "matplotlib's return values aren't echoed")
        #expect(result.passed)
    }

    @Test func checksSeeTheLearnersVariables() async throws {
        let checks = """
            expect_object("total", 6)
            expect_called("sum")
            expect_not_called("len")
            expect_printed("6")
            expect_object("missing")
            """
        let result = try await run("total = sum([1, 2, 3])\nprint(total)", checks: checks)
        #expect(result.checks.map(\.passed) == [true, true, true, true, false])
        #expect(result.checks.last?.message?.contains("total = ...") == false)
        #expect(result.checks.last?.message?.contains("missing = ...") == true)
        #expect(!result.passed)
    }

    @Test func aBrokenCheckIsInternal() async throws {
        let result = try await run("x = 1", checks: "expect_object('x', 1)\n1 / 0")
        #expect(result.checks.count == 2)
        #expect(result.checks[1].internal)
        #expect(result.hasInternalCheckErrors)
    }

    @MainActor @Test func bossStepsGroupChecks() async throws {
        let result = try await run("a = 1", checks: "step(1)\nexpect_object('a', 1)\nstep(2)\nexpect_object('b')")
        #expect(result.checks.map(\.step) == [1, 2])
        #expect(LevelSession.stepsPassed(result.checks, stepCount: 2) == 1)
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsAnEndlessLoop() async throws {
        let result = try await run("while True:\n    pass", timeLimit: 1)
        #expect(result.status == .timeout)
        #expect(result.errorEntry?.text.contains("more than 1 second") == true)
    }

    @Test(.timeLimit(.minutes(1)))
    func stopsCodeThatCatchesEverything() async throws {
        let result = try await run("import time\ntry:\n    time.sleep(30)\nexcept Exception:\n    pass", timeLimit: 1)
        #expect(result.status == .timeout)
    }

    @Test func exitIsSwitchedOff() async throws {
        let result = try await run("quit()\nx = 1")
        #expect(result.status == .error)
        #expect(result.errorEntry?.text.contains("switched off") == true)
    }

    @Test func setupSeedAndDataFiles() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "ss-py-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        try "score\n3\n5\n".write(to: folder.appending(path: "scores.csv"), atomically: true, encoding: .utf8)
        try "x = 1".write(to: folder.appending(path: "solution.py"), atomically: true, encoding: .utf8)
        let code = "import os\nd = pd.read_csv(\"scores.csv\")\nm = d[\"score\"].mean()\nr = np.random.rand()\nhas_py = os.path.exists(\"solution.py\")"
        let checks = "expect_object('m', 4.0)\nexpect_object('has_py', False)"
        let setup = "import numpy as np\nimport pandas as pd"
        let a = try await run(code, checks: checks + "\nexpect_true(True)", seed: 7, setup: setup, data: folder)
        let b = try await run(code + "\nprint(r)", checks: nil, seed: 7, setup: setup, data: folder)
        #expect(a.passed, "\(a.console) \(a.checks)")
        let printed = try #require(texts(b, .output).last.flatMap(Double.init))
        let again = try await run(code + "\nprint(r)", seed: 7, setup: setup, data: folder)
        #expect(texts(again, .output).last.flatMap(Double.init) == printed, "the seed makes numpy repeatable")
    }

    @Test func missingPythonIsAClearError() async throws {
        let engine = try REngine(pythonPath: "/nowhere/python3")
        #expect(engine.pythonURL == nil)
        await #expect(throws: REngineError.self) {
            _ = try await engine.run(RJob(code: "1", language: .python))
        }
        let r = try await engine.run(RJob(code: "1 + 1"))
        #expect(r.status == .ok, "R still works without Python")
    }
}

// MARK: - Content, highlighting and explanations (no Python needed)

@Suite("Python Wormhole content")
struct PythonContentTests {
    @Test func theSectorIsPythonWithTwins() throws {
        let library = try ContentLibrary.loadBundled()
        let sector = try #require(library.sectors.first { $0.id == 12 })
        #expect(sector.isOptional)
        #expect(sector.levels.count == 14)
        #expect(sector.levels.allSatisfy { $0.language == .python })
        #expect(library.levels.filter { $0.language == .python }.count == 14, "only the wormhole is Python")
        let code = sector.levels.filter { !$0.type.isQuiz }
        #expect(code.allSatisfy { $0.checkCode.contains("expect_") }, "check.py is loaded")
        let twins = code.filter { $0.twinCode != nil }
        #expect(twins.count >= 10)
        #expect(twins.allSatisfy { $0.lesson.contains("{{twin}}") })
        #expect(sector.levels.contains { $0.type == .boss && $0.steps?.count == 6 })
        let job = try #require(twins.first?.twinJob())
        #expect(job.language == .r)
        #expect(sector.levels.first { $0.setupCode != nil }?.setupCode?.contains("import pandas as pd") == true)
    }

    @Test func pythonReviewCardsAreMarkedPython() throws {
        let cards = try ContentLibrary.loadBundled().reviewCards.filter { $0.levelID.hasPrefix("python-wormhole.") }
        #expect(cards.count > 20)
        #expect(cards.filter { $0.kind == .fill }.allSatisfy { $0.language == .python })
        #expect(cards.filter { $0.kind == .predict }.allSatisfy { $0.language == .python }, "quiz cards take the level's language")
    }

    @Test func aPythonDocumentIsRejected() throws {
        let root = FileManager.default.temporaryDirectory.appending(path: "ss-pydoc-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let level = root.appending(path: "sector-00-x/01-y")
        try FileManager.default.createDirectory(at: level, withIntermediateDirectories: true)
        try #"{"id": 0, "name": "X", "r_skills": "", "stats_concepts": "", "hue": 0, "map_position": {"x": 0, "y": 0}, "planet_size": 40}"#
            .write(to: root.appending(path: "sector-00-x/sector.json"), atomically: true, encoding: .utf8)
        try #"{"id": "y", "title": "Y", "type": "code", "xp": 1, "language": "python", "document": "r.qmd"}"#
            .write(to: level.appending(path: "level.json"), atomically: true, encoding: .utf8)
        #expect(throws: ContentError.self) { _ = try ContentLibrary.load(from: root) }
    }

    @Test func highlightsPython() {
        let code = "import pandas as pd\n# note\nx = f\"{a:.2f}\" if a == 1 else '''doc'''\nlog.groupby(\"sex\")\nok = True"
        let tokens = PythonSyntax.tokens(in: code)
        let ns = code as NSString
        func text(_ kind: RSyntax.Kind) -> [String] { tokens.filter { $0.kind == kind }.map { ns.substring(with: $0.range) } }
        #expect(text(.keyword) == ["import", "as", "if", "else"])
        #expect(text(.comment) == ["# note"])
        #expect(text(.string) == ["f\"{a:.2f}\"", "'''doc'''", "\"sex\""])
        #expect(text(.assignment) == ["=", "="], "== isn't an assignment")
        #expect(text(.function) == ["groupby"])
        #expect(text(.constant) == ["True"])
        #expect(text(.number) == ["1"])
    }

    @Test func explainsCommonPythonErrors() {
        func explain(_ text: String) -> String? {
            ErrorExplainer.explain(ConsoleEntry(kind: .error, text: text), language: .python)
        }
        #expect(explain("NameError: name 'pd' is not defined")?.contains("import pandas as pd") == true)
        #expect(explain("NameError: name 'totl' is not defined")?.contains("`totl`") == true)
        #expect(explain("KeyError: 'Age'")?.contains("'Age'") == true)
        #expect(explain("IndexError: list index out of range")?.contains("from 0") == true)
        #expect(explain("TypeError: 'method' object is not subscriptable")?.contains("()") == true)
        #expect(explain("Python couldn't read your code: IndentationError: expected an indented block")?
            .contains("indent") == true)
        #expect(ErrorExplainer.explain(ConsoleEntry(kind: .error, text: "object 'x' not found")) != nil, "R still explained")
    }

    @Test func consoleTextByLanguage() {
        let input = ConsoleEntry(kind: .input, text: "for v in x:\n    v")
        #expect(input.consoleText(language: .python) == ">>> for v in x:\n...     v")
        #expect(input.consoleText == "> for v in x:\n+     v")
        let error = ConsoleEntry(kind: .error, text: "KeyError: 'a'", call: "line 3")
        #expect(error.consoleText(language: .python) == "Error on line 3: KeyError: 'a'")
    }

    @Test func wormholePilotBadge() throws {
        let library = try ContentLibrary.loadBundled()
        let sectors = library.sectors
        let python = try #require(library.levels.first { $0.language == .python && $0.type == .code })
        let quiz = try #require(library.levels.first { $0.language == .python && $0.type.isQuiz })
        var progress = PilotProgress()
        let record = LevelProgress(bestStars: 1, firstCleared: .now, lastCleared: .now, clears: 1, clearedWithoutHints: false)
        let fuel = FuelState.compute(practiceDays: [], today: .now)
        progress.levels[quiz.id] = record
        #expect(!Badge.earned(by: progress, sectors: sectors, streak: fuel, clearedLevel: nil, clearedCode: nil).contains("wormhole-pilot"))
        progress.levels[python.id] = record
        let earned = Badge.earned(by: progress, sectors: sectors, streak: fuel, clearedLevel: python,
                                  clearedCode: "stats.levene(a, b, center=\"mean\")")
        #expect(earned.contains("wormhole-pilot"))
        #expect(earned.contains("assumption-checker"))
    }
}
