# Sample Space Python runner: the Python twin of R/runner.R, for Python Wormhole levels.
#
# Usage: python3 -X utf8 runner.py job.json
#
# job.json and result.json have the same fields as runner.R's (see the top of that file), so
# the app reads both the same way. Not supported here: `document` (Quarto levels are R only).
#
# How a run works:
# - The learner's code is parsed with `ast` and run one top-level statement at a time in a
#   fresh namespace, like typing into the Python prompt: each statement is echoed as an
#   `input` entry, and a bare expression whose value isn't None is printed with repr(), as
#   the interactive prompt (and Jupyter) does, with two exceptions: numpy scalars print as
#   plain numbers (2.0, not np.float64(2.0)), and values returned by matplotlib calls
#   (Axes, Text, lists of lines) aren't echoed. The first error stops the run.
# - Errors become one `error` entry, "KeyError: 'hours'", with `call` = "line 3" (the line
#   of the learner's code it came from). Warnings are `warning` entries in the same form.
# - matplotlib uses the Agg backend. plt.show() saves every open figure as plot-NNN.png and
#   closes it (one plot per figure, like R's plot pages); figures still open at the end are
#   saved too. The Figure objects are kept for checks (see checks.py, plot_label()).
# - The time limit is a SIGALRM timer that raises an exception the learner's code can't catch
#   with `except Exception`; the app's watchdog kills Python if even that doesn't stop it.
# - exit() and quit() are switched off. `seed` seeds `random` and numpy's global generator.
#
# Everything lives inside main() so the learner's namespace starts empty.

import ast
import builtins
import io
import json
import os
import shutil
import signal
import sys
import time
import traceback
import warnings

MAX_OUTPUT_CHARS = 200_000
CHECK_TIME_LIMIT = 10
CODE_FILE = "<your code>"
SKIP_DATA = (".py", ".r", ".md", ".qmd", ".json", ".pyc")


class TimeLimit(BaseException):
    """Raised by the timer. A BaseException, so `except Exception:` in learner code can't swallow it."""



class State:
    """The run state, shared with the check helpers (checks.py) as `ss`."""

    def __init__(self, job):
        self.job = job
        self.code = job.get("code") or ""
        self.console = []
        self.checks = []
        self.plots = []        # file names, in order
        self.figures = []      # matplotlib Figure objects, in the same order
        self.status = "ok"
        self.output_chars = 0
        self.truncated = False
        self.duration = 0.0
        self.step = None
        self.learner = {}
        self.out_dir = ""
        self.plt_patched = False
        self.pandas_ready = False

    def add(self, kind, text, call=None):
        if self.truncated:
            return
        self.output_chars += len(text)
        if self.output_chars > MAX_OUTPUT_CHARS:
            self.truncated = True
            kind, text, call = "message", "[Output was too long, so the rest was cut off.]", None
        self.console.append({"type": kind, "text": text, "call": call})

    def output_text(self):
        return "\n".join(e["text"] for e in self.console if e["type"] == "output")


def learner_line(tb):
    """The line of the learner's code an exception came from (the deepest one), or None."""
    line = None
    for frame in traceback.extract_tb(tb):
        if frame.filename == CODE_FILE:
            line = frame.lineno
    return line


def quiet(value):
    """Values not echoed: what matplotlib and seaborn calls return (Axes, Text, lists of
    lines…), which the Python prompt would print as clutter like [<Line2D object at 0x…>]."""
    def from_matplotlib(v):
        return type(v).__module__.split(".")[0] == "matplotlib"
    if from_matplotlib(value):
        return True
    if isinstance(value, (list, tuple)) and value:
        return any(from_matplotlib(v) for v in value)
    return False


def shown(value):
    """How a bare expression's value is printed: repr(), as the Python prompt does, except
    numpy scalars, which print as plain numbers (2.0, not np.float64(2.0))."""
    numpy = sys.modules.get("numpy")
    if numpy is not None and isinstance(value, numpy.generic):
        return str(value)
    return repr(value)


def error_text(exc):
    name = type(exc).__name__
    message = str(exc)
    if isinstance(exc, KeyError) and exc.args:
        message = repr(exc.args[0])
    return f"{name}: {message}" if message else name


class Capture(io.TextIOBase):
    """Collects what print() writes during one statement."""

    def __init__(self):
        self.parts = []

    def writable(self):
        return True

    def write(self, text):
        self.parts.append(text)
        return len(text)

    def take(self):
        text = "".join(self.parts)
        self.parts = []
        return text


