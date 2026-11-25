import Foundation
import Testing
@testable import SampleSpace

/// These tests run the real system R through `REngine`, so they need Rscript installed.
@Suite("R engine", .timeLimit(.minutes(1)))
struct REngineTests {
    let engine: REngine

    init() throws {
        engine = try REngine()
    }

    private func run(_ code: String, checks: String? = nil, timeLimit: Double = 10,
                     seed: Int? = nil, setup: String? = nil) async throws -> RRunResult {
        try await engine.run(RJob(code: code, checks: checks, setup: setup, seed: seed, timeLimit: timeLimit))
    }

    private func texts(_ result: RRunResult, _ kind: ConsoleEntry.Kind) -> [String] {
        result.console.filter { $0.kind == kind }.map(\.text)
    }

    // MARK: Running code

    @Test func printsVisibleValuesLikeTheConsole() async throws {
        let result = try await run("x <- c(2, 4, 6)\nmean(x)\ncat(\"done\\n\")")
        #expect(result.status == .ok)
        #expect(result.passed)
        #expect(texts(result, .input) == ["x <- c(2, 4, 6)", "mean(x)", "cat(\"done\\n\")"])
        #expect(texts(result, .output) == ["[1] 4", "done"])
    }

    @Test func keepsMultiLineInputTogether() async throws {
        let result = try await run("f <- function(a) {\n  a * 2\n}\nf(21)")
        #expect(texts(result, .input) == ["f <- function(a) {\n  a * 2\n}", "f(21)"])
        #expect(texts(result, .output) == ["[1] 42"])
        #expect(result.console[0].consoleText == "> f <- function(a) {\n+   a * 2\n+ }")
    }

    @Test func stopsAtTheFirstError() async throws {
        let result = try await run("a <- 1\nstop(\"boom\")\nb <- 2")
        #expect(result.status == .error)
        #expect(!result.passed)
        #expect(result.errorEntry?.text == "boom")
        #expect(result.errorEntry?.call == nil, "the harness's own eval() call should be hidden")
        #expect(!texts(result, .input).contains("b <- 2"))
    }

    @Test func reportsTheCallAnErrorCameFrom() async throws {
        let result = try await run("f <- function(x) log(x)\nf(\"a\")")
        #expect(result.status == .error)
        #expect(result.errorEntry?.call == "log(x)")
        #expect(result.errorEntry?.consoleText.hasPrefix("Error in log(x):") == true)
    }

    @Test func capturesWarningsAndMessagesWithoutFailing() async throws {
        let result = try await run("as.numeric(\"a\")\nmessage(\"hello\")\nlog(-1)")
        #expect(result.status == .ok)
        #expect(texts(result, .warning) == ["NAs introduced by coercion", "NaNs produced"])
        #expect(texts(result, .message) == ["hello"])
        #expect(result.console.first(where: { $0.kind == .warning && $0.call != nil })?.call == "log(-1)")
    }

    @Test func reportsSyntaxErrors() async throws {
        let result = try await run("x <- (1 +\ny y")
        #expect(result.status == .parseError)
        #expect(result.errorEntry?.text.contains("unexpected symbol") == true)
        #expect(texts(result, .input).isEmpty)
    }

    @Test func eachRunStartsFresh() async throws {
        _ = try await run("leftover <- 99")
        let result = try await run("exists(\"leftover\")")
        #expect(texts(result, .output) == ["[1] FALSE"])
    }

    @Test func seedAndSetupMakeRunsRepeatable() async throws {
        let code = "round(rnorm(3), 4)\nnrow(dat)"
        let setup = "dat <- data.frame(x = 1:5)"
        let first = try await run(code, seed: 42, setup: setup)
        let second = try await run(code, seed: 42, setup: setup)
        #expect(first.status == .ok)
        #expect(texts(first, .output) == texts(second, .output))
        #expect(texts(first, .output).last == "[1] 5")
    }

