import Foundation

/// Everything the game remembers between launches. Saved as one JSON file:
/// `~/Library/Application Support/SampleSpace/progress.json`.
///
/// XP, rank, streak and fuel are not stored: they are worked out from this record, so they
/// can never drift out of step with it.
struct PilotProgress: Codable, Equatable, Sendable {
    var version = 1
    /// Results per level id, for levels cleared at least once.
    var levels: [String: LevelProgress] = [:]
    /// Days with practice, as local `yyyy-MM-dd` keys, oldest first.
    var practiceDays: [String] = []
    /// Badge id → when it was earned.
    var badges: [String: Date] = [:]
    /// Code left in the editor, per level id (only when it differs from the starter code).
    var drafts: [String: String] = [:]
    /// Review Nebula: each card's schedule and the cards answered per day.
    var review = ReviewRecord()

    var clearedIDs: Set<String> { Set(levels.keys) }
    var totalStars: Int { levels.values.reduce(0) { $0 + $1.bestStars } }
}

extension PilotProgress {
    /// Missing keys take their defaults, so a save from an older version (e.g. before the
    /// Review Nebula) still loads instead of being moved aside.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? version
        levels = try container.decodeIfPresent([String: LevelProgress].self, forKey: .levels) ?? [:]
        practiceDays = try container.decodeIfPresent([String].self, forKey: .practiceDays) ?? []
        badges = try container.decodeIfPresent([String: Date].self, forKey: .badges) ?? [:]
        drafts = try container.decodeIfPresent([String: String].self, forKey: .drafts) ?? [:]
        review = try container.decodeIfPresent(ReviewRecord.self, forKey: .review) ?? ReviewRecord()
    }
}

struct LevelProgress: Codable, Equatable, Sendable {
    var bestStars: Int
    var firstCleared: Date
    var lastCleared: Date
    var clears: Int = 1
    /// True once the level has been passed without hints or the solution.
    var clearedWithoutHints: Bool
}

// MARK: - XP

enum XP {
    /// Extra XP for each star beyond the first, so replaying for stars is worth it.
    static let perBonusStar = 10

    /// XP a level is worth at a given number of stars.
    static func value(of level: Level, stars: Int) -> Int {
        guard stars > 0 else { return 0 }
        return level.xp + perBonusStar * (stars - 1)
    }

    static func total(_ progress: PilotProgress, levels: [Level]) -> Int {
        levels.reduce(0) { sum, level in
            sum + value(of: level, stars: progress.levels[level.id]?.bestStars ?? 0)
        }
    }
}

// MARK: - Store

/// Reads and writes `PilotProgress`. A missing file means a new pilot; a file that can't be read
/// is moved aside (never silently overwritten) and play starts fresh.
struct ProgressStore: Sendable {
    let url: URL

    /// The real save file, unless the app was launched with `-ProgressFile /path/file.json`
    /// (handy for trying things without touching your own progress).
    static var standard: ProgressStore {
        if let path = UserDefaults.standard.string(forKey: "ProgressFile"), !path.isEmpty {
            return ProgressStore(url: URL(filePath: (path as NSString).expandingTildeInPath))
        }
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return ProgressStore(url: support.appending(path: "SampleSpace/progress.json"))
    }

    func load() -> (progress: PilotProgress, problem: String?) {
        let fm = FileManager.default
        guard fm.fileExists(atPath: url.path) else { return (PilotProgress(), nil) }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try decoder.decode(PilotProgress.self, from: data), nil)
        } catch {
            let stamp = Date.now.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false))
                .replacingOccurrences(of: ":", with: "-")
            let backup = url.deletingPathExtension().appendingPathExtension("unreadable-\(stamp).json")
            try? fm.moveItem(at: url, to: backup)
            return (PilotProgress(), "Saved progress couldn't be read, so it was moved to \(backup.lastPathComponent) "
                    + "and a new log was started.")
        }
    }

    func save(_ progress: PilotProgress) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(progress).write(to: url, options: .atomic)
    }

    func delete() throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }
}
