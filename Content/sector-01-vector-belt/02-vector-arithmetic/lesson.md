# Thruster Calibration

When you do arithmetic with a vector, R applies it to **every element**. This is called *vectorisation*, and it replaces most of the loops you'd write in other languages:

```r
x <- c(2, 4, 6)
x * 10
#> [1] 20 40 60
x + c(1, 1, 1)
#> [1] 3 5 7
```

Two vectors of the same length are combined element by element: first with first, second with second, and so on.

## Two transformations you'll use for real

- **Converting to a percentage:** divide by the maximum possible score, then multiply by 100.
- **Mean-centring:** subtract the mean from every score. A centred score of `+4` means "4 points above the mean". The centred scores always sum to zero. Centring makes regression intercepts easier to interpret, which you'll see in the Relationship Ring.

Centring is half of a z-score: a z-score also divides by the standard deviation.

> **Coming from SPSS?** This is *Transform → Compute Variable*, but you write the formula directly and can keep the result as a new object instead of a new column.

## Mission

The starter code holds five students' raw scores on a quiz marked **out of 50**.

1. Store each score as a percentage in `percent`.
2. Store the mean-centred scores in `centred` (each score minus the mean of `raw`).
