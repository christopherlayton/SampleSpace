# One-Way Rift

Time for the real thing. Sixty teachers took one of three professional-development programmes; did their self-efficacy at the end (`efficacy_t2`, 1–9) differ by programme?

## Group order

R sorts a character column's groups alphabetically (Coaching, Online, Workshop). The order doesn't change F, but it sets the order of tables, plots and post hoc comparisons, so set it on purpose:

```r
pd$programme <- factor(pd$programme, levels = c("Workshop", "Coaching", "Online"))
```

## Fitting the model

```r
fit <- aov(efficacy_t2 ~ programme, data = pd)
summary(fit)
```

`summary()` prints the ANOVA table. Its first element, `summary(fit)[[1]]`, is the same table as a data frame, so its columns can be pulled out by name. The names have spaces and symbols, so they need quotes: `tab$"F value"`, `tab$"Pr(>F)"`.

| R's table | SPSS's ANOVA table |
|---|---|
| `programme` row | Between Groups |
| `Residuals` row | Within Groups |
| `Sum Sq`, `Df`, `Mean Sq` | Sum of Squares, df, Mean Square |
| `F value`, `Pr(>F)` | F, Sig. |

R leaves out the Total row; it's the sum of the other two.

## Effect size

`effectsize::eta_squared(fit)` gives η² (for one factor, partial η² is the same thing) with a confidence interval. Its upper bound shows as 1.00 because effectsize gives η² a one-sided interval by default (η² can't be below 0, so only the lower bound is tested); that's the package's choice, not an error.

> **APA note:** report the descriptive statistics for each group, then *F*(df₁, df₂), *p* and η², e.g. *F*(2, 57) = 4.33, *p* = .018, η² = .13.

## Mission

`pd_study.csv` is loaded into `pd` with dplyr and effectsize.

1. Make `programme` a factor in the order Workshop, Coaching, Online.
2. Store each programme's `n`, `mean` and `sd` of `efficacy_t2` in `group_stats`.
3. Fit the one-way ANOVA in `fit` and print its summary.
4. Store F in `f_value` and its p in `p_value`, taken from `summary(fit)[[1]]`.
5. Store `eta_squared(fit)` in `eta`.
