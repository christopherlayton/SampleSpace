# Jammed Simulator

The ship's simulator should show how much the mean age of a random crew of 10 wanders. It stops with an error, and once it runs, it reports a standard error of exactly 0, which can't be right.

## Things that jam simulations

- **Without replacement, you run out.** `sample(x, size)` draws without replacement by default, so `size` can't be bigger than `length(x)`. Resampling (drawing many values from a fixed set, as in bootstrapping) needs `replace = TRUE`.
- **A seed in the wrong place.** `set.seed()` restarts the random-number generator. Put it inside `replicate()` and every repeat restarts from the same point, so every "random" crew is the same crew.
- **σ / n is not the standard error.** The SE of a mean is σ / **√n**. Dividing by *n* makes it far too small, and every test built on it far too confident.

A good habit: before trusting a simulation, check that it *varies* (`sd()` of the results isn't 0) and that it agrees with a formula you know.

> **From the Crew Log:** ages at first flight are approximate (year of mission minus year of birth), one per astronaut.

## Mission

Fix the script so that it runs and stores:

- `big_draw`: 1,000 ages drawn **with replacement** from `age`,
- `crew_means`: the mean ages of 2,000 random crews of 10 (each a different random crew),
- `se_sim`: the SD of `crew_means`,
- `se_formula`: the standard error from the formula.

There are **three** bugs. Keep the object names as they are.
