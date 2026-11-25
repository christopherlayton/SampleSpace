# Rift Stability Checks

An ANOVA makes three assumptions. Check them, and know what to do when one fails.

| Assumption | How to check | If it fails |
|---|---|---|
| **Independence** | the design: one score per person, no clusters | a different model (repeated measures, multilevel) |
| **Normal residuals** | Q–Q plot of `residuals(fit)`; Shapiro–Wilk | usually fine with groups of 20+; otherwise Kruskal–Wallis |
| **Equal variances** | Levene's test; compare SDs | Welch's ANOVA, Games–Howell post hoc |

## Residuals, not raw scores

Normality applies *within* each group, which is the same as asking whether the **residuals** (score − group mean) are normal. A histogram of the raw scores can look bimodal just because the groups differ.

```r
shapiro.test(residuals(fit))
qqnorm(residuals(fit)); qqline(residuals(fit))
```

As in the Means Cluster, Shapiro–Wilk flags trivial departures in big samples and misses real ones in small samples. Look at the Q–Q plot.

## Levene's test

```r
leveneTest(efficacy_t2 ~ programme, data = pd, center = mean)
```

car centres on the **median** by default (the Brown–Forsythe version, more robust). SPSS's first row, *Based on Mean*, needs `center = mean`.

## Welch's ANOVA and Kruskal–Wallis

- `oneway.test(y ~ group, data = ...)` is **Welch's ANOVA**, which doesn't assume equal variances, just as Welch's *t* doesn't. SPSS shows it under *Options → Welch* in the *Robust Tests of Equality of Means* table. It has fractional denominator df.
- `kruskal.test(y ~ group, data = ...)` is the **Kruskal–Wallis** test on ranks, a nonparametric alternative. It answers a slightly different question (whether scores in one group tend to be higher), so report it as such.

> **APA note:** report the assumption checks in a sentence before the main result, e.g. "Levene's test did not indicate unequal variances, *F*(df₁, df₂) = …, *p* = …", and say which test you then report.

## Mission

`pd` is loaded with car, and the one-way ANOVA is in `fit`.

1. Store SPSS's Levene test in `levene`.
2. Store the Shapiro–Wilk test of the residuals in `shapiro`, and draw their Q–Q plot with a reference line.
3. Store Welch's ANOVA in `welch` and the Kruskal–Wallis test in `kruskal`.

Do the three tests of programme tell the same story?
