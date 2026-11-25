_log = pd.read_csv("astronauts.csv")
_f = _log[_log["mission_number"] == 1]
_f = _f.assign(age=_f["year_of_mission"] - _f["year_of_birth"], decade=_f["year_of_mission"] // 10 * 10)
_first = get_object("first")
expect_true(_first is not None and len(_first) == 564 and {"age", "decade"} <= set(getattr(_first, "columns", [])),
            label="`first` has age and decade for 564 first missions",
            message="Filter to `mission_number == 1`, then `assign(age=..., decade=first[\"year_of_mission\"] // 10 * 10)`.")
_t = get_object("table")
expect_true(_t is not None and "df" in getattr(_t, "columns", []) and int(_t["df"].iloc[0]) == 5,
            label="decade is treated as categories (5 df)",
            message="Wrap it in `C()`: `\"age ~ C(decade)\"`. Without it decade is one number, with 1 df.")
_model = smf.ols("age ~ C(decade)", data=_f).fit()
_table = sm.stats.anova_lm(_model, typ=2)
expect_true(_t is not None and "F" in getattr(_t, "columns", []) and abs(_t["F"].iloc[0] - _table["F"].iloc[0]) < 1e-6,
            label="`table` is the ANOVA table, F(5, 558)",
            message="`sm.stats.anova_lm(model, typ=2)`.")
expect_object("eta2", _table["sum_sq"].iloc[0] / _table["sum_sq"].sum(),
              message="η² = SS between / SS total: the decade row's `sum_sq` over the column's sum.")
expect_true(type(get_object("tukey")).__name__ == "TukeyHSDResults", label="`tukey` holds Tukey's HSD comparisons",
            message="`pairwise_tukeyhsd(first[\"age\"], first[\"decade\"])`.")
_lev = stats.levene(*[g["age"] for _, g in _f.groupby("decade")], center="mean")
_lv = get_object("levene")
expect_true(_lv is not None and abs(getattr(_lv, "statistic", -1) - _lev.statistic) < 1e-6,
            label="Levene's test is centred on the mean, across all six decades",
            message="`stats.levene(*[g[\"age\"] for _, g in first.groupby(\"decade\")], center=\"mean\")`.")
_w = anova_oneway(_f["age"], _f["decade"], use_var="unequal")
_wl = get_object("welch")
expect_true(_wl is not None and abs(getattr(_wl, "statistic", 0) - _w.statistic) < 1e-6,
            label="`welch` is Welch's ANOVA", message="`anova_oneway(first[\"age\"], first[\"decade\"], use_var=\"unequal\")`.")
_used = "welch" if _lev.pvalue < 0.05 else "classic"
expect_object("test_used", _used, message="Levene's p decides: below .05 the variances differ, so use Welch.")
_p = _w.pvalue if _used == "welch" else _table["PR(>F)"].iloc[0]
expect_object("decision", "reject" if _p < 0.05 else "fail to reject",
              message="Use the p of the test you chose.")
