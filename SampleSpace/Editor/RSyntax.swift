import SwiftUI

/// A small tokenizer for colouring R code. It doesn't parse R; it only finds the pieces
/// worth colouring: comments, strings, numbers, keywords, constants, function names,
/// assignment arrows and other operators. Ranges are UTF-16 (`NSRange`), ready for AppKit.
enum RSyntax {
    enum Kind: Sendable, CaseIterable {
        case comment, string, number, keyword, constant, function, assignment, `operator`
    }

    struct Token: Hashable, Sendable {
        let kind: Kind
        let range: NSRange
    }

    static let keywords: Set<String> = [
        "if", "else", "repeat", "while", "function", "for", "in", "next", "break",
    ]
    static let constants: Set<String> = [
        "TRUE", "FALSE", "NULL", "NA", "NaN", "Inf",
        "NA_integer_", "NA_real_", "NA_character_", "NA_complex_",
    ]

    static func tokens(in code: String) -> [Token] {
        let s = Array(code.utf16)
        var tokens: [Token] = []
        var i = 0

        func add(_ kind: Kind, _ start: Int, _ end: Int) {
            tokens.append(Token(kind: kind, range: NSRange(location: start, length: end - start)))
        }
        func at(_ j: Int) -> UInt16 { j < s.count ? s[j] : 0 }

        while i < s.count {
            let c = s[i]
            switch c {
            case ch("#"):
                let start = i
                while i < s.count, s[i] != ch("\n") { i += 1 }
                add(.comment, start, i)

            case ch("\""), ch("'"), ch("`"):
                let start = i
                i += 1
                while i < s.count, s[i] != c {
                    if s[i] == ch("\\") { i += 1 }
                    i += 1
                }
                i = min(i + 1, s.count)
                // Backtick-quoted names are names, not strings.
                if c != ch("`") { add(.string, start, i) }

            case ch("0")...ch("9"):
                let start = i
                i = scanNumber(s, from: i)
                add(.number, start, i)

            case ch(".") where isDigit(at(i + 1)):
                let start = i
                i = scanNumber(s, from: i)
                add(.number, start, i)

            case _ where isIdentStart(c):
                let start = i
                while i < s.count, isIdentPart(s[i]) { i += 1 }
                let word = String(utf16CodeUnits: Array(s[start..<i]), count: i - start)
                if keywords.contains(word) {
                    add(.keyword, start, i)
                } else if constants.contains(word) {
                    add(.constant, start, i)
                } else {
                    var j = i
                    while j < s.count, s[j] == ch(" ") { j += 1 }
                    if at(j) == ch("(") { add(.function, start, i) }
                }

            case ch("<"):
                if at(i + 1) == ch("<"), at(i + 2) == ch("-") {
                    add(.assignment, i, i + 3); i += 3
                } else if at(i + 1) == ch("-") {
                    add(.assignment, i, i + 2); i += 2
                } else {
                    i += 1
                }

            case ch("-"):
                if at(i + 1) == ch(">"), at(i + 2) == ch(">") {
                    add(.assignment, i, i + 3); i += 3
                } else if at(i + 1) == ch(">") {
                    add(.assignment, i, i + 2); i += 2
                } else {
                    i += 1
                }

            case ch("|") where at(i + 1) == ch(">"):
                add(.operator, i, i + 2); i += 2

            case ch("%"):
                // %in%, %>%, %%, %/% …
                var j = i + 1
                while j < s.count, s[j] != ch("%"), s[j] != ch("\n") { j += 1 }
                if at(j) == ch("%") {
                    add(.operator, i, j + 1); i = j + 1
                } else {
                    i += 1
                }

            case ch("~"):
                add(.operator, i, i + 1); i += 1

            default:
                i += 1
            }
        }
        return tokens
    }

    // MARK: Scanning helpers

    private static func ch(_ c: Unicode.Scalar) -> UInt16 { UInt16(c.value) }

    private static func isDigit(_ c: UInt16) -> Bool { c >= ch("0") && c <= ch("9") }

    private static func isLetter(_ c: UInt16) -> Bool {
        (c >= ch("a") && c <= ch("z")) || (c >= ch("A") && c <= ch("Z")) || c > 127
    }

    private static func isIdentStart(_ c: UInt16) -> Bool { isLetter(c) || c == ch(".") || c == ch("_") }

    private static func isIdentPart(_ c: UInt16) -> Bool { isIdentStart(c) || isDigit(c) }

    private static func scanNumber(_ s: [UInt16], from start: Int) -> Int {
        var i = start
        func at(_ j: Int) -> UInt16 { j < s.count ? s[j] : 0 }
        if at(i) == ch("0"), at(i + 1) == ch("x") || at(i + 1) == ch("X") {
            i += 2
            while i < s.count, isDigit(s[i]) || (s[i] | 0x20 >= ch("a") && s[i] | 0x20 <= ch("f")) { i += 1 }
        } else {
            while i < s.count, isDigit(s[i]) || s[i] == ch(".") { i += 1 }
            if at(i) == ch("e") || at(i) == ch("E") {
                var j = i + 1
                if at(j) == ch("+") || at(j) == ch("-") { j += 1 }
                if isDigit(at(j)) {
                    i = j
                    while i < s.count, isDigit(s[i]) { i += 1 }
                }
            }
        }
        if at(i) == ch("L") || at(i) == ch("i") { i += 1 }
        return i
    }
}

