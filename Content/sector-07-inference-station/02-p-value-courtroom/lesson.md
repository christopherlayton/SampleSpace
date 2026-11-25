# p-value Courtroom

A hypothesis test works like a trial. The **null hypothesis** (H₀: "there's no difference") is the defendant, presumed innocent. Your data are the evidence. The question the court asks is narrow:

> *If H₀ were true, how surprising would evidence this strong be?*

That probability is the **p-value**. If it's smaller than the standard of proof you set in advance, **α** (usually .05), you reject H₀. If not, you *fail to reject* it, which isn't the same as proving it innocent: absence of evidence isn't evidence of absence.

## The evidence: a t statistic

For two groups of *n*, the evidence is summarised as

**t = difference in means / SE**, with SE = SD × √(2 / *n*) and *df* = 2*n* − 2.

Big |t| means the difference is large compared with how much means wander by chance (Sampling Machine's lesson). The lab draws the *t* distribution H₀ predicts; the gold line is your *t*, and the blue shaded tail is the p-value. Red shading marks the rejection region for your α.

The starting evidence is modelled on the wellbeing survey: post-test anxiety 1.8 points lower with mindfulness, pooled SD about 6.5, about 19 per group.

## What p is not

- Not the probability that H₀ is true.
- Not the probability your result was "due to chance".
- Not a measure of how big or important an effect is.

> **APA note:** report the test statistic, its degrees of freedom and the exact p: *t*(36) = 0.85, *p* = .40. Use *p* < .001 only below .001, and no leading zero (p can't exceed 1).

## Now do it in R

`pt(q, df)` is the area of the *t* distribution **below** q. So a two-sided p is `2 * pt(-abs(t), df)` and a one-sided ("greater") p is `pt(t, df, lower.tail = FALSE)`. You can also get p by simulation, as the lab's retrial button does.

## Mission

The evidence is set for you: `diff <- 1.8`, `sd_pooled <- 6.5`, `n <- 19`.

1. Store the standard error in `se`, the t statistic in `t_obs` and the degrees of freedom in `df`.
2. Store the two-sided p-value in `p_two` and the one-sided ("greater") p-value in `p_one`.
3. Simulate 2,000 studies under H₀: two groups of `n` from N(0, `sd_pooled`), keeping each `t.test(a, b, var.equal = TRUE)$statistic`, in `sim_t`.
4. Store the proportion of simulated |t| at least as large as |`t_obs`| in `sim_p`. It should be close to `p_two`.
