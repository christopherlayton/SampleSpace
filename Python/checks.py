# Sample Space check helpers for Python levels: the twin of R/checks.R.
#
# A Python level's check.py is plain Python that calls these helpers. Each call adds one line
# to the checklist the learner sees. The learner's variables are available by name, e.g.
#   expect_true(mean_hours > 1000, label="`mean_hours` is above 1,000")
#
# Every helper takes:
#   label   — what is being checked (shown in the checklist; a default is generated)
#   message — friendly feedback shown when the check fails (a default is generated)
#
# Helpers:
#   expect_object(name, value, tolerance)  — variable exists (and equals value)
#   expect_type(name, kind)                — variable is of a type: a class, or a name such as
#                                            "DataFrame", "Series", "list", "dict", "float"
#   expect_equal(actual, expected, tolerance) — any value equals expected
#   expect_true(condition)                 — any condition is true
#   expect_called(fn)                      — the code calls fn, e.g. "mean", "ttest_ind" or
#                                            "stats.ttest_ind" (methods count: "groupby")
#   expect_not_called(fn)                  — the code does not call fn
#   expect_imported(module)                — the code imports module, e.g. "pandas"
#   expect_output(pattern, fixed)          — console output matches a regular expression
#   expect_printed(value)                  — the console shows value (its repr, or the string
#                                            itself) on lines of its own
#   expect_plot(n = 1)                     — at least n figures were drawn
#   expect_no_error()                      — the code ran without an error
#   expect_contains(text, fragment)        — a string contains fragment (for APA sentences)
#   plot_label(which, plot = 1)            — a figure's "x"/"y" axis label or "title"
#   get_object(name)                       — the learner's variable, or None
#   learner_code()                         — the learner's code as one string
#   output_text()                          — everything printed, as one string
#   apa_num(x, digits = 2, lead = True)    — x rounded for APA; lead=False drops the leading
#                                            zero (for p, r, η² and other values below 1)
#   apa_p(p)                               — "p = .034" or "p < .001"
#
# Boss levels:
#   step(n)                                — the checks that follow belong to step n
#
# This file is run by runner.py in a namespace that also holds `ss`, the run state.

import ast as _ast
import math as _math
import re as _re

_MISSING = object()


def _record(passed, label, message):
    passed = bool(passed)
    ss.checks.append({"passed": passed, "label": label, "message": None if passed else message,
                      "internal": False, "step": ss.step})
    return passed


def step(n):
    ss.step = int(n)


def get_object(name):
    return ss.learner.get(name)


def learner_code():
    return ss.code


def output_text():
    return ss.output_text()


def _short(x, width=60):
    try:
        text = repr(x)
    except Exception:
        text = type(x).__name__
    text = " ".join(text.split())
    return text if len(text) <= width else text[: width - 1] + "…"


def _type_name(x):
    name = type(x).__name__
    return {"float64": "float", "int64": "int", "str": "string"}.get(name, name)


def _numbers(x):
    """x as a flat list of floats, or None if it isn't numeric."""
    try:
        import numpy as np
    except ImportError:
        np = None
    if isinstance(x, bool):
        return [float(x)]
    if isinstance(x, (int, float)):
        return [float(x)]
    if np is not None:
        if isinstance(x, np.generic):
            try:
                return [float(x)]
            except (TypeError, ValueError):
                return None
        values = getattr(x, "values", x)  # pandas Series / DataFrame
        if isinstance(values, np.ndarray) or isinstance(x, (list, tuple)):
            try:
                arr = np.asarray(values, dtype=float)
            except (TypeError, ValueError):
                return None
            return [float(v) for v in arr.ravel()]
    elif isinstance(x, (list, tuple)):
        try:
            return [float(v) for v in x]
        except (TypeError, ValueError):
            return None
    return None


def _close(a, b, tolerance):
    if _math.isnan(a) and _math.isnan(b):
        return True
    return _math.isclose(a, b, rel_tol=tolerance, abs_tol=tolerance)


def _same(actual, expected, tolerance):
    if isinstance(expected, str) or isinstance(actual, str):
        return isinstance(actual, str) and actual == expected
    if isinstance(expected, dict):
        return (isinstance(actual, dict) and set(actual) == set(expected)
                and all(_same(actual[k], expected[k], tolerance) for k in expected))
    a, e = _numbers(actual), _numbers(expected)
    if a is not None and e is not None:
        return len(a) == len(e) and all(_close(x, y, tolerance) for x, y in zip(a, e))
    if isinstance(expected, (list, tuple)) and isinstance(actual, (list, tuple)):
        return len(actual) == len(expected) and all(_same(x, y, tolerance) for x, y in zip(actual, expected))
    try:
        return bool(actual == expected)
    except Exception:
        return False


def _length(x):
    try:
        return len(x)
    except TypeError:
        return None


def _mismatch(what, actual, expected):
    a_num, e_num = _numbers(actual) is not None, _numbers(expected) is not None
    if type(actual) is not type(expected) and not (a_num and e_num):
        return f"{what} is a {_type_name(actual)}, but a {_type_name(expected)} was expected."
    la, le = _length(actual), _length(expected)
    if la is not None and le is not None and la != le and not isinstance(expected, str):
        return f"{what} has {la} item{'' if la == 1 else 's'}, but {le} {'was' if le == 1 else 'were'} expected."
    return f"{what} isn't quite right yet. It is currently: {_short(actual)}"


