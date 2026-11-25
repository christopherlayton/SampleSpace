# Spread Scanner

An average without a measure of spread is half a description. Two classes can both average 70% while one has everyone between 65 and 75 and the other runs from 30 to 100.

| Measure | What it is | R | Sensitive to extremes? |
|---|---|---|---|
| Range | max − min | `range(x)`, `diff(range(x))` | very |
| Variance | average squared distance from the mean | `var(x)` | yes (squared!) |
| Standard deviation | √variance, in the data's own units | `sd(x)` | yes |
| Interquartile range | 75th − 25th percentile: the spread of the middle half | `IQR(x)` | no |
| Percentiles | the value below which p% of the data fall | `quantile(x, p)` | no |

The mean goes with the **SD**; the median goes with the **IQR**. Report them in those pairs.

`quantile(x)` with no `p` gives the five-number summary: min, Q1, median, Q3, max (the numbers a boxplot draws).

> **Coming from SPSS?** *Frequencies → Statistics* offers Std. deviation, Variance, Range and Quartiles; *Percentile(s)* adds any others. SPSS's default percentile method differs slightly from R's default, so quartiles can disagree in the decimals; `quantile(x, type = 6)` matches SPSS.

## Mission

1. Load readr and import `astronauts.csv` into `astronauts`.
2. Store the SD of mission length in `sd_hours` and the variance in `var_hours`.
3. Store the interquartile range in `iqr_hours`.
4. Store the 90th percentile, as a plain number, in `p90_hours`.
5. Store the range (shortest and longest, as two numbers) in `range_hours`.

Compare `sd_hours` with `iqr_hours`. Why is one about nine times the other?
