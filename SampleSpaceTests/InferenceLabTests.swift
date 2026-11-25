import Foundation
import Testing
@testable import SampleSpace

@Suite("t and power maths")
struct DistributionTests {
    private func close(_ a: Double, _ b: Double, _ tol: Double = 1e-6) -> Bool { abs(a - b) < tol }

    @Test func centralTMatchesR() {
        #expect(close(Stats.tCDF(2.1, df: 5), 0.9551233751))       // pt(2.1, 5)
        #expect(close(Stats.tCDF(-0.7, df: 38), 0.2440954588))     // pt(-0.7, 38)
        #expect(close(Stats.tQuantile(0.975, df: 10), 2.2281388520))
        #expect(close(Stats.tQuantile(0.995, df: 36), 2.7194846305))
        #expect(close(Stats.normalQuantile(0.975), 1.9599639845))
        #expect(close(Stats.tDensity(1.3, df: 7), 0.1620929551))
    }

    @Test func noncentralTMatchesR() {
        #expect(close(Stats.noncentralTDensity(2, df: 38, ncp: 1.58), 0.3534842421, 1e-5))   // dt(2, 38, 1.58)
        #expect(close(Stats.noncentralTUpper(1.5, df: 2, ncp: 3), 0.9123800244, 1e-5))       // small df
    }

    @Test func powerMatchesPowerTTest() {
        #expect(close(Stats.twoSamplePower(d: 0.5, n: 20, alpha: 0.05), 0.3377083656, 1e-5))
        #expect(close(Stats.twoSamplePower(d: 0.5, n: 64, alpha: 0.05), 0.8014586234, 1e-5))
        #expect(close(Stats.twoSamplePower(d: 1.2, n: 3, alpha: 0.05), 0.2060470212, 1e-5))
        #expect(close(Stats.twoSamplePower(d: 0.2, n: 100, alpha: 0.01), 0.1203114410, 1e-5))
        #expect(close(Stats.twoSamplePower(d: 0.5, n: 20, alpha: 0.05, twoSided: false), 0.4633743493, 1e-5))
    }

    @Test @MainActor func nFor80MatchesPowerTTest() {
        let lab = PowerReactor(d: 0.5, n: 20)
        #expect(lab.nFor80 == 64)        // ceiling(power.t.test(power = .8, delta = .5)$n) = 64
    }
}

@Suite("Inference and relationship labs")
@MainActor
struct InferenceLabTests {
    private func level(_ id: String) throws -> Level {
        try #require(try ContentLibrary.loadBundled().level(id: id))
    }

    @Test func readingsMatchTheDeclaredNames() throws {
        #expect(Set(CIRain(seed: 1).readings.keys) == Set(LabKind.ciRain.readings.keys))
        #expect(Set(PValueCourtroom(seed: 1).readings.keys) == Set(LabKind.pValueCourtroom.readings.keys))
        #expect(Set(PowerReactor().readings.keys) == Set(LabKind.powerReactor.readings.keys))
        #expect(Set(CorrelationDrag(seed: 1).readings.keys) == Set(LabKind.correlationDrag.readings.keys))
        let fit = LeastSquaresFit(xs: [1, 2, 3], ys: [2, 4, 5], xLabel: "x", yLabel: "y")
        #expect(Set(fit.readings.keys) == Set(LabKind.leastSquares.readings.keys))
    }

    @Test func ciRainCoversAboutTheRightShare() {
        let lab = CIRain(mu: 40, sigma: 5, startN: 10, seed: 7)
        lab.draw(4000)
        #expect(abs(lab.coverage - 0.95) < 0.015)
        #expect(abs(lab.meanWidth / lab.expectedWidth - 1) < 0.08)
        lab.level = 0.99
        #expect(lab.intervals.isEmpty, "changing the level starts a new set")
    }

    @Test func ciRainGoalsCanBeReached() throws {
        let session = LevelSession(level: try level("inference-station.ci-rain"), engine: nil, engineError: nil)
        guard case .ciRain(let lab) = try #require(session.instrument) else { Issue.record("wrong instrument"); return }
        lab.draw(100)
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.level = 0.99
        lab.draw(100)
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.level = 0.95
        lab.n = 120
        lab.draw(1000)
        #expect(Set(session.updateLab(readings: lab.readings)) == [2, 3])
        #expect(session.labReady)
    }