def main():
    job_path = sys.argv[1]
    runner_dir = os.path.dirname(os.path.abspath(__file__))
    with open(job_path, encoding="utf-8") as f:
        job = json.load(f)
    ss = State(job)
    ss.out_dir = os.path.abspath(job["output_dir"])
    time_limit = float(job.get("time_limit") or 10)
    width = int(job.get("width") or 80)

    os.environ["MPLBACKEND"] = "Agg"
    os.environ["COLUMNS"] = str(width)

    real_stdout, real_stderr = sys.stdout, sys.stderr
    capture = Capture()
    current_line = [None]

    def flush_output():
        text = capture.take()
        if text:
            if text.endswith("\n"):
                text = text[:-1]
            ss.add("output", text)

    def show_warning(message, category, filename, lineno, file=None, line=None):
        flush_output()
        where = lineno if filename == CODE_FILE else current_line[0]
        ss.add("warning", f"{category.__name__}: {message}", f"line {where}" if where else None)

    def save_open_figures():
        plt = sys.modules.get("matplotlib.pyplot")
        if plt is None:
            return
        for num in plt.get_fignums():
            fig = plt.figure(num)
            if not fig.axes:
                plt.close(fig)
                continue
            name = f"plot-{len(ss.plots) + 1:03d}.png"
            fig.savefig(os.path.join(ss.out_dir, name), dpi=144, facecolor="white", bbox_inches="tight")
            ss.plots.append(name)
            ss.figures.append(fig)
            plt.close(fig)

    def prepare_modules():
        """Once pyplot or pandas has been imported (by the learner or a library), set it up."""
        plt = sys.modules.get("matplotlib.pyplot")
        if plt is not None and not ss.plt_patched:
            ss.plt_patched = True
            plt.rcParams["figure.figsize"] = (7, 5)
            plt.show = lambda *args, **kwargs: save_open_figures()
        pd = sys.modules.get("pandas")
        if pd is not None and not ss.pandas_ready:
            ss.pandas_ready = True
            try:
                pd.set_option("display.width", width)
                pd.set_option("display.max_columns", 20)
            except Exception:
                pass

    def alarm(signum, frame):
        raise TimeLimit()

    def run_statements(tree, namespace):
        signal.signal(signal.SIGALRM, alarm)
        started = time.monotonic()
        signal.setitimer(signal.ITIMER_REAL, time_limit)
        try:
            code_lines = ss.code.split("\n")
            echoed = 0  # last line echoed: statements sharing a line (a; b) echo it once
            for node in tree.body:
                first, last = node.lineno, node.end_lineno or node.lineno
                if last > echoed:
                    ss.add("input", "\n".join(code_lines[max(first, echoed + 1) - 1:last]))
                    echoed = last
                current_line[0] = first
                if not run_one(node, namespace):
                    break
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0)
            ss.duration = time.monotonic() - started

    def run_one(node, namespace):
        sys.stdout = sys.stderr = capture
        ok = True
        try:
            with warnings.catch_warnings():
                warnings.simplefilter("default")
                warnings.filterwarnings("ignore", message=".*non-interactive.*cannot be shown")
                warnings.filterwarnings("ignore", category=DeprecationWarning)
                warnings.showwarning = show_warning
                if isinstance(node, ast.Expr):
                    code = compile(ast.Expression(node.value), CODE_FILE, "eval")
                    value = eval(code, namespace)
                    prepare_modules()
                    if value is not None and not quiet(value):
                        print(shown(value))
                else:
                    module = ast.Module(body=[node], type_ignores=[])
                    exec(compile(module, CODE_FILE, "exec"), namespace)
                    prepare_modules()
        except TimeLimit:
            ok = False
            flush_output()
            ss.status = "timeout"
            s = "" if time_limit == 1 else "s"
            ss.add("error", f"Your code ran for more than {time_limit:g} second{s}, so it was stopped. "
                            "Look for a loop that never ends.")
        except BaseException as exc:  # noqa: BLE001 - the learner's errors, whatever they are
            ok = False
            flush_output()
            ss.status = "error"
            line = learner_line(exc.__traceback__) or current_line[0]
            ss.add("error", error_text(exc), f"line {line}" if line else None)
        finally:
            sys.stdout, sys.stderr = real_stdout, real_stderr
        flush_output()
        return ok

    def run():
        learner = {"__name__": "__main__", "__builtins__": builtins}

        def no_quit(*args, **kwargs):
            raise RuntimeError("exit() and quit() are switched off in Sample Space.")

        learner["exit"] = learner["quit"] = no_quit
        ss.learner = learner

        data_dir = job.get("data_dir")
        if data_dir and os.path.isdir(data_dir):
            for name in os.listdir(data_dir):
                path = os.path.join(data_dir, name)
                if os.path.isfile(path) and not name.lower().endswith(SKIP_DATA):
                    shutil.copy(path, ss.out_dir)
        os.chdir(ss.out_dir)

        setup = job.get("setup")
        if setup and setup.strip():
            sys.stdout = io.StringIO()
            try:
                exec(compile(setup, "<setup>", "exec"), learner)
            finally:
                sys.stdout = real_stdout
            prepare_modules()

        seed = job.get("seed")
        if seed is not None:
            import random
            random.seed(seed)
            try:
                import numpy
                numpy.random.seed(seed)
            except ImportError:
                pass

        if job.get("document"):
            raise RuntimeError("Quarto documents are run by R, not Python.")

        try:
            tree = ast.parse(ss.code, CODE_FILE)
        except SyntaxError as exc:
            ss.status = "parse_error"
            detail = exc.msg
            where = f"line {exc.lineno}" if exc.lineno else None
            text = f"Python couldn't read your code: {type(exc).__name__}: {detail}"
            if exc.text:
                pointer = " " * max((exc.offset or 1) - 1, 0) + "^"
                text += "\n" + exc.text.rstrip("\n") + "\n" + pointer
            ss.add("error", text, where)
        else:
            run_statements(tree, learner)
            save_open_figures()

        checks = job.get("checks")
        if checks and checks.strip():
            run_checks(checks, learner)

    def run_checks(check_code, learner):
        helpers = {"__name__": "checks", "__builtins__": builtins, "ss": ss}
        with open(os.path.join(runner_dir, "checks.py"), encoding="utf-8") as f:
            exec(compile(f.read(), "checks.py", "exec"), helpers)
        exported = {k: v for k, v in helpers.items() if not k.startswith("_") and k not in ("ss",)}
        namespace = dict(learner)
        namespace.update(exported)
        namespace["__builtins__"] = builtins
        try:
            tree = ast.parse(check_code, "check.py")
        except SyntaxError as exc:
            ss.checks.append({"passed": False, "label": "Level checks", "internal": True,
                              "message": f"The level's check.py has a syntax error: {exc}"})
            return
        signal.signal(signal.SIGALRM, alarm)
        signal.setitimer(signal.ITIMER_REAL, CHECK_TIME_LIMIT)
        sys.stdout = io.StringIO()
        try:
            for node in tree.body:
                try:
                    with warnings.catch_warnings():
                        warnings.simplefilter("ignore")
                        exec(compile(ast.Module(body=[node], type_ignores=[]), "check.py", "exec"), namespace)
                except TimeLimit:
                    raise
                except BaseException as exc:  # noqa: BLE001
                    ss.checks.append({"passed": False, "label": "A check couldn't run", "internal": True,
                                      "message": error_text(exc), "step": ss.step})
        except TimeLimit:
            ss.checks.append({"passed": False, "label": "Checks took too long", "internal": True,
                              "message": "The level's checks ran for more than 10 seconds.", "step": ss.step})
        finally:
            signal.setitimer(signal.ITIMER_REAL, 0)
            sys.stdout = real_stdout

    try:
        run()
    except BaseException as exc:  # noqa: BLE001
        signal.setitimer(signal.ITIMER_REAL, 0)
        sys.stdout, sys.stderr = real_stdout, real_stderr
        ss.status = "runner_error"
        ss.add("error", f"Sample Space couldn't run this: {error_text(exc)}")

    passed = ss.status == "ok" and all(c.get("passed") for c in ss.checks)
    result = {
        "status": ss.status,
        "console": ss.console,
        "plots": ss.plots,
        "checks": ss.checks,
        "passed": passed,
        "duration": round(ss.duration, 3),
    }
    with open(os.path.join(ss.out_dir, "result.json"), "w", encoding="utf-8") as f:
        json.dump(result, f, ensure_ascii=False, default=str)


main()
