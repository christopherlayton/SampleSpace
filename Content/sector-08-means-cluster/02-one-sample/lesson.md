# One-Sample Probe

The anxiety questionnaire's manual gives a norm of **28** for university students. Are the students in the wellbeing survey more anxious than that before the study starts?

- **H₀:** μ = 28 (this group's population mean equals the norm)
- **H₁:** μ ≠ 28 (two-sided)

## The test

```r
res <- t.test(survey$anxiety_pre, mu = 28)
res
```

`t` is (*M* − 28) / SE, with *n* − 1 degrees of freedom. The confidence interval is for the mean itself, the same interval you built by hand in Inference Station. It excludes 28 exactly when p < .05.

## Taking the result apart

`t.test()` returns a list (class `htest`), so you can pull out any piece instead of copying numbers by hand:

| Piece | What it holds |
|---|---|
| `res$statistic` | *t* (named "t") |
| `res$parameter` | the degrees of freedom (named "df") |
| `res$p.value` | *p* |
| `res$conf.int` | the 95% CI |
| `res$estimate` | the sample mean |

`unname()` drops the label: `unname(res$statistic)`. `broom::tidy(res)` turns the whole result into a one-row data frame, which is handy for tables.

> **Coming from SPSS?** *Analyze → Compare Means → One-Sample T Test*, Test Value 28. SPSS's CI is for the *difference* from 28; R's is for the mean. Subtract 28 from R's to match.

> **APA note:** Pre-test anxiety (*M* = 29.63, *SD* = 5.03) was higher than the norm of 28, *t*(39) = 2.04, *p* = .048. Report *t* to two decimals and *df* as a whole number.

## Mission

1. Import `wellbeing_survey.csv` into `survey`.
2. Run the one-sample *t*-test of `anxiety_pre` against 28 and store it in `res`.
3. Store *t*, *df* and *p* in `t_val`, `df_val` and `p_val` (plain numbers, no names), and the CI in `ci`.
4. Store the mean difference from the norm, *M* − 28, in `mean_diff`.
