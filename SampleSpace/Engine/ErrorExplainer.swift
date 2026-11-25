import Foundation

/// Plain-English explanations for the R errors beginners hit most often.
///
/// The console still shows R's own message (learning to read those is part of learning R);
/// the explanation appears underneath it. Returns Markdown with inline code only.
enum ErrorExplainer {
    static func explain(_ entry: ConsoleEntry) -> String? {
        guard entry.kind == .error else { return nil }
        return explain(message: entry.text)
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

    private static func capture(_ pattern: String, in text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }
}
