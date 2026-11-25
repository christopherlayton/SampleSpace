# Describe Everything

Computing each statistic separately gets old fast. The **psych** package, written by a psychologist for psychologists, gives the usual table in one call:

```r
library(psych)
describe(survey[, c("age", "anxiety_pre")])
```

You get one row per variable with `n`, `mean`, `sd`, `median`, `trimmed` (the 10% trimmed mean), `mad`, `min`, `max`, `range`, `skew`, `kurtosis` and `se` (the standard error of the mean). Missing values are left out variable by variable, so `n` can differ between rows.

The result is a data frame, so you can pull numbers out of it:

```r
desc <- describe(survey[, c("age", "anxiety_pre")])
desc["age", "mean"]
desc$skew
```

For descriptives **by group**, `describeBy(survey$anxiety_pre, group = survey$group)` gives one table per group.

> **Coming from SPSS?** This is close to *Analyze → Descriptive Statistics → Descriptives* with every option ticked. The next level matches SPSS's numbers exactly.

## Mission

`wellbeing_survey.csv` is back: 40 students, pre/post anxiety (10–50) and satisfaction (1–5).

1. Load readr and psych and import the file into `survey`.
2. Store `describe()` of `age`, `anxiety_pre`, `anxiety_post` and `satisfaction` in `desc`.
3. Store the median satisfaction from `desc` in `sat_median`.
4. Store the name of the variable whose skew is furthest from 0 (in either direction) in `most_skewed`.
