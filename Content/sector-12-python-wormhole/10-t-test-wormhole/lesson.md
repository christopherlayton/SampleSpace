# t-Test Wormhole

The question from the Means Cluster, through the wormhole: **do military and civilian astronauts fly missions of different lengths?** You answered it in R. Now do it in Python and check the two languages agree.

## One row per person

`groupby().agg()` is pandas' `group_by() |> summarise()`. Each new column is `name=(column, function)`:

```python
people = log.groupby("number").agg(
    military_civilian=("military_civilian", "first"),
    mean_hours=("hours_mission", "mean"))
```

## Two groups, two defaults to change

`scipy.stats` wants the two groups as separate columns of numbers. `.loc[rows, column]` picks rows by a condition and a column by name:

```python
civ = people.loc[people["military_civilian"] == "civilian", "mean_hours"]
```

Then the tests, with **two defaults that differ from what you know**:

| | R | Python default | to match SPSS / Welch |
|---|---|---|---|
| Levene | `leveneTest(..., center = mean)` | `stats.levene(a, b)` centres on the **median** | `center="mean"` |
| *t*-test | `t.test()` is Welch | `stats.ttest_ind(a, b)` is **Student's** (equal variances) | `equal_var=False` |

The result objects have named parts: `welch.statistic`, `welch.pvalue` and `welch.df`.

scipy has no Cohen's *d*, so compute it from the pooled SD, exactly as you did by hand in the Effect Size Gauge. Put civilians first, as R does (it orders the groups alphabetically).

{{twin}}

## Mission

`log` is loaded, with `pd`, `np` and `stats` (from scipy) imported.

1. Make `people`: one row per `number`, with `military_civilian` and `mean_hours`.
2. Store each group's `count`, `mean`, `std` and `median` of `mean_hours` in `group_stats`.
3. Store civilians' `mean_hours` in `civ` and military astronauts' in `mil`.
4. Store Levene's test (centred on the mean) in `levene`, Welch's *t*-test in `welch` and Cohen's *d* (civilian − military, pooled SD) in `d`.
5. Store your decision at α = .05 in `decision`: `"reject"` or `"fail to reject"`.
