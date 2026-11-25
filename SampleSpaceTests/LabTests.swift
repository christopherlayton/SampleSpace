import Foundation
import Testing
@testable import SampleSpace

@Suite("Lab goals")
struct LabGoalTests {
    private func goal(_ conditions: LabCondition...) -> LabGoal {
        LabGoal(text: "goal", when: conditions)
    }

    @Test func conditionsCheckEqualsMinAndMax() {
        let near = LabCondition(reading: "mean", equals: 100, tolerance: 0.5)
        #expect(near.holds(in: ["mean": 100.4]))
        #expect(!near.holds(in: ["mean": 100.6]))
        #expect(!near.holds(in: [:]), "a missing reading never holds")
        #expect(!LabCondition(reading: "se", max: 200).holds(in: ["se": .nan]), "NaN never holds")
        let band = LabCondition(reading: "area", min: 0.945, max: 0.955)
        #expect(band.holds(in: ["area": 0.95]))
        #expect(!band.holds(in: ["area": 0.96]))
    }

    @Test func aGoalNeedsEveryConditionAtOnce() {
        let g = goal(LabCondition(reading: "n", min: 30), LabCondition(reading: "samples", min: 1000))
        #expect(!g.isMet(by: ["n": 30, "samples": 999]))
        #expect(g.isMet(by: ["n": 31, "samples": 1000]))
        #expect(!LabGoal(text: "empty", when: []).isMet(by: ["n": 1]))
    }

    @Test func reachedGoalsStayReached() {
        var tracker = LabGoalTracker(goals: [
            goal(LabCondition(reading: "x", equals: 1)),
            goal(LabCondition(reading: "x", equals: 2)),
        ])
        #expect(tracker.current == 0)
        #expect(tracker.update(["x": 2]) == [1])
        #expect(tracker.current == 0)
        #expect(tracker.update(["x": 1]) == [0])
        #expect(tracker.update(["x": 5]).isEmpty)
        #expect(tracker.allReached)
        #expect(tracker.current == nil)
    }
}

@Suite("Distribution Sculptor")
@MainActor
struct DistributionSculptorTests {
    @Test func normalCDFMatchesR() {
        #expect(abs(Stats.normalCDF(0) - 0.5) < 1e-12)
        #expect(abs(Stats.normalCDF(1.959964) - 0.975) < 1e-6)   // qnorm(0.975)
        #expect(abs(Stats.normalCDF(-1) - 0.1586553) < 1e-6)     // pnorm(-1)
    }

    @Test func areasForEachShade() {
        let lab = DistributionSculptor(settings: LabSettings(startMean: 100, startSd: 15, xRange: [40, 160]))
        lab.cutoff = 130
        lab.shade = .above
        #expect(abs(lab.area - 0.02275013) < 1e-6)                // pnorm(130, 100, 15, lower.tail = FALSE)
        #expect(abs(lab.readings["z"]! - 2) < 1e-12)
        lab.shade = .below
        #expect(abs(lab.area - 0.97724987) < 1e-6)
        lab.cutoff = 129.3995
        lab.cutoff2 = 70.6005
        lab.shade = .between
        #expect(abs(lab.area - 0.95) < 1e-5)
        #expect(lab.lower == 70.6005)
        lab.shade = .outside
        #expect(abs(lab.area - 0.05) < 1e-5)
        #expect(lab.rCode == "pnorm(70.6005, 100, 15) + pnorm(129.3995, 100, 15, lower.tail = FALSE)")
    }

    @Test func valuesStayInTheirRanges() {
        let lab = DistributionSculptor(settings: LabSettings(meanRange: [60, 140], sdRange: [5, 30], xRange: [40, 160]))
        lab.mean = 500
        lab.sd = 0
        lab.cutoff = -10
        #expect(lab.mean == 140)
        #expect(lab.sd == 5)
        #expect(lab.cutoff == 40)
        #expect(lab.dragStep == 1)
    }

    @Test func shadedOutlineHasVerticalEdgesAtTheCutoff() {
        let lab = DistributionSculptor(settings: LabSettings(startMean: 0, startSd: 1, xRange: [-4, 4], shade: "below", cutoff: 0.5))
        let atCutoff = lab.shadedOutline().filter { $0.x == 0.5 }
        #expect(atCutoff.count == 2)
        #expect(atCutoff[0].y > 0 && atCutoff[1].y == 0)
        #expect(lab.dragStep == 0.01)
    }

    @Test func readingsMatchTheDeclaredNames() {
        let names = Set(DistributionSculptor().readings.keys)
        #expect(names == Set(LabKind.distributionSculptor.readings.keys))
    }
}

@Suite("Sampling Machine")
@MainActor
struct SamplingMachineTests {
    private func machine(n: Int = 2) -> SamplingMachine {
        // A skewed population: mostly small values, a few large ones.
        var population: [Double] = []
        for i in 0..<1000 {
            population.append(i < 900 ? Double(i % 10) : 100 + Double(i - 900))
        }
        return SamplingMachine(population: population, label: "test", startN: n, seed: 42)
    }

    @Test func standardErrorShrinksWithRootN() {
        let lab = machine(n: 25)
        lab.draw(4000)
        #expect(lab.means.count == 4000)
        #expect(abs(lab.meanOfMeans - lab.popMean) < 0.05 * lab.popSD)
        #expect(abs(lab.simulatedSE / lab.theorySE - 1) < 0.08)
        #expect(lab.skewOfMeans < lab.popSkew / 2, "means are much less skewed than the population")
    }

