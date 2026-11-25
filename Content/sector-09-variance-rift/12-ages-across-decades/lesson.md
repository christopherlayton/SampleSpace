# Ages Across Decades

The question from your arrival at the Variance Rift: astronauts flying for the first time were about 35 on average in the 1960s and about 42 in the 2010s. **Is the difference between decades bigger than the spread of ages within them?**

## One row per astronaut

Age at *first* flight is one number per person, so keep each astronaut's first mission (`mission_number == 1`): 564 rows, one per ID. Ages are approximate, since the log has years of birth and mission, not dates.

## The plan

1. **Describe** each decade: *n*, *M*, *SD*. The decades differ a lot in size.
2. **Check** equal variances with Levene's test (centred on the mean, as SPSS does).
3. **Test.** Fit both the classic ANOVA and **Welch's ANOVA**. With unequal group sizes, unequal variances distort the classic F, so let Levene's test (and the SDs) decide which you report.
4. **Size** the effect with η², whatever the *p*.
5. **Follow up** with **Games–Howell** comparisons, the post hoc test that, like Welch, doesn't assume equal variances.

- **H₀:** mean age at first flight is the same in every decade
- **H₁:** at least one decade's mean differs

Remember Inference Station: the log is nearly the whole population of astronauts, so a test here asks whether the decade differences are bigger than chance variation in the process, not whether they "exist".

## Mission

`astronauts` is loaded, with readr, dplyr, car and effectsize. Call Games–Howell as `rstatix::games_howell_test()`: loading rstatix would hide effectsize's `eta_squared()` behind its own.

1. Make `first`: first missions only, with `age` and a factor `decade` (1960, 1970, …).
2. Store each decade's `n`, `mean` and `sd` of age in `decade_stats`.
3. Store SPSS's Levene test in `levene`.
4. Store the classic ANOVA in `classic` and Welch's ANOVA in `welch`.
5. Store η² from `classic` in `eta` and the Games–Howell comparisons in `games`.
6. Store your decision at α = .05 in `decision` (`"reject"` or `"fail to reject"`), using the test that suits your Levene result, and name that test in `test_used` (`"classic"` or `"welch"`).

Then read your results: which decades differ, and by how many years?
