# Missing Signals

Real data have gaps: a skipped question, a participant who left early. R marks a missing value with **`NA`** (no quotes).

`NA` is contagious. If one value is unknown, anything calculated from it is unknown too:

```r
x <- c(4, NA, 6)
mean(x)
#> [1] NA
```

## The tools

| Code | Does |
|---|---|
| `is.na(x)` | TRUE where a value is missing |
| `sum(is.na(x))` | counts missing values |
| `sum(!is.na(x))` | counts **valid** values (`!` flips TRUE/FALSE) |
| `mean(x, na.rm = TRUE)` | the mean of the values that aren't missing |

`na.rm = TRUE` ("NA remove") works with `mean()`, `sum()`, `sd()`, `min()`, `max()`, `median()` and many more.

> **Coming from SPSS?** SPSS leaves out missing values automatically and reports the valid *N* in its output. R makes you decide on purpose. That's annoying at first, but it means missing data never silently change your results.

> **APA note:** report the *N* each statistic is based on. If 6 of 8 participants have sleep data, the mean comes from *n* = 6, and your write-up should say so (e.g. *M* = 6.75, *n* = 6).

## Mission

`sleep_hours` holds last night's sleep for eight participants; two didn't answer.

1. Store the number of missing values in `n_missing`.
2. Store the number of valid answers in `n_valid`.
3. Store the mean sleep of those who answered in `mean_sleep`.
