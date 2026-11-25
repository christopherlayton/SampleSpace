# Simulated Ages

A **model** is a simplified description of how data could arise. "Age at first flight is normal with mean 40 and SD 5" is a model. `rnorm()` lets you generate data from it:

```r
rnorm(5, mean = 40, sd = 5)
```

Why simulate data you could describe with a formula? Because simulation answers questions formulas can't easily reach, and because it lets you **check your understanding**: if the formula and the simulation disagree, one of them is wrong.

## Simulation vs exact

| Question | By simulation | Exactly |
|---|---|---|
| Proportion above 50 | `mean(ages > 50)` | `pnorm(50, 40, 5, lower.tail = FALSE)` |
| Mean | `mean(ages)` | 40 |
| SD | `sd(ages)` | 5 |

With 1,000 draws the simulated answers land close to the exact ones, but not on them. More draws, closer answers.

> **From the Crew Log:** real ages at first flight (approximate, from years of birth and of mission) average 40.3 years with an SD of 5.25. The model N(40, 5) is a tidy version of that, and it's the population CI Rain draws from in Inference Station.

> **Coming from SPSS?** *Transform → Compute Variable* with `RV.NORMAL(40, 5)` makes one random normal value per row of the open file. In R the number of draws is up to you and needs no data file.

## Mission

The seed is set for you.

1. Simulate **1,000** ages at first flight from the model N(40, 5) into `ages`.
2. Store the proportion of simulated ages **above 50** in `sim_over_50`, and the exact proportion from `pnorm()` in `exact_over_50`.
3. Store the simulated mean and SD in `sim_mean` and `sim_sd`.
4. Draw a histogram of `ages`.
