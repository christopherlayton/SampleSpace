import Foundation

/// What SPSS would show for the analysis an SPSS Translate level asks you to redo in R, from the
/// `spss` object in level.json:
///
///     "spss": {
///       "menu": ["Analyze", "Descriptive Statistics", "Frequencies…"],
///       "dialog": [ { "label": "Variable(s)", "value": "Teaching method [method]" } ],
///       "syntax": "FREQUENCIES VARIABLES=method\n  /ORDER=ANALYSIS.",
///       "output": [
///         { "title": "Teaching method",
///           "columns": ["", "", "Frequency", "Percent", "Valid Percent", "Cumulative Percent"],
///           "row_header_columns": 2,
///           "rows": [["Valid", "Lecture", "15", "50.0", "50.0", "50.0"], …],
///           "footnotes": ["a. …"] }
///       ]
///     }
///
/// Every number in an output table must come from R (the lesson says which call), because the
/// learner's R is checked against the same values.
struct SPSSPanel: Hashable, Sendable, Decodable {
    var menu: [String] = []
    var dialog: [SPSSSetting]?
    var syntax: String?
    var output: [SPSSTable] = []
}

/// One setting in the SPSS dialog, e.g. "Test Variable(s): Final exam score [score]".
struct SPSSSetting: Hashable, Sendable, Decodable {
    let label: String
    let value: String
}

/// One pivot table from the SPSS Output Viewer.
struct SPSSTable: Hashable, Sendable, Decodable {
    let title: String
    /// Column headings. Row-header columns usually have an empty heading.
    let columns: [String]
    /// A spanning heading row above `columns`: pairs of (text, number of columns).
    var groups: [SPSSHeaderGroup]?
    let rows: [[String]]
    /// How many leading columns are row labels (left-aligned, no gridlines between repeats).
    var rowHeaderColumns: Int?
    var footnotes: [String]?

    var headerColumns: Int { rowHeaderColumns ?? 1 }
}

struct SPSSHeaderGroup: Hashable, Sendable, Decodable {
    let text: String
    let span: Int
}
