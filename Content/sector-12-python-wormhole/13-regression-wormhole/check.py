_log = pd.read_csv("astronauts.csv")
_p = _log.groupby("number").agg(missions=("id", "size"), eva_hours=("eva_hrs_mission", "sum"))
_people = get_object("people")
expect_true(_people is not None and len(_people) == 564 and {"missions", "eva_hours"} <= set(getattr(_people, "columns", []))
            and int(_people["missions"].sum()) == 1277 and abs(_people["eva_hours"].sum() - _p["eva_hours"].sum()) < 1e-6,
            label="`people` has missions and eva_hours for 564 astronauts",
            message="`log.groupby(\"number\").agg(missions=(\"id\", \"size\"), eva_hours=(\"eva_hrs_mission\", \"sum\"))`.")
_r = stats.pearsonr(_p["missions"], _p["eva_hours"])
_s = stats.spearmanr(_p["missions"], _p["eva_hours"])
_pe, _sp = get_object("pearson"), get_object("spearman")
expect_true(_pe is not None and abs(getattr(_pe, "statistic", 0) - _r.statistic) < 1e-9, label="`pearson` is Pearson's r",
            message="`stats.pearsonr(people[\"missions\"], people[\"eva_hours\"])`.")
expect_true(_sp is not None and abs(getattr(_sp, "statistic", 0) - _s.statistic) < 1e-9, label="`spearman` is Spearman's rho",
            message="`stats.spearmanr(people[\"missions\"], people[\"eva_hours\"])`.")
_m = smf.ols("eva_hours ~ missions", data=_p).fit()
expect_true(type(get_object("model")).__name__ == "RegressionResultsWrapper", label="`model` is a fitted regression",
            message="`smf.ols(\"eva_hours ~ missions\", data=people).fit()`: don't forget `.fit()`.")
expect_called("summary")
expect_object("b", _m.params["missions"], message="`model.params[\"missions\"]` is the slope.")
expect_object("r2", _m.rsquared, message="`model.rsquared`. It should equal `pearson.statistic ** 2`.")
expect_object("eva_for_3", _m.params["Intercept"] + 3 * _m.params["missions"],
              message="`model.predict(pd.DataFrame({\"missions\": [3]})).iloc[0]` (or intercept + 3 × slope).")
