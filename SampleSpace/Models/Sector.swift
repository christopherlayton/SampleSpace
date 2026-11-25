import SwiftUI

enum SectorStatus: Sendable {
    case locked, current, completed
}

/// One system on the star map, loaded from `Content/sector-NN-name/sector.json`.
struct Sector: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let rSkills: String
    let statsConcepts: String
    let hue: Double
    /// Position on the map, in 0–1 coordinates.
    let mapPosition: CGPoint
    let planetSize: CGFloat
    var isOptional = false
    var hasRing = false
    /// Story: shown on arrival (sector panel), from `briefing` in sector.json.
    var briefing = ""
    /// Story: the Crew Log entry recovered when the sector is charted.
    var log: LogEntry?
    /// Levels in play order.
    var levels: [Level] = []
    /// Set from saved progress by `GameModel` (see `UnlockState`).
    var status: SectorStatus = .locked

    var color: Color { .planet(hue: hue) }
    var totalXP: Int { levels.reduce(0) { $0 + $1.xp } }
}

/// One entry of the Crew Log, recovered by charting a sector. See STORY.md.
struct LogEntry: Hashable, Sendable, Decodable {
    let title: String
    let text: String
}

/// Player stats shown in the HUD, worked out from saved progress by `GameModel`.
struct PlayerSnapshot: Sendable {
    var rank = Rank.cadet
    var xp = 0
    var stars = 0
    var fuel = 1.0
    var streak = 0
}
