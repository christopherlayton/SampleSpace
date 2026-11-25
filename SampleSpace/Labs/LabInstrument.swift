import SwiftUI

/// A running lab instrument, made from a level's `LabSpec`.
@MainActor
enum LabInstrument {
    case sculptor(DistributionSculptor)
    case sampler(SamplingMachine)
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
        }
    }

    var readings: [String: Double] {
        switch self {
        case .sculptor(let lab): lab.readings
        case .sampler(let lab): lab.readings
        case .unavailable: [:]
        }
    }

    func stop() {
        if case .sampler(let lab) = self { lab.stopAuto() }
    }
}

/// The instrument's own controls and charts.
struct LabInstrumentView: View {
    let instrument: LabInstrument

    var body: some View {
        switch instrument {
        case .sculptor(let lab): DistributionSculptorView(lab: lab)
        case .sampler(let lab): SamplingMachineView(lab: lab)
        case .unavailable(let message):
            ContentUnavailableView("Lab offline", systemImage: "exclamationmark.triangle", description: Text(message))
        }
    }
}
