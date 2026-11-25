import SwiftUI

/// A running lab instrument, made from a level's `LabSpec`.
@MainActor
enum LabInstrument {
    case sculptor(DistributionSculptor)
    case sampler(SamplingMachine)
    case ciRain(CIRain)
    case courtroom(PValueCourtroom)
    case power(PowerReactor)
    case correlation(CorrelationDrag)
    case leastSquares(LeastSquaresFit)
    case anova(AnovaSplitter)
    case garden(PHackingGarden)
    case chiSquare(ChiSquareGrid)
    /// The instrument couldn't start (e.g. its data file is missing).
    case unavailable(String)

    static func make(for level: Level) -> LabInstrument? {
        guard let spec = level.lab else { return nil }
        switch spec.kind {
        case .distributionSculptor:
            return .sculptor(DistributionSculptor(settings: spec.settings))
        case .samplingMachine:
            do {
                return .sampler(try SamplingMachine.make(settings: spec.settings, folder: level.folder))
            } catch {
                return .unavailable(error.localizedDescription)
            }
        case .ciRain: return .ciRain(CIRain(settings: spec.settings))
        case .pValueCourtroom: return .courtroom(PValueCourtroom(settings: spec.settings))
        case .powerReactor: return .power(PowerReactor(settings: spec.settings))
        case .correlationDrag: return .correlation(CorrelationDrag(settings: spec.settings))
        case .leastSquares:
            do {
                return .leastSquares(try LeastSquaresFit.make(settings: spec.settings, folder: level.folder))
            } catch {
                return .unavailable(error.localizedDescription)
            }
        case .anovaSplitter: return .anova(AnovaSplitter(settings: spec.settings))
        case .pHackingGarden: return .garden(PHackingGarden(settings: spec.settings))
        case .chiSquareGrid: return .chiSquare(ChiSquareGrid(settings: spec.settings))
        }
    }

    var readings: [String: Double] {
        switch self {
        case .sculptor(let lab): lab.readings
        case .sampler(let lab): lab.readings
        case .ciRain(let lab): lab.readings
        case .courtroom(let lab): lab.readings
        case .power(let lab): lab.readings
        case .correlation(let lab): lab.readings
        case .leastSquares(let lab): lab.readings
        case .anova(let lab): lab.readings
        case .garden(let lab): lab.readings
        case .chiSquare(let lab): lab.readings
        case .unavailable: [:]
        }
    }

    func stop() {
        if case .sampler(let lab) = self { lab.stopAuto() }
        if case .ciRain(let lab) = self { lab.stopAuto() }
    }
}

/// The instrument's own controls and charts.
struct LabInstrumentView: View {
    let instrument: LabInstrument

    var body: some View {
        switch instrument {
        case .sculptor(let lab): DistributionSculptorView(lab: lab)
        case .sampler(let lab): SamplingMachineView(lab: lab)
        case .ciRain(let lab): CIRainView(lab: lab)
        case .courtroom(let lab): PValueCourtroomView(lab: lab)
        case .power(let lab): PowerReactorView(lab: lab)
        case .correlation(let lab): CorrelationDragView(lab: lab)
        case .leastSquares(let lab): LeastSquaresFitView(lab: lab)
        case .anova(let lab): AnovaSplitterView(lab: lab)
        case .garden(let lab): PHackingGardenView(lab: lab)
        case .chiSquare(let lab): ChiSquareGridView(lab: lab)
        case .unavailable(let message):
            ContentUnavailableView("Lab offline", systemImage: "exclamationmark.triangle", description: Text(message))
        }
    }
}
