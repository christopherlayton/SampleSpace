import Foundation

/// The block-level Markdown used in lesson.md files, split into blocks the lesson view can
/// lay out. Inline formatting (bold, italics, `code`, links) stays in the text and is
/// rendered later with `AttributedString(markdown:)`.
///
/// Supported: `#` headings, paragraphs, fenced code blocks (longer fences nest shorter ones), `-`/`*` and `1.` lists,
/// `>` quotes, pipe tables and `---` rules. A line that is only `{{name}}` is a placeholder
/// where the lesson view inserts something of its own (e.g. `{{spss}}` for the SPSS panel).
enum MarkdownBlock: Hashable, Sendable {
    case heading(level: Int, text: String)
    case paragraph(String)
    case code(String, language: String?)
    case bullets([String])
    case numbered([String])
    case quote(String)
    case table(header: [String], rows: [[String]])
    case rule
    case placeholder(String)

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        let lines = markdown.replacingOccurrences(of: "\r\n", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var i = 0

        func flushParagraph() {
            if !paragraph.isEmpty { blocks.append(.paragraph(paragraph.joined(separator: " "))) }
            paragraph = []
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                flushParagraph()
                // A fence of N backticks closes only on a line of at least N backticks, so a
                // ```` block can show a Quarto document with ``` chunks inside it.
                let fence = trimmed.prefix { $0 == "`" }.count
                let language = String(trimmed.dropFirst(fence)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                func closes(_ line: String) -> Bool {
                    let t = line.trimmingCharacters(in: .whitespaces)
                    return t.count >= fence && t.allSatisfy { $0 == "`" }
                }
                while i < lines.count, !closes(lines[i]) {
                    code.append(lines[i])
                    i += 1
                }
                blocks.append(.code(code.joined(separator: "\n"), language: language.isEmpty ? nil : language))
                i += 1
                continue
            }

            if trimmed.isEmpty {
                flushParagraph()
            } else if trimmed.hasPrefix("{{"), trimmed.hasSuffix("}}"), trimmed.count > 4 {
                flushParagraph()
                blocks.append(.placeholder(String(trimmed.dropFirst(2).dropLast(2)).trimmingCharacters(in: .whitespaces)))
            } else if let level = headingLevel(trimmed) {
                flushParagraph()
                blocks.append(.heading(level: level, text: String(trimmed.dropFirst(level + 1))))
            } else if trimmed == "---" || trimmed == "***" {
                flushParagraph()
                blocks.append(.rule)
            } else if trimmed.hasPrefix(">") {
                flushParagraph()
                var quote: [String] = []
                while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    quote.append(lines[i].trimmingCharacters(in: .whitespaces).dropFirst()
                        .trimmingCharacters(in: .whitespaces))
                    i += 1
                }
                blocks.append(.quote(quote.joined(separator: " ")))
                continue
            } else if trimmed.hasPrefix("|") {
                flushParagraph()
                var rows: [[String]] = []
                while i < lines.count, lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                    let row = lines[i].trimmingCharacters(in: .whitespaces)
                    if !isTableSeparator(row) { rows.append(tableCells(row)) }
                    i += 1
                }
                if let header = rows.first { blocks.append(.table(header: header, rows: Array(rows.dropFirst()))) }
                continue
            } else if let item = listItem(trimmed) {
                flushParagraph()
                let ordered = item.ordered
                var items = [item.text]
                i += 1
                while i < lines.count {
                    let next = lines[i]
                    let nextTrimmed = next.trimmingCharacters(in: .whitespaces)
                    if let more = listItem(nextTrimmed), more.ordered == ordered {
                        items.append(more.text)
                    } else if !nextTrimmed.isEmpty, next.hasPrefix(" ") {
                        items[items.count - 1] += " " + nextTrimmed   // wrapped continuation line
                    } else {
                        break
                    }
                    i += 1
                }
                blocks.append(ordered ? .numbered(items) : .bullets(items))
                continue
            } else {
                paragraph.append(trimmed)
            }
            i += 1
        }
        flushParagraph()
        return blocks
    }

    private static func headingLevel(_ line: String) -> Int? {
        let hashes = line.prefix(while: { $0 == "#" }).count
        guard (1...6).contains(hashes), line.dropFirst(hashes).first == " " else { return nil }
        return hashes
    }

    private static func listItem(_ line: String) -> (ordered: Bool, text: String)? {
        if line.hasPrefix("- ") || line.hasPrefix("* ") {
            return (false, String(line.dropFirst(2)))
        }
        let digits = line.prefix(while: \.isNumber)
        if !digits.isEmpty, line.dropFirst(digits.count).hasPrefix(". ") {
            return (true, String(line.dropFirst(digits.count + 2)))
        }
        return nil
    }

    private static func isTableSeparator(_ row: String) -> Bool {
        row.allSatisfy { "|-: ".contains($0) }
    }

    private static func tableCells(_ row: String) -> [String] {
        // `\|` is a literal pipe inside a cell (e.g. the `|>` operator).
        let placeholder = "\u{0}"
        var body = row.replacingOccurrences(of: "\\|", with: placeholder)
        if body.hasPrefix("|") { body.removeFirst() }
        if body.hasSuffix("|") { body.removeLast() }
        return body.split(separator: "|", omittingEmptySubsequences: false).map {
            $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: placeholder, with: "|")
        }
    }
}

extension AttributedString {
    /// Inline Markdown (bold, italics, `code`, links) for lesson text, hints and check labels.
    /// Inline code is tinted so it stands out on the dark background.
    static func inlineMarkdown(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        var result = (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
        for run in result.runs where run.inlinePresentationIntent?.contains(.code) == true {
            result[run.range].foregroundColor = Theme.accent
        }
        return result
    }
}