    @Test func courtroomPValuesMatchR() {
        let lab = PValueCourtroom(diff: 1.8, sd: 6.5, n: 19, seed: 3)
        #expect(abs(lab.t - 0.8535342466) < 1e-8)                   // 1.8 / (6.5 * sqrt(2/19))
        #expect(abs(lab.p - 2 * (1 - 0.8004965533)) < 1e-7)         // 2 * pt(-abs(t), 36)
        lab.tails = .greater
        #expect(abs(lab.p - (1 - 0.8004965533)) < 1e-7)
        lab.tails = .two
        lab.simulate(4000)
        #expect(abs(lab.simulatedP - lab.p) < 0.03)
    }

    @Test func courtroomGoalsCanBeReached() throws {
        let session = LevelSession(level: try level("inference-station.p-value-courtroom"), engine: nil, engineError: nil)
        guard case .courtroom(let lab) = try #require(session.instrument) else { Issue.record("wrong instrument"); return }
        lab.diff = 4.3                                               // t ≈ 2.04, p ≈ .049 at n = 19
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.tails = .greater
        lab.diff = 3.8                                               // t ≈ 1.80
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.tails = .two
        lab.diff = 1.8
        lab.n = 400
        #expect(session.updateLab(readings: lab.readings) == [2])
        lab.simulate(1000)
        #expect(session.updateLab(readings: lab.readings) == [3])
    }

    @Test func powerGoalsCanBeReached() throws {
        let session = LevelSession(level: try level("inference-station.power-reactor"), engine: nil, engineError: nil)
        guard case .power(let lab) = try #require(session.instrument) else { Issue.record("wrong instrument"); return }
        lab.d = 0.5
        lab.n = 20
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.n = 64
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.n = 30
        lab.d = 0.74
        #expect(session.updateLab(readings: lab.readings) == [2])
        lab.d = 0.2
        lab.n = 394
        #expect(session.updateLab(readings: lab.readings) == [3])
    }

    @Test func newCloudsHaveTheRequestedCorrelation() {
        let lab = CorrelationDrag(count: 20, startR: 0.6, seed: 11)
        #expect(abs(lab.r - 0.6) < 0.06, "clamping to the plot can nudge r a little")
        lab.newCloud(r: -0.4)
        #expect(abs(lab.r + 0.4) < 0.06)
    }

    @Test func correlationGoalsCanBeReached() throws {
        let session = LevelSession(level: try level("relationship-ring.correlation-drag"), engine: nil, engineError: nil)
        guard case .correlation(let lab) = try #require(session.instrument) else { Issue.record("wrong instrument"); return }
        lab.newCloud(r: 0.9)
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.newCloud(r: -0.7)
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.newCloud(r: 0)
        lab.addOutlier()
        if let outlier = lab.dots.last { lab.move(outlier.id, x: 10, y: 0) }
        #expect(session.updateLab(readings: lab.readings) == [2], "one corner outlier should move r by 0.35")
    }

    @Test func leastSquaresMatchesLM() throws {
        let level = try level("relationship-ring.least-squares-fit")
        let lab = try LeastSquaresFit.make(settings: try #require(level.lab).settings, folder: level.folder)
        #expect(lab.xs.count == 46)
        #expect(abs(lab.bestIntercept - -1.8522016) < 1e-6)        // coef(lm(morale_score ~ sleep_hours))
        #expect(abs(lab.bestSlope - 0.6998186) < 1e-6)
        #expect(abs(lab.bestSSE - 35.05664) < 1e-4)
        #expect(abs(lab.sst - 46.08924) < 1e-4)
        lab.setLine(leftY: lab.bestIntercept + lab.bestSlope * lab.xDomain.lowerBound,
                    rightY: lab.bestIntercept + lab.bestSlope * lab.xDomain.upperBound)
        #expect(abs(lab.slope - lab.bestSlope) < 1e-9)
    }

    @Test func leastSquaresGoalsCanBeReached() throws {
        let session = LevelSession(level: try level("relationship-ring.least-squares-fit"), engine: nil, engineError: nil)
        guard case .leastSquares(let lab) = try #require(session.instrument) else { Issue.record("wrong instrument"); return }
        // Through the means with a too-shallow slope: about 8% above the minimum SSE.
        lab.slope = 0.35
        lab.intercept = Stats.mean(lab.ys) - 0.35 * Stats.mean(lab.xs)
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.slope = 0.7
        lab.intercept = -1.85
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.slope = 0
        lab.intercept = Stats.mean(lab.ys)
        #expect(session.updateLab(readings: lab.readings) == [2])
    }
}
