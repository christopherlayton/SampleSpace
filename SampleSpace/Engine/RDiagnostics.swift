import Foundation

/// A quick "ship systems check": which R and Quarto the app will use, the R version, and which
/// of the packages the levels need are missing; also which Python the optional Python Wormhole
/// uses and which of its libraries are missing. Shown in the welcome tour and in Settings.
struct RDiagnostics: Sendable, Equatable {
    /// Packages the levels load (PLAN.md §4), plus knitr and rmarkdown for Quarto documents.
    static let packages = ["tidyverse", "jsonlite", "psych", "car", "effectsize", "rstatix", "afex",
                           "haven", "palmerpenguins", "broom", "knitr", "rmarkdown", "quarto"]

    var rscriptPath: String?
    var rVersion: String?
    var missingPackages: [String] = []
    var quartoPath: String?
    var quartoVersion: String?
    var problem: String?
    var pythonPath: String?
    var pythonVersion: String?
    var missingPythonPackages: [String] = []

    /// Libraries the Python Wormhole levels import (pip names).
    static let pythonPackages = ["numpy", "pandas", "scipy", "statsmodels", "matplotlib", "seaborn", "pyreadstat"]

    var rReady: Bool { rVersion != nil && missingPackages.isEmpty }
    var pythonReady: Bool { pythonVersion != nil && missingPythonPackages.isEmpty }

    /// The Terminal command that installs the missing Python libraries.
    var pythonInstallCommand: String? {
        guard let pythonPath, !missingPythonPackages.isEmpty else { return nil }
        return "\(pythonPath) -m pip install \(missingPythonPackages.joined(separator: " "))"
    }

    /// The command that installs whatever is missing.
    var installCommand: String? {
        guard !missingPackages.isEmpty else { return nil }
        let list = missingPackages.map { "\"\($0)\"" }.joined(separator: ",")
        return "install.packages(c(\(list)), repos = \"https://cloud.r-project.org\")"
    }

    static func run(rscriptPath: String?, quartoPath: String?, pythonPath: String? = nil) async -> RDiagnostics {
        var result = RDiagnostics()
        let fm = FileManager.default
        let pCandidates = pythonPath.map { [$0] } ?? REngine.pythonCandidates
        if let python = pCandidates.first(where: { fm.isExecutableFile(atPath: $0) }) {
            result.pythonPath = python
            let names = pythonPackages.map { "\"\($0)\"" }.joined(separator: ",")
            let code = """
                import sys, importlib.util
                print(sys.version.split()[0])
                print(",".join(p for p in [\(names)] if importlib.util.find_spec(p) is None))
                """
            if let output = await Self.capture(python, ["-c", code], timeout: 30) {
                let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
                result.pythonVersion = lines.first.flatMap { $0.isEmpty ? nil : "Python \($0)" }
                let missing = lines.dropFirst().joined().trimmingCharacters(in: .whitespacesAndNewlines)
                result.missingPythonPackages = missing.isEmpty ? [] : missing.split(separator: ",").map(String.init)
            }
        }
        let rCandidates = rscriptPath.map { [$0] } ?? REngine.rscriptCandidates
        guard let rscript = rCandidates.first(where: { fm.isExecutableFile(atPath: $0) }) else {
            result.problem = "Couldn't find Rscript at \(rCandidates.joined(separator: ", "))."
            return result
        }
        result.rscriptPath = rscript
        let code = """
            cat(R.version.string, "\\n")
            pk <- c(\(packages.map { "\"\($0)\"" }.joined(separator: ",")))
            ok <- vapply(pk, function(p) suppressWarnings(requireNamespace(p, quietly = TRUE)), TRUE)
            cat(pk[!ok], sep = ",")
            """
        if let output = await Self.capture(rscript, ["--no-init-file", "-e", code], timeout: 60) {
            let lines = output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            result.rVersion = lines.first.map { $0.trimmingCharacters(in: .whitespaces) }.flatMap { $0.hasPrefix("R version") ? $0 : nil }
            if result.rVersion == nil { result.problem = "Rscript ran but didn't report a version:\n\(output.prefix(400))" }
            let missing = lines.dropFirst().joined().trimmingCharacters(in: .whitespacesAndNewlines)
            result.missingPackages = missing.isEmpty ? [] : missing.split(separator: ",").map(String.init)
        } else {
            result.problem = "Rscript at \(rscript) didn't respond."
        }
        let qCandidates = quartoPath.map { [$0] } ?? QuartoRenderer.candidates
        if let quarto = qCandidates.first(where: { fm.isExecutableFile(atPath: $0) }) {
            result.quartoPath = quarto
            result.quartoVersion = await Self.capture(quarto, ["--version"], timeout: 20)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return result
    }

    /// Runs a command and returns its standard output, or nil if it failed or timed out.
    private static func capture(_ path: String, _ arguments: [String], timeout: Double) async -> String? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let process = Process()
                process.executableURL = URL(filePath: path)
                process.arguments = arguments
                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = FileHandle.nullDevice
                process.standardInput = FileHandle.nullDevice
                do { try process.run() } catch {
                    continuation.resume(returning: nil)
                    return
                }
                let deadline = DispatchTime.now() + timeout
                DispatchQueue.global().asyncAfter(deadline: deadline) { if process.isRunning { process.terminate() } }
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                continuation.resume(returning: process.terminationStatus == 0 ? String(decoding: data, as: UTF8.self) : nil)
            }
        }
    }
}
