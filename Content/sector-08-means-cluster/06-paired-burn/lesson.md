# Paired Burn

In *Two Separate Crews* the mindfulness and control groups didn't differ significantly after the programme. But everyone was measured **twice**, before and after. Did anxiety change across the term?

## Paired means "work on the differences"

When the same people are measured twice, their two scores are linked: someone anxious in September is probably still fairly anxious in December. The paired *t*-test uses that by working on each person's **difference**:

```r
diffs <- survey$anxiety_pre - survey$anxiety_post   # one number per person
t.test(diffs)                                         # is the mean difference 0?
```

That's exactly the paired test:

```r
t.test(survey$anxiety_pre, survey$anxiety_post, paired = TRUE)
```

Stable differences between people cancel out in the subtraction, so the SE is much smaller than in a two-group comparison of the same scores. That's why repeated-measures designs are so powerful.

## Missing values

A person with a missing post-test has no difference, so they're dropped: 40 students, 37 complete pairs, *df* = 36. Report the *n* that was analysed.

## Watch out for formulas

`t.test(y ~ group, paired = TRUE)` used to work but now stops with *cannot use 'paired' in formula method*, because it silently relied on rows being in the right order. Use the two-column form above, or `t.test(Pair(anxiety_pre, anxiety_post) ~ 1, data = survey)`.

## Effect size for paired data

**d_z = mean difference / SD of the differences.** It's the paired cousin of Cohen's *d*. It tends to be larger than a *d* computed from the two time points' SDs, so say which one you report.

> **Coming from SPSS?** *Analyze → Compare Means → Paired-Samples T Test*, with the pair anxiety_pre–anxiety_post. SPSS subtracts the second variable from the first, as R does.

> **APA note:** Anxiety fell from pre-test (*M* = 29.76, *SD* = 5.16) to post-test (*M* = 26.86, *SD* = 6.54), *t*(36) = 4.94, *p* < .001, *d*z = 0.81. (Means for the 37 complete pairs.)

## Mission

1. Import `wellbeing_survey.csv` into `survey`.
2. Store the paired *t*-test of `anxiety_pre` against `anxiety_post` in `paired`.
3. Store each person's difference (pre − post) in `diffs`, and the one-sample *t*-test of `diffs` in `on_diffs`. Compare the two *t* values.
4. Store the number of complete pairs in `n_pairs`, the mean difference in `mean_diff` and d_z in `d_z`.
