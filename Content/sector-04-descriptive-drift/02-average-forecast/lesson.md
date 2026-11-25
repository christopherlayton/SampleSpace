# Average Forecast

Quick predictions to make the formulas stick. Work each one out in your head (or on paper) before you lock it in.

| Statistic | Formula | R |
|---|---|---|
| Mean | Σx / n | `mean(x)` |
| Median | middle value once sorted (mean of the middle two if n is even) | `median(x)` |
| Variance | Σ(x − mean)² / (n − 1) | `var(x)` |
| Standard deviation | √variance | `sd(x)` |
| z-score | (x − mean) / SD | `scale(x)` or by hand |

R's `var()` and `sd()` use **n − 1**, the *sample* formulas, like SPSS. That's what you want when your data are a sample used to estimate a population.

## Mission

Five predictions on the right.
