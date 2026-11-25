# One-Way Translator

Here is SPSS's One-Way ANOVA output for the end-of-programme self-efficacy scores. Every number on it comes from five R calls.

{{spss}}

## Table by table

| SPSS table | R |
|---|---|
| Descriptives | `group_by(programme) \|> summarise(n, mean, sd, se = sd / sqrt(n))` |
| Homogeneity, Based on Mean | `leveneTest(efficacy_t2 ~ programme, data = pd, center = mean)` |
| Homogeneity, Based on Median | `leveneTest(..., center = median)` (car's default) |
| ANOVA | `summary(aov(efficacy_t2 ~ programme, data = pd))` |
| Robust Tests: Welch | `oneway.test(efficacy_t2 ~ programme, data = pd)` |
| Multiple Comparisons, Tukey HSD | `TukeyHSD(fit)` |

## Reading the differences

- SPSS's **Mean Difference (I−J)** lists each pair twice, once each way round. R's `TukeyHSD()` lists each pair once as `B-A`, the later level minus the earlier, so its `Online-Coaching` row is SPSS's last row, −1.015.
- The **Std. Error** of every difference is the same here because the groups are the same size: √(MS within × (1/20 + 1/20)) = .357.
- SPSS flags a significant difference with an asterisk; R gives `p adj`. Both use the studentized range distribution (`ptukey()`).

> **SPSS footnote habit:** SPSS's *Sig.* is a p-value. Write it as *p* in a report, never as "Sig.".

## Mission

`pd` is loaded with `programme` in SPSS's code order (Workshop, Coaching, Online), with dplyr and car.

1. Store the Descriptives (`n`, `mean`, `sd`, `se` per programme) in `desc`.
2. Store both Levene rows: centred on the mean in `levene_mean` and on the median in `levene_median`.
3. Fit the ANOVA in `fit` and print its summary.
4. Store Welch's test in `welch` and Tukey's HSD in `tukey`.
