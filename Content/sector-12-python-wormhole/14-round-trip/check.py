import re as _re
import numpy as _np
import pandas as _pd
from scipy import stats as _stats
_log = _pd.read_csv("astronauts.csv")
_f = _log[_log["mission_number"] == 1]
_f = _f.assign(age=_f["year_of_mission"] - _f["year_of_birth"])
_w_ = _f.loc[_f["sex"] == "female", "age"]
_m_ = _f.loc[_f["sex"] == "male", "age"]

step(1)
for _lib in ("pandas", "numpy", "scipy", "seaborn", "matplotlib"):
    expect_imported(_lib)
_first = get_object("first")
expect_true(_first is not None and len(_first) == 564 and "age" in getattr(_first, "columns", [])
            and abs(_first["age"].mean() - _f["age"].mean()) < 1e-9,
            label="`first` has one row per astronaut, with `age`",
            message="Keep `mission_number == 1`, then `assign(age=year_of_mission - year_of_birth)`.")

step(2)
_b = get_object("by_sex")
expect_true(_b is not None and list(getattr(_b, "columns", [])) == ["count", "mean", "std"]
            and int(_b.loc["female", "count"]) == 64 and abs(_b.loc["male", "std"] - _m_.std()) < 1e-9,
            label="`by_sex` has count, mean and std of age by sex",
            message="`first.groupby(\"sex\")[\"age\"].agg([\"count\", \"mean\", \"std\"])`.")

step(3)
expect_called("boxplot")
expect_plot(1, message="Finish the boxplot with `plt.show()`.")
expect_true((plot_label("y", 1) or "").lower().startswith("age"), label="the y axis says Age at first flight",
            message="`plt.ylabel(\"Age at first flight\")` before `plt.show()`.")

step(4)
expect_object("women", _w_, message="`first.loc[first[\"sex\"] == \"female\", \"age\"]`.")
expect_object("men", _m_, message="`first.loc[first[\"sex\"] == \"male\", \"age\"]`.")
_lev = _stats.levene(_w_, _m_, center="mean")
_lv = get_object("levene")
expect_true(_lv is not None and abs(getattr(_lv, "statistic", -1) - _lev.statistic) < 1e-9,
            label="Levene's test is centred on the mean",
            message="`stats.levene(women, men, center=\"mean\")`.")

step(5)
_w = _stats.ttest_ind(_w_, _m_, equal_var=False)
_wl = get_object("welch")
expect_true(_wl is not None and abs(getattr(_wl, "df", 0) - _w.df) < 1e-6,
            label="`welch` is Welch's t-test", message="Add `equal_var=False`; scipy's default is Student's t.")
expect_true(_wl is not None and abs(getattr(_wl, "statistic", 0) - _w.statistic) < 1e-6,
            label="women come first (women − men)", message="`stats.ttest_ind(women, men, equal_var=False)`.")
_sp = _np.sqrt(((len(_w_) - 1) * _w_.var() + (len(_m_) - 1) * _m_.var()) / (len(_w_) + len(_m_) - 2))
_d = (_w_.mean() - _m_.mean()) / _sp
expect_object("d", _d, message="d = (mean of women − mean of men) / pooled SD.")

step(6)
expect_object("decision", "reject" if _w.pvalue < 0.05 else "fail to reject",
              message="Compare `welch.pvalue` with .05.")
_s = get_object("sentence")
expect_type("sentence", str, message="Store the sentence, a string, in `sentence`.")
_s = _s if isinstance(_s, str) else ""
expect_contains(_s, f"M = {apa_num(_w_.mean())}", label="reports women's M",
                message=f"Women's mean, two decimals: M = {apa_num(_w_.mean())}. Use `{{women.mean():.2f}}`.")
expect_contains(_s, f"M = {apa_num(_m_.mean())}", label="reports men's M")
expect_contains(_s, f"t({apa_num(_w.df)}) = {apa_num(_w.statistic)}", label="reports t(df) with two decimals",
                message="Write `t({welch.df:.2f}) = {welch.statistic:.2f}` inside the f-string.")
expect_contains(_s, apa_p(_w.pvalue), label="reports p in APA style",
                message="Below .001 APA writes p < .001 (not p = .000, and no leading zero).")
expect_contains(_s, f"d = {apa_num(_d)}", label="reports d", message="`d = {d:.2f}`.")
_typed = [n for n in (apa_num(_w.statistic), apa_num(_w.df), apa_num(abs(_d))) if n.lstrip("-") in learner_code()]
expect_true(_re.search(r"\bf[\"']", learner_code()) is not None and not _typed,
            label="the numbers come from an f-string, not typed",
            message="Build the sentence with an f-string (`f\"...{welch.statistic:.2f}...\"`) instead of typing the numbers.")
