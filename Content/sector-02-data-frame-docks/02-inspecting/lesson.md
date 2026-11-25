# Scanning the Hold

A real dataset is waiting in the hold: `penguins`, measurements of 344 penguins from three islands in Antarctica (Horst, Hill & Gorman, 2020). It's already loaded for this level.

The first thing to do with **any** new dataset is look at it. Four functions do most of the work:

| Code | Shows |
|---|---|
| `str(df)` | the *structure*: size, each variable's name and type, first few values |
| `head(df)` | the first 6 rows (`head(df, 10)` for 10) |
| `summary(df)` | per variable: min, quartiles, median, mean, max, and the count of `NA`s; counts for factors |
| `names(df)` | the variable names |

Read `str()` output line by line: `$ species : Factor w/ 3 levels` tells you `species` is a factor; `$ bill_length_mm : num` is numeric; `int` means whole numbers.

`summary()` is the quickest way to spot problems: impossible values (an age of 230) and missing data (`NA's : 2`).

> **Coming from SPSS?** `str()` is a compact Variable View. `summary()` is close to *Analyze → Descriptive Statistics → Descriptives* (plus *Frequencies* for factors), for every variable at once.

## Mission

1. Run `str(penguins)` and `summary(penguins)` and read what they tell you.
2. Store the number of penguins (rows) in `n_penguins` and of variables (columns) in `n_vars`.
3. Store the variable names in `var_names`.
4. From the `summary()` output, how many penguins have no body mass recorded? Store the number in `n_missing_mass`.
