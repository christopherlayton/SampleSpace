import SwiftUI

/// A small tokenizer for colouring Python code in Python Wormhole levels, in the same colours
/// as R (`RSyntax.Kind`): comments, strings (including triple-quoted and f-strings), numbers,
/// keywords, `True`/`False`/`None`, function and method names before `(`, and `=` assignments.
/// Like `RSyntax`, it doesn't parse Python. Ranges are UTF-16 (`NSRange`).
enum PythonSyntax {
    static let keywords: Set<String> = [
        "and", "as", "assert", "async", "await", "break", "class", "continue", "def", "del", "elif",
        "else", "except", "finally", "for", "from", "global", "if", "import", "in", "is", "lambda",
        "nonlocal", "not", "or", "pass", "raise", "return", "try", "while", "with", "yield",
    ]
    static let constants: Set<String> = ["True", "False", "None"]
    /// Letters that can start a string literal: f"…", r"…", b"…", rb"…".
    private static let stringPrefixes: Set<String> = ["f", "r", "b", "u", "rb", "br", "fr", "rf"]

    static func tokens(in code: String) -> [RSyntax.Token] {
        let s = Array(code.utf16)
        var tokens: [RSyntax.Token] = []
        var i = 0

        func add(_ kind: RSyntax.Kind, _ start: Int, _ end: Int) {
            tokens.append(RSyntax.Token(kind: kind, range: NSRange(location: start, length: end - start)))
        }
        func at(_ j: Int) -> UInt16 { j < s.count ? s[j] : 0 }

        /// Scans a string starting at its opening quote; returns the index after it.
        func scanString(from quoteAt: Int) -> Int {
            let q = s[quoteAt]
            var j = quoteAt
            if at(j + 1) == q, at(j + 2) == q {
                j += 3
                while j < s.count {
                    if s[j] == ch("\\") { j += 2; continue }
                    if s[j] == q, at(j + 1) == q, at(j + 2) == q { return j + 3 }
                    j += 1
                }
                return s.count
            }
            j += 1
            while j < s.count, s[j] != q, s[j] != ch("\n") {
                if s[j] == ch("\\") { j += 1 }
                j += 1
            }
            return min(j + 1, s.count)
        }

        while i < s.count {
            let c = s[i]
            switch c {
            case ch("#"):
                let start = i
                while i < s.count, s[i] != ch("\n") { i += 1 }
                add(.comment, start, i)

            case ch("\""), ch("'"):
                let start = i
                i = scanString(from: i)
                add(.string, start, i)

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
                if (at(i) == ch("\"") || at(i) == ch("'")), stringPrefixes.contains(word.lowercased()) {
                    i = scanString(from: i)
                    add(.string, start, i)
                } else if keywords.contains(word) {
                    add(.keyword, start, i)
                } else if constants.contains(word) {
                    add(.constant, start, i)
                } else {
                    var j = i
                    while j < s.count, s[j] == ch(" ") { j += 1 }
                    if at(j) == ch("(") { add(.function, start, i) }
                }

            case ch("="):
                // `=` and `+=` style assignments, but not `==`; keyword arguments look the same,
                // which is fine: R colours `=` in calls too.
                if at(i + 1) == ch("=") {
                    i += 2
                } else {
                    add(.assignment, i, i + 1)
                    i += 1
                }

            case ch("+"), ch("-"), ch("*"), ch("/"), ch("%"):
                var j = i + 1
                if (c == ch("*") || c == ch("/")), at(j) == c { j += 1 }
                if at(j) == ch("=") { add(.assignment, i, j + 1); i = j + 1 } else { i = j }

            case ch("!"), ch("<"), ch(">"):
                i += at(i + 1) == ch("=") ? 2 : 1

            case ch("@") where i == 0 || at(i - 1) == ch("\n") || at(i - 1) == ch(" "):
                // Decorators
                let start = i
                i += 1
                while i < s.count, isIdentPart(s[i]) || s[i] == ch(".") { i += 1 }
                add(.operator, start, i)

            default:
                i += 1
            }
        }
        return tokens
    }

    // MARK: Scanning helpers

    private static func ch(_ c: Unicode.Scalar) -> UInt16 { UInt16(c.value) }

    private static func isDigit(_ c: UInt16) -> Bool { c >= ch("0") && c <= ch("9") }

    private static func isIdentStart(_ c: UInt16) -> Bool {
        (c >= ch("a") && c <= ch("z")) || (c >= ch("A") && c <= ch("Z")) || c == ch("_") || c > 127
    }

    private static func isIdentPart(_ c: UInt16) -> Bool { isIdentStart(c) || isDigit(c) }

    private static func scanNumber(_ s: [UInt16], from start: Int) -> Int {
        var i = start
        func at(_ j: Int) -> UInt16 { j < s.count ? s[j] : 0 }
        if at(i) == ch("0"), [ch("x"), ch("X"), ch("o"), ch("O"), ch("b"), ch("B")].contains(at(i + 1)) {
            i += 2
            while i < s.count, isDigit(s[i]) || (s[i] | 0x20 >= ch("a") && s[i] | 0x20 <= ch("f")) || s[i] == ch("_") { i += 1 }
            return i
        }
        while i < s.count, isDigit(s[i]) || s[i] == ch(".") || s[i] == ch("_") { i += 1 }
        if at(i) == ch("e") || at(i) == ch("E") {
            var j = i + 1
            if at(j) == ch("+") || at(j) == ch("-") { j += 1 }
            if isDigit(at(j)) {
                i = j
                while i < s.count, isDigit(s[i]) { i += 1 }
            }
        }
        if at(i) == ch("j") || at(i) == ch("J") { i += 1 }
        return i
    }
}

extension RSyntax {
    /// Tokens for code in either language.
    static func tokens(in code: String, language: CodeLanguage) -> [Token] {
        language == .python ? PythonSyntax.tokens(in: code) : tokens(in: code)
    }

    /// Read-only highlighted code in either language.
    static func attributed(_ code: String, language: CodeLanguage) -> AttributedString {
        var result = AttributedString(code)
        result.foregroundColor = Theme.codeText
        for token in tokens(in: code, language: language) {
            guard let range = Range(token.range, in: result) else { continue }
            result[range].foregroundColor = token.kind.color
        }
        return result
    }
}
