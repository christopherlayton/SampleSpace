# Crew Lottery

A sector review. Everything you've built here (random draws, `replicate()`, the standard error) works for **proportions** as well as means.

A proportion *is* a mean: code each person 1 (yes) or 0 (no), and the mean of the 1s and 0s is the proportion of yeses. So the Central Limit Theorem applies too, and the standard error of a proportion has its own formula:

**SE = √( p (1 − p) / n )**

> **From the Crew Log:** 64 of the 564 first-time flyers in the log were women: a proportion of .113 for the whole log.

## The question

A researcher with only a random crew of 50 astronauts would estimate that proportion from their crew. How far off might they be? And how much better would a crew of 200 do? Simulate both, with replacement as in the Sampling Machine.

## Mission

`first` (one row per astronaut) is loaded for you, and the seed is set.

1. Make `women`, TRUE/FALSE for whether each astronaut in `first` is female, and store the log's proportion in `p_log`.
2. Store the proportion of women in each of **2,000** random crews of **50** in `props_50`, and in 2,000 crews of **200** in `props_200`.
3. Store the two simulated standard errors in `se_50` and `se_200`, and `se_50 / se_200` in `se_ratio`.
4. Store the formula SE for crews of 50, √(p(1 − p)/n) with `p_log`, in `se_50_formula`.
5. Draw a histogram of `props_50`.

What is `se_ratio` close to, and why?
