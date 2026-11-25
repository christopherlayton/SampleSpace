# Cargo Manifest

Welcome to the Vector Belt. Almost everything in R is built from **vectors**: ordered collections of values of the same type. A single number is a vector of length 1; a column of data is a longer one.

You make a vector with `c()`, short for *combine*:

```r
ages <- c(21, 34, 19, 42)
ages
#> [1] 21 34 19 42
```

## Functions work on the whole vector

Most R functions take a whole vector at once, with no loop needed:

| Function | Gives you | `ages` example |
|---|---|---|
| `length()` | how many values (*n*) | `4` |
| `sum()` | the total | `116` |
| `mean()` | the arithmetic mean (*M*) | `29` |
| `min()`, `max()` | the smallest and largest | `19`, `42` |

> **Coming from SPSS?** In SPSS a variable is a column in the Data View. In R a variable is a vector, and a dataset (a *data frame*, coming in the Data Frame Docks) is a set of equal-length vectors side by side.

## Mission

Eight participants completed an anxiety questionnaire. Their scores were **12, 18, 9, 22, 15, 11, 19 and 14**.

1. Store the eight scores, in that order, in a vector called `anxiety`.
2. Store the number of participants in `n_participants` using `length()`.
3. Store the total in `total_anxiety` and the mean in `mean_anxiety`.
