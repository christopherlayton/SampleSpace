import Foundation

/// Plain-English explanations for the R (and Python) errors beginners hit most often.
///
/// The console still shows R's own message (learning to read those is part of learning R);
/// the explanation appears underneath it. Returns Markdown with inline code only.
enum ErrorExplainer {
    static func explain(_ entry: ConsoleEntry, language: CodeLanguage = .r) -> String? {
        guard entry.kind == .error else { return nil }
        return language == .python ? explainPython(message: entry.text) : explain(message: entry.text)
    }

    static func explain(message: String) -> String? {
        let text = message

        if let name = capture(#"object '([^']+)' not found"#, in: text) {
            return "R doesn't have an object called `\(name)`. Check the spelling (names are "
                + "case-sensitive) and that the line that creates it comes before this one."
        }
        if let name = capture(#"could not find function "([^"]+)""#, in: text) {
            return "R doesn't know a function called `\(name)()`. Check the spelling. If it comes "
                + "from a package, load the package first with `library()`."
        }
        if let name = capture(#"there is no package called [‘']([^’']+)[’']"#, in: text) {
            return "The package `\(name)` isn't installed in this Mac's R. Check the spelling of its name."
        }
        if let name = capture(#"argument "([^"]+)" is missing, with no default"#, in: text) {
            return "A function needed its `\(name)` argument, but it wasn't given one."
        }
        if text.contains("unused argument") {
            return "A function was given an argument it doesn't have. Check the argument names "
                + "with `args()`, for example `args(round)`."
        }
        if text.contains("non-numeric argument to binary operator") {
            return "You did arithmetic with something that isn't a number, such as text in quotes. "
                + "`class()` tells you what type a value is."
        }
        if text.contains("R couldn't read your code") {
            return explainParseError(text)
        }
        if text.contains("cannot open file") || text.contains("No such file or directory")
            || text.contains("does not exist in current working directory") {
            return "R couldn't find that file. Check the file name, including its extension and capitals."
        }
        if text.contains("subscript out of bounds") {
            return "You asked for a position that doesn't exist, like the 10th item of something with 5."
        }
        if text.contains("arguments imply differing number of rows") {
            return "The columns you combined have different lengths. Every column of a data frame "
                + "needs one value per row."
        }
        if text.contains("missing value where TRUE/FALSE needed") {
            return "An `if` got `NA` instead of `TRUE` or `FALSE`. Check for missing values in the condition."
        }
        return nil
    }

