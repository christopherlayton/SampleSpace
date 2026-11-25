_log = pd.read_csv("astronauts.csv")
_f = _log[_log["mission_number"] == 1]
_era = np.where(_f["year_of_mission"] >= 2000, "2000 on", "before 2000")
_tab = pd.crosstab(_era, _f["sex"]).loc[["before 2000", "2000 on"]]
_ct = get_object("crew_table")
expect_true(_ct is not None and list(map(str, getattr(_ct, "index", []))) == ["before 2000", "2000 on"],
            label="the rows are in order: before 2000, then 2000 on",
            message="Make `era` a `pd.Categorical(..., categories=[\"before 2000\", \"2000 on\"])` so it keeps that order.")
expect_object("crew_table", _tab, message="`pd.crosstab(first[\"era\"], first[\"sex\"])`.")
expect_object("row_pct", _tab.div(_tab.sum(axis=1), axis=0) * 100,
              message="Row percentages: `pd.crosstab(..., normalize=\"index\") * 100`.")
_chi = stats.chi2_contingency(_tab, correction=False)
_c = get_object("chi")
expect_true(_c is not None and abs(getattr(_c, "statistic", -1) - _chi.statistic) < 1e-6,
            label="the chi-square is uncorrected (as SPSS's Pearson row)",
            message="For a 2 × 2 table scipy applies Yates' correction unless you add `correction=False`.")
expect_object("expected_ok", bool((_chi.expected_freq >= 5).all()),
              message="`(chi.expected_freq >= 5).all()`.")
expect_object("v", np.sqrt(_chi.statistic / (_tab.values.sum() * (min(_tab.shape) - 1))),
              message="V = √(χ² / (N × (min(rows, columns) − 1))), with N = 564.")
