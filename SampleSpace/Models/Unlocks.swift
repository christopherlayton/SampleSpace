import Foundation

/// Which sectors and levels are open, worked out from the levels cleared.
///
/// - Sector 0 is always open. Each later sector opens when the one before it is charted
///   (it has levels and all are cleared). A sector whose levels aren't written yet blocks
///   the ones after it until it gets content.
/// - In an open sector the first level is open; clearing a level opens the ones it
///   `unlocks` (by default the next level in its sector). Cleared levels stay open.
struct UnlockState: Equatable, Sendable {
    var sectorStatus: [Int: SectorStatus]
    var openLevels: Set<String>

    static func compute(sectors: [Sector], cleared: Set<String>) -> UnlockState {
        var statuses: [Int: SectorStatus] = [:]
        var open = Set<String>()

        // Targets unlocked by cleared levels, anywhere in the curriculum.
        var unlockedTargets = Set<String>()
        for sector in sectors {
            for (index, level) in sector.levels.enumerated() where cleared.contains(level.id) {
                if let targets = level.unlocks {
                    unlockedTargets.formUnion(targets)
                } else if sector.levels.indices.contains(index + 1) {
                    unlockedTargets.insert(sector.levels[index + 1].id)
                }
            }
        }

        var previousCharted = true
        for sector in sectors {
            let charted = !sector.levels.isEmpty && sector.levels.allSatisfy { cleared.contains($0.id) }
            guard previousCharted else {
                statuses[sector.id] = .locked
                continue
            }
            statuses[sector.id] = charted ? .completed : .current
            for (index, level) in sector.levels.enumerated()
            where index == 0 || cleared.contains(level.id) || unlockedTargets.contains(level.id) {
                open.insert(level.id)
            }
            // The optional sector doesn't hold up anything after it.
            if !sector.isOptional { previousCharted = charted }
        }
        return UnlockState(sectorStatus: statuses, openLevels: open)
    }
}
