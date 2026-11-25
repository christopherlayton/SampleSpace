# Tangled Threads

A relationships script for the professional-development study. It stops with errors, and one bug runs without complaint but answers the wrong question. Find all **four**.

## Things that trip people up

- **`cor.test()`'s formula.** Correlation is symmetric, with no outcome, so the formula has nothing on the left of `~`: `cor.test(~ x + y, data = d)`. Or skip the formula: `cor.test(d$x, d$y)`.
- **Which way round?** `lm(y ~ x)` predicts y from x. Swapping them fits a different line (Regression Forecast), and R can't know which you meant. Read the research question.
- **χ² needs counts.** `chisq.test()` takes a contingency table (or two factors as separate arguments), not a data frame of category labels.

## Mission

Fix the script so that:

1. `r_test` is the Pearson correlation test of `efficacy_t1` and `efficacy_t3`.
2. `model` predicts `efficacy_t3` from `efficacy_t1` and `workload_hours`.
3. `vifs` holds the model's variance inflation factors.
4. `chi` tests whether experience is independent of programme.
