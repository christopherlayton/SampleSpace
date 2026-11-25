import AppKit
import SwiftUI

/// The app's settings, kept in UserDefaults (so `@AppStorage` views and the Settings window
/// share them). Change them in Settings (⌘,).
enum Preferences {
    static let soundsEnabled = "soundsEnabled"
    static let codeFontSize = "codeFontSize"
    static let lessonFontSize = "lessonFontSize"
    static let animatedBackground = "animatedBackground"
    /// A custom Rscript path; empty means "find it" (`REngine.rscriptCandidates`).
    static let rscriptPath = "rscriptPath"
    /// A custom quarto path; empty means "find it" (`QuartoRenderer.candidates`).
    static let quartoPath = "quartoPath"
    static let hasSeenOnboarding = "hasSeenOnboarding"

    static let codeFontRange: ClosedRange<Double> = 10...22
    static let lessonFontRange: ClosedRange<Double> = 11...22
    static let defaultCodeFontSize = 13.0
    static let defaultLessonFontSize = 13.0

    static func register() {
        UserDefaults.standard.register(defaults: [
            soundsEnabled: true,
            codeFontSize: defaultCodeFontSize,
            lessonFontSize: defaultLessonFontSize,
            animatedBackground: true,
        ])
    }

    static var customRscriptPath: String? { nonEmpty(UserDefaults.standard.string(forKey: rscriptPath)) }
    static var customQuartoPath: String? { nonEmpty(UserDefaults.standard.string(forKey: quartoPath)) }

    private static func nonEmpty(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespaces), !s.isEmpty else { return nil }
        return (s as NSString).expandingTildeInPath
    }
}

// MARK: - Text sizes

private struct CodeFontSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = Preferences.defaultCodeFontSize
}

private struct LessonFontSizeKey: EnvironmentKey {
    static let defaultValue: CGFloat = Preferences.defaultLessonFontSize
}

extension EnvironmentValues {
    /// Point size for code: the editor, the console and code blocks.
    var codeFontSize: CGFloat {
        get { self[CodeFontSizeKey.self] }
        set { self[CodeFontSizeKey.self] = newValue }
    }

    /// Point size for lesson text.
    var lessonFontSize: CGFloat {
        get { self[LessonFontSizeKey.self] }
        set { self[LessonFontSizeKey.self] = newValue }
    }
}

extension Theme {
    static func code(_ size: CGFloat) -> Font { .system(size: size, design: .monospaced) }
}

// MARK: - Sounds

/// Short sound cues: a check passed or failed, a Boss step cleared, a level charted, a badge,
/// a promotion, and Review Nebula answers. They use the system's own alert sounds, quietly, and
/// can be switched off in Settings.
@MainActor
enum SoundEffects {
    enum Cue {
        case checkPassed, checkFailed, stepCleared, levelCleared, badge, promotion, reviewRight, reviewWrong

        var soundName: String {
            switch self {
            case .checkPassed: "Glass"
            case .checkFailed: "Bottle"
            case .stepCleared: "Pop"
            case .levelCleared: "Hero"
            case .badge: "Purr"
            case .promotion: "Submarine"
            case .reviewRight: "Tink"
            case .reviewWrong: "Bottle"
            }
        }

        var volume: Float {
            switch self {
            case .levelCleared, .promotion: 0.5
            default: 0.35
            }
        }
    }

    private static var cache: [String: NSSound] = [:]

    static func play(_ cue: Cue) {
        guard UserDefaults.standard.bool(forKey: Preferences.soundsEnabled) else { return }
        let name = cue.soundName
        let sound = cache[name] ?? NSSound(named: NSSound.Name(name))
        guard let sound else { return }
        cache[name] = sound
        sound.stop()
        sound.volume = cue.volume
        sound.play()
    }
}
