import Foundation

/// All sectors and levels, loaded from the `Content/` folder.
///
///     Content/
///       sector-00-launch-pad/
///         sector.json
///         01-calculator-console/   (a level folder; see `Level`)
///
/// Folder names set the order; the numbers in them are only for sorting.
struct ContentLibrary: Sendable {
    var sectors: [Sector]

    var levels: [Level] { sectors.flatMap(\.levels) }

    func level(id: String) -> Level? { levels.first { $0.id == id } }

    /// The content shipped inside the app bundle.
    static func loadBundled() throws -> ContentLibrary {
        guard let url = Bundle.main.url(forResource: "Content", withExtension: nil) else {
            throw ContentError.missingFolder("Content")
        }
        return try load(from: url)
    }

    static func load(from root: URL) throws -> ContentLibrary {
        var sectors = try subfolders(of: root, prefix: "sector-").map(loadSector)
        sectors.sort { $0.id < $1.id }

        var seen = Set<String>()
        for level in sectors.flatMap(\.levels) where !seen.insert(level.id).inserted {
            throw ContentError.duplicateLevelID(level.id)
        }
        // Until Step 5 adds saved progress, the first sector is the one in play.
        if !sectors.isEmpty { sectors[0].status = .current }
        return ContentLibrary(sectors: sectors)
    }

    // MARK: - Loading

    private static func loadSector(at folder: URL) throws -> Sector {
        let file: SectorFile = try decode(folder.appending(path: "sector.json"))
        var sector = Sector(id: file.id, name: file.name, rSkills: file.rSkills,
                            statsConcepts: file.statsConcepts, hue: file.hue,
                            mapPosition: CGPoint(x: file.mapPosition.x, y: file.mapPosition.y),
                            planetSize: file.planetSize, isOptional: file.optional ?? false,
                            hasRing: file.ring ?? false, briefing: file.briefing ?? "", log: file.log)
        sector.levels = try subfolders(of: folder)
            .filter { FileManager.default.fileExists(atPath: $0.appending(path: "level.json").path) }
            .map(loadLevel)
        return sector
    }

    private static func loadLevel(at folder: URL) throws -> Level {
        let file: LevelFile = try decode(folder.appending(path: "level.json"))
        if file.type == .lab, file.lab == nil {
            throw ContentError.badJSON(folder.appending(path: "level.json").path, "a lab level needs a \"lab\" object")
        }
        return Level(
            id: file.id, title: file.title, summary: file.summary ?? "", type: file.type,
            xp: file.xp, par: file.par ?? 2, hints: file.hints ?? [], unlocks: file.unlocks,
            timeLimit: file.timeLimit ?? 10, seed: file.seed, lab: file.lab,
            lesson: try text(folder, "lesson.md"),
            starterCode: try text(folder, "starter.R"),
            solutionCode: try text(folder, "solution.R"),
            checkCode: try text(folder, "check.R"),
            setupCode: try? text(folder, "setup.R"),
            folder: folder)
    }

    private static func subfolders(of folder: URL, prefix: String = "") throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(at: folder, includingPropertiesForKeys: [.isDirectoryKey],
                                 options: .skipsHiddenFiles)
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .filter { $0.lastPathComponent.hasPrefix(prefix) }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static func text(_ folder: URL, _ name: String) throws -> String {
        let url = folder.appending(path: name)
        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ContentError.missingFile(url.path)
        }
    }

    private static func decode<T: Decodable>(_ url: URL) throws -> T {
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(T.self, from: Data(contentsOf: url))
        } catch {
            throw ContentError.badJSON(url.path, String(describing: error))
        }
    }
}

enum ContentError: Error, LocalizedError, Equatable {
    case missingFolder(String)
    case missingFile(String)
    case badJSON(String, String)
    case duplicateLevelID(String)

    var errorDescription: String? {
        switch self {
        case .missingFolder(let name): "The \(name) folder is missing from the app."
        case .missingFile(let path): "Missing level file: \(path)"
        case .badJSON(let path, let detail): "Couldn't read \(path): \(detail)"
        case .duplicateLevelID(let id): "Two levels share the id \"\(id)\"."
        }
    }
}

// MARK: - File formats

private struct SectorFile: Decodable {
    struct Point: Decodable { let x: Double, y: Double }
    let id: Int
    let name: String
    let rSkills: String
    let statsConcepts: String
    let hue: Double
    let mapPosition: Point
    let planetSize: Double
    let ring: Bool?
    let optional: Bool?
    let briefing: String?
    let log: LogEntry?
}

private struct LevelFile: Decodable {
    let id: String
    let title: String
    let summary: String?
    let type: LevelType
    let xp: Int
    let par: Int?
    let hints: [String]?
    let unlocks: [String]?
    let timeLimit: Double?
    let seed: Int?
    let lab: LabSpec?
}
