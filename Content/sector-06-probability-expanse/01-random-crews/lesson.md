# Random Crews

Welcome to the Probability Expanse. From here on, the question behind every analysis is: *how much would this result change if I'd drawn a different sample?* To answer it you need randomness you can control.

## `sample()`

`sample(x, size)` picks `size` values from `x` at random.

| Code | Does |
|---|---|
| `sample(1:564, size = 10)` | 10 different numbers from 1 to 564 (**without** replacement: no repeats) |
| `sample(1:6, size = 600, replace = TRUE)` | 600 die rolls (**with** replacement: values can repeat) |
| `sample(x)` | `x` shuffled into a random order |

Sampling **without replacement** is how you'd pick participants: nobody is chosen twice. Sampling **with replacement** models a process that can repeat, like a die, or a population so large that drawing one person doesn't change the odds for the next.

## `set.seed()`: random, but reproducible

R's random numbers come from a generator that starts from a *seed*. Set the seed and you get the same "random" draws every time:

```r
set.seed(2026)
sample(1:564, size = 10)
```

Run those two lines twice and you'll get the same ten numbers both times. Put `set.seed()` near the top of any script that uses random numbers (simulations, random assignment, bootstrapping) so that your results can be reproduced, by you next month or by your committee.

## Probability as a long-run proportion

The probability of rolling a 6 is 1/6 ≈ 0.167. That doesn't mean every six rolls contain one 6. It means that **over many rolls, the proportion of 6s settles near 1/6**. Roll 600 times and you'll get roughly 100 sixes, not exactly 100.

`mean()` of a TRUE/FALSE vector gives the proportion TRUE, so `mean(rolls == 6)` is the proportion of sixes.

> **Coming from SPSS?** *Data → Select Cases → Random sample of cases* and *Transform → Random Number Generators* (where you set the seed). In R it's `sample()` and `set.seed()`, written into your script.

> **From the Crew Log:** the log gives each of its 564 astronauts an ID number from 1 to 564. Drawing ten numbers at random is drawing a random crew.

## Mission

1. Set the seed to **2026**, then draw **10 different** astronaut ID numbers from 1 to 564 into `crew_ids`.
2. Roll a six-sided die **600 times** into `rolls`.
3. Store the proportion of sixes in `prop_six`.
4. Print `table(rolls)` to see how evenly the faces came up.
