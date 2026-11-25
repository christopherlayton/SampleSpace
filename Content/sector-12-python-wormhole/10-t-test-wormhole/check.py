_log = pd.read_csv("astronauts.csv")
_p = _log.groupby("number").agg(mc=("military_civilian", "first"), mh=("hours_mission", "mean"))
_civ = _p.loc[_p.mc == "civilian", "mh"]
_mil = _p.loc[_p.mc == "military", "mh"]
_people = get_object("people")
expect_true(_people is not None and len(_people) == 564 and "mean_hours" in getattr(_people, "columns", [])
            and abs(_people["mean_hours"].mean() - _p["mh"].mean()) < 1e-9,
            label="`people` has one row per astronaut with `mean_hours`",
            message="Group by `number`, then `.agg(military_civilian=(\"military_civilian\", \"first\"), mean_hours=(\"hours_mission\", \"mean\"))`.")
_g = get_object("group_stats")
expect_true(_g is not None and list(getattr(_g, "columns", [])) == ["count", "mean", "std", "median"]
            and abs(_g.loc["civilian", "std"] - _civ.std()) < 1e-6,
            label="`group_stats` has count, mean, std and median per group",
            message="`people.groupby(\"military_civilian\")[\"mean_hours\"].agg([\"count\", \"mean\", \"std\", \"median\"])`.")
expect_object("civ", _civ, message="`people.loc[people[\"military_civilian\"] == \"civilian\", \"mean_hours\"]`.")
expect_object("mil", _mil)
_lev = stats.levene(_civ, _mil, center="mean")
_lv = get_object("levene")
expect_true(_lv is not None and abs(getattr(_lv, "statistic", -1) - _lev.statistic) < 1e-6,
            label="Levene's test is centred on the mean, as in SPSS",
            message="`stats.levene(civ, mil, center=\"mean\")`. Without `center=\"mean\"` scipy centres on the median.")
_w = stats.ttest_ind(_civ, _mil, equal_var=False)
_wl = get_object("welch")
expect_true(_wl is not None and abs(getattr(_wl, "df", 0) - _w.df) < 1e-6,
            label="`welch` is Welch's test (unequal variances)",
            message="scipy's default is Student's t. Add `equal_var=False`.")
expect_true(_wl is not None and abs(getattr(_wl, "statistic", 0) - _w.statistic) < 1e-6,
            label="civilians come first (civilian − military)",
            message="Pass `civ` first and `mil` second, so t has the same sign as R's.")
_sp = np.sqrt(((len(_civ) - 1) * _civ.var() + (len(_mil) - 1) * _mil.var()) / (len(_civ) + len(_mil) - 2))
expect_object("d", (_civ.mean() - _mil.mean()) / _sp,
              message="d = (mean of civ − mean of mil) / pooled SD, using `.var()` (n − 1).")
expect_object("decision", "reject" if _w.pvalue < 0.05 else "fail to reject",
              message="Compare `welch.pvalue` with .05: below it, \"reject\"; otherwise \"fail to reject\".")
