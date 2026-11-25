import Foundation
import Synchronization

/// Renders a Quarto document to a finished report (HTML by default) with the real `quarto`
/// command, the same way you would at the end of a dissertation analysis.
///
/// Knitting for checks happens in `runner.R` (fast, and the checks can see the objects); this
/// is the slower, full pipeline: Quarto runs knitr on a fresh R, then Pandoc, and writes the
/// report into a folder you can open in Finder.
struct QuartoRenderer: Sendable {
    static let candidates = [
        "/Applications/quarto/bin/quarto",
        "/usr/local/bin/quarto",
        "/opt/homebrew/bin/quarto",
        "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto",
        "/Applications/Positron.app/Contents/Resources/app/quarto/bin/quarto",
    ]

    /// How long a render may take before it is stopped.
    static let timeLimit: Double = 180

    let quartoURL: URL
    let rscriptURL: URL

    /// Finds Quarto; returns nil when it isn't installed.
    init?(rscriptURL: URL, quartoPath: String? = nil) {
        let fm = FileManager.default
        let paths = quartoPath.map { [$0] } ?? Self.candidates
        guard let path = paths.first(where: { fm.isExecutableFile(atPath: $0) }) else { return nil }
        quartoURL = URL(filePath: path)
        self.rscriptURL = rscriptURL
    }

    /// The folder reports are written to: `~/Library/Application Support/SampleSpace/Reports/<name>/`.
    static func reportFolder(named name: String) -> URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let safe = name.replacingOccurrences(of: "[^A-Za-z0-9._-]+", with: "-", options: .regularExpression)
        return support.appending(path: "SampleSpace/Reports/\(safe)", directoryHint: .isDirectory)
    }

    /// Writes `document` as `fileName` into `folder` with the data files from `dataDirectory`,
    /// renders it, and returns the report Quarto wrote.
    func render(document: String, fileName: String, dataDirectory: URL?, into folder: URL) async throws -> URL {
        let fm = FileManager.default
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        if let dataDirectory, dataDirectory.standardizedFileURL != folder.standardizedFileURL {
            for file in try fm.contentsOfDirectory(at: dataDirectory, includingPropertiesForKeys: [.isDirectoryKey],
                                                   options: .skipsHiddenFiles)
            where (try? file.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true
                && !["r", "md", "qmd", "json"].contains(file.pathExtension.lowercased()) {
                let target = folder.appending(path: file.lastPathComponent)
                try? fm.removeItem(at: target)
                try fm.copyItem(at: file, to: target)
            }
        }
        let input = folder.appending(path: fileName)
        try document.write(to: input, atomically: true, encoding: .utf8)
        let started = Date()

        let logURL = folder.appending(path: "quarto-render.log")
        fm.createFile(atPath: logURL.path, contents: nil)
        let log = try FileHandle(forWritingTo: logURL)
        defer { try? log.close() }

        let process = Process()
        process.executableURL = quartoURL
        process.arguments = ["render", fileName]
        process.currentDirectoryURL = folder
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = log
        process.standardError = log
        var environment = ProcessInfo.processInfo.environment
        let rBin = rscriptURL.deletingLastPathComponent().path
        environment["PATH"] = ([rBin, "/usr/local/bin", "/opt/homebrew/bin"] + [environment["PATH"] ?? "/usr/bin:/bin"])
            .joined(separator: ":")
        environment["QUARTO_R"] = rscriptURL.path
        environment["LANG"] = "en_US.UTF-8"
        environment["LC_ALL"] = "en_US.UTF-8"
        process.environment = environment

        let guardian = ProcessGuard()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                process.terminationHandler = { _ in
                    guardian.finish()
                    continuation.resume()
                }
                do {
                    try process.run()
                } catch {
                    process.terminationHandler = nil
                    continuation.resume(throwing: QuartoError.launchFailed(error.localizedDescription))
                    return
                }
                guardian.start(pid: process.processIdentifier)
                Task {
                    try? await Task.sleep(for: .seconds(Self.timeLimit))
                    guardian.stop()
                }
            }
        } onCancel: {
            guardian.stop()
        }
        try Task.checkCancellation()

        let logText = (try? String(contentsOf: logURL, encoding: .utf8)) ?? ""
        guard process.terminationStatus == 0 else {
            throw QuartoError.failed(Self.tail(logText))
        }
        // Quarto names the report after the document; the format comes from the YAML header.
        let base = input.deletingPathExtension().lastPathComponent
        let outputs = ["html", "pdf", "docx", "typ", "md"].map { folder.appending(path: "\(base).\($0)") }
        let fresh = outputs.filter { url in
            guard let date = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
            else { return false }
            return date >= started.addingTimeInterval(-1)
        }
        guard let report = fresh.first else { throw QuartoError.noOutput(Self.tail(logText)) }
        return report
    }

    private static func tail(_ log: String) -> String {
        log.split(separator: "\n", omittingEmptySubsequences: true).suffix(12).joined(separator: "\n")
    }
}

enum QuartoError: Error, LocalizedError {
    case notInstalled
    case launchFailed(String)
    case failed(String)
    case noOutput(String)

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            "Quarto isn't installed. Get it from quarto.org, or set its path in Settings."
        case .launchFailed(let reason):
            "Couldn't start Quarto: \(reason)"
        case .failed(let log):
            "Quarto couldn't render the report.\n\(log)"
        case .noOutput(let log):
            "Quarto finished but no report was written.\n\(log)"
        }
    }
}

/// Stops a render that runs too long or is cancelled, without signalling a finished process.
private final class ProcessGuard: Sendable {
    private struct State { var pid: pid_t?; var finished = false; var stopEarly = false }
    private let state = Mutex(State())

    func start(pid: pid_t) {
        let stopNow = state.withLock { s in
            s.pid = pid
            return s.stopEarly
        }
        if stopNow { stop() }
    }

    func finish() { state.withLock { $0.finished = true } }

    func stop() {
        let pid: pid_t? = state.withLock { s in
            guard !s.finished else { return nil }
            if s.pid == nil { s.stopEarly = true }
            return s.pid
        }
        if let pid { kill(pid, SIGTERM) }
    }
}
