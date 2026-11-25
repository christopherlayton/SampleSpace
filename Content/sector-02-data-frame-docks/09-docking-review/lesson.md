# Dock Inspection

Final inspection before leaving the Docks: the first ten minutes of almost every real analysis.

1. **Import** the data.
2. **Set types**: grouping variables become factors, with the reference group first.
3. **Audit missing data**: how much, and where?
4. **Compute** the variables you'll analyse.

## Two new tools for the audit

| Code | Gives |
|---|---|
| `colSums(is.na(df))` | missing values in each column |
| `complete.cases(df)` | TRUE for rows with **no** missing values |

`sum(complete.cases(df))` is the *n* you'd have if you dropped every row with any missing value (*listwise deletion*), which is what many procedures do by default. Comparing it with `nrow(df)` shows how much listwise deletion would cost you.

## Change scores

In a pre/post design, the **change score** (post − pre) shows each person's change. Here a negative change means anxiety went down. (In Means Cluster you'll test change properly with a paired *t*-test.)

> **APA note:** a methods section reports the sample size, how many were excluded or had missing data, and why. That's exactly what this audit gives you.

## Mission

1. Import `wellbeing_survey.csv` into `survey`.
2. Make `survey$group` a factor with **Control** as the first level.
3. Store the number of missing values per column in `missing_per_column`.
4. Store the number of students with no missing data in `n_complete`.
5. Add `survey$change`: post-test anxiety minus pre-test anxiety.
6. Store the mean change for the whole sample, ignoring missing values, in `mean_change`.
