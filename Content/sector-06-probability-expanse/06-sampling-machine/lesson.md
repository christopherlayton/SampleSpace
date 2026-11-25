# Sampling Machine

Your dissertation won't measure everyone; it will measure a **sample** and use its mean to estimate the **population** mean. A different sample would give a different mean. How much do sample means wander? This lab answers that by brute force.

## The population: hours per mission

Here the whole Crew Log is the population: 1,277 missions, with a mean (μ) of about 1,051 hours and an SD (σ) of about 1,715 hours. It is badly **right-skewed**: most missions are short Shuttle-era flights (the median is 261 hours), and a few long space-station stays drag the mean upwards.

A "crew" is a random sample of *n* missions from the log, drawn **with replacement** (a mission can be picked twice), which mimics drawing from a very large population.

## Three ideas to watch for

| Idea | What you'll see |
|---|---|
| **Sampling distribution** | The pile of crew means: the distribution of a statistic over many samples. |
| **Central Limit Theorem** | With a big enough *n*, crew means pile up into a bell shape centred on μ, even though the hours themselves are skewed. |
| **Standard error (SE)** | The SD of the sampling distribution, σ / √*n*. Bigger samples give means that wander less, but only with the square root: four times the crew halves the SE. |

The SE is what every test from here on measures against. A *t*-test asks, in effect: is the difference I found big compared with how much means wander by chance?

## The lab

The top chart is the population, the middle strip is the latest crew (its mean is the green line), and the bottom chart piles up one mean per crew on the same axis, so you can see it narrow. Changing *n* starts a new pile. The gold curve is the normal curve the Central Limit Theorem predicts. Reach the three goals to open stage 2.

## Now do it in R

| Code | Does |
|---|---|
| `sample(hours, size = 30, replace = TRUE)` | draws one crew of 30 |
| `replicate(1000, mean(sample(hours, size = 30, replace = TRUE)))` | repeats it 1,000 times, keeping each mean |
| `sd(crew_means)` | the simulated standard error |
| `sd(hours) / sqrt(30)` | the standard error from the formula |

Random draws differ every run. In your own scripts, put `set.seed()` with any number at the top, e.g. `set.seed(2026)`, so the same "random" results come back each time and your analysis can be reproduced. (Sample Space sets a seed for you in this level.)

> **Coming from SPSS?** *Descriptives → Options → S.E. mean* reports the standard error of a mean from the σ / √*n* formula, but SPSS has no menu for watching a sampling distribution form. In R it's one line with `replicate()`, and the same idea powers bootstrapping later.

> **APA note:** the SD describes how spread out your **data** are; the SE describes how precisely you've estimated the **mean**. Report *M* and *SD* for descriptive statistics, and always say which one error bars in a figure show.

## Mission

`hours` is already loaded from the log.

1. Draw one crew of 30 missions, with replacement, into `one_crew`.
2. Store the means of 1,000 random crews of 30 in `crew_means`.
3. Store the SD of `crew_means` in `se_sim`, and σ / √30 (using `sd(hours)`) in `se_formula`. They should be close.
4. Draw a histogram of `crew_means` with `hist()`.