    private static func explainParseError(_ text: String) -> String {
        let line = capture(#"line (\d+)"#, in: text).map { " on line \($0)" } ?? ""
        if text.contains("unexpected end of input") {
            return "Your code stops part-way through something: a `(`, `{`, `[` or quote was opened "
                + "but never closed."
        }
        if text.contains("unexpected INCOMPLETE_STRING") {
            return "A quote was opened\(line) but never closed. Every `\"` needs a partner."
        }
        if text.contains("unexpected input") {
            return "R found a character it can't read\(line). Curly quotes (“ ” ‘ ’) pasted from a "
                + "document are a common cause: retype them as straight quotes (\" or ')."
        }
        if text.contains("unexpected symbol") || text.contains("unexpected numeric constant")
            || text.contains("unexpected string constant") {
            return "R found two things side by side with nothing joining them\(line). Look for a "
                + "missing comma, operator or bracket, or a name with a space in it."
        }
        if let token = capture(#"unexpected '([^']+)'"#, in: text) {
            if token == "=" {
                return "R didn't expect `=`\(line). To test whether two values are equal, use `==`."
            }
            return "R didn't expect `\(token)`\(line). Check that brackets and parentheses pair up "
                + "and that nothing is left over."
        }
        if text.contains("unexpected assignment") {
            return "There's an assignment (`=` or `<-`) where R didn't expect one\(line). To compare "
                + "two values use `==`."
        }
        return "R couldn't make sense of the code\(line). The `^` under the line points at where it got stuck."
    }

    // MARK: Python

    /// Usual import lines for the short names the Python levels use.
    static let pythonImports: [String: String] = [
        "pd": "import pandas as pd", "np": "import numpy as np", "plt": "import matplotlib.pyplot as plt",
        "sns": "import seaborn as sns", "stats": "from scipy import stats", "smf": "import statsmodels.formula.api as smf",
        "sm": "import statsmodels.api as sm", "pyreadstat": "import pyreadstat",
    ]

    static func explainPython(message text: String) -> String? {
        if text.hasPrefix("Python couldn't read your code") { return explainPythonSyntax(text) }
        if let name = capture(#"NameError: name '([^']+)' is not defined"#, in: text) {
            if let line = pythonImports[name] {
                return "`\(name)` is the usual short name for a library, but it hasn't been imported yet. "
                    + "Put `\(line)` at the top, above the first line that uses it."
            }
            return "Python doesn't have a variable called `\(name)`. Check the spelling (names are "
                + "case-sensitive) and that the line that creates it comes before this one."
        }
        if let name = capture(#"No module named '([^']+)'"#, in: text) {
            return "Python can't find a library called `\(name)`. Check the spelling; if it is right, the "
                + "library isn't installed in the Python this app uses (Settings → R & Python shows which)."
        }
        if let key = capture(#"^KeyError: (.+)$"#, in: text) {
            return "There's no column (or key) called \(key). Column names are case-sensitive: "
                + "`df.columns` lists them."
        }
        if let (type, attr) = capturePair(#"'([^']+)' object has no attribute '([^']+)'"#, in: text) {
            return "A \(type) doesn't have anything called `.\(attr)`. Check the spelling; for a "
                + "column, `df[\"\(attr)\"]` always works."
        }
        if text.contains("object is not subscriptable"), text.contains("'method'") {
            return "Square brackets went straight after a method's name. Call the method first, with "
                + "`()`, then index what it returns: `df.head()[\"col\"]`, not `df.head[\"col\"]`."
        }
        if text.contains("object is not callable") {
            return "Something that isn't a function was called with `()`. Did a variable reuse a "
                + "function's name (like `sum = ...` or `mean = ...`)?"
        }
        if text.contains("list index out of range") || text.contains("index out of range")
            || text.contains("out of bounds for axis") {
            return "That position doesn't exist. Python counts from 0, so a list of 5 has positions 0 to 4."
        }
        if text.contains("unsupported operand type") || text.contains("can only concatenate str") {
            return "You did arithmetic with something that isn't a number, such as text in quotes. "
                + "`type()` tells you what something is."
        }
        if text.hasPrefix("FileNotFoundError") {
            return "Python couldn't find that file. Check the file name, including its extension and capitals."
        }
        if text.contains("could not convert string to float") {
            return "Some text couldn't be turned into a number. `pd.to_numeric(col, errors=\"coerce\")` "
                + "turns unreadable values into `NaN` instead."
        }
        if text.contains("positional argument") || text.contains("unexpected keyword argument") {
            return "A function got arguments it doesn't take (or is missing one). `help(function)` lists them."
        }
        return nil
    }

    private static func explainPythonSyntax(_ text: String) -> String {
        if text.contains("IndentationError") || text.contains("unexpected indent") || text.contains("unindent") {
            return "Python uses indentation to group lines: the lines inside a `for`, `if` or `def` are "
                + "indented by the same amount (four spaces), and other lines aren't indented at all."
        }
        if text.contains("Maybe you meant '==' or ':=' instead of '='") || text.contains("cannot assign to") {
            return "There's a `=` where Python expected a comparison. To test whether two values are equal, use `==`."
        }
        if text.contains("invalid character") {
            return "Python found a character it can't read. Curly quotes (“ ” ‘ ’) pasted from a document are a "
                + "common cause: retype them as straight quotes (\" or ')."
        }
        if text.contains("unterminated string") || text.contains("unterminated triple-quoted") {
            return "A quote was opened but never closed. Every `\"` needs a partner on the same line."
        }
        if text.contains("was never closed") || text.contains("unexpected EOF") {
            return "A `(`, `[` or `{` was opened but never closed."
        }
        if text.contains("expected ':'") {
            return "Lines that start a block (`for`, `if`, `def`, `while`) end with a colon `:`."
        }
        if text.contains("Perhaps you forgot a comma") {
            return "Two things sit side by side with nothing joining them: a comma is probably missing."
        }
        return "Python couldn't make sense of the code. The `^` under the line points at where it got stuck."
    }

    private static func capturePair(_ pattern: String, in text: String) -> (String, String)? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 2,
              let a = Range(match.range(at: 1), in: text), let b = Range(match.range(at: 2), in: text) else { return nil }
        return (String(text[a]), String(text[b]))
    }

    private static func capture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
