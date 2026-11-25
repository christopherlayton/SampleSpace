# Missing Cargo

The ship's analyst wrote a missing-data report for the morale survey before going off shift. It doesn't run, and once it does, two of its numbers are wrong.

## Rules of `NA`

- `NA` means "unknown", so almost anything done with it is unknown too: `5 > NA` is `NA`, and so is `NA == NA`. That's why you can't find missing values with `== NA` or `!= NA`. Use `is.na(x)` and `!is.na(x)`.
- `filter()` keeps only rows where the condition is `TRUE`. Rows where it is `NA` are dropped, silently.
- `mean()`, `sd()`, `sum()` and friends return `NA` if any value is missing, unless you add `na.rm = TRUE`.

## Whose data do you drop?

`na.omit(df)` (and `tidyr::drop_na(df)` with no columns named) removes every row with a missing value in **any** column. That's *listwise deletion* across the whole file, and it can throw away people who answered everything you're analysing. Be specific about which columns matter:

```r
morale |> filter(if_all(m1:m6, ~ !is.na(.x)))   # complete on the six items only
tidyr::drop_na(morale, m1:m6)                    # the same, with tidyr
```

> **Coming from SPSS?** SPSS dialogs ask "Exclude cases listwise" or "pairwise". In R you make that choice explicitly, column by column, and it's visible in your script.

> **APA note:** report how much data was missing on each variable and how you handled it. "Listwise deletion" without saying *on which variables* isn't enough.

## Mission

Fix the script so that it runs and stores:

- `n_sleep`: how many participants reported their hours of sleep,
- `sleep_by_programme`: the mean hours of sleep in each programme (ignoring missing values),
- `n_all_items`: how many participants answered all six morale items.

There are **four** bugs. Keep the object names as they are.