    @Test func quitIsSwitchedOff() async throws {
        let result = try await run("q()")
        #expect(result.status == .error)
        #expect(result.errorEntry?.text.contains("switched off") == true)
    }

    // MARK: Time limits

    @Test func stopsAnInfiniteLoop() async throws {
        let start = Date()
        let result = try await run("i <- 0\nwhile (TRUE) i <- i + 1", timeLimit: 1)
        #expect(result.status == .timeout)
        #expect(result.errorEntry?.text.contains("more than 1 second,") == true)
        #expect(Date().timeIntervalSince(start) < 4)
    }

    @Test func killsCodeThatRCannotInterrupt() async throws {
        // Clearing the time limit means only the engine's watchdog can stop this.
        let start = Date()
        let result = try await run("setTimeLimit()\nSys.sleep(60)", timeLimit: 1)
        #expect(result.status == .timeout)
        #expect(result.errorEntry?.text.contains("Sample Space ended it") == true)
        #expect(Date().timeIntervalSince(start) < 1 + REngine.killGrace + 3)
    }

    // MARK: Plots

    @Test func capturesPlotsAsPNG() async throws {
        let result = try await run("plot(1:10)\nhist(c(1, 2, 2, 3))")
        #expect(result.status == .ok)
        #expect(result.plots.count == 2)
        for plot in result.plots {
            #expect(plot.starts(with: [0x89, 0x50, 0x4E, 0x47]), "should be a PNG")
        }
    }

    @Test func noPlotMeansNoImages() async throws {
        let result = try await run("1 + 1")
        #expect(result.plots.isEmpty)
    }

    // MARK: Checks

    @Test func passingChecks() async throws {
        let result = try await run(
            "scores <- c(3, 5, 7)\nm <- mean(scores)\nprint(m)",
            checks: """
            expect_object("scores", c(3, 5, 7))
            expect_object("m", 5)
            expect_class("scores", "numeric")
            expect_called("mean")
            expect_not_called("sum")
            expect_output("[1] 5", fixed = TRUE)
            expect_true(m > 4, label = "`m` is above 4")
            expect_no_error()
            """)
        #expect(result.checks.count == 8)
        #expect(result.checks.allSatisfy { $0.passed })
        #expect(result.passed)
        #expect(result.checks.last?.label == "Runs without an error")
    }

    @Test func failingChecksExplainWhy() async throws {
        let result = try await run(
            "scores <- c(\"3\", \"5\")",
            checks: """
            expect_object("Scores")
            expect_object("scores", c(3, 5))
            expect_called("mean", message = "Use mean() to average the scores.")
            """)
        #expect(!result.passed)
        #expect(result.status == .ok)
        #expect(result.checks.map(\.passed) == [false, false, false])
        #expect(result.checks[0].message?.contains("no object called `Scores`") == true)
        #expect(result.checks[1].message == "`scores` is a character, but a double was expected.")
        #expect(result.checks[2].message == "Use mean() to average the scores.")
    }

    @Test func checksSeeNamespacedCalls() async throws {
        let result = try await run("x <- stats::median(c(1, 9, 3))",
                                   checks: "expect_called(\"median\")\nexpect_called(\"stats::median\")")
        #expect(result.checks.allSatisfy { $0.passed })
    }

    @Test func plotCheck() async throws {
        let result = try await run("barplot(c(a = 1, b = 2))", checks: "expect_plot()")
        #expect(result.passed)
    }

    @Test func checkThatCannotRunIsFlagged() async throws {
        let result = try await run("x <- 1", checks: "expect_true(y > 0)")
        #expect(!result.passed)
        #expect(result.hasInternalCheckErrors)
        #expect(result.checks.first?.message == "object 'y' not found")
    }

    @Test func errorsFailTheRunEvenWhenChecksPass() async throws {
        let result = try await run("x <- 1\nstop(\"late\")", checks: "expect_object(\"x\", 1)")
        #expect(result.checks.first?.passed == true)
        #expect(!result.passed)
    }
}
