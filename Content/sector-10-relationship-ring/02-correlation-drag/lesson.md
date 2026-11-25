# Correlation Drag

Before testing a correlation, get a feel for what r measures.

**Pearson's r** summarises a *linear* relationship between two numeric variables in one number from −1 to +1:

| r | Means |
|---|---|
| +1 | a perfect rising straight line |
| 0 | no *linear* relationship (there could still be a curve) |
| −1 | a perfect falling straight line |

r² is the proportion of variance the two variables share: r = .5 means 25% shared variance.

## What r is sensitive to

- **Outliers.** r is built from products of deviations from the mean, so one far-out point can create or destroy a correlation.
- **Non-linearity.** A perfect U-shape can have r = 0.
- **Restricted range.** Correlations shrink when you only sample part of the range.

**Spearman's rho** correlates the *ranks* instead of the values. An extreme point is just the highest rank, so rho resists outliers and also picks up any consistently rising (monotonic) pattern, curved or not.

## The lab

Drag any point and watch r. The gold line is the least-squares line (the next lab is about it). Make a new cloud at a chosen r, add an outlier in the corner that works against the trend, and drag it around. Reach the three goals to open stage 2.

> **Coming from SPSS?** *Analyze → Correlate → Bivariate* offers Pearson and Spearman tick boxes. In R: `cor(x, y)` and `cor(x, y, method = "spearman")`; `cor.test()` adds the p-value and CI.

> **APA note:** report r with its df and p, e.g. *r*(48) = .32, *p* = .02, and plot the data in a scatterplot.

## Mission

`x` and `y` are 20 values each with no real relationship (the seed is set for you).

1. Store Pearson's r for `x` and `y` in `r_cloud`.
2. Add one outlier at (9.6, 0.4): store the extended vectors in `x2` and `y2`.
3. Store Pearson's r with the outlier in `r_outlier`, and Spearman's rho with the outlier in `rho_outlier`.
4. Draw a scatterplot of `x2` and `y2` with `plot()`.

Which correlation did the single point move more?
