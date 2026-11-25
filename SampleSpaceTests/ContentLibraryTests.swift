import Foundation
import Testing
@testable import SampleSpace

@Suite("Content library")
struct ContentLibraryTests {
    @Test func loadsTheBundledStarMap() throws {
        let library = try ContentLibrary.loadBundled()
        #expect(library.sectors.map(\.id) == Array(0...12))
        #expect(library.sectors.first?.name == "Launch Pad")
        #expect(library.sectors.first?.status == .current)
        #expect(library.sectors.dropFirst().allSatisfy { $0.status == .locked })
        #expect(library.sectors.last?.isOptional == true)
    }

    @Test func launchPadHasItsLevelsInOrder() throws {
        let launchPad = try #require(try ContentLibrary.loadBundled().sectors.first)
        #expect(launchPad.levels.map(\.id) == [
            "launch-pad.calculator-console",
            "launch-pad.reading-the-console",
            "launch-pad.storing-cargo",
            "launch-pad.function-thrusters",
            "launch-pad.ships-manual",
            "launch-pad.launch-checklist",
        ])
    }

    @Test func firstThreeSectorsAreCharted() throws {
        let sectors = try ContentLibrary.loadBundled().sectors
        #expect(sectors.prefix(3).map(\.levels.count) == [6, 11, 12])
        for level in sectors.prefix(3).flatMap(\.levels) {
            #expect(level.type.isPlayable && level.type != .lab, "\(level.id)")
            #expect(level.xp > 0, "\(level.id)")
            #expect(level.hints.count >= 3, "\(level.id)")
            #expect(level.lesson.hasPrefix("# \(level.title)\n"), "\(level.id): lesson should start with its title")
            #expect(level.type.isQuiz ? !(level.quiz ?? []).isEmpty : !level.checkCode.isEmpty, "\(level.id)")
        }
    }

    @Test func sectorsThreeToFiveAreCharted() throws {
        let sectors = try ContentLibrary.loadBundled().sectors
        #expect(sectors[3...5].map(\.levels.count) == [10, 8, 8])
        for sector in sectors[3...5] {
            #expect(sector.levels.contains { $0.type != .code }, "\(sector.name) has only code levels")
            for level in sector.levels {
                #expect(level.id.hasPrefix(sector.levels[0].id.split(separator: ".")[0] + "."), "\(level.id)")
                #expect(level.hints.count >= 3, "\(level.id)")
                #expect(level.lesson.hasPrefix("# \(level.title)\n"), "\(level.id): lesson should start with its title")
            }
        }
    }

    @Test func everySectorHasItsStory() throws {
        for sector in try ContentLibrary.loadBundled().sectors {
            #expect(!sector.briefing.isEmpty, "\(sector.name) has no arrival briefing")
            #expect(sector.log.map { !$0.title.isEmpty && !$0.text.isEmpty } == true,
                    "\(sector.name) has no Crew Log entry")
        }
    }

    /// Levels keep their own copy of data-bank files; each copy must match the master.
    @Test func dataBankCopiesMatchTheMaster() throws {
        let content = try #require(Bundle.main.url(forResource: "Content", withExtension: nil))
        let bank = content.appending(path: "data-bank")
        let fm = FileManager.default
        let masters = try fm.contentsOfDirectory(atPath: bank.path).filter { !$0.hasSuffix(".md") }
        #expect(masters.contains("astronauts.csv"))
        var copies = 0
        for level in try ContentLibrary.loadBundled().levels {
            for name in masters {
                let copy = level.folder.appending(path: name)
                guard fm.fileExists(atPath: copy.path) else { continue }
                copies += 1
                #expect(try Data(contentsOf: copy) == Data(contentsOf: bank.appending(path: name)),
                        "\(level.id)/\(name) differs from Content/data-bank/\(name)")
            }
        }
        #expect(copies > 0)
    }

    /// The same promise `scripts/validate_content.sh` makes, but through the app's own engine
    /// and `Level.job(code:)`, so the Swift wiring (seed, setup, data folder) is covered too.
    @Test(.timeLimit(.minutes(5)))
    func everySolutionPassesThroughTheEngine() async throws {
        let engine = try REngine()
        for level in try ContentLibrary.loadBundled().levels where !level.type.isQuiz {
            let solved = try await engine.run(level.job(code: level.solutionCode))
            #expect(solved.passed, "\(level.id): \(solved.checks.filter { !$0.passed }.map(\.label))")
            #expect(!solved.hasInternalCheckErrors, "\(level.id)")

            let starter = try await engine.run(level.job(code: level.starterCode))
            #expect(!starter.passed, "\(level.id): starter code shouldn't pass")
        }
    }

    /// Predict questions: what the app's console shows must be the right choice, and only that one.
    @Test(.timeLimit(.minutes(1)))
    func predictionsMatchWhatTheConsoleShows() async throws {
        let engine = try REngine()
        let levels = try ContentLibrary.loadBundled().levels.filter { $0.type == .predict }
        #expect(!levels.isEmpty)
        func squash(_ s: String) -> String {
            s.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        }
        for level in levels {
            for (index, question) in (level.quiz ?? []).enumerated() where question.matchOutput != false && question.runsCode {
                let code = try #require(question.code, "\(level.id) q\(index + 1) has no code")
                let console = try await engine.run(level.job(code: code, check: false)).console
                let shown = squash(console.filter { $0.kind != .input && $0.kind != .message }
                    .map { $0.consoleText(language: level.language) }.joined(separator: "\n"))
                let matching = question.choices.indices.filter { squash(question.choices[$0]) == shown }
                #expect(matching == [question.answer], "\(level.id) q\(index + 1): R shows \(shown)")
            }
        }
    }

    @Test func quizLevelsNeedNoRFiles() throws {
        let folder = try makeContent { root in
            try write(root, "sector-00-test/sector.json", sectorJSON(id: 0))
            try write(root, "sector-00-test/01-q/level.json", #"""
                {"id": "q", "title": "Q", "type": "briefing", "xp": 10,
                 "quiz": [{"prompt": "?", "choices": ["a", "b"], "answer": 1}]}
                """#)
            try write(root, "sector-00-test/01-q/lesson.md", "# Q\n")
        }
        let level = try #require(try ContentLibrary.load(from: folder).levels.first)
        #expect(level.type.isQuiz)
        #expect(level.par == 1, "par defaults to one answer per question")
        #expect(level.checkCode.isEmpty)
    }

    @Test func rejectsAQuizWithABadAnswer() throws {
        let folder = try makeContent { root in
            try write(root, "sector-00-test/sector.json", sectorJSON(id: 0))
            try write(root, "sector-00-test/01-q/level.json", #"""
                {"id": "q", "title": "Q", "type": "predict", "xp": 10,
                 "quiz": [{"prompt": "?", "code": "1", "choices": ["a", "b"], "answer": 2}]}
                """#)
            try write(root, "sector-00-test/01-q/lesson.md", "# Q\n")
        }
        #expect(throws: ContentError.self) { try ContentLibrary.load(from: folder) }
    }

    @Test func spssLevelsLoadTheirPanel() throws {
        let level = try #require(try ContentLibrary.loadBundled().level(id: "data-frame-docks.frequency-translator"))
        let spss = try #require(level.spss)
        #expect(spss.menu.first == "Analyze")
        #expect(spss.output.count == 3)
        for table in spss.output {
            #expect(table.rows.allSatisfy { $0.count == table.columns.count }, "\(table.title)")
        }
        #expect(level.lesson.contains("{{spss}}"))
        #expect(MarkdownBlock.parse(level.lesson).contains(.placeholder("spss")))
    }

    @Test func levelDataFilesAreCopiedIntoTheWorkingDirectory() async throws {
        let folder = try makeContent { root in
            try write(root, "sector-00-test/sector.json", sectorJSON(id: 0))
            try writeLevel(root, "sector-00-test/01-data", id: "test.data")
            try write(root, "sector-00-test/01-data/scores.csv", "score\n4\n6\n")
        }
        let level = try #require(try ContentLibrary.load(from: folder).levels.first)
        let result = try await REngine().run(level.job(code: "d <- read.csv(\"scores.csv\")\nmean(d$score)",
                                                       check: false))
        #expect(result.status == .ok)
        #expect(result.console.last?.text == "[1] 5")
    }

    @Test func rejectsDuplicateLevelIDs() throws {
        let folder = try makeContent { root in
            try write(root, "sector-00-test/sector.json", sectorJSON(id: 0))
            try writeLevel(root, "sector-00-test/01-a", id: "same")
            try writeLevel(root, "sector-00-test/02-b", id: "same")
        }
        #expect(throws: ContentError.duplicateLevelID("same")) {
            try ContentLibrary.load(from: folder)
        }
    }

    @Test func reportsMissingLevelFiles() throws {
        let folder = try makeContent { root in
            try write(root, "sector-00-test/sector.json", sectorJSON(id: 0))
            try writeLevel(root, "sector-00-test/01-a", id: "a")
            try FileManager.default.removeItem(at: root.appending(path: "sector-00-test/01-a/check.R"))
        }
        #expect {
            try ContentLibrary.load(from: folder)
        } throws: { error in
            guard case ContentError.missingFile(let path) = error else { return false }
            return path.hasSuffix("check.R")
        }
    }

    // MARK: - Helpers

    private func makeContent(_ build: (URL) throws -> Void) throws -> URL {
        let root = FileManager.default.temporaryDirectory.appending(path: "ContentTest-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try build(root)
        return root
    }

    private func write(_ root: URL, _ path: String, _ text: String) throws {
        let url = root.appending(path: path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try text.write(to: url, atomically: true, encoding: .utf8)
    }

    private func writeLevel(_ root: URL, _ path: String, id: String) throws {
        try write(root, "\(path)/level.json", #"{"id": "\#(id)", "title": "T", "type": "code", "xp": 10}"#)
        for file in ["lesson.md", "starter.R", "solution.R", "check.R"] {
            try write(root, "\(path)/\(file)", "# \(file)\n")
        }
    }

    private func sectorJSON(id: Int) -> String {
        #"{"id": \#(id), "name": "Test", "r_skills": "", "stats_concepts": "", "hue": 0.5, "map_position": {"x": 0.5, "y": 0.5}, "planet_size": 60}"#
    }
}
