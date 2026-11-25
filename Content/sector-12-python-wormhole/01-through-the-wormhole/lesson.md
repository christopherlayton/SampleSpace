# Through the Wormhole

The ship's computer has a second language. Through the wormhole the same Crew Log is read by **Python**, the other language you'll meet in research and data jobs. Your dissertation stays in R; this sector is so you can read a colleague's Python, check their numbers, and know that the statistics don't change when the language does.

## The same ideas, other words

| In R | In Python |
|---|---|
| `library(readr)` | `import pandas as pd` |
| `x <- c(1, 2, 3)` | `x = [1, 2, 3]` (a *list*) |
| `x[1]` (first) | `x[0]` (first) |
| `TRUE`, `FALSE`, `NULL` | `True`, `False`, `None` |
| `NA` | `NaN` (or `None`) |
| data frame / tibble | pandas `DataFrame`; one column is a `Series` |
| `mean(x)` | `x.mean()` (a *method*) or `np.mean(x)` |
| `{ ... }` blocks | a `:` and indented lines |
| `t.test()`, `chisq.test()` | `scipy.stats.ttest_ind()`, `chi2_contingency()` |
| `aov()`, `lm()` | `statsmodels`: `smf.ols()` |
| ggplot2 | matplotlib and seaborn |

## Four habits to unlearn

1. **Counting starts at 0.** The first item is `x[0]`; `x[1:3]` means positions 1 and 2 (the end is left out).
2. **The library name stays in front.** After `import numpy as np` you write `np.mean()`, never just `mean()`.
3. **Methods.** pandas puts its tools on the data: `log.head()`, `log["hours_mission"].median()`, `log.groupby("sex")`.
4. **Indentation matters.** A `for`, `if` or `def` line ends with `:`, and the lines inside it are indented.

## Same statistics, different defaults

The maths is identical; the *defaults* aren't. You'll meet several in this sector, and each one changes a number if you don't know about it:

- numpy's standard deviation divides by *n*, pandas' (and R's, and SPSS's) by *n* − 1.
- pandas skips missing values in `mean()` without being asked; R needs `na.rm = TRUE`.
- `scipy.stats.ttest_ind()` assumes equal variances unless you say otherwise; R's `t.test()` doesn't.
- `scipy.stats.levene()` centres on the median, like `car::leveneTest()`; SPSS centres on the mean.

> **Coming from SPSS?** Everything SPSS's menus did, Python does with code, like R. Each level here shows the R you already know next to the Python, with a button to run the R, so you can check the two agree.
