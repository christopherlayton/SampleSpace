# Effect Size Gauge

A *p*-value says whether a difference is surprising under H₀. It doesn't say whether the difference is **big**. APA style asks for an effect size with every test, and your committee will too.

## Cohen's d

**d = (M₁ − M₂) / SD_pooled**

The difference in means, measured in standard deviations. The pooled SD combines both groups' SDs, weighted by their degrees of freedom:

**SD_pooled = √( ((n₁ − 1)s₁² + (n₂ − 1)s₂²) / (n₁ + n₂ − 2) )**

| |d| | Cohen's rough label |
|---|---|
| 0.2 | small |
| 0.5 | medium |
| 0.8 | large |

The labels are a last resort. Compare with effects in your own field: in education, *d* = 0.2 from a cheap intervention can matter a great deal.

## With a package

```r
library(effectsize)
cohens_d(score ~ method, data = teach)
```

It gives the same *d* plus a **95% CI**. Report both: a CI for *d* that runs from tiny to huge says your study can't pin the effect down. `hedges_g()` applies a small-sample correction and is a good choice for small groups.

> **Coming from SPSS?** SPSS 27 and later add an *Independent Samples Effect Sizes* table, whose "Standardizer" for Cohen's *d* is the pooled SD.

> **APA note:** *d* = 1.01, 95% CI [0.24, 1.76]. Give the sign or state the direction in words, and keep two decimals (*d* can exceed 1, so it keeps its leading zero).

## Mission

The teaching study: lecture vs active learning.

1. Load haven and effectsize; import `teaching_study.sav` into `teach` and make `method` a factor.
2. Store each group's scores in `lecture` and `active`, and the pooled SD in `sd_pooled`.
3. Store Cohen's *d* by hand, Lecture − Active learning, in `d_hand`.
4. Store `cohens_d(score ~ method, data = teach)` in `d_pkg` and its 95% CI as two numbers in `d_ci`.
