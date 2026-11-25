# Assembling the Manifest

Welcome to the Data Frame Docks, where vectors become datasets. A **data frame** is a table of equal-length vectors side by side:

- each **row** is a **case**: one participant, school, or observation;
- each **column** is a **variable**: one thing measured about every case.

This "one row per case, one column per variable" layout is the shape almost every R analysis expects. (It's often called *tidy* data.)

```r
pilots <- data.frame(
  name = c("Ada", "Ben", "Cy"),
  hours = c(120, 85, 240)
)
pilots
#>   name hours
#> 1  Ada   120
#> 2  Ben    85
#> 3   Cy   240
```

Each argument becomes a column: the name before `=` is the column name, the vector after it is the data.

| Code | Gives |
|---|---|
| `nrow(df)` | number of cases (rows) |
| `ncol(df)` | number of variables (columns) |
| `dim(df)` | both: rows, then columns |
| `names(df)` | the variable names |

> **Coming from SPSS?** A data frame is the Data View: rows are cases, columns are variables. The difference is that R can hold many data frames at once, each in its own object.

## Mission

The starter code has three vectors from a small study.

1. Combine them into a data frame called `study` with columns named `id`, `group` and `score`, in that order.
2. Store the number of cases in `n_cases` and the number of variables in `n_variables`.
