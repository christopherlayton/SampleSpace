# Logic Gates

A comparison asks a question of **every** value and answers with a **logical** vector of `TRUE` and `FALSE`:

```r
x <- c(3, 8, 5, 10)
x > 4
#> [1] FALSE  TRUE  TRUE  TRUE
```

| Operator | Means |
|---|---|
| `==` | equal to (two `=` signs!) |
| `!=` | not equal to |
| `<` `<=` | less than, at most |
| `>` `>=` | greater than, at least |
| `&` `\|` | and, or |

## Counting with TRUE and FALSE

R treats `TRUE` as 1 and `FALSE` as 0 when you do maths with them. So:

- `sum(x > 4)` counts how many values are above 4 (here, 3);
- `mean(x > 4)` gives the **proportion** above 4 (here, 0.75).

## Filtering

Put a logical vector inside square brackets to keep only the `TRUE` positions:

```r
x[x > 4]
#> [1]  8  5 10
```

> **Coming from SPSS?** This is *Data → Select Cases → If condition is satisfied*, except nothing gets filtered out of your dataset by accident. You make a new object and the original stays as it was.

## Mission

`scores` holds eight exam scores. The pass mark is **60**.

1. Store a logical vector saying whether each student passed (60 or more) in `passed`.
2. Store how many passed in `n_passed`, using `sum()`.
3. Store the proportion who passed in `prop_passed`, using `mean()`.
4. Store only the scores of **80 or more** in `high_scores`.