def expect_object(name, value=_MISSING, tolerance=1e-6, label=None, message=None):
    has_value = value is not _MISSING
    if label is None:
        label = f"`{name}` has the right value" if has_value else f"`{name}` exists"
    if name not in ss.learner:
        return _record(False, label, message or
                       f"There is no variable called `{name}` yet. Create it with `{name} = ...` "
                       "(Python names are case-sensitive).")
    if not has_value:
        return _record(True, label, None)
    actual = ss.learner[name]
    return _record(_same(actual, value, tolerance), label, message or _mismatch(f"`{name}`", actual, value))


def expect_type(name, kind, label=None, message=None):
    kind_name = kind if isinstance(kind, str) else kind.__name__
    label = label or f"`{name}` is a {kind_name}"
    if name not in ss.learner:
        return _record(False, label, message or f"There is no variable called `{name}` yet.")
    actual = ss.learner[name]
    if isinstance(kind, str):
        ok = any(c.__name__ == kind for c in type(actual).__mro__)
    else:
        ok = isinstance(actual, kind)
    return _record(ok, label, message or f"`{name}` is a {_type_name(actual)}, not a {kind_name}.")


def expect_equal(actual, expected, tolerance=1e-6, label=None, message=None):
    label = label or f"The value is {_short(expected)}"
    return _record(_same(actual, expected, tolerance), label, message or _mismatch("The value", actual, expected))


def expect_true(condition, label="Condition holds", message=None):
    try:
        ok = bool(condition)
    except Exception:
        ok = False
    return _record(ok, label, message or "This isn't true yet.")


def _calls():
    """Dotted names of every call in the learner's code: `stats.ttest_ind`, `log.groupby`, `len`."""
    try:
        tree = _ast.parse(ss.code)
    except SyntaxError:
        return []
    names = []

    def dotted(node):
        if isinstance(node, _ast.Name):
            return node.id
        if isinstance(node, _ast.Attribute):
            inner = dotted(node.value)
            return f"{inner}.{node.attr}" if inner else node.attr
        if isinstance(node, _ast.Call):
            return dotted(node.func)
        if isinstance(node, _ast.Subscript):
            return dotted(node.value)
        return ""

    for node in _ast.walk(tree):
        if isinstance(node, _ast.Call):
            names.append(dotted(node.func))
    return names


def _matches_call(name, fn):
    return name == fn or name.endswith("." + fn)


def expect_called(fn, label=None, message=None):
    label = label or f"Uses `{fn}()`"
    ok = any(_matches_call(n, fn) for n in _calls())
    return _record(ok, label, message or f"Your code doesn't call `{fn}()` yet.")


def expect_not_called(fn, label=None, message=None):
    label = label or f"Doesn't use `{fn}()`"
    ok = not any(_matches_call(n, fn) for n in _calls())
    return _record(ok, label, message or f"This level asks you to do it without `{fn}()`.")


def expect_imported(module, label=None, message=None):
    label = label or f"Imports `{module}`"
    try:
        tree = _ast.parse(ss.code)
    except SyntaxError:
        tree = None
    found = False
    for node in _ast.walk(tree) if tree else []:
        if isinstance(node, _ast.Import):
            found = found or any(a.name == module or a.name.startswith(module + ".") for a in node.names)
        elif isinstance(node, _ast.ImportFrom) and node.module:
            found = found or node.module == module or node.module.startswith(module + ".")
    return _record(found, label, message or f"Import it first, e.g. `import {module}`.")


def expect_output(pattern, fixed=False, label=None, message=None):
    label = label or f"Output shows {pattern}"
    text = ss.output_text()
    ok = (pattern in text) if fixed else _re.search(pattern, text, _re.MULTILINE) is not None
    return _record(ok, label, message or "The console doesn't show this yet. Print it, or put it on a line by itself.")


def expect_printed(value, label=None, message=None):
    printed = value if isinstance(value, str) else repr(value)
    label = label or f"Prints {printed}"
    ok = ("\n" + printed + "\n") in ("\n" + ss.output_text() + "\n")
    return _record(ok, label, message or
                   f"The console doesn't show {printed} yet. A value is shown when it is on a line by itself "
                   "or passed to print().")


def expect_plot(n=1, label=None, message=None):
    label = label or ("Draws a plot" if n == 1 else f"Draws {n} plots")
    return _record(len(ss.plots) >= n, label,
                   message or "No figure was drawn. Make sure your plotting code runs.")


def expect_no_error(label="Runs without an error", message=None):
    return _record(ss.status == "ok", label,
                   message or "Your code stopped with an error. Fix that first; the console shows where.")


def expect_contains(text, fragment, label=None, message=None):
    label = label or f"Says {fragment}"
    def clean(s):
        return " ".join(s.replace("*", "").replace("\u2212", "-").split())
    ok = isinstance(text, str) and clean(fragment) in clean(text)
    return _record(ok, label, message or f"Expected to find “{fragment}” in the text.")


def plot_label(which="x", plot=1):
    """A figure's axis label ("x" or "y") or "title" (the first Axes of figure `plot`)."""
    if plot < 1 or plot > len(ss.figures) or not ss.figures[plot - 1].axes:
        return None
    ax = ss.figures[plot - 1].axes[0]
    return {"x": ax.get_xlabel, "y": ax.get_ylabel, "title": ax.get_title}[which]()


def apa_num(x, digits=2, lead=True):
    text = f"{x:.{digits}f}"
    if not lead:
        text = text.replace("0.", ".", 1)
    return text


def apa_p(p):
    return "p < .001" if p < 0.001 else "p = " + apa_num(p, 3, lead=False)
