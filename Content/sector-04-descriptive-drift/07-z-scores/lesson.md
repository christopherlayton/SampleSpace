# Standard Candles

Astronomers measure distance with *standard candles*: objects of known brightness. Statisticians use the **z-score**, which puts any value on a standard scale: how many standard deviations it lies from the mean.

**z = (x − mean) / SD**

- z = 0 is exactly average; z = 2 is two SDs above; z = −1 is one SD below.
- z-scores have no units, so you can compare a test score with a reaction time.
- A whole column of z-scores has mean 0 and SD 1.

In R, either write the formula or use `scale()`:

```r
z <- (x - mean(x)) / sd(x)
z <- as.numeric(scale(x))   # scale() returns a one-column matrix; as.numeric() flattens it
```

## What z-scores *don't* do

Standardising changes the units, not the **shape**. A skewed variable gives skewed z-scores. The familiar "95% of values lie within ±1.96" is a property of the *normal* curve, so it only holds if the data are roughly normal. In a skewed variable, far more than half the values can sit below the mean.

A common screening rule flags |z| > 3 as a possible outlier. It's a reason to look, not a reason to delete.

> **Coming from SPSS?** *Descriptives → Save standardized values as variables* adds a `Zvar` column to the dataset. Same numbers.

## Mission

1. Load readr and import `astronauts.csv` into `astronauts`; `hours` is ready for you.
2. Store the z-score of every mission's length in `z_hours` (a plain numeric vector).
3. Store how many missions are more than 3 SDs from the mean in `n_extreme`.
4. Store the largest z-score in `max_z`. (Whose mission is it?)
5. Store the proportion of missions with a negative z-score in `prop_below`. Would a normal distribution give the same?
