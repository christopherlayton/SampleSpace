# Hull Breach

A crew member's analysis script has stopped working, and the report is due. This is a **Debug** level: the code in the editor is broken, and your job is to fix it, not to rewrite it.

## A debugging routine

1. **Run it** and read the *first* error. Later errors are often caused by the first one.
2. **Find the line.** R usually names the call that failed (`Error in read_csv(...)`) or quotes the code it couldn't read.
3. **Fix one thing, run again.** Repeat until it runs, then check the *results* make sense. Code that runs isn't necessarily right.

## Usual suspects

| Symptom | Likely cause |
|---|---|
| `unexpected '='` | `=` assigns; to *compare* use `==` |
| `could not find function "read_csv"` | the package isn't loaded: `library(readr)` |
| a subset with **0 rows** | a spelling or capital doesn't match: check `unique(df$col)` |
| `argument is not numeric or logical` from `mean()` | the column name is wrong, so `df$col` is `NULL`: check `names(df)` |
| a mean of `NA` | missing values: add `na.rm = TRUE` |

R won't warn you when `df$colname` names a column that doesn't exist; it just returns `NULL`. That's why the warning comes from `mean()`, one step later.

> **Coming from SPSS?** In SPSS a misspelt variable name stops the syntax with an error. In R, `$` with an unknown name quietly gives `NULL`. Tibbles (from `read_csv()`) at least add a warning: *Unknown or uninitialised column*.

## Mission

Fix the script so that it runs and stores the mean post-test anxiety of the Mindfulness group in `mean_mindful` and of the Control group in `mean_control`. There are **five** bugs. Keep the object names as they are.