    @Test func changingNStartsANewPile() {
        let lab = machine()
        lab.draw(10)
        #expect(lab.lastSample.count == 2)
        lab.n = 5
        #expect(lab.means.isEmpty)
        lab.n = 500
        #expect(lab.n == 100, "n is capped at maxN")
    }

    @Test func readingsMatchTheDeclaredNames() {
        #expect(Set(machine().readings.keys) == Set(LabKind.samplingMachine.readings.keys))
    }
}

@Suite("CSV reader")
struct CSVTableTests {
    @Test func handlesQuotesCommasAndLineEndings() {
        let table = CSVTable(text: "\u{FEFF}name,hours\r\n\"Gagarin, Yuri\",1.77\r\n\"Say \"\"hi\"\"\",NA\n\"two\nlines\",3\n")
        #expect(table.header == ["name", "hours"])
        #expect(table.rows.count == 3)
        #expect(table.rows[0] == ["Gagarin, Yuri", "1.77"])
        #expect(table.rows[1][0] == "Say \"hi\"")
        #expect(table.rows[2][0] == "two\nlines")
        #expect(table.numbers(in: "hours") == [1.77, 3])
        #expect(table.numbers(in: "missing") == nil)
    }

    @Test func readsTheCrewLog() throws {
        let content = try #require(Bundle.main.url(forResource: "Content", withExtension: nil))
        let table = try CSVTable(contentsOf: content.appending(path: "data-bank/astronauts.csv"))
        let hours = try #require(table.numbers(in: "hours_mission"))
        #expect(hours.count == 1277)
        #expect(abs(Stats.mean(hours) - 1050.884) < 0.01)          // mean(a$hours_mission)
        #expect(abs(Stats.sd(hours) - 1714.792) < 0.01)            // sd(a$hours_mission)
    }
}

@Suite("Lab levels")
@MainActor
struct LabLevelTests {
    private func labLevel(_ id: String) throws -> Level {
        try #require(try ContentLibrary.loadBundled().level(id: id))
    }

    @Test func everyGoalUsesReadingsItsInstrumentHas() throws {
        let labs = try ContentLibrary.loadBundled().levels.filter { $0.type == .lab }
        #expect(labs.count >= 2)
        for level in labs {
            let spec = try #require(level.lab, "\(level.id) has no lab spec")
            #expect(!spec.goals.isEmpty, "\(level.id) has no goals")
            let known = Set(spec.kind.readings.keys)
            for goal in spec.goals {
                for condition in goal.when {
                    #expect(known.contains(condition.reading), "\(level.id): unknown reading \(condition.reading)")
                }
            }
            let instrument = try #require(LabInstrument.make(for: level))
            if case .unavailable(let message) = instrument { Issue.record("\(level.id): \(message)") }
            // Nothing is reached for free at the starting settings.
            var tracker = LabGoalTracker(goals: spec.goals)
            #expect(tracker.update(instrument.readings).isEmpty, "\(level.id): a goal is met at the start")
        }
    }

    @Test func sculptorGoalsCanBeReached() throws {
        let session = LevelSession(level: try labLevel("probability-expanse.distribution-sculptor"),
                                   engine: nil, engineError: nil)
        guard case .sculptor(let lab) = try #require(session.instrument) else {
            Issue.record("wrong instrument"); return
        }
        #expect(!session.labReady)
        lab.mean = 100
        lab.sd = 15
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.shade = .above
        lab.cutoff = 130
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.shade = .between
        lab.cutoff = 71
        lab.cutoff2 = 129
        #expect(session.updateLab(readings: lab.readings) == [2])
        #expect(session.labReady)
    }

    @Test func samplerGoalsCanBeReached() throws {
        let session = LevelSession(level: try labLevel("probability-expanse.sampling-machine"),
                                   engine: nil, engineError: nil)
        guard case .sampler(let lab) = try #require(session.instrument) else {
            Issue.record("wrong instrument"); return
        }
        #expect(lab.population.count == 1277)
        lab.draw(500)
        #expect(session.updateLab(readings: lab.readings) == [0])
        lab.n = 30
        lab.draw(1000)
        #expect(session.updateLab(readings: lab.readings) == [1])
        lab.n = 100
        lab.draw(500)
        #expect(session.updateLab(readings: lab.readings) == [2])
        #expect(session.labReady)
    }

    @Test func checkStaysLockedUntilTheGoalsAreReached() async throws {
        let engine = try REngine()
        let level = try labLevel("probability-expanse.distribution-sculptor")
        let session = LevelSession(level: level, engine: engine, engineError: nil)
        session.code = level.solutionCode
        await session.perform(check: true)
        #expect(session.checkAttempts == 0, "Check is refused before the lab goals")
        #expect(session.checks.isEmpty)

        var readings = ["mean": 100.0, "sd": 15, "shade_above": 1, "cutoff": 130]
        session.updateLab(readings: readings)
        readings = ["mean": 100, "sd": 15, "shade_between": 1, "area": 0.95, "z_lower": -1.96, "z_upper": 1.96]
        session.updateLab(readings: readings)
        #expect(session.labReady)
        await session.perform(check: true)
        #expect(session.checkAttempts == 1)
        #expect(!session.checks.isEmpty && session.checks.allSatisfy(\.passed))
    }
}
