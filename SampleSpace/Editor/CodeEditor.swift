import AppKit
import SwiftUI

/// A code editor for R, Quarto documents or Python: an `NSTextView` with syntax colouring,
/// line numbers, indents (two spaces for R, four for Python) and automatic indentation.
/// Smart quotes and other text substitutions are off, because curly quotes break code.
struct CodeEditor: NSViewRepresentable {
    enum Language { case r, quarto, python }

    @Binding var text: String
    var language: Language = .r
    var fontSize: CGFloat = 13
    var isEditable = true

    func makeCoordinator() -> Coordinator { Coordinator(text: $text, language: language) }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(Theme.editorBackground)
        scrollView.borderType = .noBorder

        let textView = RCodeTextView(usingTextLayoutManager: false)
        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.usesFindBar = true
        textView.isIncrementalSearchingEnabled = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.smartInsertDeleteEnabled = false
        textView.drawsBackground = true
        textView.backgroundColor = NSColor(Theme.editorBackground)
        textView.insertionPointColor = NSColor(Theme.accent)
        textView.selectedTextAttributes = [.backgroundColor: NSColor(Theme.accent).withAlphaComponent(0.3)]
        textView.textContainerInset = NSSize(width: 6, height: 10)
        textView.isEditable = isEditable
        textView.setAccessibilityLabel(language == .quarto ? "Quarto document editor"
                                       : language == .python ? "Python code editor" : "R code editor")
        if language == .python {
            textView.indentUnit = "    "
            textView.opensBlock = [":", "(", "[", "{"]
        }

        // Wrap long lines to the width of the pane.
        textView.minSize = .zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        textView.string = text
        scrollView.documentView = textView

        let ruler = LineNumberRuler(textView: textView, scrollView: scrollView)
        scrollView.verticalRulerView = ruler
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        context.coordinator.textView = textView
        context.coordinator.ruler = ruler
        context.coordinator.fontSize = fontSize
        context.coordinator.highlight()
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(context.coordinator,
                                               selector: #selector(Coordinator.scrolled(_:)),
                                               name: NSView.boundsDidChangeNotification,
                                               object: scrollView.contentView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let coordinator = context.coordinator
        coordinator.text = $text
        guard let textView = coordinator.textView else { return }
        textView.isEditable = isEditable
        if coordinator.fontSize != fontSize {
            coordinator.fontSize = fontSize
            coordinator.highlight()
        }
        if textView.string != text {
            // Replace through the text storage so the change can be undone.
            let all = NSRange(location: 0, length: (textView.string as NSString).length)
            if textView.shouldChangeText(in: all, replacementString: text) {
                textView.replaceCharacters(in: all, with: text)
                textView.didChangeText()
            }
            textView.setSelectedRange(NSRange(location: 0, length: 0))
            coordinator.highlight()
        }
    }

    static func dismantleNSView(_ scrollView: NSScrollView, coordinator: Coordinator) {
        NotificationCenter.default.removeObserver(coordinator)
    }

    @MainActor final class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>
        weak var textView: NSTextView?
        weak var ruler: NSRulerView?
        var fontSize: CGFloat = 13
        let language: Language

        init(text: Binding<String>, language: Language) {
            self.text = text
            self.language = language
        }

        func textDidChange(_ notification: Notification) {
            guard let textView else { return }
            if text.wrappedValue != textView.string { text.wrappedValue = textView.string }
            highlight()
        }

        @objc func scrolled(_ notification: Notification) {
            ruler?.needsDisplay = true
        }

