import Foundation

/// A minimal CSV reader for lab data files: a header row, comma-separated fields, double quotes
/// around fields that contain commas, quotes or line breaks (`""` is a literal quote).
struct CSVTable: Sendable {
    let header: [String]
    let rows: [[String]]

    init(text: String) {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false
        var chars = Array(text.unicodeScalars)[...]
        if chars.first == "\u{FEFF}" { chars = chars.dropFirst() }
        var i = chars.startIndex
        while i < chars.endIndex {
            let c = chars[i]
            if inQuotes {
                if c == "\"" {
                    let next = chars.index(after: i)
                    if next < chars.endIndex, chars[next] == "\"" {
                        field.unicodeScalars.append("\"")
                        i = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.unicodeScalars.append(c)
                }
            } else {
                switch c {
                case "\"": inQuotes = true
                case ",":
                    record.append(field)
                    field = ""
                case "\n", "\r":
                    // "\r\n" counts once: skip the "\n" that follows a "\r".
                    if c == "\r" {
                        let next = chars.index(after: i)
                        if next < chars.endIndex, chars[next] == "\n" { i = next }
                    }
                    record.append(field)
                    field = ""
                    records.append(record)
                    record = []
                default:
                    field.unicodeScalars.append(c)
                }
            }
            i = chars.index(after: i)
        }
        if !field.isEmpty || !record.isEmpty {
            record.append(field)
            records.append(record)
        }
        header = records.first ?? []
        rows = Array(records.dropFirst()).filter { $0 != [""] }
    }

    init(contentsOf url: URL) throws {
        self.init(text: try String(contentsOf: url, encoding: .utf8))
    }

    /// The numeric values of a column; blanks and `NA` are skipped.
    func numbers(in column: String) -> [Double]? {
        guard let index = header.firstIndex(of: column) else { return nil }
        return rows.compactMap { row in
            index < row.count ? Double(row[index].trimmingCharacters(in: .whitespaces)) : nil
        }
    }
}
