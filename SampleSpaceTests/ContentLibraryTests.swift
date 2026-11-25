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
            "launch-pad.storing-cargo",
            "launch-pad.function-thrusters",
            "launch-pad.ships-manual",
            "launch-pad.launch-checklist",
        ])
    }

    @Test func firstThreeSectorsAreCharted() throws {
        let sectors = try ContentLibrary.loadBundled().sectors
        #expect(sectors.prefix(3).map(\.levels.count) == [5, 10, 9])
        for level in sectors.prefix(3).flatMap(\.levels) {
            #expect(level.type == .code, "\(level.id)")
            #expect(level.xp > 0, "\(level.id)")
            #expect(level.hints.count >= 3, "\(level.id)")
            #expect(level.lesson.hasPrefix("# \(level.title)\n"), "\(level.id): lesson should start with its title")
            #expect(!level.checkCode.isEmpty, "\(level.id)")
        }
    }

    /// The same promise `scripts/validate_content.sh` makes, but through the app's own engine
    /// and `Level.job(code:)`, so the Swift wiring (seed, setup, data folder) is covered too.
    @Test(.timeLimit(.minutes(2)))
    func everySolutionPassesThroughTheEngine() async throws {
        let engine = try REngine()
        for level in try ContentLibrary.loadBundled().levels {
            let solved = try await engine.run(level.job(code: level.solutionCode))
            #expect(solved.passed, "\(level.id): \(solved.checks.filter { !$0.passed }.map(\.label))")
            #expect(!solved.hasInternalCheckErrors, "\(level.id)")

            let starter = try await engine.run(level.job(code: level.starterCode))
            #expect(!starter.passed, "\(level.id): starter code shouldn't pass")
        }
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
