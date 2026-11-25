import Foundation
import Testing
@testable import SampleSpace

@Suite("Star scoring")
struct StarScoreTests {
    private func score(passed: Bool = true, hints: Int = 0, solution: Bool = false,
                       checks: Int = 1, par: Int = 2) -> StarScore {
        StarScore(passed: passed, hintsUsed: hints, solutionShown: solution, checkAttempts: checks, par: par)
    }

    @Test func threeStarsForNoHintsWithinPar() {
        #expect(score(checks: 1).stars == 3)
        #expect(score(checks: 2).stars == 3)
    }

    @Test func eachMissedCriterionCostsOneStar() {
        #expect(score(hints: 1).stars == 2)
        #expect(score(checks: 3).stars == 2)
        #expect(score(hints: 2, checks: 5).stars == 1)
    }

    @Test func solutionCapsAtOneStar() {
        #expect(score(hints: 3, solution: true, checks: 1).stars == 1)
        #expect(!score(solution: true).withinPar)
    }

    @Test func notPassedIsZero() {
        #expect(score(passed: false).stars == 0)
    }

    @Test func criteriaDescribeTheAttempt() {
        let lines = score(hints: 1, checks: 3).criteria
        #expect(lines.map(\.met) == [true, false, false])
        #expect(lines[1].text == "1 hint used")
        #expect(lines[2].text == "Solved in 3 checks (par 2)")
    }
}

@Suite("R syntax colouring")
struct RSyntaxTests {
    private func kinds(_ code: String) -> [(RSyntax.Kind, String)] {
        let ns = code as NSString
        return RSyntax.tokens(in: code).map { ($0.kind, ns.substring(with: $0.range)) }
    }

    @Test func colorsTheCommonPieces() {
        let tokens = kinds("x <- mean(c(1, 2.5e3, 3L)) # avg\nif (TRUE) print(\"hi\")")
        #expect(tokens.map(\.0) == [.assignment, .function, .function, .number, .number, .number,
                                     .comment, .keyword, .constant, .function, .string])
        #expect(tokens.map(\.1) == ["<-", "mean", "c", "1", "2.5e3", "3L", "# avg", "if", "TRUE",
                                     "print", "\"hi\""])
    }

    @Test func hashInsideAStringIsNotAComment() {
        let tokens = kinds("s <- \"a # b\" # real")
        #expect(tokens.map(\.1) == ["<-", "\"a # b\"", "# real"])
    }

    @Test func handlesOperatorsAndNamespaces() {
        let tokens = kinds("df |> dplyr::filter(x %in% 1:3, y ~ z)")
        #expect(tokens.map(\.1) == ["|>", "filter", "%in%", "1", "3", "~"])
    }

    @Test func unfinishedStringRunsToTheEnd() {
        let tokens = kinds("x <- \"abc")
        #expect(tokens.last?.0 == .string)
        #expect(tokens.last?.1 == "\"abc")
    }

    @Test func rangesAreUTF16() {
        let code = "é <- \"ü\" # ✓"
        let ns = code as NSString
        for token in RSyntax.tokens(in: code) {
            #expect(NSMaxRange(token.range) <= ns.length)
        }
        #expect(kinds(code).map(\.1) == ["<-", "\"ü\"", "# ✓"])
    }
}

@Suite("Lesson Markdown")
struct MarkdownBlockTests {
    @Test func splitsBlocks() {
        let blocks = MarkdownBlock.parse("""
        # Title

        Some **bold**
        text.

        ```r
        x <- 1
        x
        ```

        | A | B |
        |---|---|
        | `\\|>` | 2 |

        > **Coming from SPSS?** A note
        > over two lines.

        - one
        - two
          continued

        1. first
        2. second
        """)
        #expect(blocks == [
            .heading(level: 1, text: "Title"),
            .paragraph("Some **bold** text."),
            .code("x <- 1\nx", language: "r"),
            .table(header: ["A", "B"], rows: [["`|>`", "2"]]),
            .quote("**Coming from SPSS?** A note over two lines."),
            .bullets(["one", "two continued"]),
            .numbered(["first", "second"]),
        ])
    }

    @Test func everyBundledLessonParses() throws {
        for level in try ContentLibrary.loadBundled().levels {
            let blocks = MarkdownBlock.parse(level.lesson)
            #expect(blocks.first == .heading(level: 1, text: level.title), "\(level.id)")
        }
    }
}