        func highlight() {
            guard let textView, let storage = textView.textStorage else { return }
            let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            let all = NSRange(location: 0, length: storage.length)
            storage.beginEditing()
            storage.setAttributes([.font: font, .foregroundColor: NSColor(Theme.codeText)], range: all)
            let tokens = switch language {
            case .quarto: RSyntax.documentTokens(in: storage.string)
            case .python: PythonSyntax.tokens(in: storage.string)
            case .r: RSyntax.tokens(in: storage.string)
            }
            for token in tokens where NSMaxRange(token.range) <= storage.length {
                storage.addAttribute(.foregroundColor, value: token.kind.nsColor, range: token.range)
            }
            storage.endEditing()
            textView.typingAttributes = [.font: font, .foregroundColor: NSColor(Theme.codeText)]
            (ruler as? LineNumberRuler)?.font = NSFont.monospacedDigitSystemFont(ofSize: fontSize - 2, weight: .regular)
            ruler?.needsDisplay = true
        }
    }
}

// MARK: - Text view

/// Tab inserts one indent (two spaces; four for Python); Return keeps the current line's
/// indent and adds one more after an opening `{` or `(` (for Python, also `:` and `[`).
final class RCodeTextView: NSTextView {
    var indentUnit = "  "
    var opensBlock: Set<Character> = ["{", "("]

    override func insertTab(_ sender: Any?) {
        insertText(indentUnit, replacementRange: selectedRange())
    }

    override func insertNewline(_ sender: Any?) {
        let text = string as NSString
        let cursor = selectedRange().location
        let lineStart = text.lineRange(for: NSRange(location: cursor, length: 0)).location
        let before = text.substring(with: NSRange(location: lineStart, length: cursor - lineStart))
        var indent = String(before.prefix(while: { $0 == " " || $0 == "\t" }))
        let lastChar = before.trimmingCharacters(in: .whitespaces).last
        if let lastChar, opensBlock.contains(lastChar) { indent += indentUnit }
        insertText("\n" + indent, replacementRange: selectedRange())
    }
}

// MARK: - Line numbers

final class LineNumberRuler: NSRulerView {
    private weak var textView: NSTextView?
    var font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        clientView = textView
        ruleThickness = 36
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func drawHashMarksAndLabels(in rect: NSRect) {
        NSColor(Theme.gutterBackground).setFill()
        bounds.fill()

        guard let textView, let layoutManager = textView.layoutManager,
              let container = textView.textContainer else { return }
        let text = textView.string as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: NSColor.white.withAlphaComponent(0.35),
        ]
        let inset = textView.textContainerInset.height

        func draw(_ number: Int, lineRectY: CGFloat, lineHeight: CGFloat) {
            let label = "\(number)" as NSString
            let size = label.size(withAttributes: attributes)
            let y = convert(NSPoint(x: 0, y: lineRectY + inset), from: textView).y
            label.draw(at: NSPoint(x: ruleThickness - size.width - 8, y: y + (lineHeight - size.height) / 2),
                       withAttributes: attributes)
        }

        let visible = textView.visibleRect
        let glyphs = layoutManager.glyphRange(forBoundingRect: visible, in: container)
        let chars = layoutManager.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil)

        // Start at the first visible line, counting the lines above it.
        var index = text.lineRange(for: NSRange(location: chars.location, length: 0)).location
        var number = 1
        text.enumerateSubstrings(in: NSRange(location: 0, length: index),
                                 options: [.byLines, .substringNotRequired]) { _, _, _, _ in number += 1 }

        while index < text.length, index <= NSMaxRange(chars) {
            let lineRange = text.lineRange(for: NSRange(location: index, length: 0))
            let glyph = layoutManager.glyphIndexForCharacter(at: lineRange.location)
            let rect = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: nil)
            draw(number, lineRectY: rect.minY, lineHeight: rect.height)
            number += 1
            index = NSMaxRange(lineRange)
        }
        // The empty last line after a trailing newline (or an empty document).
        let extra = layoutManager.extraLineFragmentRect
        if !extra.isEmpty || text.length == 0 {
            let height = extra.isEmpty ? font.boundingRectForFont.height : extra.height
            draw(number, lineRectY: extra.minY, lineHeight: height)
        }
    }
}
