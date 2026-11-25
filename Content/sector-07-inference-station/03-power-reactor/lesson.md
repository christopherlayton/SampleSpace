# Power Reactor

Two ways a test can go wrong:

| | H₀ really true | H₀ really false (there is an effect) |
|---|---|---|
| **Reject H₀** | Type I error (false alarm), rate **α** | Correct: **power**, 1 − β |
| **Don't reject** | Correct | Type II error (miss), rate **β** |

You choose α. **Power** depends on three things: the true effect size, the sample size and α. A study with low power will usually miss a real effect, and when it does find one, the estimate tends to be exaggerated.

## Effect size: Cohen's d

**d = difference in means / SD.** It's the difference in SD units, so it doesn't depend on the scale. Cohen's rough labels are 0.2 small, 0.5 medium, 0.8 large, but judge size by what matters in your field.

## The lab

White is the *t* distribution if H₀ is true; gold is the *t* distribution you'd actually get if the effect is *d*. Beyond the dashed critical value you reject H₀: the red area under white is α, the green area under gold is power, and the faint gold area is β. The small chart plots power against *n*. The numbers match R's `power.t.test()`.

## Now do it in R

`power.t.test()` takes any four of `n`, `delta`, `sd`, `sig.level` and `power` and solves for the missing one. With `sd = 1`, `delta` is Cohen's d. *n* is **per group**, and always round up.

> **Your proposal:** committees and ethics boards expect an *a priori* power analysis: "To detect a medium effect (d = 0.5) with 80% power at α = .05 (two-sided), 64 participants per group are needed." Base d on earlier studies, not on hope.

> **Coming from SPSS?** Recent versions have *Analyze → Power Analysis*; many people use G*Power. `power.t.test()` gives the same answers for *t*-tests, and the **pwr** package covers ANOVA, correlation and chi-square.

## Mission

1. Store the power of a study with 20 per group and d = 0.5 in `power_20`.
2. Store the n per group needed for 80% power at d = 0.5, rounded up, in `n_needed`.
3. Store the effect size detectable with 80% power at 30 per group in `d_30`.
4. Store the n per group needed for 80% power at d = 0.2, rounded up, in `n_small`.