@Suite("Error explanations")
struct ErrorExplainerTests {
    @Test func explainsCommonRuntimeErrors() {
        #expect(ErrorExplainer.explain(message: "object 'scroes' not found")?.contains("`scroes`") == true)
        #expect(ErrorExplainer.explain(message: "could not find function \"mena\"")?.contains("`mena()`") == true)
        #expect(ErrorExplainer.explain(message: "non-numeric argument to binary operator") != nil)
        #expect(ErrorExplainer.explain(message: "unused argument (digit = 2)")?.contains("args()") == true)
    }

    @Test func explainsParseErrorsWithTheLine() {
        let symbol = ErrorExplainer.explain(message: "R couldn't read your code: line 3:3: unexpected symbol\n3: x y\n      ^")
        #expect(symbol?.contains("on line 3") == true)
        let curly = ErrorExplainer.explain(message: "R couldn't read your code: line 1:6: unexpected input")
        #expect(curly?.contains("Curly quotes") == true)
        let equals = ErrorExplainer.explain(message: "R couldn't read your code: line 1:7: unexpected '='")
        #expect(equals?.contains("`==`") == true)
        let open = ErrorExplainer.explain(message: "R couldn't read your code: line 2:0: unexpected end of input")
        #expect(open?.contains("never closed") == true)
    }

    @Test func leavesUnknownErrorsAlone() {
        #expect(ErrorExplainer.explain(message: "something unusual") == nil)
        #expect(ErrorExplainer.explain(ConsoleEntry(kind: .warning, text: "object 'x' not found")) == nil)
    }
}

/// Plays a real level through `LevelSession`, running real R.
@Suite("Level session", .timeLimit(.minutes(1)))
@MainActor
struct LevelSessionTests {
    private func makeSession(_ id: String) throws -> (GameModel, LevelSession) {
        let model = GameModel(store: .temporary())
        let level = try #require(model.level(id: id))
        return (model, model.session(for: level))
    }

    @Test func runDoesNotCountTowardParButCheckDoes() async throws {
        let (_, session) = try makeSession("launch-pad.calculator-console")
        session.code = "23 + 17"
        await session.perform(check: false)
        #expect(session.runCount == 1)
        #expect(session.checkAttempts == 0)
        #expect(session.console.contains { $0.kind == .output && $0.text == "[1] 40" })
        #expect(session.checks.isEmpty)

        await session.perform(check: true)
        #expect(session.checkAttempts == 1)
        #expect(session.outputTab == .checks)
        #expect(session.checks.contains { !$0.passed })
        #expect(session.completion == nil)
    }

    @Test func solvingRecordsStarsAndNextLevel() async throws {
        let (model, session) = try makeSession("launch-pad.calculator-console")
        session.showHint()
        session.code = session.level.solutionCode
        await session.perform(check: true)

        let completion = try #require(session.completion)
        #expect(completion.score.stars == 2)
        #expect(completion.outcome.firstClear)
        #expect(completion.outcome.xpGained == session.level.xp + XP.perBonusStar)
        #expect(completion.outcome.newBadges.map(\.id) == ["lift-off"])
        #expect(completion.outcome.opened == ["Storing Cargo"])
        #expect(model.bestStars("launch-pad.calculator-console") == 2)
        #expect(model.player.xp == session.level.xp + XP.perBonusStar)
        #expect(model.nextLevel(after: session.level)?.id == "launch-pad.storing-cargo")

        // A replay that does better raises the best score and earns only the extra star's XP.
        session.replay()
        #expect(session.code == session.level.starterCode)
        #expect(session.hintsShown == 0)
        session.code = session.level.solutionCode
        await session.perform(check: true)
        #expect(session.completion?.score.stars == 3)
        #expect(session.completion?.outcome.firstClear == false)
        #expect(session.completion?.outcome.xpGained == XP.perBonusStar)
        #expect(model.bestStars("launch-pad.calculator-console") == 3)
        #expect(model.player.xp == session.level.xp + 2 * XP.perBonusStar)
    }

    @Test func resetKeepsTheAttemptCounters() throws {
        let (_, session) = try makeSession("launch-pad.storing-cargo")
        session.code = "x <- 1"
        session.showHint()
        session.reset()
        #expect(session.code == session.level.starterCode)
        #expect(session.hintsShown == 1)
    }

    @Test func lockedSectorsAreNotPlayable() throws {
        let model = GameModel(store: .temporary())
        #expect(model.sectors.dropFirst().allSatisfy { $0.levels.allSatisfy { !model.isPlayable($0) } })
        let last = try #require(model.sectors.first?.levels.last)
        #expect(model.nextLevel(after: last) == nil)
    }
}
