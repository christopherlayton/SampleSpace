import Foundation
import Testing
@testable import SampleSpace

@Suite("F and chi-square maths")
struct FChiSquareTests {
    private func close(_ a: Double, _ b: Double, _ tol: Double = 1e-7) -> Bool { abs(a - b) < tol }

    @Test func fMatchesR() {
        #expect(close(Stats.fCDF(3.6, df1: 2, df2: 27), 0.9588795002))            // pf(3.6, 2, 27)
        #expect(close(Stats.fUpper(4.334, df1: 2, df2: 57), 0.01769499261))      // pf(4.334, 2, 57, lower.tail = FALSE)
        #expect(close(Stats.fDensity(1.3, df1: 3, df2: 20), 0.3159334329))       // df(1.3, 3, 20)
        #expect(close(Stats.fQuantile(0.999, df1: 2, df2: 27), 9.019357252, 1e-6))
        #expect(close(Stats.fQuantile(0.95, df1: 3, df2: 40), 2.838745398, 1e-6))
        let tiny = Stats.fUpper(40, df1: 5, df2: 558)                             // 3.710486291e-35
        #expect(abs(tiny / 3.710486291e-35 - 1) < 1e-5, "tiny upper tails keep their precision")
    }

    @Test func chiSquareMatchesR() {
        #expect(close(Stats.chiSquareUpper(2.564, df: 1), 0.1093216665))         // pchisq(2.564, 1, lower.tail = FALSE)
        #expect(close(Stats.chiSquareUpper(30, df: 4), 4.894437128e-06, 1e-12))
        #expect(close(Stats.chiSquareUpper(0.3, df: 5), 0.9976430863))
        #expect(Stats.chiSquareUpper(0, df: 3) == 1)
    }
}

@Suite("ANOVA, p-hacking and chi-square labs")
@MainActor
struct GroupLabTests {
    private func level(_ id: String) throws -> Level {
        try #require(try ContentLibrary.loadBundled().level(id: id))
    }

    @Test func readingsMatchTheDeclaredNames() {
        #expect(Set(AnovaSplitter(seed: 1).readings.keys) == Set(LabKind.anovaSplitter.readings.keys))
        #expect(Set(PHackingGarden(seed: 1).readings.keys) == Set(LabKind.pHackingGarden.readings.keys))
        #expect(Set(ChiSquareGrid().readings.keys) == Set(LabKind.chiSquareGrid.readings.keys))
    }

    // MARK: ANOVA Splitter

    @Test func splitterNumbersAreExact() {
        let lab = AnovaSplitter(startN: 10, startSD: 10, startSpacing: 6, seed: 4)
        // Means 44, 50, 56: SS between = 10 × (36 + 0 + 36) = 720; SS within = 27 × 10² = 2700.
        #expect(abs(lab.ssBetween - 720) < 1e-9)
        #expect(abs(lab.ssWithin - 2700) < 1e-6)
        #expect(abs(lab.f - 3.6) < 1e-9)
        #expect(abs(lab.p - 0.04112049977) < 1e-8)                               // 1 - pf(3.6, 2, 27)
        #expect(abs(lab.etaSquared - 720.0 / 3420) < 1e-9)
        for g in 0..<lab.k {
            let values = (0..<lab.n).map { lab.value(g, $0) }
            #expect(abs(Stats.mean(values) - lab.means[g]) < 1e-9, "each group's sample mean is the mean set")
        }
        lab.n = 25
        #expect(abs(lab.ssWithin - 72 * 100) < 1e-6, "new people keep the pooled SD exact")
    }

    @Test func splitterKeepsValuesInRange() {
        let lab = AnovaSplitter(seed: 2)
        lab.setMean(0, to: 500)
        #expect(lab.means[0] == AnovaSplitter.meanRange.upperBound)
        lab.withinSD = 0
        #expect(lab.withinSD == AnovaSplitter.sdRange.lowerBound)
        lab.n = 1
        #expect(lab.n == AnovaSplitter.nRange.lowerBound)
        #expect(lab.noise.allSatisfy { $0.count == lab.n })
    }

    @Test func splitterGoalsCanBeReached() throws {
        let session = LevelSession(level: try level("variance-rift.anova-splitter"), engine: nil, engineError: nil)
        guard case .anova(let lab) = try #require(session.instrument) else { Issue.record("wrong instrument"); return }
        lab.spacing = 0
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.spacing = 6
        lab.withinSD = 14                                                          // F = 360 / 196 ≈ 1.84
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.spacing = 3
        lab.withinSD = 2                                                           // F = 90 / 4 = 22.5, η² ≈ .63
        #expect(Set(session.updateLab(readings: lab.readings)) == [2, 3])
        #expect(session.labReady)
    }

    // MARK: p-Hacking Garden

