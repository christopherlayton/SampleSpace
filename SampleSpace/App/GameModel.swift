import Foundation
import Observation

/// App-wide state: the loaded content, the R engine, navigation, and this session's results.
///
/// Results live in memory only for now; Step 5 saves progress, adds ranks, fuel and badges,
/// and unlocks levels and sectors one by one.
@MainActor @Observable
final class GameModel {
    private(set) var library: ContentLibrary?
    private(set) var loadError: String?
    let engine: REngine?
    let engineError: String?

    /// Level ids pushed on top of the star map.
    var path: [String] = []

    /// Best stars earned per level id.
    private(set) var bestStars: [String: Int] = [:]
    @ObservationIgnored private var sessions: [String: LevelSession] = [:]

    init() {
        do {
            library = try ContentLibrary.loadBundled()
        } catch {
            loadError = error.localizedDescription
        }
        do {
            engine = try REngine()
            engineError = nil
        } catch {
            engine = nil
            engineError = error.localizedDescription
        }
    }

    var sectors: [Sector] { library?.sectors ?? [] }

    var player: PlayerSnapshot {
        let levels = library?.levels ?? []
        let xp = levels.filter { bestStars[$0.id] != nil }.reduce(0) { $0 + $1.xp }
        return PlayerSnapshot(xp: xp, stars: bestStars.values.reduce(0, +))
    }

    func level(id: String) -> Level? { library?.level(id: id) }

    func sector(containing level: Level) -> Sector? {
        sectors.first { $0.levels.contains { $0.id == level.id } }
    }

    func isPlayable(_ level: Level) -> Bool {
        level.type == .code && sector(containing: level)?.status != .locked
    }

    /// The level after this one in play order, if it can be played.
    func nextLevel(after level: Level) -> Level? {
        let next: Level?
        if let id = level.unlocks?.first {
            next = self.level(id: id)
        } else {
            let all = library?.levels ?? []
            next = all.firstIndex(of: level).flatMap { all.indices.contains($0 + 1) ? all[$0 + 1] : nil }
        }
        return next.flatMap { isPlayable($0) ? $0 : nil }
    }

    /// The level's working state, kept while the app is open so leaving and coming back
    /// keeps your code, console and hint count.
    func session(for level: Level) -> LevelSession {
        if let existing = sessions[level.id] { return existing }
        let session = LevelSession(level: level, engine: engine, engineError: engineError) { [weak self] stars in
            self?.record(levelID: level.id, stars: stars) ?? false
        }
        sessions[level.id] = session
        return session
    }

    /// Records a clear. Returns true the first time a level is cleared.
    private func record(levelID: String, stars: Int) -> Bool {
        let firstClear = bestStars[levelID] == nil
        bestStars[levelID] = max(bestStars[levelID] ?? 0, stars)
        return firstClear
    }

    func open(_ level: Level) {
        guard isPlayable(level) else { return }
        path.append(level.id)
    }

    /// Replaces the current level with another, so Back still goes to the map.
    func replaceTop(with level: Level) {
        if path.isEmpty { path = [level.id] } else { path[path.count - 1] = level.id }
    }
}
