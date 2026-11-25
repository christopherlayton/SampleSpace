# Regression Wormhole

From Crew Connections: **do astronauts who fly more missions spend more hours spacewalking?** One row per person again: missions flown and total EVA (spacewalk) hours.

## Correlation

```python
pearson = stats.pearsonr(people["missions"], people["eva_hours"])
pearson.statistic, pearson.pvalue      # r and p
stats.spearmanr(people["missions"], people["eva_hours"])
```

`pearsonr()` is `cor.test()`; `spearmanr()` is `cor.test(method = "spearman")`.

## Regression

statsmodels' `ols()` is `lm()`, with the same formula:

| R | Python |
|---|---|
| `model <- lm(eva_hours ~ missions, data = people)` | `model = smf.ols("eva_hours ~ missions", data=people).fit()` |
| `summary(model)` | `print(model.summary())` |
| `coef(model)` | `model.params` |
| `summary(model)$r.squared` | `model.rsquared` |
| `confint(model)` | `model.conf_int()` |
| `predict(model, data.frame(missions = 3))` | `model.predict(pd.DataFrame({"missions": [3]}))` |

`model.summary()` is long: the coefficients table in the middle is the part that matches R's. With one predictor, *R*² is *r*², in either language.

{{twin}}

## Mission

`log` is loaded, with `pd`, `np`, `stats` and `smf` imported.

1. Make `people`: one row per `number`, with `missions` (how many rows) and `eva_hours` (the sum of `eva_hrs_mission`).
2. Store the Pearson test in `pearson` and the Spearman test in `spearman`.
3. Fit `model`: EVA hours predicted by missions. Print its summary.
4. Store the slope in `b` and *R*² in `r2`.
5. Store the predicted EVA hours for someone with 3 missions in `eva_for_3` (a number).
