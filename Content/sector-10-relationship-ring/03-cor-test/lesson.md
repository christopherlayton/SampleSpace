# Testing r

`cor()` gives r. `cor.test()` adds what a report needs: a **confidence interval** for the population correlation ρ and a test of H₀: ρ = 0.

```r
pearson <- cor.test(sleep$sleep_hours, sleep$morale_score)
```

| Piece | Where | Note |
|---|---|---|
| r | `pearson$estimate` | |
| df | `pearson$parameter` | n − 2 |
| 95% CI | `pearson$conf.int` | from Fisher's z transformation, so not symmetric around r |
| p | `pearson$p.value` | the test uses *t* = r√(n − 2) ÷ √(1 − r²) |

## Plot first

r is a single number for a straight-line pattern. A curve, a few outliers or two clusters can all give the same r, so draw the scatterplot before you test.

## Spearman and ties

`method = "spearman"` correlates ranks. When values repeat (several crew sleep exactly 6.5 hours) R can't compute an exact p-value and warns you; `exact = FALSE` asks for the usual approximation, as SPSS uses.

> **Coming from SPSS?** *Analyze → Correlate → Bivariate* prints r, Sig. (2-tailed) and N for each pair, but no confidence interval. R gives you the CI; report it.

> **APA note:** *r*(df) = .xx, 95% CI [.xx, .xx], *p* = .xxx. Correlations can't exceed 1, so no leading zero.

## Mission

`sleep_morale.csv` holds 46 crew members' average nightly sleep (`sleep_hours`) and their morale composite (`morale_score`, 1–5), loaded into `sleep` with ggplot2.

1. Store a scatterplot of morale (y) against sleep (x) in `p`.
2. Store the Pearson test in `pearson`, and pull out `r`, its `df` and its 95% CI in `ci`.
3. Store `r_squared`.
4. Store Spearman's test, with `exact = FALSE`, in `spearman`.