    @Test func gardenLookSizes() {
        let lab = PHackingGarden(looks: 5, n: 20, seed: 1)
        #expect(lab.lookSizes == [4, 8, 12, 16, 20])
        lab.n = 10
        lab.looks = 10
        #expect(lab.lookSizes == Array(2...10), "looks that would test fewer than 2 per group merge")
    }

    @Test func gardenRatesMatchTheory() {
        let lab = PHackingGarden(seed: 9)
        lab.run(4000)
        #expect(abs(lab.rate - 0.05) < 0.012)
        lab.outcomes = 10
        #expect(lab.total == 0, "changing a setting clears the garden")
        lab.run(2000)
        #expect(abs(lab.rate - lab.theoryRate) < 0.035)
        #expect(abs(lab.theoryRate - 0.4012630608) < 1e-9)                         // 1 - 0.95^10
        lab.bonferroni = true
        lab.run(2000)
        #expect(abs(lab.rate - 0.049) < 0.015)
        lab.bonferroni = false
        lab.outcomes = 1
        lab.looks = 5
        lab.run(3000)
        #expect(abs(lab.rate - 0.146) < 0.02, "five looks at n = 20 (R simulation: .146)")
        #expect(lab.recent.count == PHackingGarden.shown)
    }

    @Test func gardenGoalsCanBeReached() throws {
        let session = LevelSession(level: try level("variance-rift.p-hacking-garden"), engine: nil, engineError: nil)
        guard case .garden(let lab) = try #require(session.instrument) else { Issue.record("wrong instrument"); return }
        lab.run(2000)
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.outcomes = 10
        lab.run(500)
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.outcomes = 1
        lab.looks = 5
        lab.run(2000)
        #expect(session.updateLab(readings: lab.readings) == [2])
        lab.looks = 1
        lab.outcomes = 10
        lab.bonferroni = true
        lab.run(2000)
        #expect(session.updateLab(readings: lab.readings) == [3])
        #expect(session.labReady)
    }

    // MARK: Chi-square Grid

    @Test func gridMatchesChisqTest() {
        let lab = ChiSquareGrid(counts: [[28, 22], [20, 30]])
        #expect(abs(lab.statistic - 2.564102564) < 1e-8)
        #expect(abs(lab.p - 0.1093145762) < 1e-8)                                 // pchisq(100 / 39, 1, lower.tail = FALSE)
        #expect(abs(lab.cramersV - 0.1601281538) < 1e-8)
        #expect(lab.minExpected == 24)
        lab.yates = true
        #expect(abs(lab.statistic - 1.9631410256) < 1e-9)                         // chisq.test(m)
        #expect(abs(lab.p - 0.1611777894) < 1e-7)
        #expect(abs(lab.cramersV - 0.1601281538) < 1e-8, "V uses the uncorrected χ²")

        let wide = ChiSquareGrid(rowLabels: ["a", "b"], colLabels: ["x", "y", "z"], counts: [[10, 20, 30], [25, 15, 20]])
        wide.yates = true                                                          // ignored beyond 2 × 2
        #expect(abs(wide.statistic - 9.1428571429) < 1e-8)
        #expect(abs(wide.p - 0.0103431732) < 1e-8)
        #expect(wide.df == 2)
        #expect(abs(wide.cramersV - 0.2760262237) < 1e-8)
        #expect(wide.minExpected == 17.5)
    }

    @Test func gridEditing() {
        let lab = ChiSquareGrid(counts: [[28, 22], [20, 30]])
        lab.set(0, 0, to: -5)
        #expect(lab.counts[0][0] == 0)
        lab.reset()
        lab.scale(by: 2)
        #expect(lab.n == 200)
        #expect(abs(lab.cramersV - 0.1601281538) < 1e-8, "scaling keeps the pattern")
        lab.makeIndependent()
        #expect(lab.statistic < 0.05)
    }

    @Test func gridGoalsCanBeReached() throws {
        let session = LevelSession(level: try level("relationship-ring.chi-square-grid"), engine: nil, engineError: nil)
        guard case .chiSquare(let lab) = try #require(session.instrument) else { Issue.record("wrong instrument"); return }
        lab.makeIndependent()
        #expect(session.updateLab(readings: lab.readings) == [0])
        for (i, row) in [[40, 10], [15, 35]].enumerated() { for (j, v) in row.enumerated() { lab.set(i, j, to: v) } }
        #expect(session.updateLab(readings: lab.readings) == [1])
        for (i, row) in [[270, 230], [230, 270]].enumerated() { for (j, v) in row.enumerated() { lab.set(i, j, to: v) } }
        #expect(session.updateLab(readings: lab.readings) == [2])                 // p ≈ .011, V = .08
        for (i, row) in [[4, 3], [3, 4]].enumerated() { for (j, v) in row.enumerated() { lab.set(i, j, to: v) } }
        #expect(session.updateLab(readings: lab.readings) == [3])
        #expect(session.labReady)
    }
}
