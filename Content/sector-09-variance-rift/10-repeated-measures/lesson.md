# Three Readings

The same 60 teachers rated their self-efficacy three times: before the programme (`efficacy_t1`), at the end (`efficacy_t2`) and at a follow-up (`efficacy_t3`). Ignoring programme for now, did self-efficacy change over time?

Three related measurements call for a **repeated-measures ANOVA**, the many-time-points version of the paired *t*-test. Each teacher is compared with themselves, so the stable differences *between* teachers drop out of the error term, which usually means much more power.

## Wide and long

SPSS's *GLM Repeated Measures* wants **wide** data, one column per time point. Most R tools want **long** data, one row per person per time point:

```r
long <- pd |>
  select(id, starts_with("efficacy")) |>
  pivot_longer(starts_with("efficacy"), names_to = "time", values_to = "efficacy")
```

## The model

```r
library(afex)
rm <- aov_ez(id = "id", dv = "efficacy", data = long, within = "time")
rm            # Greenhouse–Geisser corrected by default
summary(rm)   # the full story: uncorrected test, Mauchly, GG and HF
```

## Sphericity

Repeated-measures ANOVA assumes **sphericity**: the variances of the differences between every pair of time points are equal. **Mauchly's test** checks it (with the same small-sample/large-sample caveats as any assumption test). When it's doubtful, shrink the df by **ε**:

| Correction | When |
|---|---|
| Greenhouse–Geisser (ε̂GG) | the usual choice; afex applies it by default |
| Huynh–Feldt (ε̂HF) | a little less conservative, when ε is near 1 |

That's why afex prints fractional df such as *F*(1.80, 106.25). SPSS shows the same rows in *Tests of Within-Subjects Effects*.

## Following up

Which time points differ? Paired *t*-tests with a correction:

```r
pairwise.t.test(long$efficacy, long$time, paired = TRUE, p.adjust.method = "holm")
```

This pairs rows by position, so each time point's rows must be in the same teacher order, as they are after `pivot_longer()`.

> **APA note:** say which correction you used, e.g. "Mauchly's test indicated a violation of sphericity, so Greenhouse–Geisser corrected df are reported, *F*(1.80, 106.25) = …, *p* = …."

## Mission

`pd` is loaded with afex, dplyr and tidyr.

1. Reshape the three efficacy columns into `long` (columns `id`, `time`, `efficacy`).
2. Store the mean efficacy at each time in `time_means`.
3. Fit the repeated-measures ANOVA with `aov_ez()` in `rm` and print it and its summary.
4. Store Mauchly's p-value in `mauchly_p`.
5. Store Holm-corrected paired comparisons of the three times in `follow_up`.
