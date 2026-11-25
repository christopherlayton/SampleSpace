# Least-Squares Fit

A correlation says *how tightly* two variables follow a line. **Regression** finds the line:

**ŷ = b₀ + b₁x**

- **b₀**, the intercept: the predicted y when x = 0.
- **b₁**, the slope: how much the predicted y changes for each one-unit increase in x.

The data here are the crew morale survey: each person's hours of sleep and their morale score (the composite from Reverse Thrusters), 46 people with both.

## Which line?

For each point, the **residual** is the vertical distance from the point to the line: actual y minus predicted ŷ. Least squares chooses the line that makes the **sum of squared residuals** (SSE) as small as possible. Squaring makes every residual count positively and makes big misses count a lot. In the lab, each residual is drawn as a real square.

## R²

The worst sensible line ignores x: a flat line at the mean of y. Its SSE is the **total sum of squares**, SST. Then

**R² = 1 − SSE / SST**

is the proportion of the variation in y that the line accounts for. For a line with one predictor, R² = r².

## The lab

Drag the gold handles at each end of the line, or use the sliders. The least-squares line can be shown for comparison, but the first two goals only count while it's hidden. Reach the three goals to open stage 2.

> **Coming from SPSS?** *Analyze → Regression → Linear*: Dependent = morale, Independent = sleep. The Coefficients table's "B" column is `coef(fit)`, and the Model Summary's R Square is `summary(fit)$r.squared`.

> **Careful with causes:** these are correlational data. Sleep might raise morale, morale might help sleep, or something else (workload) might drive both. A regression line describes the pattern; the design decides what you can claim.

## Mission

`d` holds `sleep_morale.csv`.

1. Fit the regression of `morale_score` on `sleep_hours` with `lm()` and store it in `fit`.
2. Store its intercept and slope (from `coef()`) in `b`.
3. Store the sum of squared residuals in `sse` and the total sum of squares in `sst`.
4. Store R², worked out from `sse` and `sst`, in `r2`.