// MARK: - Colours

extension RSyntax.Kind {
    var color: Color {
        switch self {
        case .comment: Color(red: 0.50, green: 0.58, blue: 0.62)
        case .string: Color(red: 1.00, green: 0.66, blue: 0.45)
        case .number, .constant: Color(red: 0.78, green: 0.62, blue: 1.00)
        case .keyword: Color(red: 1.00, green: 0.47, blue: 0.68)
        case .function: Theme.accent
        case .assignment: Theme.gold
        case .operator: Color(red: 0.45, green: 0.90, blue: 0.75)
        }
    }

    var nsColor: NSColor { NSColor(color) }
}

extension RSyntax {
    /// Read-only highlighted code for SwiftUI `Text` (lesson code blocks, the solution).
    static func attributed(_ code: String) -> AttributedString {
        var result = AttributedString(code)
        result.foregroundColor = Theme.codeText
        for token in tokens(in: code) {
            guard let range = Range(token.range, in: result) else { continue }
            result[range].foregroundColor = token.kind.color
        }
        return result
    }
}

// MARK: - Quarto documents

extension RSyntax {
    /// Tokens for a Quarto / R Markdown document: the YAML header and chunk fences are dimmed
    /// like comments, headings stand out, and R is coloured only inside chunks and inline
    /// `` `r ...` `` code, so apostrophes in the prose don't start "strings".
    static func documentTokens(in text: String) -> [Token] {
        let ns = text as NSString
        var tokens: [Token] = []
        var location = 0
        var lineIndex = 0
        var inYAML = false
        var inChunk = false
        var chunkStart = 0

        func addR(_ range: NSRange) {
            guard range.length > 0 else { return }
            for t in RSyntax.tokens(in: ns.substring(with: range)) {
                tokens.append(Token(kind: t.kind, range: NSRange(location: t.range.location + range.location,
                                                                 length: t.range.length)))
            }
        }

        while location < ns.length {
            let lineRange = ns.lineRange(for: NSRange(location: location, length: 0))
            let line = ns.substring(with: lineRange)
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            let contentRange = NSRange(location: lineRange.location,
                                       length: (line.trimmingCharacters(in: .newlines) as NSString).length)
            defer {
                location = NSMaxRange(lineRange)
                lineIndex += 1
            }

            if lineIndex == 0, trimmed == "---" {
                inYAML = true
                tokens.append(Token(kind: .comment, range: contentRange))
                continue
            }
            if inYAML {
                tokens.append(Token(kind: .comment, range: contentRange))
                if trimmed == "---" || trimmed == "..." { inYAML = false }
                continue
            }
            if inChunk {
                if trimmed.hasPrefix("```"), trimmed.allSatisfy({ $0 == "`" }) {
                    addR(NSRange(location: chunkStart, length: lineRange.location - chunkStart))
                    tokens.append(Token(kind: .comment, range: contentRange))
                    inChunk = false
                }
                continue
            }
            if trimmed.hasPrefix("```") {
                tokens.append(Token(kind: .comment, range: contentRange))
                if trimmed.dropFirst(3).trimmingCharacters(in: .init(charactersIn: "` ")).lowercased().hasPrefix("{r") {
                    inChunk = true
                    chunkStart = NSMaxRange(lineRange)
                }
                continue
            }
            if trimmed.hasPrefix("#") {
                tokens.append(Token(kind: .keyword, range: contentRange))
                continue
            }
            // Inline R: `r expression`
            var search = NSRange(location: contentRange.location, length: contentRange.length)
            while search.length > 0 {
                let open = ns.range(of: "`r ", options: [], range: search)
                guard open.location != NSNotFound else { break }
                let afterOpen = NSMaxRange(open)
                let rest = NSRange(location: afterOpen, length: NSMaxRange(contentRange) - afterOpen)
                let close = ns.range(of: "`", options: [], range: rest)
                guard close.location != NSNotFound else { break }
                tokens.append(Token(kind: .function, range: NSRange(location: open.location, length: 2)))
                addR(NSRange(location: afterOpen, length: close.location - afterOpen))
                search = NSRange(location: NSMaxRange(close), length: NSMaxRange(contentRange) - NSMaxRange(close))
            }
        }
        if inChunk { addR(NSRange(location: chunkStart, length: ns.length - chunkStart)) }
        return tokens
    }

    /// Read-only highlighted Quarto source for lesson code blocks.
    static func attributedDocument(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        result.foregroundColor = Theme.codeText
        for token in documentTokens(in: text) {
            guard let range = Range(token.range, in: result) else { continue }
            result[range].foregroundColor = token.kind.color
        }
        return result
    }
}
